--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotes then
    return
end

local combatAction = remotes:WaitForChild("CombatAction", 15)
if not combatAction then
    return
end

local definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionCharacterUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 12
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local function corner(parent: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: GuiObject, color: Color3, transparency: number)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency
    s.Thickness = 1
    s.Parent = parent
end

local function button(parent: Instance, name: string, textValue: string, size: UDim2, position: UDim2)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = textValue
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = Color3.fromRGB(23, 25, 33)
    b.BackgroundTransparency = 0.05
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(240, 241, 246)
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 11
    b.AutoButtonColor = true
    b.Active = true
    b.Selectable = true
    b.Parent = parent
    corner(b, 13)
    stroke(b, Color3.fromRGB(76, 78, 95), 0.55)
    return b
end

local function label(parent: Instance, textValue: string, size: UDim2, position: UDim2, textSize: number)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = size
    l.Position = position
    l.Text = textValue
    l.TextColor3 = Color3.fromRGB(239, 240, 245)
    l.Font = Enum.Font.GothamBold
    l.TextSize = textSize
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local characterButton = button(
    root,
    "CharacterButton",
    "CHARACTERS",
    UDim2.fromScale(0.12, 0.06),
    UDim2.fromScale(0.145, 0.022)
)

local panel = Instance.new("Frame")
panel.Name = "CharacterPanel"
panel.Size = UDim2.fromScale(0.90, 0.82)
panel.Position = UDim2.fromScale(0.50, 0.51)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = root
corner(panel, 18)
stroke(panel, Color3.fromRGB(155, 112, 255), 1.4)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(310, 460)
sizeConstraint.MaxSize = Vector2.new(920, 740)
sizeConstraint.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Scale = 0.96
panelScale.Parent = panel

label(panel, "CHARACTERS", UDim2.fromScale(0.46, 0.075), UDim2.fromScale(0.035, 0.027), 20)
local subtitle = label(panel, "SELECT A FIGHTER", UDim2.fromScale(0.40, 0.05), UDim2.fromScale(0.035, 0.095), 9)
subtitle.TextColor3 = Color3.fromRGB(155, 158, 176)

local close = button(panel, "Close", "×", UDim2.fromScale(0.07, 0.075), UDim2.fromScale(0.92, 0.025))
close.TextSize = 22

local selectedCard = Instance.new("Frame")
selectedCard.Size = UDim2.fromScale(0.94, 0.14)
selectedCard.Position = UDim2.fromScale(0.03, 0.15)
selectedCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
selectedCard.BorderSizePixel = 0
selectedCard.Parent = panel
corner(selectedCard, 12)
stroke(selectedCard, Color3.fromRGB(69, 72, 90), 1)

local selectedName = label(selectedCard, "Potential Man", UDim2.fromScale(0.48, 0.34), UDim2.fromScale(0.025, 0.12), 15)
local selectedTitle = label(selectedCard, "", UDim2.fromScale(0.85, 0.26), UDim2.fromScale(0.025, 0.49), 9)
selectedTitle.TextColor3 = Color3.fromRGB(155, 158, 176)

local confirm = button(
    selectedCard,
    "Confirm",
    "SELECT",
    UDim2.fromScale(0.23, 0.58),
    UDim2.fromScale(0.74, 0.21)
)
confirm.TextColor3 = Color3.fromRGB(180, 235, 255)

local grid = Instance.new("ScrollingFrame")
grid.Name = "Roster"
grid.Size = UDim2.fromScale(0.94, 0.66)
grid.Position = UDim2.fromScale(0.03, 0.32)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 5
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.CanvasSize = UDim2.fromOffset(0, 0)
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.31, -8, 0, 72)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local selectedId = player:GetAttribute("CharacterId") or "PotentialMan"
local cards = {}

local order = {}
for id in pairs(definitions) do
    table.insert(order, id)
end
table.sort(order)

local function setSelected(id: string)
    local profile = definitions[id]
    if not profile then
        return
    end

    selectedId = id
    selectedName.Text = profile.Name
    selectedTitle.Text = (profile.Subtitle or "") .. "  •  " .. (profile.Archetype or "")

    for cardId, card in pairs(cards) do
        card.BackgroundColor3 = cardId == id
            and Color3.fromRGB(55, 43, 72)
            or Color3.fromRGB(23, 25, 33)
    end

    local moves = movesets.Get(id)
    local names = {}

    for slot = 1, 4 do
        local move = moves[slot]
        names[slot] = move and move.Name or ("Skill " .. tostring(slot))
    end

    selectedTitle.Text = table.concat(names, "  •  ")
end

for index, id in ipairs(order) do
    local profile = definitions[id]
    local card = button(
        grid,
        "Character_" .. id,
        profile.Name,
        UDim2.fromScale(0.31, 0.11),
        UDim2.new()
    )

    card.LayoutOrder = index
    card.TextWrapped = true
    card.TextSize = 10
    cards[id] = card

    card.Activated:Connect(function()
        setSelected(id)
    end)
end

local function setOpen(open: boolean)
    panel.Visible = open
    player:SetAttribute("CCHUD_CharacterMenuOpen", open)

    if open then
        player:SetAttribute("CCHUD_MenuOpen", true)
        local accountGui = playerGui:FindFirstChild("CursedCollisionAccountUI")
        local accountPanel = accountGui and accountGui:FindFirstChild("AccountPanel")
        if accountPanel and accountPanel:IsA("GuiObject") then
            accountPanel.Visible = false
        end

        panelScale.Scale = 0.96
        TweenService:Create(panelScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Scale = 1}):Play()
    else
        if player:GetAttribute("CCHUD_MenuOpen") == true then
            player:SetAttribute("CCHUD_MenuOpen", false)
        end
    end
end

characterButton.Activated:Connect(function()
    setOpen(not panel.Visible)
end)

close.Activated:Connect(function()
    setOpen(false)
end)

confirm.Activated:Connect(function()
    if selectedId ~= "" then
        combatAction:FireServer("SelectCharacter", selectedId)
        setOpen(false)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.M then
        setOpen(not panel.Visible)
    end
end)

player:GetAttributeChangedSignal("CharacterId"):Connect(function()
    selectedId = player:GetAttribute("CharacterId") or "PotentialMan"
    setSelected(selectedId)
end)

setSelected(selectedId)
setOpen(false)
