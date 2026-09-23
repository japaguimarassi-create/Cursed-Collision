--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputManager = require(script.Parent.Parent.Controllers.InputManager)
local InputController = require(script.Parent.Parent.Controllers.InputController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local combatRemote = remotes and remotes:WaitForChild("CombatAction", 15)
local movementRemote = remotes and remotes:WaitForChild("MovementRemote", 15)

if not combatRemote or not movementRemote then
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD_Combat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 5
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local COLORS = {
    Background = Color3.fromRGB(8, 10, 15),
    Panel = Color3.fromRGB(18, 21, 29),
    PanelPressed = Color3.fromRGB(31, 29, 43),
    Stroke = Color3.fromRGB(77, 80, 98),
    Text = Color3.fromRGB(242, 243, 248),
    Muted = Color3.fromRGB(157, 160, 177),
    Accent = Color3.fromRGB(156, 116, 255),
    Accent2 = Color3.fromRGB(99, 194, 255),
    Danger = Color3.fromRGB(218, 69, 87),
    Ready = Color3.fromRGB(102, 222, 151)
}

local refs = {
    healthFill = nil :: Frame?,
    healthText = nil :: TextLabel?,
    stateText = nil :: TextLabel?,
    powerFill = nil :: Frame?,
    powerText = nil :: TextLabel?,
    skillButtons = {} :: {[number]: TextButton},
    skillLabels = {} :: {[number]: TextLabel},
    skillCooldown = {} :: {[number]: TextLabel},
    actionButtons = {} :: {[string]: TextButton}
}

local function platform(): "Mobile" | "Console" | "PC"
    if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
        return "Mobile"
    elseif UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        return "Console"
    end
    return "PC"
end

local function corner(object: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end

local function stroke(object: GuiObject, transparency: number, thickness: number?)
    local s = Instance.new("UIStroke")
    s.Color = COLORS.Stroke
    s.Transparency = transparency
    s.Thickness = thickness or 1
    s.Parent = object
end

local function label(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number, font: Enum.Font?): TextLabel
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = size
    l.Position = position
    l.Text = text
    l.TextColor3 = COLORS.Text
    l.Font = font or Enum.Font.GothamBold
    l.TextSize = textSize
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = math.max(7, math.floor(textSize * 0.68))
    constraint.MaxTextSize = textSize
    constraint.Parent = l

    return l
end

local function button(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, minimum: number): TextButton
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.Position = position
    b.Text = text
    b.TextColor3 = COLORS.Text
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 12
    b.TextWrapped = true
    b.BackgroundColor3 = COLORS.Panel
    b.BackgroundTransparency = 0.07
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 14)
    stroke(b, 0.44)

    local minSize = Instance.new("UISizeConstraint")
    minSize.MinSize = Vector2.new(minimum, minimum)
    minSize.Parent = b

    b.MouseButton1Down:Connect(function()
        b.BackgroundColor3 = COLORS.PanelPressed
    end)
    b.MouseButton1Up:Connect(function()
        b.BackgroundColor3 = COLORS.Panel
    end)

    return b
end

local function safeAction(action: string, payload: any?)
    if player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true then
        return
    end

    combatRemote:FireServer(action, payload)
end

local function cooldownRemaining(action: string): number
    local until = tonumber(player:GetAttribute("CooldownUntil_" .. action)) or 0
    return math.max(0, until - workspace:GetServerTimeNow())
end

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local size = camera.ViewportSize
    local shortAxis = math.min(size.X, size.Y)
    local p = platform()
    local base = if p == "Mobile" then 680 elseif p == "Console" then 900 else 820
    scale.Scale = math.clamp(shortAxis / base, 0.72, 1.10)
end

local function updateCharacter()
    local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local moves = Movesets.Get(id)

    for slot = 1, 4 do
        local move = moves[slot]
        refs.skillLabels[slot].Text = tostring(move and move.Name or ("Skill " .. slot))
    end
end

local function updateHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not refs.healthFill or not refs.healthText then
        return
    end

    local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
    refs.healthFill.Size = UDim2.fromScale(ratio, 1)
    refs.healthText.Text = string.format(
        "%d / %d",
        math.floor(math.max(0, humanoid.Health) + 0.5),
        math.floor(math.max(1, humanoid.MaxHealth) + 0.5)
    )
end

local function updateState()
    if not refs.stateText then
        return
    end

    local state = tostring(player:GetAttribute("CombatState") or "Idle")
    refs.stateText.Text = ({
        Attacking = "ATTACK",
        UsingAbility = "SKILL",
        Blocking = "BLOCK",
        Stunned = "STUNNED",
        Ragdolled = "DOWN",
        Dashing = "DASH",
        Ultimate = "ULTIMATE",
        Awakening = "AWAKEN"
    })[state] or "READY"

    refs.stateText.TextColor3 =
        (state == "Stunned" or state == "Ragdolled")
        and COLORS.Danger
        or COLORS.Muted
end

local function updatePower()
    if not refs.powerFill or not refs.powerText then
        return
    end

    local ultimate = math.clamp((tonumber(player:GetAttribute("UltimateMeter")) or 0) / 100, 0, 1)
    local awakening = math.clamp((tonumber(player:GetAttribute("AwakeningMeter")) or 0) / 100, 0, 1)
    local awakeningMode = awakening > ultimate
    local value = math.max(ultimate, awakening)

    refs.powerFill.Size = UDim2.fromScale(value, 1)
    refs.powerFill.BackgroundColor3 = awakeningMode and Color3.fromRGB(255, 92, 175) or COLORS.Accent
    refs.powerText.Text = awakeningMode
        and string.format("AWAKENING  %d%%", math.floor(awakening * 100))
        or string.format("ULTIMATE  %d%%", math.floor(ultimate * 100))
end

local function updateButtons()
    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        local left = cooldownRemaining(action)
        local cooldown = refs.skillCooldown[slot]
        if cooldown then
            cooldown.Text = left > 0 and string.format("%.1fs", left) or "READY"
            refs.skillButtons[slot].BackgroundColor3 = left > 0
                and COLORS.Background
                or COLORS.Panel
        end
    end

    for action, b in pairs(refs.actionButtons) do
        local left = cooldownRemaining(action)
        if left > 0 then
            b.TextColor3 = COLORS.Muted
        else
            b.TextColor3 = COLORS.Text
        end
    end
end

local function bindHealth(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    humanoid.HealthChanged:Connect(updateHealth)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
    updateHealth()
end

local function build()
    local p = platform()

    local top = Instance.new("Frame")
    top.Name = "CombatTop"
    top.Size = UDim2.fromScale(p == "Mobile" and 0.54 or 0.34, 0.075)
    top.Position = UDim2.fromScale(0.50, 0.022)
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.BackgroundColor3 = COLORS.Background
    top.BackgroundTransparency = 0.12
    top.Parent = root
    corner(top, 12)
    stroke(top, 0.72)

    local characterName = label(top, "Potential Man", UDim2.fromScale(0.88, 0.45), UDim2.fromScale(0.06, 0.06), 14, Enum.Font.GothamBlack)
    local characterTitle = label(top, "Shadow Potential", UDim2.fromScale(0.86, 0.26), UDim2.fromScale(0.07, 0.57), 8)
    characterTitle.TextColor3 = COLORS.Muted

    local health = Instance.new("Frame")
    health.Name = "Health"
    health.Size = UDim2.fromScale(p == "Mobile" and 0.48 or 0.30, 0.040)
    health.Position = UDim2.fromScale(p == "Mobile" and 0.50 or 0.018, p == "Mobile" and 0.108 or 0.11)
    health.AnchorPoint = Vector2.new(p == "Mobile" and 0.5 or 0, 0)
    health.BackgroundColor3 = Color3.fromRGB(37, 39, 49)
    health.BorderSizePixel = 0
    health.Parent = root
    corner(health, 8)
    stroke(health, 0.74)

    refs.healthFill = Instance.new("Frame")
    refs.healthFill.Size = UDim2.fromScale(1, 1)
    refs.healthFill.BackgroundColor3 = COLORS.Danger
    refs.healthFill.BorderSizePixel = 0
    refs.healthFill.Parent = health
    corner(refs.healthFill, 8)
    refs.healthText = label(health, "100 / 100", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 8, Enum.Font.GothamBlack)

    local stateFrame = Instance.new("Frame")
    stateFrame.Size = UDim2.fromScale(0.17, 0.034)
    stateFrame.Position = UDim2.fromScale(0.50, 0.150)
    stateFrame.AnchorPoint = Vector2.new(0.5, 0)
    stateFrame.BackgroundColor3 = COLORS.Background
    stateFrame.BackgroundTransparency = 0.22
    stateFrame.Parent = root
    corner(stateFrame, 7)
    stroke(stateFrame, 0.77)
    refs.stateText = label(stateFrame, "READY", UDim2.fromScale(1, 1), UDim2.new(), 8, Enum.Font.GothamBlack)

    local meter = Instance.new("Frame")
    meter.Name = "Power"
    meter.Size = UDim2.fromScale(p == "Mobile" and 0.60 or 0.58, 0.035)
    meter.Position = UDim2.fromScale(0.50, 0.705)
    meter.AnchorPoint = Vector2.new(0.5, 0.5)
    meter.BackgroundColor3 = Color3.fromRGB(37, 39, 49)
    meter.BorderSizePixel = 0
    meter.Parent = root
    corner(meter, 8)
    stroke(meter, 0.76)

    refs.powerFill = Instance.new("Frame")
    refs.powerFill.Size = UDim2.fromScale(0, 1)
    refs.powerFill.BackgroundColor3 = COLORS.Accent
    refs.powerFill.BorderSizePixel = 0
    refs.powerFill.Parent = meter
    corner(refs.powerFill, 8)
    refs.powerText = label(meter, "ULTIMATE  0%", UDim2.fromScale(1, 1), UDim2.new(), 8, Enum.Font.GothamBlack)

    local skills = Instance.new("Frame")
    skills.Name = "Skills"
    skills.Size = UDim2.fromScale(p == "Mobile" and 0.78 or 0.74, p == "Mobile" and 0.115 or 0.120)
    skills.Position = UDim2.fromScale(0.50, 0.805)
    skills.AnchorPoint = Vector2.new(0.5, 0.5)
    skills.BackgroundTransparency = 1
    skills.Parent = root

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.235, 0, 0.92, 0)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 0)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = skills

    for slot = 1, 4 do
        local cell = Instance.new("Frame")
        cell.LayoutOrder = slot
        cell.BackgroundTransparency = 1
        cell.Parent = skills

        local b = button(cell, "Skill" .. slot, tostring(slot), UDim2.fromScale(1, 1), UDim2.new(), p == "Mobile" and 58 or 42)
        refs.skillButtons[slot] = b

        local hintText = if p == "Mobile"
            then tostring(slot)
            elseif p == "Console"
            then ({[1]="RB",[2]="Y",[3]="D-UP",[4]="D-DOWN"})[slot]
            else ({[1]="1",[2]="2",[3]="3",[4]="4"})[slot]

        label(b, hintText or "", UDim2.fromScale(0.26, 0.20), UDim2.fromScale(0.06, 0.05), 7, Enum.Font.GothamBlack)
        refs.skillLabels[slot] = label(b, "Skill " .. slot, UDim2.fromScale(0.88, 0.42), UDim2.fromScale(0.06, 0.25), 8, Enum.Font.GothamBold)
        refs.skillCooldown[slot] = label(b, "READY", UDim2.fromScale(0.86, 0.19), UDim2.fromScale(0.07, 0.76), 7, Enum.Font.GothamBlack)

        b.Activated:Connect(function()
            safeAction("Skill" .. slot)
        end)
    end

    local actions = Instance.new("Frame")
    actions.Name = "Actions"
    actions.Size = UDim2.fromScale(p == "Mobile" and 0.31 or 0.29, p == "Mobile" and 0.36 or 0.31)
    actions.Position = UDim2.fromScale(p == "Mobile" and 0.79 or 0.75, 0.54)
    actions.BackgroundTransparency = 1
    actions.Parent = root

    local m1Size = p == "Mobile" and 0.52 or 0.50
    local m1 = button(actions, "M1", p == "Mobile" and "✊" or "M1", UDim2.fromScale(m1Size, m1Size), UDim2.fromScale(0.58, 0.52), p == "Mobile" and 70 or 52)
    m1.AnchorPoint = Vector2.new(0.5, 0.5)
    if p == "Mobile" then
        m1.TextSize = 28
    else
        m1.TextSize = 20
    end
    refs.actionButtons.M1 = m1
    m1.Activated:Connect(function()
        safeAction("M1")
    end)

    local block = button(actions, "Block", p == "Mobile" and "◉" or "BLOCK", UDim2.fromScale(0.31, 0.31), UDim2.fromScale(0.16, 0.22), p == "Mobile" and 60 or 42)
    block.AnchorPoint = Vector2.new(0.5, 0.5)
    refs.actionButtons.BlockStart = block
    block.Activated:Connect(function()
        safeAction("BlockStart")
    end)

    local dash = button(actions, "Dash", p == "Mobile" and "➜" or "DASH", UDim2.fromScale(0.31, 0.31), UDim2.fromScale(0.16, 0.70), p == "Mobile" and 60 or 42)
    dash.AnchorPoint = Vector2.new(0.5, 0.5)
    refs.actionButtons.Dash = dash
    dash.Activated:Connect(function()
        safeAction("Dash", InputController:GetDashDirection())
    end)

    local sprint = button(actions, "Sprint", p == "Mobile" and "◇" or "SPRINT", UDim2.fromScale(0.31, 0.19), UDim2.fromScale(0.16, 0.04), p == "Mobile" and 56 or 42)
    sprint.AnchorPoint = Vector2.new(0.5, 0)
    sprint.Activated:Connect(function()
        local active = player:GetAttribute("LocalSprinting") == true
        player:SetAttribute("LocalSprinting", not active)
        movementRemote:FireServer(active and "SprintEnd" or "SprintStart")
        sprint.Text = active and (p == "Mobile" and "◇" or "SPRINT") or (p == "Mobile" and "◆" or "SPRINTING")
    end)

    local special = button(root, "Special", p == "Mobile" and "SPECIAL" or "SPECIAL\nE", UDim2.fromScale(p == "Mobile" and 0.20 or 0.17, 0.060), UDim2.fromScale(0.50, 0.925), p == "Mobile" and 58 or 44)
    special.AnchorPoint = Vector2.new(0.5, 0.5)
    refs.actionButtons.Special = special
    special.Activated:Connect(function()
        safeAction("Special")
    end)

    local ultimate = button(root, "Ultimate", p == "Mobile" and "ULT" or "ULTIMATE\nR3", UDim2.fromScale(0.14, 0.060), UDim2.fromScale(0.385, 0.925), p == "Mobile" and 54 or 42)
    ultimate.AnchorPoint = Vector2.new(0.5, 0.5)
    ultimate.Activated:Connect(function()
        safeAction("Ultimate")
    end)

    local awaken = button(root, "Awakening", p == "Mobile" and "AWAKEN" or "AWAKEN\nL3", UDim2.fromScale(0.14, 0.060), UDim2.fromScale(0.615, 0.925), p == "Mobile" and 54 or 42)
    awaken.AnchorPoint = Vector2.new(0.5, 0.5)
    awaken.Activated:Connect(function()
        safeAction("Awakening")
    end)

    if p == "Console" then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = m1
    end

    updateCharacter()

    local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local profile = Definitions[id]
    characterName.Text = tostring(profile and profile.Name or id)
    characterTitle.Text = tostring(profile and profile.Subtitle or "")

    player:GetAttributeChangedSignal("CharacterId"):Connect(function()
        local newId = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
        local newProfile = Definitions[newId]
        characterName.Text = tostring(newProfile and newProfile.Name or newId)
        characterTitle.Text = tostring(newProfile and newProfile.Subtitle or "")
        updateCharacter()
    end)
end

build()

updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(updateScale)
end)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateScale)

for _, attribute in ipairs({
    "CombatState",
    "UltimateMeter",
    "AwakeningMeter",
    "CooldownUntil_M1",
    "CooldownUntil_Dash",
    "CooldownUntil_Special",
    "CooldownUntil_Skill1",
    "CooldownUntil_Skill2",
    "CooldownUntil_Skill3",
    "CooldownUntil_Skill4"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(
        if string.find(attribute, "CooldownUntil_", 1, true)
        then updateButtons
        elseif attribute == "CombatState"
        then updateState
        else updatePower
    )
end

player.CharacterAdded:Connect(bindHealth)
if player.Character then
    task.defer(bindHealth, player.Character)
end

RunService.RenderStepped:Connect(function()
    updateHealth()
    updateButtons()
end)

for action, keyCodes in pairs({
    M1 = {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2},
    Dash = {Enum.KeyCode.Q, Enum.KeyCode.ButtonA},
    Special = {Enum.KeyCode.E, Enum.KeyCode.ButtonX},
    Ultimate = {Enum.KeyCode.R, Enum.KeyCode.ButtonR3},
    Awakening = {Enum.KeyCode.G, Enum.KeyCode.ButtonL3}
}) do
    InputManager:BindAction(
        "CC_HUD_" .. action,
        function(_, state)
            if state == Enum.UserInputState.Begin then
                safeAction(action, action == "Dash" and InputController:GetDashDirection() or nil)
            end
        end,
        keyCodes,
        false
    )
end

InputManager:BindAction(
    "CC_HUD_Block",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            safeAction("BlockStart")
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            safeAction("BlockEnd")
        end
    end,
    {Enum.KeyCode.F, Enum.KeyCode.ButtonL2},
    false
)

InputManager:BindAction(
    "CC_HUD_Sprint",
    function(_, state)
        if state == Enum.UserInputState.Begin then
            player:SetAttribute("LocalSprinting", true)
            movementRemote:FireServer("SprintStart")
        elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
            player:SetAttribute("LocalSprinting", false)
            movementRemote:FireServer("SprintEnd")
        end
    end,
    {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL1},
    false
)

for slot, key in ipairs({Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}) do
    InputManager:BindAction(
        "CC_HUD_Skill" .. slot,
        function(_, state)
            if state == Enum.UserInputState.Begin then
                safeAction("Skill" .. slot)
            end
        end,
        {key},
        false
    )
end

updateHealth()
updatePower()
updateState()
updateButtons()
