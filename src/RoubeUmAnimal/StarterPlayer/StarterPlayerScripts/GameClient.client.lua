local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RoubeAnimalRemotes")
local notifyRemote = remotes:WaitForChild("Notify")
local upgradeRemote = remotes:WaitForChild("RequestUpgrade")
local passRequestRemote = remotes:WaitForChild("RequestGamepass")
local passPromptRemote = remotes:WaitForChild("PromptGamepass")
local productRequestRemote = remotes:WaitForChild("RequestStackableProduct")
local productPromptRemote = remotes:WaitForChild("PromptStackableProduct")
local rebirthRequestRemote = remotes:WaitForChild("RequestRebirth")
local dailyRewardRemote = remotes:WaitForChild("RequestDailyReward")
local redeemCodeRemote = remotes:WaitForChild("RequestRedeemCode")
local questClaimRemote = remotes:WaitForChild("RequestQuest")
local collectBarnRemote = remotes:WaitForChild("RequestCollectBarnIncome")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalCatalog"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MonetizationIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MonetizationIds"))

local COLORS = {
    Background = Color3.fromRGB(35, 48, 39),
    Panel = Color3.fromRGB(55, 73, 54),
    PanelLight = Color3.fromRGB(79, 99, 67),
    Meadow = Color3.fromRGB(125, 190, 83),
    Leaf = Color3.fromRGB(70, 156, 83),
    Moss = Color3.fromRGB(46, 101, 63),
    Gold = Color3.fromRGB(255, 204, 89),
    Cream = Color3.fromRGB(255, 244, 219),
    Blue = Color3.fromRGB(106, 195, 239),
    Aqua = Color3.fromRGB(79, 203, 190),
    Purple = Color3.fromRGB(181, 139, 221),
    Orange = Color3.fromRGB(237, 145, 75),
    Red = Color3.fromRGB(221, 96, 77),
    Pink = Color3.fromRGB(246, 139, 172),
    Text = Color3.fromRGB(255, 250, 231),
    Muted = Color3.fromRGB(213, 223, 199),
    Dark = Color3.fromRGB(25, 35, 28),
}

local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("StealAnAnimalHUD")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "StealAnAnimalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(instance, radius)
    local object = Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 12)
    object.Parent = instance
    return object
end

local function outline(instance, color, thickness, transparency)
    local object = Instance.new("UIStroke")
    object.Color = color or COLORS.Gold
    object.Thickness = thickness or 1.5
    object.Transparency = transparency or 0.2
    object.Parent = instance
    return object
end

local function gradient(instance, first, last, rotation)
    local object = Instance.new("UIGradient")
    object.Color = ColorSequence.new(first, last)
    object.Rotation = rotation or 90
    object.Parent = instance
    return object
end

local function label(parent, name, text, size, position, fontSize, color, alignment)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextColor3 = color or COLORS.Text
    object.TextSize = fontSize or 14
    object.TextWrapped = true
    object.TextScaled = false
    object.TextXAlignment = alignment or Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function button(parent, name, text, size, position, color, callback, order)
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = color or COLORS.Leaf
    object.BorderSizePixel = 0
    object.AutoButtonColor = true
    object.Font = Enum.Font.GothamBlack
    object.Text = text
    object.TextColor3 = COLORS.Text
    object.TextSize = 12
    object.TextScaled = true
    object.TextWrapped = true
    object.Selectable = true
    object.Active = true
    object.LayoutOrder = order or 0
    object.Parent = parent
    corner(object, 10)
    outline(object, COLORS.Dark, 1.5, 0.35)
    gradient(object, color or COLORS.Leaf, COLORS.Moss, 90)
    object.Activated:Connect(callback)
    return object
end

local function number(value)
    value = tonumber(value) or 0
    local abs = math.abs(value)
    if abs >= 1000000000 then
        return string.format("%.1fB", value / 1000000000)
    elseif abs >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif abs >= 10000 then
        return string.format("%.1fK", value / 1000)
    end
    return tostring(math.floor(value))
end

local function rarityColor(rarity)
    if rarity == "Common" then return Color3.fromRGB(199, 213, 181) end
    if rarity == "Uncommon" then return COLORS.Leaf end
    if rarity == "Rare" then return COLORS.Blue end
    if rarity == "Epic" then return COLORS.Purple end
    if rarity == "Legendary" then return COLORS.Gold end
    return COLORS.Pink
end

local function biomeName(key)
    local info = Catalog.BiomeInfo[key]
    return info and info.Name or string.upper(tostring(key))
end

local mapLoadOverlay = Instance.new("Frame")
mapLoadOverlay.Name = "MapLoadDiagnostic"
mapLoadOverlay.Size = UDim2.fromScale(1, 1)
mapLoadOverlay.BackgroundColor3 = COLORS.Dark
mapLoadOverlay.BackgroundTransparency = 0.05
mapLoadOverlay.BorderSizePixel = 0
mapLoadOverlay.Visible = false
mapLoadOverlay.Active = true
mapLoadOverlay.ZIndex = 80
mapLoadOverlay.Parent = gui
local mapLoadCard = Instance.new("Frame")
mapLoadCard.Name = "MapLoadCard"
mapLoadCard.Size = UDim2.new(0.9, 0, 0, 235)
mapLoadCard.Position = UDim2.fromScale(0.5, 0.5)
mapLoadCard.AnchorPoint = Vector2.new(0.5, 0.5)
mapLoadCard.BackgroundColor3 = COLORS.Background
mapLoadCard.BorderSizePixel = 0
mapLoadCard.ZIndex = 81
mapLoadCard.Parent = mapLoadOverlay
corner(mapLoadCard, 16)
outline(mapLoadCard, COLORS.Orange, 2, 0.1)
gradient(mapLoadCard, COLORS.Panel, COLORS.Dark, 90)
local mapLoadTitle = label(mapLoadCard, "StatusTitle", "LOADING YOUR WORLD", UDim2.new(1, -24, 0, 42), UDim2.new(0, 12, 0, 10), 20, COLORS.Gold, Enum.TextXAlignment.Center)
mapLoadTitle.ZIndex = 82
mapLoadTitle.Font = Enum.Font.GothamBlack
local mapLoadDetails = label(mapLoadCard, "StatusDetails", "Preparing the farms, biomes and animal guardians...", UDim2.new(1, -24, 0, 100), UDim2.new(0, 12, 0, 56), 14, COLORS.Muted, Enum.TextXAlignment.Center)
mapLoadDetails.ZIndex = 82
local mapLoadClose = button(mapLoadCard, "ContinueButton", "CONTINUE ANYWAY", UDim2.new(1, -24, 0, 42), UDim2.new(0, 12, 1, -54), COLORS.Orange, function()
    mapLoadOverlay.Visible = false
end)
mapLoadClose.Visible = false
mapLoadClose.ZIndex = 82

task.spawn(function()
    local root = workspace:WaitForChild("StealAnAnimal", 40)
    if not root then
        mapLoadOverlay.Visible = true
        mapLoadTitle.Text = "WORLD DID NOT START"
        mapLoadTitle.TextColor3 = COLORS.Red
        mapLoadDetails.Text = "The server did not create the world root. Leave and join another server. If it keeps happening, the creator needs to inspect the server logs."
        mapLoadClose.Visible = true
        return
    end
    local deadline = os.clock() + 40
    while root.Parent and root:GetAttribute("MapReady") == nil and os.clock() < deadline do
        task.wait(0.25)
    end
    if root.Parent and root:GetAttribute("MapReady") == true then
        return
    end
    mapLoadOverlay.Visible = true
    mapLoadTitle.Text = "WORLD STARTED INCOMPLETE"
    mapLoadTitle.TextColor3 = COLORS.Orange
    mapLoadDetails.Text = "Farms: " .. tostring(root:GetAttribute("BaseCount") or 0) .. "/8"
        .. "\nBiomes: " .. tostring(root:GetAttribute("BiomeCount") or 0) .. "/6"
        .. "\nAnimals: " .. tostring(root:GetAttribute("AnimalCount") or 0)
        .. "\nTry another server. The server logs include the failed construction step."
    mapLoadClose.Visible = true
end)

local statsPanel = Instance.new("Frame")
statsPanel.Name = "TopHUD"
statsPanel.Size = UDim2.new(0.97, 0, 0, 100)
statsPanel.Position = UDim2.new(0.5, 0, 0, 7)
statsPanel.AnchorPoint = Vector2.new(0.5, 0)
statsPanel.BackgroundColor3 = COLORS.Background
statsPanel.BackgroundTransparency = 0.02
statsPanel.BorderSizePixel = 0
statsPanel.Parent = gui
corner(statsPanel, 15)
outline(statsPanel, COLORS.Gold, 2, 0.18)
gradient(statsPanel, Color3.fromRGB(78, 108, 65), Color3.fromRGB(35, 52, 39), 90)
local statsConstraint = Instance.new("UISizeConstraint")
statsConstraint.MinSize = Vector2.new(285, 100)
statsConstraint.MaxSize = Vector2.new(590, 100)
statsConstraint.Parent = statsPanel
local header = label(statsPanel, "Title", "STEAL AN ANIMAL", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 3), 16, COLORS.Gold, Enum.TextXAlignment.Center)
header.Font = Enum.Font.GothamBlack
local statRow = Instance.new("Frame")
statRow.Name = "FarmStats"
statRow.Size = UDim2.new(1, -12, 0, 31)
statRow.Position = UDim2.new(0, 6, 0, 29)
statRow.BackgroundTransparency = 1
statRow.Parent = statsPanel
local statLayout = Instance.new("UIListLayout")
statLayout.FillDirection = Enum.FillDirection.Horizontal
statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statLayout.SortOrder = Enum.SortOrder.LayoutOrder
statLayout.Padding = UDim.new(0, 3)
statLayout.Parent = statRow

local function statBox(name, text, order, color)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Size = UDim2.new(0.25, -3, 1, 0)
    object.BackgroundColor3 = COLORS.Panel
    object.BorderSizePixel = 0
    object.Font = Enum.Font.GothamBlack
    object.Text = text
    object.TextColor3 = color or COLORS.Text
    object.TextSize = 12
    object.TextScaled = true
    object.TextWrapped = true
    object.LayoutOrder = order
    object.Parent = statRow
    corner(object, 7)
    outline(object, color or COLORS.Gold, 1, 0.5)
    return object
end
local coinsLabel = statBox("Coins", "COINS $0", 1, COLORS.Gold)
local incomeLabel = statBox("Income", "$0/s", 2, COLORS.Green)
local barnLabel = statBox("Barn", "BARN 0/6", 3, COLORS.Cream)
local speedLabel = statBox("Speed", "SPD 16", 4, COLORS.Blue)
local carryLabel = label(statsPanel, "CarryStatus", "No animal carried • Steal one and return to your barn", UDim2.new(1, -18, 0, 24), UDim2.new(0, 9, 0, 69), 11, COLORS.Muted, Enum.TextXAlignment.Center)

local navPanel = Instance.new("Frame")
navPanel.Name = "MainNavigation"
navPanel.Size = UDim2.new(0.97, 0, 0, 58)
navPanel.Position = UDim2.new(0.5, 0, 1, -7)
navPanel.AnchorPoint = Vector2.new(0.5, 1)
navPanel.BackgroundColor3 = COLORS.Background
navPanel.BackgroundTransparency = 0.03
navPanel.BorderSizePixel = 0
navPanel.Parent = gui
corner(navPanel, 14)
outline(navPanel, COLORS.Gold, 1.5, 0.22)
gradient(navPanel, COLORS.Panel, COLORS.Dark, 90)
local navConstraint = Instance.new("UISizeConstraint")
navConstraint.MinSize = Vector2.new(285, 58)
navConstraint.MaxSize = Vector2.new(590, 58)
navConstraint.Parent = navPanel
local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 5)
navPadding.PaddingRight = UDim.new(0, 5)
navPadding.PaddingTop = UDim.new(0, 5)
navPadding.PaddingBottom = UDim.new(0, 5)
navPadding.Parent = navPanel
local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 4)
navLayout.Parent = navPanel

local backdrop = Instance.new("Frame")
backdrop.Name = "WindowBackdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.42
backdrop.Visible = false
backdrop.Active = true
backdrop.ZIndex = 30
backdrop.Parent = gui
local modal = Instance.new("Frame")
modal.Name = "Window"
modal.Size = UDim2.fromOffset(350, 510)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.BackgroundColor3 = COLORS.Background
modal.BorderSizePixel = 0
modal.ZIndex = 31
modal.Parent = backdrop
corner(modal, 17)
outline(modal, COLORS.Gold, 2, 0.1)
gradient(modal, COLORS.Panel, COLORS.Dark, 90)
local modalScale = Instance.new("UIScale")
modalScale.Scale = 0.94
modalScale.Parent = modal
local modalTitle = label(modal, "WindowTitle", "BARN", UDim2.new(1, -72, 0, 38), UDim2.new(0, 14, 0, 8), 20, COLORS.Gold)
modalTitle.ZIndex = 33
modalTitle.Font = Enum.Font.GothamBlack
local activeScreen
local lastSelectable
local closeButton = button(modal, "Close", "X", UDim2.fromOffset(38, 34), UDim2.new(1, -48, 0, 9), COLORS.Red, function()
    backdrop.Visible = false
    activeScreen = nil
    GuiService.SelectedObject = nil
end)
closeButton.ZIndex = 34
local content = Instance.new("ScrollingFrame")
content.Name = "WindowContent"
content.Size = UDim2.new(1, -18, 1, -58)
content.Position = UDim2.new(0, 9, 0, 50)
content.BackgroundColor3 = COLORS.Dark
content.BackgroundTransparency = 0.06
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = COLORS.Gold
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.Active = true
content.ZIndex = 32
content.Parent = modal
corner(content, 12)
local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0, 7)
contentPadding.PaddingRight = UDim.new(0, 7)
contentPadding.PaddingTop = UDim.new(0, 7)
contentPadding.PaddingBottom = UDim.new(0, 7)
contentPadding.Parent = content
local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 7)
contentLayout.Parent = content

local function resizeUI()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize
    statsPanel.Size = UDim2.new(0.97, 0, 0, viewport.X < 400 and 106 or 100)
    navPanel.Size = UDim2.new(0.97, 0, 0, 58)
    local width = math.max(245, math.min(630, viewport.X - 18, viewport.X * 0.95))
    local height = math.max(230, math.min(610, viewport.Y - 88, viewport.Y * 0.78))
    modal.Size = UDim2.fromOffset(width, height)
end

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child ~= contentPadding and child ~= contentLayout then
            child:Destroy()
        end
    end
    lastSelectable = nil
end

local function addInfo(order, text, accent, height)
    local card = Instance.new("Frame")
    card.Name = "Info_" .. tostring(order)
    card.Size = UDim2.new(1, -3, 0, height or 64)
    card.BackgroundColor3 = COLORS.Panel
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 33
    card.Parent = content
    corner(card, 11)
    outline(card, accent or COLORS.Meadow, 1.2, 0.35)
    gradient(card, Color3.fromRGB(74, 100, 65), Color3.fromRGB(40, 57, 43), 90)
    local stripe = Instance.new("Frame")
    stripe.Name = "Accent"
    stripe.Size = UDim2.new(0, 5, 1, -12)
    stripe.Position = UDim2.new(0, 6, 0, 6)
    stripe.BackgroundColor3 = accent or COLORS.Meadow
    stripe.BorderSizePixel = 0
    stripe.ZIndex = 34
    stripe.Parent = card
    corner(stripe, 3)
    local textLabel = label(card, "Text", text, UDim2.new(1, -24, 1, -10), UDim2.new(0, 17, 0, 5), 12, COLORS.Cream)
    textLabel.ZIndex = 34
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    return card
end

local function addAction(order, marker, titleText, description, cta, accent, callback, disabled, height)
    local card = Instance.new("Frame")
    card.Name = "Action_" .. tostring(order) .. "_" .. tostring(marker)
    card.Size = UDim2.new(1, -3, 0, height or 86)
    card.BackgroundColor3 = COLORS.Panel
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 33
    card.Parent = content
    corner(card, 12)
    outline(card, accent or COLORS.Meadow, 1.25, 0.25)
    gradient(card, Color3.fromRGB(76, 99, 66), Color3.fromRGB(40, 57, 43), 90)

    local icon = Instance.new("TextLabel")
    icon.Name = "AnimalMarker"
    icon.Size = UDim2.fromOffset(38, 38)
    icon.Position = UDim2.new(0, 7, 0.5, -19)
    icon.BackgroundColor3 = accent or COLORS.Meadow
    icon.BorderSizePixel = 0
    icon.Font = Enum.Font.GothamBlack
    icon.Text = tostring(marker)
    icon.TextColor3 = COLORS.Text
    icon.TextScaled = true
    icon.TextWrapped = true
    icon.ZIndex = 34
    icon.Parent = card
    corner(icon, 10)
    outline(icon, COLORS.Cream, 1, 0.65)
    gradient(icon, accent or COLORS.Meadow, COLORS.Moss, 90)

    local titleLabel = label(card, "Title", titleText, UDim2.new(1, -136, 0, 27), UDim2.new(0, 52, 0, 5), 12, accent or COLORS.Gold)
    titleLabel.ZIndex = 34
    titleLabel.Font = Enum.Font.GothamBlack
    local descLabel = label(card, "Description", description, UDim2.new(1, -136, 1, -36), UDim2.new(0, 52, 0, 32), 10, COLORS.Muted)
    descLabel.ZIndex = 34
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    local action = Instance.new("TextButton")
    action.Name = "ActionButton"
    action.Size = UDim2.new(0, 78, 0, 44)
    action.Position = UDim2.new(1, -85, 0.5, -22)
    action.BackgroundColor3 = disabled and Color3.fromRGB(88, 93, 77) or accent or COLORS.Leaf
    action.BorderSizePixel = 0
    action.Font = Enum.Font.GothamBlack
    action.Text = cta
    action.TextColor3 = COLORS.Text
    action.TextSize = 11
    action.TextScaled = true
    action.TextWrapped = true
    action.Active = not disabled
    action.Selectable = not disabled
    action.AutoButtonColor = not disabled
    action.ZIndex = 34
    action.Parent = card
    corner(action, 9)
    outline(action, COLORS.Dark, 1, 0.3)
    gradient(action, action.BackgroundColor3, COLORS.Moss, 90)
    if not disabled then
        action.Activated:Connect(callback)
    end
    lastSelectable = lastSelectable or action
    return card
end

local function addTextInput(order, placeholder)
    local frame = Instance.new("Frame")
    frame.Name = "TextInputRow"
    frame.Size = UDim2.new(1, -3, 0, 48)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order
    frame.Parent = content
    local input = Instance.new("TextBox")
    input.Name = "CodeInput"
    input.Size = UDim2.new(1, -6, 1, 0)
    input.Position = UDim2.new(0, 3, 0, 0)
    input.BackgroundColor3 = COLORS.PanelLight
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = false
    input.PlaceholderText = placeholder
    input.Text = ""
    input.Font = Enum.Font.GothamBold
    input.TextColor3 = COLORS.Cream
    input.PlaceholderColor3 = COLORS.Muted
    input.TextSize = 14
    input.TextXAlignment = Enum.TextXAlignment.Center
    input.ZIndex = 34
    input.Parent = frame
    corner(input, 10)
    outline(input, COLORS.Gold, 1.2, 0.35)
    lastSelectable = lastSelectable or input
    return input
end

local lowEffects = false
local function setLowEffects(enabled)
    lowEffects = enabled
    for _, object in ipairs(Lighting:GetDescendants()) do
        if object:IsA("BloomEffect") or object:IsA("BlurEffect") or object:IsA("SunRaysEffect") then
            object.Enabled = not enabled
        end
    end
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
            object.Enabled = not enabled
        end
    end
end

local function toast(message, messageType)
    local existing = gui:FindFirstChild("Toast")
    if not existing then
        existing = Instance.new("TextLabel")
        existing.Name = "Toast"
        existing.Size = UDim2.new(0.9, 0, 0, 52)
        existing.Position = UDim2.new(0.5, 0, 0, 116)
        existing.AnchorPoint = Vector2.new(0.5, 0)
        existing.BackgroundColor3 = COLORS.Background
        existing.BackgroundTransparency = 0.04
        existing.BorderSizePixel = 0
        existing.Font = Enum.Font.GothamBold
        existing.TextWrapped = true
        existing.TextSize = 13
        existing.TextColor3 = COLORS.Text
        existing.Visible = false
        existing.ZIndex = 70
        existing.Parent = gui
        corner(existing, 12)
        outline(existing, COLORS.Gold, 1.5, 0.2)
        gradient(existing, COLORS.Panel, COLORS.Dark, 90)
        local constraint = Instance.new("UISizeConstraint")
        constraint.MinSize = Vector2.new(240, 52)
        constraint.MaxSize = Vector2.new(500, 52)
        constraint.Parent = existing
    end
    existing:SetAttribute("Sequence", (existing:GetAttribute("Sequence") or 0) + 1)
    local sequence = existing:GetAttribute("Sequence")
    existing.Text = tostring(message)
    existing.TextColor3 = messageType == "Success" and COLORS.Green
        or messageType == "Warning" and COLORS.Gold
        or messageType == "Error" and COLORS.Red
        or COLORS.Text
    existing.Visible = true
    task.delay(3.4, function()
        if existing.Parent and existing:GetAttribute("Sequence") == sequence then
            existing.Visible = false
        end
    end)
end

local function refreshStats()
    local coins = tonumber(player:GetAttribute("Coins")) or 0
    local income = tonumber(player:GetAttribute("BarnIncomeRate")) or 0
    local count = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
    local capacity = tonumber(player:GetAttribute("BarnCapacity")) or Config.Barn.BaseSlots
    local speed = Config.BaseWalkSpeed + (tonumber(player:GetAttribute("SpeedLevel")) or 0) * Config.SpeedPerLevel
    header.Text = "STEAL AN ANIMAL  •  REBIRTH " .. tostring(player:GetAttribute("Rebirths") or 0)
    coinsLabel.Text = "COINS $" .. number(coins)
    incomeLabel.Text = "$" .. number(income) .. "/s"
    barnLabel.Text = "BARN " .. tostring(count) .. "/" .. tostring(capacity)
    speedLabel.Text = "SPD " .. number(speed)
    if player:GetAttribute("CarryingAnimal") == true then
        carryLabel.Text = "CARRYING: " .. tostring(player:GetAttribute("CarriedAnimalName") or "ANIMAL")
            .. "  •  $" .. number(player:GetAttribute("CarriedAnimalIncome")) .. "/s in barn"
        carryLabel.TextColor3 = COLORS.Gold
    else
        carryLabel.Text = "No animal carried • find a creature, hold STEAL, then return home"
        carryLabel.TextColor3 = COLORS.Muted
    end
end

local openScreen

local function renderBarn()
    clearContent()
    local count = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
    local capacity = tonumber(player:GetAttribute("BarnCapacity")) or Config.Barn.BaseSlots
    local income = tonumber(player:GetAttribute("BarnIncomeRate")) or 0
    local bank = tonumber(player:GetAttribute("BarnBank")) or 0
    local carried = player:GetAttribute("CarryingAnimal") == true
    addInfo(1, "YOUR BARN  •  STORE ANIMALS HERE AND THEY WILL GENERATE COINS EVERY SECOND.", COLORS.Gold, 70)
    addAction(2, "$", "UNCLAIMED BARN INCOME", "$" .. number(bank) .. " waiting to collect. Your animals earn $" .. number(income) .. " each second.", "COLLECT", COLORS.Gold, function()
        collectBarnRemote:FireServer()
    end, false, 90)
    addAction(3, "PAW", "ANIMAL CAPACITY", tostring(count) .. "/" .. tostring(capacity) .. " occupied slots. Deposit animals at the green pad.", "SLOTS", COLORS.Green, function()
        toast("Find wild animals in a biome, hold STEAL, and bring one to the green pad at your own barn.", "Info")
    end, false, 82)
    if carried then
        addInfo(4, "CARRYING " .. tostring(player:GetAttribute("CarriedAnimalName")) .. " • $" .. number(player:GetAttribute("CarriedAnimalIncome")) .. "/s. Return to your barn before a guardian catches you.", COLORS.Orange, 65)
    else
        addInfo(4, "TIP: each animal has a different income rate. Rarer creatures usually generate more coins, but their guardian patrols are more dangerous.", COLORS.Meadow, 75)
    end
    local decoded = {}
    local ok, value = pcall(function()
        return HttpService:JSONDecode(player:GetAttribute("BarnAnimalsJson") or "[]")
    end)
    if ok and type(value) == "table" then
        decoded = value
    end
    addInfo(5, "STORED ANIMALS  •  " .. tostring(#decoded) .. "/" .. tostring(capacity), COLORS.Cream, 44)
    if #decoded == 0 then
        addInfo(6, "Your barn is empty. Capture your first animal in Sunny Meadow and bring it home.", COLORS.Muted, 54)
    else
        for index, animalId in ipairs(decoded) do
            local spec = Catalog.Get(animalId)
            if spec then
                addAction(5 + index, "PAW", spec.DisplayName, biomeName(spec.Biome) .. " • " .. spec.Rarity .. " • $" .. number(spec.IncomePerSecond) .. "/second", "DETAILS", rarityColor(spec.Rarity), function()
                    toast(spec.DisplayName .. " generates $" .. tostring(spec.IncomePerSecond) .. " every second while stored.", "Info")
                end, false, 78)
            end
        end
    end
end

local function renderAnimals()
    clearContent()
    addInfo(1, "ANIMAL INDEX  •  EACH CREATURE HAS A BIOME, RARITY, WEIGHT AND COIN RATE.", COLORS.Meadow, 62)
    for index, spec in ipairs(Catalog.All()) do
        local marker = spec.Shape == "Bird" and "BIRD" or spec.Shape == "Reptile" and "REPT" or "PAWS"
        addAction(index + 1, marker, spec.DisplayName .. "  •  " .. string.upper(spec.Rarity),
            biomeName(spec.Biome) .. "  •  $" .. number(spec.IncomePerSecond) .. "/s  •  weight " .. tostring(spec.Weight),
            "FIND", rarityColor(spec.Rarity), function()
                toast("Explore " .. biomeName(spec.Biome) .. " and hold the STEAL prompt near " .. spec.DisplayName .. ".", "Info")
            end, false, 80)
    end
end

local function renderShop()
    clearContent()
    local level = tonumber(player:GetAttribute("SpeedLevel")) or 0
    local nextCost = math.min(Config.CoinsLimit, math.floor(Config.Upgrades.SpeedBaseCost * (Config.Upgrades.SpeedCostGrowth ^ level)))
    local boost = (player:GetAttribute("HasDoubleSpeed") == true) and Config.Training.DoubleSpeedMultiplier or 1
    addInfo(1, "FARM UPGRADES  •  SPEND EARNED COINS TO RUN FASTER AND ESCAPE GUARDIANS.", COLORS.Green, 66)
    addAction(2, "SPD", "SPEED LEVEL " .. tostring(level) .. "/" .. tostring(Config.MaxSpeedLevel),
        "Next level costs $" .. number(nextCost) .. ". More speed helps you bring rare animals home before the guardian catches you.", "UPGRADE", COLORS.Blue, function()
            upgradeRemote:FireServer("Speed")
        end, level >= Config.MaxSpeedLevel, 96)
    addAction(3, "2X", "DOUBLE SPEED", "Permanent pass. Increases speed upgrade and treadmill gains. Status: " .. (player:GetAttribute("HasDoubleSpeed") and "OWNED" or "NOT OWNED"), "PASSES", COLORS.Aqua, function()
        openScreen("Passes")
    end, false, 80)
    addInfo(4, "TIP: the treadmill beside your barn gives speed over time while you run on it. No strength or bench-press system exists in this game.", COLORS.Gold, 68)
end

local function passEntries()
    return {
        { key = "DoubleIncome", title = "PROFIT FARM • 2X INCOME", description = "Doubles the passive coin income of every animal stored in your barn.", marker = "2X $", color = COLORS.Gold, attr = "HasDoubleIncome" },
        { key = "DoubleSpeed", title = "QUICK ESCAPE • 2X SPEED", description = "Doubles speed training gains and improves movement while carrying animals.", marker = "2X", color = COLORS.Blue, attr = "HasDoubleSpeed" },
        { key = "VIPFarm", title = "VIP FARM", description = "Adds a permanent movement bonus and a 25% boost to barn income.", marker = "VIP", color = COLORS.Purple, attr = "HasVIPFarm" },
        { key = "ExtraBarnSlots", title = "EXPANDED BARN", description = "Unlocks four additional animal storage slots (6 → 10).", marker = "+4", color = COLORS.Green, attr = "HasExtraBarnSlots" },
    }
end

local function renderPasses()
    clearContent()
    addInfo(1, "PERMANENT GAMEPASSES  •  EACH PASS HAS A DIFFERENT EFFECT. THEY ARE NOT REPEATABLE PRODUCTS.", COLORS.Gold, 62)
    for index, item in ipairs(passEntries()) do
        local owns = player:GetAttribute(item.attr) == true
        local id = MonetizationIds.Passes[item.key]
        local configured = type(id) == "number" and id > 0
        local description = item.description .. (configured and "" or " Purchase ID not configured yet.")
        addAction(index + 1, item.marker, item.title, description, owns and "OWNED" or (configured and "BUY" or "SETUP"), item.color, function()
            if owns then
                toast("You already own this pass.", "Info")
            elseif not configured then
                toast("Create this pass in Creator Dashboard and configure its ID before purchase can be enabled.", "Warning")
            else
                passRequestRemote:FireServer(item.key)
            end
        end, owns, 88)
    end
    addInfo(6, "REPEATABLE DEVELOPER PRODUCTS  •  EACH SUCCESSFUL RECEIPT IS SAVED BY THE SERVER.", COLORS.Aqua, 54)
    local products = {
        { key = "SpeedBoost", title = "+10 SPEED", description = "A repeatable speed bundle, useful for long guardian escapes.", marker = "+10", color = COLORS.Blue },
        { key = "CoinBundle", title = "+5,000 COINS", description = "Adds 5,000 coins to your wallet. Can be purchased more than once.", marker = "$5K", color = COLORS.Gold },
    }
    for index, item in ipairs(products) do
        local id = MonetizationIds.Products[item.key]
        local configured = type(id) == "number" and id > 0
        addAction(6 + index, item.marker, item.title, item.description .. (configured and "" or " Product ID not configured yet."),
            configured and "BUY" or "SETUP", item.color, function()
                if configured then
                    productRequestRemote:FireServer(item.key)
                else
                    toast("Create this Developer Product in Creator Dashboard and configure its ID first.", "Warning")
                end
            end, false, 86)
    end
end

local function renderQuests()
    clearContent()
    local captures = tonumber(player:GetAttribute("TotalCaptured")) or 0
    local deposits = tonumber(player:GetAttribute("TotalDeposited")) or 0
    local barnCount = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
    addInfo(1, "FARM QUESTS  •  COMPLETE OBJECTIVES TO EARN EXTRA COINS.", COLORS.Purple, 56)
    local quests = {
        { id = "FirstCapture", title = "FIRST CAPTURE", marker = "1", desc = "Capture your first animal. Progress: " .. tostring(math.min(captures, 1)) .. "/1.", ready = captures >= 1, reward = "$250" },
        { id = "FirstBarn", title = "FIRST BARN DEPOSIT", marker = "B", desc = "Store an animal in your barn. Progress: " .. tostring(math.min(deposits, 1)) .. "/1.", ready = deposits >= 1, reward = "$750" },
        { id = "Collector", title = "ANIMAL COLLECTOR", marker = "5", desc = "Capture five animals. Progress: " .. tostring(math.min(captures, 5)) .. "/5.", ready = captures >= 5, reward = "$1.5K" },
        { id = "FullBarn", title = "FULL BARN", marker = "6", desc = "Store six animals in your barn. Progress: " .. tostring(math.min(barnCount, Config.Barn.BaseSlots)) .. "/" .. tostring(Config.Barn.BaseSlots) .. ".", ready = barnCount >= Config.Barn.BaseSlots, reward = "$5K" },
    }
    for index, item in ipairs(quests) do
        addAction(index + 1, item.marker, item.title, item.desc .. " Reward: " .. item.reward .. ".",
            item.ready and "CLAIM" or "IN PROGRESS", COLORS.Purple, function()
                questClaimRemote:FireServer(item.id)
            end, not item.ready, 82)
    end
end

local function renderDaily()
    clearContent()
    local streak = tonumber(player:GetAttribute("DailyStreak")) or 0
    addInfo(1, "DAILY HARVEST  •  CLAIM COINS ONCE PER DAY. KEEP YOUR STREAK ALIVE FOR BIGGER REWARDS.", COLORS.Gold, 68)
    addAction(2, "DAY", "DAY " .. tostring(math.min(streak + 1, 7)) .. " REWARD",
        "$500 base reward + $250 per streak day, up to a seven-day streak. Current streak: " .. tostring(streak) .. "/7.",
        "CLAIM", COLORS.Gold, function()
            dailyRewardRemote:FireServer()
        end, false, 92)
    addInfo(3, "REDEEM A CODE  •  CODES ARE CASE-INSENSITIVE.", COLORS.Green, 48)
    local input = addTextInput(4, "Enter a farm code...")
    addAction(5, "CODE", "REDEEM CODE", "FARMFAMILY, WILDSTART and BARNBOOST are currently supported.", "REDEEM", COLORS.Green, function()
        local code = string.gsub(input.Text, "%s+", "")
        if code == "" then
            toast("Enter a code first.", "Warning")
            return
        end
        redeemCodeRemote:FireServer(code)
    end, false, 82)
end

local function renderStats()
    clearContent()
    local data = {
        { "Coins in wallet", "$" .. number(player:GetAttribute("Coins")), COLORS.Gold },
        { "Coins waiting in barn", "$" .. number(player:GetAttribute("BarnBank")), COLORS.Green },
        { "Passive income", "$" .. number(player:GetAttribute("BarnIncomeRate")) .. "/second", COLORS.Aqua },
        { "Stored animals", tostring(player:GetAttribute("BarnAnimalCount") or 0) .. "/" .. tostring(player:GetAttribute("BarnCapacity") or Config.Barn.BaseSlots), COLORS.Cream },
        { "Animals captured", number(player:GetAttribute("TotalCaptured")), COLORS.Purple },
        { "Animals delivered to barn", number(player:GetAttribute("TotalDeposited")), COLORS.Meadow },
        { "Speed", number(player:GetAttribute("SpeedLevel")) .. "/" .. tostring(Config.MaxSpeedLevel), COLORS.Blue },
        { "Rebirths", tostring(player:GetAttribute("Rebirths") or 0) .. "/" .. tostring(Config.MaxRebirths), COLORS.Orange },
    }
    addInfo(1, "FARM STATISTICS  •  ALL VALUES COME FROM YOUR SERVER-SAVED PROFILE.", COLORS.Gold, 58)
    for index, item in ipairs(data) do
        addAction(index + 1, "STAT", item[1], item[2], "VIEW", item[3], function()
            toast(item[1] .. ": " .. item[2], "Info")
        end, false, 70)
    end
end

local function renderSettings()
    clearContent()
    addInfo(1, "SETTINGS  •  CHANGES APPLY TO YOUR CURRENT CLIENT SESSION.", COLORS.Blue, 58)
    addAction(2, "FX", "REDUCED VISUAL EFFECTS", "Disables bloom, sun rays and local point lights to improve readability on lower-end phones. Current: " .. (lowEffects and "ON" or "OFF"), lowEffects and "TURN OFF" or "TURN ON", COLORS.Aqua, function()
        setLowEffects(not lowEffects)
        renderSettings()
    end, false, 86)
    addAction(3, "HUD", "INTERFACE SCALE", "The HUD automatically adapts to the current viewport and respects the device safe area.", "RESIZE", COLORS.Green, function()
        resizeUI()
        toast("HUD layout recalculated for this screen.", "Success")
    end, false, 78)
    addInfo(4, "TIP: on mobile, use the on-screen STEAL prompt and keep the barn's green deposit pad visible when you return.", COLORS.Cream, 62)
end

local function renderRebirth()
    clearContent()
    local rebirths = tonumber(player:GetAttribute("Rebirths")) or 0
    local speed = tonumber(player:GetAttribute("SpeedLevel")) or 0
    local coins = tonumber(player:GetAttribute("Coins")) or 0
    local carrying = player:GetAttribute("CarryingAnimal") == true
    local eligible = speed >= Config.MaxSpeedLevel and coins >= Config.RebirthCoinsRequired
        and not carrying and rebirths < Config.MaxRebirths
    addInfo(1, "REBIRTH  •  RESET SPEED AND WALLET TO GAIN A PERMANENT +10% BARN INCOME MULTIPLIER.", COLORS.Orange, 72)
    addInfo(2, "Current rebirths: " .. tostring(rebirths) .. "/" .. tostring(Config.MaxRebirths)
        .. "\nRequired speed: " .. tostring(speed) .. "/" .. tostring(Config.MaxSpeedLevel)
        .. "\nRequired coins: $" .. number(coins) .. "/$" .. number(Config.RebirthCoinsRequired)
        .. "\nYou cannot rebirth while carrying an animal.", COLORS.Cream, 106)
    addAction(3, "RB", "CONFIRM REBIRTH", "The server verifies your requirements and saves the change before confirming it.", "REBIRTH", COLORS.Orange, function()
        rebirthRequestRemote:FireServer()
    end, not eligible, 86)
end

local function renderMore()
    clearContent()
    addInfo(1, "FARM MENU  •  YOUR COLLECTION, PROGRESS AND SETTINGS.", COLORS.Gold, 58)
    addAction(2, "Q", "QUESTS", "Earn bonuses for your first capture, first deposit and a full barn.", "OPEN", COLORS.Purple, function() openScreen("Quests") end, false, 72)
    addAction(3, "D", "DAILY HARVEST & CODES", "Claim a daily reward or redeem a supported farm code.", "OPEN", COLORS.Gold, function() openScreen("Daily") end, false, 72)
    addAction(4, "ST", "STATISTICS", "Inspect income, captured animals, stored animals and rebirths.", "OPEN", COLORS.Blue, function() openScreen("Stats") end, false, 72)
    addAction(5, "FX", "SETTINGS", "Adjust visual effects for your device.", "OPEN", COLORS.Aqua, function() openScreen("Settings") end, false, 72)
    addAction(6, "RB", "REBIRTH", "Trade your current speed and wallet for a permanent barn-income bonus.", "OPEN", COLORS.Orange, function() openScreen("Rebirth") end, false, 78)
end

local renderers = {
    Barn = renderBarn,
    Animals = renderAnimals,
    Shop = renderShop,
    Passes = renderPasses,
    Quests = renderQuests,
    Daily = renderDaily,
    Stats = renderStats,
    Settings = renderSettings,
    Rebirth = renderRebirth,
    More = renderMore,
}

openScreen = function(name)
    local renderer = renderers[name]
    if not renderer then
        return
    end
    activeScreen = name
    modalTitle.Text = ({
        Barn = "YOUR BARN",
        Animals = "ANIMAL INDEX",
        Shop = "FARM UPGRADES",
        Passes = "PASSES & PRODUCTS",
        Quests = "QUEST BOARD",
        Daily = "DAILY HARVEST",
        Stats = "FARM STATISTICS",
        Settings = "SETTINGS",
        Rebirth = "REBIRTH",
        More = "FARM MENU",
    })[name] or "FARM"
    renderer()
    resizeUI()
    backdrop.Visible = true
    modalScale.Scale = 0.9
    TweenService:Create(modalScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    task.defer(function()
        if backdrop.Visible and lastSelectable and UserInputService.GamepadEnabled then
            GuiService.SelectedObject = lastSelectable
        end
    end)
end

button(navPanel, "OpenBarn", "BARN", UDim2.new(0.2, -4, 1, 0), UDim2.new(), COLORS.Green, function() openScreen("Barn") end, 1)
button(navPanel, "OpenAnimals", "ANIMALS", UDim2.new(0.2, -4, 1, 0), UDim2.new(), COLORS.Pink, function() openScreen("Animals") end, 2)
button(navPanel, "OpenShop", "SHOP", UDim2.new(0.2, -4, 1, 0), UDim2.new(), COLORS.Gold, function() openScreen("Shop") end, 3)
button(navPanel, "OpenPasses", "PASSES", UDim2.new(0.2, -4, 1, 0), UDim2.new(), COLORS.Blue, function() openScreen("Passes") end, 4)
button(navPanel, "OpenMore", "MORE", UDim2.new(0.2, -4, 1, 0), UDim2.new(), COLORS.Purple, function() openScreen("More") end, 5)

local function promptPass(passId)
    if type(passId) ~= "number" or passId <= 0 then
        toast("This gamepass has not been configured yet.", "Warning")
        return
    end
    local success, err = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, passId)
    end)
    if not success then
        toast("Could not open the pass purchase: " .. tostring(err), "Error")
    end
end

local function promptProduct(productId)
    if type(productId) ~= "number" or productId <= 0 then
        toast("This developer product has not been configured yet.", "Warning")
        return
    end
    local success, err = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)
    if not success then
        toast("Could not open the product purchase: " .. tostring(err), "Error")
    end
end

notifyRemote.OnClientEvent:Connect(toast)
passPromptRemote.OnClientEvent:Connect(promptPass)
productPromptRemote.OnClientEvent:Connect(promptProduct)

local attributes = {
    "Coins", "SpeedLevel", "Rebirths", "BarnAnimalCount", "BarnCapacity", "BarnIncomeRate", "BarnBank",
    "TotalCaptured", "TotalDeposited", "BarnAnimalsJson", "CarryingAnimal", "CarriedAnimalName",
    "CarriedAnimalWeight", "CarriedAnimalIncome", "HasDoubleIncome", "HasDoubleSpeed", "HasVIPFarm", "HasExtraBarnSlots", "DailyStreak",
}
for _, attribute in ipairs(attributes) do
    player:GetAttributeChangedSignal(attribute):Connect(function()
        refreshStats()
        if activeScreen and activeScreen ~= "Daily" and activeScreen ~= "Settings" then
            local currencyChange = attribute == "BarnBank" or attribute == "BarnIncomeRate" or attribute == "Coins"
            local shouldRefresh = not currencyChange or activeScreen == "Barn" or activeScreen == "Stats" or activeScreen == "Rebirth"
            if shouldRefresh then
                local renderer = renderers[activeScreen]
                if renderer then renderer() end
            end
        end
    end)
end

local function setupCamera()
    local camera = workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeUI)
        resizeUI()
    end
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(setupCamera)
setupCamera()
refreshStats()

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not backdrop.Visible then
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
        backdrop.Visible = false
        activeScreen = nil
        GuiService.SelectedObject = nil
    end
end)
