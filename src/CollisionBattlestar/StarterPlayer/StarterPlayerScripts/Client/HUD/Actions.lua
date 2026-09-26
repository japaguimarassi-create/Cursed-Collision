--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Actions = {}

local function createAction(root, name, title, hint, accent, size)
    local button = root.Button(root.Gui, name, "", size)
    button.BackgroundColor3 = Config.UI.Surface
    button.BackgroundTransparency = 0.04
    root.Circle(button)

    local accentRing = Instance.new("UIStroke")
    accentRing.Color = accent
    accentRing.Transparency = 0.48
    accentRing.Thickness = 2
    accentRing.Parent = button

    local glyphBack = Instance.new("Frame")
    glyphBack.Size = UDim2.fromOffset(44, 44)
    glyphBack.Position = UDim2.new(0.5, -22, 0, 10)
    glyphBack.BackgroundColor3 = accent
    glyphBack.BackgroundTransparency = 0.86
    glyphBack.BorderSizePixel = 0
    glyphBack.Parent = button
    root.Circle(glyphBack)

    local glyph = root.Label(glyphBack, if name == "M1" then "A" else "↯", 18, accent)
    glyph.Size = UDim2.fromScale(1, 1)
    glyph.TextXAlignment = Enum.TextXAlignment.Center

    local label = root.Label(button, title, 9)
    label.Size = UDim2.new(1, -12, 0, 15)
    label.Position = UDim2.fromOffset(6, 54)
    label.TextXAlignment = Enum.TextXAlignment.Center

    local key = root.Label(button, hint, 7, Config.UI.Muted, Enum.Font.GothamMedium)
    key.Size = UDim2.new(1, -12, 0, 13)
    key.Position = UDim2.fromOffset(6, 69)
    key.TextXAlignment = Enum.TextXAlignment.Center

    local cooldown = Instance.new("Frame")
    cooldown.Size = UDim2.fromScale(1, 1)
    cooldown.BackgroundColor3 = Color3.new(0, 0, 0)
    cooldown.BackgroundTransparency = 0.44
    cooldown.BorderSizePixel = 0
    cooldown.Visible = false
    cooldown.ZIndex = button.ZIndex + 3
    cooldown.Parent = button
    root.Circle(cooldown)

    local cooldownText = root.Label(cooldown, "", 14, Config.UI.Text)
    cooldownText.Size = UDim2.fromScale(1, 1)
    cooldownText.TextXAlignment = Enum.TextXAlignment.Center
    cooldownText.ZIndex = button.ZIndex + 4

    local duration = if name == "M1" then Config.Combat.M1.Cooldown + 0.035 else Config.Combat.Dash.Cooldown + 0.08
    local nextReady = 0

    local function activate()
        if os.clock() < nextReady then
            return false
        end

        nextReady = os.clock() + duration
        cooldown.Visible = true
        cooldown.BackgroundTransparency = 0.32

        local token = nextReady
        task.spawn(function()
            while cooldown.Parent and os.clock() < token do
                cooldownText.Text = ("%.1f"):format(math.max(0, token - os.clock()))
                task.wait(0.05)
            end
            if cooldown.Parent and token == nextReady then
                cooldown.Visible = false
                cooldownText.Text = ""
            end
        end)

        tween = TweenService:Create(cooldown, TweenInfo.new(duration, Enum.EasingStyle.Linear), {BackgroundTransparency = 1})
        tween:Play()
        return true
    end

    return {Button = button, Activate = activate}
end

function Actions.Mount(root)
    local holder = Instance.new("Frame")
    holder.Name = "ActionBar"
    holder.Size = UDim2.fromOffset(202, 106)
    holder.Position = UDim2.new(0.5, 0, 1, -18)
    holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local m1 = createAction(root, "M1", "ATTACK", "M1 / R2", Config.UI.Accent, UDim2.fromOffset(94, 94))
    local dash = createAction(root, "Dash", "DASH", "Q / B", Config.UI.Info, UDim2.fromOffset(82, 82))
    m1.Button.Position = UDim2.fromOffset(0, 0)
    dash.Button.Position = UDim2.fromOffset(118, 6)
    m1.Button.Parent = holder
    dash.Button.Parent = holder

    root.AnimateIn(holder, "Down")
    return {M1 = m1, Dash = dash, Holder = holder}
end

return Actions
