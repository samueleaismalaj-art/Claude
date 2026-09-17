--[[
	BrainrotSpawner
	Server-side authority over "what is allowed to spawn/be captured where".
	The client owns the actual pooled NPC rendering along the track (see
	StarterPlayerScripts/BrainrotRidingController.lua) for responsiveness,
	but every id a client claims to have jumped onto or captured is checked
	against this module first so a modified client can't claim an
	out-of-zone or impossible Brainrot.

	Place: ServerScriptService/Services/BrainrotSpawner.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local RarityData = require(ReplicatedStorage.Modules.RarityData)

local BrainrotSpawner = {}

BrainrotSpawner.StartingBrainrotId = "TralaleroDude"

function BrainrotSpawner.IsValidSpawnForZone(brainrotId, zoneId)
	local data = BrainrotData.Get(brainrotId)
	return data ~= nil and data.Zone == zoneId
end

-- Weighted-random Brainrot id for a zone, honoring RarityData weights.
-- Used by the client to decide what the *next* NPC pool spawn should render,
-- and reusable server-side for future features (e.g. boss rolls) without
-- ever trusting the client's own roll.
function BrainrotSpawner.RollBrainrotForZone(zoneId)
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

function BrainrotSpawner.GetStartingBrainrotId()
	return BrainrotSpawner.StartingBrainrotId
end

function BrainrotSpawner.Init()
	math.randomseed(os.time())
end

return BrainrotSpawner
