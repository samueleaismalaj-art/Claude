--[[
	Main
	Server bootstrap. Requires every Service ModuleScript under
	ServerScriptService/Services, initializes them in dependency order, and
	wires the two cross-cutting hooks (initial data push, GetPlayerData
	RemoteFunction) that don't belong to any single service.

	Place: ServerScriptService/Main.server.lua (Script)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Remotes)

local Services = script.Parent:WaitForChild("Services")

local PlayerDataService = require(Services.PlayerDataService)
local AntiCheatService = require(Services.AntiCheatService)
local BrainrotSpawner = require(Services.BrainrotSpawner)
local EconomyService = require(Services.EconomyService)
local MissionService = require(Services.MissionService)
local HabitatService = require(Services.HabitatService)
local BiomeService = require(Services.BiomeService)
local RunManagerService = require(Services.RunManagerService)
local MapBuilder = require(Services.MapBuilder)

MapBuilder.Init()
PlayerDataService.Init()
AntiCheatService.Init()
BrainrotSpawner.Init()

local serviceRefs = {
	PlayerDataService = PlayerDataService,
	AntiCheatService = AntiCheatService,
	BrainrotSpawner = BrainrotSpawner,
}

EconomyService.Init(serviceRefs)
serviceRefs.EconomyService = EconomyService

MissionService.Init(serviceRefs)
serviceRefs.MissionService = MissionService

HabitatService.Init(serviceRefs)
BiomeService.Init(serviceRefs)
RunManagerService.Init(serviceRefs)

Remotes.GetPlayerData.OnServerInvoke = function(player)
	return PlayerDataService.WaitForData(player)
end

local function onPlayerReady(player)
	local profile = PlayerDataService.WaitForData(player)
	BiomeService.RefreshUnlocks(player)
	Remotes.DataUpdated:FireClient(player, profile)
	Remotes.MissionUpdate:FireClient(player, profile.MissionProgress)
end

Players.PlayerAdded:Connect(onPlayerReady)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerReady, player)
end

print("Brainrot Stampede: server systems online.")
