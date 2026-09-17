--[[
	MissionService
	Tracks progress on the Version 1 mission set (MissionData.ActiveSetV1),
	notifies the client on every change, and pays out rewards on claim.

	Place: ServerScriptService/Services/MissionService.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MissionData = require(ReplicatedStorage.Modules.MissionData)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local MissionService = {}

local PlayerDataService, EconomyService, AntiCheatService

local function ensureProgress(profile)
	for _, missionId in ipairs(MissionData.ActiveSetV1) do
		if not profile.MissionProgress[missionId] then
			profile.MissionProgress[missionId] = { Progress = 0, Completed = false, Claimed = false }
		end
	end
end

local function pushMissions(player)
	local profile = PlayerDataService.GetData(player)
	if not profile then
		return
	end
	Remotes.MissionUpdate:FireClient(player, profile.MissionProgress)
end

local function completeIfReady(entry, mission)
	if not entry.Completed and entry.Progress >= mission.Target then
		entry.Completed = true
	end
end

-- eventType: "RunStarted" | "RideDifferentBrainrots" | "TravelDistance"
--          | "CollectCoins" | "CaptureNew" | "ChainJumps" | "DiscoverRarity"
function MissionService.OnEvent(player, eventType, payload)
	local profile = PlayerDataService.GetData(player)
	if not profile then
		return
	end
	ensureProgress(profile)

	local changed = false

	for _, missionId in ipairs(MissionData.ActiveSetV1) do
		local mission = MissionData.Get(missionId)
		local entry = profile.MissionProgress[missionId]
		if entry.Completed then
			continue
		end

		if eventType == "RunStarted" and mission.PerRun then
			entry.Progress = 0
			changed = true
		elseif mission.Type == eventType then
			if eventType == "RideDifferentBrainrots" or eventType == "ChainJumps" then
				entry.Progress = math.max(entry.Progress, payload.Count)
				changed = true
			elseif eventType == "TravelDistance" or eventType == "CollectCoins" then
				entry.Progress += payload.Amount
				changed = true
			elseif eventType == "CaptureNew" then
				entry.Progress += 1
				changed = true
			elseif eventType == "DiscoverRarity" then
				if payload.RarityIndex >= (mission.MinRarityIndex or 1) then
					entry.Progress += 1
					changed = true
				end
			end
			completeIfReady(entry, mission)
		end
	end

	if changed then
		PlayerDataService.MarkDirty(player)
		pushMissions(player)
	end
end

local function onClaimReward(player, rewardType, missionId)
	if AntiCheatService.IsRateLimited(player, "ClaimReward") then
		return
	end
	if rewardType ~= "Mission" then
		return
	end
	local profile = PlayerDataService.GetData(player)
	if not profile then
		return
	end
	local mission = MissionData.Get(missionId)
	local entry = profile.MissionProgress[missionId]
	if not mission or not entry then
		return
	end
	if not entry.Completed or entry.Claimed then
		return
	end

	entry.Claimed = true
	PlayerDataService.MarkDirty(player)

	if mission.RewardCoins and mission.RewardCoins > 0 then
		EconomyService.AddCoins(player, mission.RewardCoins, "MissionReward")
	end
	if mission.RewardGems and mission.RewardGems > 0 then
		EconomyService.AddGems(player, mission.RewardGems)
	end

	pushMissions(player)
end

function MissionService.Init(services)
	PlayerDataService = services.PlayerDataService
	EconomyService = services.EconomyService
	AntiCheatService = services.AntiCheatService

	Remotes.ClaimReward.OnServerEvent:Connect(onClaimReward)
end

return MissionService
