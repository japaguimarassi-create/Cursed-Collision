--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Util = require(script.Parent.Util)

local player = Players.LocalPlayer
local M = {}
local started = false

function M.Start()
    if started then return end
    started = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
    local combatAction = remotes and remotes:WaitForChild("CombatAction", 15)
    if not combatAction then return end

    local definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
    local movesets = require(ReplicatedStorage.Characters.CustomMovesets)

    local gui = Util.makeGui("CursedCollisionCharacterUI", 12)
    local root = Util.makeRoot(gui)

    local button = Util.button(root, "CharacterButton", "✦", UDim2.fromScale(0.060, 0.052), UDim2.fromScale(0.075, 0.020), true)
    button.TextSize = 17

    local panel = Instance.new("Frame")
    panel.Name = "CharacterPanel"
    panel.Size = UDim2.fromScale(0.88, 0.80)
    panel.Position = UDim2.fromScale(0.50, 0.51)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Util.Colors.Panel
    panel.BackgroundTransparency = 0.07
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = root
    Util.corner(panel, 16)
    Util.stroke(panel, Util.Colors.Accent2, 0.58, 1.4)

    local panelScale = Instance.new("UIScale")
    panelScale.Scale = 0.95
    panelScale.Parent = panel

    local title = Util.label(panel, "CHARACTERS", UDim2.fromScale(0.50, 0.07), UDim2.fromScale(0.035, 0.025), 18, Enum.Font.GothamBlack)
    title.TextXAlignment = Enum.TextXAlignment.Left
    local sub = Util.label(panel, "SELECT YOUR MOVESET", UDim2.fromScale(0.55, 0.05), UDim2.fromScale(0.035, 0.092), 8)
    sub.TextColor3 = Util.Colors.Muted
    sub.TextXAlignment = Enum.TextXAlignment.Left

    local closeButton = Util.button(panel, "Close", "×", UDim2.fromScale(0.062, 0.078), UDim2.fromScale(0.923, 0.022), true)
    closeButton.TextSize = 22

    local selected = player:GetAttribute("CharacterId") or "PotentialMan"
    local selectedName = Util.label(panel, "", UDim2.fromScale(0.55, 0.08), UDim2.fromScale(0.035, 0.155), 13, Enum.Font.GothamBlack)
    selectedName.TextXAlignment = Enum.TextXAlignment.Left

    local selectedMoves = Util.label(panel, "", UDim2.fromScale(0.55, 0.09), UDim2.fromScale(0.035, 0.225), 8)
    selectedMoves.TextXAlignment = Enum.TextXAlignment.Left
    selectedMoves.TextColor3 = Util.Colors.Muted

    local confirm = Util.button(panel, "Confirm", "SELECT", UDim2.fromScale(0.20, 0.072), UDim2.fromScale(0.72, 0.182), true)
    confirm.TextColor3 = Util.Colors.Accent

    local grid = Instance.new("ScrollingFrame")
    grid.Name = "Roster"
    grid.Size = UDim2.fromScale(0.92, 0.63)
    grid.Position = UDim2.fromScale(0.04, 0.33)
    grid.BackgroundTransparency = 1
    grid.BorderSizePixel = 0
    grid.ScrollBarThickness = 5
    grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    grid.CanvasSize = UDim2.fromOffset(0, 0)
    grid.Parent = panel

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.31, -8, 0, 70)
    layout.CellPadding = UDim2.fromOffset(8, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid

    local cards: {[string]: TextButton} = {}
    local order = {}

    for id in pairs(definitions) do
        table.insert(order, id)
    end
    table.sort(order)

    local function refreshSelected()
        local profile = definitions[selected]
        selectedName.Text = profile and tostring(profile.Name) or selected

        local moves = movesets.Get(selected)
        local names = {}
        for slot = 1, 4 do
            local move = moves[slot]
            names[slot] = tostring(move and move.Name or ("Skill " .. slot))
        end
        selectedMoves.Text = table.concat(names, "  •  ")

        for id, card in pairs(cards) do
            card.BackgroundColor3 = id == selected
                and Color3.fromRGB(51, 42, 71)
                or Util.Colors.Panel
            card.TextColor3 = id == selected
                and Util.Colors.Accent
                or Util.Colors.Text
        end
    end

    for index, id in ipairs(order) do
        local profile = definitions[id]
        local card = Util.button(
            grid,
            "Character_" .. id,
            tostring(profile.Name),
            UDim2.new(0.31, -8, 0, 70),
            UDim2.new(),
            true
        )
        card.LayoutOrder = index
        cards[id] = card

        card.Activated:Connect(function()
            selected = id
            refreshSelected()
        end)
    end

    local function open()
        Util.closeKnownPanels("Character")
        Util.setMenuAttributes("Character", true)
        panel.Visible = true
        panelScale.Scale = 0.94
        TweenService:Create(panelScale, TweenInfo.new(0.14, Enum.EasingStyle.Back), {Scale = 1}):Play()
        Util.setGamepadNavigation(true)
        GuiService.SelectedObject = cards[selected]
    end

    local function closePanel()
        panel.Visible = false
        Util.setMenuAttributes("Character", false)
    end

    button.Activated:Connect(function()
        if panel.Visible then closePanel() else open() end
    end)
    closeButton.Activated:Connect(closePanel)

    confirm.Activated:Connect(function()
        if definitions[selected] then
            combatAction:FireServer("SelectCharacter", selected)
            closePanel()
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.M then
            if panel.Visible then closePanel() else open() end
        end
    end)

    player:GetAttributeChangedSignal("CharacterId"):Connect(function()
        selected = player:GetAttribute("CharacterId") or "PotentialMan"
        refreshSelected()
    end)

    refreshSelected()
end

return M
