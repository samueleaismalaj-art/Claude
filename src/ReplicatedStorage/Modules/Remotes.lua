--[[
	Remotes
	Single source of truth for every RemoteEvent/RemoteFunction the game
	uses. The server creates them the first time this module is required;
	the client just waits for them. Requiring this module from either side
	always returns the same live instances, so no other script has to
	worry about creation order.

	Place: ReplicatedStorage/Modules/Remotes.lua (ModuleScript)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local EVENT_NAMES = {
	"StartRun",        -- client -> server: request to begin a run
	"EndRun",          -- client -> server: report a crash/end
	"JumpBrainrot",    -- client -> server: attempt to jump onto a nearby Brainrot
	"CaptureBrainrot", -- client -> server: report capture-bar completion
	"ReportProgress",  -- client -> server: periodic distance/coin heartbeat (anti-cheat checked)
	"RunStateChanged",  -- server -> client: authoritative run state push (mount, rage, distance, coins)
	"CaptureResult",   -- server -> client: capture succeeded/failed + Brainrot id
	"ClaimReward",     -- client -> server: claim passive income / daily reward
	"UpgradeHabitat",  -- client -> server: spend coins to upgrade a habitat
	"PurchaseItem",    -- client -> server: shop / gamepass purchase stub
	"MissionUpdate",   -- server -> client: push mission progress changes
	"DataUpdated",     -- server -> client: push full player data snapshot
	"NotifyEvent",     -- server -> client: toast-style notifications (event start, boss, etc.)
}

local FUNCTION_NAMES = {
	"GetPlayerData", -- client -> server: request full profile snapshot on join
}

local function getOrCreateFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		if RunService:IsServer() then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		else
			folder = ReplicatedStorage:WaitForChild("Remotes", 10)
		end
	end
	return folder
end

local folder = getOrCreateFolder()

for _, name in ipairs(EVENT_NAMES) do
	local instance = folder:FindFirstChild(name)
	if not instance then
		if RunService:IsServer() then
			instance = Instance.new("RemoteEvent")
			instance.Name = name
			instance.Parent = folder
		else
			instance = folder:WaitForChild(name, 10)
		end
	end
	Remotes[name] = instance
end

for _, name in ipairs(FUNCTION_NAMES) do
	local instance = folder:FindFirstChild(name)
	if not instance then
		if RunService:IsServer() then
			instance = Instance.new("RemoteFunction")
			instance.Name = name
			instance.Parent = folder
		else
			instance = folder:WaitForChild(name, 10)
		end
	end
	Remotes[name] = instance
end

return Remotes
