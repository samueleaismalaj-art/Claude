--[[
	Main (client-only bootstrap)
	Wires every StarterGui panel (HUD, MainMenu, CollectionUI, MissionUI)
	together with the StarterPlayerScripts controllers (CameraController,
	BrainrotRidingController, IslandBuilder) and the Remotes. This is the
	only script that "knows" the whole client-side flow: join -> menu ->
	island -> run -> capture/crash -> back to island.

	Place: StarterGui/Main.client.lua (LocalScript)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local Remotes = require(ReplicatedStorage.Modules.Remotes)
local BrainrotSpawnerStartId = "TralaleroDude"

local HUD = require(script.Parent:WaitForChild("HUD"))
local MainMenu = require(script.Parent:WaitForChild("MainMenu"))
local CollectionUI = require(script.Parent:WaitForChild("CollectionUI"))
local MissionUI = require(script.Parent:WaitForChild("MissionUI"))

local CameraController = require(PlayerScripts:WaitForChild("CameraController"))
local BrainrotRidingController = require(PlayerScripts:WaitForChild("BrainrotRidingController"))
local IslandBuilder = require(PlayerScripts:WaitForChild("IslandBuilder"))

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotStampedeUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local hud = HUD.new(screenGui)
local collectionUI = CollectionUI.new(screenGui)
local missionUI = MissionUI.new(screenGui)

local cameraController = CameraController.new()
local islandBuilder = IslandBuilder.new(CFrame.new(0, -3, 0))

local latestProfile = nil
local ridingController
local startRun

local menuButton = Instance.new("TextButton")
menuButton.Size = UDim2.new(0, 100, 0, 44)
menuButton.Position = UDim2.new(0, 20, 0, 20)
menuButton.BackgroundColor3 = Color3.fromRGB(56, 60, 84)
menuButton.Text = "MENU"
menuButton.Font = Enum.Font.FredokaOne
menuButton.TextScaled = true
menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuButton.Parent = screenGui
local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuButton

local mainMenu -- forward declared, used by menuButton callback

local function updateMenuButtonVisibility()
	menuButton.Visible = not mainMenu.Root.Visible and not ridingController:IsActive()
end

local function onUpgrade(brainrotId)
	Remotes.UpgradeHabitat:FireServer(brainrotId)
end

local function refreshIslandIfIdle()
	if latestProfile and not ridingController:IsActive() then
		islandBuilder:Build(latestProfile, function()
			startRun()
		end, onUpgrade)
	end
end

local frozenCharacterState = nil

local function freezeCharacter()
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if humanoid and hrp then
		frozenCharacterState = { WalkSpeed = humanoid.WalkSpeed, JumpPower = humanoid.JumpPower }
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		hrp.Anchored = true
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
			end
		end
	end
end

local function unfreezeCharacter()
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if humanoid and hrp then
		hrp.Anchored = false
		humanoid.WalkSpeed = frozenCharacterState and frozenCharacterState.WalkSpeed or 16
		humanoid.JumpPower = frozenCharacterState and frozenCharacterState.JumpPower or 50
		hrp.CFrame = CFrame.new(0, 6, 14)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
			end
		end
	end
end

startRun = function()
	if ridingController:IsActive() then
		return
	end
	mainMenu:Hide()
	collectionUI:Hide()
	missionUI:Hide()
	updateMenuButtonVisibility()
	freezeCharacter()
	hud:ShowRunHUD()
	ridingController:StartRun(1, BrainrotSpawnerStartId)
end

ridingController = BrainrotRidingController.new(cameraController, {
	OnMountChanged = function(data, alreadyCaptured)
		hud:OnMountChanged(data, alreadyCaptured)
	end,
	OnCaptureProgress = function(progress)
		hud:UpdateCaptureProgress(progress)
	end,
	OnTick = function(tickData)
		hud:UpdateTick(tickData)
	end,
	OnSmash = function() end,
	OnCrash = function(_reason, distance)
		hud:HideRunHUD()
		unfreezeCharacter()
		cameraController:FollowCharacter()
		refreshIslandIfIdle()
		updateMenuButtonVisibility()
		hud:ShowRunSummary(distance, function() end)
	end,
})

hud:BindControls(ridingController)

mainMenu = MainMenu.new(screenGui, {
	OnPlay = startRun,
	OnOpenCollection = function()
		if latestProfile then
			collectionUI:Refresh(latestProfile)
		end
		collectionUI:Show()
	end,
	OnOpenMissions = function()
		missionUI:Show()
	end,
	OnOpenIsland = function()
		mainMenu:Hide()
		updateMenuButtonVisibility()
	end,
	OnOpenShop = function()
		mainMenu:ShowComingSoon("The Brainrot Shop")
	end,
	OnOpenDaily = function()
		mainMenu:ShowComingSoon("Daily Rewards")
	end,
	OnOpenSettings = function()
		mainMenu:ShowComingSoon("Settings")
	end,
})

menuButton.MouseButton1Click:Connect(function()
	mainMenu:Show()
	updateMenuButtonVisibility()
end)

Remotes.DataUpdated.OnClientEvent:Connect(function(profile)
	latestProfile = profile
	hud:UpdateCoins(profile.Coins)
	collectionUI:Refresh(profile)
	ridingController:SetCapturedSet(profile.CapturedBrainrots)
	refreshIslandIfIdle()
end)

Remotes.MissionUpdate.OnClientEvent:Connect(function(missionProgress)
	missionUI:Refresh(missionProgress)
	hud:UpdateMissionMini(missionUI:GetFirstIncompleteSummary(missionProgress))
end)

Remotes.CaptureResult.OnClientEvent:Connect(function(result)
	if result.Success then
		if result.IsNew then
			hud:ShowCaptureCelebration(result.Name, result.Rarity)
		end
		hud:UpdateCaptureProgress(nil)
	end
end)

local initialProfile = Remotes.GetPlayerData:InvokeServer()
if initialProfile then
	latestProfile = initialProfile
	hud:UpdateCoins(initialProfile.Coins)
	collectionUI:Refresh(initialProfile)
	ridingController:SetCapturedSet(initialProfile.CapturedBrainrots)
	missionUI:Refresh(initialProfile.MissionProgress)
end

islandBuilder:Build(latestProfile or { CapturedBrainrots = {}, HabitatLevels = {} }, startRun, onUpgrade)

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end
cameraController:FollowCharacter()
mainMenu:Show()
updateMenuButtonVisibility()

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	cameraController:FollowCharacter()
end)
