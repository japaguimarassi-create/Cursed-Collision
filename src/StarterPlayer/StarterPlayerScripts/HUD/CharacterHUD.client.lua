--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local combat = remotes and remotes:WaitForChild("CombatAction", 15)
if not combat then
    return
end

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)

local gui = Theme.CreateGui("CursedCollisionHUD_Characters", 65)
local root = Theme.Root(gui)
Theme.ResponsiveScale(root, 760, 0.70, 1.06)

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Theme.Colors.Background
backdrop.BackgroundTransparency = 0.34
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = root

local panel = Theme.Panel(root, "CharacterPanel", UDim2.fromScale(0.88, 0.80))
panel.Visible = false

local title = Theme.Label(panel, "Title", "CHARACTERS", UDim2.fromScale(0.54, 0.08), UDim2.fromScale(0.04, 0.03), 21)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack

local subtitle = Theme.Label(panel, "Subtitle", "SELECT A FIGHTER", UDim2.fromScale(0.55, 0.05), UDim2.fromScale(0.04, 0.095), 8)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = Theme.Colors.Muted

local close = Theme.Button(panel, "Close", "×", UDim2.fromOffset(52, 44), UDim2.fromScale(0.94, 0.03), 44)
close.AnchorPoint = Vector2.new(1, 0)
close.TextSize = 21

local selected = Theme.Label(panel, "Selected", "Potential Man", UDim2.fromScale(0.60, 0.09), UDim2.fromScale(0.04, 0.145), 15)
selected.TextXAlignment = Enum.TextXAlignment.Left
selected.Font = Enum.Font.GothamBlack
selected.TextColor3 = Theme.Colors.Accent

local moveInfo = Theme.Label(panel, "Moves", "", UDim2.fromScale(0.92, 0.08), UDim2.fromScale(0.04, 0.225), 8)
moveInfo.TextXAlignment = Enum.TextXAlignment.Left
moveInfo.TextColor3 = Theme.Colors.Muted

local roster = Instance.new("ScrollingFrame")
roster.Size = UDim2.fromScale(0.92, 0.56)
roster.Position = UDim2.fromScale(0.04, 0.31)
roster.BackgroundTransparency = 1
roster.BorderSizePixel = 0
roster.ScrollBarThickness = 5
roster.AutomaticCanvasSize = Enum.AutomaticSize.Y
roster.CanvasSize = UDim2.fromOffset(0, 0)
roster.Selectable = true
roster.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.31, -8, 0, 68)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = roster

local select = Theme.Button(panel, "Select", "SELECT", UDim2.fromScale(0.22, 0.075), UDim2.fromScale(0.73, 0.895), 56)
select.AnchorPoint = Vector2.new(0.5, 0.5)

local cards: {[string]: TextButton} = {}
local order = {}
for id in pairs(Definitions) do
    table.insert(order, id)
end
table.sort(order)

local selectedId = tostring(player:GetAttribute("CharacterId") or "Yuji")

local function setSelected(id: string)
    local profile = Definitions[id]
    if not profile then
        return
    end

    selectedId = id
    selected.Text = profile.Name
    moveInfo.Text = tostring(profile.Subtitle or "")

    for _, card in pairs(cards) do
        card.BackgroundColor3 = Theme.Colors.Surface2
    end
    if cards[id] then
        cards[id].BackgroundColor3 = Theme.Colors.SurfacePressed
    end
end

for index, id in ipairs(order) do
    local profile = Definitions[id]
    local card = Theme.Button(roster, "Character_" .. id, profile.Name, UDim2.new(), UDim2.new(), 58)
    card.LayoutOrder = index
    card.TextSize = 9
    cards[id] = card
    card.Activated:Connect(function()
        setSelected(id)
    end)
end

local function closePanel()
    panel.Visible = false
    backdrop.Visible = false
    player:SetAttribute("CCHUD_CharacterMenuOpen", false)
end

local function openPanel()
    player:SetAttribute("CCHUD_MenuOpen", false)
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_SettingsOpen", false)
    player:SetAttribute("CCHUD_OwnerPanelOpen", false)
    player:SetAttribute("CCHUD_CharacterMenuOpen", true)
    panel.Visible = true
    backdrop.Visible = true

    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = cards[selectedId] or select
    end
end

close.Activated:Connect(closePanel)
backdrop.Activated:Connect(closePanel)

select.Activated:Connect(function()
    combat:FireServer("SelectCharacter", selectedId)
    closePanel()
end)

player:GetAttributeChangedSignal("CCHUD_CharacterMenuOpen"):Connect(function()
    if player:GetAttribute("CCHUD_CharacterMenuOpen") == true then
        openPanel()
    else
        closePanel()
    end
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    setSelected(tostring(player:GetAttribute("CharacterId") or "Yuji"))
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.M then
        if panel.Visible then
            closePanel()
        else
            openPanel()
        end
    end
end)

setSelected(selectedId)
