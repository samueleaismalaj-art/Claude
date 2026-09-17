--[[
	MainMenu (client-only)
	The hub menu: PLAY, BRAINROT COLLECTION, BRAINROT ISLAND, MISSIONS,
	UPGRADES, SHOP, DAILY REWARD, SETTINGS. Shop/Daily Reward are Version 2
	scope per the design doc's version plan, so they open a short "coming
	soon" notice here rather than being silently missing buttons.

	Place: StarterGui/MainMenu.lua (ModuleScript)
	Required by: StarterGui/Main.client.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIStyle = require(ReplicatedStorage.Modules.UI.UIStyle)

local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu.new(screenGui, callbacks)
	local self = setmetatable({}, MainMenu)
	self.Gui = screenGui
	self.Callbacks = callbacks or {}
	self:_build()
	return self
end

function MainMenu:_build()
	local root = Instance.new("Frame")
	root.Name = "MainMenu"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = UIStyle.Colors.Background
	root.BorderSizePixel = 0
	root.Parent = self.Gui
	self.Root = root

	local title = UIStyle.MakeLabel("BRAINROT STAMPEDE", UDim2.new(0, 600, 0, 70))
	title.Position = UDim2.new(0.5, -300, 0, 40)
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = UIStyle.Colors.Accent
	title.Parent = root

	local subtitle = UIStyle.MakeLabel("Ride. Jump. Capture. Stampede.", UDim2.new(0, 600, 0, 30))
	subtitle.Position = UDim2.new(0.5, -300, 0, 108)
	subtitle.TextColor3 = UIStyle.Colors.SubText
	subtitle.Parent = root

	local list = Instance.new("Frame")
	list.Size = UDim2.new(0, 320, 0, 460)
	list.Position = UDim2.new(0.5, -160, 0, 170)
	list.BackgroundTransparency = 1
	list.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = list

	local buttons = {
		{ Text = "PLAY", Color = UIStyle.Colors.AccentGreen, Key = "OnPlay" },
		{ Text = "BRAINROT COLLECTION", Key = "OnOpenCollection" },
		{ Text = "BRAINROT ISLAND", Key = "OnOpenIsland" },
		{ Text = "MISSIONS", Key = "OnOpenMissions" },
		{ Text = "UPGRADES", Key = "OnOpenIsland" },
		{ Text = "SHOP", Key = "OnOpenShop" },
		{ Text = "DAILY REWARD", Key = "OnOpenDaily" },
		{ Text = "SETTINGS", Key = "OnOpenSettings" },
	}

	for index, entry in ipairs(buttons) do
		local button = UIStyle.MakeButton(entry.Text, UDim2.new(0, 300, 0, 50), entry.Color)
		button.LayoutOrder = index
		button.Parent = list
		button.MouseButton1Click:Connect(function()
			local callback = self.Callbacks[entry.Key]
			if callback then
				callback()
			end
		end)
	end

	self:_buildComingSoon()
end

function MainMenu:_buildComingSoon()
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.Visible = false
	overlay.ZIndex = 20
	overlay.Parent = self.Root

	local panel = UIStyle.MakePanel(UDim2.new(0, 360, 0, 180))
	panel.Position = UDim2.new(0.5, -180, 0.5, -90)
	panel.ZIndex = 21
	panel.Parent = overlay
	UIStyle.Padding(panel, 20)

	local label = UIStyle.MakeLabel("", UDim2.new(1, 0, 0, 80))
	label.ZIndex = 22
	label.Parent = panel

	local closeButton = UIStyle.MakeButton("Close", UDim2.new(0, 160, 0, 46), UIStyle.Colors.Accent)
	closeButton.Position = UDim2.new(0.5, -80, 1, -56)
	closeButton.ZIndex = 22
	closeButton.Parent = panel
	closeButton.MouseButton1Click:Connect(function()
		overlay.Visible = false
	end)

	self.ComingSoonOverlay = overlay
	self.ComingSoonLabel = label
end

function MainMenu:ShowComingSoon(feature)
	self.ComingSoonLabel.Text = feature .. "\narrives in a future update!"
	self.ComingSoonOverlay.Visible = true
end

function MainMenu:Show()
	self.Root.Visible = true
end

function MainMenu:Hide()
	self.Root.Visible = false
end

return MainMenu
