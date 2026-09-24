--!strict

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Theme = require(script.Parent.HUDTheme)
local Layouts = require(script.Parent.HUDLayout)

local player = Players.LocalPlayer
local platform = Theme.Platform()
local layout = Layouts:Get(platform)

local gui = Theme.CreateGui("CursedCollisionHUD_Topbar", 40)
local root = Theme.Root(gui)

local function makeButton(parent: Instance, name: string, text: string, width: number)
    local button = Theme.Button(
        parent,
        name,
        text,
        UDim2.fromOffset(width, layout.TopbarHeight),
        UDim2.new(),
        platform == "Mobile" and 46 or 42
    )
    button.TextSize = platform == "Mobile" and 18 or 10
    return button
end

local capsule = Instance.new("Frame")
capsule.Name = "JJSInspiredCapsule"
capsule.Size = UDim2.fromOffset(
    platform == "Mobile" and 160 or 224,
    layout.TopbarHeight
)
capsule.Position = UDim2.fromScale(0.50, 0.022)
capsule.AnchorPoint = Vector2.new(0.5, 0)
capsule.BackgroundColor3 = Theme.Colors.Surface
capsule.BackgroundTransparency = 0.06
capsule.BorderSizePixel = 0
capsule.Parent = root
Theme.Corner(capsule, 22)
Theme.Stroke(capsule, 0.34, 1.1)

local capsuleLayout = Instance.new("UIListLayout")
capsuleLayout.FillDirection = Enum.FillDirection.Horizontal
capsuleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
capsuleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
capsuleLayout.Padding = UDim.new(0, 5)
capsuleLayout.Parent = capsule

local menu = makeButton(
    capsule,
    "Menu",
    platform == "Mobile" and "☰" or "☰  MENU",
    platform == "Mobile" and 44 or 76
)

local chat = makeButton(
    capsule,
    "Chat",
    platform == "Mobile" and "▢" or "▢  CHAT",
    platform == "Mobile" and 44 or 72
)

local more = makeButton(
    capsule,
    "More",
    platform == "Mobile" and "•••" or "•••  MORE",
    platform == "Mobile" and 52 or 76
)

local function closePanels()
    Theme.CloseCombatAttributes(player)
end

local function openMenu(section: string?)
    closePanels()
    player:SetAttribute("CCHUD_MenuSection", section or "Shop")
    player:SetAttribute("CCHUD_MenuOpen", true)
end

menu.Activated:Connect(function()
    if player:GetAttribute("CCHUD_MenuOpen") == true then
        player:SetAttribute("CCHUD_MenuOpen", false)
    else
        openMenu("Shop")
    end
end)

more.Activated:Connect(function()
    openMenu("Rewards")
end)

chat.Activated:Connect(function()
    pcall(function()
        StarterGui:SetCore("ChatActive", true)
    end)

    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    end)
end)

local left = Instance.new("Frame")
left.Name = "UtilityButtons"
left.Size = UDim2.fromOffset(
    platform == "Mobile" and 112 or 190,
    layout.TopbarHeight
)
left.Position = UDim2.fromScale(0.018, 0.022)
left.BackgroundTransparency = 1
left.Parent = root

local leftLayout = Instance.new("UIListLayout")
leftLayout.FillDirection = Enum.FillDirection.Horizontal
leftLayout.Padding = UDim.new(0, 6)
leftLayout.Parent = left

local characters = makeButton(
    left,
    "Characters",
    platform == "Mobile" and "♙" or "♙  CHARACTERS",
    platform == "Mobile" and 48 or 112
)
characters.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_CharacterMenuOpen", true)
end)

local emotes = makeButton(
    left,
    "Emotes",
    platform == "Mobile" and "☺" or "☺  EMOTES",
    platform == "Mobile" and 48 or 80
)
emotes.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
end)

local right = Instance.new("Frame")
right.Name = "RightButtons"
right.Size = UDim2.fromOffset(
    platform == "Mobile" and 54 or 210,
    layout.TopbarHeight
)
right.Position = UDim2.fromScale(0.982, 0.022)
right.AnchorPoint = Vector2.new(1, 0)
right.BackgroundTransparency = 1
right.Parent = root

local rightLayout = Instance.new("UIListLayout")
rightLayout.FillDirection = Enum.FillDirection.Horizontal
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightLayout.Padding = UDim.new(0, 6)
rightLayout.Parent = right

local credits = makeButton(
    right,
    "Credits",
    platform == "Mobile" and "C" or "C  CREDITS",
    platform == "Mobile" and 52 or 92
)
credits.TextColor3 = Theme.Colors.Warning
credits.Activated:Connect(function()
    openMenu("Rewards")
end)

local settings = makeButton(
    right,
    "Settings",
    platform == "Mobile" and "⚙" or "⚙  SETTINGS",
    platform == "Mobile" and 52 or 92
)
settings.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_SettingsOpen", true)
end)

local owner = makeButton(
    right,
    "Owner",
    platform == "Mobile" and "O" or "OWNER",
    platform == "Mobile" and 52 or 72
)
owner.TextColor3 = Theme.Colors.Warning
owner.Visible = player:GetAttribute("IsGameOwner") == true
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
        credits.Text = "C  " .. tostring(player:GetAttribute("Credits") or 0)
    end
end)

local function updatePlatform()
    platform = Theme.Platform()

    capsule.Size = UDim2.fromOffset(
        platform == "Mobile" and 160 or 224,
        layout.TopbarHeight
    )

    left.Size = UDim2.fromOffset(
        platform == "Mobile" and 112 or 190,
        layout.TopbarHeight
    )

    right.Size = UDim2.fromOffset(
        platform == "Mobile" and 54 or 210,
        layout.TopbarHeight
    )

    if platform == "Mobile" then
        menu.Text = "☰"
        chat.Text = "▢"
        more.Text = "•••"
        characters.Text = "♙"
        emotes.Text = "☺"
        credits.Text = "C"
        settings.Text = "⚙"
        owner.Text = "O"
    else
        menu.Text = "☰  MENU"
        chat.Text = "▢  CHAT"
        more.Text = "•••  MORE"
        characters.Text = "♙  CHARACTERS"
        emotes.Text = "☺  EMOTES"
        credits.Text = "C  CREDITS"
        settings.Text = "⚙  SETTINGS"
        owner.Text = "OWNER"
    end

    owner.Visible = player:GetAttribute("IsGameOwner") == true
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updatePlatform)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.ButtonStart then
        openMenu("Shop")
    elseif input.KeyCode == Enum.KeyCode.ButtonSelect then
        closePanels()
        player:SetAttribute("CCHUD_SettingsOpen", true)
    elseif input.KeyCode == Enum.KeyCode.M then
        openMenu("Shop")
    end
end)

local function updateNavigation()
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = menu
    end
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateNavigation)
updatePlatform()
updateNavigation()
