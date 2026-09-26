--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Root = {}

function Root.Create(player: Player): ScreenGui
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 50
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.IgnoreGuiInset = false
    gui.Parent = playerGui

    local scale = Instance.new("UIScale")
    scale.Name = "ResponsiveScale"
    scale.Parent = gui

    local function refresh()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local factor = math.min(viewport.X / 1100, viewport.Y / 650)
        scale.Scale = math.clamp(factor, 0.76, 1.08)
    end

    local camera = workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local current = workspace.CurrentCamera
        if current then
            current:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
        end
        refresh()
    end)

    refresh()
    player:SetAttribute("CollisionHUDRootReady", true)

    return gui
end

function Root.Rounded(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

function Root.Stroke(parent: Instance, color: Color3?, transparency: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.UI.Stroke
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.24
    stroke.Parent = parent
end

function Root.Panel(parent: Instance, size: UDim2, position: UDim2, anchorPoint: Vector2?): Frame
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = anchorPoint or Vector2.zero
    frame.BackgroundColor3 = Config.UI.Surface
    frame.BackgroundTransparency = 0.07
    frame.Parent = parent
    Root.Rounded(frame, 15)
    Root.Stroke(frame)
    return frame
end

function Root.Label(parent: Instance, value: string, size: number, color: Color3?): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = color or Config.UI.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

function Root.Button(parent: Instance, name: string, value: string, size: UDim2): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.BackgroundColor3 = Config.UI.Surface
    button.BackgroundTransparency = 0.04
    button.Text = value
    button.TextColor3 = Config.UI.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.AutoButtonColor = true
    button.Parent = parent
    Root.Rounded(button, 12)
    Root.Stroke(button, nil, 0.25)
    return button
end

return Root
