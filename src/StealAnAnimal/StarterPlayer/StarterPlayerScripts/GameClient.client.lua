local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("StealAnimalRemotes")
local notifyRemote = remotes:WaitForChild("Notify")
local upgradeRemote = remotes:WaitForChild("RequestUpgrade")
local collectRemote = remotes:WaitForChild("RequestCollect")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("AnimalCatalog"))

local COLORS = {
    Background = Color3.fromRGB(25, 39, 37),
    Panel = Color3.fromRGB(39, 61, 54),
    PanelLight = Color3.fromRGB(61, 91, 69),
    Green = Color3.fromRGB(126, 211, 99),
    Gold = Color3.fromRGB(255, 205, 79),
    Cream = Color3.fromRGB(255, 248, 226),
    Aqua = Color3.fromRGB(111, 221, 219),
    Orange = Color3.fromRGB(255, 143, 75),
    Red = Color3.fromRGB(236, 93, 86),
    Purple = Color3.fromRGB(187, 145, 255),
}

local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("StealAnAnimalHUD")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "StealAnAnimalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(object, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius or 14)
    item.Parent = object
end

local function stroke(object, color, thickness)
    local item = Instance.new("UIStroke")
    item.Color = color
    item.Thickness = thickness or 1.5
    item.Transparency = 0.18
    item.Parent = object
end

local function textLabel(parent, name, text, size, position, fontSize, color, font)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.Font = font or Enum.Font.GothamBold
    item.Text = text
    item.TextColor3 = color or COLORS.Cream
    item.TextSize = fontSize or 14
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Parent = parent
    return item
end

local function makeButton(parent, name, title, color, order, callback)
    local item = Instance.new("TextButton")
    item.Name = name
    item.LayoutOrder = order
    item.Size = UDim2.new(1, 0, 0, 43)
    item.BackgroundColor3 = color
    item.BorderSizePixel = 0
    item.AutoButtonColor = true
    item.Font = Enum.Font.GothamBlack
    item.Text = title
    item.TextColor3 = COLORS.Background
    item.TextSize = 13
    item.TextWrapped = true
    item.Parent = parent
    corner(item, 11)
    item.Activated:Connect(callback)
    return item
end

local function number(value)
    value = math.floor(tonumber(value) or 0)
    if value >= 1000000000 then return string.format("%.1fB", value / 1000000000) end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 10000 then return string.format("%.1fK", value / 1000) end
    return tostring(value)
end

local compact = UserInputService.TouchEnabled
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.new(0, 12, 0, 12)
panel.Size = compact and UDim2.new(0, 250, 0, 142) or UDim2.new(0, 305, 0, 154)
panel.BackgroundColor3 = COLORS.Background
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 17)
stroke(panel, COLORS.Green, 2)

local title = textLabel(panel, "Title", "STEAL AN ANIMAL", UDim2.new(1, -22, 0, 27), UDim2.new(0, 12, 0, 6), 17, COLORS.Gold, Enum.Font.GothamBlack)
local stats = textLabel(panel, "Stats", "Moedas  0     Renda  0/s", UDim2.new(1, -22, 0, 25), UDim2.new(0, 12, 0, 34), 13, COLORS.Cream)
local barn = textLabel(panel, "Barn", "Celeiro  0/6     Velocidade  0", UDim2.new(1, -22, 0, 24), UDim2.new(0, 12, 0, 59), 12, COLORS.Aqua)
local carry = textLabel(panel, "Carry", "Mãos livres • Roube um bebê", UDim2.new(1, -22, 0, 25), UDim2.new(0, 12, 0, 84), 12, COLORS.Cream)
local stageHint = textLabel(panel, "EvolutionHint", "Bebê → Criança → Adolescente → Adulto", UDim2.new(1, -22, 0, 23), UDim2.new(0, 12, 0, 110), 10, COLORS.Gold)

local actions = Instance.new("Frame")
actions.Name = "ActionPanel"
actions.AnchorPoint = Vector2.new(1, 1)
actions.Position = UDim2.new(1, -12, 1, -12)
actions.Size = compact and UDim2.new(0, 164, 0, 204) or UDim2.new(0, 205, 0, 204)
actions.BackgroundColor3 = COLORS.Background
actions.BackgroundTransparency = 0.06
actions.BorderSizePixel = 0
actions.Parent = gui
corner(actions, 16)
stroke(actions, COLORS.Gold, 1.5)

local actionPadding = Instance.new("UIPadding")
actionPadding.PaddingTop = UDim.new(0, 9)
actionPadding.PaddingBottom = UDim.new(0, 9)
actionPadding.PaddingLeft = UDim.new(0, 9)
actionPadding.PaddingRight = UDim.new(0, 9)
actionPadding.Parent = actions

local actionLayout = Instance.new("UIListLayout")
actionLayout.Padding = UDim.new(0, 6)
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Parent = actions

makeButton(actions, "Collect", "COLETAR MOEDAS", COLORS.Gold, 1, function()
    collectRemote:FireServer()
end)
makeButton(actions, "Upgrade", "MELHORAR VELOCIDADE", COLORS.Green, 2, function()
    upgradeRemote:FireServer()
end)
makeButton(actions, "OpenBarn", "MEU CELEIRO", COLORS.Aqua, 3, function()
    local amount = tonumber(player:GetAttribute("BarnBank")) or 0
    local count = tonumber(player:GetAttribute("BarnAnimalCount")) or 0
    local income = tonumber(player:GetAttribute("BarnIncomeRate")) or 0
    showToast("Celeiro: " .. tostring(count) .. "/" .. tostring(Config.BaseSlots) .. " animais • " .. number(income) .. " moedas/s • Banco: " .. number(amount), "Info")
end)
makeButton(actions, "AnimalGuide", "GUIA DE ANIMAIS", COLORS.Purple, 4, function()
    local counts = {}
    for _, spec in ipairs(Catalog.All()) do
        counts[spec.Biome] = (counts[spec.Biome] or 0) + 1
    end
    showToast("21 espécies em 6 biomas. Os animais começam bebês e evoluem com o tempo.", "Info")
end)

local toastFrame = Instance.new("Frame")
toastFrame.Name = "Toast"
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Position = UDim2.new(0.5, 0, 0, 18)
toastFrame.Size = UDim2.new(0.82, 0, 0, 62)
toastFrame.BackgroundColor3 = COLORS.Panel
toastFrame.BackgroundTransparency = 0.04
toastFrame.BorderSizePixel = 0
toastFrame.Visible = false
toastFrame.ZIndex = 30
toastFrame.Parent = gui
corner(toastFrame, 15)
stroke(toastFrame, COLORS.Gold, 1.5)

local toastText = textLabel(toastFrame, "Message", "", UDim2.new(1, -22, 1, -12), UDim2.new(0, 11, 0, 6), 14, COLORS.Cream)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toastText.ZIndex = 31
local toastToken = 0

function showToast(message, kind)
    toastToken += 1
    local token = toastToken
    toastText.Text = tostring(message)
    toastText.TextColor3 = kind == "Error" and COLORS.Red or kind == "Warning" and COLORS.Orange or kind == "Success" and COLORS.Green or COLORS.Cream
    toastFrame.Visible = true
    toastFrame.BackgroundTransparency = 0.04
    toastFrame.Position = UDim2.new(0.5, 0, 0, 18)
    TweenService:Create(toastFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 28),
    }):Play()
    task.delay(3.2, function()
        if token == toastToken then
            toastFrame.Visible = false
        end
    end)
end

local function refresh()
    stats.Text = "Moedas  " .. number(player:GetAttribute("Coins")) .. "     Renda  " .. number(player:GetAttribute("BarnIncomeRate")) .. "/s"
    barn.Text = "Celeiro  " .. tostring(player:GetAttribute("BarnAnimalCount") or 0) .. "/" .. tostring(player:GetAttribute("BarnCapacity") or Config.BaseSlots)
        .. "     Velocidade  " .. tostring(player:GetAttribute("SpeedLevel") or 0)
    carry.Text = player:GetAttribute("CarryingAnimal") and "Carregando um animal • FUJA DO GUARDIÃO" or "Mãos livres • Roube um bebê"
end

for _, attribute in ipairs({ "Coins", "BarnIncomeRate", "BarnAnimalCount", "BarnCapacity", "SpeedLevel", "CarryingAnimal", "BarnBank" }) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
notifyRemote.OnClientEvent:Connect(showToast)
refresh()
