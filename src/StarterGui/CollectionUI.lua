--[[
	CollectionUI (client-only)
	Grid of Brainrot cards: name, rarity, biome, capture status, upgrade
	level. Undiscovered Brainrots render as "???" silhouettes.

	Place: StarterGui/CollectionUI.lua (ModuleScript)
	Required by: StarterGui/Main.client.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Modules.BrainrotData)
local BiomeData = require(ReplicatedStorage.Modules.BiomeData)
local RarityData = require(ReplicatedStorage.Modules.RarityData)
local UIStyle = require(ReplicatedStorage.Modules.UI.UIStyle)

local CollectionUI = {}
CollectionUI.__index = CollectionUI

function CollectionUI.new(screenGui)
	local self = setmetatable({}, CollectionUI)
	self.Gui = screenGui
	self:_build()
	return self
end

function CollectionUI:_build()
	local root = Instance.new("Frame")
	root.Name = "CollectionUI"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = UIStyle.Colors.Background
	root.BackgroundTransparency = 0.05
	root.Visible = false
	root.ZIndex = 5
	root.Parent = self.Gui
	self.Root = root

	local title = UIStyle.MakeLabel("BRAINROT COLLECTION", UDim2.new(0, 500, 0, 50))
	title.Position = UDim2.new(0.5, -250, 0, 20)
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = UIStyle.Colors.Accent
	title.ZIndex = 5
	title.Parent = root

	local closeButton = UIStyle.MakeButton("X", UDim2.new(0, 50, 0, 50), UIStyle.Colors.AccentRed)
	closeButton.Position = UDim2.new(1, -70, 0, 20)
	closeButton.ZIndex = 5
	closeButton.Parent = root
	closeButton.MouseButton1Click:Connect(function()
		self:Hide()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -80, 1, -120)
	scroll.Position = UDim2.new(0, 40, 0, 90)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 8
	scroll.ZIndex = 5
	scroll.Parent = root

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 220, 0, 240)
	grid.CellPadding = UDim2.new(0, 16, 0, 16)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = scroll

	self.Scroll = scroll
	self.Cards = {}

	for _, id in ipairs(BrainrotData.Order) do
		self:_buildCard(id, scroll)
	end
end

function CollectionUI:_buildCard(id, parent)
	local data = BrainrotData.Get(id)
	local biome = BiomeData.Get(data.Zone)

	local card = UIStyle.MakePanel(UDim2.new(0, 220, 0, 240), UIStyle.Colors.Panel)
	card.ZIndex = 5
	card.LayoutOrder = table.find(BrainrotData.Order, id) or 0
	card.Parent = parent
	UIStyle.Padding(card, 12)

	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(1, 0, 0, 110)
	preview.BackgroundColor3 = data.BodyColors.Primary
	preview.ZIndex = 5
	UIStyle.Corner(preview, 12)
	preview.Parent = card

	local nameLabel = UIStyle.MakeLabel(data.Name, UDim2.new(1, 0, 0, 30))
	nameLabel.Position = UDim2.new(0, 0, 0, 118)
	nameLabel.ZIndex = 5
	nameLabel.Parent = card

	local rarityLabel = UIStyle.MakeLabel(string.upper(data.Rarity), UDim2.new(1, 0, 0, 22))
	rarityLabel.Position = UDim2.new(0, 0, 0, 150)
	rarityLabel.TextColor3 = RarityData.GetInfo(data.Rarity).Color
	rarityLabel.ZIndex = 5
	rarityLabel.Parent = card

	local biomeLabel = UIStyle.MakeLabel(biome and biome.Name or "", UDim2.new(1, 0, 0, 20))
	biomeLabel.Position = UDim2.new(0, 0, 0, 174)
	biomeLabel.TextColor3 = UIStyle.Colors.SubText
	biomeLabel.Font = Enum.Font.Gotham
	biomeLabel.ZIndex = 5
	biomeLabel.Parent = card

	local statusLabel = UIStyle.MakeLabel("LOCKED", UDim2.new(1, 0, 0, 24))
	statusLabel.Position = UDim2.new(0, 0, 0, 200)
	statusLabel.ZIndex = 5
	statusLabel.Parent = card

	self.Cards[id] = {
		Card = card,
		Preview = preview,
		NameLabel = nameLabel,
		StatusLabel = statusLabel,
	}
end

function CollectionUI:Refresh(profile)
	for id, refs in pairs(self.Cards) do
		local captured = profile.CapturedBrainrots[id] == true
		if captured then
			refs.NameLabel.Text = BrainrotData.Get(id).Name
			local level = profile.HabitatLevels[id] or 1
			refs.StatusLabel.Text = ("CAPTURED  •  Lv %d"):format(level)
			refs.StatusLabel.TextColor3 = UIStyle.Colors.AccentGreen
			refs.Preview.BackgroundTransparency = 0
		else
			refs.NameLabel.Text = "???"
			refs.StatusLabel.Text = "LOCKED"
			refs.StatusLabel.TextColor3 = UIStyle.Colors.SubText
			refs.Preview.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
		end
	end
end

function CollectionUI:Show()
	self.Root.Visible = true
end

function CollectionUI:Hide()
	self.Root.Visible = false
end

return CollectionUI
