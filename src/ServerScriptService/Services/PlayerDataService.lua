--[[
	PlayerDataService
	Owns loading, caching, autosaving and saving of every player's profile.
	All other services read/write through GetData(player) — nobody else is
	allowed to touch DataStoreService directly.

	Place: ServerScriptService/Services/PlayerDataService.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataService = {}

local store = DataStoreService:GetDataStore("BrainrotStampede_PlayerData_v1")
local sessionCache = {} -- [userId] = profile table
local dirtyFlags = {} -- [userId] = true if unsaved changes exist
local loadedSignalWaiters = {} -- [userId] = {thread, ...}

local AUTOSAVE_INTERVAL = 120
local SAVE_RETRIES = 3

local function defaultProfile()
	return {
		Coins = 0,
		Gems = 0,
		Tokens = 0,
		CapturedBrainrots = {}, -- [brainrotId] = true
		HabitatLevels = {}, -- [brainrotId] = level (>=1 once that Brainrot is captured)
		UnlockedBiomes = { [1] = true },
		MissionProgress = {}, -- [missionId] = { Progress = n, Completed = bool, Claimed = bool }
		Achievements = {},
		Prestige = 0,
		Cosmetics = {},
		Stats = {
			TotalDistance = 0,
			TotalCaptures = 0,
			BestRun = 0,
			TotalCoinsEarned = 0,
			TotalJumps = 0,
		},
		LastIncomeClaim = os.time(),
	}
end

local function deepFillDefaults(profile, defaults)
	for key, value in pairs(defaults) do
		if profile[key] == nil then
			profile[key] = value
		elseif type(value) == "table" and type(profile[key]) == "table" then
			deepFillDefaults(profile[key], value)
		end
	end
	return profile
end

local function loadProfile(userId)
	local success, data
	for attempt = 1, SAVE_RETRIES do
		success, data = pcall(function()
			return store:GetAsync("Player_" .. userId)
		end)
		if success then
			break
		end
		task.wait(2 * attempt)
	end

	if not success then
		warn(("PlayerDataService: failed to load data for %d after retries"):format(userId))
		return defaultProfile()
	end

	if data == nil then
		return defaultProfile()
	end

	return deepFillDefaults(data, defaultProfile())
end

local function saveProfile(userId, profile)
	local success, err
	for attempt = 1, SAVE_RETRIES do
		success, err = pcall(function()
			store:SetAsync("Player_" .. userId, profile)
		end)
		if success then
			dirtyFlags[userId] = false
			return true
		end
		task.wait(2 * attempt)
	end
	warn(("PlayerDataService: failed to save data for %d: %s"):format(userId, tostring(err)))
	return false
end

function PlayerDataService.GetData(player)
	return sessionCache[player.UserId]
end

function PlayerDataService.WaitForData(player)
	local profile = sessionCache[player.UserId]
	if profile then
		return profile
	end
	local thread = coroutine.running()
	loadedSignalWaiters[player.UserId] = loadedSignalWaiters[player.UserId] or {}
	table.insert(loadedSignalWaiters[player.UserId], thread)
	return coroutine.yield()
end

function PlayerDataService.MarkDirty(player)
	dirtyFlags[player.UserId] = true
end

function PlayerDataService.Save(player)
	local profile = sessionCache[player.UserId]
	if profile then
		saveProfile(player.UserId, profile)
	end
end

local function onPlayerAdded(player)
	local profile = loadProfile(player.UserId)
	sessionCache[player.UserId] = profile
	dirtyFlags[player.UserId] = false

	local waiters = loadedSignalWaiters[player.UserId]
	if waiters then
		for _, thread in ipairs(waiters) do
			task.spawn(function()
				local ok, err = coroutine.resume(thread, profile)
				if not ok then
					warn("PlayerDataService waiter resume error:", err)
				end
			end)
		end
		loadedSignalWaiters[player.UserId] = nil
	end
end

local function onPlayerRemoving(player)
	local profile = sessionCache[player.UserId]
	if profile then
		saveProfile(player.UserId, profile)
	end
	sessionCache[player.UserId] = nil
	dirtyFlags[player.UserId] = nil
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				if dirtyFlags[player.UserId] then
					saveProfile(player.UserId, sessionCache[player.UserId])
				end
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = sessionCache[player.UserId]
			if profile then
				saveProfile(player.UserId, profile)
			end
		end
	end)
end

return PlayerDataService
