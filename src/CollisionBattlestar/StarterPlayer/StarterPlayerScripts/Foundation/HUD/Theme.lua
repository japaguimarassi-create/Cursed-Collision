--!strict

local Theme = {}

Theme.Colors = {
    Background = Color3.fromRGB(10, 14, 20),
    Panel = Color3.fromRGB(17, 23, 32),
    PanelSoft = Color3.fromRGB(23, 31, 43),
    Stroke = Color3.fromRGB(62, 79, 101),
    Text = Color3.fromRGB(239, 244, 250),
    Muted = Color3.fromRGB(157, 172, 190),
    Cyan = Color3.fromRGB(87, 220, 255),
    CyanDark = Color3.fromRGB(37, 112, 139),
    Gold = Color3.fromRGB(255, 214, 92),
    Green = Color3.fromRGB(74, 226, 139),
    Yellow = Color3.fromRGB(255, 192, 78),
    Red = Color3.fromRGB(255, 72, 90),
    RedDark = Color3.fromRGB(112, 30, 42),
    White = Color3.fromRGB(255, 255, 255),
}

Theme.Font = Enum.Font.GothamBold
Theme.FontHeavy = Enum.Font.GothamBlack

function Theme.Corner(parent: Instance, radius: number): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

function Theme.Stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Colors.Stroke
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function Theme.Gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?): UIGradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, top),
        ColorSequenceKeypoint.new(1, bottom),
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

function Theme.Shadow(parent: Instance, radius: number)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.62
    shadow.BorderSizePixel = 0
    shadow.ZIndex = math.max(0, parent.ZIndex - 1)
    shadow.Parent = parent
    Theme.Corner(shadow, radius)
    return shadow
end

return Theme
