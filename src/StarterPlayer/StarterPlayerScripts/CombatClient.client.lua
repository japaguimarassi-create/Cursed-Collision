--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
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

local function label(
    parent: Instance,
    textValue: string,
    size: UDim2,
    position: UDim2,
    textSize: number
)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize
    object.TextColor3 = Color3.fromRGB(235, 236, 242)
    object.Parent = parent
    return object
end

local function button(
    parent: Instance,
    textValue: string,
    size: UDim2,
    position: UDim2
)
    local object = Instance.new("TextButton")

    object.Size = size
    object.Position = position
    object.Text = textValue
    object.Font = Enum.Font.GothamBlack
    object.TextSize = 14
    object.TextColor3 = Color3.fromRGB(240, 241, 246)
    object.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
    object.BackgroundTransparency = 0.06
    object.AutoButtonColor = false
    object.Parent = parent

    corner(object, 14)
    stroke(object, 0.55)

    object.MouseButton1Down:Connect(function()
        TweenService:Create(
            object,
            TweenInfo.new(0.06),
            {Size = size + UDim2.fromOffset(2, 2)}
        ):Play()
    end)

    object.MouseButton1Up:Connect(function()
        TweenService:Create(
            object,
            TweenInfo.new(0.08),
            {Size = size}
        ):Play()
    end)

    return object
end

local root = Instance.new("Frame")
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui

local fighter = Instance.new("Frame")
fighter.Size = UDim2.fromScale(0.28, 0.09)
fighter.Position = UDim2.fromScale(0.018, 0.02)
fighter.BackgroundColor3 = Color3.fromRGB(13, 15, 21)
fighter.BackgroundTransparency = 0.10
fighter.Parent = root

corner(fighter, 14)
stroke(fighter, 0.48)

local nameLabel = label(
    fighter,
    "Potential Man",
    UDim2.fromScale(0.80, 0.44),
    UDim2.fromScale(0.07, 0.08),
    17
)

local titleLabel = label(
    fighter,
    "Shadow Potential",
    UDim2.fromScale(0.84, 0.26),
    UDim2.fromScale(0.07, 0.58),
    9
)

titleLabel.TextColor3 = Color3.fromRGB(150, 154, 168)

local stateLabel = label(
    root,
    "READY",
    UDim2.fromScale(0.28, 0.035),
    UDim2.fromScale(0.36, 0.025),
    11
)

stateLabel.TextXAlignment = Enum.TextXAlignment.Center

local special = button(
    root,
    "SPECIAL",
    UDim2.fromScale(0.14, 0.066),
    UDim2.fromScale(0.50, 0.84)
)

special.AnchorPoint = Vector2.new(0.5, 0.5)

local combat = Instance.new("Frame")
combat.Size = UDim2.fromScale(0.27, 0.35)
combat.Position = UDim2.fromScale(0.70, 0.57)
combat.BackgroundTransparency = 1
combat.Parent = root

local m1 = button(
    combat,
    "M1",
    UDim2.fromScale(0.42, 0.42),
    UDim2.fromScale(0.62, 0.58)
)

m1.AnchorPoint = Vector2.new(0.5, 0.5)
m1.TextSize = 23

local dash = button(
    combat,
    "DASH",
    UDim2.fromScale(0.30, 0.19),
    UDim2.fromScale(0.18, 0.70)
)

dash.AnchorPoint = Vector2.new(0.5, 0.5)

local block = button(
    combat,
    "BLOCK",
    UDim2.fromScale(0.30, 0.19),
    UDim2.fromScale(0.18, 0.40)
)

block.AnchorPoint = Vector2.new(0.5, 0.5)

local cooldowns = {
    M1 = label(
        m1,
        "READY",
        UDim2.fromScale(0.88, 0.22),
        UDim2.fromScale(0.06, 0.70),
        8
    ),
    Dash = label(
        dash,
        "READY",
        UDim2.fromScale(0.80, 0.22),
        UDim2.fromScale(0.10, 0.68),
        7
    ),
    Special = label(
        special,
        "READY",
        UDim2.fromScale(0.80, 0.20),
        UDim2.fromScale(0.10, 0.70),
        8
    )
}

for _, object in pairs(cooldowns) do
    object.TextColor3 = Color3.fromRGB(150, 154, 168)
end

local nextReady = {}

local function remaining(action: string): number
    return math.max(
        0,
        (nextReady[action] or 0) - os.clock()
    )
end

local function fire(action: string, payload: any)
    if action ~= "BlockStart"
        and action ~= "BlockEnd"
        and remaining(action) > 0 then
        return
    end

    local duration = 0

    if action == "M1" then
        duration = Config.Combat.M1.Cooldown
    elseif action == "Dash" then
        duration = Config.Combat.Dash.Cooldown
    elseif action == "Special" then
        duration = Config.Combat.Special.Cooldown
    end

    if duration > 0 then
        nextReady[action] = os.clock() + duration
    end

    remotes.CombatAction:FireServer(action, payload)
end

local blocking = false

m1.Activated:Connect(function()
    fire("M1")
end)

dash.Activated:Connect(function()
    fire("Dash", InputController:GetDashDirection())
end)

block.Activated:Connect(function()
    blocking = not blocking
    block.Text = blocking and "BLOCKING" or "BLOCK"
    fire(blocking and "BlockStart" or "BlockEnd")
end)

special.Activated:Connect(function()
    fire("Special")
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
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

    if input.KeyCode == Enum.KeyCode.F and not blocking then
        blocking = true
        block.Text = "BLOCKING"
        fire("BlockStart")
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and blocking then
        blocking = false
        block.Text = "BLOCK"
        fire("BlockEnd")
    end
end)

local function onCharacter(character: Model)
    ProceduralAnimator:Bind(character)
end

player.CharacterAdded:Connect(onCharacter)

if player.Character then
    onCharacter(player.Character)
end

remotes.CombatFX.OnClientEvent:Connect(function(kind, _position, payload)
    if kind == "CombatAction" and payload
        and payload.actor and payload.actor:IsA("Model") then

        ProceduralAnimator:Play(
            payload.actor,
            tostring(payload.action or ""),
            payload
        )

        stateLabel.Text = string.upper(
            tostring(payload.action or "ACTION")
        )

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
    elseif kind == "SpecialImpact" then
        stateLabel.Text = "SPECIAL HIT"

        task.delay(0.30, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)
    elseif kind == "Hit" and payload then
        stateLabel.Text = payload.final and "FINISHER" or "HIT"

        task.delay(0.16, function()
            if stateLabel.Parent then
                stateLabel.Text = "READY"
            end
        end)
    end
end)

task.spawn(function()
    while gui.Parent do
        local m1Left = remaining("M1")
        local dashLeft = remaining("Dash")
        local specialLeft = remaining("Special")

        cooldowns.M1.Text =
            m1Left <= 0.05 and "READY" or string.format("%.1fs", m1Left)

        cooldowns.Dash.Text =
            dashLeft <= 0.05 and "READY" or string.format("%.1fs", dashLeft)

        cooldowns.Special.Text =
            specialLeft <= 0.05 and "READY" or string.format("%.1fs", specialLeft)

        task.wait(0.05)
    end
end)