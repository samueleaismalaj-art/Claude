--[[
	RunManagerService
	Owns the authoritative side of a run: current mount, distance, coins,
	capture validation and run end. The client simulates movement locally
	for responsiveness (steering/jumping feel instant) and streams deltas
	here; this service clamps everything through AntiCheatService before it
	ever touches a player's saved profile.

	Place: ServerScriptService/Services/RunManagerService.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local EconomyData = require(ReplicatedStorage.Modules.EconomyData)
local UpgradeData = require(ReplicatedStorage.Modules.UpgradeData)
local RarityData = require(ReplicatedStorage.Modules.RarityData)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local RunManagerService = {}

local PlayerDataService, EconomyService, MissionService, BrainrotSpawner, AntiCheatService

local runStates = {} -- [userId] = state table

local CAPTURE_TIME_TOLERANCE = 0.75 -- seconds of slack allowed for latency

local function newRunState()
	return {
		Active = false,
		Zone = 1,
		CurrentMountId = nil,
		MountStartTime = 0,
		DistanceThisRun = 0,
		CoinsThisRun = 0,
		RiddenBrainrotsThisRun = {},
		RiddenCountThisRun = 0,
		JumpChain = 0,
		LastReportTime = os.clock(),
	}
end

local function pushRunState(player)
	local state = runStates[player.UserId]
	if state then
		Remotes.RunStateChanged:FireClient(player, {
			Active = state.Active,
			CurrentMountId = state.CurrentMountId,
			DistanceThisRun = state.DistanceThisRun,
			CoinsThisRun = state.CoinsThisRun,
			JumpChain = state.JumpChain,
		})
	end
end

local function onStartRun(player)
	if AntiCheatService.IsRateLimited(player, "StartRun") then
		return
	end
	local profile = PlayerDataService.GetData(player)
	if not profile then
		return
	end

	local state = newRunState()
	state.Active = true
	state.CurrentMountId = BrainrotSpawner.GetStartingBrainrotId()
	state.MountStartTime = os.clock()
	state.RiddenBrainrotsThisRun[state.CurrentMountId] = true
	state.RiddenCountThisRun = 1
	runStates[player.UserId] = state

	MissionService.OnEvent(player, "RunStarted", {})
	MissionService.OnEvent(player, "RideDifferentBrainrots", { Count = state.RiddenCountThisRun })

	pushRunState(player)
end

local function onReportProgress(player, payload)
	if AntiCheatService.IsRateLimited(player, "ReportProgress") then
		return
	end
	local state = runStates[player.UserId]
	local profile = PlayerDataService.GetData(player)
	if not state or not state.Active or not profile then
		return
	end
	if type(payload) ~= "table" then
		return
	end

	local now = os.clock()
	local dt = math.clamp(now - state.LastReportTime, 0.01, 2)
	state.LastReportTime = now

	local mountData = BrainrotData.Get(state.CurrentMountId)
	if not mountData then
		return
	end

	local safeDelta = AntiCheatService.ClampDistanceDelta(state.CurrentMountId, payload.DeltaDistance, dt)
	if safeDelta <= 0 then
		return
	end

	state.DistanceThisRun += safeDelta
	profile.Stats.TotalDistance += safeDelta

	local coinsEarned = math.floor(safeDelta * EconomyData.CoinsPerStud * mountData.CoinMultiplier)
	if coinsEarned > 0 then
		state.CoinsThisRun += coinsEarned
		EconomyService.AddCoins(player, coinsEarned, "Distance")
	end

	PlayerDataService.MarkDirty(player)
	MissionService.OnEvent(player, "TravelDistance", { Amount = safeDelta })
	if coinsEarned > 0 then
		MissionService.OnEvent(player, "CollectCoins", { Amount = coinsEarned })
	end

	pushRunState(player)
end

local function onJumpBrainrot(player, targetBrainrotId)
	if AntiCheatService.IsRateLimited(player, "JumpBrainrot") then
		return
	end
	local state = runStates[player.UserId]
	if not state or not state.Active then
		return
	end
	if type(targetBrainrotId) ~= "string" then
		return
	end
	if not BrainrotSpawner.IsValidSpawnForZone(targetBrainrotId, state.Zone) then
		return
	end

	state.CurrentMountId = targetBrainrotId
	state.MountStartTime = os.clock()
	state.JumpChain += 1

	if not state.RiddenBrainrotsThisRun[targetBrainrotId] then
		state.RiddenBrainrotsThisRun[targetBrainrotId] = true
		state.RiddenCountThisRun += 1
	end

	local profile = PlayerDataService.GetData(player)
	if profile then
		profile.Stats.TotalJumps += 1
		PlayerDataService.MarkDirty(player)
	end

	MissionService.OnEvent(player, "RideDifferentBrainrots", { Count = state.RiddenCountThisRun })
	MissionService.OnEvent(player, "ChainJumps", { Count = state.JumpChain })

	pushRunState(player)
end

local function onCaptureBrainrot(player, brainrotId)
	if AntiCheatService.IsRateLimited(player, "CaptureBrainrot") then
		return
	end
	local state = runStates[player.UserId]
	local profile = PlayerDataService.GetData(player)
	if not state or not state.Active or not profile then
		return
	end
	if brainrotId ~= state.CurrentMountId then
		Remotes.CaptureResult:FireClient(player, { Success = false, Reason = "NotCurrentMount" })
		return
	end

	local data = BrainrotData.Get(brainrotId)
	if not data then
		return
	end

	local existingLevel = profile.HabitatLevels[brainrotId]
	local tameEase = 0
	if existingLevel then
		local levelInfo = UpgradeData.GetLevelInfo(existingLevel)
		tameEase = levelInfo and levelInfo.TameEaseBonus or 0
	end
	local requiredTime = data.CaptureTime * (1 - tameEase)

	local elapsed = os.clock() - state.MountStartTime
	if elapsed + CAPTURE_TIME_TOLERANCE < requiredTime then
		Remotes.CaptureResult:FireClient(player, { Success = false, Reason = "TooSoon" })
		return
	end

	local isNew = not profile.CapturedBrainrots[brainrotId]
	if isNew then
		profile.CapturedBrainrots[brainrotId] = true
		profile.HabitatLevels[brainrotId] = 1
		profile.Stats.TotalCaptures += 1

		local rarityBonus = EconomyData.CaptureRarityBonus[data.Rarity] or 0
		EconomyService.AddCoins(player, EconomyData.CaptureBaseReward + rarityBonus, "Capture")

		local rarityIndex = table.find(RarityData.Order, data.Rarity) or 1
		MissionService.OnEvent(player, "CaptureNew", { BrainrotId = brainrotId })
		MissionService.OnEvent(player, "DiscoverRarity", { RarityIndex = rarityIndex })
	else
		EconomyService.AddCoins(player, math.floor(EconomyData.CaptureBaseReward * 0.25), "RecaptureBonus")
	end

	PlayerDataService.MarkDirty(player)
	Remotes.CaptureResult:FireClient(player, {
		Success = true,
		BrainrotId = brainrotId,
		IsNew = isNew,
		Rarity = data.Rarity,
		Name = data.Name,
	})
end

local function finalizeRun(player)
	local state = runStates[player.UserId]
	local profile = PlayerDataService.GetData(player)
	if not state or not profile then
		return
	end

	state.Active = false
	if state.DistanceThisRun > profile.Stats.BestRun then
		profile.Stats.BestRun = math.floor(state.DistanceThisRun)
	end
	PlayerDataService.MarkDirty(player)
	pushRunState(player)
end

local function onEndRun(player)
	if AntiCheatService.IsRateLimited(player, "EndRun") then
		return
	end
	finalizeRun(player)
end

function RunManagerService.GetRunState(player)
	return runStates[player.UserId]
end

function RunManagerService.Init(services)
	PlayerDataService = services.PlayerDataService
	EconomyService = services.EconomyService
	MissionService = services.MissionService
	BrainrotSpawner = services.BrainrotSpawner
	AntiCheatService = services.AntiCheatService

	Remotes.StartRun.OnServerEvent:Connect(onStartRun)
	Remotes.ReportProgress.OnServerEvent:Connect(onReportProgress)
	Remotes.JumpBrainrot.OnServerEvent:Connect(onJumpBrainrot)
	Remotes.CaptureBrainrot.OnServerEvent:Connect(onCaptureBrainrot)
	Remotes.EndRun.OnServerEvent:Connect(onEndRun)

	Players.PlayerRemoving:Connect(function(player)
		runStates[player.UserId] = nil
	end)
end

return RunManagerService
