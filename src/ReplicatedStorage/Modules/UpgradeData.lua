--[[
	UpgradeData
	Generic per-level habitat upgrade effects (levels 1-7, per the design doc).
	HabitatService applies these; the Island's HabitatUI reads them to show
	"what you get next".

	Place: ReplicatedStorage/Modules/UpgradeData.lua (ModuleScript)
]]

local UpgradeData = {}

UpgradeData.Levels = {
	[1] = { Description = "Unlocks the habitat for this Brainrot.", CoinBonusPercent = 0, TameEaseBonus = 0, RareChanceBonus = 0 },
	[2] = { Description = "+5% coins from this Brainrot.", CoinBonusPercent = 5, TameEaseBonus = 0, RareChanceBonus = 0 },
	[3] = { Description = "Brainrot becomes easier to tame (-15% capture time).", CoinBonusPercent = 5, TameEaseBonus = 0.15, RareChanceBonus = 0 },
	[4] = { Description = "Rare variant spawn chance increases.", CoinBonusPercent = 10, TameEaseBonus = 0.15, RareChanceBonus = 0.05 },
	[5] = { Description = "Special cosmetic appearance unlocked.", CoinBonusPercent = 10, TameEaseBonus = 0.25, RareChanceBonus = 0.05, UnlocksSkin = true },
	[6] = { Description = "Higher passive income.", CoinBonusPercent = 20, TameEaseBonus = 0.25, RareChanceBonus = 0.08 },
	[7] = { Description = "Chance for a secret Brainrot variant.", CoinBonusPercent = 30, TameEaseBonus = 0.35, RareChanceBonus = 0.12, SecretChance = 0.02 },
}

function UpgradeData.GetLevelInfo(level)
	return UpgradeData.Levels[level]
end

return UpgradeData
