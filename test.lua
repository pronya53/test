if game.CoreGui:FindFirstChild("RichPremiumGui") then
	game.CoreGui.RichPremiumGui:Destroy()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local Config = {
	ESP = false, Names = false, Boxes = false, Tracers = false, Distance = true, Friends = false, ESPMode = "Default",
	Skeleton = false, Chams = false, 
	Crosshair = false, Trail = false, TrailMode = "Neon", JumpCircles = false, ArrayList = false, Radar = false, RadarZoom = 2, KeybindsList = true,
	TargetESP = false, TargetMode = "Cubes", DamageInd = false, FakeIP = false, SelfAura = false, HitSound = false,
	
	KillShockwave = true, KillLightning = false, KillBlood = false, KillSouls = false, KillBlackHole = false,
	
	Aim = false, ShowFOV = false, AimRadius = 150, AimSmooth = 0.2, AimMode = "Camera",
	Hitbox = false, HitboxSize = 10, AutoClicker = false, TriggerBot = false, MeleeReach = false, Helper = false, HelperSmoothness = 0.3,
	
	Speed = false, SpeedMult = 2, SpeedMode = "WalkSpeed", Fly = false, FlySpeed = 50, NoClip = false, InfJump = false, Spider = false, BHop = false, BHopSpeed = 1.4, BHopStrafeForce = 0.12, Freecam = false, FreecamSpeed = 100,
	FakeLag = false, FakeLagPower = 0.5, SafeHighJump = false, SafeHighJumpPower = 15,
	
	Paint_Active = false, Paint_FilePath = "", Paint_Scale = 1, Paint_Delay = 0.02,
	Paint_Quality = "High", Paint_StartX = 0, Paint_StartY = 0, Paint_SkipWhite = true,
	Paint_MaxWidth = 400, Paint_MaxHeight = 400, Paint_BrushSize = 0.4, Paint_Dithering = false,
	Paint_ImageScale = 0.5,
	Paint_CanvasOffsetX = 0, Paint_CanvasOffsetY = 0,
	Paint_Method = "Input",
	SpectateCam = false,
	
	XRay = false, FullBright = false, NightMode = false, Wireframe = false, FOV = false, FOVValue = 90, ThemeFog = false, AestheticWorld = false,
	Freeze = false, Spinbot = false, SpinSpeed = 50, Fling = false, AntiFling = false,
	Gravity = false, TimeWarp = false, AutoToxic = false, PotatoMode = false,
	
	DynamicIsland = true, IslandMode = "Music", IslandMusic = true, IslandExpanded = false, IslandExpandOnHover = false,
	Notifications = true,
	RGBUI = false, LoadWorldSettings = true, UIStyle = "Modern",
	
	SelectedGame = "Wanted",
	Wanted_AutoBank = false,
	Wanted_AutoATM = false,
	Wanted_VehicleFly = false,
	Wanted_FlySpeed = 90,
	Wanted_FlyHeight = 45,
	Wanted_ATMDelay = 0.8,
	Wanted_ATMHits = 4,
	Wanted_ATMCooldown = 150,
	Wanted_AutoSell = true,
	Wanted_Debug = false
}

local Binds = { ESP = nil, Aim = nil, Speed = nil, Fly = nil, NoClip = nil, Freeze = nil, Spider = nil, Fling = nil, Freecam = nil, Helper = nil }

local MenuVisible = true
local MenuAnimating = false

local Connections = {}
local espBoxes, highlights, nameTags, distanceTags, tracers, ipTags, skeletonLines = {}, {}, {}, {}, {}, {}, {}
local originalHitboxes, originalTransparencies, originalMaterials = {}, {}, {}
local deadTracker, enemyHealthTracker = {}, {}
local friendsCache = {}
local function isFriend(t)
	if friendsCache[t.UserId] ~= nil then return friendsCache[t.UserId] end
	friendsCache[t.UserId] = false
	task.spawn(function() pcall(function() friendsCache[t.UserId] = player:IsFriendsWith(t.UserId) end) end)
	return friendsCache[t.UserId]
end

local origAmbient = Lighting.Ambient; local origOutdoorAmbient = Lighting.OutdoorAmbient; local origBrightness = Lighting.Brightness
local origClockTime = Lighting.ClockTime; local origGravity = Workspace.Gravity; local origGlobalShadows = Lighting.GlobalShadows
local origFogColor = Lighting.FogColor; local origFogEnd = Lighting.FogEnd; local origFogStart = Lighting.FogStart

local FOVCircle, CrosshairX, CrosshairY
local Aiming = false; local freezePos = nil; local RGBHue = 0
local aestheticBloom, aestheticCC = nil, nil
local FreecamPart = nil
local radarBlips = {}

local clamp = math.clamp or function(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local rnd = math.round or function(v) return math.floor(v + 0.5) end

local hitSound = Instance.new("Sound", Workspace); hitSound.SoundId = "rbxassetid://3744371510"; hitSound.Volume = 4
local ToxicMessages = {"Ez pz", "Sit down boy", "RICH PREMIUM 2.0 ON TOP", "Nice aim bro lol", "Go cry to admin", "1 tapped", "Skill issue"}
local FakeCountries = {"RU", "UA", "US", "DE", "PL", "KZ", "FR", "BR"}
local FakeIPs = {}

local currentOrbitRadius = 0; local lastTargetPos = nil
local specChar = nil; local specClone = nil; local specPartsMap = {}
local specEnvFolder = nil; local lastEnvUpdate = 0; local specEnvMap = {}
local spec3DTracer = nil

local R15_Bones = { {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"} }
local R6_Bones = { {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"} }

local TargetAura = { Cubes = {}, Rhombus = nil, Ring = nil, Atom = {}, Crown = {}, Helix = {}, Constellation = {}, VoidRing = nil, Wings = {} }
local SelfCrown = {}

for i = 1, 4 do
	local p = Instance.new("Part"); p.Size = Vector3.new(0.5, 0.5, 0.5); p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace
	local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.25, 0); local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.25, 0)
	local tr = Instance.new("Trail", p); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.3; tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	table.insert(TargetAura.Cubes, {Part = p, Trail = tr})
end
for i = 1, 3 do
	local p = Instance.new("Part"); p.Size = Vector3.new(0.4, 0.4, 0.4); p.Shape = Enum.PartType.Ball; p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace
	local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.2, 0); local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.2, 0)
	local tr = Instance.new("Trail", p); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.4; tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	table.insert(TargetAura.Atom, {Part = p, Trail = tr})
end
for i = 1, 6 do
	local p = Instance.new("Part"); p.Size = Vector3.new(0.3, 0.8, 0.3); p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace; table.insert(TargetAura.Crown, p)
end
for i = 1, 5 do
	local p = Instance.new("Part"); p.Size = Vector3.new(0.2, 0.6, 0.2); p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace; table.insert(SelfCrown, p)
end
TargetAura.Rhombus = Instance.new("Part"); TargetAura.Rhombus.Size = Vector3.new(1.5, 1.5, 1.5); TargetAura.Rhombus.Material = Enum.Material.Neon; TargetAura.Rhombus.Anchored = true; TargetAura.Rhombus.CanCollide = false; TargetAura.Rhombus.Transparency = 1; TargetAura.Rhombus.Parent = Workspace
TargetAura.Ring = Instance.new("Part"); TargetAura.Ring.Size = Vector3.new(0.2, 4, 4); TargetAura.Ring.Material = Enum.Material.Neon; TargetAura.Ring.Anchored = true; TargetAura.Ring.CanCollide = false; TargetAura.Ring.Transparency = 1; TargetAura.Ring.Shape = Enum.PartType.Cylinder; TargetAura.Ring.Parent = Workspace

for i = 1, 2 do
	local p = Instance.new("Part"); p.Size = Vector3.new(0.2, 0.2, 0.2); p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace
	local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.1, 0); local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.1, 0)
	local tr = Instance.new("Trail", p); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.5; tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	table.insert(TargetAura.Helix, {Part = p, Trail = tr})
end
for i = 1, 6 do
	local p = Instance.new("Part"); p.Size = Vector3.new(0.15, 0.15, 0.15); p.Shape = Enum.PartType.Ball; p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace
	local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.05, 0); local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.05, 0)
	local tr = Instance.new("Trail", p); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.6; tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
	table.insert(TargetAura.Constellation, {Part = p, Trail = tr})
end
for i = 1, 6 do
	local p = Instance.new("Part"); p.Size = Vector3.new(1, 0.1, 2); p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Parent = Workspace; table.insert(TargetAura.Wings, p)
end
TargetAura.VoidRing = Instance.new("Part"); TargetAura.VoidRing.Size = Vector3.new(0.1, 5, 5); TargetAura.VoidRing.Material = Enum.Material.Neon; TargetAura.VoidRing.Anchored = true; TargetAura.VoidRing.CanCollide = false; TargetAura.VoidRing.Transparency = 1; TargetAura.VoidRing.Shape = Enum.PartType.Cylinder; TargetAura.VoidRing.Parent = Workspace

local Themes = {
	RichDark = { BG = Color3.fromRGB(5, 5, 5), Panel = Color3.fromRGB(12, 12, 15), Btn = Color3.fromRGB(18, 18, 22), BtnHover = Color3.fromRGB(25, 25, 30), Accent = Color3.fromRGB(138, 43, 226), Text = Color3.fromRGB(240, 240, 240) },
	PurpleBlack = { BG = Color3.fromRGB(10, 5, 15), Panel = Color3.fromRGB(20, 10, 30), Btn = Color3.fromRGB(30, 15, 45), BtnHover = Color3.fromRGB(50, 25, 75), Accent = Color3.fromRGB(180, 0, 255), Text = Color3.fromRGB(240, 240, 240) },
	CyberBlue = { BG = Color3.fromRGB(5, 10, 15), Panel = Color3.fromRGB(10, 20, 30), Btn = Color3.fromRGB(20, 35, 50), BtnHover = Color3.fromRGB(35, 55, 75), Accent = Color3.fromRGB(0, 200, 255), Text = Color3.fromRGB(240, 240, 240) },
	BloodRed = { BG = Color3.fromRGB(15, 5, 5), Panel = Color3.fromRGB(25, 10, 10), Btn = Color3.fromRGB(35, 15, 15), BtnHover = Color3.fromRGB(55, 20, 20), Accent = Color3.fromRGB(255, 45, 45), Text = Color3.fromRGB(240, 240, 240) },
	Cyberpunk = { BG = Color3.fromRGB(12, 10, 5), Panel = Color3.fromRGB(20, 18, 10), Btn = Color3.fromRGB(32, 28, 15), BtnHover = Color3.fromRGB(50, 45, 20), Accent = Color3.fromRGB(255, 220, 0), Text = Color3.fromRGB(240, 240, 240) },
	Emerald = { BG = Color3.fromRGB(5, 12, 8), Panel = Color3.fromRGB(10, 22, 15), Btn = Color3.fromRGB(15, 35, 22), BtnHover = Color3.fromRGB(22, 50, 32), Accent = Color3.fromRGB(0, 255, 130), Text = Color3.fromRGB(240, 240, 240) },
	Sakura = { BG = Color3.fromRGB(15, 5, 12), Panel = Color3.fromRGB(25, 10, 20), Btn = Color3.fromRGB(38, 15, 30), BtnHover = Color3.fromRGB(58, 22, 45), Accent = Color3.fromRGB(255, 105, 180), Text = Color3.fromRGB(240, 240, 240) }
}
local ActiveThemeName = "RichDark"
local ActiveTheme = Themes[ActiveThemeName]
local UI_Elements = { Strokes = {}, Texts = {}, BG = {} }

pcall(function()
	FOVCircle = Drawing.new("Circle"); FOVCircle.Color = ActiveTheme.Accent; FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 60; FOVCircle.Visible = false
	CrosshairX = Drawing.new("Line"); CrosshairX.Color = Color3.fromRGB(0, 255, 0); CrosshairX.Thickness = 2; CrosshairX.Visible = false
	CrosshairY = Drawing.new("Line"); CrosshairY.Color = Color3.fromRGB(0, 255, 0); CrosshairY.Thickness = 2; CrosshairY.Visible = false
end)

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui")); ScreenGui.Name = "RichPremiumGui"; ScreenGui.ResetOnSpawn = false

local function rCorner(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 6) end
local function rStroke(o, c, t) local s = Instance.new("UIStroke", o); s.Color = c or ActiveTheme.Accent; s.Thickness = t or 1.5; s.Transparency = 0.3; table.insert(UI_Elements.Strokes, s); return s end

local MainFrame = Instance.new("CanvasGroup", ScreenGui); MainFrame.Size = UDim2.new(0, 700, 0, 500); MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); MainFrame.BackgroundColor3 = ActiveTheme.BG; MainFrame.BackgroundTransparency = 0.08; rCorner(MainFrame, 8); local mainStroke = rStroke(MainFrame, ActiveTheme.Accent, 1.5); table.insert(UI_Elements.BG, MainFrame)
local mainGrad = Instance.new("UIGradient", mainStroke)
mainGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, ActiveTheme.Accent),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 20, 45)),
	ColorSequenceKeypoint.new(1, ActiveTheme.Accent)
})

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = input.Position; startPos = MainFrame.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local ModernFrame = Instance.new("Frame", ScreenGui)
ModernFrame.Name = "ModernFrame"
ModernFrame.Size = UDim2.new(0, 730, 0, 490)
ModernFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
ModernFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ModernFrame.BackgroundColor3 = ActiveTheme.BG
ModernFrame.BackgroundTransparency = 0.04
ModernFrame.ClipsDescendants = true
ModernFrame.Visible = false
rCorner(ModernFrame, 14)
local modernStroke = rStroke(ModernFrame, ActiveTheme.Accent, 1.5)
local modernGrad = Instance.new("UIGradient", modernStroke)
modernGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, ActiveTheme.Accent),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 30, 50)),
	ColorSequenceKeypoint.new(1, ActiveTheme.Accent)
})
table.insert(UI_Elements.BG, ModernFrame)

local mHeaderDivider, mLogo, ModernTabBar, ModernScroll
do
	local ModernHeader = Instance.new("Frame", ModernFrame)
	ModernHeader.Name = "ModernHeader"
	ModernHeader.Size = UDim2.new(1, 0, 0, 52)
	ModernHeader.BackgroundColor3 = Color3.fromRGB(12, 12, 17)
	ModernHeader.BackgroundTransparency = 0.2
	ModernHeader.BorderSizePixel = 0

	mHeaderDivider = Instance.new("Frame", ModernHeader)
	mHeaderDivider.Size = UDim2.new(1, 0, 0, 1)
	mHeaderDivider.Position = UDim2.new(0, 0, 1, -1)
	mHeaderDivider.BackgroundColor3 = ActiveTheme.Accent
	mHeaderDivider.BackgroundTransparency = 0.7
	mHeaderDivider.BorderSizePixel = 0
	table.insert(UI_Elements.Strokes, {Color = mHeaderDivider.BackgroundColor3, Parent = mHeaderDivider})

	mLogo = Instance.new("TextLabel", ModernHeader)
	mLogo.Size = UDim2.new(0, 75, 1, 0)
	mLogo.Position = UDim2.new(0, 16, 0, 0)
	mLogo.BackgroundTransparency = 1
	mLogo.Text = "✦ RICH"
	mLogo.TextColor3 = ActiveTheme.Accent
	mLogo.Font = Enum.Font.GothamBold
	mLogo.TextSize = 17
	mLogo.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(UI_Elements.Texts, mLogo)

	local mBadge = Instance.new("Frame", ModernHeader)
	mBadge.Size = UDim2.new(0, 34, 0, 18)
	mBadge.Position = UDim2.new(0, 88, 0.5, -9)
	mBadge.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	rCorner(mBadge, 5)
	local mBadgeStroke = Instance.new("UIStroke", mBadge)
	mBadgeStroke.Color = Color3.fromRGB(50, 50, 70)
	mBadgeStroke.Thickness = 1
	local mBadgeText = Instance.new("TextLabel", mBadge)
	mBadgeText.Size = UDim2.new(1, 0, 1, 0)
	mBadgeText.BackgroundTransparency = 1
	mBadgeText.Text = "v2.1"
	mBadgeText.TextColor3 = Color3.fromRGB(180, 185, 215)
	mBadgeText.Font = Enum.Font.GothamBold
	mBadgeText.TextSize = 10

	ModernTabBar = Instance.new("Frame", ModernHeader)
	ModernTabBar.Name = "ModernTabBar"
	ModernTabBar.Size = UDim2.new(0, 486, 0, 32)
	ModernTabBar.Position = UDim2.new(0.5, 0, 0.5, 0)
ModernTabBar.AnchorPoint = Vector2.new(0.5, 0.5)
ModernTabBar.ClipsDescendants = true
ModernTabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
ModernTabBar.BackgroundTransparency = 0.2
rCorner(ModernTabBar, 16)
local mTabBarStroke = Instance.new("UIStroke", ModernTabBar)
mTabBarStroke.Color = Color3.fromRGB(40, 40, 55)
mTabBarStroke.Thickness = 1

local mTabLayout = Instance.new("UIListLayout", ModernTabBar)
mTabLayout.FillDirection = Enum.FillDirection.Horizontal
mTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
mTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
mTabLayout.Padding = UDim.new(0, 3)

local mRightFrame = Instance.new("Frame", ModernHeader)
mRightFrame.Size = UDim2.new(0, 110, 1, 0)
mRightFrame.Position = UDim2.new(1, -118, 0, 0)
mRightFrame.BackgroundTransparency = 1

local mStatusPill = Instance.new("Frame", mRightFrame)
mStatusPill.Size = UDim2.new(0, 68, 0, 24)
mStatusPill.Position = UDim2.new(0, 0, 0.5, -12)
mStatusPill.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
rCorner(mStatusPill, 12)
local mStatusDot = Instance.new("Frame", mStatusPill)
mStatusDot.Size = UDim2.new(0, 6, 0, 6)
mStatusDot.Position = UDim2.new(0, 8, 0.5, -3)
mStatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 140)
rCorner(mStatusDot, 3)
local mStatusLbl = Instance.new("TextLabel", mStatusPill)
mStatusLbl.Size = UDim2.new(1, -18, 1, 0)
mStatusLbl.Position = UDim2.new(0, 16, 0, 0)
mStatusLbl.BackgroundTransparency = 1
mStatusLbl.Text = "ONLINE"
mStatusLbl.TextColor3 = Color3.fromRGB(200, 210, 230)
mStatusLbl.Font = Enum.Font.GothamBold
mStatusLbl.TextSize = 10

local mCloseBtn = Instance.new("TextButton", mRightFrame)
mCloseBtn.Size = UDim2.new(0, 26, 0, 26)
mCloseBtn.Position = UDim2.new(1, -28, 0.5, -13)
mCloseBtn.BackgroundColor3 = Color3.fromRGB(26, 18, 22)
mCloseBtn.Text = "✕"
mCloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
mCloseBtn.Font = Enum.Font.GothamBold
mCloseBtn.TextSize = 12
rCorner(mCloseBtn, 13)
local mCloseStroke = Instance.new("UIStroke", mCloseBtn)
mCloseStroke.Color = Color3.fromRGB(60, 30, 35)
mCloseStroke.Thickness = 1
mCloseBtn.MouseButton1Click:Connect(function()
	MenuVisible = false
	local tw = TweenService:Create(ModernFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.55, 0)})
	tw:Play()
	tw.Completed:Connect(function() if not MenuVisible then ModernFrame.Visible = false end end)
end)

	ModernScroll = Instance.new("ScrollingFrame", ModernFrame)
	ModernScroll.Name = "ModernScroll"
	ModernScroll.Size = UDim2.new(1, -24, 1, -66)
	ModernScroll.Position = UDim2.new(0, 12, 0, 58)
	ModernScroll.BackgroundTransparency = 1
	ModernScroll.BorderSizePixel = 0
	ModernScroll.ScrollBarThickness = 3
	ModernScroll.ScrollBarImageColor3 = ActiveTheme.Accent
	ModernScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local mScrollLayout = Instance.new("UIListLayout", ModernScroll)
	mScrollLayout.Padding = UDim.new(0, 6)
	local mScrollPad = Instance.new("UIPadding", ModernScroll)
	mScrollPad.PaddingTop = UDim.new(0, 4)
	mScrollPad.PaddingBottom = UDim.new(0, 10)
	mScrollPad.PaddingLeft = UDim.new(0, 4)
	mScrollPad.PaddingRight = UDim.new(0, 4)

	local mDragging, mDragInput, mDragStart, mStartPos
	ModernHeader.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mDragging = true; mDragStart = input.Position; mStartPos = ModernFrame.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then mDragging = false end end)
		end
	end)
	ModernHeader.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then mDragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == mDragInput and mDragging and ModernFrame then
			local delta = input.Position - mDragStart
			ModernFrame.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + delta.X, mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y)
		end
	end)
end

local NotifContainer = Instance.new("Frame", ScreenGui)
NotifContainer.Name = "NotifContainer"
NotifContainer.Size = UDim2.new(0, 260, 1, -40)
NotifContainer.Position = UDim2.new(1, -280, 0, 20)
NotifContainer.BackgroundTransparency = 1
local notifLayout = Instance.new("UIListLayout", NotifContainer)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.Padding = UDim.new(0, 8)

local function showNotification(title, msg, duration, nColor)
	if not Config.Notifications then return end
	duration = duration or 2.5
	local accent = nColor or (Config.RGBUI and Color3.fromHSV(RGBHue, 1, 1) or ActiveTheme.Accent)
	
	local card = Instance.new("Frame", NotifContainer)
	card.Size = UDim2.new(1, 0, 0, 46)
	card.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	card.BackgroundTransparency = 0.15
	rCorner(card, 8)
	rStroke(card, accent, 1)
	
	local bar = Instance.new("Frame", card)
	bar.Size = UDim2.new(0, 3, 1, -12)
	bar.Position = UDim2.new(0, 6, 0, 6)
	bar.BackgroundColor3 = accent
	rCorner(bar, 2)
	
	local tLbl = Instance.new("TextLabel", card)
	tLbl.Size = UDim2.new(1, -22, 0, 18)
	tLbl.Position = UDim2.new(0, 16, 0, 5)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 12
	tLbl.TextColor3 = accent
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Text = title
	
	local mLbl = Instance.new("TextLabel", card)
	mLbl.Size = UDim2.new(1, -22, 0, 16)
	mLbl.Position = UDim2.new(0, 16, 0, 23)
	mLbl.BackgroundTransparency = 1
	mLbl.Font = Enum.Font.Gotham
	mLbl.TextSize = 11
	mLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	mLbl.TextXAlignment = Enum.TextXAlignment.Left
	mLbl.Text = msg
	
	card.Position = UDim2.new(1, 40, 0, 0)
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	
	task.delay(duration, function()
		if card and card.Parent then
			local tw = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1})
			tw:Play()
			tw.Completed:Connect(function() card:Destroy() end)
		end
	end)
end

local DynamicIsland, islandStroke, islandGrad, IslandTitle, IslandArtist, IslandStats, IslandCover, ProgressFill, eqBars
do
	DynamicIsland = Instance.new("Frame", ScreenGui)
	DynamicIsland.Name = "DynamicIsland"
	DynamicIsland.Size = UDim2.new(0, 290, 0, 36)
	DynamicIsland.AnchorPoint = Vector2.new(0.5, 0)
	DynamicIsland.Position = UDim2.new(0.5, 0, 0, 14)
	DynamicIsland.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	DynamicIsland.BackgroundTransparency = 0.12
	DynamicIsland.Active = true
	DynamicIsland.Draggable = true
	DynamicIsland.ClipsDescendants = true
	rCorner(DynamicIsland, 18)
	islandStroke = rStroke(DynamicIsland, ActiveTheme.Accent, 1.2)
	islandGrad = Instance.new("UIGradient", islandStroke)
	islandGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, ActiveTheme.Accent),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 25, 35)),
		ColorSequenceKeypoint.new(1, ActiveTheme.Accent)
	})
	table.insert(UI_Elements.BG, DynamicIsland)

	local eqFrame = Instance.new("Frame", DynamicIsland)
	eqFrame.Name = "EqFrame"
	eqFrame.Size = UDim2.new(0, 22, 0, 18)
	eqFrame.Position = UDim2.new(0, 12, 0.5, -9)
	eqFrame.BackgroundTransparency = 1

	eqBars = {}
	for i = 1, 4 do
		local bar = Instance.new("Frame", eqFrame)
		bar.Size = UDim2.new(0, 3, 0.4 + (i * 0.15), 0)
		bar.Position = UDim2.new(0, (i - 1) * 5, 1, 0)
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.BackgroundColor3 = ActiveTheme.Accent
		rCorner(bar, 2)
		table.insert(eqBars, bar)
		table.insert(UI_Elements.Strokes, {Color = bar.BackgroundColor3, Parent = bar})
	end

	IslandCover = Instance.new("ImageLabel", DynamicIsland)
	IslandCover.Name = "IslandCover"
	IslandCover.Size = UDim2.new(0, 24, 0, 24)
	IslandCover.Position = UDim2.new(0, 40, 0.5, -12)
	IslandCover.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	IslandCover.BackgroundTransparency = 0.2
	IslandCover.Image = "rbxassetid://6031075938"
	IslandCover.ScaleType = Enum.ScaleType.Fit
rCorner(IslandCover, 6)

local textContainer = Instance.new("Frame", DynamicIsland)
textContainer.Name = "TextContainer"
textContainer.Size = UDim2.new(1, -150, 1, 0)
textContainer.Position = UDim2.new(0, 72, 0, 0)
textContainer.BackgroundTransparency = 1
textContainer.ClipsDescendants = true

	IslandTitle = Instance.new("TextLabel", textContainer)
	IslandTitle.Name = "IslandTitle"
	IslandTitle.Size = UDim2.new(1, 0, 0, 18)
	IslandTitle.Position = UDim2.new(0, 0, 0, 2)
	IslandTitle.BackgroundTransparency = 1
	IslandTitle.Font = Enum.Font.GothamBold
	IslandTitle.TextSize = 12
	IslandTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	IslandTitle.TextXAlignment = Enum.TextXAlignment.Left
	IslandTitle.TextTruncate = Enum.TextTruncate.AtEnd
	IslandTitle.Text = "Rich Premium"

	IslandArtist = Instance.new("TextLabel", textContainer)
	IslandArtist.Name = "IslandArtist"
	IslandArtist.Size = UDim2.new(1, 0, 0, 14)
	IslandArtist.Position = UDim2.new(0, 0, 0, 18)
	IslandArtist.BackgroundTransparency = 1
	IslandArtist.Font = Enum.Font.GothamSemibold
	IslandArtist.TextSize = 10
	IslandArtist.TextColor3 = ActiveTheme.Accent
	IslandArtist.TextXAlignment = Enum.TextXAlignment.Left
	IslandArtist.TextTruncate = Enum.TextTruncate.AtEnd
	IslandArtist.Text = "v2.1 • Ready"
	table.insert(UI_Elements.Texts, IslandArtist)

	IslandStats = Instance.new("TextLabel", DynamicIsland)
	IslandStats.Name = "IslandStats"
	IslandStats.Size = UDim2.new(0, 65, 0, 20)
	IslandStats.Position = UDim2.new(1, -75, 0.5, -10)
	IslandStats.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	IslandStats.BackgroundTransparency = 0.4
	IslandStats.Font = Enum.Font.GothamBold
	IslandStats.TextSize = 10
	IslandStats.TextColor3 = ActiveTheme.Accent
	IslandStats.Text = "144 FPS"
	rCorner(IslandStats, 10)
	table.insert(UI_Elements.Texts, IslandStats)

	local ProgressBg = Instance.new("Frame", DynamicIsland)
	ProgressBg.Name = "ProgressBg"
	ProgressBg.Size = UDim2.new(1, -30, 0, 4)
	ProgressBg.Position = UDim2.new(0, 15, 1, -12)
	ProgressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	ProgressBg.BackgroundTransparency = 0.5
	ProgressBg.Visible = false
	rCorner(ProgressBg, 2)

	ProgressFill = Instance.new("Frame", ProgressBg)
	ProgressFill.Name = "ProgressFill"
	ProgressFill.Size = UDim2.new(0.35, 0, 1, 0)
	ProgressFill.BackgroundColor3 = ActiveTheme.Accent
	rCorner(ProgressFill, 2)
	table.insert(UI_Elements.Strokes, {Color = ProgressFill.BackgroundColor3, Parent = ProgressFill})

local function sendMediaControl(action)
	task.spawn(function()
		pcall(function()
			local httpFn = (type(request) == "function" and request)
				or (type(http_request) == "function" and http_request)
				or (syn and type(syn.request) == "function" and syn.request)
				or (http and type(http.request) == "function" and http.request)
				or (fluxus and type(fluxus.request) == "function" and fluxus.request)
			if httpFn then
				httpFn({Url = "http://127.0.0.1:9876/control?action=" .. action, Method = "GET"})
			elseif game and game.HttpGet then
				game:HttpGet("http://127.0.0.1:9876/control?action=" .. action)
			end
		end)
	end)
end

local MediaCtrlFrame = Instance.new("Frame", DynamicIsland)
MediaCtrlFrame.Name = "MediaCtrlFrame"
MediaCtrlFrame.Size = UDim2.new(0, 105, 0, 24)
MediaCtrlFrame.Position = UDim2.new(1, -120, 0.5, -4)
MediaCtrlFrame.BackgroundTransparency = 1
MediaCtrlFrame.Visible = false
MediaCtrlFrame.ZIndex = 15

local function createMediaBtn(text, posX, width, action)
	local b = Instance.new("TextButton", MediaCtrlFrame)
	b.Size = UDim2.new(0, width, 0, 22)
	b.Position = UDim2.new(0, posX, 0.5, -11)
	b.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	b.BackgroundTransparency = 0.2
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.ZIndex = 16
	rCorner(b, 6)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = ActiveTheme.Accent, TextColor3 = Color3.fromRGB(20,20,25)}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 24, 32), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
	end)
	b.MouseButton1Click:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.08), {Size = UDim2.new(0, width - 2, 0, 20)}):Play()
		task.delay(0.08, function()
			TweenService:Create(b, TweenInfo.new(0.12), {Size = UDim2.new(0, width, 0, 22)}):Play()
		end)
		sendMediaControl(action)
		if showNotification then
			local actNames = {prev = "Previous Track", play_pause = "Play / Pause", next = "Next Track"}
			showNotification("Music Control", actNames[action] or action, 1.5)
		end
	end)
	return b
end

local btnPrev = createMediaBtn("⏮", 0, 28, "prev")
local btnPlay = createMediaBtn("⏯", 34, 34, "play_pause")
local btnNext = createMediaBtn("⏭", 74, 28, "next")

local islandExpanded = false
local function toggleIslandExpand(state)
	if state == nil then islandExpanded = not islandExpanded else islandExpanded = state end
	Config.IslandExpanded = islandExpanded
	
	if islandExpanded then
		TweenService:Create(DynamicIsland, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 390, 0, 86)
		}):Play()
		rCorner(DynamicIsland, 24)
		
		TweenService:Create(IslandCover, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, 52, 0, 52),
			Position = UDim2.new(0, 15, 0.5, -26)
		}):Play()
		rCorner(IslandCover, 10)
		
		textContainer.Position = UDim2.new(0, 78, 0, 12)
		textContainer.Size = UDim2.new(1, -210, 0, 42)
		IslandTitle.TextSize = 13
		IslandArtist.TextSize = 11
		
		eqFrame.Position = UDim2.new(1, -30, 0, 14)
		IslandStats.Position = UDim2.new(1, -85, 0, 10)
		MediaCtrlFrame.Visible = true
		ProgressBg.Visible = true
	else
		TweenService:Create(DynamicIsland, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 290, 0, 36)
		}):Play()
		rCorner(DynamicIsland, 18)
		
		TweenService:Create(IslandCover, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 40, 0.5, -12)
		}):Play()
		rCorner(IslandCover, 6)
		
		textContainer.Position = UDim2.new(0, 72, 0, 0)
		textContainer.Size = UDim2.new(1, -150, 1, 0)
		IslandTitle.TextSize = 12
		IslandArtist.TextSize = 10
		
		eqFrame.Position = UDim2.new(0, 12, 0.5, -9)
		IslandStats.Position = UDim2.new(1, -75, 0.5, -10)
		MediaCtrlFrame.Visible = false
		ProgressBg.Visible = false
	end
end

local islandBtn = Instance.new("TextButton", DynamicIsland)
islandBtn.Size = UDim2.new(1, 0, 1, 0)
islandBtn.BackgroundTransparency = 1
islandBtn.ZIndex = 1
islandBtn.Text = ""
islandBtn.MouseButton1Click:Connect(function() toggleIslandExpand() end)
islandBtn.MouseEnter:Connect(function() if Config.IslandExpandOnHover and not islandExpanded then toggleIslandExpand(true) end end)
islandBtn.MouseLeave:Connect(function() if Config.IslandExpandOnHover and islandExpanded then toggleIslandExpand(false) end end)
end

local Title = Instance.new("TextLabel", MainFrame); Title.Size = UDim2.new(1, 0, 0, 45); Title.BackgroundTransparency = 1; Title.Text = "R I C H  P R E M I U M"; Title.Font = Enum.Font.GothamBold; Title.TextColor3 = ActiveTheme.Accent; Title.TextSize = 20; table.insert(UI_Elements.Texts, Title)
local TopLine = Instance.new("Frame", MainFrame); TopLine.Size = UDim2.new(1, 0, 0, 2); TopLine.Position = UDim2.new(0, 0, 0, 0); TopLine.BackgroundColor3 = ActiveTheme.Accent; table.insert(UI_Elements.Strokes, {Color = TopLine.BackgroundColor3, Parent = TopLine})
local topLineGrad = Instance.new("UIGradient", TopLine)
topLineGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 20)),
	ColorSequenceKeypoint.new(0.5, ActiveTheme.Accent),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
})
local TabsFrame = Instance.new("ScrollingFrame", MainFrame); TabsFrame.Size = UDim2.new(0, 160, 1, -60); TabsFrame.Position = UDim2.new(0, 15, 0, 50); TabsFrame.BackgroundColor3 = ActiveTheme.Panel; TabsFrame.BackgroundTransparency = 1; TabsFrame.BorderSizePixel = 0; TabsFrame.ScrollBarThickness = 0; rCorner(TabsFrame, 4); Instance.new("UIListLayout", TabsFrame).Padding = UDim.new(0, 4); Instance.new("UIPadding", TabsFrame).PaddingTop = UDim.new(0, 4)
local SettingsFrame = Instance.new("ScrollingFrame", MainFrame); SettingsFrame.Size = UDim2.new(0, 490, 1, -60); SettingsFrame.Position = UDim2.new(0, 190, 0, 50); SettingsFrame.BackgroundColor3 = ActiveTheme.Panel; SettingsFrame.BackgroundTransparency = 0.5; SettingsFrame.BorderSizePixel = 0; SettingsFrame.ScrollBarThickness = 2; SettingsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; rCorner(SettingsFrame, 6); Instance.new("UIListLayout", SettingsFrame).Padding = UDim.new(0, 6); Instance.new("UIPadding", SettingsFrame).PaddingTop = UDim.new(0, 6); Instance.new("UIPadding", SettingsFrame).PaddingLeft = UDim.new(0, 10)

local ArrayListFrame = Instance.new("Frame", ScreenGui); ArrayListFrame.Size = UDim2.new(0, 180, 0, 320); ArrayListFrame.Position = UDim2.new(1, -200, 0, 20); ArrayListFrame.BackgroundColor3 = ActiveTheme.BG; ArrayListFrame.BackgroundTransparency = 0.25; ArrayListFrame.BorderSizePixel = 0; rCorner(ArrayListFrame, 16); rStroke(ArrayListFrame, ActiveTheme.Accent, 1.5); table.insert(UI_Elements.BG, ArrayListFrame)
local ArrayListLabel = Instance.new("TextLabel", ArrayListFrame); ArrayListLabel.Size = UDim2.new(1, -20, 1, -20); ArrayListLabel.Position = UDim2.new(0, 10, 0, 10); ArrayListLabel.BackgroundTransparency = 1; ArrayListLabel.TextColor3 = ActiveTheme.Accent; ArrayListLabel.Font = Enum.Font.GothamSemibold; ArrayListLabel.TextSize = 13; ArrayListLabel.TextXAlignment = Enum.TextXAlignment.Right; ArrayListLabel.TextYAlignment = Enum.TextYAlignment.Top; table.insert(UI_Elements.Texts, ArrayListLabel)

local KeybindsFrame = Instance.new("Frame", ScreenGui); KeybindsFrame.Size = UDim2.new(0, 180, 0, 0); KeybindsFrame.AutomaticSize = Enum.AutomaticSize.Y; KeybindsFrame.Position = UDim2.new(1, -200, 0, 360); KeybindsFrame.BackgroundColor3 = ActiveTheme.BG; KeybindsFrame.BackgroundTransparency = 0.25; KeybindsFrame.BorderSizePixel = 0; KeybindsFrame.Active = true; KeybindsFrame.Draggable = true; rCorner(KeybindsFrame, 16); rStroke(KeybindsFrame, ActiveTheme.Accent, 1.5); table.insert(UI_Elements.BG, KeybindsFrame)
local KeybindsPad = Instance.new("UIPadding", KeybindsFrame); KeybindsPad.PaddingTop = UDim.new(0, 10); KeybindsPad.PaddingBottom = UDim.new(0, 10); KeybindsPad.PaddingLeft = UDim.new(0, 10); KeybindsPad.PaddingRight = UDim.new(0, 10)
local KeybindsLabel = Instance.new("TextLabel", KeybindsFrame); KeybindsLabel.Size = UDim2.new(1, 0, 0, 0); KeybindsLabel.AutomaticSize = Enum.AutomaticSize.Y; KeybindsLabel.Position = UDim2.new(0, 0, 0, 0); KeybindsLabel.BackgroundTransparency = 1; KeybindsLabel.TextColor3 = ActiveTheme.Accent; KeybindsLabel.Font = Enum.Font.GothamSemibold; KeybindsLabel.TextSize = 13; KeybindsLabel.TextXAlignment = Enum.TextXAlignment.Right; KeybindsLabel.TextYAlignment = Enum.TextYAlignment.Top; table.insert(UI_Elements.Texts, KeybindsLabel)

local DmgLogFrame = Instance.new("Frame", ScreenGui); DmgLogFrame.Size = UDim2.new(0, 280, 0, 40); DmgLogFrame.Position = UDim2.new(1, 20, 0.5, 0); DmgLogFrame.BackgroundColor3 = ActiveTheme.BG; DmgLogFrame.BackgroundTransparency = 0.15; rCorner(DmgLogFrame, 8); rStroke(DmgLogFrame, Color3.fromRGB(255, 50, 50), 2)
local DmgLogText = Instance.new("TextLabel", DmgLogFrame); DmgLogText.Size = UDim2.new(1, 0, 1, 0); DmgLogText.BackgroundTransparency = 1; DmgLogText.Font = Enum.Font.GothamBold; DmgLogText.TextSize = 14; DmgLogText.TextColor3 = Color3.fromRGB(240, 240, 240)

local SpecFrame = Instance.new("Frame", ScreenGui)
SpecFrame.Size = UDim2.new(0, 240, 0, 200)
SpecFrame.Position = UDim2.new(0, 12, 0, 12)
SpecFrame.BackgroundColor3 = Color3.fromRGB(5,5,5)
SpecFrame.BackgroundTransparency = 0.2
SpecFrame.Visible = false
SpecFrame.ClipsDescendants = true
rCorner(SpecFrame, 12)
rStroke(SpecFrame, Color3.fromRGB(0, 200, 255), 1.5)
table.insert(UI_Elements.BG, SpecFrame)

local SpecLabel = Instance.new("TextLabel", SpecFrame)
SpecLabel.Size = UDim2.new(1, 0, 0, 24)
SpecLabel.BackgroundTransparency = 1
SpecLabel.Text = "SPECTATE TARGET"
SpecLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
SpecLabel.Font = Enum.Font.GothamBold
SpecLabel.TextSize = 11
SpecLabel.TextXAlignment = Enum.TextXAlignment.Left
SpecLabel.Position = UDim2.new(0, 10, 0, 4)
table.insert(UI_Elements.Texts, SpecLabel)

local SpecViewport = Instance.new("ViewportFrame", SpecFrame)
SpecViewport.Size = UDim2.new(1, 0, 1, -30)
SpecViewport.Position = UDim2.new(0, 0, 0, 28)
SpecViewport.BackgroundColor3 = Color3.fromRGB(10,10,15)
SpecViewport.CurrentCamera = Instance.new("Camera")

local SpecCamPart = Instance.new("Part", Workspace)
SpecCamPart.Anchored = true
SpecCamPart.CanCollide = false
SpecCamPart.Transparency = 1
SpecCamPart.Size = Vector3.new(0.5,0.5,0.5)
SpecCamPart.Parent = Workspace

specEnvFolder = Instance.new("Folder", SpecViewport)
spec3DTracer = Instance.new("Part", SpecViewport)
spec3DTracer.Anchored = true
spec3DTracer.CanCollide = false
spec3DTracer.Material = Enum.Material.Neon
spec3DTracer.Transparency = 1

local RadarFrame = Instance.new("Frame", ScreenGui); RadarFrame.Size = UDim2.new(0, 200, 0, 200); RadarFrame.Position = UDim2.new(0, 20, 0, 20); RadarFrame.BackgroundColor3 = ActiveTheme.BG; RadarFrame.BackgroundTransparency = 0.25; RadarFrame.ClipsDescendants = true; RadarFrame.Visible = false; RadarFrame.Active = true; RadarFrame.Draggable = true; rCorner(RadarFrame, 100); rStroke(RadarFrame, ActiveTheme.Accent, 2); table.insert(UI_Elements.BG, RadarFrame)
local rLineX = Instance.new("Frame", RadarFrame); rLineX.Size = UDim2.new(1, 0, 0, 1); rLineX.Position = UDim2.new(0, 0, 0.5, 0); rLineX.BackgroundColor3 = ActiveTheme.Accent; rLineX.BackgroundTransparency = 0.5; rLineX.BorderSizePixel = 0; table.insert(UI_Elements.Strokes, {Color = rLineX.BackgroundColor3, Parent = rLineX})
local rLineY = Instance.new("Frame", RadarFrame); rLineY.Size = UDim2.new(0, 1, 1, 0); rLineY.Position = UDim2.new(0.5, 0, 0, 0); rLineY.BackgroundColor3 = ActiveTheme.Accent; rLineY.BackgroundTransparency = 0.5; rLineY.BorderSizePixel = 0; table.insert(UI_Elements.Strokes, {Color = rLineY.BackgroundColor3, Parent = rLineY})
local RadarCenter = Instance.new("Frame", RadarFrame); RadarCenter.Size = UDim2.new(0, 4, 0, 4); RadarCenter.Position = UDim2.new(0.5, -2, 0.5, -2); RadarCenter.BackgroundColor3 = Color3.fromRGB(255, 255, 255); rCorner(RadarCenter, 2)

local lastDmgTween = nil
local function showDamageUI(targetName, damage, hpLeft)
	if Config.HitSound then pcall(function() hitSound:Play() end) end
	if not Config.DamageInd then return end
	DmgLogText.Text = string.format("HIT %s | DMG: -%d | HP: %d", targetName, math.floor(damage), math.floor(hpLeft))
	if lastDmgTween then lastDmgTween:Cancel() end
	TweenService:Create(DmgLogFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -300, 0.5, 0)}):Play()
	task.delay(2, function() if DmgLogFrame.Position == UDim2.new(1, -300, 0.5, 0) then lastDmgTween = TweenService:Create(DmgLogFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0.5, 0)}); lastDmgTween:Play() end end)
end

local function sendToxicMessage()
	local msg = ToxicMessages[math.random(1, #ToxicMessages)]
	pcall(function() game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All") end)
	pcall(function() game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(msg) end)
end

local activeTabBtn = nil
local DropdownFrames = {}
local function isDropdownChild(parent)
	if not parent then return false end
	for _, df in pairs(DropdownFrames) do
		if parent == df or parent:IsDescendantOf(df) then return true end
	end
	return false
end
local function clearSettings() for _, c in pairs(SettingsFrame:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end end

local PopupFrame = Instance.new("Frame", ScreenGui)
PopupFrame.Name = "PopupFrame"
PopupFrame.Size = UDim2.new(0, 224, 0, 0)
PopupFrame.AutomaticSize = Enum.AutomaticSize.Y
PopupFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
PopupFrame.BackgroundTransparency = 0.05
PopupFrame.Visible = false
PopupFrame.ZIndex = 120
rCorner(PopupFrame, 8)
local popupStroke = rStroke(PopupFrame, ActiveTheme.Accent, 1.5)
table.insert(UI_Elements.BG, PopupFrame)

local ppLayout = Instance.new("UIListLayout", PopupFrame)
ppLayout.Padding = UDim.new(0, 5)
local ppPad = Instance.new("UIPadding", PopupFrame)
ppPad.PaddingTop = UDim.new(0, 6)
ppPad.PaddingBottom = UDim.new(0, 8)
ppPad.PaddingLeft = UDim.new(0, 6)
ppPad.PaddingRight = UDim.new(0, 6)

local currentPopupConfigKey = nil
local function closePopup()
	PopupFrame.Visible = false
	currentPopupConfigKey = nil
	for _, c in pairs(PopupFrame:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and PopupFrame.Visible then
		local pos = input.Position
		local px, py = PopupFrame.AbsolutePosition.X, PopupFrame.AbsolutePosition.Y
		local pw, ph = PopupFrame.AbsoluteSize.X, PopupFrame.AbsoluteSize.Y
		if pos.X < px - 10 or pos.X > px + pw + 10 or pos.Y < py - 10 or pos.Y > py + ph + 10 then
			closePopup()
		end
	end
end)

local function openPopup(btn, configKey, buildFunc)
	if currentPopupConfigKey == configKey and PopupFrame.Visible then closePopup(); return end
	closePopup()
	currentPopupConfigKey = configKey

	local pHeader = Instance.new("Frame", PopupFrame)
	pHeader.Size = UDim2.new(1, 0, 0, 22)
	pHeader.BackgroundTransparency = 1
	pHeader.ZIndex = 121

	local pTitle = Instance.new("TextLabel", pHeader)
	pTitle.Size = UDim2.new(1, -26, 1, 0)
	pTitle.Position = UDim2.new(0, 4, 0, 0)
	pTitle.BackgroundTransparency = 1
	pTitle.Text = tostring(configKey):upper() .. " SETTINGS"
	pTitle.TextColor3 = ActiveTheme.Accent
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextSize = 11
	pTitle.TextXAlignment = Enum.TextXAlignment.Left
	pTitle.ZIndex = 122
	table.insert(UI_Elements.Texts, pTitle)

	local pClose = Instance.new("TextButton", pHeader)
	pClose.Size = UDim2.new(0, 20, 0, 20)
	pClose.Position = UDim2.new(1, -22, 0, 1)
	pClose.BackgroundColor3 = Color3.fromRGB(28, 18, 22)
	pClose.Text = "✕"
	pClose.TextColor3 = Color3.fromRGB(255, 120, 120)
	pClose.Font = Enum.Font.GothamBold
	pClose.TextSize = 10
	pClose.ZIndex = 122
	rCorner(pClose, 4)
	pClose.MouseButton1Click:Connect(closePopup)

	local pSep = Instance.new("Frame", PopupFrame)
	pSep.Size = UDim2.new(1, 0, 0, 1)
	pSep.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
	pSep.BorderSizePixel = 0
	pSep.ZIndex = 121

	buildFunc(PopupFrame)

	local px, py = btn.AbsolutePosition.X, btn.AbsolutePosition.Y
	local screenW = Workspace.CurrentCamera.ViewportSize.X
	local popupX = px + btn.AbsoluteSize.X + 10
	if popupX + 235 > screenW then
		popupX = px - 235
	end
	PopupFrame.Position = UDim2.new(0, popupX, 0, py)
	PopupFrame.Visible = true
end

local function createPopupBtn(parent, btn, configKey, buildFunc)
	local isPopup = (parent == PopupFrame)
	local z = isPopup and 123 or 3
	local dots = Instance.new("TextButton", btn)
	dots.Size = UDim2.new(0, 28, 0, 24)
	dots.Position = UDim2.new(1, -34, 0.5, -12)
	dots.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
	dots.BackgroundTransparency = 0.2
	dots.ZIndex = z
	dots.Text = "⚙"
	dots.TextColor3 = Color3.fromRGB(180, 185, 205)
	dots.Font = Enum.Font.GothamBold
	dots.TextSize = 13
	rCorner(dots, 6)
	local dStroke = Instance.new("UIStroke", dots)
	dStroke.Color = Color3.fromRGB(50, 50, 68)
	dStroke.Thickness = 1

	dots.MouseEnter:Connect(function()
		TweenService:Create(dots, TweenInfo.new(0.2), {BackgroundColor3 = ActiveTheme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(dStroke, TweenInfo.new(0.2), {Color = ActiveTheme.Accent}):Play()
	end)
	dots.MouseLeave:Connect(function()
		TweenService:Create(dots, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 36), TextColor3 = Color3.fromRGB(180, 185, 205)}):Play()
		TweenService:Create(dStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 68)}):Play()
	end)
	dots.MouseButton1Click:Connect(function()
		openPopup(btn, configKey, buildFunc)
	end)
end

local function createButton(parent, text, sizeX, onClick, buildPopup)
	local isPopup = (parent == PopupFrame)
	local isMain = (parent == SettingsFrame)
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local w = isModern and 690 or (dropW or ((isPopup and 212) or ((parent ~= SettingsFrame and sizeX == 450) and 180 or sizeX)))
	local z = isPopup and 122 or (isDrop and 22 or 2)

	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(0, w, 0, 36)
	b.BackgroundColor3 = isPopup and Color3.fromRGB(22, 22, 32) or ActiveTheme.Btn
	b.BackgroundTransparency = 0.1
	b.Text = "  " .. text
	b.TextColor3 = Color3.fromRGB(245, 245, 255)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = isDrop and 12 or 13
	b.AutoButtonColor = false
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.ZIndex = z
	rCorner(b, 6)
	local bStroke = Instance.new("UIStroke", b)
	bStroke.Color = isPopup and Color3.fromRGB(50, 50, 72) or Color3.fromRGB(38, 38, 52)
	bStroke.Thickness = 1
	bStroke.Transparency = 0.4

	b.MouseEnter:Connect(function()
		if activeTabBtn ~= b then
			TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = isPopup and Color3.fromRGB(32, 32, 46) or ActiveTheme.BtnHover, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = ActiveTheme.Accent, Transparency = 0.1}):Play()
		end
	end)
	b.MouseLeave:Connect(function()
		if activeTabBtn ~= b then
			TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = isPopup and Color3.fromRGB(22, 22, 32) or ActiveTheme.Btn, TextColor3 = Color3.fromRGB(245, 245, 255)}):Play()
			TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = isPopup and Color3.fromRGB(50, 50, 72) or Color3.fromRGB(38, 38, 52), Transparency = 0.4}):Play()
		end
	end)
	b.MouseButton1Click:Connect(function()
		local t = TweenService:Create(b, TweenInfo.new(0.08, Enum.EasingStyle.Quint), {Size = UDim2.new(0, w - 4, 0, 33)})
		t:Play()
		t.Completed:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, w, 0, 36)}):Play()
		end)
		if onClick then onClick(b) end
	end)
	if buildPopup then createPopupBtn(parent, b, text, buildPopup) end
	return b
end

local function createTextBox(parent, placeholder, defaultVal, callback)
	local isPopup = (parent == PopupFrame)
	local isMain = (parent == SettingsFrame)
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local w = isModern and 690 or (dropW or (isMain and 450 or (isPopup and 212 or 180)))
	local z = isPopup and 122 or (isDrop and 22 or 2)

	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(0, w, 0, 38)
	card.BackgroundColor3 = isPopup and Color3.fromRGB(20, 20, 28) or Color3.fromRGB(16, 16, 22)
	card.BackgroundTransparency = 0.1
	card.ZIndex = z
	rCorner(card, 6)
	local cardStroke = Instance.new("UIStroke", card)
	cardStroke.Color = isPopup and Color3.fromRGB(50, 50, 72) or Color3.fromRGB(38, 38, 52)
	cardStroke.Thickness = 1
	cardStroke.Transparency = 0.4

	local inputW = isDrop and 58 or (isModern and 190 or (isMain and 160 or 80))
	local label = Instance.new("TextLabel", card)
	label.Size = UDim2.new(1, -(inputW + 16), 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.ZIndex = z + 1
	label.Text = placeholder
	label.TextColor3 = Color3.fromRGB(240, 240, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = isDrop and 11 or 13
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = Enum.TextXAlignment.Left

	local box = Instance.new("TextBox", card)
	box.Size = UDim2.new(0, inputW, 0, 26)
	box.Position = UDim2.new(1, -(inputW + 6), 0.5, -13)
	box.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
	box.BackgroundTransparency = 0.1
	box.ZIndex = z + 1
	box.Text = tostring(defaultVal)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderText = tostring(defaultVal)
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 175)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.ClearTextOnFocus = false
	rCorner(box, 6)
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(60, 60, 85)
	boxStroke.Thickness = 1

	box.Focused:Connect(function()
		TweenService:Create(boxStroke, TweenInfo.new(0.2), {Color = ActiveTheme.Accent}):Play()
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34, 34, 50)}):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(boxStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 60, 85)}):Play()
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)}):Play()
		local val = box.Text
		if val == "" then
			val = tostring(defaultVal)
			box.Text = val
		end
		callback(val)
	end)

	return card
end

local function addToggle(parent, text, configKey, onToggle, buildPopup)
	local state = Config[configKey]
	local isPopup = (parent == PopupFrame)
	local isMain = (parent == SettingsFrame)
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local w = isModern and 690 or (dropW or (isPopup and 212 or (isMain and 450 or 180)))
	local z = isPopup and 122 or (isDrop and 22 or 2)

	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0, w, 0, 36)
	btn.BackgroundColor3 = isPopup and Color3.fromRGB(20, 20, 30) or ActiveTheme.Btn
	btn.BackgroundTransparency = 0.1
	btn.Text = "  " .. text
	btn.TextColor3 = Color3.fromRGB(245, 245, 255)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = isDrop and 12 or 13
	btn.AutoButtonColor = false
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.ZIndex = z
	rCorner(btn, 6)
	local tStroke = Instance.new("UIStroke", btn)
	tStroke.Color = isPopup and Color3.fromRGB(50, 50, 72) or Color3.fromRGB(38, 38, 52)
	tStroke.Thickness = 1
	tStroke.Transparency = 0.4

	local switchBg = Instance.new("Frame", btn)
	switchBg.Size = UDim2.new(0, 38, 0, 20)
	switchBg.Position = UDim2.new(1, buildPopup and -76 or -46, 0.5, -10)
	switchBg.BackgroundColor3 = state and ActiveTheme.Accent or Color3.fromRGB(42, 42, 54)
	switchBg.ZIndex = z + 1
	rCorner(switchBg, 10)
	local switchStroke = Instance.new("UIStroke", switchBg)
	switchStroke.Color = state and ActiveTheme.Accent or Color3.fromRGB(60, 60, 75)
	switchStroke.Thickness = 1

	local switchKnob = Instance.new("Frame", switchBg)
	switchKnob.Size = UDim2.new(0, 16, 0, 16)
	switchKnob.Position = UDim2.new(0, state and 20 or 2, 0.5, -8)
	switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	switchKnob.ZIndex = z + 2
	rCorner(switchKnob, 8)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = isPopup and Color3.fromRGB(30, 30, 44) or ActiveTheme.BtnHover, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(tStroke, TweenInfo.new(0.2), {Color = ActiveTheme.Accent, Transparency = 0.1}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = isPopup and Color3.fromRGB(20, 20, 30) or ActiveTheme.Btn, TextColor3 = Color3.fromRGB(245, 245, 255)}):Play()
		TweenService:Create(tStroke, TweenInfo.new(0.2), {Color = isPopup and Color3.fromRGB(50, 50, 72) or Color3.fromRGB(38, 38, 52), Transparency = 0.4}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		Config[configKey] = not Config[configKey]
		local st = Config[configKey]
		local acc = Config.RGBUI and Color3.fromHSV(RGBHue, 1, 1) or ActiveTheme.Accent
		TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quint), {Size = UDim2.new(0, w - 4, 0, 33)}):Play()
		task.delay(0.08, function()
			TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, w, 0, 36)}):Play()
		end)
		TweenService:Create(switchBg, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = st and acc or Color3.fromRGB(42, 42, 54)}):Play()
		TweenService:Create(switchStroke, TweenInfo.new(0.25), {Color = st and acc or Color3.fromRGB(60, 60, 75)}):Play()
		TweenService:Create(switchKnob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, st and 20 or 2, 0.5, -8)}):Play()
		if showNotification then showNotification(text, st and "Module Enabled" or "Module Disabled", 2, st and acc or Color3.fromRGB(160, 50, 50)) end
		if onToggle then onToggle(st) end
	end)
	if buildPopup then createPopupBtn(parent, btn, configKey, buildPopup) end
	return btn
end

local function addBind(parent, featureName, bindKey)
	local isPopup = (parent == PopupFrame)
	local isMain = (parent == SettingsFrame)
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local w = isModern and 690 or (dropW or (isPopup and 212 or (isMain and 450 or 180)))
	local z = isPopup and 122 or (isDrop and 22 or 2)
	createButton(parent, "Bind: " .. (Binds[bindKey] and Binds[bindKey].Name or "None"), w, function(b)
		b.Text = "  Press any key..."
		b.TextColor3 = ActiveTheme.Accent
		local input = UserInputService.InputBegan:Wait()
		local key = (input.UserInputType == Enum.UserInputType.Keyboard) and input.KeyCode or input.UserInputType
		if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Escape or key == Enum.KeyCode.Delete then 
			Binds[bindKey] = nil
			b.Text = "  Bind: None" 
			b.TextColor3 = Color3.fromRGB(245, 245, 255)
		else 
			Binds[bindKey] = key
			b.Text = "  Bind: " .. key.Name 
			b.TextColor3 = Color3.fromRGB(245, 245, 255)
		end
	end)
end

local function ApplyWorldSettings()
	if Config.FullBright then Lighting.GlobalShadows = false; Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1) else Lighting.GlobalShadows = origGlobalShadows or true; Lighting.Ambient = origAmbient or Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient = origOutdoorAmbient or Color3.fromRGB(127,127,127) end
	if Config.NightMode then Lighting.Ambient = Color3.fromRGB(10,10,30); Lighting.Brightness = 0.5; Lighting.ClockTime = 0 else Lighting.Brightness = origBrightness or 1; Lighting.ClockTime = origClockTime or 14 end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if Config.ThemeFog then if atmo then atmo.Density = 0 end; Lighting.FogColor = ActiveTheme.Accent; Lighting.FogEnd = 300; Lighting.FogStart = 50 else if atmo then atmo.Density = 0.3 end; Lighting.FogColor = origFogColor or Color3.fromRGB(192, 192, 192); Lighting.FogEnd = origFogEnd or 100000; Lighting.FogStart = origFogStart or 0 end
	if Config.AestheticWorld then if not aestheticBloom then aestheticBloom = Instance.new("BloomEffect", Lighting); aestheticBloom.Intensity = 1.2; aestheticBloom.Size = 24; aestheticBloom.Threshold = 0.8; aestheticCC = Instance.new("ColorCorrectionEffect", Lighting); aestheticCC.TintColor = ActiveTheme.Accent end else if aestheticBloom then aestheticBloom:Destroy(); aestheticBloom = nil end; if aestheticCC then aestheticCC:Destroy(); aestheticCC = nil end end
	if Config.XRay then for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") and v.Name ~= "Terrain" then if originalTransparencies[v] == nil then originalTransparencies[v] = v.Transparency; originalMaterials[v] = v.Material end; v.Transparency = 0.6; v.Material = Enum.Material.SmoothPlastic end end else for v, t in pairs(originalTransparencies) do if v and v.Parent then v.Transparency = t; v.Material = originalMaterials[v] or Enum.Material.Plastic end end; originalTransparencies, originalMaterials = {}, {} end
	if Config.Wireframe then for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v.Name ~= "Terrain" then local sb = Instance.new("SelectionBox", v); sb.Adornee = v; sb.Color3 = ActiveTheme.Accent; sb.LineThickness = 0.05; sb.SurfaceTransparency = 1; v.Transparency = 1 end end else for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v:FindFirstChildOfClass("SelectionBox") then v:FindFirstChildOfClass("SelectionBox"):Destroy(); v.Transparency = originalTransparencies[v] or 0 end end end
end

local function spawnShockwave(pos, color)
	local p = Instance.new("Part", Workspace); p.Size = Vector3.new(1,1,1); p.Position = pos; p.Anchored = true; p.CanCollide = false; p.Shape = Enum.PartType.Ball; p.Material = Enum.Material.Neon; p.Color = color
	TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(25, 25, 25), Transparency = 1}):Play(); task.delay(0.6, function() p:Destroy() end)
end
local function spawnLightning(pos, color)
	local p = Instance.new("Part", Workspace); p.Size = Vector3.new(2, 200, 2); p.Position = pos + Vector3.new(0, 100, 0); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = color
	TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = Vector3.new(0, 200, 0), Transparency = 1}):Play(); task.delay(0.5, function() p:Destroy() end)
end
local function spawnBlood(pos)
	local a = Instance.new("Attachment", Workspace.Terrain); a.Position = pos
	local p = Instance.new("ParticleEmitter", a); p.Color = ColorSequence.new(Color3.fromRGB(150, 0, 0)); p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
	p.Speed = NumberRange.new(15, 30); p.SpreadAngle = Vector2.new(360, 360); p.Lifetime = NumberRange.new(1, 2); p.Rate = 100; p:Emit(50); task.delay(2, function() a:Destroy() end)
end
local function spawnSouls(pos, color)
	local a = Instance.new("Attachment", Workspace.Terrain); a.Position = pos
	local p = Instance.new("ParticleEmitter", a); p.Color = ColorSequence.new(color); p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	p.Speed = NumberRange.new(5, 10); p.VelocitySpread = 20; p.Acceleration = Vector3.new(0, 15, 0); p.Lifetime = NumberRange.new(2, 3); p.Rate = 100; p.Texture = "rbxassetid://243660364"; p:Emit(20); task.delay(3, function() a:Destroy() end)
end
local function spawnBlackHole(pos)
	local p = Instance.new("Part", Workspace); p.Size = Vector3.new(0,0,0); p.Position = pos; p.Anchored = true; p.CanCollide = false; p.Shape = Enum.PartType.Ball; p.Material = Enum.Material.Neon; p.Color = Color3.new(0,0,0)
	TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(15, 15, 15)}):Play()
	task.delay(1.5, function() TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = Vector3.new(0, 0, 0)}):Play(); task.delay(0.5, function() p:Destroy() end) end)
end

local function DrawSkeleton(char, color)
	if not char or not Config.Skeleton then return end
	local isR15 = char:FindFirstChild("UpperTorso") ~= nil
	local bones = isR15 and R15_Bones or R6_Bones
	if not skeletonLines[char] then skeletonLines[char] = {} end
	
	for i, connection in ipairs(bones) do
		local p1 = char:FindFirstChild(connection[1])
		local p2 = char:FindFirstChild(connection[2])
		if p1 and p2 then
			if not skeletonLines[char][i] then
				local line = Drawing.new("Line"); line.Thickness = 1.5; line.Color = color; line.Transparency = 1; skeletonLines[char][i] = line
			end
			local pos1, on1 = Workspace.CurrentCamera:WorldToViewportPoint(p1.Position)
			local pos2, on2 = Workspace.CurrentCamera:WorldToViewportPoint(p2.Position)
			if on1 and on2 then
				skeletonLines[char][i].From = Vector2.new(pos1.X, pos1.Y)
				skeletonLines[char][i].To = Vector2.new(pos2.X, pos2.Y)
				skeletonLines[char][i].Color = color
				skeletonLines[char][i].Visible = true
			else
				skeletonLines[char][i].Visible = false
			end
		elseif skeletonLines[char][i] then skeletonLines[char][i].Visible = false end
	end
end

local function getRoleColor(plr)
	local function hasTool(container, ...)
		if not container then return false end
		for _, item in pairs(container:GetChildren()) do
			if item:IsA("Tool") then
				local name = item.Name:lower()
				for _, searchStr in pairs({...}) do
					if name:find(searchStr) then return true end
				end
			end
		end
		return false
	end
	
	if hasTool(plr:FindFirstChild("Backpack"), "knife", "blade", "saw", "scythe") or hasTool(plr.Character, "knife", "blade", "saw", "scythe") then
		return Color3.fromRGB(255, 0, 0)
	elseif hasTool(plr:FindFirstChild("Backpack"), "gun", "revolver", "pistol", "blaster") or hasTool(plr.Character, "gun", "revolver", "pistol", "blaster") then
		return Color3.fromRGB(0, 0, 255)
	else
		return Color3.fromRGB(0, 255, 0)
	end
end

local function cleanESP(t)
	if highlights[t] then highlights[t]:Destroy(); highlights[t] = nil end; if nameTags[t] then nameTags[t]:Destroy(); nameTags[t] = nil end
	if distanceTags[t] then distanceTags[t]:Destroy(); distanceTags[t] = nil end; if ipTags[t] then ipTags[t]:Destroy(); ipTags[t] = nil end
	if tracers[t] then pcall(function() tracers[t]:Remove() end); tracers[t] = nil end; if espBoxes[t] then pcall(function() espBoxes[t]:Remove() end); espBoxes[t] = nil end
	if radarBlips[t] then radarBlips[t]:Destroy(); radarBlips[t] = nil end
	if t.Character and skeletonLines[t.Character] then for _, line in pairs(skeletonLines[t.Character]) do line:Remove() end; skeletonLines[t.Character] = nil end
	if t.Character and t.Character:FindFirstChild("ForceFieldChams") then t.Character.ForceFieldChams:Destroy() end
end

local function isEnemy(t)
	if t == player then return false end
	if Config.ESPMode == "Teams" and player.Team and t.Team == player.Team then return false end
	if Config.Friends and isFriend(t) then return false end
	return true
end

local function getClosestToCursor()
	local closest, shortest = nil, Config.AimRadius
	local mPos = UserInputService:GetMouseLocation()
	for _, t in pairs(Players:GetPlayers()) do
		if isEnemy(t) and t.Character and t.Character:FindFirstChild("Head") and t.Character.Humanoid.Health > 0 then
			local sPos, on = Workspace.CurrentCamera:WorldToViewportPoint(t.Character.Head.Position)
			if on then
				local d = (Vector2.new(sPos.X, sPos.Y) - mPos).Magnitude
				if d < shortest then closest = t; shortest = d end
			end
		end
	end
	return closest
end

Connections["MainLoop"] = RunService.RenderStepped:Connect(function(dt)
	if MenuVisible then UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
	
	local accentColor = Config.RGBUI and Color3.fromHSV(RGBHue,1,1) or ActiveTheme.Accent
	local lRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	
	if Config.RGBUI then
		RGBHue = (RGBHue + dt * 0.2) % 1
		for _, s in pairs(UI_Elements.Strokes) do pcall(function() s.Color = accentColor end) end
		for _, t in pairs(UI_Elements.Texts) do pcall(function() t.TextColor3 = accentColor end) end
		if FOVCircle then FOVCircle.Color = accentColor end
		for _, cube in pairs(TargetAura.Cubes) do cube.Trail.Color = ColorSequence.new(accentColor) end
		for _, at in pairs(TargetAura.Atom) do at.Trail.Color = ColorSequence.new(accentColor) end
	end
	
	if Config.ArrayList then
		local active = "ACTIVE MODULES\n\n"
		if Config.ESP then active = active .. "ESP ("..Config.ESPMode..")\n" end
		if Config.Skeleton then active = active .. "Skeleton ESP\n" end
		if Config.Chams then active = active .. "FF Chams\n" end
		if Config.Radar then active = active .. "Radar 2D\n" end
		if Config.TargetESP then active = active .. "Target HUD\n" end
		if Config.Aim then active = active .. "Aim Assist\n" end
		if Config.TriggerBot then active = active .. "TriggerBot\n" end
		if Config.HitSound then active = active .. "Hit Sound\n" end
		if Config.Speed then active = active .. "Speed Hack\n" end
		if Config.Fly then active = active .. "Fly\n" end
		if Config.Freecam then active = active .. "Freecam\n" end
		if Config.NoClip then active = active .. "NoClip\n" end
		if Config.Spider then active = active .. "Spider\n" end
		if Config.Fling then active = active .. "Fling Aura\n" end
		if Config.Trail then active = active .. "Trail ("..Config.TrailMode..")\n" end
		if Config.Wireframe then active = active .. "Wireframe\n" end
		ArrayListLabel.Text = active; ArrayListFrame.Visible = (active ~= "ACTIVE MODULES\n\n")
	else ArrayListFrame.Visible = false end
	
	if Config.KeybindsList then
		local bindsActive = "ACTIVE KEYBINDS\n\n"
		for action, key in pairs(Binds) do
			if key ~= nil and Config[action] then bindsActive = bindsActive .. action .. " [" .. key.Name .. "]\n" end
		end
		KeybindsLabel.Text = bindsActive; KeybindsFrame.Visible = (bindsActive ~= "ACTIVE KEYBINDS\n\n")
	else KeybindsFrame.Visible = false end
	
	if Config.FOV then Workspace.CurrentCamera.FieldOfView = Config.FOVValue end
	if Config.TimeWarp then Lighting.ClockTime = Lighting.ClockTime + (dt * 15) end
	if Config.ThemeFog then Lighting.FogColor = accentColor end
	if Config.AestheticWorld and aestheticCC then aestheticCC.TintColor = Color3.new(0.4 + accentColor.R*0.6, 0.4 + accentColor.G*0.6, 0.4 + accentColor.B*0.6) end

	if Config.Radar and lRoot then
		RadarFrame.Visible = true
		local camCFrame = Workspace.CurrentCamera.CFrame
		for _, t in pairs(Players:GetPlayers()) do
			if isEnemy(t) and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and t.Character.Humanoid.Health > 0 then
				local targetPos = t.Character.HumanoidRootPart.Position
				local relPos = camCFrame:PointToObjectSpace(targetPos)
				local rX = (relPos.X / Config.RadarZoom) * -1
				local rY = (relPos.Z / Config.RadarZoom)
				local maxDist = 95; local dist = math.sqrt(rX*rX + rY*rY)
				if dist > maxDist then rX = (rX / dist) * maxDist; rY = (rY / dist) * maxDist end
				
				if not radarBlips[t] then local b = Instance.new("Frame", RadarFrame); b.Size = UDim2.new(0, 6, 0, 6); rCorner(b, 3); radarBlips[t] = b end
				radarBlips[t].Position = UDim2.new(0.5, rX - 3, 0.5, rY - 3)
				if Config.ESPMode == "Role" then
					radarBlips[t].BackgroundColor3 = getRoleColor(t)
				else
					radarBlips[t].BackgroundColor3 = Config.ESPMode == "Teams" and accentColor or Color3.fromRGB(255, 50, 50)
				end
			else if radarBlips[t] then radarBlips[t]:Destroy(); radarBlips[t] = nil end end
		end
	else RadarFrame.Visible = false; for t, blip in pairs(radarBlips) do blip:Destroy(); radarBlips[t] = nil end end

	if FOVCircle then FOVCircle.Position = UserInputService:GetMouseLocation(); FOVCircle.Radius = Config.AimRadius; FOVCircle.Visible = (Config.ShowFOV and Config.Aim) end
	if CrosshairX and CrosshairY then
		if Config.Crosshair then
			local cx, cy = Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y/2
			CrosshairX.From = Vector2.new(cx-10,cy); CrosshairX.To = Vector2.new(cx+10,cy); CrosshairY.From = Vector2.new(cx,cy-10); CrosshairY.To = Vector2.new(cx,cy+10)
			CrosshairX.Visible = true; CrosshairY.Visible = true
		else CrosshairX.Visible = false; CrosshairY.Visible = false end
	end
	
	local currentTarget = getClosestToCursor()

	if Config.SpectateCam and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
	    SpecFrame.Visible = true
	    
	    if specChar ~= currentTarget.Character then
	        if specClone then specClone:Destroy() end
	        specPartsMap = {}
	        specChar = currentTarget.Character
	        local archivable = specChar.Archivable
	        specChar.Archivable = true
	        specClone = specChar:Clone()
	        specChar.Archivable = archivable
	        
	        if specClone then
	            for _, v in pairs(specClone:GetDescendants()) do
	                if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end
	            end
	            
	            local origDesc = specChar:GetDescendants()
	            local cloneDesc = specClone:GetDescendants()
	            for i, v in ipairs(origDesc) do
	                if v:IsA("BasePart") and cloneDesc[i] and cloneDesc[i]:IsA("BasePart") then
	                    specPartsMap[v] = cloneDesc[i]
	                end
	            end
	            
	            specClone.Parent = SpecViewport
	        end
	    end
	    
	    local targetRoot = currentTarget.Character.HumanoidRootPart
	    
	    if tick() - lastEnvUpdate > 0.5 then
	        lastEnvUpdate = tick()
	        local params = OverlapParams.new()
	        params.FilterType = Enum.RaycastFilterType.Exclude
	        local excludeList = {}
	        for _, p in pairs(Players:GetPlayers()) do
	            if p.Character then table.insert(excludeList, p.Character) end
	        end
	        params.FilterDescendantsInstances = excludeList
	        
	        local parts = Workspace:GetPartBoundsInRadius(targetRoot.Position, 60, params)
	        local currentParts = {}
	        for _, part in pairs(parts) do
	            if part:IsA("BasePart") and part.Transparency < 1 and part.Name ~= "Terrain" then
	                currentParts[part] = true
	                if not specEnvMap[part] then
	                    local arch = part.Archivable
	                    part.Archivable = true
	                    local c = part:Clone()
	                    part.Archivable = arch
	                    if c then
	                        c:ClearAllChildren()
	                        c.Anchored = true
	                        c.Parent = specEnvFolder
	                        specEnvMap[part] = c
	                    end
	                end
	            end
	        end
	        for realPart, clonedPart in pairs(specEnvMap) do
	            if not currentParts[realPart] then
	                clonedPart:Destroy()
	                specEnvMap[realPart] = nil
	            end
	        end
	    end

	    if specClone then
	        for origPart, clonePart in pairs(specPartsMap) do
	            if origPart and origPart.Parent then
	                clonePart.CFrame = origPart.CFrame
	            end
	        end
	    end
	    for realPart, clonedPart in pairs(specEnvMap) do
	        if realPart and realPart.Parent then
	            clonedPart.CFrame = realPart.CFrame
	        else
	            clonedPart:Destroy()
	            specEnvMap[realPart] = nil
	        end
	    end

	    local camPos = targetRoot.Position + Vector3.new(
	        math.sin(tick() * 0.7) * 8,
	        3 + math.sin(tick() * 0.4) * 1,
	        math.cos(tick() * 0.7) * 8
	    )
	    SpecCamPart.CFrame = CFrame.new(camPos, targetRoot.Position)
	    SpecViewport.CurrentCamera.CFrame = SpecCamPart.CFrame
	    SpecViewport.CurrentCamera.FieldOfView = 70
	
	    if Connections["SpecTracer"] then Connections["SpecTracer"].Visible = false end
	
	    if player.Character and player.Character:FindFirstChild("Head") and currentTarget.Character:FindFirstChild("Head") then
	        local origin = player.Character.Head.Position
	        local dest = currentTarget.Character.Head.Position
	        
	        local params = RaycastParams.new()
	        params.FilterType = Enum.RaycastFilterType.Exclude
	        local excludeList = {player.Character}
	        for _, p in pairs(Players:GetPlayers()) do
	            if p.Character then table.insert(excludeList, p.Character) end
	        end
	        params.FilterDescendantsInstances = excludeList
	        
	        local rayResult = Workspace:Raycast(origin, dest - origin, params)
	        local hasLineOfSight = (rayResult == nil)
	        
	        local dist = (dest - origin).Magnitude
	        spec3DTracer.Size = Vector3.new(0.1, 0.1, dist)
	        spec3DTracer.CFrame = CFrame.new(origin, dest) * CFrame.new(0, 0, -dist/2)
	        spec3DTracer.Color = hasLineOfSight and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
	        spec3DTracer.Transparency = 0
	    else
	        spec3DTracer.Transparency = 1
	    end
	else
	    SpecFrame.Visible = false
	    if spec3DTracer then spec3DTracer.Transparency = 1 end
	    if Connections["SpecTracer"] then
	        Connections["SpecTracer"].Visible = false
	    end
	end

	local targetRadiusDst = (Config.TargetESP and currentTarget) and 3 or 0
	currentOrbitRadius = currentOrbitRadius + (targetRadiusDst - currentOrbitRadius) * 12 * dt
	
	if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
		lastTargetPos = currentTarget.Character.HumanoidRootPart.Position
		if Config.FakeIP then
			if not FakeIPs[currentTarget] then FakeIPs[currentTarget] = string.format("%d.%d.%d.%d | %s | %dms", math.random(11,200), math.random(11,200), math.random(11,200), math.random(11,200), FakeCountries[math.random(1, #FakeCountries)], math.random(15, 120)) end
			if not ipTags[currentTarget] then
				local b = Instance.new("BillboardGui", currentTarget.Character); b.Adornee = currentTarget.Character:FindFirstChild("Head"); b.Size = UDim2.new(0,200,0,30); b.StudsOffset = Vector3.new(0,4,0); b.AlwaysOnTop = true
				local l = Instance.new("TextLabel", b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.TextSize=10; l.Font=Enum.Font.Code; l.TextColor3=Color3.fromRGB(0,255,100); l.TextStrokeTransparency=0; table.insert(UI_Elements.Texts, l); ipTags[currentTarget] = b
			end
			ipTags[currentTarget]:FindFirstChildOfClass("TextLabel").Text = "[NET] " .. FakeIPs[currentTarget]
		end
	end

	if currentOrbitRadius > 0.1 and lastTargetPos then
		local tTime = tick() * 3
		for _, obj in ipairs(TargetAura.Cubes) do obj.Part.Transparency = 1 end; for _, obj in ipairs(TargetAura.Atom) do obj.Part.Transparency = 1 end
		for _, p in ipairs(TargetAura.Crown) do p.Transparency = 1 end; TargetAura.Rhombus.Transparency = 1; TargetAura.Ring.Transparency = 1
		for _, obj in ipairs(TargetAura.Helix) do obj.Part.Transparency = 1 end; for _, obj in ipairs(TargetAura.Constellation) do obj.Part.Transparency = 1 end
		for _, p in ipairs(TargetAura.Wings) do p.Transparency = 1 end; TargetAura.VoidRing.Transparency = 1
		
		if Config.TargetMode == "Cubes" then
			for i, obj in ipairs(TargetAura.Cubes) do
				obj.Part.Transparency = 0; obj.Part.Color = accentColor; obj.Trail.Color = ColorSequence.new(accentColor)
				local angle = tTime + (math.pi/2 * i)
				local offset = Vector3.new(math.cos(angle)*currentOrbitRadius, math.sin(tTime*1.5)* (currentOrbitRadius*0.6), math.sin(angle)*currentOrbitRadius)
				obj.Part.CFrame = CFrame.new(lastTargetPos + offset) * CFrame.Angles(tTime, tTime, tTime)
			end
		elseif Config.TargetMode == "Atom" then
			for i, obj in ipairs(TargetAura.Atom) do
				obj.Part.Transparency = 0; obj.Part.Color = accentColor; obj.Trail.Color = ColorSequence.new(accentColor)
				local angle = tTime * 1.5 + (math.pi*2/3 * i)
				local offset
				if i == 1 then offset = Vector3.new(math.cos(angle), math.sin(angle), 0) * currentOrbitRadius
				elseif i == 2 then offset = Vector3.new(0, math.cos(angle), math.sin(angle)) * currentOrbitRadius
				else offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * currentOrbitRadius end
				obj.Part.CFrame = CFrame.new(lastTargetPos + offset)
			end
		elseif Config.TargetMode == "Crown" then
			for i, p in ipairs(TargetAura.Crown) do
				p.Transparency = 0.2; p.Color = accentColor
				local angle = (math.pi*2/6) * i + tTime*0.5
				local offset = Vector3.new(math.cos(angle)*(currentOrbitRadius*0.4), currentOrbitRadius*0.6 + math.sin(tTime*2)*0.2, math.sin(angle)*(currentOrbitRadius*0.4))
				p.CFrame = CFrame.new(lastTargetPos + offset + Vector3.new(0,1,0)) * CFrame.Angles(0, -angle, 0) * CFrame.Angles(math.rad(20), 0, 0)
			end
		elseif Config.TargetMode == "Rhombus" then
			TargetAura.Rhombus.Transparency = 0; TargetAura.Rhombus.Color = accentColor
			TargetAura.Rhombus.CFrame = CFrame.new(lastTargetPos + Vector3.new(0, currentOrbitRadius + 1 + math.sin(tTime)*0.5, 0)) * CFrame.Angles(tTime, tTime*1.5, 0)
		elseif Config.TargetMode == "Ring" then
			TargetAura.Ring.Transparency = 0.3; TargetAura.Ring.Color = accentColor
			TargetAura.Ring.Size = Vector3.new(0.2, currentOrbitRadius*2.5, currentOrbitRadius*2.5)
			TargetAura.Ring.CFrame = CFrame.new(lastTargetPos + Vector3.new(0, math.sin(tTime*2)*2.5, 0)) * CFrame.Angles(0, 0, math.pi/2)
		elseif Config.TargetMode == "Helix" then
			for i, obj in ipairs(TargetAura.Helix) do
				obj.Part.Transparency = 0; obj.Part.Color = accentColor; obj.Trail.Color = ColorSequence.new(accentColor)
				local angle = tTime * 2 + (math.pi * i)
				local yOffset = math.sin(tTime * 1.5 + math.pi * i) * 2
				local offset = Vector3.new(math.cos(angle)*currentOrbitRadius, yOffset, math.sin(angle)*currentOrbitRadius)
				obj.Part.CFrame = CFrame.new(lastTargetPos + offset)
			end
		elseif Config.TargetMode == "Constellation" then
			for i, obj in ipairs(TargetAura.Constellation) do
				obj.Part.Transparency = 0; obj.Part.Color = accentColor; obj.Trail.Color = ColorSequence.new(accentColor)
				local angle1 = tTime + (math.pi*2/6 * i)
				local angle2 = tTime * 1.5 + (math.pi*2/6 * i)
				local offset = Vector3.new(math.cos(angle1)*math.sin(angle2), math.cos(angle2), math.sin(angle1)*math.sin(angle2)) * (currentOrbitRadius * 1.5)
				obj.Part.CFrame = CFrame.new(lastTargetPos + offset)
			end
		elseif Config.TargetMode == "VoidRing" then
			TargetAura.VoidRing.Transparency = 0.1; TargetAura.VoidRing.Color = accentColor
			local scale = currentOrbitRadius * 3 + math.sin(tTime * 4) * 0.5
			TargetAura.VoidRing.Size = Vector3.new(0.1, scale, scale)
			TargetAura.VoidRing.CFrame = CFrame.new(lastTargetPos - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.pi/2)
		elseif Config.TargetMode == "Wings" then
			for i, p in ipairs(TargetAura.Wings) do
				p.Transparency = 0.5; p.Color = accentColor
				local side = i <= 3 and 1 or -1
				local idx = (i - 1) % 3 + 1
				local angle = math.rad(45 - (idx * 20)) * side
				local flap = math.sin(tTime * 2) * 0.2 * side
				local offset = Vector3.new(side * (currentOrbitRadius + idx*0.5), idx*0.8 + math.sin(tTime)*0.5, currentOrbitRadius)
				p.CFrame = CFrame.new(lastTargetPos + offset) * CFrame.Angles(0, flap, angle)
			end
		end
	else
		for _, obj in ipairs(TargetAura.Cubes) do obj.Part.Transparency = 1 end; for _, obj in ipairs(TargetAura.Atom) do obj.Part.Transparency = 1 end
		for _, p in ipairs(TargetAura.Crown) do p.Transparency = 1 end; TargetAura.Rhombus.Transparency = 1; TargetAura.Ring.Transparency = 1
		for _, obj in ipairs(TargetAura.Helix) do obj.Part.Transparency = 1 end; for _, obj in ipairs(TargetAura.Constellation) do obj.Part.Transparency = 1 end
		for _, p in ipairs(TargetAura.Wings) do p.Transparency = 1 end; TargetAura.VoidRing.Transparency = 1
		for t, tag in pairs(ipTags) do if tag then tag:Destroy(); ipTags[t] = nil end end
	end

	if Config.Aim and Aiming and currentTarget then
		if Config.AimMode == "Camera" then
			Workspace.CurrentCamera.CFrame = Workspace.CurrentCamera.CFrame:Lerp(CFrame.new(Workspace.CurrentCamera.CFrame.Position, currentTarget.Character.Head.Position), Config.AimSmooth)
		else
			local mPos = UserInputService:GetMouseLocation(); local sPos = Workspace.CurrentCamera:WorldToViewportPoint(currentTarget.Character.Head.Position)
			pcall(function() mousemoverel((sPos.X - mPos.X) * Config.AimSmooth, (sPos.Y - mPos.Y) * Config.AimSmooth) end)
		end
	end

	for _, t in pairs(Players:GetPlayers()) do
		if t ~= player then
			local tColor = (Config.ESPMode == "Teams" and player.Team and t.Team == player.Team) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
			if Config.ESPMode == "Default" and Config.Friends and isFriend(t) then tColor = Color3.fromRGB(0, 255, 100) end
			if Config.ESPMode == "Role" then tColor = getRoleColor(t) end
			
			if Config.ESP and Config.Boxes and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and t.Character.Humanoid.Health > 0 then
				if not espBoxes[t] then pcall(function() espBoxes[t] = Drawing.new("Square"); espBoxes[t].Thickness = 1.5; espBoxes[t].Filled = false end) end
				local sPos, on = Workspace.CurrentCamera:WorldToViewportPoint(t.Character.HumanoidRootPart.Position)
				if on and espBoxes[t] then
					local dist = (Workspace.CurrentCamera.CFrame.Position - t.Character.HumanoidRootPart.Position).Magnitude
					local sizeX, sizeY = 3000 / dist, 4500 / dist
					espBoxes[t].Size = Vector2.new(sizeX, sizeY); espBoxes[t].Position = Vector2.new(sPos.X - sizeX/2, sPos.Y - sizeY/2)
					espBoxes[t].Color = tColor; espBoxes[t].Visible = true
				elseif espBoxes[t] then espBoxes[t].Visible = false end
			else if espBoxes[t] then espBoxes[t].Visible = false end end

			if Config.ESP and Config.Skeleton and t.Character and t.Character.Humanoid.Health > 0 then
				DrawSkeleton(t.Character, tColor)
			else
				if skeletonLines[t.Character] then for _, line in pairs(skeletonLines[t.Character]) do line.Visible = false end end
			end
		end
	end

	if Config.Freecam then
		if not FreecamPart then
			FreecamPart = Instance.new("Part", Workspace); FreecamPart.Anchored = true; FreecamPart.CanCollide = false; FreecamPart.Transparency = 1
			FreecamPart.CFrame = Workspace.CurrentCamera.CFrame; Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		end
		local cam = Workspace.CurrentCamera; local mv = Vector3.new()
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
		
		FreecamPart.CFrame = FreecamPart.CFrame + (mv * (Config.FreecamSpeed * dt))
		local delta = UserInputService:GetMouseDelta()
		FreecamPart.CFrame = FreecamPart.CFrame * CFrame.Angles(0, math.rad(-delta.X), 0) * CFrame.Angles(math.rad(-delta.Y), 0, 0)
		Workspace.CurrentCamera.CFrame = FreecamPart.CFrame
	else
		if FreecamPart then FreecamPart:Destroy(); FreecamPart = nil; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom; Workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid") end
	end

	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not Config.Freecam then
		local root = player.Character.HumanoidRootPart
		local hum = player.Character:FindFirstChild("Humanoid")

		if Config.Speed and hum then
			local speedMode = Config.SpeedMode or "WalkSpeed"
			if speedMode == "WalkSpeed" then
				hum.WalkSpeed = 16 * (Config.SpeedMult or 2)
			elseif speedMode == "CFrame" and hum.MoveDirection.Magnitude > 0 then
				hum.WalkSpeed = 16
				root.CFrame = root.CFrame + (hum.MoveDirection * (((Config.SpeedMult or 2) - 1) * 16 * dt))
			elseif speedMode == "Velocity" and hum.MoveDirection.Magnitude > 0 then
				hum.WalkSpeed = 16
				root.Velocity = Vector3.new(hum.MoveDirection.X * (16 * (Config.SpeedMult or 2)), root.Velocity.Y, hum.MoveDirection.Z * (16 * (Config.SpeedMult or 2)))
			end
		end

		if Config.Spinbot and not Config.Fling then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0) end
		if Config.Fling then
			root.Velocity = Vector3.new(math.random(-5000, 5000), math.random(-5000, 5000), math.random(-5000, 5000))
			root.CFrame = root.CFrame * CFrame.Angles(math.rad(math.random(-180,180)), math.rad(math.random(-180,180)), math.rad(math.random(-180,180)))
		end
		if Config.Fly then
			if player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.PlatformStand = true end
			local cam = Workspace.CurrentCamera.CFrame; local mv = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
			if not Config.Fling then root.Velocity = Vector3.new(0,0,0) end
			root.CFrame = root.CFrame + (mv * (Config.FlySpeed * dt))
		end

		if Config.Freeze then
			if not freezePos then freezePos = root.CFrame end
			root.CFrame = freezePos
			root.Velocity = Vector3.new(0,0,0)
		else
			freezePos = nil
		end

		if Config.Spider and hum.MoveDirection.Magnitude > 0 then
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {player.Character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local result = Workspace:Raycast(root.Position, root.CFrame.LookVector * 2.5, raycastParams)
			if result then
				root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
			end
		end
	end
end)

local fpsCount = 0
local lastFpsTime = tick()
local lastFakeLagTime = tick()
local lastMusicPoll = 0
local currentSongData = { title = "Rich Premium", artist = "Rich Premium", is_playing = false, progress = 0 }

Connections["Heartbeat"] = RunService.Heartbeat:Connect(function(dt)
	if Config.FakeLag and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local lRoot = player.Character.HumanoidRootPart
		if tick() - lastFakeLagTime >= (Config.FakeLagPower or 0.5) then
			lRoot.Anchored = true
			task.wait(0.05)
			if lRoot then lRoot.Anchored = false end
			lastFakeLagTime = tick()
		end
	end

	if Config.DynamicIsland and eqBars and #eqBars > 0 then
		local t = tick() * 8
		for idx, bar in ipairs(eqBars) do
			local scale = clamp(0.2 + 0.7 * math.abs(math.sin(t + (idx * 1.2))), 0.2, 1)
			bar.Size = UDim2.new(0, 3, scale, 0)
		end
	end

	if Config.DynamicIsland and Config.IslandMusic and (tick() - lastMusicPoll >= 1.0) then
		lastMusicPoll = tick()
		task.spawn(function()
			pcall(function()
				local raw = nil
				local httpFn = (type(request) == "function" and request)
					or (type(http_request) == "function" and http_request)
					or (syn and type(syn.request) == "function" and syn.request)
					or (http and type(http.request) == "function" and http.request)
					or (fluxus and type(fluxus.request) == "function" and fluxus.request)

				if httpFn then
					local res = httpFn({Url = "http://127.0.0.1:9876/song", Method = "GET"})
					if res and (res.StatusCode == 200 or res.StatusMessage == "OK") then
						raw = res.Body
					end
				end
				if not raw and game and game.HttpGet then
					local s, b = pcall(function() return game:HttpGet("http://127.0.0.1:9876/song") end)
					if s and b and #b > 2 then raw = b end
				end
				if not raw and isfile then
					if isfile("RichPremium/song.json") then
						raw = readfile("RichPremium/song.json")
					elseif isfile("song.json") then
						raw = readfile("song.json")
					elseif isfile("current_song.json") then
						raw = readfile("current_song.json")
					end
				end
				if raw and #raw > 5 then
					local data = HttpService:JSONDecode(raw)
					if data and data.title then
						currentSongData = data
					end
				end
			end)
		end)
	end

	fpsCount = fpsCount + 1
	if tick() - lastFpsTime >= 1 then
		local ping = math.floor(player:GetNetworkPing() * 1000)
		pcall(function()
			if Config.DynamicIsland and DynamicIsland then
				DynamicIsland.Visible = true
				if Config.IslandMode == "Music" and currentSongData and currentSongData.is_playing then
					IslandTitle.Text = currentSongData.title or "Unknown Track"
					IslandArtist.Text = (currentSongData.artist or "PC Audio") .. " • " .. ping .. "ms"
					if currentSongData.cover and currentSongData.cover ~= "" and currentSongData.cover:sub(1,10) == "rbxassetid" then
						IslandCover.Image = currentSongData.cover
					else
						IslandCover.Image = "rbxassetid://6031075938"
					end
					if currentSongData.progress then
						ProgressFill.Size = UDim2.new(clamp(currentSongData.progress, 0, 1), 0, 1, 0)
					end
				else
					IslandTitle.Text = "Rich Premium"
					IslandArtist.Text = "v2.1 • " .. ping .. "ms"
					IslandCover.Image = "rbxassetid://6031075938"
				end
				IslandStats.Text = tostring(fpsCount) .. " FPS"
			end
		end)
		fpsCount = 0
		lastFpsTime = tick()
	end
	local lRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local accentColor = Config.RGBUI and Color3.fromHSV(RGBHue,1,1) or ActiveTheme.Accent
	
	if Config.DynamicIsland and Config.RGBUI and islandStroke and islandGrad then
		islandStroke.Color = accentColor
		islandGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accentColor),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 20, 30)),
			ColorSequenceKeypoint.new(1, accentColor)
		})
	end
	
	if Config.Gravity then Workspace.Gravity = 50 else Workspace.Gravity = origGravity or 196.2 end
	
	if Config.Trail and lRoot and lRoot.Velocity.Magnitude > 5 then
		if Config.TrailMode == "Neon" then
			local p = Instance.new("Part", Workspace); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = accentColor
			p.Size = Vector3.new(1.5, 0.2, 1.5); p.Position = lRoot.Position - Vector3.new(0, 3, 0); p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(math.random(-360,360)), 0)
			TweenService:Create(p, TweenInfo.new(0.5), {Transparency = 1, Size = Vector3.new(0,0,0)}):Play(); task.delay(0.5, function() p:Destroy() end)
		elseif Config.TrailMode == "Fire" then
			local a = Instance.new("Attachment", Workspace.Terrain); a.Position = lRoot.Position - Vector3.new(0, 2.5, 0)
			local p = Instance.new("ParticleEmitter", a); p.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0)); p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
			p.Speed = NumberRange.new(2, 5); p.Lifetime = NumberRange.new(0.5, 1); p.Rate = 100; p.LightEmission = 1; p:Emit(2); task.delay(1, function() a:Destroy() end)
		elseif Config.TrailMode == "Smoke" then
			local a = Instance.new("Attachment", Workspace.Terrain); a.Position = lRoot.Position - Vector3.new(0, 2.5, 0)
			local p = Instance.new("ParticleEmitter", a); p.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150)); p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 4)})
			p.Speed = NumberRange.new(1, 3); p.Lifetime = NumberRange.new(1, 2); p.Rate = 50; p.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,1)}); p:Emit(1); task.delay(2, function() a:Destroy() end)
		end
	end

	if Config.TriggerBot then
		local tgt = player:GetMouse().Target
		if tgt and tgt.Parent and tgt.Parent:FindFirstChild("Humanoid") and tgt.Parent.Name ~= player.Name then pcall(function() mouse1click() end) end
	end

	if Config.AutoClicker and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		pcall(function() mouse1click() end)
	end

	if Config.MeleeReach and player.Character then
		local tool = player.Character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then tool.Handle.Size = Vector3.new(15, 15, 15); tool.Handle.Massless = true; tool.Handle.Transparency = 0.8 end
	end

	for _, t in pairs(Players:GetPlayers()) do
		local skipSelf = (t == player)
		local char = t.Character
		local alive = char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0

		if char and char:FindFirstChild("Humanoid") then
			local currentHP = char.Humanoid.Health; local root = char:FindFirstChild("HumanoidRootPart")
			
			if alive and root then
				if not enemyHealthTracker[t] then enemyHealthTracker[t] = currentHP end
				if currentHP < enemyHealthTracker[t] then
					local damage = enemyHealthTracker[t] - currentHP
					if damage > 0.5 then showDamageUI(t.Name, damage, currentHP) end
					enemyHealthTracker[t] = currentHP
				elseif currentHP > enemyHealthTracker[t] then enemyHealthTracker[t] = currentHP end
			end

			if currentHP <= 0 and not deadTracker[t] then
				deadTracker[t] = true
				if Config.AutoToxic then sendToxicMessage() end
				if root and lRoot and (lRoot.Position - root.Position).Magnitude < 150 then
					if Config.KillShockwave then spawnShockwave(root.Position, accentColor) end
					if Config.KillLightning then spawnLightning(root.Position, accentColor) end
					if Config.KillBlood then spawnBlood(root.Position) end
					if Config.KillSouls then spawnSouls(root.Position, accentColor) end
					if Config.KillBlackHole then spawnBlackHole(root.Position) end
				end
			elseif currentHP > 0 then deadTracker[t] = false end
		end
		
		if Config.AntiFling and alive and char.HumanoidRootPart.Velocity.Magnitude > 100 then
			for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
		end

		if not alive or not Config.ESP then
			cleanESP(t)
			if originalHitboxes[t] and char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.Size = originalHitboxes[t].S; char.HumanoidRootPart.Transparency = originalHitboxes[t].T; char.HumanoidRootPart.CanCollide = originalHitboxes[t].C; originalHitboxes[t] = nil
			end
			do end --[[continue]]
		end

		if highlights[t] and highlights[t].Parent == nil then cleanESP(t) end
		if nameTags[t] and nameTags[t].Parent == nil then cleanESP(t) end
		if distanceTags[t] and distanceTags[t].Parent == nil then cleanESP(t) end

		if alive and Config.ESP then
			local tColor
			if Config.ESPMode == "Teams" then if player.Team and t.Team == player.Team then tColor = Color3.fromRGB(0, 255, 100) else tColor = Color3.fromRGB(255, 50, 50) end
			elseif Config.ESPMode == "Role" then tColor = getRoleColor(t)
			else tColor = (Config.Friends and isFriend(t)) and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,50,50) end
			
			if Config.Chams then
				if not char:FindFirstChild("FFChams") then
					local h = Instance.new("Highlight", char); h.Name = "FFChams"; h.FillTransparency = 0; h.OutlineTransparency = 1; h.FillColor = tColor
				else char.FFChams.FillColor = tColor end
				if highlights[t] then highlights[t]:Destroy(); highlights[t] = nil end
			else
				if char:FindFirstChild("FFChams") then char.FFChams:Destroy() end
				if not highlights[t] then local h = Instance.new("Highlight", char); h.FillTransparency = 0.8; h.OutlineTransparency = 0; highlights[t] = h end
				highlights[t].FillColor = tColor; highlights[t].OutlineColor = tColor
			end
			
			if Config.Names then
				if not nameTags[t] then
					local b = Instance.new("BillboardGui", char); b.Size = UDim2.new(0,150,0,30); b.StudsOffset = Vector3.new(0,2.5,0); b.AlwaysOnTop = true
					local l = Instance.new("TextLabel", b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.TextSize=12; l.Font=Enum.Font.GothamBold; l.TextStrokeTransparency=0.2; nameTags[t] = b
				end
				nameTags[t].Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
				local lbl = nameTags[t]:FindFirstChildOfClass("TextLabel"); lbl.Text = t.Name; lbl.TextColor3 = tColor
			else if nameTags[t] then nameTags[t]:Destroy(); nameTags[t] = nil end end
			
			if Config.Distance then
				if not distanceTags[t] then
					local b = Instance.new("BillboardGui", char); b.Size = UDim2.new(0,100,0,30); b.StudsOffset = Vector3.new(0,-3,0); b.AlwaysOnTop = true
					local l = Instance.new("TextLabel", b); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.TextSize=11; l.Font=Enum.Font.GothamSemibold; l.TextStrokeTransparency=0.2; table.insert(UI_Elements.Texts, l); distanceTags[t] = b
				end
				distanceTags[t].Adornee = char:FindFirstChild("HumanoidRootPart")
				if lRoot and distanceTags[t] then 
					local lbl = distanceTags[t]:FindFirstChildOfClass("TextLabel"); lbl.Text = math.floor((lRoot.Position - char.HumanoidRootPart.Position).Magnitude) .. "m"; lbl.TextColor3 = tColor
				end
			else if distanceTags[t] then distanceTags[t]:Destroy(); distanceTags[t] = nil end end
			
			if Config.Tracers then
				if not tracers[t] then pcall(function() tracers[t] = Drawing.new("Line"); tracers[t].Thickness = 1.5 end) end
				local sPos, on = Workspace.CurrentCamera:WorldToViewportPoint(char.HumanoidRootPart.Position)
				if on and tracers[t] then
					tracers[t].From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X/2, Workspace.CurrentCamera.ViewportSize.Y); tracers[t].To = Vector2.new(sPos.X, sPos.Y); tracers[t].Color = tColor; tracers[t].Visible = true
				elseif tracers[t] then tracers[t].Visible = false end
			else if tracers[t] then pcall(function() tracers[t]:Remove() end); tracers[t] = nil end end

			if Config.Hitbox then
				local r = char:FindFirstChild("HumanoidRootPart")
				if r then
					if not originalHitboxes[t] then originalHitboxes[t] = {S=r.Size, T=r.Transparency, C=r.CanCollide} end
					r.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize); r.Transparency = 0.7; r.CanCollide = false
				end
			end
		end
	end
end)

Connections["Stepped"] = RunService.Stepped:Connect(function()
	if Config.NoClip and player.Character then
		local mode = Config.NoClipMode or "Stepped"
		if mode == "Stepped" then
			for _, part in pairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		elseif mode == "State" then
			local hum = player.Character:FindFirstChild("Humanoid")
			if hum then hum:ChangeState(11) end
		elseif mode == "Raycast" then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character:FindFirstChild("Humanoid")
			if root and hum and hum.MoveDirection.Magnitude > 0 then
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {player.Character}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				local result = Workspace:Raycast(root.Position, hum.MoveDirection * 1.5, raycastParams)
				if result and result.Instance.CanCollide then
					root.CFrame = root.CFrame + (hum.MoveDirection * 2)
				end
			end
		end
	end
end)

local bhopState = {
	lastGroundTick = 0,
	airStrafeSpeed = 0,
	isHoldingJump = false,
	bhopActive = false,
	lastJumpTick = 0,
	strafeDir = 0,
	consecutiveHops = 0,
	peakSpeed = 0
}

Connections["BHopStrafe"] = RunService.RenderStepped:Connect(function(dt)
	if not Config.BHop then return end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	
	local isGrounded = hum.FloorMaterial ~= Enum.Material.Air
	local cam = Workspace.CurrentCamera
	
	if isGrounded then
		bhopState.lastGroundTick = tick()
		if bhopState.isHoldingJump and (tick() - bhopState.lastJumpTick) > 0.05 then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			bhopState.lastJumpTick = tick()
			bhopState.consecutiveHops = bhopState.consecutiveHops + 1
			local vel = root.Velocity
			local hSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
			if hSpeed > 16 then
				local moveDir = Vector3.new(vel.X, 0, vel.Z).Unit
				local boost = math.min(hSpeed, 16 * (Config.BHopSpeed or 1.4))
				root.Velocity = Vector3.new(moveDir.X * boost, root.Velocity.Y + 2, moveDir.Z * boost)
			end
		end
	else
		local strafeForce = Config.BHopStrafeForce or 0.12
		local isStrafingLeft = UserInputService:IsKeyDown(Enum.KeyCode.A)
		local isStrafingRight = UserInputService:IsKeyDown(Enum.KeyCode.D)
		local isForward = UserInputService:IsKeyDown(Enum.KeyCode.W)
		
		if isStrafingLeft or isStrafingRight then
			local strafeVec = Vector3.new(0, 0, 0)
			local camLook = cam.CFrame.LookVector
			local camRight = cam.CFrame.RightVector
			
			if isStrafingLeft then
				strafeVec = strafeVec - Vector3.new(camRight.X, 0, camRight.Z).Unit
			end
			if isStrafingRight then
				strafeVec = strafeVec + Vector3.new(camRight.X, 0, camRight.Z).Unit
			end
			if isForward then
				strafeVec = strafeVec + Vector3.new(camLook.X, 0, camLook.Z).Unit * 0.5
			end
			
			if strafeVec.Magnitude > 0 then
				strafeVec = strafeVec.Unit
				local currentVel = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
				local currentSpeed = currentVel.Magnitude
				local maxSpeed = 16 * (Config.BHopSpeed or 1.4) * 1.8
				
				local dot = currentVel.Unit:Dot(strafeVec)
				local addSpeed = strafeForce * 60 * dt
				if currentSpeed < maxSpeed then
					local accel = strafeVec * addSpeed
					root.Velocity = Vector3.new(
						root.Velocity.X + accel.X,
						root.Velocity.Y,
						root.Velocity.Z + accel.Z
					)
				end
				
				if currentSpeed > bhopState.peakSpeed then
					bhopState.peakSpeed = currentSpeed
				end
			end
		end
	end
end)

Connections["BHopJumpTrack"] = UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Space then
		bhopState.isHoldingJump = true
	end
end)
Connections["BHopJumpRelease"] = UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		bhopState.isHoldingJump = false
		bhopState.consecutiveHops = 0
		bhopState.peakSpeed = 0
	end
end)

Connections["JumpRequest"] = UserInputService.JumpRequest:Connect(function()
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local hum = player.Character.Humanoid
		if Config.InfJump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		
		if Config.SafeHighJump and hum.FloorMaterial ~= Enum.Material.Air then
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			task.spawn(function()
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
					local targetHeight = Config.SafeHighJumpPower or 15
					local frames = 15
					for i = 1, frames do
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local r = player.Character.HumanoidRootPart
							r.CFrame = r.CFrame + Vector3.new(0, targetHeight / frames, 0)
						end
						task.wait()
					end
				end
				task.wait(0.1)
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end)
		end

		if Config.JumpCircles and hum.FloorMaterial ~= Enum.Material.Air then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local p = Instance.new("Part", Workspace); p.Size = Vector3.new(0.1, 5, 5); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = Config.RGBUI and Color3.fromHSV(RGBHue,1,1) or ActiveTheme.Accent
				p.CFrame = CFrame.new(root.Position - Vector3.new(0,3,0)) * CFrame.Angles(0, 0, math.rad(90)); p.Shape = Enum.PartType.Cylinder
				TweenService:Create(p, TweenInfo.new(0.6), {Size = Vector3.new(0.1, 15, 15), Transparency = 1}):Play(); task.delay(0.6, function() p:Destroy() end)
			end
		end
	end
end)

Connections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
		MenuVisible = not MenuVisible
		if not MenuAnimating then
			MenuAnimating = true
			if not MenuVisible and PopupFrame then PopupFrame.Visible = false end
			if Config.UIStyle == "Dropdown" then
				for _, df in pairs(DropdownFrames) do df.Visible = MenuVisible end
				MenuAnimating = false
			elseif Config.UIStyle == "Modern" then
				if ModernFrame then
					if MenuVisible then
						ModernFrame.Visible = true
						ModernFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
						TweenService:Create(ModernFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					else
						local tw = TweenService:Create(ModernFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.55, 0)})
						tw:Play()
						tw.Completed:Connect(function() if not MenuVisible then ModernFrame.Visible = false end end)
					end
				end
				MenuAnimating = false
			else
				TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = MenuVisible and UDim2.new(0.5, -310, 0.5, -245) or UDim2.new(0.5, -310, -1, 0)}):Play(); task.delay(0.4, function() MenuAnimating = false end)
			end
		end
	end
	if Binds.Aim ~= nil and (input.UserInputType == Binds.Aim or input.KeyCode == Binds.Aim) then Aiming = true end
	for action, key in pairs(Binds) do 
		if key ~= nil and action ~= "Aim" and (input.KeyCode == key or input.UserInputType == key) then 
			if Config[action] ~= nil then 
				Config[action] = not Config[action]; 
				if action == "Freecam" and not Config.Freecam and FreecamPart then 
					FreecamPart:Destroy(); FreecamPart = nil; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom; Workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid") 
				end
				if action == "Helper" and Config.Helper then
					task.spawn(function()
						local cam = Workspace.CurrentCamera
						local startCFrame = cam.CFrame
						local goal = cam.CFrame * CFrame.Angles(math.rad(85), math.rad(180), 0)
						local tween = TweenService:Create(cam, TweenInfo.new(Config.HelperSmoothness or 0.3, Enum.EasingStyle.Sine), {CFrame = goal})
						tween:Play(); tween.Completed:Wait()
						if mouse1click then mouse1click() end
						task.wait(0.05)
						local backTween = TweenService:Create(cam, TweenInfo.new(Config.HelperSmoothness or 0.3, Enum.EasingStyle.Sine), {CFrame = startCFrame})
						backTween:Play(); backTween.Completed:Wait()
						Config.Helper = false
					end)
				end
			end 
		end 
	end
end)
Connections["InputEnded"] = UserInputService.InputEnded:Connect(function(input, proc) if Binds.Aim ~= nil and (input.UserInputType == Binds.Aim or input.KeyCode == Binds.Aim) then Aiming = false end end)

local function SaveConfig(name)
	pcall(function()
		if not isfolder("RichPremium") then makefolder("RichPremium") end
		local data = { C = Config, B = {}, T = ActiveThemeName }
		for k, v in pairs(Binds) do data.B[k] = v and (v.Name or "None") or "None" end
		writefile("RichPremium/" .. name .. ".json", HttpService:JSONEncode(data))
	end)
end

local function LoadConfig(name)
	pcall(function()
		local raw = readfile("RichPremium/" .. name .. ".json")
		local data = HttpService:JSONDecode(raw)
		if not data or type(data) ~= "table" or not data.C or type(data.C) ~= "table" then
			if showNotification then showNotification("Config Error", "Invalid config file: " .. tostring(name), 2, Color3.fromRGB(255, 60, 60)) end
			return
		end
		local loadWorld = Config.LoadWorldSettings
		for k, v in pairs(data.C) do
			if not loadWorld and (k == "XRay" or k == "FullBright" or k == "NightMode" or k == "FOV" or k == "ThemeFog" or k == "AestheticWorld" or k == "Gravity" or k == "TimeWarp" or k == "PotatoMode" or k == "Wireframe") then
			else Config[k] = v end
		end
		for k, v in pairs(data.B) do if v == "None" then Binds[k] = nil else Binds[k] = Enum.KeyCode[v] or Enum.UserInputType[v] end end
		Config.LoadWorldSettings = loadWorld
		ActiveThemeName = data.T or "RichDark"; ActiveTheme = Themes[ActiveThemeName] or Themes["RichDark"]; MainFrame.BackgroundColor3 = ActiveTheme.BG; TabsFrame.BackgroundColor3 = ActiveTheme.Panel; SettingsFrame.BackgroundColor3 = ActiveTheme.Panel; ArrayListFrame.BackgroundColor3 = ActiveTheme.BG; DmgLogFrame.BackgroundColor3 = ActiveTheme.BG; RadarFrame.BackgroundColor3 = ActiveTheme.BG; if DynamicIsland then DynamicIsland.BackgroundColor3 = ActiveTheme.BG end
		if ModernFrame then
			ModernFrame.BackgroundColor3 = ActiveTheme.BG
			if modernStroke then modernStroke.Color = ActiveTheme.Accent end
			if mHeaderDivider then mHeaderDivider.BackgroundColor3 = ActiveTheme.Accent end
			if mLogo then mLogo.TextColor3 = ActiveTheme.Accent end
			if ModernScroll then ModernScroll.ScrollBarImageColor3 = ActiveTheme.Accent end
			for tName, tBtn in pairs(modernTabButtons) do
				if tName == modernActiveTab then tBtn.BackgroundColor3 = ActiveTheme.Accent end
			end
		end
		for _, df in pairs(DropdownFrames) do
			df.BackgroundColor3 = ActiveTheme.Panel
			local sc = df:FindFirstChild("Scroll")
			if sc then sc.BackgroundColor3 = ActiveTheme.Panel end
		end
		for _,s in pairs(UI_Elements.Strokes) do pcall(function() s.Color=ActiveTheme.Accent end) end; for _,t in pairs(UI_Elements.Texts) do pcall(function() t.TextColor3=ActiveTheme.Accent end) end
		ApplyWorldSettings()
		if RefreshUI then RefreshUI() end
	end)
end

local Builders = {}

Builders.Combat = function(parent)
	parent = parent or SettingsFrame
	addToggle(parent, "Aim Assist", "Aim", nil, function(p)
		addToggle(p, "Show FOV Circle", "ShowFOV")
		createButton(p, "Aim Mode: " .. Config.AimMode, 180, function(b) Config.AimMode = Config.AimMode == "Camera" and "Mouse" or "Camera"; b.Text = "  Aim Mode: " .. Config.AimMode end)
		createTextBox(p, "Radius", tostring(Config.AimRadius), function(v) Config.AimRadius = tonumber(v) or 150; if FOVCircle then FOVCircle.Radius = Config.AimRadius end end)
		createTextBox(p, "Smoothness", tostring(Config.AimSmooth), function(v) Config.AimSmooth = clamp(tonumber(v) or 0.2, 0.01, 1) end)
		addBind(p, "Aim Assist", "Aim")
		addToggle(p, "Spectate Cam (PIP)", "SpectateCam")
	end)

	addToggle(parent, "TriggerBot", "TriggerBot")
	addToggle(parent, "Auto-Clicker", "AutoClicker")
	addToggle(parent, "Helper (Auto Throw)", "Helper", nil, function(p)
		createTextBox(p, "Flick Speed", tostring(Config.HelperSmoothness), function(v) Config.HelperSmoothness = tonumber(v) or 0.3 end)
		addBind(p, "Helper", "Helper")
	end)
	addToggle(parent, "Hitbox Expander", "Hitbox")
	addToggle(parent, "Melee Reach Aura", "MeleeReach")
	addToggle(parent, "Spinbot", "Spinbot")
	addToggle(parent, "Fling Aura", "Fling", nil, function(p) addBind(p, "Fling", "Fling") end)
	addToggle(parent, "Anti-Fling", "AntiFling")
end

Builders.Visuals = function(parent)
	parent = parent or SettingsFrame
	addToggle(parent, "Master ESP", "ESP", nil, function(p)
		createButton(p, "ESP Mode: " .. Config.ESPMode, 180, function(b) 
			local modes = {"Default", "Teams", "Role"}
			Config.ESPMode = modes[(table.find(modes, Config.ESPMode) or 1) % #modes + 1]
			b.Text = "  ESP Mode: " .. Config.ESPMode 
		end)
		addToggle(p, "Show Names", "Names"); addToggle(p, "Show 2D Boxes", "Boxes"); addToggle(p, "Show Distance", "Distance")
		addToggle(p, "Show Tracers", "Tracers"); addToggle(p, "ForceField Chams", "Chams"); addToggle(p, "Skeleton ESP", "Skeleton"); addToggle(p, "Highlight Friends", "Friends"); addBind(p, "Toggle ESP", "ESP")
	end)
	
	addToggle(parent, "Target HUD (Aura)", "TargetESP", nil, function(p)
		createButton(p, "Visual Mode: " .. Config.TargetMode, 180, function(b) 
			local modes = {"Cubes", "Rhombus", "Ring", "Atom", "Crown", "Helix", "Constellation", "Wings", "VoidRing"}
			Config.TargetMode = modes[(table.find(modes, Config.TargetMode) % #modes) + 1]; b.Text = "  Visual Mode: " .. Config.TargetMode
		end)
		addToggle(p, "Fake IP Scanner", "FakeIP")
	end)

	createButton(parent, "World Aesthetics", 450, function() end, function(p)
		addToggle(p, "FullBright", "FullBright", ApplyWorldSettings)
		addToggle(p, "Theme Fog", "ThemeFog", ApplyWorldSettings)
		addToggle(p, "Neon Atmo", "AestheticWorld", ApplyWorldSettings)
		addToggle(p, "Wireframe", "Wireframe", ApplyWorldSettings)
	end)

	createButton(parent, "Kill Effects", 450, function() end, function(p)
		addToggle(p, "Shockwave", "KillShockwave"); addToggle(p, "Lightning", "KillLightning")
		addToggle(p, "Blood Burst", "KillBlood"); addToggle(p, "Souls", "KillSouls"); addToggle(p, "Black Hole", "KillBlackHole")
	end)

	addToggle(parent, "Movement Trail", "Trail", nil, function(p) createButton(p, "Trail: " .. Config.TrailMode, 180, function(b) local m={"Neon","Fire","Smoke"}; Config.TrailMode = m[(table.find(m, Config.TrailMode)%#m)+1]; b.Text = "  Trail: " .. Config.TrailMode end) end)
	addToggle(parent, "Jump Circles", "JumpCircles")
	addToggle(parent, "Radar 2D", "Radar", nil, function(p) createTextBox(p, "Radar Zoom", tostring(Config.RadarZoom), function(v) Config.RadarZoom = tonumber(v) or 2 end) end)
	addToggle(parent, "Hit Sound (Ping)", "HitSound")
	addToggle(parent, "Damage Log (UI)", "DamageInd")
	addToggle(parent, "Center Crosshair", "Crosshair")
	addToggle(parent, "Show Array List", "ArrayList")
	addToggle(parent, "Show Keybinds", "KeybindsList")
	addToggle(parent, "Dynamic Island (iPhone)", "DynamicIsland", function(st)
		if DynamicIsland then DynamicIsland.Visible = st end
	end, function(p)
		createButton(p, "Mode: " .. (Config.IslandMode or "Music"), 180, function(b)
			Config.IslandMode = (Config.IslandMode == "Music") and "Stats" or "Music"
			b.Text = "  Mode: " .. Config.IslandMode
			if showNotification then showNotification("Island Mode", "Switched to " .. Config.IslandMode, 2) end
		end)
		addToggle(p, "PC Music Sync", "IslandMusic")
		addToggle(p, "Expand On Hover", "IslandExpandOnHover")
	end)
	addToggle(parent, "Toast Notifications", "Notifications")
end

Builders.Movement = function(parent)
	parent = parent or SettingsFrame
	addToggle(parent, "Speed Hack", "Speed", function(st) if not st and player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed=16 end end, function(p)
		createButton(p, "Speed Mode: " .. (Config.SpeedMode or "WalkSpeed"), 180, function(b) 
			local modes = {"WalkSpeed", "CFrame", "Velocity"}
			Config.SpeedMode = Config.SpeedMode or "WalkSpeed"
			Config.SpeedMode = modes[(table.find(modes, Config.SpeedMode) % #modes) + 1]
			b.Text = "  Speed Mode: " .. Config.SpeedMode 
		end)
		createTextBox(p, "Multiplier", tostring(Config.SpeedMult or 2), function(v) Config.SpeedMult = tonumber(v) or 2 end)
		addBind(p, "Speed", "Speed") 
	end)
	addToggle(parent, "Fly Camera", "Fly", function(st) if not st and player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.PlatformStand=false end end, function(p) addBind(p, "Fly", "Fly") end)
	addToggle(parent, "Freecam", "Freecam", function(st) if not st and FreecamPart then FreecamPart:Destroy(); FreecamPart = nil; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom; Workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChild("Humanoid") end end, function(p) createTextBox(p, "Speed", tostring(Config.FreecamSpeed), function(v) Config.FreecamSpeed = tonumber(v) or 100 end); addBind(p, "Freecam", "Freecam") end)
	addToggle(parent, "NoClip", "NoClip", function(st) if not st and player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end end, function(p) 
		createButton(p, "NoClip Mode: " .. (Config.NoClipMode or "Stepped"), 180, function(b)
			local modes = {"Stepped", "State", "Raycast"}
			Config.NoClipMode = Config.NoClipMode or "Stepped"
			Config.NoClipMode = modes[(table.find(modes, Config.NoClipMode) or 1) % #modes + 1]
			b.Text = "  NoClip Mode: " .. Config.NoClipMode
		end)
		addBind(p, "NoClip", "NoClip")
	end)
	addToggle(parent, "Spider (Climb)", "Spider", nil, function(p) addBind(p, "Spider", "Spider") end)
	addToggle(parent, "Infinite Jump", "InfJump")
	addToggle(parent, "B-Hop (CS2 Style)", "BHop", nil, function(p)
		createTextBox(p, "Speed Mult", tostring(Config.BHopSpeed or 1.4), function(v) Config.BHopSpeed = clamp(tonumber(v) or 1.4, 1, 3) end)
		createTextBox(p, "Strafe Force", tostring(Config.BHopStrafeForce or 0.12), function(v) Config.BHopStrafeForce = clamp(tonumber(v) or 0.12, 0.01, 0.5) end)
	end)
	addToggle(parent, "Fake Lag", "FakeLag", nil, function(p) createTextBox(p, "Lag Delay (s)", tostring(Config.FakeLagPower or 0.5), function(v) Config.FakeLagPower = tonumber(v) or 0.5 end) end)
	addToggle(parent, "Safe High Jump", "SafeHighJump", nil, function(p) createTextBox(p, "Height", tostring(Config.SafeHighJumpPower or 15), function(v) Config.SafeHighJumpPower = tonumber(v) or 15 end) end)
	addToggle(parent, "Freeze Position", "Freeze", nil, function(p) addBind(p, "Freeze", "Freeze") end)
end

Builders.WorldMisc = function(parent)
	parent = parent or SettingsFrame
	addToggle(parent, "X-Ray", "XRay", ApplyWorldSettings)
	addToggle(parent, "Potato Mode", "PotatoMode", function(st) if st then for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v.Name ~= "Terrain" then v.Material = Enum.Material.SmoothPlastic elseif v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end end end end)
	addToggle(parent, "Night Mode", "NightMode", ApplyWorldSettings)
	addToggle(parent, "Time Warp", "TimeWarp")
	addToggle(parent, "Low Gravity", "Gravity", function() if origGravity == nil then origGravity = Workspace.Gravity end end)
	addToggle(parent, "Lock FOV", "FOV", function(st) if not st then Workspace.CurrentCamera.FieldOfView = 70 end end)
	addToggle(parent, "Auto-Toxic", "AutoToxic")
end

do
	local wantedStatus = "Idle"
	local wantedStatusLabels = {}
local function setWantedStatus(text)
	wantedStatus = text
	for _, lbl in pairs(wantedStatusLabels) do
		pcall(function() lbl.Text = "[STATUS] " .. text end)
	end
end

local atmCooldowns = {}
local currentVehicle = nil
local flyVehicleTo = nil

local WantedDebug = {
	Active = false,
	LastTarget = nil,
	LastInfo = "",
	Highlight = nil,
	AllHighlights = {},
	SameObjects = {},
	SameIndex = 1,
	Card = nil,
	CardLabels = {},
	TestingFly = false
}

local function copyToClipboard(str)
	local copied = false
	str = tostring(str or "")
	pcall(function()
		if setclipboard then setclipboard(str); copied = true
		elseif toclipboard then toclipboard(str); copied = true
		elseif writeclipboard then writeclipboard(str); copied = true
		elseif syn and syn.write_clipboard then syn.write_clipboard(str); copied = true
		elseif Clipboard and Clipboard.set then Clipboard.set(str); copied = true
		elseif setrbxclipboard then setrbxclipboard(str); copied = true
		end
	end)
	pcall(function() print("[RICH INSPECTOR]\n" .. str) end)
	return copied
end

local function getObjectInfoString(target)
	if not target then return "No target selected." end
	local p = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
	local pos = p and p.Position or Vector3.new()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local dist = hrp and math.floor((pos - hrp.Position).Magnitude) or 0

	local prompts = {}
	for _, desc in pairs(target:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			table.insert(prompts, string.format("Prompt(Action='%s', Object='%s', Hold=%.1fs)", desc.ActionText, desc.ObjectText, desc.HoldDuration))
		elseif desc:IsA("ClickDetector") then
			table.insert(prompts, "ClickDetector")
		elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
			table.insert(prompts, desc.ClassName .. "('" .. desc.Name .. "')")
		end
	end
	local promptStr = #prompts > 0 and table.concat(prompts, " | ") or "None"

	local childList = {}
	for _, ch in ipairs(target:GetChildren()) do
		if #childList < 8 then
			table.insert(childList, ch.Name .. " (" .. ch.ClassName .. ")")
		end
	end
	local childStr = #childList > 0 and table.concat(childList, ", ") or "None"

	local sibStr = "None"
	if target.Parent and target.Parent ~= Workspace then
		local counts = {}
		for _, sib in ipairs(target.Parent:GetChildren()) do
			counts[sib.Name] = (counts[sib.Name] or 0) + 1
		end
		local parts = {}
		for k, v in pairs(counts) do
			if #parts < 8 then table.insert(parts, k .. " (x" .. v .. ")") end
		end
		sibStr = target.Parent.Name .. " -> " .. table.concat(parts, ", ")
	end

	local attrList = {}
	pcall(function()
		for k, v in pairs(target:GetAttributes()) do
			if #attrList < 6 then table.insert(attrList, tostring(k) .. "=" .. tostring(v)) end
		end
		for _, vObj in ipairs(target:GetChildren()) do
			if vObj:IsA("ValueBase") and #attrList < 6 then
				table.insert(attrList, vObj.Name .. "=" .. tostring(vObj.Value))
			end
		end
	end)
	local attrStr = #attrList > 0 and table.concat(attrList, ", ") or "None"

	local remotes = {}
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		for _, r in ipairs(rs:GetDescendants()) do
			if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and #remotes < 6 then
				local rn = r.Name:lower()
				if rn:find("atm") or rn:find("rob") or rn:find("gizmo") or rn:find("bank") or rn:find("gold") or rn:find("cash") or rn:find("dealer") or rn:find("interact") then
					table.insert(remotes, r.Name .. " (" .. r.ClassName .. ")")
				end
			end
		end
	end)
	local remStr = #remotes > 0 and table.concat(remotes, ", ") or "None"

	local sameLines = {}
	for idx, item in ipairs(WantedDebug.SameObjects or {}) do
		if idx <= 15 then
			local statusTag = ""
			if item.Instance.Name == "ATM" and isATMBroken then
				local broken, timeLeft = isATMBroken(item.Instance, item.Part)
				statusTag = broken and string.format(" [BROKEN %ds]", timeLeft) or " [READY]"
			end
			table.insert(sameLines, string.format("#%d [%d studs]%s: Vector3.new(%.1f, %.1f, %.1f)", idx, item.Dist, statusTag, item.Pos.X, item.Pos.Y, item.Pos.Z))
		end
	end
	local sameStr = #sameLines > 0 and (string.format("Found %d '%s' objects:\n%s", #(WantedDebug.SameObjects or {}), target.Name, table.concat(sameLines, "\n"))) or "None found."

	return string.format("[WANTED INSPECTOR]\nName: %s\nClass: %s\nPath: %s\nParent: %s\nPosition: Vector3.new(%.1f, %.1f, %.1f)\nDistance: %d studs\nInteractions: %s\nChildren: %s\nAttributes: %s\nParent Content: %s\nRelated Remotes: %s\n\n=== ALL IDENTICAL OBJECTS (%d) ===\n%s",
		target.Name, target.ClassName, target:GetFullName(), target.Parent and target.Parent.Name or "None", pos.X, pos.Y, pos.Z, dist, promptStr, childStr, attrStr, sibStr, remStr, #(WantedDebug.SameObjects or {}), sameStr)
end

local crackTargetATM = nil
local flyTarget = nil
local isATMBroken = nil
local resetBrokenATMs = nil
local getATMFrontCFrame = nil

local function highlightSameObjects()
	for _, h in pairs(WantedDebug.AllHighlights or {}) do pcall(function() h:Destroy() end) end
	WantedDebug.AllHighlights = {}
	for idx, item in ipairs(WantedDebug.SameObjects or {}) do
		if idx <= 35 then
			local sb = Instance.new("SelectionBox")
			sb.Name = "RichSameHighlight"
			sb.Adornee = item.Instance
			local col = Color3.fromRGB(0, 200, 255)
			if item.Instance.Name == "ATM" and isATMBroken then
				local broken = isATMBroken(item.Instance, item.Part)
				col = broken and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 255, 140)
			else
				col = (idx == 1) and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(0, 200, 255)
			end
			sb.Color3 = col
			sb.LineThickness = 0.03
			sb.SurfaceTransparency = 0.88
			sb.SurfaceColor3 = col
			sb.Parent = Workspace
			table.insert(WantedDebug.AllHighlights, sb)
		end
	end
end

local function buildInspectorCard()

	if WantedDebug.Card then return WantedDebug.Card end
	local card = Instance.new("Frame", ScreenGui)
	card.Name = "RichInspectorCard"
	card.Size = UDim2.new(0, 360, 0, 320)
	card.Position = UDim2.new(0.5, -180, 0.55, 0)
	card.BackgroundColor3 = Color3.fromRGB(13, 15, 22)
	card.BackgroundTransparency = 0.06
	card.Active = true
	card.Draggable = false
	card.Visible = false
	card.ZIndex = 160
	rCorner(card, 8)
	rStroke(card, Color3.fromRGB(0, 220, 255), 1.5)

	local header = Instance.new("Frame", card)
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundTransparency = 1
	header.ZIndex = 161

	local hTitle = Instance.new("TextLabel", header)
	hTitle.Size = UDim2.new(1, -30, 1, 0)
	hTitle.Position = UDim2.new(0, 8, 0, 0)
	hTitle.BackgroundTransparency = 1
	hTitle.Text = "🔍 OBJECT INSPECTOR (SELECT & COPY)"
	hTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
	hTitle.Font = Enum.Font.GothamBold
	hTitle.TextSize = 11
	hTitle.TextXAlignment = Enum.TextXAlignment.Left
	hTitle.ZIndex = 162

	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = card.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local closeBtn = Instance.new("TextButton", header)
	closeBtn.Size = UDim2.new(0, 22, 0, 22)
	closeBtn.Position = UDim2.new(1, -26, 0, 3)
	closeBtn.BackgroundColor3 = Color3.fromRGB(30, 18, 22)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 11
	closeBtn.ZIndex = 162
	rCorner(closeBtn, 4)
	closeBtn.MouseButton1Click:Connect(function()
		card.Visible = false
		if WantedDebug.Highlight then WantedDebug.Highlight.Adornee = nil end
		for _, h in pairs(WantedDebug.AllHighlights or {}) do pcall(function() h:Destroy() end) end
		WantedDebug.AllHighlights = {}
	end)

	local infoScroll = Instance.new("ScrollingFrame", card)
	infoScroll.Size = UDim2.new(1, -16, 0, 205)
	infoScroll.Position = UDim2.new(0, 8, 0, 32)
	infoScroll.BackgroundTransparency = 0.5
	infoScroll.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	infoScroll.BorderSizePixel = 0
	infoScroll.ScrollBarThickness = 3
	infoScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	infoScroll.ZIndex = 161
	rCorner(infoScroll, 4)

	local infoBox = Instance.new("TextBox", infoScroll)
	infoBox.Size = UDim2.new(1, -6, 0, 0)
	infoBox.Position = UDim2.new(0, 3, 0, 3)
	infoBox.AutomaticSize = Enum.AutomaticSize.Y
	infoBox.BackgroundTransparency = 1
	infoBox.Font = Enum.Font.Code
	infoBox.TextSize = 10.5
	infoBox.TextColor3 = Color3.fromRGB(220, 235, 255)
	infoBox.TextXAlignment = Enum.TextXAlignment.Left
	infoBox.TextYAlignment = Enum.TextYAlignment.Top
	infoBox.TextWrapped = true
	infoBox.ClearTextOnFocus = false
	infoBox.TextEditable = false
	infoBox.MultiLine = true
	infoBox.Text = "Click any object in the 3D world to inspect."
	infoBox.ZIndex = 162
	WantedDebug.CardLabels.Info = infoBox

	local copyBtn = Instance.new("TextButton", card)
	copyBtn.Size = UDim2.new(0.48, -2, 0, 28)
	copyBtn.Position = UDim2.new(0, 8, 1, -66)
	copyBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
	copyBtn.Text = "📋 Copy Info"
	copyBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.TextSize = 11
	copyBtn.ZIndex = 163
	rCorner(copyBtn, 6)

	local function doCopy()
		if WantedDebug.LastInfo and #WantedDebug.LastInfo > 0 then
			copyToClipboard(WantedDebug.LastInfo)
			copyBtn.Text = "✓ Copied (F9 Console)!"
			task.delay(1.5, function() copyBtn.Text = "📋 Copy Info" end)
			pcall(function() infoBox:CaptureFocus() end)
			if showNotification then showNotification("Copied to Clipboard!", "Text also printed to F9 developer console.", 2.5, Color3.fromRGB(0, 220, 255)) end
		end
	end
	copyBtn.MouseButton1Click:Connect(doCopy)
	pcall(function() copyBtn.Activated:Connect(doCopy) end)

	local flyBtn = Instance.new("TextButton", card)
	flyBtn.Size = UDim2.new(0.48, -2, 0, 28)
	flyBtn.Position = UDim2.new(0.52, 0, 1, -66)
	flyBtn.BackgroundColor3 = Color3.fromRGB(20, 42, 30)
	flyBtn.Text = "🚀 Fly Here"
	flyBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
	flyBtn.Font = Enum.Font.GothamBold
	flyBtn.TextSize = 11
	flyBtn.ZIndex = 163
	rCorner(flyBtn, 6)
	flyBtn.MouseButton1Click:Connect(function()
		if WantedDebug.LastTarget and flyTarget then
			local p = WantedDebug.LastTarget:IsA("BasePart") and WantedDebug.LastTarget or WantedDebug.LastTarget:FindFirstChildWhichIsA("BasePart")
			if p then
				WantedDebug.TestingFly = true
				setWantedStatus("Debug: Flying to " .. WantedDebug.LastTarget.Name .. "...")
				if (WantedDebug.LastTarget.Name == "ATM" or WantedDebug.LastTarget.Name:lower():find("atm")) and getATMFrontCFrame then
					local _, targetPos = getATMFrontCFrame(WantedDebug.LastTarget, p)
					flyTarget(targetPos)
				else
					flyTarget(p.Position + Vector3.new(0, 2, 0))
				end
				WantedDebug.TestingFly = false
				setWantedStatus("Debug: Arrived at " .. WantedDebug.LastTarget.Name)
			end
		end
	end)

	local crackBtn = Instance.new("TextButton", card)
	crackBtn.Size = UDim2.new(0.48, -2, 0, 28)
	crackBtn.Position = UDim2.new(0, 8, 1, -34)
	crackBtn.BackgroundColor3 = Color3.fromRGB(42, 28, 20)
	crackBtn.Text = "🔨 Crack / Interact"
	crackBtn.TextColor3 = Color3.fromRGB(255, 180, 80)
	crackBtn.Font = Enum.Font.GothamBold
	crackBtn.TextSize = 11
	crackBtn.ZIndex = 163
	rCorner(crackBtn, 6)
	crackBtn.MouseButton1Click:Connect(function()
		if WantedDebug.LastTarget and crackTargetATM then
			local part = WantedDebug.LastTarget:IsA("BasePart") and WantedDebug.LastTarget or WantedDebug.LastTarget:FindFirstChildWhichIsA("BasePart")
			if part then
				crackTargetATM({Model = WantedDebug.LastTarget, Part = part})
			end
		end
	end)

	local nextBtn = Instance.new("TextButton", card)
	nextBtn.Size = UDim2.new(0.48, -2, 0, 28)
	nextBtn.Position = UDim2.new(0.52, 0, 1, -34)
	nextBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 42)
	nextBtn.Text = "📍 Fly to Next"
	nextBtn.TextColor3 = Color3.fromRGB(200, 140, 255)
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.TextSize = 11
	nextBtn.ZIndex = 163
	rCorner(nextBtn, 6)
	nextBtn.MouseButton1Click:Connect(function()
		local list = WantedDebug.SameObjects or {}
		if #list > 0 and flyTarget then
			WantedDebug.SameIndex = (WantedDebug.SameIndex % #list) + 1
			local item = list[WantedDebug.SameIndex]
			if item and item.Part then
				nextBtn.Text = string.format("📍 Next (%d/%d)", WantedDebug.SameIndex, #list)
				WantedDebug.TestingFly = true
				setWantedStatus(string.format("Flying to %s #%d...", item.Instance.Name, WantedDebug.SameIndex))
				if (item.Instance.Name == "ATM" or item.Instance.Name:lower():find("atm")) and getATMFrontCFrame then
					local _, targetPos = getATMFrontCFrame(item.Instance, item.Part)
					flyTarget(targetPos)
				else
					flyTarget(item.Part.Position + Vector3.new(0, 2, 0))
				end
				WantedDebug.TestingFly = false
				setWantedStatus(string.format("Arrived at %s #%d!", item.Instance.Name, WantedDebug.SameIndex))
			end
		end
	end)

	WantedDebug.Card = card
	return card
end

local function inspectObject(target)
	if not target then return end
	WantedDebug.LastTarget = target

	local sameObjects = {}
	local targetName = target.Name
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local pPos = hrp and hrp.Position or Vector3.new()

	local seen = {}
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj.Name == targetName and (obj:IsA("Model") or obj:IsA("BasePart")) then
			local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
			if part and not seen[obj] and math.abs(part.Position.Y) < 1500 and not obj:FindFirstAncestorOfClass("Player") then
				seen[obj] = true
				local d = math.floor((part.Position - pPos).Magnitude)
				table.insert(sameObjects, {Instance = obj, Part = part, Pos = part.Position, Dist = d})
			end
		end
	end
	table.sort(sameObjects, function(a, b) return a.Dist < b.Dist end)
	WantedDebug.SameObjects = sameObjects
	WantedDebug.SameIndex = 1

	highlightSameObjects()

	local infoStr = getObjectInfoString(target)
	WantedDebug.LastInfo = infoStr

	if not WantedDebug.Highlight then
		local sb = Instance.new("SelectionBox")
		sb.Name = "RichInspectorHighlight"
		sb.Color3 = Color3.fromRGB(0, 240, 255)
		sb.LineThickness = 0.04
		sb.SurfaceTransparency = 0.8
		sb.SurfaceColor3 = Color3.fromRGB(0, 240, 255)
		sb.Parent = Workspace
		WantedDebug.Highlight = sb
	end
	WantedDebug.Highlight.Adornee = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart") or target) or target

	local card = buildInspectorCard()
	if WantedDebug.CardLabels.Info then
		WantedDebug.CardLabels.Info.Text = infoStr
	end
	card.Visible = true

	copyToClipboard(infoStr)
	if showNotification then
		showNotification("🔍 Object Inspected", target.Name .. " (Total: " .. #sameObjects .. ", Copied!)", 3, Color3.fromRGB(0, 220, 255))
	end
	print(infoStr)
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if Config.Wanted_Debug and not gpe and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local mPos = UserInputService:GetMouseLocation()
		local ray = Workspace.CurrentCamera:ViewportPointToRay(mPos.X, mPos.Y)
		local params = RaycastParams.new()
		if player.Character then
			params.FilterDescendantsInstances = {player.Character}
			params.FilterType = Enum.RaycastFilterType.Exclude
		end
		local res = Workspace:Raycast(ray.Origin, ray.Direction * 1500, params)
		if res and res.Instance then
			local hit = res.Instance
			local target = hit
			if hit.Parent and hit.Parent:IsA("Model") and hit.Parent ~= Workspace and hit.Parent ~= player.Character then
				target = hit.Parent
			end
			inspectObject(target)
		end
	end
end)

local function interactPrompt(prompt, count)
	if not prompt then return end
	count = count or 1
	for i = 1, count do
		pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt, 0, true)
				fireproximityprompt(prompt)
			elseif prompt.InputHoldBegin and prompt.InputHoldEnd then
				prompt:InputHoldBegin()
				task.wait(prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.05) or 0.1)
				prompt:InputHoldEnd()
			end
		end)
		task.wait(0.12)
	end
end

local function triggerEKey(count, interval)
	count = count or 1
	interval = interval or 0.28
	local vim = nil
	pcall(function() vim = game:GetService("VirtualInputManager") end)
	local vu = nil
	pcall(function() vu = game:GetService("VirtualUser") end)

	for i = 1, count do
		pcall(function()
			if vim then
				vim:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
				vim:SendKeyEvent(true, Enum.KeyCode.E, false, false)
			end
		end)
		pcall(function()
			if vu then
				vu:CaptureController()
				vu:SetKeyDown("e")
				vu:TypeKey(0x65)
				vu:TypeKey(101)
			end
		end)
		pcall(function()
			if keyclick then
				keyclick(0x45)
				keyclick(101)
			end
		end)
		pcall(function()
			if keypress then
				keypress(0x45)
				keypress(101)
			end
		end)

		task.wait(0.08)

		pcall(function()
			if vim then
				vim:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
				vim:SendKeyEvent(false, Enum.KeyCode.E, false, false)
			end
		end)
		pcall(function()
			if vu then
				vu:SetKeyUp("e")
			end
		end)
		pcall(function()
			if keyrelease then
				keyrelease(0x45)
				keyrelease(101)
			end
		end)

		if i < count then
			task.wait(interval)
		end
	end
end


local function getOrEnterVehicle()
	local char = player.Character
	if not char then return nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil, nil end

	if hum.SeatPart and (hum.SeatPart:IsA("VehicleSeat") or hum.SeatPart:IsA("Seat")) then
		local seat = hum.SeatPart
		local root = seat.AssemblyRootPart or seat.Parent.PrimaryPart or seat
		currentVehicle = seat.Parent
		return seat, root
	end

	setWantedStatus("Finding Nearest Vehicle...")
	local bestSeat, bestDist = nil, math.huge
	for _, desc in pairs(Workspace:GetDescendants()) do
		if (desc:IsA("VehicleSeat") or (desc:IsA("Seat") and desc.Name:lower():find("drive"))) and not desc.Occupant then
			local d = (desc.Position - hrp.Position).Magnitude
			if d < bestDist then
				bestDist = d
				bestSeat = desc
			end
		end
	end

	if not bestSeat then
		setWantedStatus("Spawning Vehicle via Remote...")
		pcall(function()
			for _, rem in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
				if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
					local n = rem.Name:lower()
					if n:find("spawncar") or n:find("spawnvehicle") or n:find("carspawn") or n:find("vehiclespawn") then
						if rem:IsA("RemoteEvent") then rem:FireServer("Default") else rem:InvokeServer("Default") end
						task.wait(0.8)
						break
					end
				end
			end
		end)

		for _, desc in pairs(Workspace:GetDescendants()) do
			if (desc:IsA("VehicleSeat") or (desc:IsA("Seat") and desc.Name:lower():find("drive"))) and not desc.Occupant then
				local d = (desc.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestSeat = desc
				end
			end
		end
	end

	if bestSeat then
		setWantedStatus("Entering Vehicle Seat...")
		hrp.CFrame = bestSeat.CFrame + Vector3.new(0, 2.5, 0)
		task.wait(0.2)
		bestSeat:Sit(hum)
		task.wait(0.3)
		if hum.SeatPart then
			local root = bestSeat.AssemblyRootPart or bestSeat.Parent.PrimaryPart or bestSeat
			currentVehicle = bestSeat.Parent
			return bestSeat, root
		end
	end

	return nil, nil
end

flyVehicleTo = function(targetPos, speed)
	local seat, root = getOrEnterVehicle()
	if not seat or not root then
		setWantedStatus("Failed to get vehicle!")
		return false
	end

	speed = speed or (Config.Wanted_FlySpeed or 95)
	local curY = root.Position.Y
	local targetY = clamp(targetPos.Y, -300, 1500)
	local flyHeight = clamp(Config.Wanted_FlyHeight or 55, 15, 90)
	local cruiseHeight = clamp(math.max(curY, targetY) + flyHeight, curY + 12, curY + 80)
	local waypoints = {
		Vector3.new(root.Position.X, cruiseHeight, root.Position.Z),
		Vector3.new(targetPos.X, cruiseHeight, targetPos.Z),
		Vector3.new(targetPos.X, targetPos.Y + 2.5, targetPos.Z)
	}

	pcall(function()
		for _, p in pairs(seat.Parent:GetDescendants()) do
			if p:IsA("BasePart") and p.Name:lower():find("wheel") then p.CanCollide = false end
		end
	end)

	for wpIdx, wp in ipairs(waypoints) do
		local threshold = (wpIdx == #waypoints) and 4 or 7
		while (root.Position - wp).Magnitude > threshold do
			if not (Config.Wanted_AutoBank or Config.Wanted_AutoATM or Config.Wanted_VehicleFly or WantedDebug.TestingFly) then
				pcall(function()
					root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end)
				return false
			end
			local dt = RunService.Heartbeat:Wait()
			local offset = wp - root.Position
			local dist = offset.Magnitude
			if dist < 0.05 then break end
			local dir = offset.Unit
			local step = math.min(dist, speed * dt)
			local nextPos = root.Position + dir * step
			local hDir = Vector3.new(dir.X, 0, dir.Z)
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				if hDir.Magnitude > 0.08 then
					root.CFrame = CFrame.new(nextPos, nextPos + hDir)
				else
					root.CFrame = CFrame.new(nextPos) * root.CFrame.Rotation
				end
			end)
		end
	end

	pcall(function()
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end)
	return true
end

local function flyCharacterTo(targetPos, speed, shouldCancel)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return false end

	speed = speed or (Config.Wanted_FlySpeed or 85)
	local curPos = hrp.Position
	local dist = (targetPos - curPos).Magnitude

	if dist <= 3.0 then
		pcall(function()
			hrp.CFrame = CFrame.new(targetPos)
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end)
		return true
	end

	pcall(function()
		hum.PlatformStand = true
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)

	local waypoints = {}
	if dist > 35 then
		local flyHeight = clamp(Config.Wanted_FlyHeight or 45, 18, 75)
		local cruiseY = math.max(curPos.Y, targetPos.Y) + flyHeight
		table.insert(waypoints, Vector3.new(curPos.X, cruiseY, curPos.Z))
		table.insert(waypoints, Vector3.new(targetPos.X, cruiseY, targetPos.Z))
		table.insert(waypoints, targetPos)
	else
		table.insert(waypoints, targetPos)
	end

	local arrived = true
	for wpIdx, wp in ipairs(waypoints) do
		local threshold = (wpIdx == #waypoints) and 2.5 or 5.0
		while (hrp.Position - wp).Magnitude > threshold do
			if shouldCancel and shouldCancel() then
				arrived = false
				break
			end
			local dt = RunService.Heartbeat:Wait()
			if not hrp or not hum then arrived = false; break end

			local offset = wp - hrp.Position
			local distToWp = offset.Magnitude
			if distToWp < 0.05 then break end

			local dir = offset.Unit
			local step = math.min(distToWp, speed * dt)
			local nextPos = hrp.Position + dir * step
			local lookDir = Vector3.new(dir.X, 0, dir.Z)

			pcall(function()
				hrp.AssemblyLinearVelocity = dir * speed
				hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				if lookDir.Magnitude > 0.1 then
					hrp.CFrame = CFrame.new(nextPos, nextPos + lookDir)
				else
					hrp.CFrame = CFrame.new(nextPos) * hrp.CFrame.Rotation
				end
			end)
		end
		if not arrived then break end
	end

	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		hrp.CFrame = CFrame.new(targetPos)
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = true end
		end
	end)

	return arrived
end

flyTarget = function(targetPos, speed, shouldCancel)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
		return flyVehicleTo(targetPos, speed)
	else
		return flyCharacterTo(targetPos, speed, shouldCancel)
	end
end

local brokenATMs = {}

isATMBroken = function(atmModel, part)
	if not atmModel then return false, 0 end
	local objId = atmModel:GetAttribute("objectId")
	local posKey = part and string.format("%.0f_%.0f", part.Position.X, part.Position.Z)
	local lastRobbed = (objId and brokenATMs[objId]) or (posKey and brokenATMs[posKey]) or brokenATMs[atmModel] or 0
	local cd = Config.Wanted_ATMCooldown or 150
	if (tick() - lastRobbed) < cd then
		return true, math.ceil(cd - (tick() - lastRobbed))
	end
	if atmModel:GetAttribute("broken") == true or atmModel:GetAttribute("robbed") == true or atmModel:GetAttribute("empty") == true then
		return true, 60
	end
	local alarm = atmModel:FindFirstChild("AlarmLight")
	if alarm and alarm:IsA("BasePart") then
		if alarm.Material == Enum.Material.Neon or (alarm.Color.R > 0.8 and alarm.Color.G < 0.3) then
			return true, 60
		end
	end
	return false, 0
end

local function markATMBroken(atmModel, part)
	local objId = atmModel:GetAttribute("objectId")
	local posKey = part and string.format("%.0f_%.0f", part.Position.X, part.Position.Z)
	local now = tick()
	if objId then brokenATMs[objId] = now end
	if posKey then brokenATMs[posKey] = now end
	brokenATMs[atmModel] = now
	atmCooldowns[atmModel] = now
end

resetBrokenATMs = function()
	brokenATMs = {}
	atmCooldowns = {}
	if showNotification then showNotification("ATM Memory Reset", "Cleared all ATM cooldowns and broken states.", 2, Color3.fromRGB(0, 255, 140)) end
	setWantedStatus("ATM cooldown memory cleared!")
end

getATMFrontCFrame = function(atmModel, atmPart)
	local targetPart = atmModel:FindFirstChild("Slot") or atmModel:FindFirstChild("ATMDoor") or atmPart
	local basePos = targetPart.Position
	local look = targetPart.CFrame.LookVector
	local right = targetPart.CFrame.RightVector

	local forwardDir = nil
	pcall(function()
		local modelCf, modelSize = atmModel:GetBoundingBox()
		local offsetFromCenter = Vector3.new(basePos.X - modelCf.Position.X, 0, basePos.Z - modelCf.Position.Z)
		if offsetFromCenter.Magnitude > 0.15 then
			forwardDir = offsetFromCenter.Unit
		end
	end)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {atmModel, player.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	if not forwardDir then
		local candidates = {look, -look, right, -right}
		local bestDir = look
		local bestClearDist = -1

		for _, cand in ipairs(candidates) do
			local candH = Vector3.new(cand.X, 0, cand.Z).Unit
			local hit = Workspace:Raycast(basePos, candH * 6, rayParams)
			local clearDist = hit and (hit.Position - basePos).Magnitude or 6
			if clearDist > bestClearDist then
				bestClearDist = clearDist
				bestDir = candH
			end
		end
		forwardDir = bestDir
	end

	local wallHit = Workspace:Raycast(basePos, forwardDir * 2.5, rayParams)
	if wallHit and (wallHit.Position - basePos).Magnitude < 1.7 then
		forwardDir = -forwardDir
	end

	local standPos = basePos + forwardDir * 1.8

	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local standY = hrp and hrp.Position.Y or basePos.Y
	local floorHit = Workspace:Raycast(Vector3.new(standPos.X, basePos.Y + 3, standPos.Z), Vector3.new(0, -12, 0), rayParams)
	if floorHit then
		standY = floorHit.Position.Y + 3.0
	end

	standPos = Vector3.new(standPos.X, standY, standPos.Z)
	local lookAtTarget = Vector3.new(basePos.X, standY, basePos.Z)
	return CFrame.new(standPos, lookAtTarget), standPos
end

crackTargetATM = function(atm)
	if not atm or not atm.Part then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	pcall(function()
		hum.Sit = false
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	local standCFrame, standPos = getATMFrontCFrame(atm.Model, atm.Part)
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		hrp.CFrame = standCFrame
	end)
	task.wait(0.12)

	local totalHits = Config.Wanted_ATMHits or 4
	for hit = 1, totalHits do
		if not (Config.Wanted_AutoATM or WantedDebug.TestingFly) then break end
		pcall(function()
			hrp.CFrame = standCFrame
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end)
		setWantedStatus(string.format("Cracking %s (Hit %d/%d)...", atm.Model.Name, hit, totalHits))

		pcall(function()
			local tool = char:FindFirstChildOfClass("Tool")
			if not tool then
				local bp = player:FindFirstChild("Backpack")
				tool = bp and bp:FindFirstChildOfClass("Tool")
				if tool and hum then hum:EquipTool(tool) end
			end
			if tool then tool:Activate() end
		end)

		pcall(function()
			for _, desc in ipairs(atm.Model:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					interactPrompt(desc, 1)
				elseif desc:IsA("ClickDetector") then
					pcall(function() fireclickdetector(desc) end)
				elseif desc:IsA("GuiButton") then
					pcall(function()
						if firesignal then
							firesignal(desc.MouseButton1Click)
							firesignal(desc.Activated)
						end
					end)
				end
			end
		end)

		pcall(function()
			local pg = player:FindFirstChild("PlayerGui")
			if pg then
				for _, g in ipairs(pg:GetDescendants()) do
					if (g:IsA("TextButton") or g:IsA("ImageButton")) and g.Visible then
						local gn = g.Name:lower()
						local gt = (g:IsA("TextButton") and g.Text or ""):lower()
						if gn:find("interact") or gn:find("rob") or gn:find("atm") or gn:find("action") or gt:find("e") or gt:find("rob") or gt:find("crack") then
							if firesignal then
								firesignal(g.MouseButton1Click)
								firesignal(g.Activated)
							end
						end
					end
				end
			end
		end)

		triggerEKey(1, 0.01)
		task.wait(0.30)
	end

	setWantedStatus("ATM Cracked! Collecting Cash Drops...")
	task.wait(Config.Wanted_ATMDelay or 0.6)
	pcall(function()
		local pickupRange = 22
		for _, obj in pairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				local n = obj.Name:lower()
				local gType = tostring(obj:GetAttribute("gizmoType") or "")
				if gType == "Lootable" or n:find("cash") or n:find("money") or n:find("drop") or n:find("bill") or n:find("coin") or n:find("ruble") or n:find("dollar") then
					if (obj.Position - standPos).Magnitude < pickupRange then
						hrp.CFrame = obj.CFrame + Vector3.new(0, 1, 0)
						triggerEKey(1, 0.08)
						task.wait(0.12)
					end
				end
			end
		end
	end)

	markATMBroken(atm.Model, atm.Part)
	setWantedStatus("Cracked " .. atm.Model.Name .. " (Marked Broken in memory)!")
end

local function crackNearestATM()
	local atms = findATMs(false)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if #atms == 0 then
		local allAtms = findATMs(true)
		if #allAtms > 0 then
			setWantedStatus("Nearest ATM is broken/on cooldown!")
		else
			setWantedStatus("No ATMs found nearby!")
		end
		return
	end
	local bestAtm, bestDist = atms[1], math.huge
	for _, a in ipairs(atms) do
		local d = (a.Part.Position - hrp.Position).Magnitude
		if d < bestDist then bestDist = d; bestAtm = a end
	end
	crackTargetATM(bestAtm)
end

local function getGizmosFolder()
	return (Workspace:FindFirstChild("Local") and Workspace.Local:FindFirstChild("Gizmos")) or Workspace:FindFirstChild("Gizmos")
end

local function findBankGoldBars()
	local bars = {}
	local seen = {}

	local gizmos = getGizmosFolder()
	if gizmos then
		for _, obj in ipairs(gizmos:GetChildren()) do
			local n = obj.Name:lower()
			local gType = tostring(obj:GetAttribute("gizmoType") or "")
			if gType == "Lootable" or n:find("gold") or n:find("silver") or n:find("bar") or n:find("vault") or n:find("cash") or n:find("money") or n:find("pallet") or n:find("safe") then
				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part and not seen[obj] and part.Transparency < 1 and not obj:FindFirstAncestorOfClass("Player") then
					seen[obj] = true
					table.insert(bars, {Model = obj, Part = part, Name = obj.Name})
				end
			end
		end
	end

	if #bars == 0 then
		for _, obj in pairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") or obj:IsA("Model") then
				local n = obj.Name:lower()
				local skipNode = (n:find("atmosphere") or n:find("platform") or n:find("terrain")) ~= nil
				if (n:find("gold") or n:find("ingot") or n:find("bar") or n:find("vaultcash") or n:find("cashpile") or n:find("moneybag")) and not obj:FindFirstAncestorOfClass("Tool") and not obj:FindFirstAncestorOfClass("Player") then
					local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
					if part and not seen[obj] and part.Transparency < 1 and math.abs(part.Position.Y) < 1500 then
						seen[obj] = true
						table.insert(bars, {Model = obj, Part = part, Name = obj.Name})
					end
				end
			end
		end
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and #bars > 1 then
		table.sort(bars, function(a, b)
			return (a.Part.Position - hrp.Position).Magnitude < (b.Part.Position - hrp.Position).Magnitude
		end)
	end
	return bars
end

local function findGoldDealer()
	local gizmos = getGizmosFolder()
	if gizmos then
		for _, obj in ipairs(gizmos:GetChildren()) do
			local n = obj.Name:lower()
			if n:find("buyer") or n:find("dealer") or n:find("fence") or n:find("sell") or n:find("pawn") or n:find("gold") then
				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part then return part end
			end
		end
	end

	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if n:find("buyer") or n:find("dealer") or n:find("fence") or n:find("goldbuyer") or n:find("pawn") or n:find("seller") or n:find("dropoff") then
			local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
			if part then return part end
		end
		if obj:IsA("ProximityPrompt") then
			local act = (obj.ActionText .. " " .. obj.ObjectText):lower()
			if act:find("sell") or act:find("dealer") or act:find("gold") then
				return obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
			end
		end
	end
	return nil
end

local function findATMs(includeBroken)
	local atms = {}
	local seen = {}

	local gizmosFolders = {}
	if Workspace:FindFirstChild("Local") and Workspace.Local:FindFirstChild("Gizmos") then
		table.insert(gizmosFolders, Workspace.Local.Gizmos)
	end
	if Workspace:FindFirstChild("Gizmos") then
		table.insert(gizmosFolders, Workspace.Gizmos)
	end

	for _, gFolder in ipairs(gizmosFolders) do
		for _, child in ipairs(gFolder:GetChildren()) do
			local n = child.Name:lower()
			local gType = tostring(child:GetAttribute("gizmoType") or "")
			if n == "atm" or gType == "ATM" or n:find("atm") or n:find("bankomat") then
				local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart")
				if part and not seen[child] and math.abs(part.Position.Y) < 1500 then
					seen[child] = true
					local broken, timeLeft = isATMBroken(child, part)
					if includeBroken or not broken then
						local prompt = child:FindFirstChildOfClass("ProximityPrompt") or child:FindFirstChildWhichIsA("ProximityPrompt", true)
						table.insert(atms, {Model = child, Part = part, Prompt = prompt, Broken = broken, TimeLeft = timeLeft})
					end
				end
			end
		end
	end

	for _, obj in pairs(Workspace:GetDescendants()) do
		local n = obj.Name:lower()
		if n:find("atmosphere") or n:find("platform") or n:find("water") or n:find("batman") or n:find("treatment") or n:find("terrain") or n:find("camera") then
			do end --[[continue]]
		end

		local isATM = false
		local prompt = nil

		if obj:IsA("ProximityPrompt") then
			local act = (obj.ActionText .. " " .. obj.ObjectText):lower()
			if act:find("atm") or act:find("hack") or act:find("rob") or act:find("break") or act:find("bankomat") then
				isATM = true
				prompt = obj
			end
		elseif obj:GetAttribute("gizmoType") == "ATM" or n:match("%fatm%f[%A]") or n == "atm" or n:find("atm_") or n:find("_atm") or n:find("atm ") or n:find(" atm") or n:find("bankomat") or n:find("cashmachine") or n:find("cash_machine") then
			isATM = true
		end

		if isATM then
			local model = obj:IsA("Model") and obj or (obj.Parent and obj.Parent:IsA("Model") and obj.Parent or obj)
			local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart") or (model:IsA("Model") and model:FindFirstChildWhichIsA("BasePart"))
			if part and not seen[model] and math.abs(part.Position.Y) < 1500 and not part:FindFirstAncestorOfClass("Player") then
				seen[model] = true
				local broken, timeLeft = isATMBroken(model, part)
				if includeBroken or not broken then
					table.insert(atms, {Model = model, Part = part, Prompt = prompt, Broken = broken, TimeLeft = timeLeft})
				end
			end
		end
	end

	return atms
end

local bankFarmThread = nil
local function startWantedBankLoop()
	if bankFarmThread then return end
	bankFarmThread = task.spawn(function()
		while Config.Wanted_AutoBank do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")

			local lootItems = findBankGoldBars()
			local targetPos = nil
			if #lootItems > 0 then
				targetPos = lootItems[1].Part.Position
			else
				for _, obj in pairs(Workspace:GetDescendants()) do
					if obj.Name:lower():find("bank") or obj.Name:lower():find("vault") then
						local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
						if p then targetPos = p.Position; break end
					end
				end
			end

			if not targetPos then
				setWantedStatus("Bank Vault not found! Waiting...")
				task.wait(3)
				do end --[[continue]]
			end

			setWantedStatus("Bank Farm: Flying to Bank Vault...")
			local arrived = flyTarget(targetPos + Vector3.new(0, 2, 0), Config.Wanted_FlySpeed, function() return not Config.Wanted_AutoBank end)
			if not arrived or not Config.Wanted_AutoBank then break end

			setWantedStatus("Bank Farm: Collecting Vault Loot...")
			lootItems = findBankGoldBars()
			if #lootItems > 0 and hrp then
				for idx, item in ipairs(lootItems) do
					if not Config.Wanted_AutoBank then break end
					if item.Model and item.Model.Parent and item.Part.Transparency < 0.9 then
						setWantedStatus(string.format("Bank Farm: Looting %s (%d/%d)...", item.Name, idx, #lootItems))
						pcall(function()
							hrp.CFrame = item.Part.CFrame + Vector3.new(0, 1.2, 0)
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							local prompt = item.Model:FindFirstChildOfClass("ProximityPrompt") or item.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
							if prompt then
								interactPrompt(prompt, 1)
							end
							triggerEKey(2, 0.12)
							task.wait(0.18)
						end)
					end
				end
			else
				setWantedStatus("No gold available. Waiting 5s...")
				task.wait(5)
			end

			if Config.Wanted_AutoSell and Config.Wanted_AutoBank then
				setWantedStatus("Bank Farm: Locating Gold Dealer...")
				local dealer = findGoldDealer()
				if dealer then
					setWantedStatus("Bank Farm: Flying to Gold Dealer...")
					flyTarget(dealer.Position + Vector3.new(0, 2, 0), Config.Wanted_FlySpeed, function() return not Config.Wanted_AutoBank end)
					setWantedStatus("Bank Farm: Selling Gold...")
					local prompt = dealer:FindFirstChildOfClass("ProximityPrompt") or dealer.Parent:FindFirstChildOfClass("ProximityPrompt")
					if prompt then
						interactPrompt(prompt, 2)
					else
						triggerEKey(3, 0.15)
					end
					task.wait(1.5)
					setWantedStatus("Gold Sold! Heading back to Bank...")
				end
			end

			task.wait(1)
		end
		bankFarmThread = nil
		setWantedStatus("Bank Farm Stopped.")
	end)
end

local atmFarmThread = nil
local function startWantedATMLoop()
	if atmFarmThread then return end
	atmFarmThread = task.spawn(function()
		while Config.Wanted_AutoATM do
			setWantedStatus("ATM Farm: Scanning map for ATMs...")
			local atms = findATMs(false)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")

			if #atms == 0 or not hrp then
				local allAtms = findATMs(true)
				if #allAtms > 0 then
					local minTime = math.huge
					for _, a in ipairs(allAtms) do
						if a.TimeLeft and a.TimeLeft > 0 and a.TimeLeft < minTime then
							minTime = a.TimeLeft
						end
					end
					if minTime == math.huge then minTime = 10 end
					setWantedStatus(string.format("All %d ATMs on cooldown! Next ready in %ds. Waiting...", #allAtms, minTime))
				else
					setWantedStatus("No ATMs found on map! Retrying in 3s...")
				end
				task.wait(3)
				do end --[[continue]]
			end

			local bestAtm, bestDist = nil, math.huge
			for _, item in ipairs(atms) do
				local d = (item.Part.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestAtm = item
				end
			end

			if not bestAtm then
				task.wait(2)
				do end --[[continue]]
			end

			setWantedStatus("ATM Farm: Flying to ATM (" .. bestAtm.Model.Name .. ")...")
			local standCFrame, targetPos = getATMFrontCFrame(bestAtm.Model, bestAtm.Part)
			local arrived = flyTarget(targetPos, Config.Wanted_FlySpeed, function() return not Config.Wanted_AutoATM end)
			if not arrived or not Config.Wanted_AutoATM then break end

			crackTargetATM(bestAtm)
			task.wait(0.3)
		end
		atmFarmThread = nil
		setWantedStatus("ATM Farm Stopped.")
	end)
end

Connections["Wanted_VehicleFly"] = RunService.Heartbeat:Connect(function(dt)
	if Config.Wanted_VehicleFly and player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart then
			local seat = hum.SeatPart
			local root = seat.AssemblyRootPart or seat
			local cam = Workspace.CurrentCamera
			local mv = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0, 1, 0) end

			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			if mv.Magnitude > 0 then
				local spd = (Config.Wanted_FlySpeed or 95)
				root.CFrame = CFrame.new(root.Position + (mv.Unit * (spd * dt)), root.Position + cam.CFrame.LookVector * 10)
			end
		end
	end
end)

Builders.Games = function(parent)
	parent = parent or SettingsFrame
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local btnW = isModern and 690 or (dropW or (parent == SettingsFrame and 450 or 180))

	local gameCard = Instance.new("Frame", parent)
	gameCard.Size = UDim2.new(0, btnW, 0, 52)
	gameCard.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	gameCard.BackgroundTransparency = 0.1
	rCorner(gameCard, 6)
	local gStroke = Instance.new("UIStroke", gameCard)
	gStroke.Color = ActiveTheme.Accent
	gStroke.Thickness = 1
	gStroke.Transparency = 0.3

	local gTitle = Instance.new("TextLabel", gameCard)
	gTitle.Size = UDim2.new(0.65, 0, 0, 22)
	gTitle.Position = UDim2.new(0, 10, 0, 6)
	gTitle.BackgroundTransparency = 1
	gTitle.Text = "🎮 ACTIVE PLACE: WANTED"
	gTitle.TextColor3 = ActiveTheme.Accent
	gTitle.Font = Enum.Font.GothamBold
	gTitle.TextSize = 12
	gTitle.TextXAlignment = Enum.TextXAlignment.Left

	local gSub = Instance.new("TextLabel", gameCard)
	gSub.Size = UDim2.new(0.65, 0, 0, 18)
	gSub.Position = UDim2.new(0, 10, 0, 28)
	gSub.BackgroundTransparency = 1
	gSub.Text = "Place ID: " .. tostring(game.PlaceId) .. " • Wild West Crime"
	gSub.TextColor3 = Color3.fromRGB(160, 165, 185)
	gSub.Font = Enum.Font.Gotham
	gSub.TextSize = 10
	gSub.TextXAlignment = Enum.TextXAlignment.Left

	local gStatusBadge = Instance.new("TextLabel", gameCard)
	gStatusBadge.Size = UDim2.new(0, 78, 0, 22)
	gStatusBadge.Position = UDim2.new(1, -86, 0.5, -11)
	gStatusBadge.BackgroundColor3 = Color3.fromRGB(24, 34, 28)
	gStatusBadge.Text = "● ACTIVE"
	gStatusBadge.TextColor3 = Color3.fromRGB(0, 255, 140)
	gStatusBadge.Font = Enum.Font.GothamBold
	gStatusBadge.TextSize = 10
	rCorner(gStatusBadge, 11)

	local statLbl = Instance.new("TextLabel", parent)
	statLbl.Size = UDim2.new(0, btnW, 0, 26)
	statLbl.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	statLbl.BackgroundTransparency = 0.2
	statLbl.Text = "[STATUS] " .. wantedStatus
	statLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
	statLbl.Font = Enum.Font.GothamBold
	statLbl.TextSize = 11
	rCorner(statLbl, 6)
	table.insert(wantedStatusLabels, statLbl)

	local sep1 = Instance.new("Frame", parent); sep1.Size = UDim2.new(0, btnW, 0, 1); sep1.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep1.BorderSizePixel = 0
	local tBank = Instance.new("TextLabel", parent); tBank.Size = UDim2.new(1,0,0,22); tBank.BackgroundTransparency = 1; tBank.Text = "🏦 BANK GOLD AUTO-FARM"; tBank.Font = Enum.Font.GothamBold; tBank.TextColor3 = Color3.fromRGB(240,240,255); tBank.TextSize = 12

	addToggle(parent, "Auto-Farm Bank Vault", "Wanted_AutoBank", function(st)
		if st then startWantedBankLoop() else setWantedStatus("Bank Farm Paused.") end
	end)
	addToggle(parent, "Auto-Sell at Dealer", "Wanted_AutoSell")
	createButton(parent, "Fly to Bank Directly", btnW, function()
		local dealer = findBankGoldBars()
		local p = #dealer > 0 and dealer[1].Position or nil
		if not p then for _, o in pairs(Workspace:GetDescendants()) do if o.Name:lower():find("bank") and o:IsA("BasePart") then p = o.Position; break end end end
		if p and flyTarget then flyTarget(p + Vector3.new(0, 2, 0)) end
	end)
	createButton(parent, "Fly to Gold Dealer Directly", btnW, function()
		local d = findGoldDealer()
		if d and flyTarget then flyTarget(d.Position + Vector3.new(0, 2, 0)) end
	end)

	local sep2 = Instance.new("Frame", parent); sep2.Size = UDim2.new(0, btnW, 0, 1); sep2.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep2.BorderSizePixel = 0
	local tATM = Instance.new("TextLabel", parent); tATM.Size = UDim2.new(1,0,0,22); tATM.BackgroundTransparency = 1; tATM.Text = "🏧 ATM ROBBERY AUTO-FARM"; tATM.Font = Enum.Font.GothamBold; tATM.TextColor3 = Color3.fromRGB(240,240,255); tATM.TextSize = 12

	addToggle(parent, "Auto-Rob All ATMs", "Wanted_AutoATM", function(st)
		if st then startWantedATMLoop() else setWantedStatus("ATM Farm Paused.") end
	end)
	createButton(parent, "🔨 Crack Nearest ATM Now", btnW, function()
		crackNearestATM()
	end)
	createButton(parent, "Fly to Nearest ATM", btnW, function()
		local atms = findATMs()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and #atms > 0 and flyTarget then
			local bA, bD = atms[1], math.huge
			for _, item in ipairs(atms) do
				local d = (item.Part.Position - hrp.Position).Magnitude
				if d < bD then bD = d; bA = item end
			end
			local _, targetPos = getATMFrontCFrame(bA.Model, bA.Part)
			flyTarget(targetPos, Config.Wanted_FlySpeed)
		end
	end)
	createButton(parent, "🔄 Reset ATM Memory (Clear Cooldowns)", btnW, function()
		if resetBrokenATMs then resetBrokenATMs() end
	end)
	createTextBox(parent, "ATM Cooldown (s)", tostring(Config.Wanted_ATMCooldown or 150), function(v)
		Config.Wanted_ATMCooldown = tonumber(v) or 150
	end)
	createTextBox(parent, "ATM Hits Required", tostring(Config.Wanted_ATMHits or 4), function(v)
		Config.Wanted_ATMHits = tonumber(v) or 4
	end)
	createTextBox(parent, "Cash Collect Delay (s)", tostring(Config.Wanted_ATMDelay or 0.8), function(v)
		Config.Wanted_ATMDelay = tonumber(v) or 0.8
	end)

	local sep3 = Instance.new("Frame", parent); sep3.Size = UDim2.new(0, btnW, 0, 1); sep3.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep3.BorderSizePixel = 0
	local tVeh = Instance.new("TextLabel", parent); tVeh.Size = UDim2.new(1,0,0,22); tVeh.BackgroundTransparency = 1; tVeh.Text = "🚗 VEHICLE FLIGHT & BYPASS"; tVeh.Font = Enum.Font.GothamBold; tVeh.TextColor3 = Color3.fromRGB(240,240,255); tVeh.TextSize = 12

	addToggle(parent, "Vehicle 3D Flight (WASD)", "Wanted_VehicleFly")
	createButton(parent, "Get / Enter Nearest Vehicle", btnW, function()
		getOrEnterVehicle()
	end)
	createTextBox(parent, "Flight Speed", tostring(Config.Wanted_FlySpeed or 95), function(v)
		Config.Wanted_FlySpeed = tonumber(v) or 95
	end)
	createTextBox(parent, "Cruise Altitude", tostring(Config.Wanted_FlyHeight or 55), function(v)
		Config.Wanted_FlyHeight = tonumber(v) or 55
	end)

	local sep4 = Instance.new("Frame", parent); sep4.Size = UDim2.new(0, btnW, 0, 1); sep4.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep4.BorderSizePixel = 0
	local tDeb = Instance.new("TextLabel", parent); tDeb.Size = UDim2.new(1,0,0,22); tDeb.BackgroundTransparency = 1; tDeb.Text = "🔍 OBJECT INSPECTOR & DEBUG"; tDeb.Font = Enum.Font.GothamBold; tDeb.TextColor3 = Color3.fromRGB(0,220,255); tDeb.TextSize = 12

	addToggle(parent, "Debug Inspector (Click in World)", "Wanted_Debug", function(st)
		WantedDebug.Active = st
		if not st and WantedDebug.Highlight then WantedDebug.Highlight.Adornee = nil end
		if not st then
			for _, h in pairs(WantedDebug.AllHighlights or {}) do pcall(function() h:Destroy() end) end
			WantedDebug.AllHighlights = {}
		end
		if not st and WantedDebug.Card then WantedDebug.Card.Visible = false end
		if showNotification then
			showNotification("Debug Inspector", st and "CLICK ANY 3D OBJECT TO INSPECT" or "Inspector Disabled", 2, st and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(160, 50, 50))
		end
	end)
	createButton(parent, "Copy Last Inspected Info", btnW, function(b)
		if WantedDebug.LastInfo and #WantedDebug.LastInfo > 0 then
			copyToClipboard(WantedDebug.LastInfo)
			b.Text = "  ✓ Copied to Clipboard (also in F9)!"
			task.delay(1.5, function() b.Text = "  Copy Last Inspected Info" end)
			if showNotification then showNotification("Copied to Clipboard!", "Full data copied & printed to F9.", 2.5, Color3.fromRGB(0, 220, 255)) end
		else
			b.Text = "  No object inspected yet! Click an ATM first."
			task.delay(1.5, function() b.Text = "  Copy Last Inspected Info" end)
		end
	end)
	createButton(parent, "Fly to Inspected Target", btnW, function()
		if WantedDebug.LastTarget and flyTarget then
			local p = WantedDebug.LastTarget:IsA("BasePart") and WantedDebug.LastTarget or WantedDebug.LastTarget:FindFirstChildWhichIsA("BasePart")
			if p then
				WantedDebug.TestingFly = true
				setWantedStatus("Debug: Flying to " .. WantedDebug.LastTarget.Name .. "...")
				flyTarget(p.Position + Vector3.new(0, 2, 0))
				WantedDebug.TestingFly = false
				setWantedStatus("Debug: Arrived at " .. WantedDebug.LastTarget.Name)
			end
		end
	end)
	createButton(parent, "📍 Highlight All Matching Objects", btnW, function()
		highlightSameObjects()
		if showNotification then showNotification("Highlights Active", "Marked all identical objects across map", 2, Color3.fromRGB(0, 220, 255)) end
	end)
end
end

Builders.ThemeUI = function(parent)
	parent = parent or SettingsFrame
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local btnW = isModern and 690 or (dropW or (parent == SettingsFrame and 450 or 180))
	createButton(parent, "UI Style: " .. Config.UIStyle, btnW, function(b)
		local styles = {"Window", "Dropdown", "Modern"}
		local curIdx = table.find(styles, Config.UIStyle) or 1
		Config.UIStyle = styles[(curIdx % #styles) + 1]
		b.Text = "  UI Style: " .. Config.UIStyle
		if RefreshUI then RefreshUI() end
		if showNotification then showNotification("UI Style Changed", "Active: " .. Config.UIStyle, 2, ActiveTheme.Accent) end
	end)
	addToggle(parent, "RGB Chroma UI", "RGBUI")
	local t2 = Instance.new("TextLabel", parent); t2.Size = UDim2.new(1,0,0,24); t2.BackgroundTransparency = 1; t2.Text = "STATIC THEMES"; t2.Font = Enum.Font.GothamBold; t2.TextColor3 = Color3.fromRGB(240,240,255); t2.TextSize = 13
	local function setT(name)
		Config.RGBUI = false; ActiveThemeName = name; ActiveTheme = Themes[name] or Themes["RichDark"]
		MainFrame.BackgroundColor3 = ActiveTheme.BG; TabsFrame.BackgroundColor3 = ActiveTheme.Panel; SettingsFrame.BackgroundColor3 = ActiveTheme.Panel; ArrayListFrame.BackgroundColor3 = ActiveTheme.BG; DmgLogFrame.BackgroundColor3 = ActiveTheme.BG; RadarFrame.BackgroundColor3 = ActiveTheme.BG
		if DynamicIsland then DynamicIsland.BackgroundColor3 = ActiveTheme.BG end
		if ModernFrame then
			ModernFrame.BackgroundColor3 = ActiveTheme.BG
			if modernStroke then modernStroke.Color = ActiveTheme.Accent end
			if mHeaderDivider then mHeaderDivider.BackgroundColor3 = ActiveTheme.Accent end
			if mLogo then mLogo.TextColor3 = ActiveTheme.Accent end
			if ModernScroll then ModernScroll.ScrollBarImageColor3 = ActiveTheme.Accent end
			for tName, tBtn in pairs(modernTabButtons) do
				if tName == modernActiveTab then tBtn.BackgroundColor3 = ActiveTheme.Accent end
			end
		end
		for _, df in pairs(DropdownFrames) do
			df.BackgroundColor3 = ActiveTheme.Panel
			local sc = df:FindFirstChild("Scroll")
			if sc then sc.BackgroundColor3 = ActiveTheme.Panel; sc.ScrollBarImageColor3 = ActiveTheme.Accent end
			local top = df:FindFirstChildOfClass("TextButton")
			if top then top.TextColor3 = ActiveTheme.Accent end
		end
		for _,s in pairs(UI_Elements.Strokes) do pcall(function() s.Color=ActiveTheme.Accent end) end
		for _,t in pairs(UI_Elements.Texts) do pcall(function() t.TextColor3=ActiveTheme.Accent end) end
		if showNotification then showNotification("Theme Changed", "Switched to " .. name, 2, ActiveTheme.Accent) end
	end
	createButton(parent, "Rich Dark", btnW, function() setT("RichDark") end)
	createButton(parent, "Purple Black", btnW, function() setT("PurpleBlack") end)
	createButton(parent, "Cyber Blue", btnW, function() setT("CyberBlue") end)
	createButton(parent, "Blood Red", btnW, function() setT("BloodRed") end)
	createButton(parent, "Cyberpunk", btnW, function() setT("Cyberpunk") end)
	createButton(parent, "Emerald Green", btnW, function() setT("Emerald") end)
	createButton(parent, "Midnight Sakura", btnW, function() setT("Sakura") end)
end

Builders.Configs = function(parent)
	parent = parent or SettingsFrame
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local btnW = isModern and 690 or (dropW or (parent == SettingsFrame and 450 or 180))
	local cfgName = "Default"
	createTextBox(parent, "Config Name", cfgName, function(v) cfgName = v end)
	createButton(parent, "Save Config", btnW, function(b) SaveConfig(cfgName); b.Text="  Saved!"; task.delay(1, function() b.Text="  Save Config" end) end)
	
	addToggle(parent, "Load World/Weather Settings", "LoadWorldSettings")
	
	createButton(parent, "Open Config Folder", btnW, function(b) pcall(function() if openfolder then openfolder("RichPremium") b.Text="  Opened!" else b.Text="  Not supported by Executor" end end); task.delay(1.5, function() b.Text="  Open Config Folder" end) end)
	
	local sep = Instance.new("Frame", parent); sep.Size = UDim2.new(0, btnW, 0, 2); sep.BackgroundColor3 = ActiveTheme.Accent; table.insert(UI_Elements.Strokes, {Color = sep.BackgroundColor3, Parent = sep})
	local t2 = Instance.new("TextLabel", parent); t2.Size = UDim2.new(1,0,0,24); t2.BackgroundTransparency = 1; t2.Text = "SAVED CONFIGS"; t2.Font = Enum.Font.GothamBold; t2.TextColor3 = Color3.fromRGB(240,240,255); t2.TextSize = 13
	
	pcall(function()
		if isfolder("RichPremium") then
			local files = listfiles("RichPremium")
			for _, file in ipairs(files) do
				local name = file:match("([^/\\]+)%.json$")
				if name and name:lower() ~= "song" and name:lower() ~= "current_song" and name:lower() ~= "music" then
					local isValid = false
					pcall(function()
						local content = readfile(file)
						local dec = HttpService:JSONDecode(content)
						if dec and dec.C and type(dec.C) == "table" then isValid = true end
					end)
					if isValid then
						createButton(parent, "[Load] " .. name, btnW, function(b) LoadConfig(name); b.Text="  Loaded!"; task.delay(1, function() b.Text="  [Load] " .. name end) end)
					end
				end
			end
		end
	end)

	local sep2 = Instance.new("Frame", parent); sep2.Size = UDim2.new(0, btnW, 0, 2); sep2.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
	local dangerCard = Instance.new("Frame", parent)
	dangerCard.Size = UDim2.new(0, btnW, 0, 72)
	dangerCard.BackgroundColor3 = Color3.fromRGB(26, 14, 18)
	dangerCard.BackgroundTransparency = 0.2
	rCorner(dangerCard, 6)
	local dStroke = Instance.new("UIStroke", dangerCard)
	dStroke.Color = Color3.fromRGB(150, 40, 40)
	dStroke.Thickness = 1

	local dTitle = Instance.new("TextLabel", dangerCard)
	dTitle.Size = UDim2.new(1, -12, 0, 20)
	dTitle.Position = UDim2.new(0, 8, 0, 5)
	dTitle.BackgroundTransparency = 1
	dTitle.Text = "⚠ SCRIPT MANAGEMENT (EJECT)"
	dTitle.TextColor3 = Color3.fromRGB(255, 90, 90)
	dTitle.Font = Enum.Font.GothamBold
	dTitle.TextSize = 11
	dTitle.TextXAlignment = Enum.TextXAlignment.Left

	local unhookConfirm = false
	local unhookBtn = Instance.new("TextButton", dangerCard)
	unhookBtn.Size = UDim2.new(1, -16, 0, 32)
	unhookBtn.Position = UDim2.new(0, 8, 0, 28)
	unhookBtn.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
	unhookBtn.Text = "FORCE UNHOOK (Eject Script)"
	unhookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	unhookBtn.Font = Enum.Font.GothamBold
	unhookBtn.TextSize = 12
	rCorner(unhookBtn, 4)

	unhookBtn.MouseButton1Click:Connect(function()
		if not unhookConfirm then
			unhookConfirm = true
			unhookBtn.Text = "ARE YOU SURE? CLICK AGAIN"
			unhookBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
			task.delay(3, function() unhookConfirm = false; unhookBtn.Text = "FORCE UNHOOK (Eject Script)"; unhookBtn.BackgroundColor3 = Color3.fromRGB(150, 35, 35) end)
		else
			if Builders.MusicStop then Builders.MusicStop() end; if Builders.PaintStop then Builders.PaintStop() end; Config.Wanted_AutoBank = false; Config.Wanted_AutoATM = false; Config.Wanted_VehicleFly = false; Config.Wanted_Debug = false
			for _, c in pairs(Connections) do c:Disconnect() end; for _, t in pairs(Players:GetPlayers()) do cleanESP(t) end
			pcall(function() FOVCircle:Remove(); CrosshairX:Remove(); CrosshairY:Remove() end); for _, o in pairs(TargetAura.Cubes) do pcall(function() o.Part:Destroy() end) end
			for _, o in pairs(TargetAura.Atom) do pcall(function() o.Part:Destroy() end) end; for _, p in pairs(TargetAura.Crown) do pcall(function() p:Destroy() end) end
			pcall(function() TargetAura.Rhombus:Destroy(); TargetAura.Ring:Destroy() end); if aestheticBloom then aestheticBloom:Destroy() end; if aestheticCC then aestheticCC:Destroy() end
			if FreecamPart then FreecamPart:Destroy(); Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
			SpecFrame:Destroy(); SpecCamPart:Destroy()
			if Connections["SpecTracer"] then Connections["SpecTracer"]:Remove() end
			if player.Character then for _,p in pairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end; if player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed=16 end end
			Workspace.CurrentCamera.FieldOfView = 70; Lighting.Ambient = origAmbient or Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient = origOutdoorAmbient or Color3.fromRGB(127,127,127); Lighting.GlobalShadows = origGlobalShadows or true; Lighting.Brightness = origBrightness or 1; Lighting.ClockTime = origClockTime or 14; Workspace.Gravity = origGravity or 196.2
			local atmo = Lighting:FindFirstChildOfClass("Atmosphere"); if atmo then atmo.Density = 0.3 end; Lighting.FogColor = origFogColor or Color3.fromRGB(192, 192, 192); Lighting.FogEnd = origFogEnd or 100000; Lighting.FogStart = origFogStart or 0
			for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v:FindFirstChildOfClass("SelectionBox") then v:FindFirstChildOfClass("SelectionBox"):Destroy(); v.Transparency = originalTransparencies[v] or 0 end end
			if ModernFrame then ModernFrame:Destroy() end
			if PopupFrame then PopupFrame:Destroy() end
			for _, df in pairs(DropdownFrames) do df:Destroy() end
			DropdownFrames = {}
			ScreenGui:Destroy()
		end
	end)
end

do

Config.Music_Text = Config.Music_Text or ""
Config.Music_Delay = Config.Music_Delay or 0.12
Config.Music_Speed = Config.Music_Speed or 1
Config.Music_StartDelay = Config.Music_StartDelay or 3
Config.Music_Hold = Config.Music_Hold or 0.04
Config.Music_Loop = Config.Music_Loop or false

local MusicState = { Playing = false, Paused = false, Token = 0, Status = "Idle", Labels = {} }

local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local DigitNames = {
	["0"] = "Zero", ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four",
	["5"] = "Five", ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine"
}
local ShiftDigits = {
	["!"] = "1", ["@"] = "2", ["#"] = "3", ["$"] = "4", ["%"] = "5",
	["^"] = "6", ["&"] = "7", ["*"] = "8", ["("] = "9", [")"] = "0"
}

local function setMusicStatus(text)
	MusicState.Status = text
	for i, lbl in pairs(MusicState.Labels) do
		if lbl and lbl.Parent then
			pcall(function() lbl.Text = "[MUSIC] " .. text end)
		else
			MusicState.Labels[i] = nil
		end
	end
end

local function sendKey(code, down)
	pcall(function()
		if VIM then VIM:SendKeyEvent(down, code, false, game) end
	end)
end

local function noteFromChar(ch)
	local d = ShiftDigits[ch]
	if d then return Enum.KeyCode[DigitNames[d]], true end
	if DigitNames[ch] then return Enum.KeyCode[DigitNames[ch]], false end
	if ch:match("^%a$") then
		return Enum.KeyCode[ch:upper()], ch:match("^%u$") ~= nil
	end
	return nil, false
end

local function parseSong(text)
	local tokens = {}
	local i, n = 1, #text
	while i <= n do
		local ch = text:sub(i, i)
		if ch == "[" then
			local j = text:find("]", i + 1, true)
			local inner = text:sub(i + 1, (j or (n + 1)) - 1)
			local notes = {}
			for k = 1, #inner do
				local code, sh = noteFromChar(inner:sub(k, k))
				if code then table.insert(notes, { code = code, shift = sh }) end
			end
			if #notes > 0 then table.insert(tokens, { t = "n", notes = notes }) end
			i = (j or n) + 1
		else
			local code, sh = noteFromChar(ch)
			if code then
				table.insert(tokens, { t = "n", notes = { { code = code, shift = sh } } })
			elseif ch == " " or ch == "-" then
				table.insert(tokens, { t = "w", mult = 1 })
			elseif ch == "|" or ch == "\n" then
				table.insert(tokens, { t = "w", mult = 2 })
			end
			i = i + 1
		end
	end
	return tokens
end

local function playNotes(notes, hold)
	local plain, shifted = {}, {}
	for _, nt in ipairs(notes) do
		if nt.shift then table.insert(shifted, nt.code) else table.insert(plain, nt.code) end
	end
	for _, c in ipairs(plain) do sendKey(c, true) end
	if #shifted > 0 then
		sendKey(Enum.KeyCode.LeftShift, true)
		for _, c in ipairs(shifted) do sendKey(c, true) end
	end
	task.wait(hold)
	for _, c in ipairs(shifted) do sendKey(c, false) end
	if #shifted > 0 then sendKey(Enum.KeyCode.LeftShift, false) end
	for _, c in ipairs(plain) do sendKey(c, false) end
end

local function stopMusic()
	MusicState.Token = MusicState.Token + 1
	MusicState.Playing = false
	MusicState.Paused = false
	sendKey(Enum.KeyCode.LeftShift, false)
	setMusicStatus("Stopped")
end

local function startMusic()
	if not VIM then setMusicStatus("VirtualInputManager недоступен в этом executor!"); return end
	local tokens = parseSong(Config.Music_Text or "")
	if #tokens == 0 then setMusicStatus("Текст пустой — вставь ноты!"); return end

	MusicState.Token = MusicState.Token + 1
	local token = MusicState.Token
	MusicState.Playing = true
	MusicState.Paused = false

	task.spawn(function()
		for s = math.floor(Config.Music_StartDelay or 3), 1, -1 do
			setMusicStatus("Старт через " .. s .. "с... кликни на пианино")
			task.wait(1)
			if token ~= MusicState.Token then return end
		end

		repeat
			for idx, tk in ipairs(tokens) do
				while MusicState.Paused and token == MusicState.Token do task.wait(0.1) end
				if token ~= MusicState.Token then return end

				local unit = math.max(0.01, (Config.Music_Delay or 0.12) / math.max(0.05, Config.Music_Speed or 1))
				if tk.t == "n" then
					playNotes(tk.notes, math.min(Config.Music_Hold or 0.04, unit * 0.8))
					task.wait(unit)
				else
					task.wait(unit * tk.mult)
				end
				if idx % 6 == 0 then
					setMusicStatus(string.format("Играет %d/%d", idx, #tokens))
				end
			end
		until (not Config.Music_Loop) or token ~= MusicState.Token

		if token == MusicState.Token then
			MusicState.Playing = false
			setMusicStatus("Готово!")
		end
	end)
end

Builders.MusicStop = function() stopMusic() end

Builders.Music = function(parent)
	parent = parent or SettingsFrame
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local btnW = isModern and 690 or (dropW or (parent == SettingsFrame and 450 or 180))

	local statLbl = Instance.new("TextLabel", parent)
	statLbl.Size = UDim2.new(0, btnW, 0, 26)
	statLbl.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	statLbl.BackgroundTransparency = 0.2
	statLbl.Text = "[MUSIC] " .. MusicState.Status
	statLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
	statLbl.Font = Enum.Font.GothamBold
	statLbl.TextSize = 11
	statLbl.TextTruncate = Enum.TextTruncate.AtEnd
	rCorner(statLbl, 6)
	table.insert(MusicState.Labels, statLbl)

	local songBox = Instance.new("TextBox", parent)
	songBox.Size = UDim2.new(0, btnW, 0, 130)
	songBox.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
	songBox.BackgroundTransparency = 0.1
	songBox.TextColor3 = Color3.fromRGB(240, 240, 255)
	songBox.PlaceholderText = "Вставь ноты сюда. Пример: [qe] w [qr] t | y u i o"
	songBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 155)
	songBox.Font = Enum.Font.Code
	songBox.TextSize = 13
	songBox.TextXAlignment = Enum.TextXAlignment.Left
	songBox.TextYAlignment = Enum.TextYAlignment.Top
	songBox.TextWrapped = true
	songBox.MultiLine = true
	songBox.ClearTextOnFocus = false
	songBox.Text = Config.Music_Text or ""
	rCorner(songBox, 6)
	local sbStroke = Instance.new("UIStroke", songBox)
	sbStroke.Color = Color3.fromRGB(60, 60, 85); sbStroke.Thickness = 1
	local sbPad = Instance.new("UIPadding", songBox)
	sbPad.PaddingTop = UDim.new(0, 6); sbPad.PaddingLeft = UDim.new(0, 8); sbPad.PaddingRight = UDim.new(0, 8)
	songBox.FocusLost:Connect(function() Config.Music_Text = songBox.Text end)
	songBox:GetPropertyChangedSignal("Text"):Connect(function() Config.Music_Text = songBox.Text end)

	createButton(parent, "▶ Start", btnW, function()
		Config.Music_Text = songBox.Text
		startMusic()
	end)
	createButton(parent, "⏸ Pause / Resume", btnW, function(b)
		if MusicState.Playing then
			MusicState.Paused = not MusicState.Paused
			setMusicStatus(MusicState.Paused and "Пауза" or "Продолжаю...")
		end
	end)
	createButton(parent, "⏹ Stop", btnW, function() stopMusic() end)

	createTextBox(parent, "Speed (x)", tostring(Config.Music_Speed), function(v)
		Config.Music_Speed = clamp(tonumber(v) or 1, 0.1, 10)
	end)
	createTextBox(parent, "Note Delay (s)", tostring(Config.Music_Delay), function(v)
		Config.Music_Delay = clamp(tonumber(v) or 0.12, 0.02, 2)
	end)
	createTextBox(parent, "Key Hold (s)", tostring(Config.Music_Hold), function(v)
		Config.Music_Hold = clamp(tonumber(v) or 0.04, 0.01, 0.5)
	end)
	createTextBox(parent, "Start Delay (s)", tostring(Config.Music_StartDelay), function(v)
		Config.Music_StartDelay = clamp(tonumber(v) or 3, 0, 15)
	end)
	addToggle(parent, "Loop Song", "Music_Loop")

	createButton(parent, "Test: Scale (1-0 q-p)", btnW, function()
		songBox.Text = "1234567890qwertyuiop"
		Config.Music_Text = songBox.Text
	end)
	createButton(parent, "Clear Text", btnW, function()
		songBox.Text = ""
		Config.Music_Text = ""
	end)

	local help = Instance.new("TextLabel", parent)
	help.Size = UDim2.new(0, btnW, 0, 78)
	help.BackgroundTransparency = 1
	help.TextColor3 = Color3.fromRGB(160, 165, 185)
	help.Font = Enum.Font.Gotham
	help.TextSize = 11
	help.TextWrapped = true
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextYAlignment = Enum.TextYAlignment.Top
	help.Text = "Формат: буквы/цифры = ноты (как на клавишах пианино)\nЗаглавные и ! @ $ % ^ * ( = диезы (Shift)\n[asd] = аккорд (одновременно)\nПробел или - = пауза, | и новая строка = длинная пауза"
end

end

do

local PaintState = {
	Running = false,
	Paused = false,
	Token = 0,
	Status = "Готов. Выберите или укажите путь к картинке.",
	Progress = 0,
	CompletedStrokes = 0,
	TotalStrokes = 0,
	CurrentColorIdx = 0,
	TotalColors = 0,
	Labels = {},
	ProgressBarFills = {},
	SelectedCanvas = nil,
	CanvasHighlight = nil,
	LoadedImage = nil,
	LoadedImageName = "",
	OrigCamCFrame = nil,
	OrigCamType = nil
}

local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function setPaintStatus(text, progress)
	PaintState.Status = text
	if progress then PaintState.Progress = clamp(progress, 0, 1) end
	for i, lbl in pairs(PaintState.Labels) do
		if lbl and lbl.Parent then
			pcall(function() lbl.Text = "[PAINT] " .. text end)
		else
			PaintState.Labels[i] = nil
		end
	end
	for i, bar in pairs(PaintState.ProgressBarFills) do
		if bar and bar.Parent then
			pcall(function()
				bar.Size = UDim2.new(PaintState.Progress, 0, 1, 0)
			end)
		else
			PaintState.ProgressBarFills[i] = nil
		end
	end
end

local function findCanvasPart()
	if PaintState.SelectedCanvas and PaintState.SelectedCanvas.Parent then
		return PaintState.SelectedCanvas
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local res = Workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), rayParams)
		if res and res.Instance and res.Instance:IsA("BasePart") then
			local sz = res.Instance.Size
			if (sz.X >= 10 and sz.Z >= 10) or res.Instance.Name:lower():find("canvas") or res.Instance.Name:lower():find("холст") or res.Instance.Name:lower():find("draw") then
				PaintState.SelectedCanvas = res.Instance
				return res.Instance
			end
		end
	end

	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local n = obj.Name:lower()
			if n == "canvas" or n == "холст" or n:find("canvaspart") or n:find("drawpart") or n:find("drawingboard") or n:find("paintboard") then
				PaintState.SelectedCanvas = obj
				return obj
			end
		end
	end

	if hrp then
		local bestPart, bestDist = nil, math.huge
		for _, obj in pairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and not obj:FindFirstAncestorOfClass("Player") and not obj.Parent:FindFirstChild("Humanoid") then
				local sz = obj.Size
				if sz.X >= 16 and sz.Z >= 16 and sz.Y <= 5 then
					local d = (obj.Position - hrp.Position).Magnitude
					if d < 120 and d < bestDist then
						bestDist = d
						bestPart = obj
					end
				end
			end
		end
		if bestPart then
			PaintState.SelectedCanvas = bestPart
			return bestPart
		end
	end

	return nil
end

local function highlightCanvas(part)
	if not part then return end
	if PaintState.CanvasHighlight then
		pcall(function() PaintState.CanvasHighlight:Destroy() end)
		PaintState.CanvasHighlight = nil
	end
	local hl = Instance.new("Highlight")
	hl.Name = "CanvasHighlight"
	hl.Adornee = part
	hl.FillColor = ActiveTheme.Accent
	hl.FillTransparency = 0.8
	hl.OutlineColor = ActiveTheme.Accent
	hl.OutlineTransparency = 0.1
	hl.Parent = part
	PaintState.CanvasHighlight = hl
	task.delay(4, function()
		if PaintState.CanvasHighlight == hl then
			TweenService:Create(hl, TweenInfo.new(1), {FillTransparency = 1, OutlineTransparency = 1}):Play()
			task.delay(1, function() hl:Destroy() end)
		end
	end)
end

local function getCanvasInfo(part)
	if not part then
		return 90, 90, Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), 0.2
	end
	local cf = part.CFrame
	local sz = part.Size

	local faces = {
		{ n = cf.LookVector,   w = sz.X, h = sz.Y, t = sz.Z },
		{ n = -cf.LookVector,  w = sz.X, h = sz.Y, t = sz.Z },
		{ n = cf.RightVector,  w = sz.Z, h = sz.Y, t = sz.X },
		{ n = -cf.RightVector, w = sz.Z, h = sz.Y, t = sz.X },
		{ n = cf.UpVector,     w = sz.X, h = sz.Z, t = sz.Y },
		{ n = -cf.UpVector,    w = sz.X, h = sz.Z, t = sz.Y },
	}
	local best = faces[1]
	for i = 2, #faces do
		local f = faces[i]
		if f.w * f.h > best.w * best.h then best = f end
	end

	local normal = best.n
	pcall(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and (normal:Dot(hrp.Position - part.Position)) < 0 then
			normal = -normal
		end
	end)

	local cam = Workspace.CurrentCamera
	local camRight = (cam and cam.CFrame.RightVector) or Vector3.xAxis
	local camDown = -(cam and cam.CFrame.UpVector or Vector3.yAxis)

	local function projectToPlane(v)
		local p = v - normal * normal:Dot(v)
		if p.Magnitude < 1e-4 then return nil end
		return p.Unit
	end

	local rightV = projectToPlane(camRight) or projectToPlane(Vector3.xAxis) or Vector3.zAxis
	local downV = projectToPlane(camDown)
	if not downV then downV = normal:Cross(rightV) end
	downV = downV - rightV * rightV:Dot(downV)
	if downV.Magnitude < 1e-4 then
		downV = normal:Cross(rightV)
	else
		downV = downV.Unit
	end
	if downV:Dot(camDown) < 0 then downV = -downV end
	if rightV:Dot(projectToPlane(camRight) or rightV) < 0 then rightV = -rightV end

	local function axisExtent(axisVec)
		return math.abs(sz.X * cf.RightVector:Dot(axisVec))
			+ math.abs(sz.Y * cf.UpVector:Dot(axisVec))
			+ math.abs(sz.Z * cf.LookVector:Dot(axisVec))
	end
	local eR, eD = axisExtent(rightV), axisExtent(downV)
	if eD > eR then
		rightV, downV = downV, -rightV
		eR, eD = eD, eR
	end

	local surfW = math.max(eR, 1)
	local surfH = math.max(eD, 1)
	local thickness = math.max(best.t, 0.05)

	return surfW, surfH, normal, rightV, downV, thickness
end

local function equipBrushTool()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChild("Humanoid")

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local n = item.Name:lower()
			if n:find("brush") or n:find("кист") or n:find("paint") or n:find("draw") then
				return item
			end
		end
	end

	local bp = player:FindFirstChild("Backpack")
	if bp and hum then
		for _, item in ipairs(bp:GetChildren()) do
			if item:IsA("Tool") then
				local n = item.Name:lower()
				if n:find("brush") or n:find("кист") or n:find("paint") or n:find("draw") then
					hum:EquipTool(item)
					task.wait(0.15)
					return item
				end
			end
		end
		local allTools = bp:GetChildren()
		if #allTools > 0 then
			local lastTool = allTools[#allTools]
			if lastTool:IsA("Tool") then
				hum:EquipTool(lastTool)
				task.wait(0.15)
				return lastTool
			end
		end
	end
	return nil
end

local function setInGameColor(c3)
	local r = clamp(math.floor(c3.R * 255), 0, 255)
	local g = clamp(math.floor(c3.G * 255), 0, 255)
	local b = clamp(math.floor(c3.B * 255), 0, 255)
	local hex = string.format("%02X%02X%02X", r, g, b)

	pcall(function()
		local pg = player:FindFirstChild("PlayerGui")
		if pg then
			for _, desc in ipairs(pg:GetDescendants()) do
				if desc:IsA("TextBox") then
					local cleanText = desc.Text:gsub("#", ""):gsub("%s", "")
					if (#cleanText == 6 and cleanText:match("^%x%x%x%x%x%x$")) or desc.Name:lower():find("hex") or (desc.PlaceholderText and desc.PlaceholderText:lower():find("hex")) then
						desc.Text = hex
						pcall(function() desc:CaptureFocus(); desc:ReleaseFocus(true) end)
					end
				end
			end
		end
	end)

	pcall(function()
		local tool = equipBrushTool()
		local checkRemotes = {}
		if tool then
			for _, v in ipairs(tool:GetDescendants()) do if v:IsA("RemoteEvent") then table.insert(checkRemotes, v) end end
		end
		local rs = game:GetService("ReplicatedStorage")
		for _, v in ipairs(rs:GetDescendants()) do
			if v:IsA("RemoteEvent") then
				local n = v.Name:lower()
				if n:find("color") or n:find("palette") or n:find("brushcolor") then
					table.insert(checkRemotes, v)
				end
			end
		end
		for _, rem in ipairs(checkRemotes) do
			pcall(function() rem:FireServer(c3) end)
			pcall(function() rem:FireServer(hex) end)
			pcall(function() rem:FireServer("Color", c3) end)
		end
	end)
end

local function clearInGameCanvas()
	local found = false
	pcall(function()
		local pg = player:FindFirstChild("PlayerGui")
		if pg then
			for _, desc in ipairs(pg:GetDescendants()) do
				if desc:IsA("TextButton") then
					local t = desc.Text:lower()
					if t:find("стереть") or t:find("очистить") or t:find("clear") or t:find("erase all") then
						found = true
						if firesignal then
							firesignal(desc.MouseButton1Click)
							firesignal(desc.Activated)
						else
							desc.MouseButton1Click:Fire()
						end
					end
				end
			end
		end
	end)

	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		for _, v in ipairs(rs:GetDescendants()) do
			if v:IsA("RemoteEvent") then
				local n = v.Name:lower()
				if n:find("clear") or n:find("erase") or n:find("resetcanvas") then
					v:FireServer()
					found = true
				end
			end
		end
	end)

	if found then
		PaintState.CompletedStrokes = 0
		setPaintStatus("Холст очищен.", 0)
		if showNotification then showNotification("Paint Bot", "Холст очищен!", 2, Color3.fromRGB(0, 220, 255)) end
	else
		if showNotification then showNotification("Paint Bot", "Кнопка очистки не найдена в UI.", 2, Color3.fromRGB(255, 120, 120)) end
	end
end


local function decodeBMP(raw)
	if #raw < 54 then return nil, "Файл слишком мал для BMP" end
	if raw:sub(1, 2) ~= "BM" then return nil, "Не является файлом BMP" end

	local function r32(offset)
		local b1, b2, b3, b4 = string.byte(raw, offset, offset + 3)
		return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
	end
	local function r16(offset)
		local b1, b2 = string.byte(raw, offset, offset + 1)
		return b1 + b2 * 256
	end

	local dataOffset = r32(11)
	local width = r32(19)
	local height = r32(23)
	local bpp = r16(29)

	if bpp ~= 24 and bpp ~= 32 then
		return nil, "Поддерживаются только 24-bit и 32-bit BMP (данный файл: " .. tostring(bpp) .. "-bit)"
	end

	local isFlipped = height > 0
	height = math.abs(height)
	local rowSize = math.floor((bpp * width + 31) / 32) * 4
	local bytesPerPixel = bpp / 8

	local img = {
		Width = width,
		Height = height,
		GetPixel = function(self, x, y)
			x = clamp(x, 1, width)
			y = clamp(y, 1, height)
			local rowY = isFlipped and (height - y) or (y - 1)
			local pos = dataOffset + rowY * rowSize + (x - 1) * bytesPerPixel + 1
			if pos + 2 > #raw then return Color3.new(1, 1, 1), 1 end
			local b, g, r = string.byte(raw, pos, pos + 2)
			local a = (bpp == 32 and (pos + 3 <= #raw)) and (string.byte(raw, pos + 3) / 255) or 1
			return Color3.fromRGB(r, g, b), a
		end
	}
	return img
end


local function decodePNG(data)
	if not data or #data < 8 then return nil, "Файл слишком мал для PNG" end
	local b1,b2,b3,b4,b5,b6,b7,b8 = string.byte(data, 1, 8)
if not (b1 == 137 and b2 == 80 and b3 == 78 and b4 == 71 and b5 == 13 and b6 == 10 and b7 == 26 and b8 == 10) then
return nil, string.format("Не PNG (сигнатура: %d %d %d %d %d %d %d %d)", b1 or 0, b2 or 0, b3 or 0, b4 or 0, b5 or 0, b6 or 0, b7 or 0, b8 or 0)
end

	local _b = bit32 or bit or {}
	local band = _b.band or function(a, b)
		local res, p = 0, 1
		while a > 0 and b > 0 do
			local ra, rb = a % 2, b % 2
			if ra == 1 and rb == 1 then res = res + p end
			a = math.floor(a / 2); b = math.floor(b / 2); p = p * 2
		end
		return res
	end
	local bor = _b.bor or function(a, b)
		local res, p = 0, 1
		while a > 0 or b > 0 do
			local ra, rb = a % 2, b % 2
			if ra == 1 or rb == 1 then res = res + p end
			a = math.floor(a / 2); b = math.floor(b / 2); p = p * 2
		end
		return res
	end
	local lshift = _b.lshift or function(a, n)
		return math.floor(a * (2 ^ n)) % 4294967296
	end
	local rshift = _b.rshift or function(a, n)
		return math.floor(a / (2 ^ n))
	end

	local function r32BE(str, pos)
		local b1, b2, b3, b4 = string.byte(str, pos, pos + 3)
		return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
	end

	local pos = 9
	local dataLen = #data
	local ihdr = nil
	local idatChunks = {}
	local plte = nil
	local trns = nil

	while pos + 8 <= dataLen do
		local chunkLen = r32BE(data, pos)
		pos = pos + 4
		local chunkType = data:sub(pos, pos + 3)
		pos = pos + 4

		local chunkData = ""
		if chunkLen > 0 then
			local endPos = math.min(dataLen, pos + chunkLen - 1)
			chunkData = data:sub(pos, endPos)
			pos = pos + chunkLen
		end
		pos = pos + 4

		if chunkType == "IHDR" and #chunkData >= 13 then
			ihdr = {
				width = r32BE(chunkData, 1),
				height = r32BE(chunkData, 5),
				bitDepth = string.byte(chunkData, 9),
				colorType = string.byte(chunkData, 10),
				compression = string.byte(chunkData, 11),
				filter = string.byte(chunkData, 12),
				interlace = string.byte(chunkData, 13)
			}
		elseif chunkType == "IDAT" then
			table.insert(idatChunks, chunkData)
		elseif chunkType == "PLTE" then
			plte = chunkData
		elseif chunkType == "tRNS" then
			trns = chunkData
		elseif chunkType == "IEND" then
			break
		end
	end

	if not ihdr then return nil, "Чанк IHDR не найден в PNG" end
	if #idatChunks == 0 then return nil, "Данные IDAT отсутствуют в PNG" end

	local compressed = table.concat(idatChunks)

	local function makeBitReader(str, startByte)
		local bytePos = startByte or 1
		local bitBuf = 0
		local bitCount = 0
		local sLen = #str

		local function getBits(n)
			if n == 0 then return 0 end
			while bitCount < n do
				if bytePos <= sLen then
					local b = string.byte(str, bytePos)
					bytePos = bytePos + 1
					bitBuf = bor(bitBuf, lshift(b, bitCount))
					bitCount = bitCount + 8
				else
					break
				end
			end
			local mask = lshift(1, n) - 1
			local val = band(bitBuf, mask)
			bitBuf = rshift(bitBuf, n)
			bitCount = math.max(0, bitCount - n)
			return val
		end

		local function getBit()
			return getBits(1)
		end

		local function alignToByte()
			local drop = bitCount % 8
			if drop > 0 then
				getBits(drop)
			end
		end

		return {
			getBit = getBit,
			getBits = getBits,
			alignToByte = alignToByte
		}
	end

	local function buildHuffmanTree(lengths, maxSym)
		local bl_count = {}
		local maxBits = 0
		for sym = 0, maxSym do
			local l = lengths[sym]
			if l and l > 0 then
				bl_count[l] = (bl_count[l] or 0) + 1
				if l > maxBits then maxBits = l end
			end
		end
		if maxBits == 0 then return {} end

		local code = 0
		local next_code = {}
		for bits = 1, maxBits do
			code = lshift(code + (bl_count[bits - 1] or 0), 1)
			next_code[bits] = code
		end

		local root = {}
		for sym = 0, maxSym do
			local l = lengths[sym]
			if l and l > 0 then
				local c = next_code[l]
				next_code[l] = c + 1
				local node = root
				for i = l - 1, 0, -1 do
					local b = band(rshift(c, i), 1)
					if i == 0 then
						node[b] = sym
					else
						if not node[b] or type(node[b]) ~= "table" then
							node[b] = {}
						end
						node = node[b]
					end
				end
			end
		end
		if maxBits == 1 and (bl_count[1] or 0) == 1 then
			root[0] = root[0] or root[1]
			root[1] = root[1] or root[0]
		end
		return root
	end

	local function decodeSymbol(reader, tree)
		local node = tree
		while type(node) == "table" do
			local b = reader.getBit()
			node = node[b]
			if node == nil then return nil, "Поврежденные коды Хаффмана" end
		end
		return node
	end

	local LENGTH_BASE = {
		[257]=3, [258]=4, [259]=5, [260]=6, [261]=7, [262]=8, [263]=9, [264]=10,
		[265]=11, [266]=13, [267]=15, [268]=17, [269]=19, [270]=23, [271]=27, [272]=31,
		[273]=35, [274]=43, [275]=51, [276]=59, [277]=67, [278]=83, [279]=99, [280]=115,
		[281]=131, [282]=163, [283]=195, [284]=227, [285]=258
	}
	local LENGTH_EXTRA = {
		[257]=0, [258]=0, [259]=0, [260]=0, [261]=0, [262]=0, [263]=0, [264]=0,
		[265]=1, [266]=1, [267]=1, [268]=1, [269]=2, [270]=2, [271]=2, [272]=2,
		[273]=3, [274]=3, [275]=3, [276]=3, [277]=4, [278]=4, [279]=4, [280]=4,
		[281]=5, [282]=5, [283]=5, [284]=5, [285]=0
	}
	local DIST_BASE = {
		[0]=1, [1]=2, [2]=3, [3]=4, [4]=5, [5]=7, [6]=9, [7]=13,
		[8]=17, [9]=25, [10]=33, [11]=49, [12]=65, [13]=97, [14]=129, [15]=193,
		[16]=257, [17]=385, [18]=513, [19]=769, [20]=1025, [21]=1537, [22]=2049, [23]=3073,
		[24]=4097, [25]=6145, [26]=8193, [27]=12289, [28]=16385, [29]=24577
	}
	local DIST_EXTRA = {
		[0]=0, [1]=0, [2]=0, [3]=0, [4]=1, [5]=1, [6]=2, [7]=2,
		[8]=3, [9]=3, [10]=4, [11]=4, [12]=5, [13]=5, [14]=6, [15]=6,
		[16]=7, [17]=7, [18]=8, [19]=8, [20]=9, [21]=9, [22]=10, [23]=10,
		[24]=11, [25]=11, [26]=12, [27]=12, [28]=13, [29]=13
	}
	local CL_ORDER = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}

	local fixedLitLengths = {}
	for i = 0, 143 do fixedLitLengths[i] = 8 end
	for i = 144, 255 do fixedLitLengths[i] = 9 end
	for i = 256, 279 do fixedLitLengths[i] = 7 end
	for i = 280, 287 do fixedLitLengths[i] = 8 end
	local fixedLitTree = buildHuffmanTree(fixedLitLengths, 287)

	local fixedDistLengths = {}
	for i = 0, 31 do fixedDistLengths[i] = 5 end
	local fixedDistTree = buildHuffmanTree(fixedDistLengths, 31)

	local function inflateZlib(zData)
		local okNative, resNative = pcall(function()
			if syn and syn.crypt and syn.crypt.custom and syn.crypt.custom.inflate then
				return syn.crypt.custom.inflate(zData)
			elseif crypt and crypt.custom and crypt.custom.inflate then
				return crypt.custom.inflate(zData)
			elseif zlib and zlib.decompress then
				return zlib.decompress(zData)
			end
			return nil
		end)
		if okNative and resNative and type(resNative) == "string" and #resNative > 0 then
			local t = {}
			for i = 1, #resNative do t[i] = string.byte(resNative, i) end
			return t
		end

		if #zData < 6 then return nil, "Слишком короткий поток zlib" end
		local flg = string.byte(zData, 2)
		local startByte = (band(flg, 32) ~= 0) and 7 or 3

		local reader = makeBitReader(zData, startByte)
		local out = {}
		local outLen = 0

		while true do
			local bfinal = reader.getBit()
			local btype = reader.getBits(2)

			if btype == 0 then
				reader.alignToByte()
				local len = reader.getBits(16)
				local _nlen = reader.getBits(16)
				for _ = 1, len do
					outLen = outLen + 1
					out[outLen] = reader.getBits(8)
				end
			elseif btype == 1 or btype == 2 then
				local litTree, distTree
				if btype == 1 then
					litTree = fixedLitTree
					distTree = fixedDistTree
				else
					local hlit = reader.getBits(5) + 257
					local hdist = reader.getBits(5) + 1
					local hclen = reader.getBits(4) + 4

					local clLengths = {}
					for i = 1, hclen do
						clLengths[CL_ORDER[i]] = reader.getBits(3)
					end
					local clTree = buildHuffmanTree(clLengths, 18)

					local allLengths = {}
					local total = hlit + hdist
					local idx = 0
					while idx < total do
						local sym, err = decodeSymbol(reader, clTree)
						if not sym then return nil, err end
						if sym < 16 then
							allLengths[idx] = sym
							idx = idx + 1
						elseif sym == 16 then
							local prev = allLengths[idx - 1] or 0
							local rep = 3 + reader.getBits(2)
							for _ = 1, rep do
								allLengths[idx] = prev
								idx = idx + 1
							end
						elseif sym == 17 then
							local rep = 3 + reader.getBits(3)
							for _ = 1, rep do
								allLengths[idx] = 0
								idx = idx + 1
							end
						elseif sym == 18 then
							local rep = 11 + reader.getBits(7)
							for _ = 1, rep do
								allLengths[idx] = 0
								idx = idx + 1
							end
						end
					end

					local litLengths = {}
					for i = 0, hlit - 1 do litLengths[i] = allLengths[i] or 0 end
					local distLengths = {}
					for i = 0, hdist - 1 do distLengths[i] = allLengths[hlit + i] or 0 end

					litTree = buildHuffmanTree(litLengths, hlit - 1)
					distTree = buildHuffmanTree(distLengths, hdist - 1)
				end

				while true do
					local sym, err = decodeSymbol(reader, litTree)
					if not sym then return nil, err end

					if sym < 256 then
						outLen = outLen + 1
						out[outLen] = sym
					elseif sym == 256 then
						break
					else
						local length = LENGTH_BASE[sym] + ((LENGTH_EXTRA[sym] or 0) > 0 and reader.getBits(LENGTH_EXTRA[sym]) or 0)
						local distSym, distErr = decodeSymbol(reader, distTree)
						if not distSym then return nil, distErr end
						local dist = DIST_BASE[distSym] + ((DIST_EXTRA[distSym] or 0) > 0 and reader.getBits(DIST_EXTRA[distSym]) or 0)

						local srcPos = outLen - dist + 1
						for _ = 1, length do
							outLen = outLen + 1
							out[outLen] = out[srcPos]
							srcPos = srcPos + 1
						end
					end
				end
			else
				return nil, "Неподдерживаемый тип блока Deflate: " .. tostring(btype)
			end

			if bfinal == 1 then break end
		end

		return out
	end

	local rawBytes, inflateErr = inflateZlib(compressed)
	if not rawBytes then
		return nil, "Ошибка декомпрессии PNG (Deflate): " .. tostring(inflateErr)
	end

	local width = ihdr.width
	local height = ihdr.height
	local colorType = ihdr.colorType
	local bitDepth = ihdr.bitDepth

	local channelsMap = { [0] = 1, [2] = 3, [3] = 1, [4] = 2, [6] = 4 }
	local channels = channelsMap[colorType] or 3
	local bpp = math.max(1, math.floor(channels * bitDepth / 8))
	local stride = math.ceil(width * channels * bitDepth / 8)

	local rows = {}
	local prevRow = nil
	local rawPos = 1

	for y = 1, height do
		if rawPos > #rawBytes then break end
		local filterType = rawBytes[rawPos]
		rawPos = rawPos + 1

		local currRow = {}
		for x = 1, stride do
			local rawByte = rawBytes[rawPos] or 0
			rawPos = rawPos + 1

			local a = (x > bpp) and currRow[x - bpp] or 0
			local b = prevRow and prevRow[x] or 0
			local c = (prevRow and x > bpp) and prevRow[x - bpp] or 0

			local val
			if filterType == 0 then
				val = rawByte
			elseif filterType == 1 then
				val = (rawByte + a) % 256
			elseif filterType == 2 then
				val = (rawByte + b) % 256
			elseif filterType == 3 then
				val = (rawByte + math.floor((a + b) / 2)) % 256
			elseif filterType == 4 then
				local p = a + b - c
				local pa = math.abs(p - a)
				local pb = math.abs(p - b)
				local pc = math.abs(p - c)
				local pr = (pa <= pb and pa <= pc) and a or ((pb <= pc) and b or c)
				val = (rawByte + pr) % 256
			else
				val = rawByte
			end
			currRow[x] = val
		end
		rows[y] = currRow
		prevRow = currRow
	end

	local img = {
		Width = width,
		Height = height,
		GetPixel = function(self, x, y)
			x = clamp(x, 1, width)
			y = clamp(y, 1, height)
			local row = rows[y]
			if not row then return Color3.new(0, 0, 0), 0 end

			if colorType == 2 then
				if bitDepth == 8 then
					local idx = (x - 1) * 3 + 1
					local r = row[idx] or 0
					local g = row[idx + 1] or 0
					local b = row[idx + 2] or 0
					return Color3.fromRGB(r, g, b), 1
				else
					local idx = (x - 1) * 6 + 1
					return Color3.fromRGB(row[idx] or 0, row[idx + 2] or 0, row[idx + 4] or 0), 1
				end
			elseif colorType == 6 then
				if bitDepth == 8 then
					local idx = (x - 1) * 4 + 1
					local r = row[idx] or 0
					local g = row[idx + 1] or 0
					local b = row[idx + 2] or 0
					local a = (row[idx + 3] or 255) / 255
					return Color3.fromRGB(r, g, b), a
				else
					local idx = (x - 1) * 8 + 1
					local a = (row[idx + 6] or 255) / 255
					return Color3.fromRGB(row[idx] or 0, row[idx + 2] or 0, row[idx + 4] or 0), a
				end
			elseif colorType == 3 then
				local palIdx = 0
				if bitDepth == 8 then
					palIdx = row[x] or 0
				elseif bitDepth == 4 then
					local byteIdx = math.floor((x - 1) / 2) + 1
					local b = row[byteIdx] or 0
					palIdx = ((x - 1) % 2 == 0) and rshift(b, 4) or band(b, 15)
				elseif bitDepth == 1 then
					local byteIdx = math.floor((x - 1) / 8) + 1
					local b = row[byteIdx] or 0
					local bitOff = 7 - ((x - 1) % 8)
					palIdx = band(rshift(b, bitOff), 1)
				else
					palIdx = row[x] or 0
				end

				local r, g, b = 0, 0, 0
				if plte then
					local pPos = palIdx * 3 + 1
					r = string.byte(plte, pPos) or 0
					g = string.byte(plte, pPos + 1) or 0
					b = string.byte(plte, pPos + 2) or 0
				end
				local a = 1
				if trns and #trns > palIdx then
					a = (string.byte(trns, palIdx + 1) or 255) / 255
				end
				return Color3.fromRGB(r, g, b), a
			elseif colorType == 0 then
				local v = row[x] or 0
				return Color3.fromRGB(v, v, v), 1
			elseif colorType == 4 then
				local idx = (x - 1) * 2 + 1
				local v = row[idx] or 0
				local a = (row[idx + 1] or 255) / 255
				return Color3.fromRGB(v, v, v), a
			end

			return Color3.new(1, 1, 1), 1
		end
	}

	return img
end

local function decodeImage(data, filename)
	if not data or #data == 0 then
		return nil, "Файл пуст (0 байт)"
	end

	if data:sub(1, 2) == "BM" then
		return decodeBMP(data)
	end

	local ok, imgOrErr = pcall(function()
		return decodePNG(data)
	end)
	if ok and imgOrErr and type(imgOrErr) == "table" and imgOrErr.Width and imgOrErr.Height and imgOrErr.GetPixel then
		return imgOrErr
	end

	if _G.RichPNGDecoder and _G.RichPNGDecoder.new then
		local ok2, img2 = pcall(function()
			return _G.RichPNGDecoder.new(data)
		end)
		if ok2 and img2 and img2.Width and img2.Height and img2.GetPixel then
			return img2
		end
	end

	local errReason = tostring(imgOrErr or "неверный или поврежденный формат PNG")
	warn("[RICH PAINT] Ошибка декодирования:", errReason, "| Файл:", tostring(filename), "| Размер:", #data, "байт")
return nil, "Ошибка декодирования PNG: " .. errReason .. ". Вы также можете сохранить картинку как 24-bit .BMP в Paint (BMP поддерживается 100% оффлайн)."
end

local function fetchImageData(pathOrUrl)
	if not pathOrUrl or type(pathOrUrl) ~= "string" then return nil, "Путь не указан" end
	local rawInput = pathOrUrl:gsub('^%s+', ''):gsub('%s+$', ''):gsub('^["\']', ''):gsub('["\']$', '')
	if rawInput == "" then return nil, "Путь не указан" end

	if rawInput:find("^https?://") then
		local ok, body = pcall(function()
			if game and game.HttpGet then return game:HttpGet(rawInput) end
			return nil
		end)
		if ok and body and #body > 0 then
			return body, rawInput:match("[^/?#]+$") or "web_image.png"
		end
		local req = (syn and syn.request) or (http and http.request) or http_request or request
		if req then
			local res = req({Url = rawInput, Method = "GET"})
			if res and res.Body and #res.Body > 0 then
				return res.Body, rawInput:match("[^/?#]+$") or "web_image.png"
			end
		end
		return nil, "Ошибка скачивания по URL. Проверьте ссылку."
	end

	local norm = rawInput:gsub("\\", "/")
	local afterWorkspace = norm:match("[Ww][Oo][Rr][Kk][Ss][Pp][Aa][Cc][Ee]/(.+)$")
	local afterRich = norm:match("[Rr][Ii][Cc][Hh][Pp][Rr][Ee][Mm][Ii][Uu][Mm]/(.+)$")
	local justFilename = norm:match("([^/]+)$") or norm
	local nameNoExt = justFilename:match("(.+)%.%w+$") or justFilename

	local candidates = {}
	local function addCand(c)
		if c and c ~= "" and not table.find(candidates, c) then
			table.insert(candidates, c)
		end
	end

	if afterWorkspace then
		addCand(afterWorkspace)
	end
	if afterRich then
		addCand("RichPremium/" .. afterRich)
		addCand(afterRich)
	end
	addCand("RichPremium/" .. justFilename)
	addCand(justFilename)
	addCand(norm)
	addCand(rawInput)
	addCand("RichPremium/" .. nameNoExt .. ".png")
	addCand("RichPremium/" .. nameNoExt .. ".bmp")
	addCand(nameNoExt .. ".png")
	addCand(nameNoExt .. ".bmp")

	for _, cand in ipairs(candidates) do
		local ok, content = pcall(function()
			return readfile(cand)
		end)
		if ok and type(content) == "string" and #content > 0 then
			local dispName = cand:match("([^/]+)$") or cand
			return content, dispName
		end
	end

	return nil, string.format("Файл не найден. В Xeno путь считается от папки workspace. Попробуйте указать: 'RichPremium/%s' или '%s'.", justFilename, justFilename)
end

local function colorDistSq(c1, c2)
	local dr = c1.R - c2.R
	local dg = c1.G - c2.G
	local db = c1.B - c2.B
	return dr * dr * 0.299 + dg * dg * 0.587 + db * db * 0.114
end

local function extractPalette(pixelGrid, targetW, targetH, maxColors)
	local samples = {}
	local stepX = math.max(1, math.floor(targetW / 40))
	local stepY = math.max(1, math.floor(targetH / 40))

	for y = 1, targetH, stepY do
		for x = 1, targetW, stepX do
			local c = pixelGrid[y] and pixelGrid[y][x]
			if c then
				if not (c.R > 0.94 and c.G > 0.94 and c.B > 0.94) then
					table.insert(samples, c)
				end
			end
		end
	end

	if #samples == 0 then
		return { Color3.new(0, 0, 0) }
	end

	local palette = {}
	table.insert(palette, samples[1])

	while #palette < maxColors and #palette < #samples do
		local bestCandidate, maxMinDist = nil, -1
		for _, s in ipairs(samples) do
			local minDist = math.huge
			for _, p in ipairs(palette) do
				local d = colorDistSq(s, p)
				if d < minDist then minDist = d end
			end
			if minDist > maxMinDist then
				maxMinDist = minDist
				bestCandidate = s
			end
		end
		if bestCandidate then
			table.insert(palette, bestCandidate)
		else
			break
		end
	end

	table.sort(palette, function(a, b)
		local lumA = a.R * 0.299 + a.G * 0.587 + a.B * 0.114
		local lumB = b.R * 0.299 + b.G * 0.587 + b.B * 0.114
		return lumA < lumB
	end)

	return palette
end

local function mapToPalette(c, palette)
	local bestIdx = 1
	local bestDist = math.huge
	for i, palColor in ipairs(palette) do
		local d = colorDistSq(c, palColor)
		if d < bestDist then
			bestDist = d
			bestIdx = i
		end
	end
	return bestIdx, palette[bestIdx]
end

local function prepareDrawBatches(img, targetW, targetH, paletteSize, skipWhite)
	local origW = img.Width
	local origH = img.Height
	local imgAspect = origW / math.max(1, origH)
	local gridAspect = targetW / math.max(1, targetH)
	local effTW, effTH = targetW, targetH
	if gridAspect > imgAspect then
		effTH = math.max(2, rnd(targetW / imgAspect))
	else
		effTW = math.max(2, rnd(targetH * imgAspect))
	end
	local padX = (effTW - targetW) / 2
	local padY = (effTH - targetH) / 2
	local drawW = effTW - 2 * padX
	local drawH = effTH - 2 * padY
	local grid = {}
	for y = 1, targetH do
		grid[y] = {}
		local fy0 = ((y - 1) + padY) * (origH / effTH)
		local fy1 = (y + padY) * (origH / effTH)
		local sy0 = math.max(1, math.floor(fy0) + 1)
		local sy1 = math.min(origH, math.ceil(fy1))
		if sy1 < sy0 then sy1 = sy0 end
		for x = 1, drawW do
			local fx0 = ((x - 1) + padX) * (origW / effTW)
			local fx1 = (x + padX) * (origW / effTW)
			local sx0 = math.max(1, math.floor(fx0) + 1)
			local sx1 = math.min(origW, math.ceil(fx1))
			if sx1 < sx0 then sx1 = sx0 end
			local rSum, gSum, bSum, cnt = 0, 0, 0, 0
			for sy = sy0, sy1 do
				for sx = sx0, sx1 do
					local col, alpha = img:GetPixel(sx, sy)
					if col and (alpha or 1) >= 0.25 then
						rSum = rSum + col.R
						gSum = gSum + col.G
						bSum = bSum + col.B
						cnt = cnt + 1
					end
				end
			end
			if cnt > 0 then
				grid[y][x] = Color3.new(rSum / cnt, gSum / cnt, bSum / cnt)
			else
				grid[y][x] = Color3.new(1, 1, 1)
			end
		end
	end

	local palette = extractPalette(grid, drawW, drawH, paletteSize or 24)

	local colorBuckets = {}
	for i = 1, #palette do
		colorBuckets[i] = {
			Color = palette[i],
			Segments = {}
		}
	end

	local totalSegments = 0

	for y = 1, drawH do
		local curColorIdx = nil
		local startX = nil

		for x = 1, drawW do
			local c = grid[y][x]
			local isWhite = skipWhite and (c.R > 0.93 and c.G > 0.93 and c.B > 0.93)
			local palIdx = isWhite and 0 or mapToPalette(c, palette)

			if palIdx ~= curColorIdx then
				if curColorIdx and curColorIdx > 0 and startX then
					table.insert(colorBuckets[curColorIdx].Segments, {
						StartX = startX,
						EndX = x - 1,
						Y = y
					})
					totalSegments = totalSegments + 1
				end
				curColorIdx = palIdx
				startX = (palIdx > 0) and x or nil
			end
		end

		if curColorIdx and curColorIdx > 0 and startX then
			table.insert(colorBuckets[curColorIdx].Segments, {
				StartX = startX,
				EndX = drawW,
				Y = y
			})
			totalSegments = totalSegments + 1
		end
	end

	return colorBuckets, palette, totalSegments, drawW, drawH
end

local function stopPainting()
	PaintState.Token = PaintState.Token + 1
	PaintState.Running = false
	PaintState.Paused = false
	setPaintStatus("Остановлено.", 0)

	pcall(function()
		if PaintState.OrigCamType and PaintState.OrigCamCFrame then
			Workspace.CurrentCamera.CameraType = PaintState.OrigCamType
			Workspace.CurrentCamera.CFrame = PaintState.OrigCamCFrame
			PaintState.OrigCamType = nil
			PaintState.OrigCamCFrame = nil
		end
	end)
end

local function executePainting()
	if not PaintState.LoadedImage then
		setPaintStatus("Сначала загрузите изображение!")
		if showNotification then showNotification("Paint Bot", "Загрузите PNG или BMP файл!", 2, Color3.fromRGB(255, 100, 100)) end
		return
	end

	local canvas = findCanvasPart()
	if not canvas then
		setPaintStatus("Холст не найден! Встаньте на зону для рисования.")
		if showNotification then showNotification("Paint Bot", "Встаньте на холст на полу!", 2, Color3.fromRGB(255, 100, 100)) end
		return
	end

	highlightCanvas(canvas)

	if Config.Paint_AutoEquip ~= false then
		equipBrushTool()
	end

	PaintState.Token = PaintState.Token + 1
	local token = PaintState.Token
	PaintState.Running = true
	PaintState.Paused = false

	setPaintStatus("Анализ и подготовка штрихов (RLE)...")
	task.wait(0.05)

	local targetRes = clamp(tonumber(Config.Paint_Resolution) or 90, 30, 200)
	local paletteSize = clamp(tonumber(Config.Paint_PaletteSize) or 24, 6, 64)
	local skipWhite = (Config.Paint_SkipWhite ~= false)
	local delayTime = math.max(0.003, tonumber(Config.Paint_Delay) or 0.015)
	local imgScale = clamp(tonumber(Config.Paint_ImageScale) or 0.5, 0.05, 1)
	local offX = tonumber(Config.Paint_CanvasOffsetX) or 0
	local offY = tonumber(Config.Paint_CanvasOffsetY) or 0
	local paintMethod = tostring(Config.Paint_Method or "Input")

	local colorBuckets, palette, totalSegments, gridW, gridH = prepareDrawBatches(
		PaintState.LoadedImage,
		targetRes,
		targetRes,
		paletteSize,
		skipWhite
	)

	PaintState.TotalStrokes = totalSegments
	PaintState.CompletedStrokes = 0
	PaintState.TotalColors = #colorBuckets

	if totalSegments == 0 then
		setPaintStatus("Все пиксели белые либо пропущены!")
		PaintState.Running = false
		return
	end

	local cam = Workspace.CurrentCamera
	if Config.Paint_TopDownCam ~= false then
		PaintState.OrigCamType = cam.CameraType
		PaintState.OrigCamCFrame = cam.CFrame
		cam.CameraType = Enum.CameraType.Scriptable
		local surfW, surfH, normVec, rightVec, downVec = getCanvasInfo(canvas)
		local offXc = tonumber(Config.Paint_CanvasOffsetX) or 0
		local offYc = tonumber(Config.Paint_CanvasOffsetY) or 0
		local imgScaleC = clamp(tonumber(Config.Paint_ImageScale) or 0.5, 0.05, 1)
		local regW = surfW * imgScaleC
		local regH = surfH * imgScaleC
		local drawSpanW = regW * clamp(gridW / gridH, 0.02, 1)
		local drawSpanH = regH * clamp(gridH / gridW, 0.02, 1)
		local camCenter = canvas.Position + (rightVec * offXc) + (downVec * offYc)
		local camHeight = math.max(drawSpanW, drawSpanH) * 1.35 + 8
		cam.CFrame = CFrame.lookAt(camCenter + (normVec * camHeight), camCenter, downVec)
		task.wait(0.2)
	end

	local tool = equipBrushTool()
	local drawRemote = nil
	if tool then
		drawRemote = tool:FindFirstChildWhichIsA("RemoteEvent", true)
	end
	if not drawRemote then
		local rs = game:GetService("ReplicatedStorage")
		for _, v in pairs(rs:GetDescendants()) do
			if v:IsA("RemoteEvent") then
				local n = v.Name:lower()
				if n:find("draw") or n:find("stroke") or n:find("paint") or n:find("addline") then
					drawRemote = v
					break
				end
			end
		end
	end

	task.spawn(function()
		local surfW, surfH, normVec, rightVec, downVec, thick = getCanvasInfo(canvas)
		local effW = surfW * imgScale
		local effH = surfH * imgScale
		local centerPos = canvas.Position + (rightVec * offX) + (downVec * offY)
		local surfaceOffset = normVec * (thick / 2 + 0.08)

                local ratioWH = gridW / math.max(1, gridH)
                local drawW, drawH
                if ratioWH >= 1 then
                        drawW = math.min(effW, effH * ratioWH)
                        drawH = drawW / ratioWH
                else
                        drawH = math.min(effH, effW / ratioWH)
                        drawW = drawH * ratioWH
                end

		local function gridToWorld(gx, gy)
			local u = (gx - 0.5) / gridW - 0.5
			local v = (gy - 0.5) / gridH - 0.5
			return centerPos + surfaceOffset + (rightVec * (u * drawW)) + (downVec * (v * drawH))
		end

		for cIdx, bucket in ipairs(colorBuckets) do
			local skipBucket = (#bucket.Segments == 0)
			if token ~= PaintState.Token then return end

			PaintState.CurrentColorIdx = cIdx
			setInGameColor(bucket.Color)
			task.wait(0.04)

			for sIdx, seg in ipairs(bucket.Segments) do
				while PaintState.Paused and token == PaintState.Token do
					task.wait(0.1)
				end
				if token ~= PaintState.Token then return end

				local pStart = gridToWorld(seg.StartX, seg.Y)
				local pEnd = gridToWorld(seg.EndX, seg.Y)

				if drawRemote and paintMethod == "Remote" then
					pcall(function()
						drawRemote:FireServer(pStart, pEnd, bucket.Color, 0.1)
					end)
				end

				local s1, on1 = cam:WorldToViewportPoint(pStart)
				local s2, on2 = cam:WorldToViewportPoint(pEnd)

				local skipStroke = false
				if paintMethod ~= "Remote" and (not on1 or not on2) then
					skipStroke = true
				end

				if paintMethod ~= "Remote" and on1 and on2 and VIM then
					if math.abs(s1.X - s2.X) < 3 and math.abs(s1.Y - s2.Y) < 3 then
						VIM:SendMouseButtonEvent(s1.X, s1.Y, 0, true, game, 0)
						task.wait(0.003)
						VIM:SendMouseButtonEvent(s1.X, s1.Y, 0, false, game, 0)
					else
						VIM:SendMouseButtonEvent(s1.X, s1.Y, 0, true, game, 0)
						task.wait(0.003)
						VIM:SendMouseMoveEvent(s2.X, s2.Y, game)
						task.wait(0.003)
						VIM:SendMouseButtonEvent(s2.X, s2.Y, 0, false, game, 0)
					end
				elseif paintMethod ~= "Remote" and on1 and mouse1click then
					pcall(function()
						mousemoveabs(s1.X, s1.Y)
						mouse1click()
					end)
				end
				if not skipStroke then
				PaintState.CompletedStrokes = PaintState.CompletedStrokes + 1
				local prog = PaintState.CompletedStrokes / totalSegments

				if PaintState.CompletedStrokes % 6 == 0 or sIdx == #bucket.Segments then
					setPaintStatus(
						string.format("Цвет %d/%d • Штрих %d/%d (%.1f%%)", cIdx, #colorBuckets, PaintState.CompletedStrokes, totalSegments, prog * 100),
						prog
					)
				end

				task.wait(delayTime)
				end
			end
		end

		if token == PaintState.Token then
			PaintState.Running = false
			setPaintStatus("Рисунок завершен! Шедевр готов! ✨", 1)
			if showNotification then
				showNotification("Paint Bot", "Рисунок полностью нарисован на холсте!", 3.5, Color3.fromRGB(0, 255, 140))
			end
			if PaintState.OrigCamType and PaintState.OrigCamCFrame then
				cam.CameraType = PaintState.OrigCamType
				cam.CFrame = PaintState.OrigCamCFrame
				PaintState.OrigCamType = nil
				PaintState.OrigCamCFrame = nil
			end
		end
	end)
end

Builders.PaintStop = function() stopPainting() end

Builders.Paint = function(parent)
	parent = parent or SettingsFrame
	local isModern = (ModernScroll and (parent == ModernScroll or parent:IsDescendantOf(ModernScroll)))
	local isDrop = isDropdownChild(parent)
	local dropW = isDrop and (parent.AbsoluteSize.X > 50 and (parent.AbsoluteSize.X - 10) or 165) or nil
	local btnW = isModern and 690 or (dropW or (parent == SettingsFrame and 450 or 180))

	local statusCard = Instance.new("Frame", parent)
	statusCard.Size = UDim2.new(0, btnW, 0, 72)
	statusCard.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
	statusCard.BackgroundTransparency = 0.1
	rCorner(statusCard, 6)
	local scStroke = Instance.new("UIStroke", statusCard)
	scStroke.Color = ActiveTheme.Accent
	scStroke.Thickness = 1
	scStroke.Transparency = 0.3

	local statLbl = Instance.new("TextLabel", statusCard)
	statLbl.Size = UDim2.new(1, -16, 0, 22)
	statLbl.Position = UDim2.new(0, 8, 0, 6)
	statLbl.BackgroundTransparency = 1
	statLbl.Text = "[PAINT] " .. PaintState.Status
	statLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
	statLbl.Font = Enum.Font.GothamBold
	statLbl.TextSize = 11
	statLbl.TextTruncate = Enum.TextTruncate.AtEnd
	statLbl.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(PaintState.Labels, statLbl)

	local canvasStat = Instance.new("TextLabel", statusCard)
	canvasStat.Size = UDim2.new(1, -16, 0, 16)
	canvasStat.Position = UDim2.new(0, 8, 0, 28)
	canvasStat.BackgroundTransparency = 1
	local curCan = findCanvasPart()
	if curCan then
		local sw, sh = getCanvasInfo(curCan)
		canvasStat.Text = string.format("Холст: %s (%dx%d studs)", curCan.Name, math.floor(sw), math.floor(sh))
		canvasStat.TextColor3 = Color3.fromRGB(0, 255, 140)
	else
		canvasStat.Text = "Холст: Не обнаружен (встаньте в зону рисования)"
		canvasStat.TextColor3 = Color3.fromRGB(255, 160, 80)
	end
	canvasStat.Font = Enum.Font.Gotham
	canvasStat.TextSize = 10
	canvasStat.TextXAlignment = Enum.TextXAlignment.Left

	local barBg = Instance.new("Frame", statusCard)
	barBg.Size = UDim2.new(1, -16, 0, 12)
	barBg.Position = UDim2.new(0, 8, 0, 48)
	barBg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
	rCorner(barBg, 6)

	local barFill = Instance.new("Frame", barBg)
	barFill.Size = UDim2.new(PaintState.Progress, 0, 1, 0)
	barFill.BackgroundColor3 = ActiveTheme.Accent
	rCorner(barFill, 6)
	table.insert(PaintState.ProgressBarFills, barFill)

	local sep1 = Instance.new("Frame", parent); sep1.Size = UDim2.new(0, btnW, 0, 1); sep1.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep1.BorderSizePixel = 0
	local tImg = Instance.new("TextLabel", parent); tImg.Size = UDim2.new(1,0,0,22); tImg.BackgroundTransparency = 1; tImg.Text = "📁 ИСТОЧНИК ИЗОБРАЖЕНИЯ (PNG / BMP / URL)"; tImg.Font = Enum.Font.GothamBold; tImg.TextColor3 = Color3.fromRGB(240,240,255); tImg.TextSize = 12

	local pathBox = Instance.new("TextBox", parent)
	pathBox.Size = UDim2.new(0, btnW, 0, 36)
	pathBox.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	pathBox.TextColor3 = Color3.fromRGB(240, 240, 255)
	pathBox.PlaceholderText = "Путь к файлу (RichPremium/art.png) или URL (https://...)"
	pathBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 155)
	pathBox.Font = Enum.Font.Gotham
	pathBox.TextSize = 12
	pathBox.ClearTextOnFocus = false
	pathBox.Text = Config.Paint_FilePath or ""
	rCorner(pathBox, 6)
	local pbStroke = Instance.new("UIStroke", pathBox)
	pbStroke.Color = Color3.fromRGB(50, 50, 75); pbStroke.Thickness = 1
	pathBox.FocusLost:Connect(function() Config.Paint_FilePath = pathBox.Text end)

	local PaintPreviewImage = nil
	local PaintPreviewFrame, PreviewHint
	local function doLoadImage(targetPath)
		setPaintStatus("Загрузка и парсинг изображения...")
		task.spawn(function()
			local ok, raw, filename = pcall(function()
				return fetchImageData(targetPath)
			end)
			if not ok or not raw then
				local msg = tostring(filename or raw or "Файл не найден")
				setPaintStatus("Ошибка: " .. msg)
				if showNotification then showNotification("Paint Bot", msg, 3.5, Color3.fromRGB(255, 80, 80)) end
				return
			end

			pcall(function()
				if pathBox and filename and (pathBox.Text:find("\\") or pathBox.Text:find(":") or #pathBox.Text > 50) then
					pathBox.Text = "RichPremium/" .. filename
					Config.Paint_FilePath = pathBox.Text
				end
			end)

			local decOk, img, err = pcall(function()
				return decodeImage(raw, filename)
			end)
			if not decOk or not img then
				local msg = tostring(err or img or "Ошибка декодирования")
				setPaintStatus("Ошибка: " .. msg)
				if showNotification then showNotification("Paint Bot", msg, 4, Color3.fromRGB(255, 80, 80)) end
				return
			end

			PaintState.LoadedImage = img
			PaintState.LoadedImageName = filename
			setPaintStatus(string.format("Загружено: %s (%dx%d px)", filename, img.Width, img.Height))
			if showNotification then
				showNotification("Изображение загружено!", string.format("%s [%dx%d px]", filename, img.Width, img.Height), 2.5, Color3.fromRGB(0, 255, 140))
			end
			pcall(function()
				if not PaintPreviewFrame then return end
				local gVim = nil
				pcall(function() gVim = getgenv().VIM or _G.VIM end)
				if type(gVim) ~= "table" and type(gVim) ~= "userdata" then gVim = nil end
				if gVim and gVim.CreateCanvas then
					local dsW, dsH = 160, math.max(1, math.floor(160 * (img.Height / math.max(1, img.Width))))
					if img.Height > img.Width then dsH = 160; dsW = math.max(1, math.floor(160 * (img.Width / math.max(1, img.Height)))) end
					local cv = gVim:CreateCanvas(dsW, dsH)
					for py = 0, dsH - 1 do
						local srcY = clamp(math.floor(py * (img.Height / dsH)) + 1, 1, img.Height)
						for px = 0, dsW - 1 do
							local srcX = clamp(math.floor(px * (img.Width / dsW)) + 1, 1, img.Width)
							local col, alpha = img:GetPixel(srcX, srcY)
							if col and (alpha or 1) >= 0.25 then
								cv:SetPixel(px, py, col)
							else
								cv:SetPixel(px, py, Color3.fromRGB(28, 28, 38))
							end
						end
					end
					if PaintPreviewImage then PaintPreviewImage:Destroy() end
					PaintPreviewImage = cv:GetImageLabel()
					PaintPreviewImage.Parent = PaintPreviewFrame
					PaintPreviewImage.Size = UDim2.new(0, dsW, 0, dsH)
					PaintPreviewImage.Position = UDim2.new(0.5, -dsW / 2, 0.5, -dsH / 2)
					if PreviewHint then PreviewHint.Text = "" end
				elseif PreviewHint then
					PreviewHint.Text = "Картинка загружена (предпросмотр недоступен)"
				end
			end)
		end)
	end

	createButton(parent, "🔍 Загрузить и проверить изображение", btnW, function()
		doLoadImage(pathBox.Text)
	end)

	local pCard = Instance.new("Frame", parent)
	pCard.Size = UDim2.new(0, btnW, 0, 34)
	pCard.BackgroundTransparency = 1

	local btnP1 = Instance.new("TextButton", pCard)
	btnP1.Size = UDim2.new(0.32, -4, 1, 0)
	btnP1.Position = UDim2.new(0, 0, 0, 0)
	btnP1.BackgroundColor3 = Color3.fromRGB(22, 30, 24)
	btnP1.Text = "🐸 Pepe Meme"
	btnP1.TextColor3 = Color3.fromRGB(120, 240, 140)
	btnP1.Font = Enum.Font.GothamBold; btnP1.TextSize = 11; rCorner(btnP1, 6)
	btnP1.MouseButton1Click:Connect(function()
		pathBox.Text = "https://i.imgur.com/8Qe7wJq.png"
		doLoadImage(pathBox.Text)
	end)

	local btnP2 = Instance.new("TextButton", pCard)
	btnP2.Size = UDim2.new(0.32, -4, 1, 0)
	btnP2.Position = UDim2.new(0.34, 0, 0, 0)
	btnP2.BackgroundColor3 = Color3.fromRGB(30, 22, 28)
	btnP2.Text = "🎨 Mona Lisa"
	btnP2.TextColor3 = Color3.fromRGB(240, 160, 200)
	btnP2.Font = Enum.Font.GothamBold; btnP2.TextSize = 11; rCorner(btnP2, 6)
	btnP2.MouseButton1Click:Connect(function()
		pathBox.Text = "https://i.imgur.com/uR1jW1z.png"
		doLoadImage(pathBox.Text)
	end)

	local btnP3 = Instance.new("TextButton", pCard)
	btnP3.Size = UDim2.new(0.32, -4, 1, 0)
	btnP3.Position = UDim2.new(0.68, 0, 0, 0)
	btnP3.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
	btnP3.Text = "👤 Anime Icon"
	btnP3.TextColor3 = Color3.fromRGB(140, 200, 255)
	btnP3.Font = Enum.Font.GothamBold; btnP3.TextSize = 11; rCorner(btnP3, 6)
	btnP3.MouseButton1Click:Connect(function()
		pathBox.Text = "https://i.imgur.com/5h8hXmD.png"
		doLoadImage(pathBox.Text)
	end)

	PaintPreviewFrame = Instance.new("Frame", parent)
	PaintPreviewFrame.Size = UDim2.new(0, btnW, 0, 170)
	PaintPreviewFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	PaintPreviewFrame.BackgroundTransparency = 0.05
	rCorner(PaintPreviewFrame, 6)
	local ppStroke = Instance.new("UIStroke", PaintPreviewFrame)
	ppStroke.Color = Color3.fromRGB(50, 50, 75); ppStroke.Thickness = 1; ppStroke.Transparency = 0.3
	PreviewHint = Instance.new("TextLabel", PaintPreviewFrame)
	PreviewHint.Size = UDim2.new(1, 0, 1, 0)
	PreviewHint.BackgroundTransparency = 1
	PreviewHint.Text = "Здесь появится предпросмотр после загрузки"
	PreviewHint.TextColor3 = Color3.fromRGB(110, 110, 140)
	PreviewHint.Font = Enum.Font.Gotham
	PreviewHint.TextSize = 11

	local sep2 = Instance.new("Frame", parent); sep2.Size = UDim2.new(0, btnW, 0, 1); sep2.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep2.BorderSizePixel = 0
	local tCan = Instance.new("TextLabel", parent); tCan.Size = UDim2.new(1,0,0,22); tCan.BackgroundTransparency = 1; tCan.Text = "🎯 НАСТРОЙКА ХОЛСТА И ИНСТРУМЕНТОВ"; tCan.Font = Enum.Font.GothamBold; tCan.TextColor3 = Color3.fromRGB(240,240,255); tCan.TextSize = 12

	createButton(parent, "📍 Автодетект холста (Под ногами)", btnW, function()
		PaintState.SelectedCanvas = nil
		local c = findCanvasPart()
		if c then
			highlightCanvas(c)
			local sw, sh = getCanvasInfo(c)
			canvasStat.Text = string.format("Холст: %s (%dx%d studs)", c.Name, math.floor(sw), math.floor(sh))
			canvasStat.TextColor3 = Color3.fromRGB(0, 255, 140)
			if showNotification then showNotification("Холст найден!", string.format("%s [%dx%d studs]", c.Name, math.floor(sw), math.floor(sh)), 2, Color3.fromRGB(0, 255, 140)) end
		else
			canvasStat.Text = "Холст не найден!"
			canvasStat.TextColor3 = Color3.fromRGB(255, 100, 100)
			if showNotification then showNotification("Холст не найден", "Встаньте на белый квадрат на полу", 2, Color3.fromRGB(255, 100, 100)) end
		end
	end)

	createButton(parent, "🧹 Очистить холст (Стереть все в игре)", btnW, function()
		clearInGameCanvas()
	end)

	createButton(parent, "🖌 Взять кисточку в руки (Auto-Equip)", btnW, function()
		local t = equipBrushTool()
		if t then
			if showNotification then showNotification("Кисть готова", "Инструмент " .. t.Name .. " экипирован", 2, ActiveTheme.Accent) end
		else
			if showNotification then showNotification("Ошибка", "Инструмент кисти не найден в рюкзаке", 2, Color3.fromRGB(255, 100, 100)) end
		end
	end)

	local sep3 = Instance.new("Frame", parent); sep3.Size = UDim2.new(0, btnW, 0, 1); sep3.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep3.BorderSizePixel = 0
	local tRun = Instance.new("TextLabel", parent); tRun.Size = UDim2.new(1,0,0,22); tRun.BackgroundTransparency = 1; tRun.Text = "⚡ УПРАВЛЕНИЕ ПЕЧАТЬЮ"; tRun.Font = Enum.Font.GothamBold; tRun.TextColor3 = Color3.fromRGB(0,255,140); tRun.TextSize = 12

	local startBtn = Instance.new("TextButton", parent)
	startBtn.Size = UDim2.new(0, btnW, 0, 38)
	startBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 32)
	startBtn.Text = "▶ НАЧАТЬ РИСОВАНИЕ НА ХОЛСТЕ"
	startBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 13
	rCorner(startBtn, 6)
	local sStroke = Instance.new("UIStroke", startBtn)
	sStroke.Color = Color3.fromRGB(0, 255, 140); sStroke.Thickness = 1.2; sStroke.Transparency = 0.3

	startBtn.MouseButton1Click:Connect(function()
		if not PaintState.Running then
			executePainting()
		else
			if showNotification then showNotification("Paint Bot", "Печать уже запущена!", 1.5) end
		end
	end)

	local ctrlRow = Instance.new("Frame", parent)
	ctrlRow.Size = UDim2.new(0, btnW, 0, 32)
	ctrlRow.BackgroundTransparency = 1

	local pauseBtn = Instance.new("TextButton", ctrlRow)
	pauseBtn.Size = UDim2.new(0.48, -2, 1, 0)
	pauseBtn.Position = UDim2.new(0, 0, 0, 0)
	pauseBtn.BackgroundColor3 = Color3.fromRGB(36, 32, 20)
	pauseBtn.Text = "⏸ Пауза / Продолжить"
	pauseBtn.TextColor3 = Color3.fromRGB(255, 210, 80)
	pauseBtn.Font = Enum.Font.GothamBold; pauseBtn.TextSize = 11; rCorner(pauseBtn, 6)
	pauseBtn.MouseButton1Click:Connect(function()
		if PaintState.Running then
			PaintState.Paused = not PaintState.Paused
			setPaintStatus(PaintState.Paused and "Пауза" or "Печать продолжается...")
		end
	end)

	local stopBtn = Instance.new("TextButton", ctrlRow)
	stopBtn.Size = UDim2.new(0.48, -2, 1, 0)
	stopBtn.Position = UDim2.new(0.52, 0, 0, 0)
	stopBtn.BackgroundColor3 = Color3.fromRGB(42, 20, 24)
	stopBtn.Text = "⏹ Остановить печать"
	stopBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
	stopBtn.Font = Enum.Font.GothamBold; stopBtn.TextSize = 11; rCorner(stopBtn, 6)
	stopBtn.MouseButton1Click:Connect(function()
		stopPainting()
	end)

	local sep4 = Instance.new("Frame", parent); sep4.Size = UDim2.new(0, btnW, 0, 1); sep4.BackgroundColor3 = Color3.fromRGB(45, 45, 60); sep4.BorderSizePixel = 0
	local tSet = Instance.new("TextLabel", parent); tSet.Size = UDim2.new(1,0,0,22); tSet.BackgroundTransparency = 1; tSet.Text = "⚙ НАСТРОЙКИ КАЧЕСТВА И СКОРОСТИ"; tSet.Font = Enum.Font.GothamBold; tSet.TextColor3 = Color3.fromRGB(240,240,255); tSet.TextSize = 12

	createTextBox(parent, "Детализация (ширина px)", tostring(Config.Paint_Resolution or 90), function(v)
		Config.Paint_Resolution = clamp(tonumber(v) or 90, 30, 200)
	end)

	createTextBox(parent, "Кол-во цветов палитры", tostring(Config.Paint_PaletteSize or 24), function(v)
		Config.Paint_PaletteSize = clamp(tonumber(v) or 24, 6, 64)
	end)

	createTextBox(parent, "Задержка штриха (сек)", tostring(Config.Paint_Delay or 0.015), function(v)
		Config.Paint_Delay = clamp(tonumber(v) or 0.015, 0.002, 0.2)
	end)

	createTextBox(parent, "Размер фото на холсте (0.05 - 1)", tostring(Config.Paint_ImageScale or 0.5), function(v)
		Config.Paint_ImageScale = clamp(tonumber(v) or 0.5, 0.05, 1)
	end)

	createTextBox(parent, "Сдвиг рисунка по горизонтали (studs)", tostring(Config.Paint_CanvasOffsetX or 0), function(v)
		Config.Paint_CanvasOffsetX = tonumber(v) or 0
	end)

	createTextBox(parent, "Сдвиг рисунка по вертикали (studs)", tostring(Config.Paint_CanvasOffsetY or 0), function(v)
		Config.Paint_CanvasOffsetY = tonumber(v) or 0
	end)

	addToggle(parent, "Выбор метода рисования", "Paint_MethodPopup", nil, function(p)
		for _, m in ipairs({"Input", "Remote", "Mouse"}) do
			createButton(p, "Метод: " .. m, 200, function(b)
				Config.Paint_Method = m
					b.Text = "✔ Метод: " .. m
			end)
		end
	end)

	addToggle(parent, "Пропускать белый фон холста", "Paint_SkipWhite")
	addToggle(parent, "Top-Down камера во время печати", "Paint_TopDownCam")
	addToggle(parent, "Авто-экипировка кисточки", "Paint_AutoEquip")
end

end

local function buildMainTab(name, logicFunc)
	local btn = Instance.new("TextButton", TabsFrame); btn.Size = UDim2.new(1, -10, 0, 35); btn.BackgroundColor3 = ActiveTheme.Btn; btn.BackgroundTransparency = 0.1; btn.Text = "   " .. name; btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 13; btn.TextXAlignment = Enum.TextXAlignment.Left; rCorner(btn, 6)
	local ind = Instance.new("Frame", btn); ind.Name = "Indicator"; ind.Size = UDim2.new(0, 3, 0, 0); ind.Position = UDim2.new(0, 3, 0.5, 0); ind.AnchorPoint = Vector2.new(0, 0.5); ind.BackgroundColor3 = ActiveTheme.Accent; ind.BorderSizePixel = 0; rCorner(ind, 2)
	table.insert(UI_Elements.Strokes, {Color = ind.BackgroundColor3, Parent = ind})

	btn.MouseEnter:Connect(function()
		if activeTabBtn ~= btn then TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = ActiveTheme.BtnHover, TextColor3 = Color3.fromRGB(240, 240, 240)}):Play() end
	end)
	btn.MouseLeave:Connect(function()
		if activeTabBtn ~= btn then TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = ActiveTheme.Btn, TextColor3 = Color3.fromRGB(180, 180, 180)}):Play() end
	end)

	btn.MouseButton1Click:Connect(function()
		if activeTabBtn == btn then return end
		TweenService:Create(SettingsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {CanvasPosition = Vector2.new(0,0)}):Play()
		clearSettings()
		if activeTabBtn then
			local oldInd = activeTabBtn:FindFirstChild("Indicator")
			if oldInd then TweenService:Create(oldInd, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 0)}):Play() end
			TweenService:Create(activeTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = ActiveTheme.Btn, TextColor3 = Color3.fromRGB(180,180,180)}):Play()
		end
		activeTabBtn = btn;
		TweenService:Create(ind, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 0.65, 0)}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Config.RGBUI and Color3.fromHSV(RGBHue,1,1) or ActiveTheme.Accent, TextColor3 = Color3.fromRGB(20,20,25)}):Play()
		logicFunc()
	end)
	return btn
end

local mainTabs = {
	{Name = "Combat", Icon = "⚔", Builder = Builders.Combat},
	{Name = "Visuals", Icon = "👁", Builder = Builders.Visuals},
	{Name = "Movement", Icon = "⚡", Builder = Builders.Movement},
	{Name = "World & Misc", Icon = "🌍", Builder = Builders.WorldMisc},
	{Name = "Games", Icon = "🎮", Builder = Builders.Games},
	{Name = "Paint", Icon = "🎨", Builder = Builders.Paint},
	{Name = "Music", Icon = "🎵", Builder = Builders.Music},
	{Name = "Themes", Icon = "🖌", Builder = Builders.ThemeUI},
	{Name = "Configs", Icon = "⚙", Builder = Builders.Configs}
}

local function buildDropdownUI()
	for _, df in pairs(DropdownFrames) do df:Destroy() end
	DropdownFrames = {}
	
	local screenW = Workspace.CurrentCamera.ViewportSize.X
	local numTabs = #mainTabs
	local spacing = 8
	local colW = clamp(math.floor((screenW - 40 - (numTabs - 1) * spacing) / numTabs), 130, 185)
	local totalW = numTabs * colW + (numTabs - 1) * spacing
	local startX = math.max(16, math.floor((screenW - totalW) / 2))
	
	for i, cat in ipairs(mainTabs) do
		local posX = startX + (i - 1) * (colW + spacing)
		local frame = Instance.new("Frame", ScreenGui)
		frame.Name = "Dropdown_" .. cat.Name
		frame.Size = UDim2.new(0, colW, 0, 34)
		frame.Position = UDim2.new(0, posX, 0, 20)
		frame.BackgroundColor3 = ActiveTheme.Panel
		frame.BackgroundTransparency = 0.1
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Draggable = true
		frame.ZIndex = 20
		frame.Visible = MenuVisible
		rCorner(frame, 8)
		rStroke(frame, ActiveTheme.Accent, 1.2)
		
		local top = Instance.new("TextButton", frame)
		top.Size = UDim2.new(1, 0, 1, 0)
		top.BackgroundTransparency = 1
		top.Text = "  " .. (cat.Icon and (cat.Icon .. " ") or "") .. cat.Name
		top.TextColor3 = ActiveTheme.Accent
		top.Font = Enum.Font.GothamBold
		top.TextSize = 13
		top.TextXAlignment = Enum.TextXAlignment.Left
		top.ZIndex = 21
		table.insert(UI_Elements.Texts, top)
		
		local arrow = Instance.new("TextLabel", top)
		arrow.Size = UDim2.new(0, 24, 1, 0)
		arrow.Position = UDim2.new(1, -26, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = Color3.fromRGB(170, 175, 195)
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 11
		arrow.ZIndex = 22
		
		local scroll = Instance.new("ScrollingFrame", frame)
		scroll.Name = "Scroll"
		scroll.Size = UDim2.new(1, 0, 0, 320)
		scroll.Position = UDim2.new(0, 0, 1, 6)
		scroll.BackgroundColor3 = ActiveTheme.Panel
		scroll.BackgroundTransparency = 0.1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = ActiveTheme.Accent
		scroll.Visible = false
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ZIndex = 21
		scroll.ClipsDescendants = true
		rCorner(scroll, 8)
		rStroke(scroll, ActiveTheme.Accent, 1)
		
		local listLayout = Instance.new("UIListLayout", scroll)
		listLayout.Padding = UDim.new(0, 5)
		local pad = Instance.new("UIPadding", scroll)
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.PaddingLeft = UDim.new(0, 5)
		pad.PaddingRight = UDim.new(0, 5)
		
		local function bringToFront()
			for _, df in pairs(DropdownFrames) do
				df.ZIndex = 20
				local sc = df:FindFirstChild("Scroll")
				if sc then sc.ZIndex = 21 end
			end
			frame.ZIndex = 30
			scroll.ZIndex = 31
		end
		
		top.MouseButton1Click:Connect(function()
			bringToFront()
			scroll.Visible = not scroll.Visible
			arrow.Text = scroll.Visible and "▲" or "▼"
			arrow.TextColor3 = scroll.Visible and ActiveTheme.Accent or Color3.fromRGB(170, 175, 195)
		end)
		
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				bringToFront()
			end
		end)
		
		cat.Builder(scroll)
		
		table.insert(DropdownFrames, frame)
		table.insert(UI_Elements.BG, frame)
		table.insert(UI_Elements.BG, scroll)
	end
end

local modernActiveTab = "Combat"
local modernTabButtons = {}

local function clearModernContent()
	for _, c in pairs(ModernScroll:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function buildModernUI()
	for _, b in pairs(ModernTabBar:GetChildren()) do
		if b:IsA("TextButton") then b:Destroy() end
	end
	modernTabButtons = {}

	local tabs = {
		{Name = "Combat", Builder = Builders.Combat},
		{Name = "Visuals", Builder = Builders.Visuals},
		{Name = "Movement", Builder = Builders.Movement},
		{Name = "World", Builder = Builders.WorldMisc},
		{Name = "Games", Builder = Builders.Games},
		{Name = "Paint", Builder = Builders.Paint},
		{Name = "Music", Builder = Builders.Music},
		{Name = "Themes", Builder = Builders.ThemeUI},
		{Name = "Configs", Builder = Builders.Configs}
	}

	local function selectModernTab(tabName, builder)
		modernActiveTab = tabName
		clearModernContent()
		ModernScroll.CanvasPosition = Vector2.new(0, 0)

		for name, btn in pairs(modernTabButtons) do
			if name == tabName then
				TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
					BackgroundColor3 = ActiveTheme.Accent,
					BackgroundTransparency = 0,
					TextColor3 = Color3.fromRGB(15, 15, 20)
				}):Play()
			else
				TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(155, 160, 185)
				}):Play()
			end
		end

		builder(ModernScroll)
	end

	for _, t in ipairs(tabs) do
		local btn = Instance.new("TextButton", ModernTabBar)
		btn.Size = UDim2.new(0, 51, 0, 26)
		btn.BackgroundTransparency = (t.Name == modernActiveTab) and 0 or 1
		btn.BackgroundColor3 = ActiveTheme.Accent
		btn.Text = t.Name
		btn.TextColor3 = (t.Name == modernActiveTab) and Color3.fromRGB(15, 15, 20) or Color3.fromRGB(155, 160, 185)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.AutoButtonColor = false
		rCorner(btn, 13)
		modernTabButtons[t.Name] = btn

		btn.MouseEnter:Connect(function()
			if modernActiveTab ~= t.Name then
				TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(245, 245, 255)}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if modernActiveTab ~= t.Name then
				TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(155, 160, 185)}):Play()
			end
		end)

		btn.MouseButton1Click:Connect(function()
			selectModernTab(t.Name, t.Builder)
		end)
	end

	local cur = tabs[1]
	for _, t in ipairs(tabs) do
		if t.Name == modernActiveTab then
			cur = t
			break
		end
	end
	selectModernTab(cur.Name, cur.Builder)
end

RefreshUI = function()
	if Config.UIStyle == "Dropdown" then
		MainFrame.Visible = false
		if ModernFrame then ModernFrame.Visible = false end
		buildDropdownUI()
	elseif Config.UIStyle == "Modern" then
		MainFrame.Visible = false
		for _, df in pairs(DropdownFrames) do df:Destroy() end
		DropdownFrames = {}
		if ModernFrame then
			ModernFrame.Visible = MenuVisible
			buildModernUI()
		end
	else
		if ModernFrame then ModernFrame.Visible = false end
		MainFrame.Visible = MenuVisible
		for _, df in pairs(DropdownFrames) do df:Destroy() end
		DropdownFrames = {}
		clearSettings()
		
		for _, c in pairs(TabsFrame:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end
		local firstBtn = nil
		for i, cat in ipairs(mainTabs) do
			local btn = buildMainTab(cat.Name, cat.Builder)
			if i == 1 then firstBtn = btn end
		end

		local unhookSep = Instance.new("Frame", TabsFrame); unhookSep.Size = UDim2.new(1, -10, 0, 1); unhookSep.BackgroundColor3 = Color3.fromRGB(60, 30, 35); unhookSep.BorderSizePixel = 0
		local unhook = Instance.new("TextButton", TabsFrame); unhook.Size = UDim2.new(1, -10, 0, 32); unhook.BackgroundColor3 = Color3.fromRGB(140, 35, 35); unhook.Text = "FORCE UNHOOK"; unhook.TextColor3 = Color3.new(1,1,1); unhook.Font = Enum.Font.GothamSemibold; unhook.TextSize = 12; rCorner(unhook, 6)
		local uConfirm = false
		unhook.MouseButton1Click:Connect(function()
			if not uConfirm then uConfirm = true; unhook.Text = "SURE?"; task.delay(3, function() uConfirm = false; unhook.Text = "FORCE UNHOOK" end) else
				if Builders.MusicStop then Builders.MusicStop() end; if Builders.PaintStop then Builders.PaintStop() end; Config.Wanted_AutoBank = false; Config.Wanted_AutoATM = false; Config.Wanted_VehicleFly = false; Config.Wanted_Debug = false
				for _, c in pairs(Connections) do c:Disconnect() end; for _, t in pairs(Players:GetPlayers()) do cleanESP(t) end
				pcall(function() FOVCircle:Remove(); CrosshairX:Remove(); CrosshairY:Remove() end); for _, o in pairs(TargetAura.Cubes) do pcall(function() o.Part:Destroy() end) end
				for _, o in pairs(TargetAura.Atom) do pcall(function() o.Part:Destroy() end) end; for _, p in pairs(TargetAura.Crown) do pcall(function() p:Destroy() end) end
				pcall(function() TargetAura.Rhombus:Destroy(); TargetAura.Ring:Destroy() end); if aestheticBloom then aestheticBloom:Destroy() end; if aestheticCC then aestheticCC:Destroy() end
				if FreecamPart then FreecamPart:Destroy(); Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
				SpecFrame:Destroy()
				SpecCamPart:Destroy()
				if Connections["SpecTracer"] then Connections["SpecTracer"]:Remove() end
				if player.Character then for _,p in pairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end; if player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed=16 end end
				Workspace.CurrentCamera.FieldOfView = 70; Lighting.Ambient = origAmbient or Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient = origOutdoorAmbient or Color3.fromRGB(127,127,127); Lighting.GlobalShadows = origGlobalShadows or true; Lighting.Brightness = origBrightness or 1; Lighting.ClockTime = origClockTime or 14; Workspace.Gravity = origGravity or 196.2
				local atmo = Lighting:FindFirstChildOfClass("Atmosphere"); if atmo then atmo.Density = 0.3 end; Lighting.FogColor = origFogColor or Color3.fromRGB(192, 192, 192); Lighting.FogEnd = origFogEnd or 100000; Lighting.FogStart = origFogStart or 0
				for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v:FindFirstChildOfClass("SelectionBox") then v:FindFirstChildOfClass("SelectionBox"):Destroy(); v.Transparency = originalTransparencies[v] or 0 end end
				if ModernFrame then ModernFrame:Destroy() end
				if PopupFrame then PopupFrame:Destroy() end
				for _, df in pairs(DropdownFrames) do df:Destroy() end
				DropdownFrames = {}
				ScreenGui:Destroy()
			end
		end)
		
		if firstBtn then
			activeTabBtn = nil
			firstBtn.BackgroundColor3 = ActiveTheme.Accent
			firstBtn.TextColor3 = Color3.fromRGB(20,20,25)
			local ind = firstBtn:FindFirstChild("Indicator")
			if ind then ind.Size = UDim2.new(0, 3, 0.65, 0) end
			activeTabBtn = firstBtn
			mainTabs[1].Builder(SettingsFrame)
		end
	end
end

RefreshUI()

