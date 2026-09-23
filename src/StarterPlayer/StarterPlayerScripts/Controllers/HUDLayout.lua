--!strict

local HUDLayout = {}

HUDLayout.Colors = {
    Panel = Color3.fromRGB(9, 11, 17),
    PanelSoft = Color3.fromRGB(16, 19, 27),
    Button = Color3.fromRGB(22, 25, 34),
    ButtonPressed = Color3.fromRGB(38, 42, 56),
    Stroke = Color3.fromRGB(78, 82, 102),
    Text = Color3.fromRGB(241, 242, 247),
    Muted = Color3.fromRGB(157, 161, 179),
    Accent = Color3.fromRGB(157, 117, 255),
    Health = Color3.fromRGB(216, 72, 88),
    Ready = Color3.fromRGB(104, 222, 148)
}

function HUDLayout:GetScale(viewport: Vector2): number
    local shortAxis = math.min(viewport.X, viewport.Y)
    local scale = shortAxis / 720

    if viewport.X / math.max(viewport.Y, 1) < 0.9 then
        scale *= 0.92
    elseif viewport.X / math.max(viewport.Y, 1) > 2.1 then
        scale *= 1.04
    end

    return math.clamp(scale, 0.70, 1.08)
end

function HUDLayout:IsCompact(viewport: Vector2): boolean
    return math.min(viewport.X, viewport.Y) < 620
end

function HUDLayout:IsWide(viewport: Vector2): boolean
    return viewport.X / math.max(viewport.Y, 1) > 1.75
end

function HUDLayout:ActionLayout(viewport: Vector2): {[string]: UDim2}
    local compact = self:IsCompact(viewport)
    local bottom = if compact then 0.855 else 0.825
    local right = if compact then 0.78 else 0.75

    return {
        M1 = UDim2.fromScale(right, bottom),
        Block = UDim2.fromScale(right - 0.12, bottom - 0.105),
        Dash = UDim2.fromScale(right - 0.12, bottom + 0.005),
        Sprint = UDim2.fromScale(right - 0.12, bottom - 0.215),
        Special = UDim2.fromScale(0.50, if compact then 0.945 else 0.925),
        Ultimate = UDim2.fromScale(0.375, if compact then 0.945 else 0.925),
        Awakening = UDim2.fromScale(0.625, if compact then 0.945 else 0.925)
    }
end

return HUDLayout
