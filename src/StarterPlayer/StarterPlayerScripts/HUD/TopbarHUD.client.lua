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

Theme.ResponsiveScale(root, 900, 0.78, 1.06)

local left = Instance.new("Frame")
left.Name = "LeftUtility"
left.Size = UDim2.fromScale(platform == "Mobile" and 0.24 or 0.29, 0.075)
left.Position = UDim2.fromScale(0.018, 0.018)
left.BackgroundTransparency = 1
left.Parent = root

local right = Instance.new("Frame")
right.Name = "RightUtility"
right.Size = UDim2.fromScale(platform == "Mobile" and 0.25 or 0.30, 0.075)
right.Position = UDim2.fromScale(0.982, 0.018)
right.AnchorPoint = Vector2.new(1, 0)
right.BackgroundTransparency = 1
right.Parent = root

local function capsule(parent: Frame, name: string, width: number): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.fromOffset(width, layout.TopbarHeight)
    frame.BackgroundColor3 = Theme.Colors.Surface
    frame.BackgroundTransparency = 0.10
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Theme.Corner(frame, 18)
    Theme.Stroke(frame, 0.42, 1)
    return frame
end

local leftCapsule = capsule(left, "Main", platform == "Mobile" and 174 or 252)
local rightCapsule = capsule(right, "Meta", platform == "Mobile" and 176 or 250)

local function button(parent: Frame, name: string, icon: string, text: string, width: number): TextButton
    local result = Theme.Button(parent, name, platform == "Mobile" and icon or text, UDim2.fromOffset(width, layout.TopbarHeight - 4), UDim2.new(), 38)
    result.TextSize = platform == "Mobile" and 15 or 8
    return result
end

local leftList = Instance.new("UIListLayout")
leftList.FillDirection = Enum.FillDirection.Horizontal
leftList.HorizontalAlignment = Enum.HorizontalAlignment.Left
leftList.VerticalAlignment = Enum.VerticalAlignment.Center
leftList.Padding = UDim.new(0, 3)
leftList.Parent = leftCapsule

local rightList = Instance.new("UIListLayout")
rightList.FillDirection = Enum.FillDirection.Horizontal
rightList.HorizontalAlignment = Enum.HorizontalAlignment.Right
rightList.VerticalAlignment = Enum.VerticalAlignment.Center
rightList.Padding = UDim.new(0, 3)
rightList.Parent = rightCapsule

local characters = button(leftCapsule, "Characters", "♙", "♙  CHARACTERS", platform == "Mobile" and 52 or 102)
local emotes = button(leftCapsule, "Emotes", "✦", "✦  EMOTES", platform == "Mobile" and 52 or 82)
local more = button(leftCapsule, "More", "•••", "•••  MORE", platform == "Mobile" and 52 or 66)

local credits = button(rightCapsule, "Credits", "C", "C  " .. tostring(player:GetAttribute("Credits") or 0), platform == "Mobile" and 52 or 78)
credits.TextColor3 = Theme.Colors.Warning

local settings = button(rightCapsule, "Settings", "⚙", "⚙  SETTINGS", platform == "Mobile" and 52 or 94)

local owner = button(rightCapsule, "Owner", "★", "★  OWNER", platform == "Mobile" and 52 or 76)
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

more.Activated:Connect(function()
    closePanels()
    player:SetAttribute("CCHUD_MenuSection", "Shop")
    player:SetAttribute("CCHUD_MenuOpen", true)
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
        credits.Text = "C  " .. tostring(player:GetAttribute("Credits") or 0)
    end
end)

local function updatePlatform()
    platform = ControlMap:GetPlatform(UserInputService.PreferredInput)
    layout = Layouts:Get(platform)

    leftCapsule.Size = UDim2.fromOffset(platform == "Mobile" and 174 or 252, layout.TopbarHeight)
    rightCapsule.Size = UDim2.fromOffset(platform == "Mobile" and 176 or 250, layout.TopbarHeight)

    characters.Text = platform == "Mobile" and "♙" or "♙  CHARACTERS"
    emotes.Text = platform == "Mobile" and "✦" or "✦  EMOTES"
    more.Text = platform == "Mobile" and "•••" or "•••  MORE"
    credits.Text = platform == "Mobile" and "C" or "C  " .. tostring(player:GetAttribute("Credits") or 0)
    settings.Text = platform == "Mobile" and "⚙" or "⚙  SETTINGS"
    owner.Text = platform == "Mobile" and "★" or "★  OWNER"
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