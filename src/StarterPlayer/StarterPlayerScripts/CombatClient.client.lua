local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatAction = remotes:WaitForChild("CombatAction")
local serverEvent = remotes:WaitForChild("ServerEvent")
local combatFX = remotes:WaitForChild("CombatFX")
local clashEvent = remotes:WaitForChild("ClashEvent")
local selection = remotes:WaitForChild("Selection")
local definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local moves = require(ReplicatedStorage.Characters.CharacterMoves)
local Config = require(ReplicatedStorage.Shared.Config)
local CombatVFX = require(ReplicatedStorage.Combat.CombatVFX)
local CombatAnimationService = require(ReplicatedStorage.Combat.CombatAnimationService)

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local accent = Color3.fromRGB(142, 101, 235)
local accentBright = Color3.fromRGB(205, 181, 255)
local red = Color3.fromRGB(219, 70, 85)
local gold = Color3.fromRGB(245, 190, 76)
local blue = Color3.fromRGB(91, 171, 255)
local panel = Color3.fromRGB(11, 13, 18)
local tile = Color3.fromRGB(24, 27, 35)
local tileHover = Color3.fromRGB(35, 38, 48)
local text = Color3.fromRGB(238, 239, 245)
local muted = Color3.fromRGB(151, 154, 170)

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.3
    s.Parent = parent
    return s
end

local function label(parent, textValue, size, position, font, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = textValue or ""
    l.Size = size
    l.Position = position
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 14
    l.TextColor3 = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function button(parent, name, textValue, size, position, strokeColor)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = textValue or ""
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = tile
    b.BackgroundTransparency = 0.04
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = text
    b.AutoButtonColor = false
    b.Selectable = true
    b.Parent = parent
    corner(b, 10)
    stroke(b, strokeColor or Color3.fromRGB(73, 77, 93), 1, 0.2)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = tileHover}):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = tile}):Play()
    end)

    return b
end

local function fireAction(action, duration)
    local now = os.clock()
    local untilValue = tonumber(gui:GetAttribute("Cooldown_" .. action)) or 0
    if untilValue > now then
        return false
    end

    if duration and duration > 0 then
        gui:SetAttribute("Cooldown_" .. action, now + duration)
    end

    combatAction:FireServer(action)
    return true
end

local function healthPercent()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.MaxHealth <= 0 then
        return 0
    end
    return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
end

local function cooldownFor(action)
    if action == "M1" then
        return Config.Combat.M1.Cooldown
    elseif action == "Heavy" then
        return Config.Combat.Heavy.Cooldown
    elseif action == "Dash" then
        return Config.Combat.Dash.Cooldown
    elseif action == "Dodge" then
        return Config.Combat.Dodge.Cooldown
    elseif action == "Grab" then
        return Config.Combat.Grab.Cooldown
    elseif action == "Domain" then
        return Config.Domain.Cooldown
    end

    local id = player:GetAttribute("CharacterId") or "Yuji"
    local definition = definitions[id]
    if action == "Special" then
        return definition and definition.SpecialCooldown or 0.6
    elseif action == "Skill" then
        return definition and definition.SkillCooldown or 0.6
    end

    return 0
end

local fighterCard = Instance.new("Frame")
fighterCard.Name = "FighterCard"
fighterCard.Size = UDim2.fromScale(0.28, 0.105)
fighterCard.Position = UDim2.fromScale(0.018, 0.018)
fighterCard.BackgroundColor3 = panel
fighterCard.BackgroundTransparency = 0.08
fighterCard.BorderSizePixel = 0
fighterCard.Parent = gui
corner(fighterCard, 12)
stroke(fighterCard, Color3.fromRGB(72, 76, 92), 1, 0.3)

local title = label(fighterCard, "CURSED COLLISION", UDim2.fromScale(0.72, 0.2), UDim2.fromScale(0.05, 0.06), Enum.Font.GothamBlack, 11)
title.TextColor3 = muted
local characterLabel = label(fighterCard, "Yuji Itadori", UDim2.fromScale(0.82, 0.28), UDim2.fromScale(0.05, 0.24), Enum.Font.GothamBold, 16)
local uniqueLabel = label(fighterCard, "", UDim2.fromScale(0.82, 0.22), UDim2.fromScale(0.05, 0.49), Enum.Font.Gotham, 10)
uniqueLabel.TextColor3 = muted

local rosterButton = button(gui, "RosterButton", "≡", UDim2.fromScale(0.045, 0.055), UDim2.fromScale(0.305, 0.03), accent)
rosterButton.TextSize = 20
rosterButton.BackgroundColor3 = panel

local healthCard = Instance.new("Frame")
healthCard.Name = "HealthCard"
healthCard.Size = UDim2.fromScale(0.205, 0.105)
healthCard.Position = UDim2.fromScale(0.67, 0.018)
healthCard.BackgroundColor3 = panel
healthCard.BackgroundTransparency = 0.08
healthCard.BorderSizePixel = 0
healthCard.Parent = gui
corner(healthCard, 12)
stroke(healthCard, Color3.fromRGB(72, 76, 92), 1, 0.3)

local healthText = label(healthCard, "100% HP", UDim2.fromScale(0.88, 0.27), UDim2.fromScale(0.06, 0.08), Enum.Font.GothamBlack, 14)
healthText.TextXAlignment = Enum.TextXAlignment.Right

local healthBack = Instance.new("Frame")
healthBack.Size = UDim2.fromScale(0.88, 0.18)
healthBack.Position = UDim2.fromScale(0.06, 0.46)
healthBack.BackgroundColor3 = Color3.fromRGB(54, 29, 35)
healthBack.BorderSizePixel = 0
healthBack.Parent = healthCard
corner(healthBack, 5)

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = red
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
corner(healthFill, 5)

local awakeningBack = Instance.new("Frame")
awakeningBack.Name = "AwakeningBar"
awakeningBack.Size = UDim2.fromScale(0.88, 0.12)
awakeningBack.Position = UDim2.fromScale(0.06, 0.73)
awakeningBack.BackgroundColor3 = Color3.fromRGB(42, 32, 61)
awakeningBack.BorderSizePixel = 0
awakeningBack.Parent = healthCard
corner(awakeningBack, 4)

local awakeningFill = Instance.new("Frame")
awakeningFill.Size = UDim2.fromScale(0, 1)
awakeningFill.BackgroundColor3 = accent
awakeningFill.BorderSizePixel = 0
awakeningFill.Parent = awakeningBack
corner(awakeningFill, 4)

local awakeningText = label(healthCard, "0%", UDim2.fromScale(0.28, 0.2), UDim2.fromScale(0.06, 0.82), Enum.Font.GothamBold, 9)
awakeningText.TextColor3 = accentBright

local stateLabel = label(gui, "READY", UDim2.fromScale(0.30, 0.04), UDim2.fromScale(0.35, 0.025), Enum.Font.GothamBlack, 11)
stateLabel.TextXAlignment = Enum.TextXAlignment.Center
stateLabel.TextColor3 = Color3.fromRGB(225, 226, 236)

local techniqueFrame = Instance.new("Frame")
techniqueFrame.Name = "TechniqueBar"
techniqueFrame.Size = UDim2.fromScale(0.47, 0.13)
techniqueFrame.Position = UDim2.fromScale(0.265, 0.835)
techniqueFrame.BackgroundTransparency = 1
techniqueFrame.Parent = gui

local techniqueLayout = Instance.new("UIGridLayout")
techniqueLayout.CellSize = UDim2.new(0.238, 0, 0.92, 0)
techniqueLayout.CellPadding = UDim2.new(0.016, 0, 0, 0)
techniqueLayout.FillDirectionMaxCells = 4
techniqueLayout.SortOrder = Enum.SortOrder.LayoutOrder
techniqueLayout.Parent = techniqueFrame

local function techniqueButton(name, keyText, action, order)
    local b = button(techniqueFrame, name, "", UDim2.new(), UDim2.new(), accent)
    b.LayoutOrder = order

    local key = label(b, keyText, UDim2.fromScale(0.26, 0.26), UDim2.fromScale(0.06, 0.07), Enum.Font.GothamBlack, 10)
    key.TextColor3 = accentBright

    local move = label(b, name, UDim2.fromScale(0.82, 0.34), UDim2.fromScale(0.09, 0.30), Enum.Font.GothamBold, 12)
    move.TextXAlignment = Enum.TextXAlignment.Center

    local hint = label(b, "READY", UDim2.fromScale(0.82, 0.22), UDim2.fromScale(0.09, 0.68), Enum.Font.Gotham, 8)
    hint.TextXAlignment = Enum.TextXAlignment.Center
    hint.TextColor3 = muted

    b.Activated:Connect(function()
        if action == "Awaken" then
            fireAction(action)
        elseif action == "Domain" then
            fireAction(action, cooldownFor(action))
        else
            fireAction(action, cooldownFor(action))
        end
    end)

    return b, hint, move, key
end

local _specialButton, specialHint, specialMove, specialKey = techniqueButton("SPECIAL", "1", "Special", 1)
local _skillButton, skillHint, skillMove, skillKey = techniqueButton("SKILL", "2", "Skill", 2)
local _awakenButton, awakenHint, awakenMove, awakenKey = techniqueButton("AWAKEN", "3", "Awaken", 3)
local domainButton, domainHint, domainMove, domainKey = techniqueButton("DOMAIN", "4", "Domain", 4)

local oneTime = button(gui, "OneTime", "OT  READY", UDim2.fromScale(0.105, 0.055), UDim2.fromScale(0.155, 0.866), Color3.fromRGB(244, 96, 140))
oneTime.TextSize = 11
oneTime.Activated:Connect(function()
    fireAction("OneTime")
end)

local actionFrame = Instance.new("Frame")
actionFrame.Name = "CombatActions"
actionFrame.Size = UDim2.fromScale(0.245, 0.34)
actionFrame.Position = UDim2.fromScale(0.745, 0.59)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = gui

local m1 = button(actionFrame, "M1", "M1", UDim2.fromScale(0.44, 0.50), UDim2.fromScale(0.28, 0.39), red)
m1.TextSize = 22
stroke(m1, red, 1.6, 0.06)
m1.Activated:Connect(function()
    fireAction("M1", cooldownFor("M1"))
end)

local function smallAction(name, textValue, action, position, strokeColor)
    local b = button(actionFrame, name, textValue, UDim2.fromScale(0.27, 0.18), position, strokeColor)
    b.TextSize = 9
    b.Activated:Connect(function()
        fireAction(action, cooldownFor(action))
    end)
    return b
end

local _heavy = smallAction("Heavy", "HEAVY", "Heavy", UDim2.fromScale(0.02, 0.19), Color3.fromRGB(175, 177, 193))
local _grab = smallAction("Grab", "GRAB", "Grab", UDim2.fromScale(0.71, 0.19), Color3.fromRGB(175, 177, 193))
local _dash = smallAction("Dash", "DASH", "Dash", UDim2.fromScale(0.02, 0.70), accent)
local _dodge = smallAction("Dodge", "DODGE", "Dodge", UDim2.fromScale(0.71, 0.70), gold)
local blockButton = button(actionFrame, "Block", "BLOCK", UDim2.fromScale(0.27, 0.18), UDim2.fromScale(0.36, 0.00), blue)
blockButton.TextSize = 9

local mobileBlock = false
blockButton.Activated:Connect(function()
    mobileBlock = not mobileBlock
    blockButton.Text = mobileBlock and "BLOCKING" or "BLOCK"
    combatAction:FireServer(mobileBlock and "BlockStart" or "BlockEnd")
end)

local rosterOverlay = Instance.new("Frame")
rosterOverlay.Name = "RosterOverlay"
rosterOverlay.Size = UDim2.fromScale(0.78, 0.78)
rosterOverlay.Position = UDim2.fromScale(0.5, 0.52)
rosterOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
rosterOverlay.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
rosterOverlay.BackgroundTransparency = 0.04
rosterOverlay.BorderSizePixel = 0
rosterOverlay.Visible = false
rosterOverlay.ZIndex = 20
rosterOverlay.Parent = gui
corner(rosterOverlay, 16)
stroke(rosterOverlay, accent, 1.3, 0.28)

local rosterTitle = label(rosterOverlay, "CHOOSE FIGHTER", UDim2.fromScale(0.70, 0.08), UDim2.fromScale(0.035, 0.03), Enum.Font.GothamBlack, 20)
rosterTitle.ZIndex = 21
local rosterSub = label(rosterOverlay, "24 KITS  •  TAP TO SELECT", UDim2.fromScale(0.70, 0.05), UDim2.fromScale(0.037, 0.11), Enum.Font.Gotham, 10)
rosterSub.TextColor3 = muted
rosterSub.ZIndex = 21

local closeRoster = button(rosterOverlay, "Close", "×", UDim2.fromScale(0.065, 0.075), UDim2.fromScale(0.91, 0.025), red)
closeRoster.TextSize = 22
closeRoster.ZIndex = 21

local selectFrame = Instance.new("ScrollingFrame")
selectFrame.Name = "CharacterGrid"
selectFrame.Size = UDim2.fromScale(0.93, 0.80)
selectFrame.Position = UDim2.fromScale(0.035, 0.18)
selectFrame.BackgroundTransparency = 1
selectFrame.BorderSizePixel = 0
selectFrame.ScrollBarThickness = 4
selectFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
selectFrame.CanvasSize = UDim2.fromOffset(0, 0)
selectFrame.ZIndex = 21
selectFrame.Parent = rosterOverlay

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.238, 0, 0, 68)
grid.CellPadding = UDim2.new(0.012, 0, 0, 9)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.FillDirectionMaxCells = 4
grid.Parent = selectFrame

local ids = {}
for id in pairs(definitions) do
    table.insert(ids, id)
end
table.sort(ids)

for index, id in ipairs(ids) do
    local definition = definitions[id]
    local b = button(selectFrame, id, definition.Name, UDim2.new(), UDim2.new(), Color3.fromRGB(81, 84, 101))
    b.LayoutOrder = index
    b.TextSize = 12
    b.TextWrapped = true
    b.ZIndex = 22

    local sub = label(b, definition.Unique or "", UDim2.fromScale(0.90, 0.22), UDim2.fromScale(0.05, 0.70), Enum.Font.Gotham, 8)
    sub.TextColor3 = muted
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.ZIndex = 23

    b.Activated:Connect(function()
        selection:FireServer(id)
        rosterOverlay.Visible = false
    end)
end

rosterButton.Activated:Connect(function()
    rosterOverlay.Visible = not rosterOverlay.Visible
end)

closeRoster.Activated:Connect(function()
    rosterOverlay.Visible = false
end)

local clashFrame = Instance.new("Frame")
clashFrame.Name = "DomainClash"
clashFrame.Size = UDim2.fromScale(0.58, 0.26)
clashFrame.Position = UDim2.fromScale(0.50, 0.50)
clashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
clashFrame.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
clashFrame.BackgroundTransparency = 0.05
clashFrame.BorderSizePixel = 0
clashFrame.Visible = false
clashFrame.ZIndex = 30
clashFrame.Parent = gui
corner(clashFrame, 16)
stroke(clashFrame, gold, 1.6, 0.1)

local clashTitle = label(clashFrame, "DOMAIN CLASH", UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.06), Enum.Font.GothamBlack, 22)
clashTitle.TextXAlignment = Enum.TextXAlignment.Center
clashTitle.ZIndex = 31

local clashHint = label(clashFrame, "CHOOSE A RESPONSE", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0.29), Enum.Font.Gotham, 10)
clashHint.TextXAlignment = Enum.TextXAlignment.Center
clashHint.TextColor3 = muted
clashHint.ZIndex = 31

local clashButtons = {}
for i, moveName in ipairs({"CRUSH", "COUNTER", "FEINT", "BREAK"}) do
    local b = button(clashFrame, "Clash" .. i, tostring(i) .. "  " .. moveName, UDim2.fromScale(0.21, 0.42), UDim2.fromScale(0.025 + (i - 1) * 0.245, 0.46), accent)
    b.TextSize = 10
    b.ZIndex = 31
    clashButtons[i] = b
    b.Activated:Connect(function()
        combatAction:FireServer("ClashMove", i)
    end)
end

local stateAttributeNames = {
    "Momentum", "Infinity", "LimitlessState", "SlashState", "Shikigami", "RikaActive", "CopySlot", "WeaponMode",
    "SoulIntegrity", "SwapReady", "Jackpot", "JackpotRoll", "Blood", "ElectricalCharge", "FrameSequence",
    "TechniqueStock", "Heat", "Tide", "Roots", "Evidence", "Confiscated", "ComedyContext", "Frost",
    "Construction", "OutputCharge", "SkyDistortion", "SimpleDomain", "PerfectComboStep", "OneTimeAttackReady"
}

local function uniqueText()
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local key = player:GetAttribute("UniqueState") or ""
    local values = {
        Yuji = "Momentum " .. tostring(player:GetAttribute("Momentum") or 0),
        Gojo = (player:GetAttribute("Infinity") and "Infinity ON" or "Infinity OFF") .. " • " .. tostring(player:GetAttribute("LimitlessState") or "Neutral"),
        Sukuna = "State " .. tostring(player:GetAttribute("SlashState") or "Dismantle"),
        Megumi = tostring(player:GetAttribute("Shikigami") or "Divine Dogs"),
        Yuta = "Rika " .. (player:GetAttribute("RikaActive") and "ON" or "OFF") .. " • Copy " .. tostring(player:GetAttribute("CopySlot") or 1),
        Maki = tostring(player:GetAttribute("WeaponMode") or "Katana"),
        Toji = tostring(player:GetAttribute("WeaponMode") or "Katana"),
        Mahito = "Soul " .. tostring(math.floor(player:GetAttribute("SoulIntegrity") or 100)),
        Todo = "Swap " .. (player:GetAttribute("SwapReady") and "READY" or "USED"),
        Hakari = player:GetAttribute("Jackpot") and "JACKPOT" or ("Roll " .. tostring(player:GetAttribute("JackpotRoll") or 0)),
        Choso = "Blood " .. tostring(math.floor(player:GetAttribute("Blood") or 100)),
        Kashimo = "Charge " .. tostring(math.floor(player:GetAttribute("ElectricalCharge") or 0)),
        Naoya = "Frames " .. tostring(player:GetAttribute("FrameSequence") or 0) .. "/24",
        Kenjaku = "Stock " .. tostring(player:GetAttribute("TechniqueStock") or 0),
        Jogo = "Heat " .. tostring(math.floor(player:GetAttribute("Heat") or 0)),
        Dagon = "Tide " .. tostring(math.floor(player:GetAttribute("Tide") or 0)),
        Hanami = "Roots " .. tostring(math.floor(player:GetAttribute("Roots") or 0)),
        Higuruma = "Evidence " .. tostring(math.floor(player:GetAttribute("Evidence") or 0)),
        Takaba = "Context " .. tostring(math.floor(player:GetAttribute("ComedyContext") or 0)),
        Uraume = "Frost " .. tostring(math.floor(player:GetAttribute("Frost") or 0)),
        Yorozu = "Construction " .. tostring(player:GetAttribute("Construction") or 0),
        Ryu = "Output " .. tostring(math.floor(player:GetAttribute("OutputCharge") or 0)),
        Uro = "Sky " .. tostring(math.floor(player:GetAttribute("SkyDistortion") or 0)),
        Kusakabe = "Simple Domain " .. (player:GetAttribute("SimpleDomain") and "ON" or "OFF")
    }

    if key ~= "" then
        return key .. " • " .. (values[id] or "")
    end
    return values[id] or ""
end

local function update()
    local aw = tonumber(player:GetAttribute("Awakening") or 0) or 0
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local definition = definitions[id]
    local moveSet = moves[id]
    local hpRatio = healthPercent()

    if moveSet then
        specialMove.Text = moveSet.SpecialName or "SPECIAL"
        skillMove.Text = moveSet.SkillName or "SKILL"
    end

    awakenMove.Text = player:GetAttribute("AwakeningName") or (definition and definition.AwakeningName) or "AWAKEN"
    domainMove.Text = definition and definition.Domain or "NO DOMAIN"
    characterLabel.Text = player:GetAttribute("CharacterName") or (definition and definition.Name) or id
    uniqueLabel.Text = (definition and definition.Subtitle or "Fighter") .. " • " .. uniqueText()

    healthFill.Size = UDim2.fromScale(hpRatio, 1)
    healthText.Text = tostring(math.floor(hpRatio * 100 + 0.5)) .. "% HP"

    local awakeningRatio = math.clamp(aw / 100, 0, 1)
    awakeningFill.Size = UDim2.fromScale(awakeningRatio, 1)
    awakeningText.Text = tostring(math.floor(awakeningRatio * 100 + 0.5)) .. "%"

    local currentState = "READY"
    if player:GetAttribute("InClash") then
        currentState = "DOMAIN CLASH"
    elseif player:GetAttribute("AwakeningActive") then
        currentState = "AWAKENING"
    elseif player:GetAttribute("DomainActive") then
        currentState = "DOMAIN ACTIVE"
    elseif player:GetAttribute("ClashOpening") then
        currentState = "CLASH OPENING"
    end
    stateLabel.Text = currentState

    local hasDomain = definition and definition.Domain ~= nil
    domainButton.Text = hasDomain and "DOMAIN" or "NO DOMAIN"
    domainButton.BackgroundTransparency = hasDomain and 0.04 or 0.45
    domainHint.Text = hasDomain and "READY" or "LOCKED"
    domainHint.TextColor3 = hasDomain and muted or Color3.fromRGB(106, 109, 123)

    awakenHint.Text = awakeningRatio >= 1 and "READY" or "CHARGE"
    oneTime.Text = player:GetAttribute("OneTimeAttackReady") and "OT  READY" or "OT  USED"

    local preferred = UserInputService.PreferredInput
    local touch = preferred == Enum.PreferredInput.Touch
    if touch then
        specialKey.Text = "TAP"
        skillKey.Text = "TAP"
        awakenKey.Text = "TAP"
        domainKey.Text = hasDomain and "TAP" or "—"
    elseif preferred == Enum.PreferredInput.Gamepad then
        specialKey.Text = "X"
        skillKey.Text = "Y"
        awakenKey.Text = "↑"
        domainKey.Text = hasDomain and "↓" or "—"
    else
        specialKey.Text = "Z"
        skillKey.Text = "X"
        awakenKey.Text = "G"
        domainKey.Text = hasDomain and "H" or "—"
    end
end

local function refreshCooldownHints()
    local now = os.clock()
    local function hintFor(action, labelObject, fallback)
        local remaining = math.max(0, (tonumber(gui:GetAttribute("Cooldown_" .. action)) or 0) - now)
        if remaining > 0.01 then
            labelObject.Text = string.format("%.1fs", remaining)
            labelObject.TextColor3 = muted
        else
            labelObject.Text = fallback or "READY"
            labelObject.TextColor3 = muted
        end
    end

    hintFor("Special", specialHint, "READY")
    hintFor("Skill", skillHint, "READY")
    hintFor("Domain", domainHint, domainButton.Text == "NO DOMAIN" and "LOCKED" or "READY")
end

for _, attr in ipairs({
    "Awakening", "CharacterId", "CharacterName", "CharacterTitle", "UniqueState",
    "AwakeningActive", "AwakeningName", "DomainActive", "DomainName", "InClash", "ClashOpening",
    table.unpack(stateAttributeNames)
}) do
    player:GetAttributeChangedSignal(attr):Connect(update)
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(update)

local function bindHumanoid(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(update)
    update()
end

if player.Character then
    bindHumanoid(player.Character)
end
player.CharacterAdded:Connect(bindHumanoid)

local keyActions = {
    [Enum.KeyCode.R] = "Heavy",
    [Enum.KeyCode.Q] = "Dash",
    [Enum.KeyCode.F] = "BlockStart",
    [Enum.KeyCode.E] = "Dodge",
    [Enum.KeyCode.T] = "Grab",
    [Enum.KeyCode.Z] = "Special",
    [Enum.KeyCode.X] = "Skill",
    [Enum.KeyCode.G] = "Awaken",
    [Enum.KeyCode.H] = "Domain",
    [Enum.KeyCode.J] = "OneTime"
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fireAction("M1", cooldownFor("M1"))
        return
    end

    local clashKeyMap = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4
    }

    local clashMove = clashKeyMap[input.KeyCode]
    if clashMove and player:GetAttribute("InClash") then
        combatAction:FireServer("ClashMove", clashMove)
        return
    end

    local action = keyActions[input.KeyCode]
    if action then
        fireAction(action, cooldownFor(action))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        combatAction:FireServer("BlockEnd")
    end
end)

local function floatingDamage(target, amount, tag)
    if not target or not target.Parent then
        return
    end

    local head = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
    if not head then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageNumber"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(92, 42)
    billboard.StudsOffset = Vector3.new((math.random() - 0.5) * 1.2, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = head

    local value = Instance.new("TextLabel")
    value.Size = UDim2.fromScale(1, 1)
    value.BackgroundTransparency = 1
    value.Text = "-" .. tostring(math.floor(tonumber(amount) or 0))
    value.Font = Enum.Font.GothamBlack
    value.TextSize = tag == "BlackFlash" and 25 or 20
    value.TextColor3 = tag == "BlackFlash" and Color3.fromRGB(235, 235, 255) or Color3.fromRGB(255, 238, 238)
    value.TextStrokeTransparency = 0.35
    value.TextStrokeColor3 = Color3.fromRGB(10, 10, 15)
    value.Parent = billboard

    local move = TweenService:Create(
        billboard,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {StudsOffset = billboard.StudsOffset + Vector3.new(0, 1.6, 0)}
    )
    local fade = TweenService:Create(
        value,
        TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {TextTransparency = 1, TextStrokeTransparency = 1}
    )
    move:Play()
    fade:Play()
    Debris:AddItem(billboard, 0.48)
end

local function burst(position, size, transparency, duration)
    if typeof(position) ~= "Vector3" then
        return
    end

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
    part.Material = Enum.Material.Neon
    part.Color = accentBright
    part.Transparency = transparency
    part.CFrame = CFrame.new(position)
    part.Parent = workspace.CurrentCamera

    local tween = TweenService:Create(part, TweenInfo.new(duration), {
        Size = Vector3.new(size * 2.8, size * 2.8, size * 2.8),
        Transparency = 1
    })
    tween:Play()
    Debris:AddItem(part, duration + 0.1)
end

combatFX.OnClientEvent:Connect(function(kind, position, payload, extra)
    if kind == "CharacterMove" then
        CombatVFX.CharacterMove(position, payload)
        if payload and payload.actor and payload.actor:IsA("Model") then
            CombatAnimationService.Play(payload.actor, payload.move or "Special", payload.action or "Special")
        end
        return
    elseif kind == "CharacterOneTime" then
        CombatVFX.CharacterOneTime(position, payload, extra)
        return
    elseif kind == "CharacterAwakening" then
        CombatVFX.Awakening(position, payload, extra)
        return
    elseif kind == "DomainStart" then
        CombatVFX.Domain(position, payload, false)
        return
    elseif kind == "DomainClashStart" then
        CombatVFX.Domain(position, payload, true)
        return
    elseif kind == "Dash" or kind == "MeleeSwing" or kind == "Heavy" or kind == "Grab" or kind == "Block" then
        CombatVFX.Utility(kind, position, payload)
        return
    end

    if kind == "HitReaction" then
        CombatAnimationService.HitReact(position, payload, extra)
        return
    elseif kind == "DamageNumber" then
        floatingDamage(position, payload, extra)
        return
    end

    if typeof(position) ~= "Vector3" then
        return
    end

    if kind == "BlackFlash" then
        burst(position, 2.4, 0.05, 0.18)
    elseif kind == "PerfectBlock" then
        burst(position, 1.6, 0.1, 0.12)
    elseif kind == "Hit" then
        burst(position, 0.9, 0.28, 0.09)
    elseif kind == "Awakening" then
        burst(position, 3.4, 0.18, 0.25)
    elseif kind == "DomainStart" or kind == "DomainClashStart" then
        burst(position, 5.2, 0.55, 0.45)
    elseif kind == "OneTimeAttack" then
        burst(position, 7.4, 0.3, 0.5)
    else
        burst(position, 2.5, 0.25, 0.2)
    end
end)

clashEvent.OnClientEvent:Connect(function(event, payload)
    payload = payload or {}

    if event == "ClashStart" or event == "ClashReset" then
        clashFrame.Visible = true
        clashHint.Text = "ROUND " .. tostring(payload.round or 1) .. " • CHOOSE"
        stateLabel.Text = "DOMAIN CLASH"
    elseif event == "ClashLocked" then
        clashHint.Text = "LOCKED • WAIT"
        stateLabel.Text = "CLASH LOCKED"
    elseif event == "ClashPressure" then
        clashHint.Text = "PRESSURE " .. tostring(payload.value or payload.opponent or 0)
        stateLabel.Text = "CLASH PRESSURE"
    elseif event == "ClashNeutral" then
        clashHint.Text = "NEUTRAL • RESET"
        stateLabel.Text = "CLASH NEUTRAL"
    elseif event == "ClashEnd" then
        clashFrame.Visible = false
        update()
    end
end)

serverEvent.OnClientEvent:Connect(function(event)
    if event == "BlackFlashWindow" then
        stateLabel.Text = "BLACK FLASH"
        task.delay(0.3, update)
    elseif event == "DodgeEvaded" then
        stateLabel.Text = "DODGED"
        task.delay(0.35, update)
    end
end)

task.spawn(function()
    while gui.Parent do
        refreshCooldownHints()
        task.wait(0.1)
    end
end)

update()
