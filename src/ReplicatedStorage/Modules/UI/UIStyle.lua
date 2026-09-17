--[[
	UIStyle
	Small helpers shared by every StarterGui script so the interface reads
	as one colorful, rounded, mobile-friendly system instead of five
	separately-styled panels.

	Place: ReplicatedStorage/Modules/UI/UIStyle.lua (ModuleScript)
]]

local UIStyle = {}

UIStyle.Colors = {
	Background = Color3.fromRGB(30, 32, 45),
	Panel = Color3.fromRGB(42, 45, 64),
	PanelLight = Color3.fromRGB(56, 60, 84),
	Accent = Color3.fromRGB(255, 196, 0),
	AccentGreen = Color3.fromRGB(90, 220, 130),
	AccentRed = Color3.fromRGB(255, 90, 90),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(200, 202, 215),
}

function UIStyle.Corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = parent
	return corner
end

function UIStyle.Stroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(0, 0, 0)
	stroke.Thickness = thickness or 2
	stroke.Transparency = 0.4
	stroke.Parent = parent
	return stroke
end

function UIStyle.Padding(parent, amount)
	local padding = Instance.new("UIPadding")
	amount = amount or 8
	padding.PaddingTop = UDim.new(0, amount)
	padding.PaddingBottom = UDim.new(0, amount)
	padding.PaddingLeft = UDim.new(0, amount)
	padding.PaddingRight = UDim.new(0, amount)
	padding.Parent = parent
	return padding
end

function UIStyle.MakeButton(text, size, color)
	local button = Instance.new("TextButton")
	button.Size = size or UDim2.new(0, 220, 0, 56)
	button.BackgroundColor3 = color or UIStyle.Colors.Accent
	button.Text = text
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(40, 30, 0)
	button.AutoButtonColor = true
	UIStyle.Corner(button, 14)
	UIStyle.Stroke(button, Color3.fromRGB(0, 0, 0), 2)
	return button
end

function UIStyle.MakeLabel(text, size, textColor, scaled)
	local label = Instance.new("TextLabel")
	label.Size = size or UDim2.new(1, 0, 0, 30)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextScaled = scaled ~= false
	label.TextColor3 = textColor or UIStyle.Colors.Text
	label.TextStrokeTransparency = 0.5
	return label
end

function UIStyle.MakePanel(size, color)
	local panel = Instance.new("Frame")
	panel.Size = size
	panel.BackgroundColor3 = color or UIStyle.Colors.Panel
	panel.BorderSizePixel = 0
	UIStyle.Corner(panel, 16)
	return panel
end

function UIStyle.MakeBar(size, fillColor)
	local track = Instance.new("Frame")
	track.Size = size
	track.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	track.BorderSizePixel = 0
	UIStyle.Corner(track, 10)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = fillColor or UIStyle.Colors.AccentGreen
	fill.BorderSizePixel = 0
	UIStyle.Corner(fill, 10)
	fill.Parent = track

	return track, fill
end

return UIStyle
