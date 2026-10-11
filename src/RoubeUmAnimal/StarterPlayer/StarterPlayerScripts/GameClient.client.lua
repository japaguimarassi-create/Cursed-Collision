local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RoubeAnimalRemotes")
local notifyRemote = remotes:WaitForChild("Notify")
local upgradeRemote = remotes:WaitForChild("RequestUpgrade")
local passRequestRemote = remotes:WaitForChild("RequestGamepass")
local passPromptRemote = remotes:WaitForChild("PromptGamepass")
local productRequestRemote = remotes:WaitForChild("RequestStackableProduct")
local productPromptRemote = remotes:WaitForChild("PromptStackableProduct")
local rebirthRequestRemote = remotes:WaitForChild("RequestRebirth")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalCatalog"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MonetizationIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MonetizationIds"))

local COLORS = {
    Background = Color3.fromRGB(22, 30, 44),
    Panel = Color3.fromRGB(34, 46, 64),
    PanelLight = Color3.fromRGB(48, 64, 86),
    Blue = Color3.fromRGB(65, 166, 244),
    Green = Color3.fromRGB(55, 184, 113),
    Gold = Color3.fromRGB(231, 171, 49),
    Red = Color3.fromRGB(217, 75, 74),
    Purple = Color3.fromRGB(145, 89, 187),
    Orange = Color3.fromRGB(222, 119, 43),
    Teal = Color3.fromRGB(40, 147, 136),
    Text = Color3.fromRGB(248, 250, 255),
    Muted = Color3.fromRGB(190, 202, 216),
    Dark = Color3.fromRGB(14, 20, 30),
}

local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("RoubeUmAnimalHUD")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeUmAnimalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 15
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(instance, radius)
    local object = Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 12)
    object.Parent = instance
    return object
end

local function stroke(instance, color, thickness, transparency)
    local object = Instance.new("UIStroke")
    object.Color = color or COLORS.Blue
    object.Thickness = thickness or 1
    object.Transparency = transparency or 0.25
    object.Parent = instance
    return object
end

local function makeLabel(parent, name, text, size, position, fontSize, color, alignment)
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

local function makeButton(parent, name, text, size, position, color, callback)
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = color or COLORS.PanelLight
    object.BorderSizePixel = 0
    object.AutoButtonColor = true
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextColor3 = COLORS.Text
    object.TextScaled = true
    object.TextWrapped = true
    object.Selectable = true
    object.Active = true
    object.Parent = parent
    corner(object, 10)
    stroke(object, COLORS.Dark, 2, 0.35)
    object.Activated:Connect(callback)
    return object
end

local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.new(0.96, 0, 0, 86)
statsPanel.Position = UDim2.new(0.5, 0, 0, 8)
statsPanel.AnchorPoint = Vector2.new(0.5, 0)
statsPanel.BackgroundColor3 = COLORS.Background
statsPanel.BackgroundTransparency = 0.04
statsPanel.BorderSizePixel = 0
statsPanel.Parent = gui
corner(statsPanel, 14)
stroke(statsPanel, COLORS.Blue, 2, 0.22)

local statsConstraint = Instance.new("UISizeConstraint")
statsConstraint.MinSize = Vector2.new(270, 86)
statsConstraint.MaxSize = Vector2.new(540, 86)
statsConstraint.Parent = statsPanel

local title = makeLabel(
    statsPanel,
    "Title",
    "ROUBE UM ANIMAL",
    UDim2.new(1, -20, 0, 24),
    UDim2.new(0, 10, 0, 3),
    16,
    COLORS.Blue,
    Enum.TextXAlignment.Center
)
title.Font = Enum.Font.GothamBlack

local statRow = Instance.new("Frame")
statRow.Name = "StatsRow"
statRow.Size = UDim2.new(1, -12, 0, 25)
statRow.Position = UDim2.new(0, 6, 0, 27)
statRow.BackgroundTransparency = 1
statRow.Parent = statsPanel

local statLayout = Instance.new("UIListLayout")
statLayout.FillDirection = Enum.FillDirection.Horizontal
statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statLayout.SortOrder = Enum.SortOrder.LayoutOrder
statLayout.Padding = UDim.new(0, 2)
statLayout.Parent = statRow

local function statText(name, defaultText, order, color)
    local text = Instance.new("TextLabel")
    text.Name = name
    text.Size = UDim2.new(0.25, -2, 1, 0)
    text.BackgroundColor3 = COLORS.PanelLight
    text.BorderSizePixel = 0
    text.Font = Enum.Font.GothamBold
    text.Text = defaultText
    text.TextColor3 = color or COLORS.Text
    text.TextScaled = true
    text.TextWrapped = true
    text.LayoutOrder = order
    text.Parent = statRow
    corner(text, 6)
    return text
end

local coinsLabel = statText("Coins", "Moedas: …", 1, COLORS.Gold)
local speedLabel = statText("Speed", "Vel: …", 2, COLORS.Blue)
local strengthLabel = statText("Strength", "Força: …", 3, COLORS.Red)
local rebirthLabel = statText("Rebirths", "RB: 0", 4, COLORS.Orange)

local carryLabel = makeLabel(
    statsPanel,
    "Carry",
    "Carregando: nenhum animal",
    UDim2.new(1, -18, 0, 20),
    UDim2.new(0, 9, 0, 60),
    11,
    COLORS.Muted,
    Enum.TextXAlignment.Center
)

local navPanel = Instance.new("Frame")
navPanel.Name = "MainNavigation"
navPanel.Size = UDim2.new(0.94, 0, 0, 62)
navPanel.Position = UDim2.new(0.5, 0, 1, -10)
navPanel.AnchorPoint = Vector2.new(0.5, 1)
navPanel.BackgroundColor3 = COLORS.Background
navPanel.BackgroundTransparency = 0.04
navPanel.BorderSizePixel = 0
navPanel.Parent = gui
corner(navPanel, 13)
stroke(navPanel, COLORS.Blue, 1.5, 0.25)

local navConstraint = Instance.new("UISizeConstraint")
navConstraint.MinSize = Vector2.new(270, 62)
navConstraint.MaxSize = Vector2.new(520, 62)
navConstraint.Parent = navPanel

local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 6)
navPadding.PaddingRight = UDim.new(0, 6)
navPadding.PaddingTop = UDim.new(0, 6)
navPadding.PaddingBottom = UDim.new(0, 6)
navPadding.Parent = navPanel

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 6)
navLayout.Parent = navPanel

local modalBackdrop = Instance.new("Frame")
modalBackdrop.Name = "ModalBackdrop"
modalBackdrop.Size = UDim2.fromScale(1, 1)
modalBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modalBackdrop.BackgroundTransparency = 0.38
modalBackdrop.Visible = false
modalBackdrop.Active = true
modalBackdrop.ZIndex = 30
modalBackdrop.Parent = gui

local modal = Instance.new("Frame")
modal.Name = "Window"
modal.Size = UDim2.fromOffset(330, 440)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.BackgroundColor3 = COLORS.Background
modal.BorderSizePixel = 0
modal.ZIndex = 31
modal.Parent = modalBackdrop
corner(modal, 16)
stroke(modal, COLORS.Blue, 2, 0.1)

local activeScreen
local lastSelectable

local modalScale = Instance.new("UIScale")
modalScale.Scale = 0.92
modalScale.Parent = modal

local modalTitle = makeLabel(
    modal,
    "WindowTitle",
    "LOJA",
    UDim2.new(1, -68, 0, 36),
    UDim2.new(0, 16, 0, 8),
    20,
    COLORS.Text
)
modalTitle.ZIndex = 33
modalTitle.Font = Enum.Font.GothamBlack

local closeButton = makeButton(
    modal,
    "Close",
    "X",
    UDim2.fromOffset(38, 34),
    UDim2.new(1, -48, 0, 9),
    COLORS.Red,
    function()
        modalBackdrop.Visible = false
        activeScreen = nil
        GuiService.SelectedObject = nil
    end
)
closeButton.ZIndex = 34

local content = Instance.new("ScrollingFrame")
content.Name = "WindowContent"
content.Size = UDim2.new(1, -20, 1, -58)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundColor3 = COLORS.Panel
content.BackgroundTransparency = 0.08
content.BorderSizePixel = 0
content.ScrollBarThickness = 6
content.ScrollBarImageColor3 = COLORS.Blue
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.Active = true
content.ZIndex = 32
content.Parent = modal
corner(content, 11)

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = content

local function resizeUI()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    statsPanel.Size = UDim2.new(0.96, 0, 0, 86)
    navPanel.Size = UDim2.new(0.94, 0, 0, 62)

    local width = math.max(220, math.min(610, viewport.X - 20, viewport.X * 0.94))
    local height = math.max(170, math.min(540, viewport.Y - 48, viewport.Y * 0.82))
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

local function addInfo(text, order)
    local object = makeLabel(
        content,
        "Info" .. tostring(order or 0),
        text,
        UDim2.new(1, -8, 0, 58),
        UDim2.new(0, 0, 0, 0),
        13,
        COLORS.Muted
    )
    object.LayoutOrder = order or 1
    object.ZIndex = 33
    object.TextYAlignment = Enum.TextYAlignment.Center
    return object
end

local function addAction(name, titleText, description, buttonText, color, callback, order, disabled, markerText)
    local card = Instance.new("Frame")
    card.Name = name .. "Card"
    card.Size = UDim2.new(1, -4, 0, markerText and 84 or 74)
    card.BackgroundColor3 = COLORS.PanelLight
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.ZIndex = 33
    card.Parent = content
    corner(card, 10)
    stroke(card, color or COLORS.Blue, 1.2, 0.3)

    local action = Instance.new("TextButton")
    action.Name = name
    action.Size = UDim2.new(1, 0, 1, 0)
    action.BackgroundTransparency = 1
    action.BorderSizePixel = 0
    action.Text = ""
    action.Active = not disabled
    action.Selectable = not disabled
    action.AutoButtonColor = not disabled
    action.ZIndex = 34
    action.Parent = card

    local textOffset = markerText and 49 or 9
    local textWidth = markerText and 0.46 or 0.66
    if markerText then
        local marker = Instance.new("TextLabel")
        marker.Name = "DistinctiveMarker"
        marker.Size = UDim2.fromOffset(34, 34)
        marker.Position = UDim2.new(0, 8, 0.5, -17)
        marker.BackgroundColor3 = color or COLORS.Blue
        marker.BorderSizePixel = 0
        marker.Font = Enum.Font.GothamBlack
        marker.Text = markerText
        marker.TextColor3 = COLORS.Text
        marker.TextScaled = true
        marker.TextWrapped = true
        marker.ZIndex = 35
        marker.Parent = action
        corner(marker, 9)
        stroke(marker, COLORS.Text, 1, 0.7)
    end

    local titleLabel = makeLabel(
        action,
        "Title",
        titleText,
        UDim2.new(textWidth, -14, 0, 26),
        UDim2.new(0, textOffset, 0, 7),
        markerText and 12 or 14,
        color or COLORS.Text
    )
    titleLabel.ZIndex = 35
    titleLabel.Font = Enum.Font.GothamBlack

    local descLabel = makeLabel(
        action,
        "Description",
        description,
        UDim2.new(markerText and 0.46 or 0.66, -8, 0, markerText and 38 or 30),
        UDim2.new(0, textOffset, 0, 34),
        11,
        COLORS.Muted
    )
    descLabel.ZIndex = 35

    local buttonLabel = makeLabel(
        action,
        "ButtonText",
        buttonText or "ABRIR",
        UDim2.new(0.29, -4, 0, markerText and 42 or 36),
        UDim2.new(0.70, 0, 0.5, markerText and -21 or -18),
        10,
        disabled and COLORS.Muted or COLORS.Text,
        Enum.TextXAlignment.Center
    )
    buttonLabel.ZIndex = 36
    buttonLabel.Font = Enum.Font.GothamBlack

    if not disabled then
        action.Activated:Connect(callback)
    end

    if not lastSelectable and not disabled then
        lastSelectable = action
    end

    return card
end

local function formatNumber(value)
    local amount = tonumber(value) or 0
    if amount >= 1000000 then
        return string.format("%.1fM", amount / 1000000)
    end
    if amount >= 1000 then
        return string.format("%.1fK", amount / 1000)
    end
    return tostring(math.floor(amount))
end

local function displayToast(message, messageType)
    local toast = gui:FindFirstChild("Toast")
    if not toast then
        toast = Instance.new("TextLabel")
        toast.Name = "Toast"
        toast.Size = UDim2.new(0.86, 0, 0, 52)
        toast.Position = UDim2.new(0.5, 0, 0.5, 0)
        toast.AnchorPoint = Vector2.new(0.5, 0.5)
        toast.BackgroundColor3 = COLORS.Background
        toast.BorderSizePixel = 0
        toast.Font = Enum.Font.GothamBold
        toast.TextColor3 = COLORS.Text
        toast.TextSize = 15
        toast.TextWrapped = true
        toast.Visible = false
        toast.ZIndex = 50
        toast.Parent = gui
        corner(toast, 12)
        stroke(toast, COLORS.Blue, 1.5, 0.15)

        local constraint = Instance.new("UISizeConstraint")
        constraint.MinSize = Vector2.new(240, 52)
        constraint.MaxSize = Vector2.new(480, 52)
        constraint.Parent = toast
    end

    toast:SetAttribute("ToastSequence", (toast:GetAttribute("ToastSequence") or 0) + 1)
    local sequence = toast:GetAttribute("ToastSequence")
    toast.Text = tostring(message)

    if messageType == "Success" then
        toast.TextColor3 = COLORS.Green
    elseif messageType == "Warning" then
        toast.TextColor3 = COLORS.Gold
    elseif messageType == "Error" then
        toast.TextColor3 = COLORS.Red
    else
        toast.TextColor3 = COLORS.Text
    end

    toast.Visible = true
    task.delay(3.5, function()
        if toast.Parent and toast:GetAttribute("ToastSequence") == sequence then
            toast.Visible = false
        end
    end)
end

local function updateStats()
    coinsLabel.Text = "MOEDAS\n" .. formatNumber(player:GetAttribute("Coins"))
    speedLabel.Text = "VEL " .. formatNumber(player:GetAttribute("SpeedLevel"))
    strengthLabel.Text = "FOR " .. formatNumber(player:GetAttribute("Strength"))
    rebirthLabel.Text = "RB " .. formatNumber(player:GetAttribute("Rebirths"))

    if player:GetAttribute("CarryingAnimal") == true then
        carryLabel.Text = "CARREGANDO: " .. tostring(player:GetAttribute("CarriedAnimalName") or "ANIMAL")
            .. "  •  PESO " .. formatNumber(player:GetAttribute("CarriedAnimalWeight"))
        carryLabel.TextColor3 = COLORS.Gold
    else
        carryLabel.Text = "Nenhum animal carregado • volte ao seu curral para vender"
        carryLabel.TextColor3 = COLORS.Muted
    end
end

local function renderShop()
    clearContent()
    addInfo("LOJA DE MELHORIAS — use suas moedas para evoluir sem Robux.", 1)
    addAction("BuySpeed", "Treino de Velocidade", "Compra +1 nível de velocidade. O custo cresce conforme você evolui.", "MELHORAR", COLORS.Blue, function() upgradeRemote:FireServer("Speed") end, 2, false, "SPD")
    addAction("BuyStrength", "Treino de Força", "Compra +5 de Força. Necessária para roubar espécies mais raras.", "MELHORAR", COLORS.Red, function() upgradeRemote:FireServer("Strength") end, 3, false, "STR")
    addInfo("DICA: a esteira aumenta Velocidade e o supino aumenta Força sem gastar moedas.", 4)
end

local function renderPasses()
    clearContent()
    addInfo("PASSES PERMANENTES — cada item tem um efeito diferente e é comprado uma única vez.", 1)
    local passes = {
        { key = "DoubleSpeed", title = "Turbo: 2x Velocidade", desc = "Dobra a velocidade de movimento e os ganhos da esteira.", attr = "HasDoubleSpeed", color = COLORS.Blue, marker = "2X\nSPD", cta = "TURBO" },
        { key = "DoubleStrength", title = "Força: 2x Treino", desc = "Dobra os ganhos de Força no supino e nos upgrades com moedas.", attr = "HasDoubleStrength", color = COLORS.Purple, marker = "2X\nSTR", cta = "FORÇA" },
        { key = "DoubleCoins", title = "Magnata: 2x Moedas", desc = "Receba o dobro de moedas ao vender animais.", attr = "HasDoubleCoins", color = COLORS.Gold, marker = "2X\n$", cta = "MOEDAS" },
        { key = "VIPSpeed", title = "VIP: +50 Velocidade", desc = "Bônus fixo de +50 na velocidade-base, respeitando o limite do jogo.", attr = "HasVIPSpeed", color = COLORS.Teal, marker = "VIP", cta = "VIP" },
    }
    for index, item in ipairs(passes) do
        local active = player:GetAttribute(item.attr) == true
        local passId = MonetizationIds.Passes[item.key]
        local configured = type(passId) == "number" and passId > 0
        local description = item.desc
        if not configured then description = description .. " ID pendente no Creator Dashboard." end
        addAction(item.key, active and (item.title .. " — ATIVO") or item.title, description, active and "ATIVO" or (configured and item.cta or "ID PENDENTE"), item.color, function() passRequestRemote:FireServer(item.key) end, index + 2, active, item.marker)
    end
    addInfo("PRODUTOS ACUMULÁVEIS — compras repetíveis, com entrega confirmada e salva pelo servidor.", 7)
    local speedConfigured = type(MonetizationIds.Products.StackableSpeed) == "number" and MonetizationIds.Products.StackableSpeed > 0
    addAction("StackableSpeed", "+10 Velocidade", speedConfigured and "Compra repetível que soma +10 níveis até o limite." or "Compra repetível: +10 níveis. ID pendente no Creator Dashboard.", speedConfigured and "COMPRAR" or "ID PENDENTE", COLORS.Green, function() productRequestRemote:FireServer("StackableSpeed") end, 8, (tonumber(player:GetAttribute("SpeedLevel")) or 0) >= Config.MaxSpeedLevel, "+10\nSPD")
    local strengthConfigured = type(MonetizationIds.Products.StackableStrength) == "number" and MonetizationIds.Products.StackableStrength > 0
    addAction("StackableStrength", "+10 Força", strengthConfigured and "Compra repetível que soma +10 de Força até o limite." or "Compra repetível: +10 de Força. ID pendente no Creator Dashboard.", strengthConfigured and "COMPRAR" or "ID PENDENTE", COLORS.Orange, function() productRequestRemote:FireServer("StackableStrength") end, 9, (tonumber(player:GetAttribute("Strength")) or 0) >= Config.MaxStrength, "+10\nSTR")
end

local biomeOrder = {
    Farm = 1,
    Jungle = 2,
    Volcano = 3,
}

local biomeNames = {
    Farm = "FAZENDA",
    Jungle = "SELVA",
    Volcano = "VULCÃO",
}

local rarityNames = {
    Common = "Comum",
    Uncommon = "Incomum",
    Rare = "Raro",
    Epic = "Épico",
    Legendary = "Lendário",
    Mythic = "Mítico",
}

local function renderAnimals()
    clearContent()
    addInfo("Catálogo dos animais que podem ser roubados e vendidos. Esta experiência não guarda animais como pets no inventário.", 1)

    local animals = {}
    for _, animal in pairs(Catalog.Animals) do
        table.insert(animals, animal)
    end

    table.sort(animals, function(a, b)
        local biomeA = biomeOrder[a.Biome] or 99
        local biomeB = biomeOrder[b.Biome] or 99
        if biomeA == biomeB then
            return a.RequiredStrength < b.RequiredStrength
        end
        return biomeA < biomeB
    end)

    for index, animal in ipairs(animals) do
        local color = animal.Biome == "Farm" and COLORS.Green
            or animal.Biome == "Jungle" and COLORS.Teal
            or COLORS.Orange
        local requirementMet = (tonumber(player:GetAttribute("Strength")) or 0) >= animal.RequiredStrength
        addAction(
            "Animal_" .. animal.Id,
            animal.DisplayName .. " • " .. (rarityNames[animal.Rarity] or animal.Rarity),
            biomeNames[animal.Biome] .. "  |  Força " .. tostring(animal.RequiredStrength)
                .. "  |  Peso " .. tostring(animal.Weight)
                .. "  |  Valor-base " .. formatNumber(animal.BaseValue)
                .. (requirementMet and "  |  REQUISITO OK" or "  |  FORÇA INSUFICIENTE"),
            requirementMet and "PODE ROUBAR" or "TREINE",
            color,
            function()
                displayToast(
                    requirementMet and ("Procure " .. animal.DisplayName .. " no bioma " .. biomeNames[animal.Biome] .. ".")
                        or ("Treine até Força " .. tostring(animal.RequiredStrength) .. "."),
                    requirementMet and "Info" or "Warning"
                )
            end,
            index + 1
        )
    end
end

local function renderRebirth()
    clearContent()
    local rebirths = tonumber(player:GetAttribute("Rebirths")) or 0
    local speed = tonumber(player:GetAttribute("SpeedLevel")) or 0
    local strength = tonumber(player:GetAttribute("Strength")) or 0
    local carrying = player:GetAttribute("CarryingAnimal") == true
    local atCap = rebirths >= Config.MaxRebirths
    local eligible = speed >= Config.MaxSpeedLevel and strength >= Config.MaxStrength and not carrying and not atCap
    local bonus = math.floor(rebirths * Config.RebirthCoinBonusPerRebirth * 100)

    addInfo(
        "Renascimento " .. tostring(rebirths) .. " / " .. tostring(Config.MaxRebirths)
            .. "\nBônus atual de vendas: +" .. tostring(bonus) .. "% de moedas."
            .. "\nAo renascer: Velocidade volta a 0 e Força a 10. O bônus permanente aumenta em "
            .. tostring(math.floor(Config.RebirthCoinBonusPerRebirth * 100)) .. "%.",
        1
    )

    addInfo(
        "REQUISITOS\nVelocidade: " .. tostring(speed) .. " / " .. tostring(Config.MaxSpeedLevel)
            .. "\nForça: " .. tostring(strength) .. " / " .. tostring(Config.MaxStrength)
            .. "\nNão pode estar carregando um animal.",
        2
    )

    addAction(
        "RequestRebirth",
        atCap and "Limite de renascimentos atingido" or "Confirmar Renascimento",
        eligible
            and "Seu progresso será salvo no servidor antes da confirmação."
            or (atCap and "Você já atingiu o limite." or "Complete os requisitos antes de renascer."),
        eligible and "RENASCER" or "BLOQUEADO",
        COLORS.Orange,
        function()
            rebirthRequestRemote:FireServer()
        end,
        3,
        not eligible
    )

    addInfo("As moedas e gamepasses permanentes são mantidos. O renascimento só é confirmado se a gravação no DataStore for bem-sucedida.", 4)
end

local function openScreen(name)
    activeScreen = name
    modalTitle.Text = name == "Shop" and "LOJA DE MELHORIAS"
        or name == "Passes" and "PASSES & ROBUX"
        or name == "Animals" and "CATÁLOGO DE ANIMAIS"
        or "RENASCIMENTO"
    if name == "Shop" then
        renderShop()
    elseif name == "Passes" then
        renderPasses()
    elseif name == "Animals" then
        renderAnimals()
    else
        renderRebirth()
    end

    resizeUI()
    modalBackdrop.Visible = true
    modalScale.Scale = 0.92
    TweenService:Create(modalScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    task.defer(function()
        if modalBackdrop.Visible and lastSelectable and UserInputService.GamepadEnabled then
            GuiService.SelectedObject = lastSelectable
        end
    end)
end

makeButton(
    navPanel,
    "OpenShop",
    "LOJA",
    UDim2.new(0.25, -8, 1, -12),
    UDim2.new(),
    COLORS.Green,
    function()
        openScreen("Shop")
    end
).LayoutOrder = 1

makeButton(
    navPanel,
    "OpenPasses",
    "PASSES",
    UDim2.new(0.25, -8, 1, -12),
    UDim2.new(),
    COLORS.Blue,
    function()
        openScreen("Passes")
    end
).LayoutOrder = 2

makeButton(
    navPanel,
    "OpenAnimals",
    "ANIMAIS",
    UDim2.new(0.25, -8, 1, -12),
    UDim2.new(),
    COLORS.Purple,
    function()
        openScreen("Animals")
    end
).LayoutOrder = 3

makeButton(
    navPanel,
    "OpenRebirth",
    "RENASCER",
    UDim2.new(0.25, -8, 1, -12),
    UDim2.new(),
    COLORS.Orange,
    function()
        openScreen("Rebirth")
    end
).LayoutOrder = 4

local function promptPass(passId)
    if type(passId) ~= "number" or passId <= 0 then
        displayToast("Gamepass ainda não configurado.", "Warning")
        return
    end

    local success, err = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, passId)
    end)

    if not success then
        displayToast("Não foi possível abrir o gamepass: " .. tostring(err), "Error")
    end
end

local function promptProduct(productId)
    if type(productId) ~= "number" or productId <= 0 then
        displayToast("Produto acumulável ainda não configurado.", "Warning")
        return
    end

    local success, err = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)

    if not success then
        displayToast("Não foi possível abrir o produto: " .. tostring(err), "Error")
    end
end

notifyRemote.OnClientEvent:Connect(displayToast)
passPromptRemote.OnClientEvent:Connect(promptPass)
productPromptRemote.OnClientEvent:Connect(promptProduct)

for _, attribute in ipairs({
    "Coins",
    "SpeedLevel",
    "Strength",
    "Rebirths",
    "CarryingAnimal",
    "CarriedAnimalName",
    "CarriedAnimalWeight",
    "HasDoubleSpeed",
    "HasDoubleStrength",
    "HasDoubleCoins",
    "HasVIPSpeed",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(function()
        updateStats()
        if activeScreen == "Shop" then
            renderShop()
        elseif activeScreen == "Passes" then
            renderPasses()
        elseif activeScreen == "Animals" then
            renderAnimals()
        elseif activeScreen == "Rebirth" then
            renderRebirth()
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
updateStats()

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not modalBackdrop.Visible then
        return
    end

    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
        modalBackdrop.Visible = false
        activeScreen = nil
        GuiService.SelectedObject = nil
    end
end)
