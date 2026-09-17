--[[
	AntiCheatService
	Shared server-side guards. Nothing here is a full physics simulation —
	the client still owns the "feel" of movement for responsiveness — but
	every value that affects currency, progression or captures is clamped
	or rejected here before any other service trusts it.

	Place: ServerScriptService/Services/AntiCheatService.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)

local AntiCheatService = {}

-- Fastest any Brainrot can legitimately travel (base speed * generous headroom
-- for AccelerateOverTime/rage speed multipliers).
local MAX_PLAUSIBLE_STUDS_PER_SEC = 70

local lastRemoteCall = {} -- [userId][remoteName] = os.clock()
local MIN_INTERVALS = {
	ReportProgress = 0.25,
	JumpBrainrot = 0.15,
	CaptureBrainrot = 0.15,
	UpgradeHabitat = 0.3,
	StartRun = 0.5,
	EndRun = 0.2,
	ClaimReward = 0.3,
	PurchaseItem = 0.3,
}

function AntiCheatService.IsRateLimited(player, remoteName)
	local minInterval = MIN_INTERVALS[remoteName] or 0.1
	local userId = player.UserId
	lastRemoteCall[userId] = lastRemoteCall[userId] or {}
	local now = os.clock()
	local last = lastRemoteCall[userId][remoteName]
	if last and (now - last) < minInterval then
		return true
	end
	lastRemoteCall[userId][remoteName] = now
	return false
end

-- Clamps a client-reported distance delta to what the ridden Brainrot could
-- plausibly have covered in dt seconds. Returns the SAFE value to credit.
function AntiCheatService.ClampDistanceDelta(brainrotId, reportedDelta, dt)
	if type(reportedDelta) ~= "number" or reportedDelta ~= reportedDelta or reportedDelta < 0 then
		return 0
	end
	if type(dt) ~= "number" or dt <= 0 then
		return 0
	end

	local data = BrainrotData.Get(brainrotId)
	local speedCap = data and (data.Speed * 2.5) or MAX_PLAUSIBLE_STUDS_PER_SEC
	speedCap = math.min(speedCap, MAX_PLAUSIBLE_STUDS_PER_SEC)

	local maxDelta = speedCap * dt
	return math.min(reportedDelta, maxDelta)
end

function AntiCheatService.CleanupPlayer(player)
	lastRemoteCall[player.UserId] = nil
end

function AntiCheatService.Init()
	local Players = game:GetService("Players")
	Players.PlayerRemoving:Connect(AntiCheatService.CleanupPlayer)
end

return AntiCheatService
