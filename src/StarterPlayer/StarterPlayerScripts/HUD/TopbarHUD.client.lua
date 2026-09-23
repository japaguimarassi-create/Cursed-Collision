--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local gui = Theme.CreateGui("CursedCollisionHUD_Topbar", 40)
local root = Theme.Root(gui)

local function openOnly(attribute: string)
    Theme.CloseCombatAttributes(player)
    player:SetAttribute(attribute, true)
end

local function makeTopButton(parent: Instance, name: string, text: string): TextButton
    return Theme.Button(parent, name, text, UDim2.fromOffset(84, 48), UDim2.new())
end

local left = Instance.new("Frame")
left.Size = UDim2.fromScale(0.47, 0.072)
left.Position = UDim2.fromScale(0.018, 0.018)
left.BackgroundTransparency = 1
left.Parent = root

local leftLayout = Instance.new("UIListLayout")
leftLayout.FillDirection = Enum.FillDirection.Horizontal
leftLayout.Padding = UDim.new(0, 6)
leftLayout.Parent = left

local characters = makeTopButton(left, "Characters", "♙  CHARACTERS")
characters.Size = UDim2.fromOffset(124, 48)
characters.Activated:Connect(function()
    openOnly("CCHUD_CharacterMenuOpen")
end)

local emotes = makeTopButton(left, "Emotes", "☺  EMOTES")
emotes.Size = UDim2.fromOffset(98, 48)
emotes.Activated:Connect(function()
    openOnly("CCHUD_EmoteWheelOpen")
end)

local menu = makeTopButton(left, "Menu", "☰  MENU")
menu.Activated:Connect(function()
    openOnly("CCHUD_MenuOpen")
end)

local right = Instance.new("Frame")
right.Size = UDim2.fromScale(0.40, 0.072)
right.Position = UDim2.fromScale(0.982, 0.018)
right.AnchorPoint = Vector2.new(1, 0)
right.BackgroundTransparency = 1
right.Parent = root

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Horizontal
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightLayout.Padding = UDim.new(0, 6)
rightLayout.Parent = right

local leaderboard = makeTopButton(right, "Leaderboard", "♛  PLAYERS")
leaderboard.Size = UDim2.fromOffset(98, 48)
leaderboard.Activated:Connect(function()
    openOnly("CCHUD_MenuOpen")
    player:SetAttribute("CCHUD_MenuSection", "Leaderboard")
end)

local settings = makeTopButton(right, "Settings", "⚙  SETTINGS")
settings.Size = UDim2.fromOffset(98, 48)
settings.Activated:Connect(function()
    Theme.CloseCombatAttributes(player)
    player:SetAttribute("CCHUD_SettingsOpen", true)
end)

local owner = makeTopButton(right, "Owner", "OWNER")
owner.Size = UDim2.fromOffset(78, 48)
owner.TextColor3 = Theme.Colors.Warning
owner.Visible = player:GetAttribute("IsGameOwner") == true
owner.Activated:Connect(function()
    Theme.CloseCombatAttributes(player)
    player:SetAttribute("CCHUD_OwnerPanelOpen", true)
end)

player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    owner.Visible = player:GetAttribute("IsGameOwner") == true
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.ButtonStart then
        openOnly("CCHUD_MenuOpen")
    elseif input.KeyCode == Enum.KeyCode.ButtonSelect then
        Theme.CloseCombatAttributes(player)
        player:SetAttribute("CCHUD_SettingsOpen", true)
    elseif input.KeyCode == Enum.KeyCode.M then
        openOnly("CCHUD_MenuOpen")
    end
end)

local function updateNavigation()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = menu
    end
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateNavigation)
updateNavigation()
