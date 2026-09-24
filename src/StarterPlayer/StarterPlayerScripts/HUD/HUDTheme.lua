--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Theme = {}

Theme.Colors = {
    Background = Color3.fromRGB(4, 6, 10),
    Surface = Color3.fromRGB(10, 13, 19),
    Surface2 = Color3.fromRGB(17, 21, 29),
    SurfacePressed = Color3.fromRGB(29, 35, 48),
    Stroke = Color3.fromRGB(112, 125, 150),
    Text = Color3.fromRGB(244, 247, 252),
    Muted = Color3.fromRGB(145, 153, 169),
    Accent = Color3.fromRGB(93, 154, 255),
    AccentBright = Color3.fromRGB(146, 92, 255),
    Health = Color3.fromRGB(235, 72, 91),
    Success = Color3.fromRGB(90, 222, 145),
    Warning = Color3.fromRGB(255, 194, 86),
    Black = Color3.fromRGB(0, 0, 0)
}

function Theme.Platform(): "Mobile" | "Console" | "PC"
    local input = UserInputService.PreferredInput
    if input == Enum.PreferredInput.Touch then
        return "Mobile"
    elseif input == Enum.PreferredInput.Gamepad then
        return "Console"
    end
    return "PC"
end

function Theme.CreateGui(name: string, displayOrder: number): ScreenGui
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.DisplayOrder = displayOrder
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    return gui
end

function Theme.Root(gui: ScreenGui): Frame
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Parent = gui
    return root
end

function Theme.Corner(object: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

function Theme.Circle(object: GuiObject)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = object
end

function Theme.Stroke(object: GuiObject, transparency: number?, thickness: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.Stroke
    stroke.Transparency = transparency or 0.55
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
end

function Theme.Label(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, textSize: number): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = text
    label.TextColor3 = Theme.Colors.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = math.max(7, math.floor(textSize * 0.66))
    constraint.MaxTextSize = textSize
    constraint.Parent = label
    return label
end

function Theme.Button(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, minTouch: number?): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Theme.Colors.Surface2
    button.BackgroundTransparency = 0.06
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Theme.Colors.Text
    button.Font = Enum.Font.GothamBlack
    button.TextSize = 11
    button.TextWrapped = true
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Parent = parent

    Theme.Corner(button, 12)
    Theme.Stroke(button, 0.58, 1)

    if minTouch then
        local constraint = Instance.new("UISizeConstraint")
        constraint.MinSize = Vector2.new(minTouch, minTouch)
        constraint.Parent = button
    end

    button.Activated:Connect(function()
        button.BackgroundColor3 = Theme.Colors.SurfacePressed
        task.delay(0.09, function()
            if button.Parent then
                button.BackgroundColor3 = Theme.Colors.Surface2
            end
        end)
    end)

    return button
end

function Theme.CircleButton(parent: Instance, name: string, text: string, size: number): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(size, size)
    button.BackgroundColor3 = Theme.Colors.Surface
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Theme.Colors.Text
    button.Font = Enum.Font.GothamBlack
    button.TextSize = math.max(14, math.floor(size * 0.29))
    button.TextWrapped = true
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Parent = parent
    Theme.Circle(button)
    Theme.Stroke(button, 0.35, 1.25)

    local scale = Instance.new("UIScale")
    scale.Name = "PressScale"
    scale.Scale = 1
    scale.Parent = button

    button.Activated:Connect(function()
        scale.Scale = 0.92
        button.BackgroundColor3 = Theme.Colors.SurfacePressed
        task.delay(0.09, function()
            if button.Parent then
                scale.Scale = 1
                button.BackgroundColor3 = Theme.Colors.Surface
            end
        end)
    end)

    return button
end

function Theme.Panel(parent: Instance, name: string, size: UDim2): Frame
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = size
    panel.Position = UDim2.fromScale(0.50, 0.51)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Theme.Colors.Surface
    panel.BackgroundTransparency = 0.035
    panel.BorderSizePixel = 0
    panel.Parent = parent
    Theme.Corner(panel, 18)
    Theme.Stroke(panel, 0.28, 1.25)

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(310, 420)
    sizeConstraint.MaxSize = Vector2.new(980, 760)
    sizeConstraint.Parent = panel
    return panel
end

function Theme.ResponsiveScale(root: GuiObject, reference: number?, minimum: number?, maximum: number?)
    local scale = Instance.new("UIScale")
    scale.Name = "ResponsiveScale"
    scale.Parent = root

    local function update()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        local base = reference or 720
        scale.Scale = math.clamp(shortAxis / base, minimum or 0.72, maximum or 1.10)
    end

    update()

    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(update)
    end)
    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(update)

    return scale
end

function Theme.CloseCombatAttributes(player: Player)
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
end

return Theme