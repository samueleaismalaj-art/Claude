--[[
	BrainrotData
	Definition table for every Brainrot in the game. Version 1 ships the
	8 Brainrot Plains characters; later versions append more entries here
	(and to BiomeData) without touching any system code.

	Place: ReplicatedStorage/Modules/BrainrotData.lua (ModuleScript)

	Field reference:
		Id              unique string key, also used as the ride/capture id
		Name            display name
		Rarity          key into RarityData.Info
		Zone            BiomeData zone id this Brainrot natively spawns in
		Speed           base forward studs/second while ridden
		Handling        0-1, how quickly it responds to steering input
		RageTime        seconds ridden before it starts destabilizing
		CaptureTime     seconds standing on an undiscovered Brainrot to tame it
		Special         ability id consumed by BrainrotRidingController
		Habitat         Brainrot Island habitat name
		UpgradeBonus    text shown in Collection UI describing the habitat's payoff
		Description     flavor text
		DiscoveryAnim   discovery pose id consumed by the capture VFX module
		BodyColors      procedural model palette {Primary, Secondary, Accent}
		CoinMultiplier  multiplier applied to coins earned while riding this Brainrot
]]

local BrainrotData = {}

BrainrotData.List = {
	TralaleroDude = {
		Id = "TralaleroDude",
		Name = "Tralalero Dude",
		Rarity = "Common",
		Zone = 1,
		Speed = 34,
		Handling = 0.75,
		RageTime = 14,
		CaptureTime = 3,
		Special = "Balanced",
		Habitat = "Tralalero Beach",
		UpgradeBonus = "Balanced starter income, easiest habitat to max out.",
		Description = "The original chaos icon. Nothing special, everything special.",
		DiscoveryAnim = "Shuffle",
		BodyColors = { Primary = Color3.fromRGB(60, 140, 235), Secondary = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(255, 210, 60) },
		CoinMultiplier = 1,
	},

	EspressoGoblin = {
		Id = "EspressoGoblin",
		Name = "Espresso Goblin",
		Rarity = "Common",
		Zone = 1,
		Speed = 30,
		Handling = 0.6,
		RageTime = 9,
		CaptureTime = 3.5,
		Special = "RageJitter",
		Habitat = "Goblin Espresso Den",
		UpgradeBonus = "Rage-fueled sprints grant a short coin surge on capture.",
		Description = "Drank 14 espressos. Screams. Regrets nothing.",
		DiscoveryAnim = "Screech",
		BodyColors = { Primary = Color3.fromRGB(90, 60, 40), Secondary = Color3.fromRGB(190, 130, 40), Accent = Color3.fromRGB(255, 60, 40) },
		CoinMultiplier = 1.05,
	},

	BananaSigma = {
		Id = "BananaSigma",
		Name = "Banana Sigma",
		Rarity = "Common",
		Zone = 1,
		Speed = 28,
		Handling = 0.65,
		RageTime = 16,
		CaptureTime = 3,
		Special = "SmashObstacles",
		Habitat = "Sigma Gym",
		UpgradeBonus = "Smashes crates for bonus coins without losing speed.",
		Description = "Went to the gym. Became a banana. Never skips leg day.",
		DiscoveryAnim = "Flex",
		BodyColors = { Primary = Color3.fromRGB(255, 221, 51), Secondary = Color3.fromRGB(80, 60, 20), Accent = Color3.fromRGB(255, 255, 255) },
		CoinMultiplier = 1,
	},

	CrocoBro = {
		Id = "CrocoBro",
		Name = "Croco Bro",
		Rarity = "Common",
		Zone = 1,
		Speed = 40,
		Handling = 0.35,
		RageTime = 12,
		CaptureTime = 3.5,
		Special = "FastStraightHardTurn",
		Habitat = "Crocodilo Swamp",
		UpgradeBonus = "Highest base speed on the Plains; rewards precise timing.",
		Description = "Blazing fast. Turns like a school bus. Fear it anyway.",
		DiscoveryAnim = "TailSlam",
		BodyColors = { Primary = Color3.fromRGB(60, 130, 70), Secondary = Color3.fromRGB(220, 230, 150), Accent = Color3.fromRGB(255, 255, 255) },
		CoinMultiplier = 1,
	},

	CappuccinoKid = {
		Id = "CappuccinoKid",
		Name = "Cappuccino Kid",
		Rarity = "Common",
		Zone = 1,
		Speed = 26,
		Handling = 0.7,
		RageTime = 13,
		CaptureTime = 3,
		Special = "AccelerateOverTime",
		Habitat = "Cappuccino Cafe",
		UpgradeBonus = "Late-run speed ramps grant escalating distance bonuses.",
		Description = "Starts slow, ends terrifying. Caffeine hits different.",
		DiscoveryAnim = "Sip",
		BodyColors = { Primary = Color3.fromRGB(200, 160, 110), Secondary = Color3.fromRGB(255, 250, 240), Accent = Color3.fromRGB(120, 80, 40) },
		CoinMultiplier = 1,
	},

	WiFiPigeon = {
		Id = "WiFiPigeon",
		Name = "WiFi Pigeon",
		Rarity = "Common",
		Zone = 1,
		Speed = 30,
		Handling = 0.8,
		RageTime = 15,
		CaptureTime = 3,
		Special = "GlideJump",
		Habitat = "Pigeon Rooftop",
		UpgradeBonus = "Extended glide distance makes gaps trivial to clear.",
		Description = "Steals your WiFi. Also your heart. Mostly your WiFi.",
		DiscoveryAnim = "WingFlap",
		BodyColors = { Primary = Color3.fromRGB(130, 140, 150), Secondary = Color3.fromRGB(230, 230, 235), Accent = Color3.fromRGB(60, 120, 255) },
		CoinMultiplier = 1,
	},

	SpaghettiWarrior = {
		Id = "SpaghettiWarrior",
		Name = "Spaghetti Warrior",
		Rarity = "Uncommon",
		Zone = 1,
		Speed = 32,
		Handling = 0.5,
		RageTime = 10,
		CaptureTime = 4.5,
		Special = "ErraticWobble",
		Habitat = "Spaghetti Kitchen",
		UpgradeBonus = "Wobble dodges give a small chance to ignore one hit per run.",
		Description = "Forged from noodles and rage. Somehow holds a sword.",
		DiscoveryAnim = "SwordTwirl",
		BodyColors = { Primary = Color3.fromRGB(235, 200, 90), Secondary = Color3.fromRGB(190, 40, 40), Accent = Color3.fromRGB(255, 255, 255) },
		CoinMultiplier = 1.1,
	},

	MicrowaveMonkey = {
		Id = "MicrowaveMonkey",
		Name = "Microwave Monkey",
		Rarity = "Uncommon",
		Zone = 1,
		Speed = 29,
		Handling = 0.45,
		RageTime = 8,
		CaptureTime = 4.5,
		Special = "ErraticCoinBonus",
		Habitat = "Monkey Internet Cafe",
		UpgradeBonus = "Highest coin-per-second of any Plains Brainrot.",
		Description = "Heated itself for 3 minutes. Gained sentience and swagger.",
		DiscoveryAnim = "Beep",
		BodyColors = { Primary = Color3.fromRGB(90, 90, 95), Secondary = Color3.fromRGB(50, 200, 120), Accent = Color3.fromRGB(255, 255, 255) },
		CoinMultiplier = 1.25,
	},
}

BrainrotData.Order = {
	"TralaleroDude",
	"EspressoGoblin",
	"BananaSigma",
	"CrocoBro",
	"CappuccinoKid",
	"WiFiPigeon",
	"SpaghettiWarrior",
	"MicrowaveMonkey",
}

function BrainrotData.Get(id)
	return BrainrotData.List[id]
end

function BrainrotData.GetByZone(zoneId)
	local results = {}
	for _, id in ipairs(BrainrotData.Order) do
		local data = BrainrotData.List[id]
		if data.Zone == zoneId then
			table.insert(results, data)
		end
	end
	return results
end

return BrainrotData
