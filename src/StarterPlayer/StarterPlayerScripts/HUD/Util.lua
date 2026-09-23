--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Util = {}

Util.Colors = {
    Background = Color3.fromRGB(12, 13, 18),
    Panel = Color3.fromRGB(18, 20, 28),
    PanelSoft = Color3.fromRGB(27, 29, 39),
    Text = Color3.fromRGB(238, 239, 245),
    Muted = Color3.fromRGB(155, 158, 176),
    Accent = Color3.fromRGB(118, 201, 255),
    Accent2 = Color3.fromRGB(165, 121, 255),
    Danger = Color3.fromRGB(218, 70, 88),
    Success = Color3.fromRGB(106, 222, 152),
    Gold = Color3.fromRGB(255, 211, 102),
    Black = Color3.fromRGB(5, 6, 9)
}

function Util.platform(): "Mobile" | "Console" | "PC"
    local preferred = UserInputService.PreferredInput
    if preferred == Enum.PreferredInput.Touch then
        return "Mobile"
    end
    if preferred == Enum.PreferredInput.Gamepad then
        return "Console"
    end
    return "PC"
end

function Util.makeGui(name: string, displayOrder: number): ScreenGui
    local existing = player.PlayerGui:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = displayOrder
    gui.Parent = player.PlayerGui
    return gui
end

function Util.makeRoot(gui: ScreenGui): Frame
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

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
        local platform = Util.platform()

        local base = if platform == "Mobile"
            then 680
            elseif platform == "Console"
            then 900
            else 820

        scale.Scale = math.clamp(shortAxis / base, 0.72, 1.18)
    end

    update()

    local function bindCamera()
        local camera = workspace.CurrentCamera
        if camera then
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
        end
    end

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        bindCamera()
        update()
    end)

    bindCamera()

    return root
end

function Util.corner(parent: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

function Util.stroke(parent: GuiObject, color: Color3, transparency: number, thickness: number?)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency
    s.Thickness = thickness or 1
    s.Parent = parent
end

function Util.label(
    parent: Instance,
    text: string,
    size: UDim2,
    position: UDim2,
    textSize: number,
    font: Enum.Font?
): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Text = text
    label.TextColor3 = Util.Colors.Text
    label.Font = font or Enum.Font.GothamBold
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent

    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = math.max(8, math.floor(textSize * 0.65))
    constraint.MaxTextSize = textSize
    constraint.Parent = label

    return label
end

function Util.button(
    parent: Instance,
    name: string,
    text: string,
    size: UDim2,
    position: UDim2,
    compact: boolean?
): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.Text = text
    button.TextColor3 = Util.Colors.Text
    button.Font = Enum.Font.GothamBlack
    button.TextSize = compact and 10 or 12
    button.TextWrapped = true
    button.BackgroundColor3 = Util.Colors.Panel
    button.BackgroundTransparency = 0.06
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Parent = parent

    Util.corner(button, compact and 10 or 13)
    Util.stroke(button, Color3.fromRGB(74, 78, 96), 0.42, 1)

    local normal = button.BackgroundTransparency
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.06), {
            BackgroundTransparency = 0
        }):Play()
    end)
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.08), {
            BackgroundTransparency = normal
        }):Play()
    end)

    return button
end

function Util.setGamepadNavigation(enabled: boolean)
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = enabled
    end
end

function Util.setMenuAttributes(menu: string, open: boolean)
    if menu == "Menu" then
        player:SetAttribute("CCHUD_MenuOpen", open)
    elseif menu == "Character" then
        player:SetAttribute("CCHUD_CharacterMenuOpen", open)
    elseif menu == "Emote" then
        player:SetAttribute("CCHUD_EmoteWheelOpen", open)
    elseif menu == "Owner" then
        player:SetAttribute("CCHUD_OwnerPanelOpen", open)
    end
end

function Util.closeKnownPanels(except: string?)
    local guiNames = {
        {"CursedCollisionAccountUI", "AccountPanel", "Menu"},
        {"CursedCollisionCharacterUI", "CharacterPanel", "Character"},
        {"CursedCollisionOwnerUI", "OwnerPanel", "Owner"},
        {"CursedCollisionEmoteUI", "EmoteWheel", "Emote"}
    }

    for _, entry in ipairs(guiNames) do
        if entry[3] ~= except then
            local gui = player.PlayerGui:FindFirstChild(entry[1])
            local panel = gui and gui:FindFirstChild(entry[2])
            if panel and panel:IsA("GuiObject") then
                panel.Visible = false
            end
            Util.setMenuAttributes(entry[3], false)
        end
    end

    if except ~= "Menu" then
        player:SetAttribute("CCHUD_MenuOpen", false)
    end
end

return Util
