--[[
	CameraController (client-only)
	Third-person chase camera. On Brainrot Island the camera behaves like
	a normal Roblox follow camera (player walks around with default
	controls). During a run it switches to Scriptable and chases whatever
	Brainrot the player currently rides, with a lightweight shake/punch API
	for captures, rare spawns, biome transitions and near misses.

	Place: StarterPlayer/StarterPlayerScripts/CameraController.lua (ModuleScript)
	Required by: StarterPlayerScripts/Main.client.lua
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CameraController = {}
CameraController.__index = CameraController

local BASE_OFFSET = Vector3.new(0, 8, 16)

function CameraController.new()
	local self = setmetatable({}, CameraController)
	self.Camera = Workspace.CurrentCamera
	self.Connection = nil
	self.ShakeIntensity = 0
	self.ShakeDecay = 4
	self.SmoothPosition = nil
	self.SmoothLook = nil
	return self
end

function CameraController:FollowCharacter()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self.Camera.CameraType = Enum.CameraType.Custom
	local character = Players.LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self.Camera.CameraSubject = humanoid
		end
	end
end

function CameraController:Shake(intensity)
	self.ShakeIntensity = math.max(self.ShakeIntensity, intensity)
end

function CameraController:FollowMount(getMountCFrame)
	if self.Connection then
		self.Connection:Disconnect()
	end
	self.Camera.CameraType = Enum.CameraType.Scriptable
	self.SmoothPosition = nil
	self.SmoothLook = nil

	self.Connection = RunService.RenderStepped:Connect(function(dt)
		local mountCFrame = getMountCFrame()
		if not mountCFrame then
			return
		end

		local desiredPos = mountCFrame:PointToWorldSpace(BASE_OFFSET)
		local lookAt = mountCFrame.Position + mountCFrame.LookVector * -6 + Vector3.new(0, 3, 0)

		self.SmoothPosition = self.SmoothPosition and self.SmoothPosition:Lerp(desiredPos, math.clamp(dt * 6, 0, 1)) or desiredPos
		self.SmoothLook = self.SmoothLook and self.SmoothLook:Lerp(lookAt, math.clamp(dt * 8, 0, 1)) or lookAt

		local shakeOffset = Vector3.new(0, 0, 0)
		if self.ShakeIntensity > 0.01 then
			shakeOffset = Vector3.new(
				(math.random() - 0.5) * self.ShakeIntensity,
				(math.random() - 0.5) * self.ShakeIntensity,
				0
			)
			self.ShakeIntensity = math.max(0, self.ShakeIntensity - self.ShakeDecay * dt)
		end

		self.Camera.CFrame = CFrame.lookAt(self.SmoothPosition + shakeOffset, self.SmoothLook + shakeOffset)
	end)
end

function CameraController:Stop()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

return CameraController
