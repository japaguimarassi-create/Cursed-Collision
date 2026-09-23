--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
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

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local Roster = require(ReplicatedStorage.Characters.PlayableRoster)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local existing = playerGui:FindFirstChild("CursedCollisionCharacterUI")
if existing then
    existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionCharacterUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 12
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local function refreshScale()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local shortAxis = math.min(
        camera.ViewportSize.X,
        camera.ViewportSize.Y
    )

    scale.Scale = math.clamp(shortAxis / 720, 0.74, 1.06)
end

refreshScale()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    refreshScale()

    local camera = workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
    end
end)

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

local function corner(parent: GuiObject, radius: number)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius)
    ui.Parent = parent
end

local function stroke(parent: GuiObject, transparency: number)
    local ui = Instance.new("UIStroke")
    ui.Thickness = 1
    ui.Transparency = transparency
    ui.Parent = parent
end

local function text(
    parent: Instance,
    value: string,
    size: UDim2,
    position: UDim2,
    textSize: number
): TextLabel
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Text = value
    label.TextColor3 = Color3.fromRGB(238, 240, 247)
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function button(
    parent: Instance,
    name: string,
    value: string,
    size: UDim2,
    position: UDim2
): TextButton
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Text = value
    object.TextColor3 = Color3.fromRGB(238, 240, 247)
    object.Font = Enum.Font.GothamBlack
    object.TextSize = 11
    object.TextWrapped = true
    object.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    object.BackgroundTransparency = 0.05
    object.BorderSizePixel = 0
    object.AutoButtonColor = true
    object.Active = true
    object.Selectable = true
    object.Parent = parent
    corner(object, 13)
    stroke(object, 0.60)
    return object
end

local openButton = button(
    root,
    "CharacterButton",
    "CHARACTERS",
    UDim2.fromScale(0.125, 0.060),
    UDim2.fromScale(0.14, 0.018)
)

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(3, 4, 7)
overlay.BackgroundTransparency = 0.28
overlay.Visible = false
overlay.Parent = root

local panel = Instance.new("Frame")
panel.Name = "CharacterPanel"
panel.Size = UDim2.fromScale(0.90, 0.82)
panel.Position = UDim2.fromScale(0.5, 0.50)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(9, 11, 17)
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = root

local panelLimit = Instance.new("UISizeConstraint")
panelLimit.MinSize = Vector2.new(300, 420)
panelLimit.MaxSize = Vector2.new(920, 740)
panelLimit.Parent = panel

corner(panel, 20)
stroke(panel, 0.30)

local panelScale = Instance.new("UIScale")
panelScale.Scale = 0.94
panelScale.Parent = panel

local title = text(
    panel,
    "CHARACTERS",
    UDim2.fromScale(0.58, 0.08),
    UDim2.fromScale(0.035, 0.03),
    20
)

local subtitle = text(
    panel,
    "FOCUSED ROSTER • 4 FIGHTERS",
    UDim2.fromScale(0.60, 0.05),
    UDim2.fromScale(0.035, 0.095),
    9
)

subtitle.TextColor3 = Color3.fromRGB(154, 158, 176)

local close = button(
    panel,
    "Close",
    "×",
    UDim2.fromScale(0.075, 0.075),
    UDim2.fromScale(0.92, 0.025)
)
close.TextSize = 22

local selected = Instance.new("Frame")
selected.Size = UDim2.fromScale(0.94, 0.17)
selected.Position = UDim2.fromScale(0.03, 0.15)
selected.BackgroundColor3 = Color3.fromRGB(19, 22, 30)
selected.BorderSizePixel = 0
selected.Parent = panel

corner(selected, 13)
stroke(selected, 0.48)

local selectedName = text(
    selected,
    "Yuji Itadori",
    UDim2.fromScale(0.50, 0.30),
    UDim2.fromScale(0.025, 0.09),
    16
)

local selectedTitle = text(
    selected,
    "Black Flash Momentum",
    UDim2.fromScale(0.65, 0.23),
    UDim2.fromScale(0.025, 0.42),
    9
)

selectedTitle.TextColor3 = Color3.fromRGB(158, 162, 180)

local selectedMoves = text(
    selected,
    "",
    UDim2.fromScale(0.67, 0.24),
    UDim2.fromScale(0.025, 0.70),
    8
)

selectedMoves.TextColor3 = Color3.fromRGB(126, 131, 150)

local confirm = button(
    selected,
    "Confirm",
    "SELECT",
    UDim2.fromScale(0.23, 0.58),
    UDim2.fromScale(0.74, 0.21)
)

local grid = Instance.new("ScrollingFrame")
grid.Name = "Roster"
grid.Size = UDim2.fromScale(0.94, 0.63)
grid.Position = UDim2.fromScale(0.03, 0.34)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 4
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.CanvasSize = UDim2.fromOffset(0, 0)
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.48, -8, 0, 96)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local cards: {[string]: TextButton} = {}
local selectedId = player:GetAttribute("CharacterId") or Roster.Default

local function setSelected(id: string)
    local definition = Definitions[id]
    if not definition then
        return
    end

    selectedId = id
    selectedName.Text = definition.Name
    selectedTitle.Text = definition.Subtitle

    local moves = Movesets.Get(
        id,
        player:GetAttribute("AwakeningActive") == true
            or player:GetAttribute("UltimateActive") == true
    )

    local names = {}
    for slot = 1, 4 do
        names[slot] = moves[slot] and moves[slot].Name or "Skill"
    end

    selectedMoves.Text = table.concat(names, "  •  ")

    for cardId, card in pairs(cards) do
        card.BackgroundColor3 = cardId == id
            and Color3.fromRGB(54, 43, 76)
            or Color3.fromRGB(20, 23, 31)
    end
end

local function render()
    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end

    table.clear(cards)

    for index, id in ipairs(Roster.Order) do
        local definition = Definitions[id]
        if definition then
            local card = button(
                grid,
                "Character_" .. id,
                definition.Name
                    .. "\n"
                    .. definition.Subtitle,
                UDim2.new(0.48, 0, 0, 96),
                UDim2.new()
            )

            card.LayoutOrder = index
            cards[id] = card

            card.Activated:Connect(function()
                setSelected(id)
            end)
        end
    end

    setSelected(selectedId)
end

local function closeOtherMenus()
    local accountGui = playerGui:FindFirstChild("CursedCollisionAccountUI")
    local accountPanel = accountGui and accountGui:FindFirstChild("AccountPanel")
    if accountPanel and accountPanel:IsA("GuiObject") then
        accountPanel.Visible = false
    end

    local ownerGui = playerGui:FindFirstChild("CursedCollisionOwnerUI")
    local ownerPanel = ownerGui and ownerGui:FindFirstChild("OwnerPanel")
    if ownerPanel and ownerPanel:IsA("GuiObject") then
        ownerPanel.Visible = false
    end
end

local function setOpen(open: boolean)
    panel.Visible = open
    overlay.Visible = open
    player:SetAttribute("CCHUD_CharacterMenuOpen", open)

    if open then
        closeOtherMenus()
        player:SetAttribute("CCHUD_MenuOpen", true)

        panelScale.Scale = 0.94
        TweenService:Create(
            panelScale,
            TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()

        if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
            GuiService.GuiNavigationEnabled = true
            GuiService.SelectedObject = cards[selectedId]
        end
    else
        if player:GetAttribute("CCHUD_MenuOpen") == true then
            player:SetAttribute("CCHUD_MenuOpen", false)
        end
        GuiService.SelectedObject = nil
    end
end

openButton.Activated:Connect(function()
    setOpen(not panel.Visible)
end)

close.Activated:Connect(function()
    setOpen(false)
end)

overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        setOpen(false)
    end
end)

confirm.Activated:Connect(function()
    if Definitions[selectedId] then
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
    selectedId = player:GetAttribute("CharacterId") or Roster.Default
    setSelected(selectedId)
end)

player:GetAttributeChangedSignal("AwakeningActive"):Connect(function()
    if panel.Visible then
        setSelected(selectedId)
    end
end)

player:GetAttributeChangedSignal("UltimateActive"):Connect(function()
    if panel.Visible then
        setSelected(selectedId)
    end
end)

render()
setOpen(false)
