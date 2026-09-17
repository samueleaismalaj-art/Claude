--[[
	BrainrotModelFactory
	Builds the procedural, low-poly, chibi "meme" rig used for every
	Brainrot — the ridden mount, track NPCs, Island habitat residents and
	Collection card previews all come from this one function so a visual
	tweak only has to happen in one place.

	No real meshes/animations are shipped (this is a text-only delivery),
	so bodies are built from primitive Parts with WeldConstraints and
	animated procedurally (bob/tilt/jitter) by the caller each frame via
	BrainrotModelFactory.Animate. This keeps the project fully playable
	without any imported assets while leaving clear seams for an artist to
	later swap in real meshes/animations per Brainrot.

	Place: ReplicatedStorage/Modules/BrainrotModelFactory.lua (ModuleScript)
]]

local BrainrotModelFactory = {}

local function weld(part, root)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = root
	weldConstraint.Part1 = part
	weldConstraint.Parent = root
end

function BrainrotModelFactory.Create(brainrotData, scale)
	scale = scale or 1
	local colors = brainrotData.BodyColors or { Primary = Color3.fromRGB(200, 200, 200), Secondary = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(0, 0, 0) }

	local model = Instance.new("Model")
	model.Name = brainrotData.Id

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Shape = Enum.PartType.Block
	root.Size = Vector3.new(1, 1, 1) * scale
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = false
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Shape = Enum.PartType.Ball
	torso.Size = Vector3.new(4.2, 4.2, 4.2) * scale
	torso.Color = colors.Primary
	torso.Material = Enum.Material.SmoothPlastic
	torso.CanCollide = false
	torso.Anchored = false
	torso.CFrame = root.CFrame * CFrame.new(0, 0, 0)
	torso.Parent = model
	weld(torso, root)

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.6, 2.6, 2.6) * scale
	head.Color = colors.Secondary
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Anchored = false
	head.CFrame = root.CFrame * CFrame.new(0, 2.6 * scale, -1.6 * scale)
	head.Parent = model
	weld(head, root)

	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.55, 0.55, 0.55) * scale
		eye.Color = Color3.fromRGB(20, 20, 20)
		eye.Material = Enum.Material.SmoothPlastic
		eye.CanCollide = false
		eye.Anchored = false
		eye.CFrame = head.CFrame * CFrame.new(0.9 * side * scale, 0.2 * scale, -1.1 * scale)
		eye.Parent = model
		weld(eye, root)
	end

	for _, side in ipairs({ -1, 1 }) do
		local leg = Instance.new("Part")
		leg.Name = "Leg"
		leg.Shape = Enum.PartType.Block
		leg.Size = Vector3.new(1.2, 2.2, 1.2) * scale
		leg.Color = colors.Accent
		leg.Material = Enum.Material.SmoothPlastic
		leg.CanCollide = false
		leg.Anchored = false
		leg.CFrame = root.CFrame * CFrame.new(1.3 * side * scale, -3 * scale, 0.5 * scale)
		leg.Parent = model
		weld(leg, root)
	end

	local badge = Instance.new("BillboardGui")
	badge.Name = "NameTag"
	badge.Size = UDim2.new(6, 0, 1.6, 0)
	badge.StudsOffset = Vector3.new(0, 4.2 * scale, 0)
	badge.AlwaysOnTop = false
	badge.Parent = torso

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = brainrotData.Name
	label.Parent = badge

	model.PrimaryPart = root
	return model
end

-- Cheap procedural "exaggerated meme" animation: bob + tilt + optional
-- rage jitter, applied on top of a base CFrame the caller computes for
-- forward movement/lane position each frame.
function BrainrotModelFactory.Animate(model, baseCFrame, t, opts)
	opts = opts or {}
	local bobAmplitude = opts.BobAmplitude or 0.6
	local bobSpeed = opts.BobSpeed or 8
	local tilt = opts.Tilt or 0
	local jitter = opts.Jitter or 0

	local bob = math.sin(t * bobSpeed) * bobAmplitude
	local jitterOffset = Vector3.new(0, 0, 0)
	local jitterRot = 0
	if jitter > 0 then
		jitterOffset = Vector3.new((math.random() - 0.5) * jitter, (math.random() - 0.5) * jitter, 0)
		jitterRot = (math.random() - 0.5) * jitter * 0.5
	end

	local cframe = baseCFrame
		* CFrame.new(jitterOffset.X, bob + jitterOffset.Y, 0)
		* CFrame.Angles(0, 0, math.rad(tilt + jitterRot))

	if model.PrimaryPart then
		model:PivotTo(cframe)
	end
end

return BrainrotModelFactory
