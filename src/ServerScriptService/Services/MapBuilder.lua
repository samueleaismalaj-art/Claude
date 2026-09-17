--[[
	MapBuilder (server)
	Ensures a minimal shared spawn platform + SpawnLocation exist in
	Workspace, regardless of which Studio template the place was created
	from (Baseplate template or completely empty). The actual Brainrot
	Island hub and the endless run track are built privately per-client
	(see StarterPlayerScripts/IslandBuilder.lua and TrackBuilder.lua) so
	each player's collection and run are rendered only for them — see the
	"Architecture & Simplifications" section of README.md for why.

	Place: ServerScriptService/Services/MapBuilder.lua (ModuleScript)
	Orchestrated by: ServerScriptService/Main.server.lua
]]

local Workspace = game:GetService("Workspace")

local MapBuilder = {}

function MapBuilder.Init()
	if Workspace:FindFirstChild("BrainrotStampedeSpawn") then
		return
	end

	local platform = Instance.new("Part")
	platform.Name = "BrainrotStampedeSpawn"
	platform.Size = Vector3.new(60, 4, 60)
	platform.Position = Vector3.new(0, 0, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.Grass
	platform.Color = Color3.fromRGB(90, 200, 110)
	platform.Parent = Workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 2.5, 0)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Duration = 0
	spawn.Parent = Workspace

	local sky = Instance.new("Sky")
	sky.Parent = game:GetService("Lighting")

	game:GetService("Lighting").Brightness = 2
	game:GetService("Lighting").ClockTime = 14
	game:GetService("Lighting").FogEnd = 100000
end

return MapBuilder
