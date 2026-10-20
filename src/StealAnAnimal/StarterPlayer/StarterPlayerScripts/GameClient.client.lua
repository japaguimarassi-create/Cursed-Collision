local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("StealAnimalRemotes")
local notifyRemote = remotes:WaitForChild("Notify")
local upgradeRemote = remotes:WaitForChild("RequestUpgrade")
local collectRemote = remotes:WaitForChild("RequestCollect")
local rebirthRemote = remotes:WaitForChild("RequestRebirth")
local dailyRemote = remotes:WaitForChild("RequestDailyReward")
local codeRemote = remotes:WaitForChild("RequestRedeemCode")
local questRemote = remotes:WaitForChild("RequestQuest")
local mapBotRemote = remotes:WaitForChild("RequestMapBot")
local mapBotReportRemote = remotes:WaitForChild("MapBotReport")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("AnimalCatalog"))

local COLORS = {
    Background = Color3.fromRGB(20, 34, 48),
    Panel = Color3.fromRGB(29, 49, 66),
    PanelRaised = Color3.fromRGB(43, 69, 87),
    Card = Color3.fromRGB(35, 61, 79),
    CardEdge = Color3.fromRGB(88, 129, 148),
    Mint = Color3.fromRGB(83, 235, 125),
    Gold = Color3.fromRGB(255, 204, 48),
    Cream = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(190, 208, 218),
    Aqua = Color3.fromRGB(64, 190, 255),
    Orange = Color3.fromRGB(255, 132, 46),
    Red = Color3.fromRGB(255, 67, 77),
    Purple = Color3.fromRGB(177, 112, 255),
}

local old = playerGui:FindFirstChild("StealAnAnimalHUD")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "StealAnAnimalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 40
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Name = "ResponsiveScale"
uiScale.Scale = 1
uiScale.Parent = gui

local touchDevice = UserInputService.TouchEnabled
local compactHud = false
local lowEffects = false
local savedEffectStates = {}
local lastMapBotReport = "Toque em EXECUTAR MAPBOT para verificar as oito fazendas, os biomas, os guardiões e o caminho até o pad."

local function updateScale()
    local camera = workspace.CurrentCamera
    if camera then
        local baseScale = touchDevice and 1 or camera.ViewportSize.X / 1100
        uiScale.Scale = math.clamp(baseScale * (compactHud and 0.9 or 1), 0.82, 1.12)
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

local title = makeLabel(top, "GameTitle", touchDevice and "STEAL ANIMAL" or "STEAL AN ANIMAL", UDim2.new(1, -166, 0, 25), UDim2.new(0, 14, 0, 7), touchDevice and 12 or 16, COLORS.Gold, Enum.Font.GothamBlack)
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
    local button = makeButton(dock, name, text, accent, COLORS.Background)
    button.LayoutOrder = order
    button.Size = UDim2.new(0.2, -6, 1, 0)
    button.TextSize = touchDevice and 10 or 11
    outline(button, accent, 1.2, 0.05)
    return button
end

local barnButton = makeDockButton("OpenBarn", "CELEIRO", 1, COLORS.Mint)
local collectButton = makeDockButton("Collect", "COLETAR", 2, COLORS.Gold)
local upgradeButton = makeDockButton("OpenShop", "LOJA", 3, COLORS.Aqua)
local rebirthButton = makeDockButton("OpenRebirth", "RENASCER", 4, COLORS.Purple)
local moreButton = makeDockButton("OpenMore", "MAIS", 5, COLORS.Gold)

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

local menuList = Instance.new("ScrollingFrame")
menuList.Name = "MenuList"
menuList.Position = UDim2.new(0, 16, 0, 59)
menuList.Size = UDim2.new(1, -32, 0, 158)
menuList.BackgroundTransparency = 1
menuList.BorderSizePixel = 0
menuList.ScrollBarThickness = 4
menuList.ScrollBarImageColor3 = COLORS.Mint
menuList.AutomaticCanvasSize = Enum.AutomaticSize.Y
menuList.CanvasSize = UDim2.new()
menuList.ScrollingDirection = Enum.ScrollingDirection.Y
menuList.Visible = false
menuList.ZIndex = 72
menuList.Parent = modal
local menuPadding = Instance.new("UIPadding")
menuPadding.PaddingRight = UDim.new(0, 4)
menuPadding.PaddingBottom = UDim.new(0, 4)
menuPadding.Parent = menuList
local menuLayout = Instance.new("UIListLayout")
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Padding = UDim.new(0, 6)
menuLayout.Parent = menuList

local codeInput = Instance.new("TextBox")
codeInput.Name = "RedeemCodeInput"
codeInput.Position = UDim2.new(0, 16, 0, 222)
codeInput.Size = UDim2.new(1, -32, 0, 34)
codeInput.BackgroundColor3 = COLORS.Card
codeInput.BorderSizePixel = 0
codeInput.ClearTextOnFocus = false
codeInput.PlaceholderText = "Digite o código"
codeInput.PlaceholderColor3 = COLORS.Muted
codeInput.Text = ""
codeInput.TextColor3 = COLORS.Cream
codeInput.Font = Enum.Font.GothamBold
codeInput.TextSize = 14
codeInput.Visible = false
codeInput.ZIndex = 72
codeInput.Parent = modal
round(codeInput, 10)
outline(codeInput, COLORS.CardEdge, 1)

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

local function clearMenuRows()
    for _, child in ipairs(menuList:GetChildren()) do
        if child ~= menuLayout and child ~= menuPadding then
            child:Destroy()
        end
    end
end

local function addMenuRow(order, name, detail, accent, callback, disabled)
    local item = Instance.new("TextButton")
    item.Name = "Row_" .. tostring(order)
    item.LayoutOrder = order
    item.Size = UDim2.new(1, -2, 0, 47)
    item.BackgroundColor3 = disabled and COLORS.Panel or COLORS.Card
    item.BorderSizePixel = 0
    item.AutoButtonColor = not disabled
    item.Text = ""
    item.Active = not disabled
    item.Selectable = not disabled
    item.ZIndex = 73
    item.Parent = menuList
    round(item, 10)
    outline(item, accent or COLORS.CardEdge, 1, 0.35)
    local heading = makeLabel(item, "Heading", name, UDim2.new(1, -18, 0, 18), UDim2.new(0, 10, 0, 3), 11, disabled and COLORS.Muted or (accent or COLORS.Cream), Enum.Font.GothamBold)
    heading.ZIndex = 74
    heading.Active = false
    local subtitle = makeLabel(item, "Detail", detail or "", UDim2.new(1, -18, 0, 20), UDim2.new(0, 10, 0, 22), 10, COLORS.Muted, Enum.Font.GothamMedium)
    subtitle.ZIndex = 74
    subtitle.Active = false
    if callback and not disabled then
        item.Activated:Connect(callback)
    end
    return item
end

local function showListPanel(kind, panelTitle, rows)
    activePanel = kind
    modalTitle.Text = panelTitle
    modalBody.Visible = false
    menuList.Visible = true
    codeInput.Visible = false
    primaryButton.Visible = false
    primaryButton.Active = false
    secondaryButton.Visible = true
    secondaryButton.Text = kind == "More" and "FECHAR" or "VOLTAR"
    clearMenuRows()
    for index, row in ipairs(rows) do
        addMenuRow(index, row.Title, row.Detail, row.Color, row.Action, row.Disabled)
    end
end

local function decodeQuestClaims()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(tostring(player:GetAttribute("QuestClaimsJson") or "{}"))
    end)
    return ok and type(data) == "table" and data or {}
end

local function applyLowEffects()
    local effectTypes = {
        ParticleEmitter = true,
        Trail = true,
        Beam = true,
        Fire = true,
        Smoke = true,
        Sparkles = true,
    }
    for _, object in ipairs(workspace:GetDescendants()) do
        if effectTypes[object.ClassName] then
            if savedEffectStates[object] == nil then
                savedEffectStates[object] = object.Enabled
            end
            if lowEffects then
                object.Enabled = false
            else
                object.Enabled = savedEffectStates[object]
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(object)
    if not lowEffects then return end
    if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
        or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
        task.defer(function()
            if object.Parent then
                if savedEffectStates[object] == nil then savedEffectStates[object] = object.Enabled end
                object.Enabled = false
            end
        end)
    end
end)

local function openPanel(kind, preserveConfirmation)
    activePanel = kind
    if preserveConfirmation ~= true then
        confirmingRebirth = false
    end
    modalBody.Visible = true
    menuList.Visible = false
    codeInput.Visible = false
    primaryButton.Visible = true
    primaryButton.Active = true
    primaryButton.AutoButtonColor = true
    secondaryButton.Visible = false
    primaryButton.BackgroundColor3 = COLORS.Mint
    secondaryButton.Text = "FECHAR"

    if kind == "More" then
        showListPanel("More", "PROGRESSO E SISTEMA", {
            { Title = "ÍNDICE ANIMAL", Detail = "Espécies, biomas, raridade e renda-base", Color = COLORS.Mint, Action = function() openPanel("AnimalIndex") end },
            { Title = "LOJA DE MELHORIAS", Detail = "Compre níveis de esteira usando moedas do jogo", Color = COLORS.Aqua, Action = function() openPanel("Shop") end },
            { Title = "RECOMPENSA DIÁRIA", Detail = "Bônus diário e sequência de 7 dias", Color = COLORS.Gold, Action = function() openPanel("Daily") end },
            { Title = "MISSÕES", Detail = "Quatro objetivos com recompensas permanentes", Color = COLORS.Mint, Action = function() openPanel("Quests") end },
            { Title = "CÓDIGOS", Detail = "Resgate FARMFAMILY, WILDSTART e BARNBOOST", Color = COLORS.Aqua, Action = function() openPanel("Codes") end },
            { Title = "ESTATÍSTICAS", Detail = "Capturas, depósitos, treino e progresso", Color = COLORS.Purple, Action = function() openPanel("Stats") end },
            { Title = "CONFIGURAÇÕES", Detail = "Reduzir efeitos e compactar a interface", Color = COLORS.Orange, Action = function() openPanel("Settings") end },
            { Title = "MAPBOT / DIAGNÓSTICO", Detail = "Verifica fazendas, biomas, guardiões e caminho", Color = COLORS.Aqua, Action = function() openPanel("Diagnostics") end },
        })
        return
    elseif kind == "AnimalIndex" then
        local rows = {}
        for _, biome in ipairs(Config.Biomes) do
            table.insert(rows, { Title = string.upper(biome.Name), Detail = "BIOMA " .. tostring(biome.Phase), Color = biome.Accent, Disabled = true })
            for _, spec in ipairs(Catalog.ForBiome(biome.Id)) do
                table.insert(rows, { Title = spec.Name .. " • " .. spec.Rarity, Detail = "Renda-base: +" .. formatNumber(spec.Income) .. "/s • Peso: " .. tostring(spec.Weight), Color = spec.Accent, Disabled = true })
            end
        end
        showListPanel("AnimalIndex", "ÍNDICE ANIMAL", rows)
        return
    elseif kind == "Barn" then
        local bank = tonumber(player:GetAttribute("BarnBank")) or 0
        local count = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
        local income = tonumber(player:GetAttribute("BarnIncomeRate")) or 0
        local summary = tostring(player:GetAttribute("BarnSummary") or "")
        local rows = {
            { Title = "BANCO: " .. formatNumber(bank) .. " MOEDAS", Detail = "Renda do celeiro: " .. formatNumber(income) .. " moedas por segundo", Color = COLORS.Gold, Action = function() collectRemote:FireServer() end },
        }
        if summary == "" or string.find(summary, "está vazio", 1, true) then
            table.insert(rows, { Title = "CELEIRO VAZIO", Detail = "Vá ao corredor e roube um filhote.", Color = COLORS.Muted, Disabled = true })
        else
            for line in string.gmatch(summary, "[^\n]+") do
                table.insert(rows, { Title = line, Detail = "Animal guardado • evolução e renda automáticas", Color = COLORS.Mint, Disabled = true })
            end
        end
        table.insert(rows, { Title = "ESPAÇOS", Detail = tostring(count) .. "/" .. tostring(player:GetAttribute("BarnCapacity") or Config.BaseSlots) .. " ocupados", Color = COLORS.Aqua, Disabled = true })
        showListPanel("Barn", "MEU CELEIRO", rows)
        return
    elseif kind == "Daily" then
        local available = player:GetAttribute("DailyClaimAvailable") == true
        local streak = tonumber(player:GetAttribute("DailyStreak")) or 0
        local nextStreak = available and math.min(streak + 1, 7) or streak
        local reward = available and (500 + math.max(0, nextStreak - 1) * 250) or 0
        showListPanel("Daily", "RECOMPENSA DIÁRIA", {
            { Title = available and ("COLETAR +" .. formatNumber(reward) .. " MOEDAS") or "RECOMPENSA JÁ COLETADA", Detail = available and ("Sequência de " .. tostring(nextStreak) .. "/7 dias") or ("Sua sequência atual: " .. tostring(streak) .. "/7 dias"), Color = COLORS.Gold, Disabled = not available, Action = function() dailyRemote:FireServer() end },
            { Title = "BÔNUS DE SEQUÊNCIA", Detail = "500 moedas no dia 1; +250 por dia consecutivo, até 2.000.", Color = COLORS.Mint, Disabled = true },
        })
        return
    elseif kind == "Quests" then
        local claims = decodeQuestClaims()
        local captured = tonumber(player:GetAttribute("TotalCaptured")) or 0
        local deposited = tonumber(player:GetAttribute("TotalDeposited")) or 0
        local animals = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
        local capacity = tonumber(player:GetAttribute("BarnCapacity")) or Config.BaseSlots
        local questRows = {
            { Id = "FirstCapture", Title = "PRIMEIRO ROUBO", Detail = "Capture um animal • +" .. formatNumber(250), Done = captured >= 1 },
            { Id = "FirstBarn", Title = "PRIMEIRO DEPÓSITO", Detail = "Leve um animal ao celeiro • +" .. formatNumber(750), Done = deposited >= 1 },
            { Id = "Collector", Title = "COLECIONADOR", Detail = "Capture 5 animais • +" .. formatNumber(1500), Done = captured >= 5 },
            { Id = "FullBarn", Title = "CELEIRO CHEIO", Detail = "Guarde " .. tostring(capacity) .. " animais • +" .. formatNumber(5000), Done = animals >= capacity },
        }
        local rows = {}
        for _, quest in ipairs(questRows) do
            local claimed = claims[quest.Id] ~= nil
            local status = claimed and "RECOMPENSA RESGATADA" or quest.Done and "OBJETIVO COMPLETO • TOQUE PARA RESGATAR" or "EM ANDAMENTO"
            table.insert(rows, {
                Title = quest.Title .. (claimed and " ✓" or ""),
                Detail = quest.Detail .. " • " .. status,
                Color = claimed and COLORS.Muted or quest.Done and COLORS.Mint or COLORS.Gold,
                Disabled = claimed,
                Action = function() questRemote:FireServer(quest.Id) end,
            })
        end
        showListPanel("Quests", "MISSÕES", rows)
        return
    elseif kind == "Settings" then
        showListPanel("Settings", "CONFIGURAÇÕES", {
            { Title = "EFEITOS REDUZIDOS: " .. (lowEffects and "LIGADO" or "DESLIGADO"), Detail = "Desativa partículas e efeitos visuais locais.", Color = COLORS.Aqua, Action = function() lowEffects = not lowEffects; applyLowEffects(); openPanel("Settings") end },
            { Title = "HUD COMPACTO: " .. (compactHud and "LIGADO" or "DESLIGADO"), Detail = "Reduz toda a interface para liberar espaço na tela.", Color = COLORS.Gold, Action = function() compactHud = not compactHud; updateScale(); openPanel("Settings") end },
            { Title = "DADOS E COMPRAS", Detail = "Não há compras pagas ativadas nesta versão.", Color = COLORS.Muted, Disabled = true },
        })
        return
    elseif kind == "Stats" then
        modalTitle.Text = "ESTATÍSTICAS"
        modalBody.Text = "CAPTURAS  " .. formatNumber(player:GetAttribute("TotalCaptured"))
            .. "\nDEPÓSITOS  " .. formatNumber(player:GetAttribute("TotalDeposited"))
            .. "\nMOEDAS  " .. formatNumber(player:GetAttribute("Coins"))
            .. "\nBANCO DO CELEIRO  " .. formatNumber(player:GetAttribute("BarnBank"))
            .. "\nANIMAIS GUARDADOS  " .. tostring(player:GetAttribute("BarnAnimalCount") or 0) .. "/" .. tostring(player:GetAttribute("BarnCapacity") or Config.BaseSlots)
            .. "\nPONTOS DE VELOCIDADE  " .. formatNumber(player:GetAttribute("SpeedLevel"))
            .. "\nVELOCIDADE ATUAL  " .. string.format("%.1f", tonumber(player:GetAttribute("EffectiveWalkSpeed")) or Config.BaseWalkSpeed)
            .. "\nNÍVEL DA ESTEIRA  " .. tostring(player:GetAttribute("TreadmillLevel") or 1)
            .. "\nRENASCIMENTOS  " .. tostring(player:GetAttribute("Rebirths") or 0)
            .. "\nMULTIPLICADOR DE RENDA  x" .. string.format("%.1f", tonumber(player:GetAttribute("RebirthMultiplier")) or 1)
        primaryButton.Text = "VOLTAR AO MENU"
        return
    elseif kind == "Codes" then
        modalTitle.Text = "CÓDIGOS DE RECOMPENSA"
        modalBody.Text = "Códigos ativos, cada um resgatável uma vez por conta:\nFARMFAMILY  •  +1.000 moedas\nWILDSTART  •  +1.500 moedas\nBARNBOOST  •  +2.500 moedas"
        codeInput.Visible = true
        primaryButton.Text = "RESGATAR CÓDIGO"
        primaryButton.BackgroundColor3 = COLORS.Aqua
        return
    elseif kind == "Diagnostics" then
        modalTitle.Text = "MAPBOT • DIAGNÓSTICO"
        modalBody.Text = lastMapBotReport
        primaryButton.Text = "EXECUTAR MAPBOT"
        primaryButton.BackgroundColor3 = COLORS.Aqua
        return
    elseif kind == "Treadmill" or kind == "Shop" then
        modalTitle.Text = kind == "Shop" and "LOJA DE MELHORIAS" or "ESTEIRA DE VELOCIDADE"
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
    elseif kind == "Rebirth" then
        modalTitle.Text = "RENASCIMENTO"
        local count = tonumber(player:GetAttribute("Rebirths")) or 0
        local cost = tonumber(player:GetAttribute("RebirthCost")) or 0
        local multiplier = tonumber(player:GetAttribute("RebirthMultiplier")) or 1
        local bonus = tonumber(Config.RebirthIncomeBonus) or 0.1
        local nextMultiplier = multiplier + bonus
        local coins = tonumber(player:GetAttribute("Coins")) or 0
        local speed = tonumber(player:GetAttribute("SpeedLevel")) or 0
        local requiredSpeed = tonumber(player:GetAttribute("RebirthRequiredSpeed")) or Config.MaxSpeedPoints
        local carrying = player:GetAttribute("CarryingAnimal") == true
        local eligible = cost > 0 and coins >= cost and speed >= requiredSpeed and not carrying
        if confirmingRebirth then
            modalBody.Text = "CONFIRMAR RENASCIMENTO " .. tostring(count + 1) .. "?\n\nVocê reiniciará suas moedas e pontos de velocidade. Animais guardados, banco do celeiro e nível da esteira serão preservados.\n\nBônus permanente: +10% de renda por renascimento, acumulável até 25 vezes."
            primaryButton.Text = "CONFIRMAR RENASCIMENTO"
            primaryButton.BackgroundColor3 = COLORS.Red
            primaryButton.Active = true
            primaryButton.AutoButtonColor = true
            secondaryButton.Text = "CANCELAR"
            secondaryButton.Visible = true
        else
            modalBody.Text = "RENASCIMENTOS  " .. tostring(count) .. "/" .. tostring(Config.MaxRebirths)
                .. "\nBÔNUS ATUAL  x" .. string.format("%.1f", multiplier)
                .. "\nPRÓXIMO BÔNUS  x" .. string.format("%.1f", nextMultiplier)
                .. "\nREQUISITOS: " .. formatNumber(cost) .. " moedas e " .. formatNumber(requiredSpeed) .. " pontos de velocidade."
                .. "\nSEU PROGRESSO: " .. formatNumber(coins) .. "/" .. formatNumber(cost) .. " moedas; " .. formatNumber(speed) .. "/" .. formatNumber(requiredSpeed) .. " velocidade."
                .. "\n\nRenascer reinicia moedas e velocidade, mantendo os animais do celeiro, o banco e a esteira. Cada renascimento dá +10% de renda permanente."
            primaryButton.Text = cost <= 0 and "LIMITE ATINGIDO" or carrying and "ENTREGUE O ANIMAL PRIMEIRO" or not eligible and "CUMPRA OS REQUISITOS" or "PREPARAR RENASCIMENTO"
            primaryButton.BackgroundColor3 = COLORS.Purple
            primaryButton.Active = eligible
            primaryButton.AutoButtonColor = eligible
            secondaryButton.Text = "FECHAR"
            secondaryButton.Visible = false
        end
    elseif kind == "Guide" then
        modalTitle.Text = "COMO JOGAR"
        modalBody.Text = "1. Encontre um filhote no corredor e segure ROUBAR.\n2. Fuja do guardião e leve o animal ao pad verde da sua fazenda.\n3. Colete moedas no pad dourado; animais evoluem e produzem mais.\n4. Treine na esteira e compre melhorias com moedas.\n5. Resgate recompensas diárias, missões e códigos no menu MAIS.\n6. Renascimento exige velocidade máxima e 100.000 moedas; concede +10% de renda permanente e preserva seus animais.\n\nSão 8 biomas e " .. tostring(#Catalog.All()) .. " espécies."
        primaryButton.Text = "ENTENDI"
        primaryButton.BackgroundColor3 = COLORS.Mint
    end

    if kind ~= "Rebirth" then
        primaryButton.Active = true
        primaryButton.AutoButtonColor = true
        secondaryButton.Text = "FECHAR"
    end
    primaryButton.Visible = true
    if codeInput.Visible then
        primaryButton.Position = UDim2.new(0, 16, 1, -58)
        primaryButton.Size = UDim2.new(1, -32, 0, 43)
    elseif secondaryButton.Visible then
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
    elseif tonumber(player:GetAttribute("TotalCaptured")) == 0 then
        objectiveText.Text = "PRIMEIRO OBJETIVO: ROUBE UM FILHOTE NO CORREDOR"
    else
        objectiveText.Text = "ROUBE UM FILHOTE • LEVE-O À SUA FAZENDA • COLETE MOEDAS"
    end
    if activePanel then
        openPanel(activePanel, confirmingRebirth)
    end
end

barnButton.Activated:Connect(function() openPanel("Barn") end)
collectButton.Activated:Connect(function() collectRemote:FireServer() end)
upgradeButton.Activated:Connect(function() openPanel("Shop") end)
rebirthButton.Activated:Connect(function() openPanel("Rebirth") end)
moreButton.Activated:Connect(function() openPanel("More") end)
helpButton.Activated:Connect(function() openPanel("Guide") end)
closeButton.Activated:Connect(closeModal)

primaryButton.Activated:Connect(function()
    if activePanel == "Barn" then
        collectRemote:FireServer()
        closeModal()
    elseif activePanel == "Treadmill" or activePanel == "Shop" then
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
            local speed = tonumber(player:GetAttribute("SpeedLevel")) or 0
            local requiredSpeed = tonumber(player:GetAttribute("RebirthRequiredSpeed")) or Config.MaxSpeedPoints
            local coins = tonumber(player:GetAttribute("Coins")) or 0
            if cost > 0 and coins >= cost and speed >= requiredSpeed and player:GetAttribute("CarryingAnimal") ~= true then
                confirmingRebirth = true
                openPanel("Rebirth", true)
            end
        end
    elseif activePanel == "Codes" then
        if #string.gsub(codeInput.Text, "%s+", "") > 0 then
            codeRemote:FireServer(codeInput.Text)
            codeInput.Text = ""
        else
            showToast("Digite um dos códigos ativos.", "Warning")
        end
    elseif activePanel == "Diagnostics" then
        modalBody.Text = "Executando MapBot: conferindo cenário e calculando rota..."
        mapBotRemote:FireServer()
    else
        closeModal()
    end
end)

secondaryButton.Activated:Connect(function()
    if activePanel == "Rebirth" and confirmingRebirth then
        confirmingRebirth = false
        openPanel("Rebirth")
    elseif activePanel and activePanel ~= "More" then
        openPanel("More")
    else
        closeModal()
    end
end)

mapBotReportRemote.OnClientEvent:Connect(function(report, kind)
    lastMapBotReport = tostring(report)
    if activePanel == "Diagnostics" then
        openPanel("Diagnostics")
    end
    showToast(kind == "Success" and "MapBot concluiu a verificação." or "MapBot concluiu a verificação com alertas.", kind or "Info")
end)

for _, attribute in ipairs({
    "Coins", "BarnBank", "BarnIncomeRate", "BarnAnimalCount", "BarnCapacity",
    "EffectiveWalkSpeed", "TreadmillLevel", "TreadmillGain", "TreadmillUpgradeCost",
    "CarryingAnimal", "ProfileLoaded", "BarnSummary", "Rebirths", "RebirthMultiplier",
    "RebirthCost", "RebirthRequiredCoins", "RebirthRequiredSpeed",
    "DailyStreak", "DailyClaimAvailable", "TotalCaptured", "TotalDeposited", "QuestClaimsJson",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

notifyRemote.OnClientEvent:Connect(showToast)
refresh()
