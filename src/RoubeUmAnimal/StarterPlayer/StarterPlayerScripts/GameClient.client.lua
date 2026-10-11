local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RoubeAnimalRemotes")
local notifyRemote = remotes:WaitForChild("Notify")
local upgradeRemote = remotes:WaitForChild("RequestUpgrade")
local passRequestRemote = remotes:WaitForChild("RequestGamepass")
local passPromptRemote = remotes:WaitForChild("PromptGamepass")

local COLORS = {
    Background = Color3.fromRGB(20, 29, 43),
    Panel = Color3.fromRGB(31, 45, 64),
    PanelLight = Color3.fromRGB(43, 61, 84),
    Blue = Color3.fromRGB(76, 190, 255),
    Green = Color3.fromRGB(81, 225, 147),
    Gold = Color3.fromRGB(255, 203, 88),
    Red = Color3.fromRGB(255, 107, 112),
    Text = Color3.fromRGB(247, 250, 255),
    Muted = Color3.fromRGB(184, 198, 215),
}

local gui = Instance.new("ScreenGui")
gui.Name = "RoubeUmAnimalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 15
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local toastSequence = 0

local function corner(instance, radius)
    local object = Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 12)
    object.Parent = instance
end

local function stroke(instance, color, thickness, transparency)
    local object = Instance.new("UIStroke")
    object.Color = color or COLORS.Blue
    object.Thickness = thickness or 1
    object.Transparency = transparency or 0.25
    object.Parent = instance
end

local function createPanel(name, size, position, anchorPoint)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = anchorPoint or Vector2.zero
    frame.BackgroundColor3 = COLORS.Background
    frame.BackgroundTransparency = 0.06
    frame.BorderSizePixel = 0
    frame.Parent = gui
    corner(frame, 14)
    stroke(frame, COLORS.Blue, 1, 0.45)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.PanelLight),
        ColorSequenceKeypoint.new(1, COLORS.Background),
    })
    gradient.Rotation = 90
    gradient.Parent = frame

    return frame
end

local function label(parent, name, text, size, position, fontSize, color, font)
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = font or Enum.Font.GothamMedium
    object.Text = text
    object.TextColor3 = color or COLORS.Text
    object.TextSize = fontSize or 14
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function button(parent, name, text, position, color, callback, size)
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size or UDim2.new(1, -20, 0, 38)
    object.Position = position
    object.BackgroundColor3 = color or COLORS.PanelLight
    object.BorderSizePixel = 0
    object.AutoButtonColor = true
    object.Font = Enum.Font.GothamBold
    object.Text = text
    object.TextColor3 = COLORS.Text
    object.TextSize = 13
    object.TextWrapped = true
    object.Parent = parent

    corner(object, 9)
    stroke(object, color or COLORS.Blue, 1, 0.45)
    object.Activated:Connect(callback)

    return object
end

local statsPanel = createPanel(
    "StatsPanel",
    UDim2.new(0, 238, 0, 166),
    UDim2.new(0, 12, 0, 12)
)

label(
    statsPanel,
    "Title",
    "ROUBE UM ANIMAL",
    UDim2.new(1, -20, 0, 27),
    UDim2.new(0, 10, 0, 7),
    16,
    COLORS.Blue,
    Enum.Font.GothamBlack
)

local coinsLabel = label(statsPanel, "Coins", "Moedas: ...", UDim2.new(1, -20, 0, 23), UDim2.new(0, 10, 0, 40), 14, COLORS.Gold)
local speedLabel = label(statsPanel, "Speed", "Velocidade: ...", UDim2.new(1, -20, 0, 23), UDim2.new(0, 10, 0, 65), 14)
local strengthLabel = label(statsPanel, "Strength", "Força: ...", UDim2.new(1, -20, 0, 23), UDim2.new(0, 10, 0, 90), 14)
local carryLabel = label(statsPanel, "Carry", "Animal: nenhum", UDim2.new(1, -20, 0, 27), UDim2.new(0, 10, 0, 117), 12, COLORS.Muted)

local shopPanel = createPanel(
    "UpgradePanel",
    UDim2.new(0, 238, 0, 244),
    UDim2.new(0, 12, 1, -12),
    Vector2.new(0, 1)
)

label(
    shopPanel,
    "ShopTitle",
    "TREINO & MELHORIAS",
    UDim2.new(1, -20, 0, 26),
    UDim2.new(0, 10, 0, 7),
    14,
    COLORS.Blue,
    Enum.Font.GothamBlack
)

button(
    shopPanel,
    "BuySpeed",
    "Melhorar Velocidade",
    UDim2.new(0, 10, 0, 39),
    COLORS.PanelLight,
    function()
        upgradeRemote:FireServer("Speed")
    end
)

button(
    shopPanel,
    "BuyStrength",
    "Melhorar Força",
    UDim2.new(0, 10, 0, 83),
    COLORS.PanelLight,
    function()
        upgradeRemote:FireServer("Strength")
    end
)

button(
    shopPanel,
    "DoubleCoins",
    "Moedas em Dobro",
    UDim2.new(0, 10, 0, 127),
    Color3.fromRGB(148, 111, 34),
    function()
        passRequestRemote:FireServer("DoubleCoins")
    end
)

button(
    shopPanel,
    "VIPSpeed",
    "VIP: +50 Velocidade",
    UDim2.new(0, 10, 0, 171),
    Color3.fromRGB(43, 104, 148),
    function()
        passRequestRemote:FireServer("VIPSpeed")
    end
)

label(
    shopPanel,
    "TrainingTip",
    "Esteira: interaja ou corra. Supino: aproxime-se e interaja.",
    UDim2.new(1, -20, 0, 32),
    UDim2.new(0, 10, 0, 210),
    10,
    COLORS.Muted
)

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.Size = UDim2.new(0.8, 0, 0, 54)
toast.Position = UDim2.new(0.5, 0, 0.78, 0)
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.BackgroundColor3 = COLORS.Background
toast.BackgroundTransparency = 0.06
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.Text = ""
toast.TextColor3 = COLORS.Text
toast.TextSize = 15
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 12)
stroke(toast, COLORS.Blue, 1, 0.2)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(230, 54)
sizeConstraint.MaxSize = Vector2.new(470, 54)
sizeConstraint.Parent = toast

local function displayToast(message, messageType)
    toastSequence += 1
    local sequence = toastSequence

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
        if toastSequence == sequence then
            toast.Visible = false
        end
    end)
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

local function updateFromAttributes()
    coinsLabel.Text = "Moedas: " .. formatNumber(player:GetAttribute("Coins"))
    speedLabel.Text = "Velocidade: " .. formatNumber(player:GetAttribute("SpeedLevel"))
    strengthLabel.Text = "Força: " .. formatNumber(player:GetAttribute("Strength"))

    local carrying = player:GetAttribute("CarryingAnimal") == true
    local animalName = player:GetAttribute("CarriedAnimalName")
    local weight = player:GetAttribute("CarriedAnimalWeight")

    if carrying then
        carryLabel.Text = "Carregando: " .. tostring(animalName or "Animal") .. " · peso " .. formatNumber(weight)
        carryLabel.TextColor3 = COLORS.Gold
    else
        carryLabel.Text = "Animal: nenhum"
        carryLabel.TextColor3 = COLORS.Muted
    end

    local doubleCoins = shopPanel:FindFirstChild("DoubleCoins")
    local vipSpeed = shopPanel:FindFirstChild("VIPSpeed")

    if doubleCoins then
        doubleCoins.Text = player:GetAttribute("HasDoubleCoins") and "Moedas em Dobro ativo" or "Moedas em Dobro"
    end

    if vipSpeed then
        vipSpeed.Text = player:GetAttribute("HasVIPSpeed") and "VIP +50 ativo" or "VIP: +50 Velocidade"
    end
end

local function bindLeaderstats()
    local stats = player:FindFirstChild("leaderstats")

    if not stats then
        return
    end

    for _, value in ipairs(stats:GetChildren()) do
        if value:IsA("IntValue") and not value:GetAttribute("HUDBound") then
            value:SetAttribute("HUDBound", true)
            value.Changed:Connect(updateFromAttributes)
        end
    end

    stats.ChildAdded:Connect(function(value)
        if value:IsA("IntValue") and not value:GetAttribute("HUDBound") then
            value:SetAttribute("HUDBound", true)
            value.Changed:Connect(updateFromAttributes)
            updateFromAttributes()
        end
    end)

    updateFromAttributes()
end

for _, attribute in ipairs({
    "Coins",
    "SpeedLevel",
    "Strength",
    "CarryingAnimal",
    "CarriedAnimalName",
    "CarriedAnimalWeight",
    "HasDoubleCoins",
    "HasVIPSpeed",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(updateFromAttributes)
end

player.ChildAdded:Connect(function(child)
    if child.Name == "leaderstats" then
        task.defer(bindLeaderstats)
    end
end)

notifyRemote.OnClientEvent:Connect(function(message, messageType)
    displayToast(message, messageType)
end)

passPromptRemote.OnClientEvent:Connect(function(gamepassId)
    if type(gamepassId) ~= "number" or gamepassId <= 0 then
        displayToast("O gamepass ainda não está configurado.", "Warning")
        return
    end

    local success, err = pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, gamepassId)
    end)

    if not success then
        displayToast("Não foi possível abrir a compra: " .. tostring(err), "Error")
    end
end)

task.defer(bindLeaderstats)
updateFromAttributes()
