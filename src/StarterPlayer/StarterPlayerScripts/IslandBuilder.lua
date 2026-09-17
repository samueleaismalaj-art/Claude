--[[
	IslandBuilder (client-only)
	Builds "Brainrot Island" — the player hub with all 8 Version 1
	habitats — privately for the local client, same trick as TrackBuilder
	(client-created Workspace instances never replicate). This lets each
	player see their own collection/habitat levels without any server-side
	per-viewer rendering logic. Also builds the central "Start Run" portal.

	Place: StarterPlayer/StarterPlayerScripts/IslandBuilder.lua (ModuleScript)
	Required by: StarterPlayerScripts/Main.client.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local RarityData = require(ReplicatedStorage.Modules.RarityData)
local EconomyData = require(ReplicatedStorage.Modules.EconomyData)
local BrainrotModelFactory = require(ReplicatedStorage.Modules.BrainrotModelFactory)

local IslandBuilder = {}
IslandBuilder.__index = IslandBuilder

local RADIUS = 55
local PLOT_SIZE = 16
local DISC_THICKNESS = 10

function IslandBuilder.new(origin)
	local self = setmetatable({}, IslandBuilder)
	self.Origin = origin
	-- Top surface of the island disc — everything (portal, habitats) is
	-- placed relative to this, not the disc's own center point.
	self.GroundY = origin.Position.Y + DISC_THICKNESS / 2
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "PrivateIsland"
	self.Folder.Parent = Workspace
	self.StartPortalPrompt = nil
	return self
end

function IslandBuilder:_buildGroundDisc()
	local disc = Instance.new("Part")
	disc.Name = "IslandBase"
	disc.Shape = Enum.PartType.Cylinder
	disc.Anchored = true
	disc.CanCollide = true
	disc.Size = Vector3.new(DISC_THICKNESS, (RADIUS + 25) * 2, (RADIUS + 25) * 2)
	disc.CFrame = self.Origin * CFrame.Angles(0, 0, math.rad(90))
	disc.Color = Color3.fromRGB(120, 210, 140)
	disc.Material = Enum.Material.Grass
	disc.Parent = self.Folder
end

function IslandBuilder:_buildStartPortal(onStartRun)
	local pad = Instance.new("Part")
	pad.Name = "StartRunPortal"
	pad.Anchored = true
	pad.CanCollide = true
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(3, 14, 14)
	pad.CFrame = CFrame.new(self.Origin.Position.X, self.GroundY + 1.5, self.Origin.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
	pad.Color = Color3.fromRGB(255, 210, 60)
	pad.Material = Enum.Material.Neon
	pad.Parent = self.Folder

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Start Run"
	prompt.ObjectText = "Brainrot Plains"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		if onStartRun then
			onStartRun()
		end
	end)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(8, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.Parent = pad
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Text = "PLAY"
	label.Parent = billboard

	self.StartPortalPrompt = prompt
end

local function tierForLevel(level)
	level = level or 0
	if level <= 1 then
		return { Height = 4, Color = Color3.fromRGB(180, 180, 180), Material = Enum.Material.WoodPlanks }
	elseif level <= 3 then
		return { Height = 8, Color = Color3.fromRGB(140, 170, 220), Material = Enum.Material.Concrete }
	elseif level <= 5 then
		return { Height = 14, Color = Color3.fromRGB(180, 130, 230), Material = Enum.Material.Marble }
	else
		return { Height = 22, Color = Color3.fromRGB(255, 210, 60), Material = Enum.Material.Neon }
	end
end

function IslandBuilder:_buildHabitat(index, total, brainrotData, profile, onUpgrade)
	local angle = (index - 1) / total * math.pi * 2
	local x = self.Origin.Position.X + math.cos(angle) * RADIUS
	local z = self.Origin.Position.Z + math.sin(angle) * RADIUS
	local base = Vector3.new(x, self.GroundY, z)

	local captured = profile.CapturedBrainrots[brainrotData.Id] == true
	local level = profile.HabitatLevels[brainrotData.Id]
	local tier = tierForLevel(level)

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Habitat_" .. brainrotData.Id
	plotFolder.Parent = self.Folder

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Anchored = true
	platform.CanCollide = true
	platform.Size = Vector3.new(PLOT_SIZE, tier.Height, PLOT_SIZE)
	platform.Position = base + Vector3.new(0, tier.Height / 2, 0)
	platform.Color = captured and tier.Color or Color3.fromRGB(90, 90, 95)
	platform.Material = captured and tier.Material or Enum.Material.Slate
	platform.Parent = plotFolder

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.new(10, 0, 2.6, 0)
	sign.StudsOffset = Vector3.new(0, tier.Height + 3, 0)
	sign.Parent = platform

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = brainrotData.Habitat
	nameLabel.Parent = sign

	local subLabel = Instance.new("TextLabel")
	subLabel.BackgroundTransparency = 1
	subLabel.Position = UDim2.new(0, 0, 0.55, 0)
	subLabel.Size = UDim2.new(1, 0, 0.45, 0)
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextScaled = true
	subLabel.TextColor3 = RarityData.GetInfo(brainrotData.Rarity).Color
	subLabel.TextStrokeTransparency = 0.5
	subLabel.Text = captured and (brainrotData.Name .. "  •  Lv " .. tostring(level)) or "???  •  Undiscovered"
	subLabel.Parent = sign

	if captured then
		local resident = BrainrotModelFactory.Create(brainrotData, 0.9)
		resident:PivotTo(CFrame.new(base + Vector3.new(0, tier.Height + 3, 0)))
		resident.Parent = plotFolder

		task.spawn(function()
			local t = 0
			while resident.Parent do
				t += task.wait(0.05)
				BrainrotModelFactory.Animate(resident, CFrame.new(base + Vector3.new(0, tier.Height + 3, 0)), t, { BobAmplitude = 0.5, BobSpeed = 3 })
			end
		end)

		local nextCost = EconomyData.GetHabitatUpgradeCost(level)
		if nextCost then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Upgrade (" .. nextCost .. " coins)"
			prompt.ObjectText = brainrotData.Habitat
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 16
			prompt.Parent = platform
			prompt.Triggered:Connect(function()
				if onUpgrade then
					onUpgrade(brainrotData.Id)
				end
			end)
		end
	else
		local silhouette = Instance.new("Part")
		silhouette.Shape = Enum.PartType.Ball
		silhouette.Size = Vector3.new(4, 4, 4)
		silhouette.Color = Color3.fromRGB(30, 30, 30)
		silhouette.Material = Enum.Material.SmoothPlastic
		silhouette.Anchored = true
		silhouette.CanCollide = false
		silhouette.CFrame = CFrame.new(base + Vector3.new(0, tier.Height + 3, 0))
		silhouette.Parent = plotFolder
	end
end

function IslandBuilder:Build(profile, onStartRun, onUpgrade)
	self.Folder:ClearAllChildren()
	self:_buildGroundDisc()
	self:_buildStartPortal(onStartRun)

	for index, id in ipairs(BrainrotData.Order) do
		local data = BrainrotData.Get(id)
		self:_buildHabitat(index, #BrainrotData.Order, data, profile, onUpgrade)
	end
end

function IslandBuilder:Destroy()
	self.Folder:Destroy()
end

return IslandBuilder
