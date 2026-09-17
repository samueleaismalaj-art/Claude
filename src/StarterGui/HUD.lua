--[[
	HUD (client-only)
	The in-run heads-up display: distance, mission progress, coins,
	current Brainrot name/rarity/rage meter, the "NEW BRAINROT" +
	capture-progress flow, the capture celebration popup, the run-summary
	popup, and the mobile steer/jump buttons (PC uses A/D/arrows + Space,
	wired by BrainrotRidingController directly).

	Place: StarterGui/HUD.lua (ModuleScript)
	Required by: StarterGui/Main.client.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityData = require(ReplicatedStorage.Modules.RarityData)
local UIStyle = require(ReplicatedStorage.Modules.UI.UIStyle)

local HUD = {}
HUD.__index = HUD

function HUD.new(screenGui)
	local self = setmetatable({}, HUD)
	self.Gui = screenGui
	self:_build()
	return self
end

function HUD:_build()
	local root = Instance.new("Frame")
	root.Name = "HUD"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = self.Gui
	self.Root = root

	-- Top left: distance
	self.DistanceLabel = UIStyle.MakeLabel("0 studs", UDim2.new(0, 220, 0, 40))
	self.DistanceLabel.Position = UDim2.new(0, 20, 0, 20)
	self.DistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.DistanceLabel.Parent = root

	-- Top center: mission progress
	self.MissionLabel = UIStyle.MakeLabel("", UDim2.new(0, 420, 0, 34))
	self.MissionLabel.Position = UDim2.new(0.5, -210, 0, 20)
	self.MissionLabel.TextColor3 = UIStyle.Colors.Accent
	self.MissionLabel.Parent = root

	-- Top right: coins
	self.CoinsLabel = UIStyle.MakeLabel("0 coins", UDim2.new(0, 220, 0, 40))
	self.CoinsLabel.Position = UDim2.new(1, -240, 0, 20)
	self.CoinsLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.CoinsLabel.TextColor3 = UIStyle.Colors.Accent
	self.CoinsLabel.Parent = root

	-- Bottom center cluster
	self.NewTag = UIStyle.MakeLabel("NEW BRAINROT", UDim2.new(0, 300, 0, 34))
	self.NewTag.Position = UDim2.new(0.5, -150, 1, -230)
	self.NewTag.TextColor3 = UIStyle.Colors.AccentGreen
	self.NewTag.Visible = false
	self.NewTag.Parent = root

	self.MountNameLabel = UIStyle.MakeLabel("Tralalero Dude", UDim2.new(0, 400, 0, 40))
	self.MountNameLabel.Position = UDim2.new(0.5, -200, 1, -190)
	self.MountNameLabel.Parent = root

	self.MountRarityLabel = UIStyle.MakeLabel("COMMON", UDim2.new(0, 400, 0, 26))
	self.MountRarityLabel.Position = UDim2.new(0.5, -200, 1, -150)
	self.MountRarityLabel.Parent = root

	local rageTrack, rageFill = UIStyle.MakeBar(UDim2.new(0, 260, 0, 14), UIStyle.Colors.AccentRed)
	rageTrack.Position = UDim2.new(0.5, -130, 1, -120)
	rageTrack.Parent = root
	self.RageFill = rageFill

	local captureTrack, captureFill = UIStyle.MakeBar(UDim2.new(0, 300, 0, 18), UIStyle.Colors.AccentGreen)
	captureTrack.Position = UDim2.new(0.5, -150, 1, -95)
	captureTrack.Visible = false
	captureTrack.Parent = root
	self.CaptureTrack = captureTrack
	self.CaptureFill = captureFill

	self:_buildMobileControls(root)
	self:_buildCelebrationPopup()
	self:_buildRunSummaryPopup()
end

function HUD:_buildMobileControls(root)
	local steerFrame = Instance.new("Frame")
	steerFrame.BackgroundTransparency = 1
	steerFrame.Size = UDim2.new(0, 260, 0, 110)
	steerFrame.Position = UDim2.new(0, 20, 1, -140)
	steerFrame.Parent = root

	local leftButton = UIStyle.MakeButton("◀", UDim2.new(0, 110, 0, 110), UIStyle.Colors.PanelLight)
	leftButton.Position = UDim2.new(0, 0, 0, 0)
	leftButton.Parent = steerFrame

	local rightButton = UIStyle.MakeButton("▶", UDim2.new(0, 110, 0, 110), UIStyle.Colors.PanelLight)
	rightButton.Position = UDim2.new(0, 140, 0, 0)
	rightButton.Parent = steerFrame

	local jumpButton = UIStyle.MakeButton("JUMP", UDim2.new(0, 140, 0, 110), UIStyle.Colors.Accent)
	jumpButton.Position = UDim2.new(1, -160, 1, -140)
	jumpButton.AnchorPoint = Vector2.new(0, 0)
	jumpButton.Parent = root

	self.LeftButton = leftButton
	self.RightButton = rightButton
	self.JumpButton = jumpButton
end

function HUD:BindControls(controller)
	self.LeftButton.MouseButton1Down:Connect(function()
		controller:SetSteerAxis(-1)
	end)
	self.LeftButton.MouseButton1Up:Connect(function()
		controller:SetSteerAxis(0)
	end)
	self.LeftButton.MouseLeave:Connect(function()
		controller:SetSteerAxis(0)
	end)

	self.RightButton.MouseButton1Down:Connect(function()
		controller:SetSteerAxis(1)
	end)
	self.RightButton.MouseButton1Up:Connect(function()
		controller:SetSteerAxis(0)
	end)
	self.RightButton.MouseLeave:Connect(function()
		controller:SetSteerAxis(0)
	end)

	self.JumpButton.MouseButton1Down:Connect(function()
		controller:RequestJump()
	end)
end

function HUD:_buildCelebrationPopup()
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.Visible = false
	overlay.ZIndex = 10
	overlay.Parent = self.Root

	local panel = UIStyle.MakePanel(UDim2.new(0, 420, 0, 260))
	panel.Position = UDim2.new(0.5, -210, 0.5, -130)
	panel.ZIndex = 11
	panel.Parent = overlay
	UIStyle.Padding(panel, 20)

	local header = UIStyle.MakeLabel("NEW BRAINROT DISCOVERED!", UDim2.new(1, 0, 0, 40))
	header.TextColor3 = UIStyle.Colors.AccentGreen
	header.ZIndex = 12
	header.Parent = panel

	local nameLabel = UIStyle.MakeLabel("", UDim2.new(1, 0, 0, 60))
	nameLabel.Position = UDim2.new(0, 0, 0, 50)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.ZIndex = 12
	nameLabel.Parent = panel

	local rarityLabel = UIStyle.MakeLabel("", UDim2.new(1, 0, 0, 36))
	rarityLabel.Position = UDim2.new(0, 0, 0, 118)
	rarityLabel.ZIndex = 12
	rarityLabel.Parent = panel

	local addButton = UIStyle.MakeButton("Add to Collection", UDim2.new(0, 240, 0, 54), UIStyle.Colors.Accent)
	addButton.Position = UDim2.new(0.5, -120, 1, -70)
	addButton.ZIndex = 12
	addButton.Parent = panel

	addButton.MouseButton1Click:Connect(function()
		overlay.Visible = false
	end)

	self.CelebrationOverlay = overlay
	self.CelebrationName = nameLabel
	self.CelebrationRarity = rarityLabel
end

function HUD:ShowCaptureCelebration(name, rarity)
	local info = RarityData.GetInfo(rarity)
	self.CelebrationName.Text = string.upper(name)
	self.CelebrationRarity.Text = "RARITY: " .. string.upper(rarity)
	self.CelebrationRarity.TextColor3 = info.Color
	self.CelebrationOverlay.Visible = true
	task.delay(3.5, function()
		if self.CelebrationOverlay then
			self.CelebrationOverlay.Visible = false
		end
	end)
end

function HUD:_buildRunSummaryPopup()
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.Visible = false
	overlay.ZIndex = 10
	overlay.Parent = self.Root

	local panel = UIStyle.MakePanel(UDim2.new(0, 380, 0, 240))
	panel.Position = UDim2.new(0.5, -190, 0.5, -120)
	panel.ZIndex = 11
	panel.Parent = overlay
	UIStyle.Padding(panel, 20)

	local header = UIStyle.MakeLabel("RUN ENDED", UDim2.new(1, 0, 0, 40))
	header.TextColor3 = UIStyle.Colors.AccentRed
	header.ZIndex = 12
	header.Parent = panel

	local statsLabel = UIStyle.MakeLabel("", UDim2.new(1, 0, 0, 80))
	statsLabel.Position = UDim2.new(0, 0, 0, 46)
	statsLabel.TextColor3 = UIStyle.Colors.SubText
	statsLabel.ZIndex = 12
	statsLabel.Parent = panel

	local continueButton = UIStyle.MakeButton("Return to Island", UDim2.new(0, 260, 0, 54), UIStyle.Colors.Accent)
	continueButton.Position = UDim2.new(0.5, -130, 1, -66)
	continueButton.ZIndex = 12
	continueButton.Parent = panel

	self.RunSummaryOverlay = overlay
	self.RunSummaryStats = statsLabel
	self.RunSummaryContinue = continueButton
end

function HUD:ShowRunSummary(distance, onContinue)
	self.RunSummaryStats.Text = ("Distance: %d studs"):format(math.floor(distance))
	self.RunSummaryOverlay.Visible = true

	local connection
	connection = self.RunSummaryContinue.MouseButton1Click:Connect(function()
		self.RunSummaryOverlay.Visible = false
		connection:Disconnect()
		if onContinue then
			onContinue()
		end
	end)
end

function HUD:ShowRunHUD()
	self.Root.Visible = true
end

function HUD:HideRunHUD()
	self.Root.Visible = false
	self.CaptureTrack.Visible = false
	self.NewTag.Visible = false
end

function HUD:UpdateTick(tick)
	self.DistanceLabel.Text = ("%d studs"):format(math.floor(tick.Distance))
	self.RageFill.Size = UDim2.new(tick.RageMeter, 0, 1, 0)
	self.RageFill.BackgroundColor3 = tick.IsRaging and UIStyle.Colors.AccentRed or UIStyle.Colors.Accent
	self.MountNameLabel.Text = tick.BrainrotName or ""
	if tick.BrainrotRarity then
		self.MountRarityLabel.Text = string.upper(tick.BrainrotRarity)
		self.MountRarityLabel.TextColor3 = RarityData.GetInfo(tick.BrainrotRarity).Color
	end
end

function HUD:UpdateCoins(coins)
	self.CoinsLabel.Text = ("%d coins"):format(coins)
end

function HUD:UpdateMissionMini(text)
	self.MissionLabel.Text = text or ""
end

function HUD:OnMountChanged(data, alreadyCaptured)
	self.NewTag.Visible = not alreadyCaptured
	self.CaptureTrack.Visible = not alreadyCaptured
	if alreadyCaptured then
		self.CaptureFill.Size = UDim2.new(0, 0, 1, 0)
	end
end

function HUD:UpdateCaptureProgress(progress)
	if progress == nil then
		self.CaptureTrack.Visible = false
		self.NewTag.Visible = false
		return
	end
	self.CaptureTrack.Visible = true
	self.NewTag.Visible = true
	self.CaptureFill.Size = UDim2.new(progress, 0, 1, 0)
end

return HUD
