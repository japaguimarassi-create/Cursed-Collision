--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.HUDTheme)
local Layouts = require(script.Parent.HUDLayout)
local ControlMap = require(script.Parent.ControlMap)
local InputController = require(script.Parent.Parent.Controllers.InputController)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local combatRemote = remotes and remotes:WaitForChild("CombatAction", 15)
local movementRemote = remotes and remotes:WaitForChild("MovementRemote", 15)

if not combatRemote or not movementRemote then
    return
end

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local MoveDefinitions = require(ReplicatedStorage.Characters.CustomMovesets)

local platform: ControlMap.Platform = ControlMap:GetPlatform(UserInputService.PreferredInput)
local layout = Layouts:Get(platform)

local function hint(action: string): string
    return ControlMap:GetHint(platform, action)
end

local gui = Theme.CreateGui("CursedCollisionHUD_Combat", 30)
local root = Theme.Root(gui)
Theme.ResponsiveScale(root, layout.CombatScaleReference, layout.CombatMinScale, layout.CombatMaxScale)

local function blocked(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_SettingsOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function fire(action: string, payload: any?)
    if blocked()
        or player:GetAttribute("Stunned") == true
        or player:GetAttribute("Ragdolled") == true then
        return
    end
    combatRemote:FireServer(action, payload)
end

local combatZone = Instance.new("Frame")
combatZone.Name = "CombatZone"
combatZone.Size = UDim2.fromScale(0.60, 0.30)
combatZone.Position = UDim2.fromScale(0.50, layout.SkillsY)
combatZone.AnchorPoint = Vector2.new(0.5, 1)
combatZone.BackgroundTransparency = 1
combatZone.Parent = root

local identity = Instance.new("Frame")
identity.Name = "Identity"
identity.Size = UDim2.fromScale(platform == "Mobile" and 0.62 or 0.68, 0.18)
identity.Position = UDim2.fromScale(0.50, 0.00)
identity.AnchorPoint = Vector2.new(0.5, 0)
identity.BackgroundColor3 = Theme.Colors.Surface
identity.BackgroundTransparency = 0.10
identity.BorderSizePixel = 0
identity.Parent = combatZone
Theme.Corner(identity, 11)
Theme.Stroke(identity, 0.48, 1)

local name = Theme.Label(identity, "Name", "Yuji Itadori", UDim2.fromScale(0.92, 0.56), UDim2.fromScale(0.04, 0.05), 13)
name.Font = Enum.Font.GothamBlack
local title = Theme.Label(identity, "Title", "Shibuya Vessel → Shinjuku", UDim2.fromScale(0.92, 0.25), UDim2.fromScale(0.04, 0.65), 7)
title.TextColor3 = Theme.Colors.Muted

local health = Instance.new("Frame")
health.Name = "Health"
health.Size = UDim2.fromScale(0.72, 0.10)
health.Position = UDim2.fromScale(0.50, 0.195)
health.AnchorPoint = Vector2.new(0.5, 0)
health.BackgroundColor3 = Theme.Colors.Surface2
health.BorderSizePixel = 0
health.Parent = combatZone
Theme.Corner(health, 7)
Theme.Stroke(health, 0.52)

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Theme.Colors.Health
healthFill.BorderSizePixel = 0
healthFill.Parent = health
Theme.Corner(healthFill, 7)

local healthText = Theme.Label(health, "Text", "100 / 100", UDim2.fromScale(0.98, 1), UDim2.new(), 8)
healthText.Font = Enum.Font.GothamBlack

local power = Instance.new("Frame")
power.Name = "Awakening"
power.Size = UDim2.fromScale(0.72, 0.085)
power.Position = UDim2.fromScale(0.50, 0.305)
power.AnchorPoint = Vector2.new(0.5, 0)
power.BackgroundColor3 = Theme.Colors.Surface2
power.BorderSizePixel = 0
power.Parent = combatZone
Theme.Corner(power, 7)
Theme.Stroke(power, 0.52)

local powerFill = Instance.new("Frame")
powerFill.Name = "Fill"
powerFill.Size = UDim2.fromScale(0, 1)
powerFill.BackgroundColor3 = Theme.Colors.AccentBright
powerFill.BorderSizePixel = 0
powerFill.Parent = power
Theme.Corner(powerFill, 7)

local powerText = Theme.Label(power, "Text", "AWAKENING 0%", UDim2.fromScale(0.98, 1), UDim2.new(), 7)
powerText.Font = Enum.Font.GothamBlack

local powerButton = Instance.new("TextButton")
powerButton.Name = "Activate"
powerButton.Size = UDim2.fromScale(1, 1)
powerButton.BackgroundTransparency = 1
powerButton.BorderSizePixel = 0
powerButton.Text = ""
powerButton.AutoButtonColor = false
powerButton.Active = platform ~= "PC"
powerButton.Selectable = platform ~= "PC"
powerButton.Parent = power
powerButton.Activated:Connect(function()
    if platform ~= "PC" then
        fire("Awakening")
    end
end)

local skills = Instance.new("Frame")
skills.Name = "Skills"
skills.Size = UDim2.fromScale(platform == "Mobile" and 0.78 or 0.80, 0.34)
skills.Position = UDim2.fromScale(0.50, 0.41)
skills.AnchorPoint = Vector2.new(0.5, 0)
skills.BackgroundTransparency = 1
skills.Parent = combatZone

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.24, -4, 1, 0)
grid.CellPadding = UDim2.new(0.013, 0, 0, 0)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = skills

local skillButtons: {[number]: TextButton} = {}
local skillLabels: {[number]: TextLabel} = {}
local skillHints: {[number]: TextLabel} = {}
local cooldownLabels: {[number]: TextLabel} = {}
local skillOverlays: {[number]: Frame} = {}

for slot = 1, 4 do
    local cell = Instance.new("Frame")
    cell.Name = "Slot" .. tostring(slot)
    cell.BackgroundTransparency = 1
    cell.LayoutOrder = slot
    cell.Parent = skills

    local button = Theme.Button(cell, "Button", "", UDim2.fromScale(1, 1), UDim2.new(), platform == "Mobile" and 56 or 48)
    button.Text = ""
    button.Selectable = true

    local overlay = Instance.new("Frame")
    overlay.Name = "CooldownOverlay"
    overlay.AnchorPoint = Vector2.new(0, 1)
    overlay.Position = UDim2.fromScale(0, 1)
    overlay.Size = UDim2.fromScale(1, 0)
    overlay.BackgroundColor3 = Theme.Colors.Background
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.ZIndex = button.ZIndex + 1
    overlay.Parent = button
    Theme.Corner(overlay, 14)

    local keyLabel = Theme.Label(button, "Key", hint("Skill" .. tostring(slot)), UDim2.fromScale(0.24, 0.20), UDim2.fromScale(0.07, 0.05), 8)
    keyLabel.Font = Enum.Font.GothamBlack
    skillHints[slot] = keyLabel

    skillLabels[slot] = Theme.Label(button, "Name", "SKILL " .. tostring(slot), UDim2.fromScale(0.86, 0.42), UDim2.fromScale(0.07, 0.25), platform == "Mobile" and 9 or 10)
    skillLabels[slot].Font = Enum.Font.GothamBold

    cooldownLabels[slot] = Theme.Label(button, "Cooldown", "READY", UDim2.fromScale(0.86, 0.20), UDim2.fromScale(0.07, 0.74), 7)
    cooldownLabels[slot].Font = Enum.Font.GothamBlack

    skillButtons[slot] = button
    skillOverlays[slot] = overlay

    button.Activated:Connect(function()
        fire("Skill" .. tostring(slot))
    end)
end

local actions = Instance.new("Frame")
actions.Name = "MobileActions"
actions.Size = UDim2.fromScale(0.28, 0.44)
actions.Position = UDim2.fromScale(layout.ActionsX, layout.ActionsY)
actions.AnchorPoint = Vector2.new(0.5, 0.5)
actions.BackgroundTransparency = 1
actions.Visible = platform ~= "PC"
actions.Parent = root

local function actionButton(
    nameText: string,
    label: string,
    size: number,
    position: UDim2,
    textSize: number
): TextButton
    local button = Theme.Button(actions, nameText, label, UDim2.fromOffset(size, size), position, size)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.TextSize = textSize
    return button
end

local attack = actionButton(
    "Attack",
    "✊",
    platform == "Mobile" and 72 or 64,
    UDim2.fromScale(0.70, 0.74),
    platform == "Mobile" and 24 or 20
)
local attackCaption = Theme.Label(attack, "Caption", "ATK", UDim2.fromScale(0.7, 0.18), UDim2.fromScale(0.15, 0.68), 7)
attackCaption.Font = Enum.Font.GothamBlack
attack.Activated:Connect(function()
    fire("M1")
end)

local dash = actionButton(
    "Dash",
    "➤",
    platform == "Mobile" and 56 or 50,
    UDim2.fromScale(0.31, 0.54),
    17
)
local dashCaption = Theme.Label(dash, "Caption", "DASH", UDim2.fromScale(0.74, 0.18), UDim2.fromScale(0.13, 0.67), 6)
dashCaption.Font = Enum.Font.GothamBlack
dash.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

local block = actionButton(
    "Block",
    "◇",
    platform == "Mobile" and 54 or 48,
    UDim2.fromScale(0.67, 0.22),
    18
)
local blockCaption = Theme.Label(block, "Caption", "BLOCK", UDim2.fromScale(0.74, 0.18), UDim2.fromScale(0.13, 0.67), 6)
blockCaption.Font = Enum.Font.GothamBlack
block.Activated:Connect(function()
    local active = player:GetAttribute("LocalBlocking") == true
    player:SetAttribute("LocalBlocking", not active)
    fire(active and "BlockEnd" or "BlockStart")
end)

local special = actionButton(
    "Special",
    "★",
    platform == "Mobile" and 54 or 48,
    UDim2.fromScale(0.31, 0.84),
    18
)
local specialCaption = Theme.Label(special, "Caption", "SPECIAL", UDim2.fromScale(0.82, 0.18), UDim2.fromScale(0.09, 0.67), 6)
specialCaption.Font = Enum.Font.GothamBlack
special.Activated:Connect(function()
    fire("Special")
end)

local sprint = actionButton(
    "Sprint",
    "↗",
    platform == "Mobile" and 48 or 44,
    UDim2.fromScale(0.20, 0.08),
    16
)
local sprintCaption = Theme.Label(sprint, "Caption", "RUN", UDim2.fromScale(0.70, 0.20), UDim2.fromScale(0.15, 0.65), 6)
sprintCaption.Font = Enum.Font.GothamBlack
sprint.Activated:Connect(function()
    local active = player:GetAttribute("LocalSprinting") == true
    player:SetAttribute("LocalSprinting", not active)
    movementRemote:FireServer(active and "SprintEnd" or "SprintStart")
end)

local function getMoves()
    local id = tostring(player:GetAttribute("CharacterId") or "Yuji")
    local transformed = player:GetAttribute("TransformationActive") == true
        or player:GetAttribute("AwakeningActive") == true
        or player:GetAttribute("UltimateActive") == true
    return MoveDefinitions.Get(id, transformed)
end

local function updateCharacter()
    local id = tostring(player:GetAttribute("CharacterId") or "Yuji")
    local profile = Definitions[id]
    name.Text = profile and profile.Name or id
    title.Text = profile and profile.Subtitle or ""

    local moves = getMoves()
    for slot = 1, 4 do
        local move = moves[slot]
        skillLabels[slot].Text = move and tostring(move.Name) or ("SKILL " .. tostring(slot))
    end
end

local function updateHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local maxHealth = math.max(1, humanoid.MaxHealth)
    local ratio = math.clamp(humanoid.Health / maxHealth, 0, 1)
    healthFill.Size = UDim2.fromScale(ratio, 1)
    healthText.Text = string.format("%d / %d", math.floor(humanoid.Health + 0.5), math.floor(maxHealth + 0.5))
end

local function updatePower()
    local ultimate = math.clamp((tonumber(player:GetAttribute("UltimateMeter")) or 0) / 100, 0, 1)
    local awakeningMeter = math.clamp((tonumber(player:GetAttribute("AwakeningMeter")) or 0) / 100, 0, 1)
    local value = math.max(ultimate, awakeningMeter)
    powerFill.Size = UDim2.fromScale(value, 1)

    local active = player:GetAttribute("TransformationActive") == true
    local ready = value >= 1
    powerFill.BackgroundColor3 = active and Theme.Colors.Warning or Theme.Colors.AccentBright
    powerText.Text = active
        and "TRANSFORMAÇÃO ATIVA"
        or ready
            and (platform == "Mobile" and "TOQUE PARA DESPERTAR" or "DESPERTAR PRONTO")
            or string.format("DESPERTAR  %d%%", math.floor(value * 100))
end

local function updateCooldowns()
    for slot = 1, 4 do
        local action = "Skill" .. tostring(slot)
        local untilAt = tonumber(player:GetAttribute("CooldownUntil_" .. action)) or 0
        local left = math.max(0, untilAt - workspace:GetServerTimeNow())
        local ratio = math.clamp(left / 15, 0, 1)

        cooldownLabels[slot].Text = left > 0
            and string.format("%.1f", left)
            or "READY"
        skillOverlays[slot].Size = UDim2.fromScale(1, ratio)
        cooldownLabels[slot].TextColor3 = left > 0
            and Theme.Colors.Muted
            or Theme.Colors.Success
    end
end

local function refreshPlatform()
    platform = ControlMap:GetPlatform(UserInputService.PreferredInput)
    layout = Layouts:Get(platform)

    actions.Visible = platform ~= "PC"
    powerButton.Active = platform ~= "PC"
    powerButton.Selectable = platform ~= "PC"

    for slot = 1, 4 do
        skillHints[slot].Text = ControlMap:GetHint(platform, "Skill" .. tostring(slot))
    end

end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshPlatform)

player:GetAttributeChangedSignal("CharacterId"):Connect(updateCharacter)
player:GetAttributeChangedSignal("TransformationActive"):Connect(updateCharacter)
player:GetAttributeChangedSignal("AwakeningActive"):Connect(updateCharacter)
player:GetAttributeChangedSignal("UltimateActive"):Connect(updateCharacter)
player:GetAttributeChangedSignal("UltimateMeter"):Connect(updatePower)
player:GetAttributeChangedSignal("AwakeningMeter"):Connect(updatePower)

player.CharacterAdded:Connect(function(character)
    task.defer(updateHealth)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.HealthChanged:Connect(updateHealth)
    end
end)

if player.Character then
    task.defer(updateHealth)
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(updateHealth)
    end
end

updateCharacter()
updateHealth()
updatePower()
refreshPlatform()

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
    accumulator += dt
    if accumulator >= 0.08 then
        accumulator = 0
        updateCooldowns()
    end
end)
