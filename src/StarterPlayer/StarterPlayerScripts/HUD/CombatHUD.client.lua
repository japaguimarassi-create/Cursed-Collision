--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Theme = require(script.Parent.HUDTheme)
local InputController = require(script.Parent.Parent.Controllers.InputController)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local combatRemote = remotes and remotes:WaitForChild("CombatAction", 15)
local movementRemote = remotes and remotes:WaitForChild("MovementRemote", 15)
if not combatRemote or not movementRemote then
    return
end

local platform = Theme.Platform()
local gui = Theme.CreateGui("CursedCollisionHUD_Combat", 30)
local root = Theme.Root(gui)
Theme.ResponsiveScale(root, platform == "Mobile" and 690 or 820, 0.68, 1.10)

local blocked = function(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_SettingsOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true
end

local function fire(action: string, payload: any?)
    if blocked() then
        return
    end
    combatRemote:FireServer(action, payload)
end

local identity = Instance.new("Frame")
identity.Size = UDim2.fromScale(platform == "Mobile" and 0.54 or 0.32, 0.075)
identity.Position = UDim2.fromScale(0.50, 0.025)
identity.AnchorPoint = Vector2.new(0.5, 0)
identity.BackgroundColor3 = Theme.Colors.Surface
identity.BackgroundTransparency = 0.10
identity.BorderSizePixel = 0
identity.Parent = root
Theme.Corner(identity, 13)
Theme.Stroke(identity, 0.70)

local name = Theme.Label(identity, "Name", "Potential Man", UDim2.fromScale(0.90, 0.48), UDim2.fromScale(0.05, 0.04), 14)
name.Font = Enum.Font.GothamBlack
local title = Theme.Label(identity, "Title", "Shadow Potential", UDim2.fromScale(0.90, 0.25), UDim2.fromScale(0.05, 0.57), 8)
title.TextColor3 = Theme.Colors.Muted

local health = Instance.new("Frame")
health.Size = UDim2.fromScale(platform == "Mobile" and 0.52 or 0.29, 0.040)
health.Position = UDim2.fromScale(platform == "Mobile" and 0.50 or 0.018, platform == "Mobile" and 0.108 or 0.112)
health.AnchorPoint = Vector2.new(platform == "Mobile" and 0.5 or 0, 0)
health.BackgroundColor3 = Theme.Colors.Surface2
health.BorderSizePixel = 0
health.Parent = root
Theme.Corner(health, 8)
Theme.Stroke(health, 0.72)

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Theme.Colors.Health
healthFill.BorderSizePixel = 0
healthFill.Parent = health
Theme.Corner(healthFill, 8)

local healthText = Theme.Label(health, "Text", "100 / 100", UDim2.fromScale(1, 1), UDim2.new(), 8)
healthText.Font = Enum.Font.GothamBlack

local state = Theme.Label(root, "State", "READY", UDim2.fromScale(0.18, 0.034), UDim2.fromScale(0.50, 0.156), 8)
state.AnchorPoint = Vector2.new(0.5, 0)
state.TextColor3 = Theme.Colors.Muted
state.Font = Enum.Font.GothamBlack

local power = Instance.new("Frame")
power.Size = UDim2.fromScale(platform == "Mobile" and 0.62 or 0.58, 0.036)
power.Position = UDim2.fromScale(0.50, 0.710)
power.AnchorPoint = Vector2.new(0.5, 0.5)
power.BackgroundColor3 = Theme.Colors.Surface2
power.BorderSizePixel = 0
power.Parent = root
Theme.Corner(power, 8)
Theme.Stroke(power, 0.72)

local powerFill = Instance.new("Frame")
powerFill.Size = UDim2.fromScale(0, 1)
powerFill.BackgroundColor3 = Theme.Colors.Accent
powerFill.BorderSizePixel = 0
powerFill.Parent = power
Theme.Corner(powerFill, 8)

local powerText = Theme.Label(power, "Text", "ULTIMATE 0%", UDim2.fromScale(1, 1), UDim2.new(), 8)
powerText.Font = Enum.Font.GothamBlack

local skills = Instance.new("Frame")
skills.Size = UDim2.fromScale(platform == "Mobile" and 0.78 or 0.72, platform == "Mobile" and 0.12 or 0.13)
skills.Position = UDim2.fromScale(0.50, 0.812)
skills.AnchorPoint = Vector2.new(0.5, 0.5)
skills.BackgroundTransparency = 1
skills.Parent = root

local skillGrid = Instance.new("UIGridLayout")
skillGrid.CellSize = UDim2.new(0.235, 0, 0.90, 0)
skillGrid.CellPadding = UDim2.new(0.02, 0, 0, 0)
skillGrid.SortOrder = Enum.SortOrder.LayoutOrder
skillGrid.Parent = skills

local skillLabels: {[number]: TextLabel} = {}
local cooldownLabels: {[number]: TextLabel} = {}

local function serverCooldown(action: string): number
    local untilAt = tonumber(player:GetAttribute("CooldownUntil_" .. action)) or 0
    return math.max(0, untilAt - workspace:GetServerTimeNow())
end

for slot = 1, 4 do
    local cell = Instance.new("Frame")
    cell.BackgroundTransparency = 1
    cell.LayoutOrder = slot
    cell.Parent = skills

    local b = Theme.Button(cell, "Skill" .. slot, "", UDim2.fromScale(1, 1), UDim2.new(), platform == "Mobile" and 58 or 44)
    local hint = if platform == "Mobile"
        then tostring(slot)
        elseif platform == "Console"
        then ({[1]="RB", [2]="Y", [3]="D-UP", [4]="D-DOWN"})[slot]
        else tostring(slot)

    Theme.Label(b, "Hint", hint or "", UDim2.fromScale(0.25, 0.20), UDim2.fromScale(0.06, 0.04), 7)
    skillLabels[slot] = Theme.Label(b, "Name", "Skill " .. slot, UDim2.fromScale(0.88, 0.45), UDim2.fromScale(0.06, 0.23), 8)
    cooldownLabels[slot] = Theme.Label(b, "Cooldown", "READY", UDim2.fromScale(0.84, 0.20), UDim2.fromScale(0.08, 0.76), 7)

    b.Activated:Connect(function()
        fire("Skill" .. slot)
    end)
end

local actions = Instance.new("Frame")
actions.Size = UDim2.fromScale(platform == "Mobile" and 0.32 or 0.29, platform == "Mobile" and 0.34 or 0.31)
actions.Position = UDim2.fromScale(platform == "Mobile" and 0.78 or 0.755, 0.55)
actions.BackgroundTransparency = 1
actions.Parent = root

local m1 = Theme.Button(actions, "M1", platform == "Mobile" and "✊" or "M1", UDim2.fromScale(0.52, 0.52), UDim2.fromScale(0.58, 0.51), platform == "Mobile" and 70 or 52)
m1.AnchorPoint = Vector2.new(0.5, 0.5)
m1.TextSize = platform == "Mobile" and 28 or 20
m1.Activated:Connect(function()
    fire("M1")
end)

local block = Theme.Button(actions, "Block", platform == "Mobile" and "◉" or "BLOCK", UDim2.fromScale(0.32, 0.30), UDim2.fromScale(0.15, 0.25), platform == "Mobile" and 62 or 44)
block.AnchorPoint = Vector2.new(0.5, 0.5)
block.Activated:Connect(function()
    local active = player:GetAttribute("LocalBlocking") == true
    player:SetAttribute("LocalBlocking", not active)
    block.Text = active and (platform == "Mobile" and "◉" or "BLOCK") or (platform == "Mobile" and "◉" or "BLOCKING")
    fire(active and "BlockEnd" or "BlockStart")
end)

local dash = Theme.Button(actions, "Dash", platform == "Mobile" and "➜" or "DASH", UDim2.fromScale(0.32, 0.30), UDim2.fromScale(0.15, 0.72), platform == "Mobile" and 62 or 44)
dash.AnchorPoint = Vector2.new(0.5, 0.5)
dash.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

local sprint = Theme.Button(actions, "Sprint", platform == "Mobile" and "◇" or "SPRINT", UDim2.fromScale(0.32, 0.18), UDim2.fromScale(0.15, 0.03), platform == "Mobile" and 58 or 44)
sprint.AnchorPoint = Vector2.new(0.5, 0)
sprint.Activated:Connect(function()
    local active = player:GetAttribute("LocalSprinting") == true
    player:SetAttribute("LocalSprinting", not active)
    sprint.Text = active and (platform == "Mobile" and "◇" or "SPRINT") or (platform == "Mobile" and "◆" or "SPRINTING")
    movementRemote:FireServer(active and "SprintEnd" or "SprintStart")
end)

local special = Theme.Button(root, "Special", platform == "Mobile" and "SPECIAL" or "SPECIAL  [E]", UDim2.fromScale(platform == "Mobile" and 0.21 or 0.18, 0.060), UDim2.fromScale(0.50, 0.930), platform == "Mobile" and 58 or 44)
special.AnchorPoint = Vector2.new(0.5, 0.5)
special.Activated:Connect(function()
    fire("Special")
end)

local ultimate = Theme.Button(root, "Ultimate", platform == "Mobile" and "ULT" or "ULT [R]", UDim2.fromScale(0.135, 0.060), UDim2.fromScale(0.385, 0.930), platform == "Mobile" and 54 or 42)
ultimate.AnchorPoint = Vector2.new(0.5, 0.5)
ultimate.Activated:Connect(function()
    fire("Ultimate")
end)

local awakening = Theme.Button(root, "Awakening", platform == "Mobile" and "AWAKEN" or "AWAKEN [G]", UDim2.fromScale(0.135, 0.060), UDim2.fromScale(0.615, 0.930), platform == "Mobile" and 54 or 42)
awakening.AnchorPoint = Vector2.new(0.5, 0.5)
awakening.Activated:Connect(function()
    fire("Awakening")
end)

local function updateCharacter()
    local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    local defs = require(ReplicatedStorage.Characters.CharacterDefinitions)
    local moves = require(ReplicatedStorage.Characters.CustomMovesets).Get(id)
    local profile = defs[id]

    name.Text = profile and profile.Name or id
    title.Text = profile and profile.Subtitle or ""
    for slot = 1, 4 do
        local move = moves[slot]
        skillLabels[slot].Text = move and move.Name or ("Skill " .. slot)
    end
end

local function updateHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
    healthFill.Size = UDim2.fromScale(ratio, 1)
    healthText.Text = string.format(
        "%d / %d",
        math.floor(math.max(0, humanoid.Health) + 0.5),
        math.floor(math.max(1, humanoid.MaxHealth) + 0.5)
    )
end

local function updatePower()
    local ultimateValue = math.clamp((tonumber(player:GetAttribute("UltimateMeter")) or 0) / 100, 0, 1)
    local awakeningValue = math.clamp((tonumber(player:GetAttribute("AwakeningMeter")) or 0) / 100, 0, 1)
    local useAwakening = awakeningValue > ultimateValue
    local value = math.max(ultimateValue, awakeningValue)

    powerFill.Size = UDim2.fromScale(value, 1)
    powerFill.BackgroundColor3 = useAwakening and Theme.Colors.AccentBright or Theme.Colors.Accent
    powerText.Text = useAwakening
        and string.format("AWAKENING  %d%%", math.floor(awakeningValue * 100))
        or string.format("ULTIMATE  %d%%", math.floor(ultimateValue * 100))

    ultimate.Text = player:GetAttribute("UltimateReady") == true and "ULTIMATE READY" or "ULTIMATE"
    awakening.Text = player:GetAttribute("AwakeningReady") == true and "AWAKEN READY" or "AWAKEN"
end

local function updateState()
    local combatState = tostring(player:GetAttribute("CombatState") or "Idle")
    local display = ({
        Attacking = "ATTACK",
        UsingAbility = "SKILL",
        Blocking = "BLOCK",
        Stunned = "STUNNED",
        Ragdolled = "DOWN",
        Dashing = "DASH",
        Ultimate = "ULTIMATE",
        Awakening = "AWAKEN"
    })[combatState] or "READY"

    state.Text = display
    state.TextColor3 = (combatState == "Stunned" or combatState == "Ragdolled")
        and Theme.Colors.Health
        or Theme.Colors.Muted
end

local function updateCooldowns()
    for slot = 1, 4 do
        local left = serverCooldown("Skill" .. slot)
        cooldownLabels[slot].Text = left > 0 and string.format("%.1fs", left) or "READY"
    end
end

player:GetAttributeChangedSignal("CharacterId"):Connect(updateCharacter)
player:GetAttributeChangedSignal("UltimateMeter"):Connect(updatePower)
player:GetAttributeChangedSignal("AwakeningMeter"):Connect(updatePower)
player:GetAttributeChangedSignal("UltimateReady"):Connect(updatePower)
player:GetAttributeChangedSignal("AwakeningReady"):Connect(updatePower)
player:GetAttributeChangedSignal("CombatState"):Connect(updateState)

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
updateState()

-- Loop apenas para texto/estado de cooldown; não cria Instances a cada frame.
local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
    accumulator += dt
    if accumulator >= 0.10 then
        accumulator = 0
        updateCooldowns()
    end
end)

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    player:SetAttribute("CC_HUD_Input", tostring(UserInputService.PreferredInput))
end)
