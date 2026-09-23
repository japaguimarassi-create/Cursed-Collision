--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local combat = remotes and remotes:WaitForChild("CombatAction", 15)
if not combat then return end

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD_Characters"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 25
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(3,4,7)
backdrop.BackgroundTransparency = 0.30
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.88, 0.80)
panel.Position = UDim2.fromScale(0.50, 0.51)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(11,13,19)
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = root

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,18)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(157,117,255)
stroke.Transparency = 0.25
stroke.Thickness = 1.5
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.60,0.09)
title.Position = UDim2.fromScale(0.04,0.03)
title.BackgroundTransparency = 1
title.Text = "CHARACTERS"
title.Font = Enum.Font.GothamBlack
title.TextSize = 21
title.TextColor3 = Color3.fromRGB(240,241,246)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromScale(0.07,0.075)
close.Position = UDim2.fromScale(0.92,0.025)
close.Text = "×"
close.Font = Enum.Font.GothamBlack
close.TextSize = 22
close.TextColor3 = Color3.fromRGB(240,241,246)
close.BackgroundColor3 = Color3.fromRGB(20,23,31)
close.BorderSizePixel = 0
close.Parent = panel

local selected = Instance.new("TextLabel")
selected.Size = UDim2.fromScale(0.87,0.11)
selected.Position = UDim2.fromScale(0.04,0.13)
selected.BackgroundTransparency = 1
selected.Text = "Potential Man"
selected.Font = Enum.Font.GothamBlack
selected.TextSize = 16
selected.TextColor3 = Color3.fromRGB(157,117,255)
selected.TextXAlignment = Enum.TextXAlignment.Left
selected.Parent = panel

local grid = Instance.new("ScrollingFrame")
grid.Size = UDim2.fromScale(0.92,0.68)
grid.Position = UDim2.fromScale(0.04,0.26)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 4
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.CanvasSize = UDim2.fromOffset(0,0)
grid.Selectable = true
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.31, -8, 0, 66)
layout.CellPadding = UDim2.fromOffset(8,8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local selectButton = Instance.new("TextButton")
selectButton.Size = UDim2.fromScale(0.22,0.065)
selectButton.Position = UDim2.fromScale(0.72,0.86)
selectButton.Text = "SELECT"
selectButton.Font = Enum.Font.GothamBlack
selectButton.TextSize = 10
selectButton.TextColor3 = Color3.fromRGB(220,235,255)
selectButton.BackgroundColor3 = Color3.fromRGB(37,29,55)
selectButton.BorderSizePixel = 0
selectButton.Parent = panel

for _,b in ipairs({close,selectButton}) do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,10)
    c.Parent = b
end

local selectedId = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
local cards: {[string]: TextButton} = {}

local function setSelected(id: string)
    local data = Definitions[id]
    if not data then return end
    selectedId = id
    selected.Text = data.Name .. "  •  " .. tostring(data.Subtitle or "")
    for id2,b in pairs(cards) do
        b.BackgroundColor3 = id2 == id and Color3.fromRGB(52,39,74) or Color3.fromRGB(21,24,32)
    end
end

local ids = {}
for id in pairs(Definitions) do table.insert(ids,id) end
table.sort(ids)

for index,id in ipairs(ids) do
    local data = Definitions[id]
    local b = Instance.new("TextButton")
    b.Name = id
    b.LayoutOrder = index
    b.Text = data.Name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.TextWrapped = true
    b.TextColor3 = Color3.fromRGB(239,240,245)
    b.BackgroundColor3 = Color3.fromRGB(21,24,32)
    b.BorderSizePixel = 0
    b.Selectable = true
    b.Active = true
    b.Parent = grid
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,11)
    c.Parent = b
    b.Activated:Connect(function() setSelected(id) end)
    cards[id] = b
end

local function closePanel()
    panel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
end

local function openPanel()
    panel.Visible = true
    backdrop.Visible = true
    player:SetAttribute("CCHUD_CharacterMenuOpen", true)
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", false)
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = selectButton
    end
end

selectButton.Activated:Connect(function()
    combat:FireServer("SelectCharacter", selectedId)
    closePanel()
end)
close.Activated:Connect(closePanel)
backdrop.Activated:Connect(closePanel)

for _,attribute in ipairs({"CCHUD_CharacterMenuOpen"}) do
    player:GetAttributeChangedSignal(attribute):Connect(function()
        if player:GetAttribute(attribute) == true then openPanel() else closePanel() end
    end)
end

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    setSelected(tostring(player:GetAttribute("CharacterId") or "PotentialMan"))
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M then
        if panel.Visible then closePanel() else openPanel() end
    end
end)

setSelected(selectedId)
