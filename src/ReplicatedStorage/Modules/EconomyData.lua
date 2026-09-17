--[[
	EconomyData
	Tunable constants for coin/gem income. Kept separate from EconomyService
	so designers can rebalance numbers without touching logic.

	Place: ReplicatedStorage/Modules/EconomyData.lua (ModuleScript)
]]

local EconomyData = {}

EconomyData.CoinsPerStud = 0.12
EconomyData.CaptureBaseReward = 40
EconomyData.CaptureRarityBonus = {
	Common = 0,
	Uncommon = 25,
	Rare = 60,
	Epic = 140,
	Legendary = 320,
	Mythic = 700,
	Secret = 1500,
}

EconomyData.PassiveIncomePerHabitatLevel = 2 -- coins/minute per habitat level while offline/on Island
EconomyData.MaxOfflinePassiveMinutes = 240

-- Habitat upgrade cost curve: cost(level) = Base * Growth^(level-1)
EconomyData.HabitatUpgradeBaseCost = 100
EconomyData.HabitatUpgradeGrowth = 1.65
EconomyData.HabitatMaxLevel = 7

function EconomyData.GetHabitatUpgradeCost(currentLevel)
	local nextLevel = currentLevel + 1
	if nextLevel > EconomyData.HabitatMaxLevel then
		return nil
	end
	return math.floor(EconomyData.HabitatUpgradeBaseCost * (EconomyData.HabitatUpgradeGrowth ^ (nextLevel - 1)))
end

return EconomyData
