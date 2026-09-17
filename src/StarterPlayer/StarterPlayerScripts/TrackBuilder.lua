--[[
	TrackBuilder (client-only)
	Builds and recycles the endless Brainrot Plains run track for the
	LOCAL player only. Instances created here are parented under Workspace
	from a LocalScript context, which means Roblox never replicates them
	to the server or to other clients — each player's run is a private,
	client-rendered lane, which is what makes an endless "on-rails" runner
	cheap and simple to build without a full server-authoritative physics
	sim. See README.md "Architecture & Simplifications".

	Place: StarterPlayer/StarterPlayerScripts/TrackBuilder.lua (ModuleScript)
	Required by: StarterPlayerScripts/BrainrotRidingController.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local RarityData = require(ReplicatedStorage.Modules.RarityData)
local BrainrotModelFactory = require(ReplicatedStorage.Modules.BrainrotModelFactory)

local TrackBuilder = {}
TrackBuilder.__index = TrackBuilder

TrackBuilder.LANE_X = { -12, 0, 12 }
TrackBuilder.SEGMENT_LENGTH = 80
local LOOKAHEAD_SEGMENTS = 8
local BEHIND_KEEP_SEGMENTS = 2
local GROUND_COLORS = {
	Color3.fromRGB(96, 205, 120),
	Color3.fromRGB(104, 215, 128),
	Color3.fromRGB(88, 195, 112),
}

local function rollBrainrotForZone(zoneId)
	local candidates = BrainrotData.GetByZone(zoneId)
	if #candidates == 0 then
		return nil
	end
	local totalWeight = 0
	for _, data in ipairs(candidates) do
		totalWeight += RarityData.GetInfo(data.Rarity).Weight
	end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, data in ipairs(candidates) do
		cumulative += RarityData.GetInfo(data.Rarity).Weight
		if roll <= cumulative then
			return data.Id
		end
	end
	return candidates[#candidates].Id
end

function TrackBuilder.new(zoneId, origin)
	local self = setmetatable({}, TrackBuilder)
	self.ZoneId = zoneId
	self.Origin = origin -- CFrame, +Y up, track runs toward -Z
	self.Segments = {} -- [index] = { Folder, Obstacles = {}, NPCs = {} }
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "PrivateTrack"
	self.Folder.Parent = Workspace
	return self
end

function TrackBuilder:_segmentZCenter(index)
	return self.Origin.Position.Z - (index + 0.5) * TrackBuilder.SEGMENT_LENGTH
end

function TrackBuilder:_buildSegment(index)
	if self.Segments[index] then
		return
	end

	local segFolder = Instance.new("Folder")
	segFolder.Name = "Segment_" .. index
	segFolder.Parent = self.Folder

	local zCenter = self:_segmentZCenter(index)

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.CanCollide = false
	ground.Size = Vector3.new(46, 2, TrackBuilder.SEGMENT_LENGTH)
	ground.Position = Vector3.new(self.Origin.Position.X, self.Origin.Position.Y - 3, zCenter)
	ground.Color = GROUND_COLORS[(index % #GROUND_COLORS) + 1]
	ground.Material = Enum.Material.Grass
	ground.Parent = segFolder

	local segment = { Folder = segFolder, Obstacles = {}, NPCs = {} }

	-- Obstacles: 1-2 per segment, never blocking every lane at once.
	local obstacleCount = (index > 1) and math.random(1, 2) or 0
	local blockedLanes = {}
	for _ = 1, obstacleCount do
		local lane = math.random(1, 3)
		if not blockedLanes[lane] then
			blockedLanes[lane] = true
			local z = zCenter + (math.random() - 0.5) * (TrackBuilder.SEGMENT_LENGTH * 0.5)
			local breakable = math.random() < 0.35

			local obstacle = Instance.new("Part")
			obstacle.Name = breakable and "Breakable" or "Blocker"
			obstacle.Anchored = true
			obstacle.CanCollide = false
			obstacle.Size = breakable and Vector3.new(5, 5, 5) or Vector3.new(6, 7, 2)
			obstacle.Position = Vector3.new(self.Origin.Position.X + TrackBuilder.LANE_X[lane], self.Origin.Position.Y + (breakable and 2 or 2.5), z)
			obstacle.Color = breakable and Color3.fromRGB(200, 140, 60) or Color3.fromRGB(150, 60, 60)
			obstacle.Material = breakable and Enum.Material.Wood or Enum.Material.Concrete
			obstacle.Parent = segFolder

			table.insert(segment.Obstacles, { Lane = lane, Z = z, Part = obstacle, Breakable = breakable })
		end
	end

	-- One Brainrot NPC spawn per segment (skip the very first couple so the
	-- run opens with a clear runway).
	if index > 1 then
		local lane = math.random(1, 3)
		local z = zCenter + (math.random() - 0.5) * (TrackBuilder.SEGMENT_LENGTH * 0.3)
		local brainrotId = rollBrainrotForZone(self.ZoneId)
		if brainrotId then
			local data = BrainrotData.Get(brainrotId)
			local model = BrainrotModelFactory.Create(data, 1)
			model:PivotTo(CFrame.new(self.Origin.Position.X + TrackBuilder.LANE_X[lane], self.Origin.Position.Y, z))
			model.Parent = segFolder
			table.insert(segment.NPCs, { Lane = lane, Z = z, BrainrotId = brainrotId, Model = model, Active = true })
		end
	end

	self.Segments[index] = segment
end

function TrackBuilder:_destroySegment(index)
	local segment = self.Segments[index]
	if segment then
		segment.Folder:Destroy()
		self.Segments[index] = nil
	end
end

function TrackBuilder:GetCurrentIndex(mountZ)
	return math.floor((self.Origin.Position.Z - mountZ) / TrackBuilder.SEGMENT_LENGTH)
end

function TrackBuilder:Update(mountZ)
	local currentIndex = self:GetCurrentIndex(mountZ)

	for i = math.max(0, currentIndex - 1), currentIndex + LOOKAHEAD_SEGMENTS do
		self:_buildSegment(i)
	end

	for index in pairs(self.Segments) do
		if index < currentIndex - BEHIND_KEEP_SEGMENTS then
			self:_destroySegment(index)
		end
	end
end

function TrackBuilder:GetObstacleAt(lane, mountZ, tolerance)
	local currentIndex = self:GetCurrentIndex(mountZ)
	for i = currentIndex - 1, currentIndex + 1 do
		local segment = self.Segments[i]
		if segment then
			for _, obstacle in ipairs(segment.Obstacles) do
				if obstacle.Part.Parent and obstacle.Lane == lane and math.abs(obstacle.Z - mountZ) <= tolerance then
					return obstacle
				end
			end
		end
	end
	return nil
end

function TrackBuilder:Destroy()
	self.Folder:Destroy()
	self.Segments = {}
end

return TrackBuilder
