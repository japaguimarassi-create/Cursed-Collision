--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD_Topbar"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local function corner(o: GuiObject, r: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
end

local function makeButton(name: string, text: string, x: number): TextButton
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.fromScale(0.065, 0.052)
    b.Position = UDim2.fromScale(x, 0.018)
    b.Text = text
    b.TextSize = 15
    b.Font = Enum.Font.GothamBlack
    b.TextColor3 = Color3.fromRGB(240, 241, 246)
    b.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
    b.BackgroundTransparency = 0.08
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = root
    corner(b, 12)
    local s = Instance.new("UIStroke")
    s.Transparency = 0.46
    s.Color = Color3.fromRGB(78, 81, 99)
    s.Parent = b

    local c = Instance.new("UISizeConstraint")
    c.MinSize = Vector2.new(50, 44)
    c.Parent = b
    return b
end

local character = makeButton("Characters", "♙", 0.03)
local emotes = makeButton("Emotes", "☺", 0.105)
local menu = makeButton("Menu", "☰", 0.18)
local settings = makeButton("Settings", "⚙", 0.255)

local owner = makeButton("Owner", "OWNER", 0.90)
owner.Visible = player:GetAttribute("IsGameOwner") == true
owner.TextSize = 9

local function toggle(attribute: string)
    local value = player:GetAttribute(attribute) == true
    player:SetAttribute(attribute, not value)
end

character.Activated:Connect(function()
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    toggle("CCHUD_CharacterMenuOpen")
end)

emotes.Activated:Connect(function()
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    toggle("CCHUD_EmoteWheelOpen")
end)

menu.Activated:Connect(function()
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    toggle("CCHUD_MenuOpen")
end)

settings.Activated:Connect(function()
    player:SetAttribute("CCHUD_SettingsOpen", not (player:GetAttribute("CCHUD_SettingsOpen") == true))
end)

owner.Activated:Connect(function()
    player:SetAttribute("CCHUD_OwnerPanelOpen", not (player:GetAttribute("CCHUD_OwnerPanelOpen") == true))
end)

player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    owner.Visible = player:GetAttribute("IsGameOwner") == true
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.ButtonStart then
        player:SetAttribute("CCHUD_MenuOpen", not (player:GetAttribute("CCHUD_MenuOpen") == true))
    elseif input.KeyCode == Enum.KeyCode.ButtonSelect then
        player:SetAttribute("CCHUD_SettingsOpen", not (player:GetAttribute("CCHUD_SettingsOpen") == true))
    end
end)

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = menu
    end
end)

if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
    GuiService.GuiNavigationEnabled = true
    GuiService.SelectedObject = menu
end
