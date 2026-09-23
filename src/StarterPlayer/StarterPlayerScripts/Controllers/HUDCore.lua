--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local HUDCore = {}
HUDCore.__index = HUDCore

local COLORS = {
    Surface = Color3.fromRGB(10, 12, 18),
    Surface2 = Color3.fromRGB(18, 21, 30),
    Surface3 = Color3.fromRGB(26, 29, 40),
    Text = Color3.fromRGB(240, 242, 248),
    Muted = Color3.fromRGB(157, 161, 179),
    Accent = Color3.fromRGB(161, 112, 255),
    Accent2 = Color3.fromRGB(214, 83, 255),
    Health = Color3.fromRGB(232, 70, 91),
    Success = Color3.fromRGB(95, 220, 142),
    Warning = Color3.fromRGB(255, 196, 93)
}

export type Core = {
    Gui: ScreenGui,
    Root: Frame,
    Overlay: Frame,
    Palette: {[string]: Color3},
    GetMode: (self: Core) -> string,
    Button: (self: Core, parent: Instance, name: string, title: string) -> TextButton,
    Panel: (self: Core, parent: Instance, name: string) -> Frame,
    Label: (self: Core, parent: Instance, name: string, text: string) -> TextLabel,
}

local player = Players.LocalPlayer

local function addCorner(object: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

local function addStroke(object: GuiObject, transparency: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Accent
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.55
    stroke.Parent = object
end

function HUDCore.new(): Core
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("CursedCollisionHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CursedCollisionHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.DisplayOrder = 50
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Parent = gui

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.ZIndex = 100
    overlay.Parent = root

    local scale = Instance.new("UIScale")
    scale.Name = "ResponsiveScale"
    scale.Parent = root

    local function refresh()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local shortAxis = math.min(viewport.X, viewport.Y)
        local multiplier = if viewport.X / math.max(1, viewport.Y) > 1.35 then 1 else 0.92
        scale.Scale = math.clamp((shortAxis / 720) * multiplier, 0.70, 1.08)
    end

    refresh()

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refresh)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
    end

    UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
        player:SetAttribute("CC_HUD_Input", tostring(UserInputService.PreferredInput))
    end)

    player:SetAttribute("CC_HUD_Input", tostring(UserInputService.PreferredInput))

    local self = setmetatable({
        Gui = gui,
        Root = root,
        Overlay = overlay,
        Palette = COLORS
    }, HUDCore)

    function self:GetMode(): string
        local input = UserInputService.PreferredInput
        if input == Enum.PreferredInput.Touch then
            return "Mobile"
        end
        if input == Enum.PreferredInput.Gamepad then
            return "Console"
        end
        return "Desktop"
    end

    return self
end

function HUDCore:Button(parent: Instance, name: string, title: string): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromOffset(96, 52)
    button.BackgroundColor3 = COLORS.Surface2
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.Text = title
    button.TextColor3 = COLORS.Text
    button.Font = Enum.Font.GothamBlack
    button.TextSize = 11
    button.TextWrapped = true
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Parent = parent
    addCorner(button, 14)
    addStroke(button, 0.60)
    return button
end

function HUDCore:Panel(parent: Instance, name: string): Frame
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = COLORS.Surface
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = parent
    addCorner(panel, 20)
    addStroke(panel, 0.35)
    return panel
end

function HUDCore:Label(parent: Instance, name: string, text: string): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = text
    label.TextColor3 = COLORS.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

return HUDCore
