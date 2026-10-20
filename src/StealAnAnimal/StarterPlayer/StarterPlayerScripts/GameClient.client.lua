local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("StealAnimalRemotes")
local notifyRemote = remotes:WaitForChild("Notify")
local upgradeRemote = remotes:WaitForChild("RequestUpgrade")
local collectRemote = remotes:WaitForChild("RequestCollect")
local rebirthRemote = remotes:WaitForChild("RequestRebirth")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("AnimalCatalog"))

local COLORS = {
    Background = Color3.fromRGB(13, 25, 29),
    Panel = Color3.fromRGB(20, 39, 43),
    PanelRaised = Color3.fromRGB(28, 53, 55),
    Card = Color3.fromRGB(32, 59, 60),
    CardEdge = Color3.fromRGB(59, 92, 86),
    Mint = Color3.fromRGB(130, 231, 173),
    Gold = Color3.fromRGB(255, 207, 105),
    Cream = Color3.fromRGB(250, 247, 232),
    Muted = Color3.fromRGB(174, 194, 186),
    Aqua = Color3.fromRGB(105, 211, 221),
    Orange = Color3.fromRGB(255, 159, 95),
    Red = Color3.fromRGB(255, 113, 112),
    Purple = Color3.fromRGB(196, 162, 255),
}

local old = playerGui:FindFirstChild("StealAnAnimalHUD")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "StealAnAnimalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Name = "ResponsiveScale"
uiScale.Scale = 1
uiScale.Parent = gui

local touchDevice = UserInputService.TouchEnabled

local function updateScale()
    local camera = workspace.CurrentCamera
    if camera then
        local baseScale = touchDevice and 1 or camera.ViewportSize.X / 1100
        uiScale.Scale = math.clamp(baseScale, 0.92, 1.12)
    end
end

updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)

local function round(object, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius or 14)
    item.Parent = object
end

local function outline(object, color, thickness, transparency)
    local item = Instance.new("UIStroke")
    item.Color = color
    item.Thickness = thickness or 1
    item.Transparency = transparency or 0.15
    item.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    item.Parent = object
    return item
end

local function makeLabel(parent, name, text, size, position, fontSize, color, font, xAlign)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.Font = font or Enum.Font.GothamMedium
    item.Text = text
    item.TextColor3 = color or COLORS.Cream
    item.TextSize = fontSize or 14
    item.TextWrapped = true
    item.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Parent = parent
    return item
end

local function makeButton(parent, name, text, color, textColor)
    local item = Instance.new("TextButton")
    item.Name = name
    item.BackgroundColor3 = color
    item.BorderSizePixel = 0
    item.AutoButtonColor = true
    item.Font = Enum.Font.GothamBold
    item.Text = text
    item.TextColor3 = textColor or COLORS.Background
    item.TextSize = 13
    item.TextWrapped = true
    item.Parent = parent
    round(item, 12)
    return item
end

local function formatNumber(value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if value >= 1000000000 then return string.format("%.2fB", value / 1000000000) end
    if value >= 1000000 then return string.format("%.2fM", value / 1000000) end
    if value >= 10000 then return string.format("%.1fK", value / 1000) end
    return tostring(value)
end

local top = Instance.new("Frame")
top.Name = "TopDashboard"
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.new(0.5, 0, 0, 10)
top.Size = UDim2.new(1, -20, 0, 128)
top.BackgroundColor3 = COLORS.Background
top.BackgroundTransparency = 0.04
top.BorderSizePixel = 0
top.Parent = gui
round(top, 18)
outline(top, COLORS.CardEdge, 1.3)
local topConstraint = Instance.new("UISizeConstraint")
topConstraint.MaxSize = Vector2.new(760, 128)
topConstraint.MinSize = Vector2.new(260, 128)
topConstraint.Parent = top

local title = makeLabel(top, "GameTitle", "STEAL AN ANIMAL", UDim2.new(1, -148, 0, 25), UDim2.new(0, 14, 0, 7), 16, COLORS.Gold, Enum.Font.GothamBlack)
local rebirthBadge = Instance.new("Frame")
rebirthBadge.Name = "RebirthBadge"
rebirthBadge.AnchorPoint = Vector2.new(1, 0)
rebirthBadge.Position = UDim2.new(1, -43, 0, 7)
rebirthBadge.Size = UDim2.new(0, 108, 0, 25)
rebirthBadge.BackgroundColor3 = COLORS.PanelRaised
rebirthBadge.BorderSizePixel = 0
rebirthBadge.Parent = top
round(rebirthBadge, 9)
outline(rebirthBadge, COLORS.Purple, 1)
local rebirthBadgeText = makeLabel(rebirthBadge, "Count", "RENASC. 0", UDim2.new(1, -8, 1, 0), UDim2.new(0, 4, 0, 0), 10, COLORS.Purple, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

local helpButton = makeButton(top, "Help", "?", COLORS.Card, COLORS.Cream)
helpButton.AnchorPoint = Vector2.new(1, 0)
helpButton.Position = UDim2.new(1, -9, 0, 6)
helpButton.Size = UDim2.new(0, 27, 0, 27)
helpButton.TextSize = 16
outline(helpButton, COLORS.CardEdge, 1)

local statsFrame = Instance.new("Frame")
statsFrame.Name = "ResourceCards"
statsFrame.Position = UDim2.new(0, 10, 0, 39)
statsFrame.Size = UDim2.new(1, -20, 0, 53)
statsFrame.BackgroundTransparency = 1
statsFrame.Parent = top

local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Padding = UDim.new(0, 6)
statsLayout.Parent = statsFrame

local function makeStat(name, label, accent, order)
    local card = Instance.new("Frame")
    card.Name = name
    card.LayoutOrder = order
    card.Size = UDim2.new(1 / 3, -4, 1, 0)
    card.BackgroundColor3 = COLORS.Card
    card.BorderSizePixel = 0
    card.Parent = statsFrame
    round(card, 11)
    outline(card, COLORS.CardEdge, 1, 0.3)
    local marker = Instance.new("Frame")
    marker.Name = "Accent"
    marker.Size = UDim2.new(0, 3, 1, -14)
    marker.Position = UDim2.new(0, 6, 0, 7)
    marker.BackgroundColor3 = accent
    marker.BorderSizePixel = 0
    marker.Parent = card
    round(marker, 2)
    makeLabel(card, "Caption", label, UDim2.new(1, -18, 0, 16), UDim2.new(0, 14, 0, 5), 9, COLORS.Muted, Enum.Font.GothamBold)
    local value = makeLabel(card, "Value", "0", UDim2.new(1, -18, 0, 24), UDim2.new(0, 14, 0, 23), 15, accent, Enum.Font.GothamBlack)
    return value
end

local coinsValue = makeStat("CoinsCard", "MOEDAS", COLORS.Gold, 1)
local incomeValue = makeStat("IncomeCard", "RENDA / SEG", COLORS.Mint, 2)
local speedValue = makeStat("SpeedCard", "VELOCIDADE", COLORS.Aqua, 3)
local overview = makeLabel(top, "Overview", "CELEIRO 0/6  •  BANCO 0", UDim2.new(1, -24, 0, 20), UDim2.new(0, 14, 0, 98), 10, COLORS.Muted, Enum.Font.GothamBold)

local objective = Instance.new("Frame")
objective.Name = "Objective"
objective.AnchorPoint = Vector2.new(0.5, 0)
objective.Position = UDim2.new(0.5, 0, 0, 146)
objective.Size = UDim2.new(0.88, 0, 0, 32)
objective.BackgroundColor3 = COLORS.Panel
objective.BackgroundTransparency = 0.08
objective.BorderSizePixel = 0
objective.Parent = gui
round(objective, 10)
outline(objective, COLORS.CardEdge, 1, 0.35)
local objectiveText = makeLabel(objective, "Text", "ROUBE UM FILHOTE E LEVE-O À SUA FAZENDA", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), 10, COLORS.Cream, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

local dock = Instance.new("Frame")
dock.Name = "ActionDock"
dock.AnchorPoint = Vector2.new(0.5, 1)
dock.Position = UDim2.new(0.5, 0, 1, -10)
dock.Size = UDim2.new(1, -18, 0, 72)
dock.BackgroundColor3 = COLORS.Background
dock.BackgroundTransparency = 0.03
dock.BorderSizePixel = 0
dock.Parent = gui
round(dock, 18)
outline(dock, COLORS.CardEdge, 1.2)
local dockConstraint = Instance.new("UISizeConstraint")
dockConstraint.MaxSize = Vector2.new(720, 72)
dockConstraint.MinSize = Vector2.new(250, 72)
dockConstraint.Parent = dock

local dockPadding = Instance.new("UIPadding")
dockPadding.PaddingLeft = UDim.new(0, 7)
dockPadding.PaddingRight = UDim.new(0, 7)
dockPadding.PaddingTop = UDim.new(0, 7)
dockPadding.PaddingBottom = UDim.new(0, 7)
dockPadding.Parent = dock

local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
dockLayout.Padding = UDim.new(0, 5)
dockLayout.Parent = dock

local function makeDockButton(name, text, order, accent)
    local button = makeButton(dock, name, text, COLORS.PanelRaised, COLORS.Cream)
    button.LayoutOrder = order
    button.Size = UDim2.new(0.25, -8, 1, 0)
    button.TextSize = 11
    outline(button, accent, 1.2, 0.2)
    return button
end

local barnButton = makeDockButton("OpenBarn", "CELEIRO", 1, COLORS.Mint)
local collectButton = makeDockButton("Collect", "COLETAR", 2, COLORS.Gold)
local upgradeButton = makeDockButton("OpenTreadmill", "ESTEIRA", 3, COLORS.Aqua)
local rebirthButton = makeDockButton("OpenRebirth", "RENASCER", 4, COLORS.Purple)

local shade = Instance.new("Frame")
shade.Name = "ModalShade"
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.fromRGB(4, 9, 11)
shade.BackgroundTransparency = 0.36
shade.Visible = false
shade.ZIndex = 70
shade.Parent = gui

local modal = Instance.new("Frame")
modal.Name = "Modal"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.Size = UDim2.new(0.9, 0, 0, 320)
modal.BackgroundColor3 = COLORS.Panel
modal.BorderSizePixel = 0
modal.ZIndex = 71
modal.Parent = shade
round(modal, 18)
outline(modal, COLORS.CardEdge, 1.5)
local modalConstraint = Instance.new("UISizeConstraint")
modalConstraint.MaxSize = Vector2.new(480, 320)
modalConstraint.MinSize = Vector2.new(260, 300)
modalConstraint.Parent = modal

local modalTitle = makeLabel(modal, "ModalTitle", "", UDim2.new(1, -64, 0, 28), UDim2.new(0, 16, 0, 12), 17, COLORS.Gold, Enum.Font.GothamBlack)
modalTitle.ZIndex = 72
local closeButton = makeButton(modal, "Close", "×", COLORS.Card, COLORS.Cream)
closeButton.Position = UDim2.new(1, -43, 0, 10)
closeButton.Size = UDim2.new(0, 31, 0, 31)
closeButton.TextSize = 20
closeButton.ZIndex = 72
local modalRule = Instance.new("Frame")
modalRule.Size = UDim2.new(1, -30, 0, 1)
modalRule.Position = UDim2.new(0, 15, 0, 49)
modalRule.BackgroundColor3 = COLORS.CardEdge
modalRule.BorderSizePixel = 0
modalRule.ZIndex = 72
modalRule.Parent = modal
local modalBody = makeLabel(modal, "Body", "", UDim2.new(1, -32, 0, 158), UDim2.new(0, 16, 0, 60), 13, COLORS.Cream, Enum.Font.GothamMedium)
modalBody.TextYAlignment = Enum.TextYAlignment.Top
modalBody.ZIndex = 72

local primaryButton = makeButton(modal, "PrimaryAction", "", COLORS.Mint, COLORS.Background)
primaryButton.Position = UDim2.new(0, 16, 1, -58)
primaryButton.Size = UDim2.new(1, -32, 0, 43)
primaryButton.ZIndex = 72
local secondaryButton = makeButton(modal, "SecondaryAction", "FECHAR", COLORS.Card, COLORS.Cream)
secondaryButton.Position = UDim2.new(0, 16, 1, -58)
secondaryButton.Size = UDim2.new(1, -32, 0, 43)
secondaryButton.ZIndex = 72
secondaryButton.Visible = false

local toast = Instance.new("Frame")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 188)
toast.Size = UDim2.new(0.84, 0, 0, 54)
toast.BackgroundColor3 = COLORS.PanelRaised
toast.BackgroundTransparency = 0.04
toast.BorderSizePixel = 0
toast.Visible = false
toast.ZIndex = 100
toast.Parent = gui
round(toast, 13)
outline(toast, COLORS.Gold, 1.4)
local toastText = makeLabel(toast, "Message", "", UDim2.new(1, -20, 1, -10), UDim2.new(0, 10, 0, 5), 13, COLORS.Cream, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
toastText.ZIndex = 101
local toastToken = 0

local function showToast(message, kind)
    toastToken += 1
    local token = toastToken
    toastText.Text = tostring(message)
    toastText.TextColor3 = kind == "Error" and COLORS.Red or kind == "Warning" and COLORS.Orange or kind == "Success" and COLORS.Mint or COLORS.Cream
    toast.Visible = true
    toast.Position = UDim2.new(0.5, 0, 0, 181)
    TweenService:Create(toast, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 192),
    }):Play()
    task.delay(3.5, function()
        if token == toastToken then
            toast.Visible = false
        end
    end)
end

local activePanel = nil
local confirmingRebirth = false

local function closeModal()
    shade.Visible = false
    activePanel = nil
    confirmingRebirth = false
    secondaryButton.Visible = false
    primaryButton.Visible = true
end

local function openPanel(kind, preserveConfirmation)
    activePanel = kind
    if preserveConfirmation ~= true then
        confirmingRebirth = false
    end
    shade.Visible = true
    secondaryButton.Visible = false
    primaryButton.Visible = true
    if kind == "Barn" then
        modalTitle.Text = "MEU CELEIRO"
        local summary = tostring(player:GetAttribute("BarnSummary") or "Carregando seus animais...")
        modalBody.Text = "ANIMAIS  " .. tostring(player:GetAttribute("BarnAnimalCount") or 0) .. "/" .. tostring(player:GetAttribute("BarnCapacity") or Config.BaseSlots)
            .. "\nRENDA  " .. formatNumber(player:GetAttribute("BarnIncomeRate")) .. " moedas/s"
            .. "\nBANCO  " .. formatNumber(player:GetAttribute("BarnBank"))
            .. "\n\n" .. summary
        primaryButton.Text = "COLETAR NO BANCO"
        primaryButton.BackgroundColor3 = COLORS.Gold
        secondaryButton.Visible = false
    elseif kind == "Treadmill" then
        modalTitle.Text = "ESTEIRA DE VELOCIDADE"
        local level = tonumber(player:GetAttribute("TreadmillLevel")) or 1
        local gain = tonumber(player:GetAttribute("TreadmillGain")) or Config.BaseTrainingGain
        local cost = tonumber(player:GetAttribute("TreadmillUpgradeCost")) or 0
        modalBody.Text = "NÍVEL ATUAL  " .. tostring(level) .. "/" .. tostring(Config.MaxTreadmillLevel)
            .. "\nGANHO  +" .. tostring(gain) .. " pontos de velocidade por segundo"
            .. "\nPRÓXIMA MELHORIA  " .. (cost > 0 and (formatNumber(cost) .. " moedas") or "NÍVEL MÁXIMO")
            .. "\n\nFique na esteira da sua fazenda para acumular velocidade. A melhoria aumenta o ganho de treino."
        primaryButton.Text = cost > 0 and "COMPRAR MELHORIA" or "NÍVEL MÁXIMO"
        primaryButton.BackgroundColor3 = COLORS.Aqua
        primaryButton.Active = cost > 0
        primaryButton.AutoButtonColor = cost > 0
        secondaryButton.Visible = false
    elseif kind == "Rebirth" then
        modalTitle.Text = "RENASCIMENTO"
        local count = tonumber(player:GetAttribute("Rebirths")) or 0
        local cost = tonumber(player:GetAttribute("RebirthCost")) or 0
        local multiplier = tonumber(player:GetAttribute("RebirthMultiplier")) or 1
        local nextMultiplier = 1 + (count + 1) * (tonumber(Config.RebirthIncomeBonus) or 0.5)
        local coins = tonumber(player:GetAttribute("Coins")) or 0
        local carrying = player:GetAttribute("CarryingAnimal") == true
        if confirmingRebirth then
            modalBody.Text = "CONFIRMAR RENASCIMENTO " .. tostring(count + 1) .. "?\n\nVocê perderá moedas, banco do celeiro, todos os animais, pontos de velocidade e nível da esteira.\n\nO bônus permanente será x" .. string.format("%.1f", nextMultiplier) .. " de renda dos animais. Esta ação não pode ser desfeita."
            primaryButton.Text = "CONFIRMAR E REINICIAR"
            primaryButton.BackgroundColor3 = COLORS.Red
            primaryButton.Active = true
            primaryButton.AutoButtonColor = true
            secondaryButton.Text = "CANCELAR"
            secondaryButton.Visible = true
        else
            modalBody.Text = "RENASCIMENTO ATUAL  " .. tostring(count) .. "\nBÔNUS ATUAL  x" .. string.format("%.1f", multiplier) .. " de renda"
                .. "\nPRÓXIMO BÔNUS  x" .. string.format("%.1f", nextMultiplier)
                .. "\nCUSTO  " .. (cost > 0 and (formatNumber(cost) .. " moedas") or "LIMITE MÁXIMO")
                .. "\n\nAo renascer, você recomeça a fazenda e recebe +50% de renda permanente. O custo aumenta a cada renascimento."
            primaryButton.Text = cost <= 0 and "LIMITE ATINGIDO" or carrying and "ENTREGUE O ANIMAL PRIMEIRO" or coins < cost and ("FALTAM " .. formatNumber(cost - coins) .. " MOEDAS") or "PREPARAR RENASCIMENTO"
            primaryButton.BackgroundColor3 = COLORS.Purple
            secondaryButton.Text = "FECHAR"
            secondaryButton.Visible = false
            primaryButton.Active = cost > 0 and coins >= cost and not carrying
            primaryButton.AutoButtonColor = primaryButton.Active
        end
    elseif kind == "Guide" then
        modalTitle.Text = "COMO JOGAR"
        modalBody.Text = "1. Encontre um filhote no corredor e segure ROUBAR.\n2. Fuja do guardião e leve o animal ao pad verde da sua fazenda.\n3. Colete moedas no pad dourado; animais evoluem e produzem mais.\n4. Treine na esteira e compre melhorias com moedas.\n5. Renascimento reinicia sua fazenda e concede bônus permanente de renda.\n\nSão 8 biomas e " .. tostring(#Catalog.All()) .. " espécies."
        primaryButton.Text = "ENTENDI"
        primaryButton.BackgroundColor3 = COLORS.Mint
        secondaryButton.Visible = false
    end
    if kind ~= "Rebirth" then
        primaryButton.Active = true
        primaryButton.AutoButtonColor = true
        secondaryButton.Text = "FECHAR"
    end
    if secondaryButton.Visible then
        primaryButton.Position = UDim2.new(0, 16, 1, -104)
        primaryButton.Size = UDim2.new(1, -32, 0, 42)
        secondaryButton.Position = UDim2.new(0, 16, 1, -55)
        secondaryButton.Size = UDim2.new(1, -32, 0, 38)
    else
        primaryButton.Position = UDim2.new(0, 16, 1, -58)
        primaryButton.Size = UDim2.new(1, -32, 0, 43)
    end
end

local function refresh()
    local coins = tonumber(player:GetAttribute("Coins")) or 0
    local bank = tonumber(player:GetAttribute("BarnBank")) or 0
    local income = tonumber(player:GetAttribute("BarnIncomeRate")) or 0
    local speed = tonumber(player:GetAttribute("EffectiveWalkSpeed")) or Config.BaseWalkSpeed
    local count = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
    local capacity = tonumber(player:GetAttribute("BarnCapacity")) or Config.BaseSlots
    local rebirths = tonumber(player:GetAttribute("Rebirths")) or 0
    coinsValue.Text = formatNumber(coins)
    incomeValue.Text = formatNumber(income)
    speedValue.Text = string.format("%.1f", speed)
    overview.Text = "CELEIRO " .. tostring(count) .. "/" .. tostring(capacity) .. "  •  BANCO " .. formatNumber(bank)
    rebirthBadgeText.Text = "RENASC. " .. tostring(rebirths)
    if player:GetAttribute("ProfileLoaded") ~= true then
        objectiveText.Text = "CARREGANDO SEU PROGRESSO..."
    elseif player:GetAttribute("CarryingAnimal") == true then
        objectiveText.Text = "FUGA! LEVE O FILHOTE AO PAD VERDE DA SUA FAZENDA"
    else
        objectiveText.Text = "ROUBE UM FILHOTE • LEVE-O À SUA FAZENDA • COLETE MOEDAS"
    end
    if activePanel then
        openPanel(activePanel, confirmingRebirth)
    end
end

barnButton.Activated:Connect(function()
    openPanel("Barn")
end)

collectButton.Activated:Connect(function()
    collectRemote:FireServer()
end)

upgradeButton.Activated:Connect(function()
    openPanel("Treadmill")
end)

rebirthButton.Activated:Connect(function()
    openPanel("Rebirth")
end)

helpButton.Activated:Connect(function()
    openPanel("Guide")
end)

closeButton.Activated:Connect(closeModal)

primaryButton.Activated:Connect(function()
    if activePanel == "Barn" then
        collectRemote:FireServer()
        closeModal()
    elseif activePanel == "Treadmill" then
        if (tonumber(player:GetAttribute("TreadmillUpgradeCost")) or 0) > 0 then
            upgradeRemote:FireServer()
        end
        closeModal()
    elseif activePanel == "Rebirth" then
        if confirmingRebirth then
            rebirthRemote:FireServer()
            closeModal()
        else
            local cost = tonumber(player:GetAttribute("RebirthCost")) or 0
            local coins = tonumber(player:GetAttribute("Coins")) or 0
            if cost > 0 and coins >= cost and player:GetAttribute("CarryingAnimal") ~= true then
                confirmingRebirth = true
                openPanel("Rebirth", true)
            end
        end
    else
        closeModal()
    end
end)

secondaryButton.Activated:Connect(function()
    if activePanel == "Rebirth" and confirmingRebirth then
        confirmingRebirth = false
        openPanel("Rebirth")
    else
        closeModal()
    end
end)

for _, attribute in ipairs({
    "Coins", "BarnBank", "BarnIncomeRate", "BarnAnimalCount", "BarnCapacity",
    "EffectiveWalkSpeed", "TreadmillLevel", "TreadmillGain", "TreadmillUpgradeCost",
    "CarryingAnimal", "ProfileLoaded", "BarnSummary", "Rebirths", "RebirthMultiplier",
    "RebirthCost",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

notifyRemote.OnClientEvent:Connect(showToast)
refresh()
