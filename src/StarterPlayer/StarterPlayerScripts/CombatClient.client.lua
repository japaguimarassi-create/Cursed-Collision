--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CharacterMoves = require(ReplicatedStorage.Characters.CharacterMoves)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Controllers.InputController)
local ProceduralAnimator = require(script.Parent.Controllers.ProceduralAnimator)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotesFolder then
    return
end

local combatAction = remotesFolder:WaitForChild("CombatAction", 15)
local combatFX = remotesFolder:WaitForChild("CombatFX", 15)
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
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 5
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Name = "ResponsiveScale"
scale.Scale = 1
scale.Parent = root

local function refreshScale()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize
    local factor = math.clamp(viewport.Y / 800, 0.78, 1.16)
    if viewport.X < viewport.Y then
        factor = math.clamp(factor, 0.82, 1.08)
    end
    scale.Scale = factor
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshScale)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end
refreshScale()

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

local function button(parent: Instance, textValue: string, size: UDim2, position: UDim2)
    local object = Instance.new("TextButton")
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.Font = Enum.Font.GothamBlack
    object.TextSize = 12
    object.TextColor3 = Color3.fromRGB(240, 241, 246)
    object.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
    object.BackgroundTransparency = 0.04
    object.AutoButtonColor = false
    object.Active = true
    object.Selectable = true
    object.Parent = parent
    corner(object, 13)
    stroke(object, 0.52)

    local buttonScale = Instance.new("UIScale")
    buttonScale.Scale = 1
    buttonScale.Parent = object

    object.Activated:Connect(function()
        TweenService:Create(buttonScale, TweenInfo.new(0.06), {Scale = 0.96}):Play()
        task.delay(0.06, function()
            if buttonScale.Parent then
                TweenService:Create(buttonScale, TweenInfo.new(0.11, Enum.EasingStyle.Back), {Scale = 1}):Play()
            end
        end)
    end)

    return object
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

local roster = {}
for id in pairs(Definitions) do
    table.insert(roster, id)
end
table.sort(roster)

local function findCurrentIndex()
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    return table.find(roster, id) or 1
end

local currentIndex = findCurrentIndex()

local fighter = Instance.new("Frame")
fighter.Name = "CharacterCard"
fighter.Size = UDim2.fromScale(0.31, 0.095)
fighter.Position = UDim2.fromScale(0.018, 0.018)
fighter.BackgroundColor3 = Color3.fromRGB(13, 15, 21)
fighter.BackgroundTransparency = 0.06
fighter.Parent = root
corner(fighter, 14)
stroke(fighter, 0.48)

local previousCharacter = button(fighter, "<", UDim2.fromScale(0.15, 0.68), UDim2.fromScale(0.015, 0.16))
local nextCharacter = button(fighter, ">", UDim2.fromScale(0.15, 0.68), UDim2.fromScale(0.835, 0.16))

local nameLabel = label(fighter, "Potential Man", UDim2.fromScale(0.66, 0.38), UDim2.fromScale(0.17, 0.07), 15)
nameLabel.TextXAlignment = Enum.TextXAlignment.Center

local titleLabel = label(fighter, "Shadow Potential", UDim2.fromScale(0.66, 0.25), UDim2.fromScale(0.17, 0.56), 8)
titleLabel.TextColor3 = Color3.fromRGB(150, 154, 168)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local stateCard = Instance.new("Frame")
stateCard.Size = UDim2.fromScale(0.20, 0.05)
stateCard.Position = UDim2.fromScale(0.40, 0.018)
stateCard.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
stateCard.BackgroundTransparency = 0.18
stateCard.Parent = root
corner(stateCard, 10)
stroke(stateCard, 0.72)

local stateLabel = label(stateCard, "READY", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 10)
stateLabel.TextXAlignment = Enum.TextXAlignment.Center

local skillFrame = Instance.new("Frame")
skillFrame.Name = "Skills"
skillFrame.Size = UDim2.fromScale(0.92, 0.12)
skillFrame.Position = UDim2.fromScale(0.50, 0.815)
skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skillFrame.BackgroundTransparency = 1
skillFrame.Parent = root

local skillButtons = {}
local skillCooldowns = {}

for slot = 1, 4 do
    local x = (slot - 0.5) / 4
    local skillButton = button(skillFrame, tostring(slot), UDim2.fromScale(0.235, 0.88), UDim2.fromScale(x, 0.06))
    skillButton.AnchorPoint = Vector2.new(0.5, 0)
    skillButton.TextScaled = false
    skillButton.TextSize = 11
    skillButtons[slot] = skillButton

    local cooldown = label(skillButton, "READY", UDim2.fromScale(0.84, 0.22), UDim2.fromScale(0.08, 0.73), 7)
    cooldown.TextColor3 = Color3.fromRGB(150, 154, 168)
    cooldown.TextXAlignment = Enum.TextXAlignment.Center
    skillCooldowns[slot] = cooldown
end

local baseFrame = Instance.new("Frame")
baseFrame.Name = "BaseActions"
baseFrame.Size = UDim2.fromScale(0.31, 0.29)
baseFrame.Position = UDim2.fromScale(0.715, 0.545)
baseFrame.BackgroundTransparency = 1
baseFrame.Parent = root

local m1 = button(baseFrame, "M1", UDim2.fromScale(0.46, 0.46), UDim2.fromScale(0.62, 0.50))
m1.AnchorPoint = Vector2.new(0.5, 0.5)
m1.TextSize = 22

local dash = button(baseFrame, "DASH", UDim2.fromScale(0.34, 0.20), UDim2.fromScale(0.18, 0.63))
dash.AnchorPoint = Vector2.new(0.5, 0.5)

local block = button(baseFrame, "BLOCK", UDim2.fromScale(0.34, 0.20), UDim2.fromScale(0.18, 0.34))
block.AnchorPoint = Vector2.new(0.5, 0.5)

local special = button(root, "SPECIAL", UDim2.fromScale(0.17, 0.065), UDim2.fromScale(0.50, 0.934))
special.AnchorPoint = Vector2.new(0.5, 0.5)
special.TextSize = 11

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
    if player:GetAttribute("CCHUD_MenuOpen") == true then
        return
    end

    if action ~= "BlockStart" and action ~= "BlockEnd" and remaining(action) > 0 then
        return
    end

    local duration = if action == "BlockStart" or action == "BlockEnd" then 0 else moveCooldown(action)
    if duration > 0 then
        localCooldowns[action] = os.clock() + duration
    end

    combatAction:FireServer(action, payload)
end

local function refreshCharacter()
    currentIndex = findCurrentIndex()
    local id = player:GetAttribute("CharacterId") or roster[currentIndex]
    local profile = Definitions[id]
    local moves = CustomMovesets.Get(id)

    nameLabel.Text = profile and profile.Name or id
    titleLabel.Text = profile and profile.Subtitle or ""

    for slot = 1, 4 do
        local move = moves[slot]
        skillButtons[slot].Text = tostring(slot) .. "\n" .. (move and move.Name or "Skill")
    end

    special.Text = (CharacterMoves[id] and CharacterMoves[id].SpecialName or "SPECIAL") .. "\nSPECIAL"
    localCooldowns = {}
end

local function selectCharacter(index: number)
    if #roster == 0 then
        return
    end

    currentIndex = ((index - 1) % #roster) + 1
    local id = roster[currentIndex]
    player:SetAttribute("LocalPendingCharacter", id)
    combatAction:FireServer("SelectCharacter", id)
end

previousCharacter.Activated:Connect(function()
    selectCharacter(currentIndex - 1)
end)

nextCharacter.Activated:Connect(function()
    selectCharacter(currentIndex + 1)
end)

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

local function setBlocking(active: boolean)
    player:SetAttribute("LocalBlocking", active)
    block.Text = active and "BLOCKING" or "BLOCK"
    fire(active and "BlockStart" or "BlockEnd")
end

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

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fire("M1")
        return
    end

    local slot = keySkills[input.KeyCode]
    if slot then
        fire("Skill" .. tostring(slot))
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

    if input.KeyCode == Enum.KeyCode.F and player:GetAttribute("LocalBlocking") ~= true then
        setBlocking(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and player:GetAttribute("LocalBlocking") == true then
        setBlocking(false)
    end
end)

player.CharacterAdded:Connect(function(character)
    ProceduralAnimator:Bind(character)
end)

if player.Character then
    ProceduralAnimator:Bind(player.Character)
end

player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)

player:GetAttributeChangedSignal("CCHUD_MenuOpen"):Connect(function()
    local open = player:GetAttribute("CCHUD_MenuOpen") == true
    root.Visible = not open
    if open and player:GetAttribute("LocalBlocking") == true then
        player:SetAttribute("LocalBlocking", false)
        block.Text = "BLOCK"
    end
end)

combatFX.OnClientEvent:Connect(function(kind, _position, payload)
    if kind == "CombatAction"
        and payload
        and payload.actor
        and payload.actor:IsA("Model") then

        ProceduralAnimator:Play(payload.actor, tostring(payload.action or ""), payload)
        stateLabel.Text = string.upper(tostring(payload.action or "ACTION"))

        task.delay(0.18, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)

    elseif kind == "BlockImpact" then
        stateLabel.Text = "BLOCKED"
        task.delay(0.22, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)

    elseif kind == "Hit" and payload then
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
            skillCooldowns[slot].Text = left <= 0.05 and "READY" or string.format("%.1fs", left)
        end
        task.wait(0.08)
    end
end)

refreshCharacter()
root.Visible = player:GetAttribute("CCHUD_MenuOpen") ~= true
