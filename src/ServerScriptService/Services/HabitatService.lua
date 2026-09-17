--[[
	HabitatService
	Handles Brainrot Island habitat upgrades. A habitat only exists (level
	>= 1) once its Brainrot has been captured at least once, per the
	UpgradeData level-1 effect ("unlocks the habitat").

	Place: ServerScriptService/Services/HabitatService.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local EconomyData = require(ReplicatedStorage.Modules.EconomyData)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local HabitatService = {}

local PlayerDataService, EconomyService, AntiCheatService

local function pushSnapshot(player)
	local profile = PlayerDataService.GetData(player)
	if profile then
		Remotes.DataUpdated:FireClient(player, profile)
	end
end

local function onUpgradeHabitat(player, brainrotId)
	if AntiCheatService.IsRateLimited(player, "UpgradeHabitat") then
		return
	end
	local profile = PlayerDataService.GetData(player)
	if not profile then
		return
	end
	if not profile.CapturedBrainrots[brainrotId] then
		return
	end
	if not BrainrotData.Get(brainrotId) then
		return
	end

	local currentLevel = profile.HabitatLevels[brainrotId] or 1
	local cost = EconomyData.GetHabitatUpgradeCost(currentLevel)
	if cost == nil then
		return -- already max level
	end

	if not EconomyService.SpendCoins(player, cost) then
		return
	end

	profile.HabitatLevels[brainrotId] = currentLevel + 1
	PlayerDataService.MarkDirty(player)
	pushSnapshot(player)
end

function HabitatService.Init(services)
	PlayerDataService = services.PlayerDataService
	EconomyService = services.EconomyService
	AntiCheatService = services.AntiCheatService

	Remotes.UpgradeHabitat.OnServerEvent:Connect(onUpgradeHabitat)
end

return HabitatService
