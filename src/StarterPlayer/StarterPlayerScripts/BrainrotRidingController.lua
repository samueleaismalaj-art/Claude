--[[
	BrainrotRidingController (client-only)
	The core gameplay loop: owns the ridden Brainrot, steering, jumping,
	rage/crash, capture timing and per-tick server reporting. The client
	simulates movement every frame for instant-feeling controls; every
	number that matters for currency/progression is sent to the server
	(RunManagerService) which re-validates and clamps it before it's ever
	saved. See README.md "Architecture & Simplifications".

	Place: StarterPlayer/StarterPlayerScripts/BrainrotRidingController.lua (ModuleScript)
	Required by: StarterPlayerScripts/Main.client.lua
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local Remotes = require(ReplicatedStorage.Modules.Remotes)
local BrainrotModelFactory = require(ReplicatedStorage.Modules.BrainrotModelFactory)
local TrackBuilder = require(script.Parent.TrackBuilder)

local LocalPlayer = Players.LocalPlayer

local BrainrotRidingController = {}
BrainrotRidingController.__index = BrainrotRidingController

local TRACK_ORIGIN = CFrame.new(0, 45, -6000)
local X_MIN, X_MAX = -17, 17
local STEER_BASE_SPEED = 14
local STEER_HANDLING_SCALE = 30
local Z_COLLIDE_TOLERANCE = 3
local X_COLLIDE_WIDTH = 3.6
local RAGE_GRACE_TIME = 5
local JUMP_HOP_DURATION = 0.45
local JUMP_LANE_RANGE = 9
local JUMP_LANE_RANGE_GLIDE = 15
local JUMP_FORWARD_RANGE = 16
local JUMP_FORWARD_RANGE_GLIDE = 26
local REPORT_INTERVAL = 0.25

function BrainrotRidingController.new(cameraController, callbacks)
	local self = setmetatable({}, BrainrotRidingController)
	self.Camera = cameraController
	self.Callbacks = callbacks or {}
	self.CapturedSet = {}
	self.Active = false
	self.SteerAxis = 0
	self.Track = nil
	self.MountModel = nil
	self.MountId = nil
	self.MountX = 0
	self.MountZ = 0
	self.ElapsedOnMount = 0
	self.HopUntil = 0
	self.DistanceThisRun = 0
	self.DistanceSinceReport = 0
	self.LastReportClock = 0
	self.CaptureFired = false
	self.RunTime = 0
	self:_bindInput()
	return self
end

function BrainrotRidingController:SetCapturedSet(capturedBrainrots)
	self.CapturedSet = {}
	for id in pairs(capturedBrainrots or {}) do
		self.CapturedSet[id] = true
	end
end

function BrainrotRidingController:_bindInput()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			self.SteerAxis = -1
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			self.SteerAxis = 1
		elseif input.KeyCode == Enum.KeyCode.Space then
			self:RequestJump()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, _processed)
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			if self.SteerAxis == -1 then
				self.SteerAxis = 0
			end
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			if self.SteerAxis == 1 then
				self.SteerAxis = 0
			end
		end
	end)
end

-- Called by the mobile HUD steer buttons (hold to steer, release to stop).
function BrainrotRidingController:SetSteerAxis(axis)
	self.SteerAxis = axis
end

function BrainrotRidingController:_currentData()
	return BrainrotData.Get(self.MountId)
end

function BrainrotRidingController:_isRaging()
	local data = self:_currentData()
	return data and self.ElapsedOnMount >= data.RageTime
end

function BrainrotRidingController:_computeSpeed(dt)
	local data = self:_currentData()
	if not data then
		return 0
	end
	local speed = data.Speed

	if data.Special == "AccelerateOverTime" then
		speed += math.min(self.ElapsedOnMount * 1.2, 14)
	end

	if self:_isRaging() then
		speed *= 1.35
	end

	return speed
end

function BrainrotRidingController:_swapMount(newId, newModel)
	if self.MountModel then
		self.MountModel:Destroy()
	end
	self.MountId = newId
	self.MountModel = newModel
	-- Reparent out of its segment folder so track recycling never destroys
	-- the Brainrot the player is actively riding.
	self.MountModel.Parent = self.Track.Folder
	self.ElapsedOnMount = 0
	self.CaptureFired = false

	local data = self:_currentData()
	if self.Callbacks.OnMountChanged then
		self.Callbacks.OnMountChanged(data, self.CapturedSet[newId] == true)
	end
end

function BrainrotRidingController:RequestJump()
	if not self.Active then
		return
	end

	local data = self:_currentData()
	local laneRange = (data and data.Special == "GlideJump") and JUMP_LANE_RANGE_GLIDE or JUMP_LANE_RANGE
	local forwardRange = (data and data.Special == "GlideJump") and JUMP_FORWARD_RANGE_GLIDE or JUMP_FORWARD_RANGE

	-- TrackBuilder stores NPCs by lane index; filter by continuous X distance
	-- here instead since the rider moves along a continuous X, not lanes.
	local target, bestDist = nil, math.huge
	local currentIndex = self.Track:GetCurrentIndex(self.MountZ)
	for i = currentIndex - 1, currentIndex + 2 do
		local segment = self.Track.Segments[i]
		if segment then
			for _, candidate in ipairs(segment.NPCs) do
				if candidate.Active and candidate.Model.Parent then
					local candidateX = TrackBuilder.LANE_X[candidate.Lane]
					local zDist = self.MountZ - candidate.Z
					if math.abs(candidateX - self.MountX) <= laneRange and zDist <= forwardRange and zDist >= -6 then
						local dist = math.abs(zDist)
						if dist < bestDist then
							bestDist = dist
							target = candidate
						end
					end
				end
			end
		end
	end

	self.HopUntil = self.RunTime + JUMP_HOP_DURATION

	if target then
		target.Active = false
		local model = target.Model
		self:_swapMount(target.BrainrotId, model)
		Remotes.JumpBrainrot:FireServer(target.BrainrotId)
	end
end

function BrainrotRidingController:_handleCollisions(dt)
	local hopping = self.RunTime < self.HopUntil
	local lane = self.MountX < -6 and 1 or (self.MountX > 6 and 3 or 2)
	local obstacle = self.Track:GetObstacleAt(lane, self.MountZ, Z_COLLIDE_TOLERANCE)
	if not obstacle then
		return false
	end
	if math.abs(obstacle.Part.Position.X - self.MountX) > X_COLLIDE_WIDTH then
		return false
	end

	local data = self:_currentData()

	if obstacle.Breakable and data and data.Special == "SmashObstacles" then
		obstacle.Part:Destroy()
		if self.Callbacks.OnSmash then
			self.Callbacks.OnSmash()
		end
		return false
	end

	if hopping then
		return false
	end

	return true -- crash
end

function BrainrotRidingController:_updateCapture(dt)
	local data = self:_currentData()
	if not data then
		return
	end
	if self.CapturedSet[self.MountId] then
		if self.Callbacks.OnCaptureProgress then
			self.Callbacks.OnCaptureProgress(nil, data)
		end
		return
	end

	local progress = math.clamp(self.ElapsedOnMount / data.CaptureTime, 0, 1)
	if self.Callbacks.OnCaptureProgress then
		self.Callbacks.OnCaptureProgress(progress, data)
	end

	if progress >= 1 and not self.CaptureFired then
		self.CaptureFired = true
		Remotes.CaptureBrainrot:FireServer(self.MountId)
	end
end

function BrainrotRidingController:_extraDrift(dt)
	local data = self:_currentData()
	if not data then
		return 0
	end
	if data.Special == "ErraticWobble" then
		return math.sin(self.RunTime * 3.2) * 9 * dt
	elseif data.Special == "ErraticCoinBonus" then
		if math.random() < 0.02 then
			return (math.random() - 0.5) * 6
		end
	end
	return 0
end

function BrainrotRidingController:_step(dt)
	self.RunTime += dt
	self.ElapsedOnMount += dt

	self.MountX += self.SteerAxis * (STEER_BASE_SPEED + (self:_currentData().Handling * STEER_HANDLING_SCALE)) * dt
	self.MountX += self:_extraDrift(dt)
	self.MountX = math.clamp(self.MountX, X_MIN, X_MAX)

	local speed = self:_computeSpeed(dt)
	local delta = speed * dt
	self.MountZ -= delta
	self.DistanceThisRun += delta
	self.DistanceSinceReport += delta

	self.Track:Update(self.MountZ)

	if self:_handleCollisions(dt) then
		self:_crash("Obstacle")
		return
	end

	local raging = self:_isRaging()
	if raging and self.ElapsedOnMount >= (self:_currentData().RageTime + RAGE_GRACE_TIME) then
		self:_crash("Rage")
		return
	end

	local jitterAmount = 0
	if raging then
		local data = self:_currentData()
		jitterAmount = data.Special == "RageJitter" and 1.4 or 0.5
	end

	local baseCFrame = CFrame.new(self.MountX, TRACK_ORIGIN.Position.Y, self.MountZ)
	local tilt = self.SteerAxis * -12
	BrainrotModelFactory.Animate(self.MountModel, baseCFrame, self.RunTime, {
		BobAmplitude = 0.7,
		BobSpeed = 9,
		Tilt = tilt,
		Jitter = jitterAmount,
	})

	self:_updateCapture(dt)

	if os.clock() - self.LastReportClock >= REPORT_INTERVAL then
		self.LastReportClock = os.clock()
		Remotes.ReportProgress:FireServer({ DeltaDistance = self.DistanceSinceReport })
		self.DistanceSinceReport = 0
	end

	if self.Callbacks.OnTick then
		local data = self:_currentData()
		self.Callbacks.OnTick({
			Distance = self.DistanceThisRun,
			RageMeter = data and math.clamp(self.ElapsedOnMount / (data.RageTime + RAGE_GRACE_TIME), 0, 1) or 0,
			IsRaging = raging,
			BrainrotName = data and data.Name,
			BrainrotRarity = data and data.Rarity,
		})
	end

	self.Camera:Shake(jitterAmount * 0.4)
end

function BrainrotRidingController:_crash(reason)
	self.Active = false
	if self.DistanceSinceReport > 0 then
		Remotes.ReportProgress:FireServer({ DeltaDistance = self.DistanceSinceReport })
		self.DistanceSinceReport = 0
	end
	Remotes.EndRun:FireServer(self.DistanceThisRun)

	if self.HeartbeatConn then
		self.HeartbeatConn:Disconnect()
		self.HeartbeatConn = nil
	end

	if self.Callbacks.OnCrash then
		self.Callbacks.OnCrash(reason, self.DistanceThisRun)
	end

	if self.Track then
		self.Track:Destroy()
		self.Track = nil
	end
	if self.MountModel then
		self.MountModel:Destroy()
		self.MountModel = nil
	end
end

function BrainrotRidingController:StartRun(zoneId, startingBrainrotId)
	if self.Active then
		return
	end

	self.Active = true
	self.MountId = startingBrainrotId
	self.MountX = 0
	self.MountZ = TRACK_ORIGIN.Position.Z
	self.ElapsedOnMount = 0
	self.DistanceThisRun = 0
	self.DistanceSinceReport = 0
	self.RunTime = 0
	self.CaptureFired = false
	self.LastReportClock = os.clock()
	self.SteerAxis = 0

	self.Track = TrackBuilder.new(zoneId, TRACK_ORIGIN)
	self.Track:Update(self.MountZ)

	local data = self:_currentData()
	self.MountModel = BrainrotModelFactory.Create(data, 1)
	self.MountModel:PivotTo(CFrame.new(self.MountX, TRACK_ORIGIN.Position.Y, self.MountZ))
	self.MountModel.Parent = self.Track.Folder

	if self.Callbacks.OnMountChanged then
		self.Callbacks.OnMountChanged(data, self.CapturedSet[self.MountId] == true)
	end

	Remotes.StartRun:FireServer()

	self.Camera:FollowMount(function()
		if not self.MountModel or not self.MountModel.PrimaryPart then
			return nil
		end
		return self.MountModel:GetPivot()
	end)

	self.HeartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if self.Active then
			self:_step(math.min(dt, 0.1))
		end
	end)
end

function BrainrotRidingController:IsActive()
	return self.Active
end

return BrainrotRidingController
