local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatAction = remotes:WaitForChild("CombatAction")
local serverEvent = remotes:WaitForChild("ServerEvent")
local combatFX = remotes:WaitForChild("CombatFX")
local clashEvent = remotes:WaitForChild("ClashEvent")
local selection = remotes:WaitForChild("Selection")
local definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local Config = require(ReplicatedStorage.Shared.Config)
local CombatVFX = require(ReplicatedStorage.Combat.CombatVFX)
local CombatSFX = require(ReplicatedStorage.Combat.CombatSFX)
local controllers = script.Parent:WaitForChild("Controllers")
local AnimationController = require(controllers.AnimationController)
local CameraController = require(controllers.CameraController)
local InputController = require(controllers.InputController)
local AbilityController = require(controllers.AbilityController)

local abilityController = AbilityController.new(combatAction)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local accent = Color3.fromRGB(142, 101, 235)
local accentBright = Color3.fromRGB(205, 181, 255)
local red = Color3.fromRGB(219, 70, 85)
local gold = Color3.fromRGB(245, 190, 76)
local blue = Color3.fromRGB(91, 171, 255)
local panel = Color3.fromRGB(11, 13, 18)
local tile = Color3.fromRGB(24, 27, 35)
local tileHover = Color3.fromRGB(35, 38, 48)
local text = Color3.fromRGB(238, 239, 245)
local muted = Color3.fromRGB(151, 154, 170)

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.3
    s.Parent = parent
    return s
end

local function label(parent, textValue, size, position, font, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = textValue or ""
    l.Size = size
    l.Position = position
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 14
    l.TextColor3 = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function button(parent, name, textValue, size, position, strokeColor)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = textValue or ""
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = tile
    b.BackgroundTransparency = 0.04
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = text
    b.AutoButtonColor = false
    b.Selectable = true
    b.Parent = parent
    corner(b, 10)
    stroke(b, strokeColor or Color3.fromRGB(73, 77, 93), 1, 0.2)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = tileHover}):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = tile}):Play()
    end)

    return b
end

local function fireAction(action, duration, payload)
    local now = os.clock()
    local untilValue = tonumber(gui:GetAttribute("Cooldown_" .. action)) or 0
    if untilValue > now then
        return false
    end

    if duration and duration > 0 then
        gui:SetAttribute("Cooldown_" .. action, now + duration)
    end

    abilityController:Fire(action, payload)
    return true
end

local function healthPercent()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.MaxHealth <= 0 then
        return 0
    end
    return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
end

local function cooldownFor(action)
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    elseif action == "Heavy" then
        return Config.Combat.Heavy.Cooldown
    elseif action == "Dash" then
        return Config.Combat.Dash.Cooldown
    elseif action == "Dodge" then
        return Config.Combat.Dodge.Cooldown
    elseif action == "Grab" then
        return Config.Combat.Grab.Cooldown
    elseif action == "Domain" then
        return Config.Domain.Cooldown
    end

    local id = player:GetAttribute("CharacterId") or "Yuji"
    local slot = tonumber(string.match(tostring(action), "^Skill(%d)$"))
    if slot then
        local moveSet = movesets[id] or movesets.Yuji
        local move = moveSet[slot]
        return move and move.Cooldown or 0.6
    end

    return 0
end

local function makePanel(name, size, position, parent, transparency)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = panel
    frame.BackgroundTransparency = transparency or 0.12
    frame.BorderSizePixel = 0
    frame.Parent = parent
    corner(frame, 12)
    stroke(frame, Color3.fromRGB(72, 76, 92), 1, 0.3)
    return frame
end

local function makeProgress(parent, name, position, size, fillColor, backColor)
    local back = Instance.new("Frame")
    back.Name = name
    back.Size = size
    back.Position = position
    back.BackgroundColor3 = backColor
    back.BorderSizePixel = 0
    back.ClipsDescendants = true
    back.Parent = parent
    corner(back, 5)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.Parent = back
    corner(fill, 5)

    return back, fill
end

local function makeCombatButton(parent, name, textValue, accentColor, scale, anchor)
    local b = Instance.new("TextButton")
    b.Name = name
    b.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
    b.Size = scale
    b.BackgroundColor3 = tile
    b.BackgroundTransparency = 0.05
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBlack
    b.Text = textValue
    b.TextColor3 = text
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Selectable = true
    b.Parent = parent
    corner(b, 16)
    stroke(b, accentColor, 1.4, 0.22)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {
            BackgroundColor3 = tileHover,
            Size = scale + UDim2.fromOffset(3, 3)
        }):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {
            BackgroundColor3 = tile,
            Size = scale
        }):Play()
    end)

    return b
end

gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.ClipToDeviceSafeArea = true

local topLeft = makePanel(
    "FighterCard",
    UDim2.fromScale(0.255, 0.093),
    UDim2.fromScale(0.018, 0.018),
    gui,
    0.10
)

local title = label(topLeft, "CURSED COLLISION", UDim2.fromScale(0.70, 0.20), UDim2.fromScale(0.06, 0.08), Enum.Font.GothamBlack, 10)
title.TextColor3 = muted
local characterLabel = label(topLeft, "Yuji Itadori", UDim2.fromScale(0.86, 0.34), UDim2.fromScale(0.06, 0.25), Enum.Font.GothamBlack, 17)
local uniqueLabel = label(topLeft, "", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.06, 0.62), Enum.Font.Gotham, 9)
uniqueLabel.TextColor3 = muted
corner(topLeft, 13)

local rosterButton = makeCombatButton(gui, "RosterButton", "≡", accent, UDim2.fromScale(0.048, 0.068), Vector2.new(0.5, 0.5))
rosterButton.Position = UDim2.fromScale(0.286, 0.054)
rosterButton.TextSize = 22
rosterButton.BackgroundColor3 = panel

local healthCard = makePanel(
    "HealthCard",
    UDim2.fromScale(0.255, 0.093),
    UDim2.fromScale(0.727, 0.018),
    gui,
    0.10
)

local healthText = label(healthCard, "100% HP", UDim2.fromScale(0.86, 0.28), UDim2.fromScale(0.07, 0.08), Enum.Font.GothamBlack, 15)
healthText.TextXAlignment = Enum.TextXAlignment.Right

local healthBack, healthFill = makeProgress(
    healthCard,
    "HealthBar",
    UDim2.fromScale(0.07, 0.45),
    UDim2.fromScale(0.86, 0.18),
    red,
    Color3.fromRGB(49, 24, 30)
)

local awakeningBack, awakeningFill = makeProgress(
    healthCard,
    "AwakeningBar",
    UDim2.fromScale(0.07, 0.72),
    UDim2.fromScale(0.86, 0.11),
    accent,
    Color3.fromRGB(35, 27, 54)
)

local awakeningText = label(healthCard, "AWAKEN 0%", UDim2.fromScale(0.54, 0.18), UDim2.fromScale(0.07, 0.84), Enum.Font.GothamBold, 8)
awakeningText.TextColor3 = accentBright

local stateLabel = label(gui, "READY", UDim2.fromScale(0.34, 0.034), UDim2.fromScale(0.33, 0.038), Enum.Font.GothamBlack, 11)
stateLabel.TextXAlignment = Enum.TextXAlignment.Center
stateLabel.TextColor3 = Color3.fromRGB(230, 231, 240)

local techniqueFrame = Instance.new("Frame")
techniqueFrame.Name = "TechniqueBar"
techniqueFrame.AnchorPoint = Vector2.new(0.5, 1)
techniqueFrame.Size = UDim2.fromScale(0.50, 0.115)
techniqueFrame.Position = UDim2.fromScale(0.50, 0.972)
techniqueFrame.BackgroundTransparency = 1
techniqueFrame.Parent = gui

local techniqueLayout = Instance.new("UIGridLayout")
techniqueLayout.CellSize = UDim2.new(0.235, 0, 0.92, 0)
techniqueLayout.CellPadding = UDim2.new(0.02, 0, 0, 0)
techniqueLayout.FillDirectionMaxCells = 4
techniqueLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
techniqueLayout.SortOrder = Enum.SortOrder.LayoutOrder
techniqueLayout.Parent = techniqueFrame

local skillButtons = {}
local skillHints = {}
local skillNames = {}
local skillKeys = {}

local function techniqueButton(slot)
    local moveSet = movesets[player:GetAttribute("CharacterId") or "Yuji"] or movesets.Yuji
    local move = moveSet[slot]
    local b = button(techniqueFrame, "Skill" .. tostring(slot), "", UDim2.new(), UDim2.new(), accent)
    b.LayoutOrder = slot
    b.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
    b.BackgroundTransparency = 0.08
    stroke(b, accent, 1.15, 0.3)

    local key = label(b, tostring(slot), UDim2.fromScale(0.24, 0.25), UDim2.fromScale(0.07, 0.07), Enum.Font.GothamBlack, 10)
    key.TextColor3 = accentBright

    local moveLabel = label(b, move and move.Name or ("SKILL " .. tostring(slot)), UDim2.fromScale(0.84, 0.34), UDim2.fromScale(0.08, 0.30), Enum.Font.GothamBlack, 11)
    moveLabel.TextXAlignment = Enum.TextXAlignment.Center

    local hint = label(b, "READY", UDim2.fromScale(0.84, 0.22), UDim2.fromScale(0.08, 0.69), Enum.Font.Gotham, 8)
    hint.TextXAlignment = Enum.TextXAlignment.Center
    hint.TextColor3 = muted

    b.Activated:Connect(function()
        local action = "Skill" .. tostring(slot)
        fireAction(action, cooldownFor(action))
    end)

    skillButtons[slot] = b
    skillHints[slot] = hint
    skillNames[slot] = moveLabel
    skillKeys[slot] = key
end

for slot = 1, 4 do
    techniqueButton(slot)
end

local oneTime = makeCombatButton(
    gui,
    "OneTime",
    "OT  READY",
    Color3.fromRGB(244, 96, 140),
    UDim2.fromScale(0.086, 0.055),
    Vector2.new(0.5, 0.5)
)
oneTime.Position = UDim2.fromScale(0.395, 0.872)
oneTime.TextSize = 9
oneTime.Activated:Connect(function()
    fireAction("OneTime")
end)

local awakeningAction = makeCombatButton(
    gui,
    "AwakeningAction",
    "AWAKEN",
    gold,
    UDim2.fromScale(0.086, 0.055),
    Vector2.new(0.5, 0.5)
)
awakeningAction.Position = UDim2.fromScale(0.50, 0.872)
awakeningAction.TextSize = 9
awakeningAction.Activated:Connect(function()
    fireAction("Awaken")
end)

local domainButton = makeCombatButton(
    gui,
    "DomainAction",
    "DOMAIN",
    blue,
    UDim2.fromScale(0.086, 0.055),
    Vector2.new(0.5, 0.5)
)
domainButton.Position = UDim2.fromScale(0.605, 0.872)
domainButton.TextSize = 9
domainButton.Activated:Connect(function()
    fireAction("Domain", cooldownFor("Domain"))
end)

local actionFrame = Instance.new("Frame")
actionFrame.Name = "CombatActions"
actionFrame.Size = UDim2.fromScale(0.26, 0.36)
actionFrame.Position = UDim2.fromScale(0.735, 0.585)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = gui

local m1 = makeCombatButton(actionFrame, "M1", "M1", red, UDim2.fromScale(0.34, 0.34), Vector2.new(0.5, 0.5))
m1.Position = UDim2.fromScale(0.67, 0.62)
m1.TextSize = 22
stroke(m1, red, 1.8, 0.05)
m1.Activated:Connect(function()
    fireAction("M1", cooldownFor("M1"))
end)

local function smallAction(name, textValue, action, position, strokeColor)
    local b = makeCombatButton(actionFrame, name, textValue, strokeColor, UDim2.fromScale(0.23, 0.18), Vector2.new(0.5, 0.5))
    b.Position = position
    b.TextSize = 9
    b.Activated:Connect(function()
        local payload = action == "Dash" and InputController:GetDashDirection() or nil
        fireAction(action, cooldownFor(action), payload)
    end)
    return b
end

local heavyButton = smallAction("Heavy", "HEAVY", "Heavy", UDim2.fromScale(0.23, 0.27), Color3.fromRGB(188, 191, 205))
local grabButton = smallAction("Grab", "GRAB", "Grab", UDim2.fromScale(0.82, 0.27), Color3.fromRGB(188, 191, 205))
local counterButton = smallAction("Counter", "COUNTER", "Counter", UDim2.fromScale(0.50, 0.27), Color3.fromRGB(196, 141, 255))
local dashButton = smallAction("Dash", "DASH", "Dash", UDim2.fromScale(0.20, 0.72), accent)
local dodgeButton = smallAction("Dodge", "DODGE", "Dodge", UDim2.fromScale(0.84, 0.72), gold)
local slamButton = smallAction("Slam", "SLAM", "Slam", UDim2.fromScale(0.50, 0.72), Color3.fromRGB(255, 132, 92))
local blockButton = makeCombatButton(actionFrame, "Block", "BLOCK", blue, UDim2.fromScale(0.30, 0.19), Vector2.new(0.5, 0.5))
blockButton.Position = UDim2.fromScale(0.27, 0.52)
blockButton.TextSize = 9

local mobileBlock = false
blockButton.Activated:Connect(function()
    mobileBlock = not mobileBlock
    blockButton.Text = mobileBlock and "BLOCKING" or "BLOCK"
    combatAction:FireServer(mobileBlock and "BlockStart" or "BlockEnd")
end)

local function isTouch()
    return UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

local function isGamepad()
    return UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

local function setResponsiveLayout()
    local touch = isTouch()
    local gamepad = isGamepad()

    if touch then
        techniqueFrame.Size = UDim2.fromScale(0.60, 0.105)
        techniqueFrame.Position = UDim2.fromScale(0.51, 0.972)
        actionFrame.Size = UDim2.fromScale(0.31, 0.42)
        actionFrame.Position = UDim2.fromScale(0.695, 0.525)

        m1.Size = UDim2.fromScale(0.38, 0.31)
        m1.Position = UDim2.fromScale(0.70, 0.62)
        blockButton.Size = UDim2.fromScale(0.25, 0.18)
        blockButton.Position = UDim2.fromScale(0.27, 0.44)

        heavyButton.Position = UDim2.fromScale(0.28, 0.20)
        grabButton.Position = UDim2.fromScale(0.82, 0.20)
        dashButton.Position = UDim2.fromScale(0.20, 0.72)
        dodgeButton.Position = UDim2.fromScale(0.86, 0.72)

        oneTime.Position = UDim2.fromScale(0.375, 0.865)
        awakeningAction.Position = UDim2.fromScale(0.50, 0.865)
        domainButton.Position = UDim2.fromScale(0.625, 0.865)
    else
        techniqueFrame.Size = UDim2.fromScale(0.47, 0.11)
        techniqueFrame.Position = UDim2.fromScale(0.50, 0.972)
        actionFrame.Size = UDim2.fromScale(0.255, 0.34)
        actionFrame.Position = UDim2.fromScale(0.735, 0.59)

        m1.Size = UDim2.fromScale(0.36, 0.36)
        m1.Position = UDim2.fromScale(0.66, 0.63)
        blockButton.Position = UDim2.fromScale(0.27, 0.50)

        heavyButton.Position = UDim2.fromScale(0.23, 0.25)
        grabButton.Position = UDim2.fromScale(0.82, 0.25)
        dashButton.Position = UDim2.fromScale(0.20, 0.74)
        dodgeButton.Position = UDim2.fromScale(0.84, 0.74)

        oneTime.Position = UDim2.fromScale(0.395, 0.872)
        awakeningAction.Position = UDim2.fromScale(0.50, 0.872)
        domainButton.Position = UDim2.fromScale(0.605, 0.872)
    end

    local scale = gui:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Parent = gui
    end
    scale.Scale = touch and 0.96 or gamepad and 1.0 or 0.94
end

local function setButtonKeys()
    local touch = isTouch()
    local gamepad = isGamepad()
    local gamepadKeys = {"X", "Y", "RB", "LB"}

    for slot = 1, 4 do
        if touch then
            skillKeys[slot].Text = "TAP"
        elseif gamepad then
            skillKeys[slot].Text = gamepadKeys[slot]
        else
            skillKeys[slot].Text = tostring(slot)
        end
    end
end

setResponsiveLayout()
setButtonKeys()
local rosterOverlay = Instance.new("Frame")
rosterOverlay.Name = "RosterOverlay"
rosterOverlay.Size = UDim2.fromScale(0.78, 0.78)
rosterOverlay.Position = UDim2.fromScale(0.5, 0.52)
rosterOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
rosterOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
rosterOverlay.BackgroundTransparency = 0.04
rosterOverlay.BorderSizePixel = 0
rosterOverlay.Visible = false
rosterOverlay.ZIndex = 20
rosterOverlay.Parent = gui
corner(rosterOverlay, 16)
stroke(rosterOverlay, accent, 1.3, 0.28)

local rosterTitle = label(rosterOverlay, "CHOOSE FIGHTER", UDim2.fromScale(0.70, 0.08), UDim2.fromScale(0.035, 0.03), Enum.Font.GothamBlack, 20)
rosterTitle.ZIndex = 21
local rosterSub = label(rosterOverlay, "24 KITS  •  TAP TO SELECT", UDim2.fromScale(0.70, 0.05), UDim2.fromScale(0.037, 0.11), Enum.Font.Gotham, 10)
rosterSub.TextColor3 = muted
rosterSub.ZIndex = 21

local closeRoster = button(rosterOverlay, "Close", "×", UDim2.fromScale(0.065, 0.075), UDim2.fromScale(0.91, 0.025), red)
closeRoster.TextSize = 22
closeRoster.ZIndex = 21

local selectFrame = Instance.new("ScrollingFrame")
selectFrame.Name = "CharacterGrid"
selectFrame.Size = UDim2.fromScale(0.93, 0.80)
selectFrame.Position = UDim2.fromScale(0.035, 0.18)
selectFrame.BackgroundTransparency = 1
selectFrame.BorderSizePixel = 0
selectFrame.ScrollBarThickness = 4
selectFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
selectFrame.CanvasSize = UDim2.fromOffset(0, 0)
selectFrame.ZIndex = 21
selectFrame.Parent = rosterOverlay

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.238, 0, 0, 68)
grid.CellPadding = UDim2.new(0.012, 0, 0, 9)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.FillDirectionMaxCells = 4
grid.Parent = selectFrame

local ids = {}
for id in pairs(definitions) do
    table.insert(ids, id)
end
table.sort(ids)

for index, id in ipairs(ids) do
    local definition = definitions[id]
    local b = button(selectFrame, id, definition.Name, UDim2.new(), UDim2.new(), Color3.fromRGB(81, 84, 101))
    b.LayoutOrder = index
    b.TextSize = 12
    b.TextWrapped = true
    b.ZIndex = 22

    local sub = label(b, definition.Unique or "", UDim2.fromScale(0.90, 0.22), UDim2.fromScale(0.05, 0.70), Enum.Font.Gotham, 8)
    sub.TextColor3 = muted
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.ZIndex = 23

    b.Activated:Connect(function()
        selection:FireServer(id)
        rosterOverlay.Visible = false
    end)
end

rosterButton.Activated:Connect(function()
    rosterOverlay.Visible = not rosterOverlay.Visible
end)

closeRoster.Activated:Connect(function()
    rosterOverlay.Visible = false
end)

local clashFrame = Instance.new("Frame")
clashFrame.Name = "DomainClash"
clashFrame.Size = UDim2.fromScale(0.58, 0.26)
clashFrame.Position = UDim2.fromScale(0.50, 0.50)
clashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
clashFrame.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
clashFrame.BackgroundTransparency = 0.05
clashFrame.BorderSizePixel = 0
clashFrame.Visible = false
clashFrame.ZIndex = 30
clashFrame.Parent = gui
corner(clashFrame, 16)
stroke(clashFrame, gold, 1.6, 0.1)

local clashTitle = label(clashFrame, "DOMAIN CLASH", UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.06), Enum.Font.GothamBlack, 22)
clashTitle.TextXAlignment = Enum.TextXAlignment.Center
clashTitle.ZIndex = 31

local clashHint = label(clashFrame, "CHOOSE A RESPONSE", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0.29), Enum.Font.Gotham, 10)
clashHint.TextXAlignment = Enum.TextXAlignment.Center
clashHint.TextColor3 = muted
clashHint.ZIndex = 31

local clashButtons = {}
for i, moveName in ipairs({"CRUSH", "COUNTER", "FEINT", "BREAK"}) do
    local b = button(clashFrame, "Clash" .. i, tostring(i) .. "  " .. moveName, UDim2.fromScale(0.21, 0.42), UDim2.fromScale(0.025 + (i - 1) * 0.245, 0.46), accent)
    b.TextSize = 10
    b.ZIndex = 31
    clashButtons[i] = b
    b.Activated:Connect(function()
        combatAction:FireServer("ClashMove", i)
    end)
end

local stateAttributeNames = {
    "Momentum", "Infinity", "LimitlessState", "SlashState", "Shikigami", "RikaActive", "CopySlot", "WeaponMode",
    "SoulIntegrity", "SwapReady", "Jackpot", "JackpotRoll", "Blood", "ElectricalCharge", "FrameSequence",
    "TechniqueStock", "Heat", "Tide", "Roots", "Evidence", "Confiscated", "ComedyContext", "Frost",
    "Construction", "OutputCharge", "SkyDistortion", "SimpleDomain", "PerfectComboStep", "OneTimeAttackReady"
}

local function uniqueText()
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local key = player:GetAttribute("UniqueState") or ""
    local values = {
        Yuji = "Momentum " .. tostring(player:GetAttribute("Momentum") or 0),
        Gojo = (player:GetAttribute("Infinity") and "Infinity ON" or "Infinity OFF") .. " • " .. tostring(player:GetAttribute("LimitlessState") or "Neutral"),
        Sukuna = "State " .. tostring(player:GetAttribute("SlashState") or "Dismantle"),
        Megumi = tostring(player:GetAttribute("Shikigami") or "Divine Dogs"),
        Yuta = "Rika " .. (player:GetAttribute("RikaActive") and "ON" or "OFF") .. " • Copy " .. tostring(player:GetAttribute("CopySlot") or 1),
        Maki = tostring(player:GetAttribute("WeaponMode") or "Katana"),
        Toji = tostring(player:GetAttribute("WeaponMode") or "Katana"),
        Mahito = "Soul " .. tostring(math.floor(player:GetAttribute("SoulIntegrity") or 100)),
        Todo = "Swap " .. (player:GetAttribute("SwapReady") and "READY" or "USED"),
        Hakari = player:GetAttribute("Jackpot") and "JACKPOT" or ("Roll " .. tostring(player:GetAttribute("JackpotRoll") or 0)),
        Choso = "Blood " .. tostring(math.floor(player:GetAttribute("Blood") or 100)),
        Kashimo = "Charge " .. tostring(math.floor(player:GetAttribute("ElectricalCharge") or 0)),
        Naoya = "Frames " .. tostring(player:GetAttribute("FrameSequence") or 0) .. "/24",
        Kenjaku = "Stock " .. tostring(player:GetAttribute("TechniqueStock") or 0),
        Jogo = "Heat " .. tostring(math.floor(player:GetAttribute("Heat") or 0)),
        Dagon = "Tide " .. tostring(math.floor(player:GetAttribute("Tide") or 0)),
        Hanami = "Roots " .. tostring(math.floor(player:GetAttribute("Roots") or 0)),
        Higuruma = "Evidence " .. tostring(math.floor(player:GetAttribute("Evidence") or 0)),
        Takaba = "Context " .. tostring(math.floor(player:GetAttribute("ComedyContext") or 0)),
        Uraume = "Frost " .. tostring(math.floor(player:GetAttribute("Frost") or 0)),
        Yorozu = "Construction " .. tostring(player:GetAttribute("Construction") or 0),
        Ryu = "Output " .. tostring(math.floor(player:GetAttribute("OutputCharge") or 0)),
        Uro = "Sky " .. tostring(math.floor(player:GetAttribute("SkyDistortion") or 0)),
        Kusakabe = "Simple Domain " .. (player:GetAttribute("SimpleDomain") and "ON" or "OFF")
    }

    if key ~= "" then
        return key .. " • " .. (values[id] or "")
    end
    return values[id] or ""
end

local function update()
    local aw = tonumber(player:GetAttribute("Awakening") or 0) or 0
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local definition = definitions[id]
    local moveSet = movesets[id] or movesets.Yuji
    local hpRatio = healthPercent()

    for slot = 1, 4 do
        local move = moveSet[slot]
        skillNames[slot].Text = move and move.Name or ("SKILL " .. tostring(slot))
    end

    characterLabel.Text = player:GetAttribute("CharacterName") or (definition and definition.Name) or id
    uniqueLabel.Text = (definition and definition.Subtitle or "Fighter") .. " • " .. uniqueText()

    healthFill.Size = UDim2.fromScale(hpRatio, 1)
    healthText.Text = tostring(math.floor(hpRatio * 100 + 0.5)) .. "% HP"

    local awakeningRatio = math.clamp(aw / 100, 0, 1)
    awakeningFill.Size = UDim2.fromScale(awakeningRatio, 1)
    awakeningText.Text = tostring(math.floor(awakeningRatio * 100 + 0.5)) .. "%"

    local currentState = "READY"
    if player:GetAttribute("InClash") then
        currentState = "DOMAIN CLASH"
    elseif player:GetAttribute("AwakeningActive") then
        currentState = "AWAKENING"
    elseif player:GetAttribute("DomainActive") then
        currentState = "DOMAIN ACTIVE"
    elseif player:GetAttribute("ClashOpening") then
        currentState = "CLASH OPENING"
    end
    stateLabel.Text = currentState

    local hasDomain = definition and definition.Domain ~= nil
    domainButton.Text = hasDomain and "DOMAIN" or "NO DOMAIN"
    domainButton.BackgroundTransparency = hasDomain and 0.04 or 0.45
    domainButton.Active = hasDomain
    awakeningAction.Text = awakeningRatio >= 1 and "AWAKEN" or "CHARGE"
    oneTime.Text = player:GetAttribute("OneTimeAttackReady") and "OT  READY" or "OT  USED"

    local preferred = UserInputService.PreferredInput
    local touch = preferred == Enum.PreferredInput.Touch
    local gamepad = preferred == Enum.PreferredInput.Gamepad
    local gamepadKeys = {"X", "Y", "RB", "LB"}
    for slot = 1, 4 do
        if touch then
            skillKeys[slot].Text = "TAP"
        elseif gamepad then
            skillKeys[slot].Text = gamepadKeys[slot]
        else
            skillKeys[slot].Text = tostring(slot)
        end
    end
end

local function refreshCooldownHints()
    local now = os.clock()
    local function hintFor(action, labelObject, fallback)
        local remaining = math.max(0, (tonumber(gui:GetAttribute("Cooldown_" .. action)) or 0) - now)
        if remaining > 0.01 then
            labelObject.Text = string.format("%.1fs", remaining)
            labelObject.TextColor3 = muted
        else
            labelObject.Text = fallback or "READY"
            labelObject.TextColor3 = muted
        end
    end

    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        hintFor(action, skillHints[slot], "READY")
    end
end

for _, attr in ipairs({
    "Awakening", "CharacterId", "CharacterName", "CharacterTitle", "UniqueState",
    "AwakeningActive", "AwakeningName", "DomainActive", "DomainName", "InClash", "ClashOpening",
    table.unpack(stateAttributeNames)
}) do
    player:GetAttributeChangedSignal(attr):Connect(update)
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    setResponsiveLayout()
    setButtonKeys()
    update()
end)

local function bindHumanoid(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(update)
    AnimationController:StartIdleCombat(character, 1)
    update()
end

if player.Character then
    bindHumanoid(player.Character)
end
player.CharacterAdded:Connect(bindHumanoid)

local keyActions = {
    [Enum.KeyCode.R] = "Heavy",
    [Enum.KeyCode.Q] = "Dash",
    [Enum.KeyCode.F] = "BlockStart",
    [Enum.KeyCode.E] = "Dodge",
    [Enum.KeyCode.T] = "Grab",
    [Enum.KeyCode.C] = "Counter",
    [Enum.KeyCode.V] = "Slam",
    [Enum.KeyCode.One] = "Skill1",
    [Enum.KeyCode.Two] = "Skill2",
    [Enum.KeyCode.Three] = "Skill3",
    [Enum.KeyCode.Four] = "Skill4",
    [Enum.KeyCode.G] = "Awaken",
    [Enum.KeyCode.H] = "Domain",
    [Enum.KeyCode.J] = "OneTime"
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fireAction("M1", cooldownFor("M1"))
        return
    end

    local clashKeyMap = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4
    }

    local clashMove = clashKeyMap[input.KeyCode]
    if clashMove and player:GetAttribute("InClash") then
        combatAction:FireServer("ClashMove", clashMove)
        return
    end

    if input.KeyCode == Enum.KeyCode.Q then
        fireAction("Dash", cooldownFor("Dash"), InputController:GetDashDirection())
        return
    end

    local action = keyActions[input.KeyCode]
    if action then
        fireAction(action, cooldownFor(action))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        combatAction:FireServer("BlockEnd")
    end
end)

local function floatingDamage(target, amount, tag)
    if not target or not target.Parent then
        return
    end

    local head = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
    if not head then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageNumber"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(92, 42)
    billboard.StudsOffset = Vector3.new((math.random() - 0.5) * 1.2, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = head

    local value = Instance.new("TextLabel")
    value.Size = UDim2.fromScale(1, 1)
    value.BackgroundTransparency = 1
    value.Text = "-" .. tostring(math.floor(tonumber(amount) or 0))
    value.Font = Enum.Font.GothamBlack
    value.TextSize = tag == "BlackFlash" and 25 or 20
    value.TextColor3 = tag == "BlackFlash" and Color3.fromRGB(235, 235, 255) or Color3.fromRGB(255, 238, 238)
    value.TextStrokeTransparency = 0.35
    value.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
    value.Parent = billboard

    local move = TweenService:Create(
        billboard,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {StudsOffset = billboard.StudsOffset + Vector3.new(0, 1.6, 0)}
    )
    local fade = TweenService:Create(
        value,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {TextTransparency = 1, TextStrokeTransparency = 1}
    )
    move:Play()
    fade:Play()
    Debris:AddItem(billboard, 0.48)
end

local function burst(position, size, transparency, duration)
    if typeof(position) ~= "Vector3" then
        return
    end

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
    part.Material = Enum.Material.Neon
    part.Color = accentBright
    part.Transparency = transparency
    part.CFrame = CFrame.new(position)
    part.Parent = workspace.CurrentCamera

    local tween = TweenService:Create(part, TweenInfo.new(duration), {
        Size = Vector3.new(size * 2.8, size * 2.8, size * 2.8),
        Transparency = 1
    })
    tween:Play()
    Debris:AddItem(part, duration + 0.1)
end

combatFX.OnClientEvent:Connect(function(kind, position, payload, extra)
    if kind == "CharacterMove" then
        CombatVFX.CharacterMove(position, payload)
        if payload and payload.actor and payload.actor:IsA("Model") then
            if payload.action == "M1" or payload.action == "Heavy" or payload.action == "Grab" then
                AnimationController:PlayAttack(payload.actor, payload.move or payload.action, payload.combo, payload.power)
            elseif payload.action == "Dash" or payload.action == "Dodge" then
                AnimationController:PlayAttack(payload.actor, "Dash", {pulse = 1})
            else
                AnimationController:PlaySkill(payload.actor, payload.move or payload.action, {power = payload.power})
            end
        end
        return
    elseif kind == "CharacterOneTime" then
        CombatVFX.CharacterOneTime(position, payload, extra)
        return
    elseif kind == "CharacterAwakening" then
        CombatVFX.Awakening(position, payload, extra)
        return
    elseif kind == "DomainStart" then
        CombatVFX.Domain(position, payload and payload.character or payload, false)
        if payload and payload.actor and payload.actor:IsA("Model") then
            AnimationController:PlayDomain(payload.actor, {pulse = 2, entry = 0.18})
        end
        return
    elseif kind == "DomainClashStart" then
        CombatVFX.Domain(position, payload and payload.character or payload, true)
        if payload and payload.actor and payload.actor:IsA("Model") then
            AnimationController:PlayDomain(payload.actor, {pulse = 2.5, entry = 0.18})
        end
        return
    elseif kind == "Dash" or kind == "MeleeSwing" or kind == "Heavy" or kind == "Grab" or kind == "Block" or kind == "Dodge" or kind == "EnvironmentBreak" then
        CombatVFX.Utility(kind, position, payload)
        CombatSFX.Universal(kind, position)
        if kind == "Dash" or kind == "Dodge" then
            CameraController:Dash()
        elseif kind == "Heavy" then
            CameraController:Heavy()
        end
        return
    elseif kind == "Counter" then
        CameraController:Impact(0.18, 3)
        return
    elseif kind == "WallImpact" then
        CameraController:Impact(0.45, 7)
        return
    elseif kind == "DeathReaction" then
        CameraController:StrongHit()
        return
    end

    if kind == "HitReaction" then
        AnimationController:HitReact(position, payload, extra)
        if extra == "Heavy" or extra == "Launcher" or extra == "Slam" or extra == "Counter" then
            CameraController:Impact(0.15, 3)
        end
        return
    elseif kind == "DamageNumber" then
        floatingDamage(position, payload, extra)
        return
    end

    if typeof(position) ~= "Vector3" then
        return
    end

    if kind == "BlackFlash" then
        burst(position, 2.4, 0.05, 0.18)
        CameraController:StrongHit()
    elseif kind == "PerfectBlock" then
        burst(position, 1.6, 0.1, 0.12)
        CameraController:Impact(0.22, 4)
    elseif kind == "Hit" then
        burst(position, payload and payload.heavy and 1.25 or 0.9, 0.28, payload and payload.heavy and 0.12 or 0.09)
        if payload and payload.heavy then
            CameraController:Impact(0.12, 2)
        end
    elseif kind == "Awakening" then
        burst(position, 3.4, 0.18, 0.25)
    elseif kind == "DomainStart" or kind == "DomainClashStart" then
        burst(position, 5.2, 0.55, 0.45)
    elseif kind == "OneTimeAttack" then
        burst(position, 7.4, 0.3, 0.5)
    else
        burst(position, 2.5, 0.25, 0.2)
    end
end)

clashEvent.OnClientEvent:Connect(function(event, payload)
    payload = payload or {}

    if event == "ClashStart" or event == "ClashReset" then
        clashFrame.Visible = true
        clashHint.Text = "ROUND " .. tostring(payload.round or 1) .. " • CHOOSE"
        stateLabel.Text = "DOMAIN CLASH"
    elseif event == "ClashLocked" then
        clashHint.Text = "LOCKED • WAIT"
        stateLabel.Text = "CLASH LOCKED"
    elseif event == "ClashPressure" then
        clashHint.Text = "PRESSURE " .. tostring(payload.value or payload.opponent or 0)
        stateLabel.Text = "CLASH PRESSURE"
    elseif event == "ClashNeutral" then
        clashHint.Text = "NEUTRAL • RESET"
        stateLabel.Text = "CLASH NEUTRAL"
    elseif event == "ClashEnd" then
        clashFrame.Visible = false
        update()
    end
end)

serverEvent.OnClientEvent:Connect(function(event)
    if event == "BlackFlashWindow" then
        stateLabel.Text = "BLACK FLASH"
        task.delay(0.3, update)
    elseif event == "DodgeEvaded" then
        stateLabel.Text = "DODGED"
        task.delay(0.35, update)
    end
end)

task.spawn(function()
    while gui.Parent do
        refreshCooldownHints()
        task.wait(0.1)
    end
end)

update()
