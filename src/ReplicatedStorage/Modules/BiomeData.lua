--[[
	BiomeData
	Zone/biome progression table. Version 1 only builds and unlocks Zone 1
	(Brainrot Plains); zones 2-8 are data stubs so BiomeService, the
	Collection UI and the Island expansion signage all have real content to
	read as soon as later versions add their Brainrots and geometry.

	Place: ReplicatedStorage/Modules/BiomeData.lua (ModuleScript)
]]

local BiomeData = {}

BiomeData.Zones = {
	{
		Id = 1,
		Name = "Brainrot Plains",
		Theme = "Bright beginner grassland",
		UnlockRequirement = { Type = "Free" },
		Implemented = true,
	},
	{
		Id = 2,
		Name = "Italian Brainrot City",
		Theme = "Cafes, scooters, fountains, chaotic streets",
		UnlockRequirement = { Type = "CaptureCount", Amount = 8 },
		Implemented = false,
	},
	{
		Id = 3,
		Name = "Sigma Desert",
		Theme = "Desert highway, gyms, giant statues",
		UnlockRequirement = { Type = "MissionsCompleted", Amount = 12 },
		Implemented = false,
	},
	{
		Id = 4,
		Name = "Brainrot Jungle",
		Theme = "Oversized plants, meme ruins, waterfalls",
		UnlockRequirement = { Type = "HabitatsUpgraded", Amount = 5 },
		Implemented = false,
	},
	{
		Id = 5,
		Name = "Frozen Brainrot",
		Theme = "Snow, ice, frozen meme statues",
		UnlockRequirement = { Type = "RareCaptures", Amount = 3 },
		Implemented = false,
	},
	{
		Id = 6,
		Name = "Cyber Brainrot City",
		Theme = "Neon, holograms, cyber highways",
		UnlockRequirement = { Type = "DistanceMilestone", Amount = 50000 },
		Implemented = false,
	},
	{
		Id = 7,
		Name = "Brainrot Space",
		Theme = "Planets, floating islands, black holes",
		UnlockRequirement = { Type = "TotalBrainrotsOwned", Amount = 40 },
		Implemented = false,
	},
	{
		Id = 8,
		Name = "Forbidden Brainrot Dimension",
		Theme = "Portals, corrupted environments, distorted music",
		UnlockRequirement = { Type = "QuestChain", Amount = 1, QuestId = "ForbiddenGate" },
		Implemented = false,
	},
}

function BiomeData.Get(zoneId)
	for _, zone in ipairs(BiomeData.Zones) do
		if zone.Id == zoneId then
			return zone
		end
	end
	return nil
end

return BiomeData
