--[[
	MissionUI (client-only)
	Lists the 5 active Version 1 missions with progress bars and claim
	buttons.

	Place: StarterGui/MissionUI.lua (ModuleScript)
	Required by: StarterGui/Main.client.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MissionData = require(ReplicatedStorage.Modules.MissionData)
local UIStyle = require(ReplicatedStorage.Modules.UI.UIStyle)
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local MissionUI = {}
MissionUI.__index = MissionUI

function MissionUI.new(screenGui)
	local self = setmetatable({}, MissionUI)
	self.Gui = screenGui
	self.Rows = {}
	self:_build()
	return self
end

function MissionUI:_build()
	local root = Instance.new("Frame")
	root.Name = "MissionUI"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = UIStyle.Colors.Background
	root.BackgroundTransparency = 0.05
	root.Visible = false
	root.ZIndex = 5
	root.Parent = self.Gui
	self.Root = root

	local title = UIStyle.MakeLabel("MISSIONS", UDim2.new(0, 500, 0, 50))
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

	local list = Instance.new("Frame")
	list.Size = UDim2.new(0, 560, 0, 420)
	list.Position = UDim2.new(0.5, -280, 0, 100)
	list.BackgroundTransparency = 1
	list.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 14)
	layout.Parent = list

	for _, missionId in ipairs(MissionData.ActiveSetV1) do
		self:_buildRow(missionId, list)
	end
end

function MissionUI:_buildRow(missionId, parent)
	local mission = MissionData.Get(missionId)

	local row = UIStyle.MakePanel(UDim2.new(1, 0, 0, 74), UIStyle.Colors.Panel)
	row.ZIndex = 5
	row.Parent = parent
	UIStyle.Padding(row, 10)

	local desc = UIStyle.MakeLabel(mission.Description, UDim2.new(0.6, 0, 0, 26))
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.ZIndex = 5
	desc.Parent = row

	local track, fill = UIStyle.MakeBar(UDim2.new(0.6, 0, 0, 14), UIStyle.Colors.AccentGreen)
	track.Position = UDim2.new(0, 0, 0, 32)
	track.ZIndex = 5
	track.Parent = row
	for _, child in ipairs(track:GetChildren()) do
		child.ZIndex = 5
	end

	local claimButton = UIStyle.MakeButton("Claim", UDim2.new(0, 120, 0, 44), UIStyle.Colors.Accent)
	claimButton.Position = UDim2.new(1, -130, 0, 8)
	claimButton.ZIndex = 5
	claimButton.Visible = false
	claimButton.Parent = row
	claimButton.MouseButton1Click:Connect(function()
		Remotes.ClaimReward:FireServer("Mission", missionId)
	end)

	self.Rows[missionId] = { Row = row, Fill = fill, ClaimButton = claimButton, Mission = mission }
end

function MissionUI:Refresh(missionProgress)
	if not missionProgress then
		return
	end
	for missionId, refs in pairs(self.Rows) do
		local entry = missionProgress[missionId]
		if entry then
			local ratio = math.clamp(entry.Progress / refs.Mission.Target, 0, 1)
			refs.Fill.Size = UDim2.new(ratio, 0, 1, 0)
			refs.ClaimButton.Visible = entry.Completed and not entry.Claimed
			refs.ClaimButton.Text = entry.Claimed and "Claimed" or "Claim"
		end
	end
end

function MissionUI:GetFirstIncompleteSummary(missionProgress)
	if not missionProgress then
		return ""
	end
	for _, missionId in ipairs(MissionData.ActiveSetV1) do
		local entry = missionProgress[missionId]
		local mission = MissionData.Get(missionId)
		if entry and not entry.Completed then
			return ("%s (%d/%d)"):format(mission.Description, math.floor(entry.Progress), mission.Target)
		end
	end
	return "All missions complete!"
end

function MissionUI:Show()
	self.Root.Visible = true
end

function MissionUI:Hide()
	self.Root.Visible = false
end

return MissionUI
