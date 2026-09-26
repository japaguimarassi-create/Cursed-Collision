--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Root = {}

local function tween(object: Instance, info: TweenInfo, goal)
    return TweenService:Create(object, info, goal)
end

function Root.Create(player: Player): ScreenGui
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 70
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
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
        local widthScale = viewport.X / 1280
        local heightScale = viewport.Y / 720
        scale.Scale = math.clamp(math.min(widthScale, heightScale), 0.68, 1.05)
    end

    local function hookCamera(camera: Camera?)
        if not camera then
            return
        end
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
        refresh()
    end

    hookCamera(workspace.CurrentCamera)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        hookCamera(workspace.CurrentCamera)
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

function Root.Circle(parent: Instance)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = parent
end

function Root.Stroke(parent: Instance, color: Color3?, transparency: number?, thickness: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.UI.Stroke
    stroke.Transparency = transparency or 0.18
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

function Root.Label(parent: Instance, value: string, size: number, color: Color3?, font: Enum.Font?)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = color or Config.UI.Text
    label.Font = font or Enum.Font.GothamBold
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    return label
end

function Root.Pill(parent: Instance, size: UDim2, position: UDim2, background: Color3?, transparency: number?)
    local pill = Instance.new("Frame")
    pill.Size = size
    pill.Position = position
    pill.BackgroundColor3 = background or Config.UI.Surface
    pill.BackgroundTransparency = transparency or 0.1
    pill.BorderSizePixel = 0
    pill.Parent = parent
    Root.Rounded(pill, 14)
    Root.Stroke(pill, nil, 0.22, 1)
    return pill
end

function Root.Button(parent: Instance, name: string, value: string, size: UDim2)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.BackgroundColor3 = Config.UI.Surface2
    button.BackgroundTransparency = 0.08
    button.Text = value
    button.TextColor3 = Config.UI.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = parent
    Root.Rounded(button, 14)
    Root.Stroke(button, nil, 0.22, 1)

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    button.MouseEnter:Connect(function()
        tween(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Scale = 1.03}):Play()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = Config.UI.Surface3}):Play()
    end)

    button.MouseLeave:Connect(function()
        tween(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Scale = 1}):Play()
        tween(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {BackgroundColor3 = Config.UI.Surface2}):Play()
    end)

    button.Activated:Connect(function()
        local down = tween(scale, TweenInfo.new(0.055, Enum.EasingStyle.Quad), {Scale = 0.94})
        down:Play()
        down.Completed:Connect(function()
            if button.Parent then
                tween(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Scale = 1}):Play()
            end
        end)
    end)

    return button
end

function Root.Progress(parent: Instance, size: UDim2, position: UDim2, fillColor: Color3, height: number?)
    local back = Instance.new("Frame")
    back.Size = size
    back.Position = position
    back.BackgroundColor3 = Config.UI.Surface3
    back.BackgroundTransparency = 0.22
    back.BorderSizePixel = 0
    back.Parent = parent
    Root.Rounded(back, height or 5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.Parent = back
    Root.Rounded(fill, height or 5)
    return back, fill
end

function Root.AnimateIn(object: GuiObject, direction: string?)
    local target = object.Position
    local offsetX = if direction == "Left" then -24 elseif direction == "Right" then 24 else 0
    local offsetY = if direction == "Up" then -20 elseif direction == "Down" then 20 else 0
    object.Position = UDim2.new(target.X.Scale, target.X.Offset + offsetX, target.Y.Scale, target.Y.Offset + offsetY)
    tween(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = target}):Play()
end

return Root
