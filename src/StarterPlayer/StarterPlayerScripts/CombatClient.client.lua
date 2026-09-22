--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CharacterMoves = require(ReplicatedStorage.Characters.CharacterMoves)
local CustomMovesets = require(ReplicatedStorage.Characters.CustomMovesets)
local InputController = require(script.Parent.Controllers.InputController)
local ProceduralAnimator = require(script.Parent.Controllers.ProceduralAnimator)

local player = Players.LocalPlayer
local remotes = RemoteService:Get()

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionCombatHUD"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

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
    object.BackgroundTransparency = 0.06
    object.AutoButtonColor = false
    object.Parent = parent
    corner(object, 13)
    stroke(object, 0.55)

    object.MouseButton1Down:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.06), {
            Size = size + UDim2.fromOffset(2, 2)
        }):Play()
    end)

    object.MouseButton1Up:Connect(function()
        TweenService:Create(object, TweenInfo.new(0.08), {
            Size = size
        }):Play()
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

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

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
fighter.Size = UDim2.fromScale(0.34, 0.105)
fighter.Position = UDim2.fromScale(0.018, 0.018)
fighter.BackgroundColor3 = Color3.fromRGB(13, 15, 21)
fighter.BackgroundTransparency = 0.08
fighter.Parent = root
corner(fighter, 14)
stroke(fighter, 0.48)

local previousCharacter = button(
    fighter,
    "<",
    UDim2.fromScale(0.14, 0.68),
    UDim2.fromScale(0.02, 0.16)
)

local nextCharacter = button(
    fighter,
    ">",
    UDim2.fromScale(0.14, 0.68),
    UDim2.fromScale(0.84, 0.16)
)

local nameLabel = label(
    fighter,
    "Potential Man",
    UDim2.fromScale(0.66, 0.40),
    UDim2.fromScale(0.17, 0.06),
    15
)
nameLabel.TextXAlignment = Enum.TextXAlignment.Center

local titleLabel = label(
    fighter,
    "Shadow Potential",
    UDim2.fromScale(0.66, 0.25),
    UDim2.fromScale(0.17, 0.56),
    8
)
titleLabel.TextColor3 = Color3.fromRGB(150, 154, 168)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local stateLabel = label(
    root,
    "READY",
    UDim2.fromScale(0.30, 0.035),
    UDim2.fromScale(0.35, 0.022),
    11
)
stateLabel.TextXAlignment = Enum.TextXAlignment.Center

local skillFrame = Instance.new("Frame")
skillFrame.Size = UDim2.fromScale(0.70, 0.13)
skillFrame.Position = UDim2.fromScale(0.50, 0.80)
skillFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skillFrame.BackgroundTransparency = 1
skillFrame.Parent = root

local skillButtons = {}
local skillCooldowns = {}

for slot = 1, 4 do
    local x = (slot - 0.5) / 4

    local skillButton = button(
        skillFrame,
        tostring(slot),
        UDim2.fromScale(0.235, 0.84),
        UDim2.fromScale(x, 0.08)
    )
    skillButton.AnchorPoint = Vector2.new(0.5, 0)
    skillButtons[slot] = skillButton

    skillCooldowns[slot] = label(
        skillButton,
        "READY",
        UDim2.fromScale(0.84, 0.23),
        UDim2.fromScale(0.08, 0.71),
        7
    )
    skillCooldowns[slot].TextColor3 = Color3.fromRGB(150, 154, 168)
end

local baseFrame = Instance.new("Frame")
baseFrame.Size = UDim2.fromScale(0.30, 0.30)
baseFrame.Position = UDim2.fromScale(0.72, 0.54)
baseFrame.BackgroundTransparency = 1
baseFrame.Parent = root

local m1 = button(baseFrame, "M1", UDim2.fromScale(0.44, 0.44), UDim2.fromScale(0.62, 0.50))
m1.AnchorPoint = Vector2.new(0.5, 0.5)
m1.TextSize = 22

local dash = button(baseFrame, "DASH", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.18, 0.62))
dash.AnchorPoint = Vector2.new(0.5, 0.5)

local block = button(baseFrame, "BLOCK", UDim2.fromScale(0.32, 0.20), UDim2.fromScale(0.18, 0.34))
block.AnchorPoint = Vector2.new(0.5, 0.5)

local special = button(root, "SPECIAL", UDim2.fromScale(0.17, 0.07), UDim2.fromScale(0.50, 0.925))
special.AnchorPoint = Vector2.new(0.5, 0.5)

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

    remotes.CombatAction:FireServer(action, payload)
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
        skillButtons[slot].Text =
            tostring(slot) .. "\n" .. (move and move.Name or "Skill")
    end

    special.Text =
        (CharacterMoves[id] and CharacterMoves[id].SpecialName or "SPECIAL")
        .. "\nSPECIAL"

    localCooldowns = {}
end

local function selectCharacter(index: number)
    currentIndex = ((index - 1) % #roster) + 1
    local id = roster[currentIndex]

    refreshCharacter()

    player:SetAttribute("LocalPendingCharacter", id)
    remotes.CombatAction:FireServer("SelectCharacter", id)
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

block.Activated:Connect(function()
    local active = player:GetAttribute("LocalBlocking") ~= true
    player:SetAttribute("LocalBlocking", active)
    block.Text = active and "BLOCKING" or "BLOCK"
    fire(active and "BlockStart" or "BlockEnd")
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
    if processed then
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

    if input.KeyCode == Enum.KeyCode.F
        and player:GetAttribute("LocalBlocking") ~= true then
        player:SetAttribute("LocalBlocking", true)
        block.Text = "BLOCKING"
        fire("BlockStart")
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F
        and player:GetAttribute("LocalBlocking") == true then
        player:SetAttribute("LocalBlocking", false)
        block.Text = "BLOCK"
        fire("BlockEnd")
    end
end)

player.CharacterAdded:Connect(function(character)
    ProceduralAnimator:Bind(character)
end)

if player.Character then
    ProceduralAnimator:Bind(player.Character)
end

player:GetAttributeChangedSignal("CharacterId"):Connect(refreshCharacter)

remotes.CombatFX.OnClientEvent:Connect(function(kind, _position, payload)
    if kind == "CombatAction"
        and payload
        and payload.actor
        and payload.actor:IsA("Model") then

        ProceduralAnimator:Play(
            payload.actor,
            tostring(payload.action or ""),
            payload
        )

        stateLabel.Text =
            string.upper(tostring(payload.action or "ACTION"))

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
            skillCooldowns[slot].Text =
                left <= 0.05
                and "READY"
                or string.format("%.1fs", left)
        end
        task.wait(0.05)
    end
end)

refreshCharacter()
