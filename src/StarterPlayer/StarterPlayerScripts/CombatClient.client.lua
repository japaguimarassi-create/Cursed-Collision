--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CharacterMoves = require(ReplicatedStorage.Characters.CharacterMoves)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Controllers.InputController)
local ProceduralAnimator = require(script.Parent.Controllers.ProceduralAnimator)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local combatAction = remotes:WaitForChild("CombatAction", 15)
local combatFX = remotes:WaitForChild("CombatFX", 15)

if not combatAction or not combatFX then
    return
end

local oldGui = playerGui:FindFirstChild("CursedCollisionCombatHUD")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionCombatHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local function refreshScale()
    local camera = workspace.CurrentCamera
    if camera then
        scale.Scale = math.clamp(camera.ViewportSize.Y / 800, 0.82, 1.15)
    end
end

refreshScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshScale)

local function corner(object: GuiObject, radius: number)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius)
    ui.Parent = object
end

local function stroke(object: GuiObject, transparency: number)
    local ui = Instance.new("UIStroke")
    ui.Thickness = 1
    ui.Transparency = transparency
    ui.Parent = object
end

local function button(parent: Instance, name: string, textValue: string, size: UDim2, position: UDim2)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.Position = position
    b.Text = textValue
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(240, 241, 246)
    b.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
    b.BackgroundTransparency = 0.04
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 13)
    stroke(b, 0.52)
    return b
end

local function label(parent: Instance, textValue: string, size: UDim2, position: UDim2, textSize: number)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize
    object.TextColor3 = Color3.fromRGB(235, 236, 242)
    object.TextWrapped = true
    object.Parent = parent
    return object
end

local identity = Instance.new("Frame")
identity.Name = "Identity"
identity.Size = UDim2.fromScale(0.26, 0.065)
identity.Position = UDim2.fromScale(0.50, 0.026)
identity.AnchorPoint = Vector2.new(0.5, 0)
identity.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
identity.BackgroundTransparency = 0.20
identity.Parent = root
corner(identity, 10)
stroke(identity, 0.72)

local nameLabel = label(identity, "Potential Man", UDim2.fromScale(0.94, 0.53), UDim2.fromScale(0.03, 0.05), 13)
nameLabel.TextXAlignment = Enum.TextXAlignment.Center

local titleLabel = label(identity, "Shadow Potential", UDim2.fromScale(0.94, 0.27), UDim2.fromScale(0.03, 0.61), 7)
titleLabel.TextColor3 = Color3.fromRGB(150, 154, 168)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local healthBar = Instance.new("Frame")
healthBar.Name = "HealthBar"
healthBar.Size = UDim2.fromScale(0.29, 0.032)
healthBar.Position = UDim2.fromScale(0.018, 0.122)
healthBar.BackgroundColor3 = Color3.fromRGB(37, 39, 49)
healthBar.BorderSizePixel = 0
healthBar.Parent = root
corner(healthBar, 8)
stroke(healthBar, 0.72)

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(210, 70, 86)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBar
corner(healthFill, 8)

local healthText = label(healthBar, "100 / 100", UDim2.fromScale(1, 1), UDim2.new(), 8)
healthText.TextXAlignment = Enum.TextXAlignment.Center

local status = Instance.new("Frame")
status.Name = "Status"
status.Size = UDim2.fromScale(0.18, 0.042)
status.Position = UDim2.fromScale(0.50, 0.10)
status.AnchorPoint = Vector2.new(0.5, 0)
status.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
status.BackgroundTransparency = 0.22
status.Parent = root
corner(status, 9)
stroke(status, 0.78)

local stateLabel = label(status, "READY", UDim2.fromScale(1, 1), UDim2.new(), 9)
stateLabel.TextXAlignment = Enum.TextXAlignment.Center

local awakening = Instance.new("Frame")
awakening.Name = "AwakeningBar"
awakening.Size = UDim2.fromScale(0.58, 0.038)
awakening.Position = UDim2.fromScale(0.50, 0.725)
awakening.AnchorPoint = Vector2.new(0.5, 0.5)
awakening.BackgroundColor3 = Color3.fromRGB(37, 39, 49)
awakening.BorderSizePixel = 0
awakening.Parent = root
corner(awakening, 8)
stroke(awakening, 0.72)

local awakeningFill = Instance.new("Frame")
awakeningFill.Name = "Fill"
awakeningFill.Size = UDim2.fromScale(0, 1)
awakeningFill.BackgroundColor3 = Color3.fromRGB(155, 112, 255)
awakeningFill.BorderSizePixel = 0
awakeningFill.Parent = awakening
corner(awakeningFill, 8)

local awakeningName = label(awakening, "ULTIMATE", UDim2.fromScale(1, 1), UDim2.new(), 8)
awakeningName.TextXAlignment = Enum.TextXAlignment.Center
awakeningName.TextColor3 = Color3.fromRGB(205, 207, 218)

local skillFrame = Instance.new("Frame")
skillFrame.Name = "Skills"
skillFrame.Size = UDim2.fromScale(0.76, 0.125)
skillFrame.Position = UDim2.fromScale(0.50, 0.825)
skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skillFrame.BackgroundTransparency = 1
skillFrame.Parent = root

local skillButtons = {}
local skillCooldowns = {}

for slot = 1, 4 do
    local x = (slot - 0.5) / 4
    local skillButton = button(
        skillFrame,
        "Skill" .. tostring(slot),
        tostring(slot),
        UDim2.fromScale(0.235, 0.87),
        UDim2.fromScale(x, 0.06)
    )

    skillButton.AnchorPoint = Vector2.new(0.5, 0)
    skillButton.TextSize = 10
    skillButtons[slot] = skillButton

    local cooldown = label(
        skillButton,
        "READY",
        UDim2.fromScale(0.88, 0.22),
        UDim2.fromScale(0.06, 0.73),
        7
    )

    cooldown.TextXAlignment = Enum.TextXAlignment.Center
    cooldown.TextColor3 = Color3.fromRGB(150, 154, 168)
    skillCooldowns[slot] = cooldown
end

local actionFrame = Instance.new("Frame")
actionFrame.Name = "Actions"
actionFrame.Size = UDim2.fromScale(0.31, 0.30)
actionFrame.Position = UDim2.fromScale(0.725, 0.54)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = root

local m1 = button(actionFrame, "M1", "M1", UDim2.fromScale(0.46, 0.46), UDim2.fromScale(0.63, 0.50))
m1.AnchorPoint = Vector2.new(0.5, 0.5)
m1.TextSize = 22

local dash = button(actionFrame, "Dash", "DASH", UDim2.fromScale(0.34, 0.20), UDim2.fromScale(0.18, 0.63))
dash.AnchorPoint = Vector2.new(0.5, 0.5)

local block = button(actionFrame, "Block", "BLOCK", UDim2.fromScale(0.34, 0.20), UDim2.fromScale(0.18, 0.34))
block.AnchorPoint = Vector2.new(0.5, 0.5)

local special = button(root, "Special", "SPECIAL", UDim2.fromScale(0.18, 0.066), UDim2.fromScale(0.50, 0.935))
special.AnchorPoint = Vector2.new(0.5, 0.5)
special.TextSize = 10

local ultimateButton = button(
    root,
    "Ultimate",
    "ULTIMATE",
    UDim2.fromScale(0.14, 0.066),
    UDim2.fromScale(0.39, 0.935)
)
ultimateButton.AnchorPoint = Vector2.new(0.5, 0.5)
ultimateButton.TextSize = 9

local awakeningButton = button(
    root,
    "Awakening",
    "AWAKEN",
    UDim2.fromScale(0.14, 0.066),
    UDim2.fromScale(0.61, 0.935)
)
awakeningButton.AnchorPoint = Vector2.new(0.5, 0.5)
awakeningButton.TextSize = 9

local localCooldowns: {[string]: number} = {}

local function remaining(action: string): number
    return math.max(0, (localCooldowns[action] or 0) - os.clock())
end

local function moveCooldown(action: string): number
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    elseif action == "Dash" then
        return Config.Combat.Dash.Cooldown
    elseif action == "Special" then
        return Config.Combat.Special.Cooldown
    end

    local slot = tonumber(string.sub(action, 6))
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    local move = slot and CustomMovesets.GetMove(id, slot)

    return math.clamp(
        tonumber(move and move.Cooldown) or 1,
        Config.Combat.Skill.MinCooldown,
        Config.Combat.Skill.MaxCooldown
    )
end

local function fire(action: string, payload: any)
    if player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true then
        return
    end

    if action ~= "BlockStart"
        and action ~= "BlockEnd"
        and remaining(action) > 0 then
        return
    end

    local duration = if action == "BlockStart" or action == "BlockEnd"
        then 0
        else moveCooldown(action)

    if duration > 0 then
        localCooldowns[action] = os.clock() + duration
    end

    combatAction:FireServer(action, payload)
end

local function refreshCharacter()
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    local profile = Definitions[id]
    local moves = CustomMovesets.Get(id)

    nameLabel.Text = profile and profile.Name or id
    titleLabel.Text = profile and profile.Subtitle or ""

    for slot = 1, 4 do
        local move = moves[slot]
        skillButtons[slot].Text = tostring(slot) .. "\n" .. (move and move.Name or "Skill")
    end

    local specialName = CharacterMoves[id] and CharacterMoves[id].SpecialName or "SPECIAL"
    special.Text = specialName .. "\nSPECIAL"

    awakeningName.Text = (profile and (profile.AwakeningName or profile.OneTimeName) or "ULTIMATE") .. "  •  ULTIMATE"
    localCooldowns = {}
end

local function setBlocking(active: boolean)
    player:SetAttribute("LocalBlocking", active)
    block.Text = active and "BLOCKING" or "BLOCK"
    fire(active and "BlockStart" or "BlockEnd")
end

local function activatePower(action: string)
    if player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true then
        return
    end

    combatAction:FireServer(action)
end

ultimateButton.Activated:Connect(function()
    activatePower("Ultimate")
end)

awakeningButton.Activated:Connect(function()
    activatePower("Awakening")
end)

local function readHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
    healthFill.Size = UDim2.fromScale(ratio, 1)
    healthText.Text = string.format(
        "%d / %d",
        math.max(0, math.floor(humanoid.Health + 0.5)),
        math.max(1, math.floor(humanoid.MaxHealth + 0.5))
    )
end

local function bindHealth()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    humanoid.HealthChanged:Connect(readHealth)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(readHealth)
    readHealth()
end

local function readPowerMeters()
    local ultimate = math.clamp(
        (tonumber(player:GetAttribute("UltimateMeter")) or 0) / 100,
        0,
        1
    )

    local awakeningValue = math.clamp(
        (tonumber(player:GetAttribute("AwakeningMeter")) or 0) / 100,
        0,
        1
    )

    awakeningFill.Size = UDim2.fromScale(ultimate, 1)
    awakeningName.Text = ultimate >= 1
        and "ULTIMATE READY"
        or string.format("ULTIMATE %d%%", math.floor(ultimate * 100))

    ultimateButton.Text = player:GetAttribute("UltimateReady") == true
        and "ULTIMATE\nREADY"
        or "ULTIMATE"

    awakeningButton.Text = player:GetAttribute("AwakeningReady") == true
        and "AWAKEN\nREADY"
        or "AWAKEN"

    if awakeningValue > ultimate then
        awakeningFill.BackgroundColor3 = Color3.fromRGB(255, 94, 177)
        awakeningFill.Size = UDim2.fromScale(awakeningValue, 1)
    else
        awakeningFill.BackgroundColor3 = Color3.fromRGB(155, 112, 255)
    end
end

bindHealth()

for slot = 1, 4 do
    skillButtons[slot].Activated:Connect(function()
        fire("Skill" .. tostring(slot))
    end)
end

m1.Activated:Connect(function()
    fire("M1")
end)

dash.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

block.Activated:Connect(function()
    setBlocking(player:GetAttribute("LocalBlocking") ~= true)
end)

special.Activated:Connect(function()
    fire("Special")
end)

local keySkills = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or player:GetAttribute("CCHUD_MenuOpen") == true then
        return
    end

    local slot = keySkills[input.KeyCode]
    if slot then
        fire("Skill" .. tostring(slot))
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fire("M1")
        return
    end

    if input.KeyCode == Enum.KeyCode.Q then
        fire("Dash", InputController:GetDashDirection())
        return
    end

    if input.KeyCode == Enum.KeyCode.E then
        fire("Special")
        return
    end

    if input.KeyCode == Enum.KeyCode.F
        and player:GetAttribute("LocalBlocking") ~= true then
        setBlocking(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and player:GetAttribute("LocalBlocking") == true then
        setBlocking(false)
    end
end)

player.CharacterAdded:Connect(function(_character)
    bindHealth()
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)

local function hideForMenu()
    local hidden =
        player:GetAttribute("CCHUD_MenuOpen") == true
        or player:GetAttribute("CCHUD_CharacterMenuOpen") == true
        or player:GetAttribute("CCHUD_EmoteWheelOpen") == true
        or player:GetAttribute("CCHUD_OwnerPanelOpen") == true

    root.Visible = not hidden

    if hidden and player:GetAttribute("LocalBlocking") == true then
        player:SetAttribute("LocalBlocking", false)
        block.Text = "BLOCK"
        combatAction:FireServer("BlockEnd")
    end
end

for _, attribute in ipairs({
    "CCHUD_MenuOpen",
    "CCHUD_CharacterMenuOpen",
    "CCHUD_EmoteWheelOpen",
    "CCHUD_OwnerPanelOpen"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(hideForMenu)
end

local function readAwakening()
    local value = tonumber(player:GetAttribute("AwakeningMeter"))
        or tonumber(player:GetAttribute("AwakeningProgress"))
        or 0
    awakeningFill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)
end

player:GetAttributeChangedSignal("AwakeningMeter"):Connect(readAwakening)
player:GetAttributeChangedSignal("AwakeningProgress"):Connect(readAwakening)

for _, attribute in ipairs({
    "UltimateMeter",
    "AwakeningMeter",
    "UltimateReady",
    "AwakeningReady"
}) do
    player:GetAttributeChangedSignal(attribute):Connect(readPowerMeters)
end

combatFX.OnClientEvent:Connect(function(kind, _, payload)
    if kind == "CombatAction" and payload and payload.actor then
        if payload.actor:IsA("Model") then
            ProceduralAnimator:Play(payload.actor, tostring(payload.action or ""), payload)
        end

        if payload.actor == player.Character then
            stateLabel.Text = string.upper(tostring(payload.action or "ACTION"))
            task.delay(0.18, function()
                if stateLabel.Parent then
                    stateLabel.Text = "READY"
                end
            end)
        end

    elseif kind == "BlockImpact" then
        stateLabel.Text = "BLOCKED"
        task.delay(0.22, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)

    elseif kind == "Hit" and payload and payload.actor == player.Character then
        stateLabel.Text = payload.final and "FINISHER" or "HIT"
        task.delay(0.18, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)

    elseif kind == "ProjectileImpact" then
        stateLabel.Text = "IMPACT"
        task.delay(0.16, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)
    end
end)

task.spawn(function()
    while gui.Parent do
        for slot = 1, 4 do
            local left = remaining("Skill" .. tostring(slot))
            skillCooldowns[slot].Text =
                left <= 0.05 and "READY" or string.format("%.1fs", left)
        end
        task.wait(0.08)
    end
end)

refreshCharacter()
readAwakening()
readPowerMeters()
hideForMenu()
