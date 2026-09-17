--[[
	MissionData
	Mission templates. MissionService picks 5 active missions for Version 1
	(a fixed daily-style set); the pool is larger so later versions can
	rotate 3 fresh missions per day without new code.

	Place: ReplicatedStorage/Modules/MissionData.lua (ModuleScript)

	Type reference (matched against events raised by RunManagerService):
		RideDifferentBrainrots  ride N distinct Brainrots in a single run
		TravelDistance          cumulative lifetime distance in studs
		CaptureNew              capture N new (never-owned) Brainrots
		ChainJumps              N consecutive jumps in one run without crashing
		CollectCoins            cumulative lifetime coins earned
]]

local MissionData = {}

MissionData.Pool = {
	{
		Id = "Ride5Different",
		Description = "Ride 5 different Brainrots in one run",
		Type = "RideDifferentBrainrots",
		Target = 5,
		PerRun = true,
		RewardCoins = 150,
		RewardGems = 0,
	},
	{
		Id = "Travel2000",
		Description = "Travel 2,000 studs",
		Type = "TravelDistance",
		Target = 2000,
		PerRun = false,
		RewardCoins = 200,
		RewardGems = 0,
	},
	{
		Id = "CaptureOneNew",
		Description = "Capture a new Brainrot",
		Type = "CaptureNew",
		Target = 1,
		PerRun = false,
		RewardCoins = 175,
		RewardGems = 1,
	},
	{
		Id = "Chain10Jumps",
		Description = "Jump between 10 Brainrots without crashing",
		Type = "ChainJumps",
		Target = 10,
		PerRun = true,
		RewardCoins = 250,
		RewardGems = 1,
	},
	{
		Id = "Collect500Coins",
		Description = "Collect 500 coins",
		Type = "CollectCoins",
		Target = 500,
		PerRun = false,
		RewardCoins = 100,
		RewardGems = 0,
	},
	{
		Id = "RideCrocodilo30",
		Description = "Ride Croco Bro for 30 seconds",
		Type = "RideSpecificDuration",
		BrainrotId = "CrocoBro",
		Target = 30,
		PerRun = true,
		RewardCoins = 180,
		RewardGems = 0,
	},
	{
		Id = "DiscoverOneRare",
		Description = "Discover one Uncommon or better Brainrot",
		Type = "DiscoverRarity",
		MinRarityIndex = 2,
		Target = 1,
		PerRun = false,
		RewardCoins = 220,
		RewardGems = 1,
	},
}

-- Fixed 5-mission set for Version 1. Later versions can randomly sample
-- MissionData.Pool per player/day instead of using this constant.
MissionData.ActiveSetV1 = {
	"Ride5Different",
	"Travel2000",
	"CaptureOneNew",
	"Chain10Jumps",
	"Collect500Coins",
}

function MissionData.Get(id)
	for _, mission in ipairs(MissionData.Pool) do
		if mission.Id == id then
			return mission
		end
	end
	return nil
end

return MissionData
