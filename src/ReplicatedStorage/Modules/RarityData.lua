--[[
	RarityData
	Central definition of every rarity tier used across the game:
	Brainrot collection, capture VFX, spawn weighting and UI badge colors.
	Place: ReplicatedStorage/Modules/RarityData.lua (ModuleScript)
]]

local RarityData = {}

RarityData.Order = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

RarityData.Info = {
	Common = {
		Color = Color3.fromRGB(176, 190, 197),
		AuraColor = Color3.fromRGB(255, 255, 255),
		Weight = 100,
		Effect = "Simple",
		CaptureShake = 0,
	},
	Uncommon = {
		Color = Color3.fromRGB(96, 200, 120),
		AuraColor = Color3.fromRGB(96, 220, 120),
		Weight = 55,
		Effect = "Simple",
		CaptureShake = 0.1,
	},
	Rare = {
		Color = Color3.fromRGB(66, 160, 245),
		AuraColor = Color3.fromRGB(80, 200, 255),
		Weight = 25,
		Effect = "Aura",
		CaptureShake = 0.2,
	},
	Epic = {
		Color = Color3.fromRGB(160, 80, 235),
		AuraColor = Color3.fromRGB(190, 90, 255),
		Weight = 10,
		Effect = "Energy",
		CaptureShake = 0.35,
	},
	Legendary = {
		Color = Color3.fromRGB(255, 195, 40),
		AuraColor = Color3.fromRGB(255, 215, 60),
		Weight = 4,
		Effect = "GoldExplosion",
		CaptureShake = 0.55,
	},
	Mythic = {
		Color = Color3.fromRGB(255, 80, 190),
		AuraColor = Color3.fromRGB(150, 220, 255),
		Weight = 1.2,
		Effect = "Cosmic",
		CaptureShake = 0.75,
	},
	Secret = {
		Color = Color3.fromRGB(20, 20, 20),
		AuraColor = Color3.fromRGB(255, 0, 60),
		Weight = 0.1,
		Effect = "Cinematic",
		CaptureShake = 1,
	},
}

function RarityData.GetInfo(rarityName)
	return RarityData.Info[rarityName] or RarityData.Info.Common
end

return RarityData
