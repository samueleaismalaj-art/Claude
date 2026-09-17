--[[
	BiomeService
	Checks BiomeData unlock requirements against a player's profile. Version
	1 only ever has Zone 1 (Brainrot Plains) built, but this evaluates the
	full progression table so Versions 2-4 can flip `Implemented = true`
	on later zones without writing new unlock logic.

	Place: ServerScriptService/Services/BiomeService.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BiomeData = require(ReplicatedStorage.Modules.BiomeData)
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)

local BiomeService = {}

local PlayerDataService

local function countRareCaptures(profile)
	local count = 0
	for brainrotId in pairs(profile.CapturedBrainrots) do
		local data = BrainrotData.Get(brainrotId)
		if data and data.Rarity ~= "Common" then
			count += 1
		end
	end
	return count
end

local function countCompletedMissions(profile)
	local count = 0
	for _, entry in pairs(profile.MissionProgress) do
		if entry.Completed then
			count += 1
		end
	end
	return count
end

local function countUpgradedHabitats(profile)
	local count = 0
	for _, level in pairs(profile.HabitatLevels) do
		if level > 1 then
			count += 1
		end
	end
	return count
end

local function meetsRequirement(profile, requirement)
	if requirement.Type == "Free" then
		return true
	elseif requirement.Type == "CaptureCount" then
		local count = 0
		for _ in pairs(profile.CapturedBrainrots) do
			count += 1
		end
		return count >= requirement.Amount
	elseif requirement.Type == "MissionsCompleted" then
		return countCompletedMissions(profile) >= requirement.Amount
	elseif requirement.Type == "HabitatsUpgraded" then
		return countUpgradedHabitats(profile) >= requirement.Amount
	elseif requirement.Type == "RareCaptures" then
		return countRareCaptures(profile) >= requirement.Amount
	elseif requirement.Type == "DistanceMilestone" then
		return profile.Stats.TotalDistance >= requirement.Amount
	elseif requirement.Type == "TotalBrainrotsOwned" then
		local count = 0
		for _ in pairs(profile.CapturedBrainrots) do
			count += 1
		end
		return count >= requirement.Amount
	elseif requirement.Type == "QuestChain" then
		return false -- reserved for Version 4
	end
	return false
end

function BiomeService.RefreshUnlocks(player)
	local profile = PlayerDataService.GetData(player)
	if not profile then
		return
	end

	local unlockedAny = false
	for _, zone in ipairs(BiomeData.Zones) do
		if zone.Implemented and not profile.UnlockedBiomes[zone.Id] then
			if meetsRequirement(profile, zone.UnlockRequirement) then
				profile.UnlockedBiomes[zone.Id] = true
				unlockedAny = true
			end
		end
	end

	if unlockedAny then
		PlayerDataService.MarkDirty(player)
	end
	return unlockedAny
end

function BiomeService.IsBiomeUnlocked(player, zoneId)
	local profile = PlayerDataService.GetData(player)
	return profile ~= nil and profile.UnlockedBiomes[zoneId] == true
end

function BiomeService.Init(services)
	PlayerDataService = services.PlayerDataService
end

return BiomeService
