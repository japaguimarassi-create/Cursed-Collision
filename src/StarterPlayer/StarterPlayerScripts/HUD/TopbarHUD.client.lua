--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.HUDTheme)
local Layouts = require(script.Parent.HUDLayout)
local ControlMap = require(script.Parent.ControlMap)

local player = Players.LocalPlayer
local platform: ControlMap.Platform = ControlMap:GetPlatform(UserInputService.PreferredInput)
local layout = Layouts:Get(platform)

local gui = Theme.CreateGui("CursedCollisionHUD_Topbar", 40)
local root = Theme.Root(gui)

Theme.ResponsiveScale(root, 900, 0.80, 1.05)

local capsule = Instance.new("Frame")
capsule.Name = "UtilityCapsule"
capsule.Size = UDim2.fromScale(platform == "Mobile" and 0.42 or 0.34, 0.064)
capsule.Position = UDim2.fromScale(0.50, 0.024)
capsule.AnchorPoint = Vector2.new(0.5, 0)
capsule.BackgroundColor3 = Theme.Colors.Surface
capsule.BackgroundTransparency = 0.10
capsule.BorderSizePixel = 0
capsule.Parent = root
Theme.Corner(capsule, 22)
Theme.Stroke(capsule, 0.36, 1.1)

local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Horizontal
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Center
list.Padding = UDim.new(0, 5)
list.Parent = capsule

local function makeButton(name: string, icon: string, wideIcon: string, width: number): TextButton
    local button = Theme.Button(
        capsule,
        name,
        platform == "Mobile" and icon or wideIcon,
        UDim2.fromOffset(width, layout.TopbarHeight - 6),
        UDim2.new(),
        platform == "Mobile" and 44 or 42
    )
    button.TextSize = platform == "Mobile" and 16 or 9
    return button
end

local characters = makeButton(
    "Characters",
    "♙",
    "♙  CHARACTERS",
    platform == "Mobile" and 48 or 104
)

local emotes = makeButton(
    "Emotes",
    "☺",
    "☺  EMOTES",
    platform == "Mobile" and 48 or 82
)

local credits = makeButton(
    "Credits",
    "◉",
    "◉  " .. tostring(player:GetAttribute("Credits") or 0),
    platform == "Mobile" and 48 or 84
)
credits.TextColor3 = Theme.Colors.Warning

local settings = makeButton(
    "Settings",
    "⚙",
    "⚙  SETTINGS",
    platform == "Mobile" and 48 or 92
)

local owner = makeButton(
    "Owner",
    "◆",
    "◆  OWNER",
    platform == "Mobile" and 48 or 78
)
owner.TextColor3 = Theme.Colors.Warning
owner.Visible = player:GetAttribute("IsGameOwner") == true

local function closePanels()
    Theme.CloseCombatAttributes(player)
end

characters.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_CharacterMenuOpen", true)
end)

emotes.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
end)

credits.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_MenuSection", "Rewards")
    player:SetAttribute("CCHUD_MenuOpen", true)
end)

settings.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_SettingsOpen", true)
end)

owner.Activated:Connect(function()
    if player:GetAttribute("IsGameOwner") == true then
        closePanels()
        player:SetAttribute("CCHUD_OwnerPanelOpen", true)
    end
end)

player:GetAttributeChangedSignal("IsGameOwner"):Connect(function()
    owner.Visible = player:GetAttribute("IsGameOwner") == true
end)

player:GetAttributeChangedSignal("Credits"):Connect(function()
    if platform ~= "Mobile" then
        credits.Text = "◉  " .. tostring(player:GetAttribute("Credits") or 0)
    end
end)

local function updatePlatform()
    platform = ControlMap:GetPlatform(UserInputService.PreferredInput)
    layout = Layouts:Get(platform)

    capsule.Size = UDim2.fromScale(
        platform == "Mobile" and 0.42 or 0.34,
        0.064
    )

    characters.Text = platform == "Mobile" and "♙" or "♙  CHARACTERS"
    emotes.Text = platform == "Mobile" and "☺" or "☺  EMOTES"
    credits.Text = platform == "Mobile"
        and "◉"
        or "◉  " .. tostring(player:GetAttribute("Credits") or 0)
    settings.Text = platform == "Mobile" and "⚙" or "⚙  SETTINGS"
    owner.Text = platform == "Mobile" and "◆" or "◆  OWNER"
    owner.Visible = player:GetAttribute("IsGameOwner") == true
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updatePlatform)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.M then
        player:SetAttribute("CCHUD_MenuSection", "Shop")
        player:SetAttribute("CCHUD_MenuOpen", true)
    elseif input.KeyCode == Enum.KeyCode.ButtonStart then
        player:SetAttribute("CCHUD_MenuSection", "Shop")
        player:SetAttribute("CCHUD_MenuOpen", true)
    elseif input.KeyCode == Enum.KeyCode.ButtonSelect then
        player:SetAttribute("CCHUD_SettingsOpen", true)
    end
end)

local function updateNavigation()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = characters
    end
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateNavigation)

updatePlatform()
updateNavigation()
