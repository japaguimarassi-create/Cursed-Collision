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

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function gradient(parent, colorA, colorB, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(colorA, colorB)
    g.Rotation = rotation or 0
    g.Parent = parent
    return g
end

local function label(parent, text, size, position, font, textSize)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.Size = size
    l.Position = position
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 16
    l.TextColor3 = Color3.fromRGB(235, 235, 245)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function button(parent, name, text, size, position, accent)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Size = size
    b.Position = position
    b.AutoButtonColor = false
    b.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
    b.BackgroundTransparency = 0.08
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.fromRGB(238, 238, 245)
    b.TextSize = 15
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 12)
    stroke(b, accent or Color3.fromRGB(90, 94, 112), 1.5, 0.25)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(34, 37, 48)}):Play()
    end)

    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(22, 24, 31)}):Play()
    end)

    return b
end

local accent = Color3.fromRGB(152, 104, 255)
local accentBright = Color3.fromRGB(197, 163, 255)
local danger = Color3.fromRGB(220, 72, 86)
local gold = Color3.fromRGB(245, 190, 76)
local panel = Color3.fromRGB(12, 14, 20)

local header = Instance.new("Frame")
header.Name = "PlayerPanel"
header.Size = UDim2.fromScale(0.39, 0.135)
header.Position = UDim2.fromScale(0.02, 0.025)
header.BackgroundColor3 = panel
header.BackgroundTransparency = 0.08
header.BorderSizePixel = 0
header.Parent = gui
corner(header, 14)
stroke(header, Color3.fromRGB(90, 94, 112), 1.5, 0.35)
gradient(header, Color3.fromRGB(18, 20, 29), Color3.fromRGB(10, 11, 16), 0)

local rosterButton = button(gui, "RosterButton", "☰", UDim2.fromScale(0.055, 0.065), UDim2.fromScale(0.425, 0.028), accent)
rosterButton.TextSize = 22

local title = label(header, "CURSED COLLISION", UDim2.fromScale(0.62, 0.25), UDim2.fromScale(0.04, 0.04), Enum.Font.GothamBlack, 17)
local characterLabel = label(header, "Yuji Itadori", UDim2.fromScale(0.92, 0.25), UDim2.fromScale(0.04, 0.27), Enum.Font.GothamBold, 16)
local uniqueLabel = label(header, "", UDim2.fromScale(0.92, 0.20), UDim2.fromScale(0.04, 0.49), Enum.Font.Gotham, 12)
uniqueLabel.TextColor3 = Color3.fromRGB(171, 174, 190)

local healthBack = Instance.new("Frame")
healthBack.Name = "HealthBar"
healthBack.Size = UDim2.fromScale(0.58, 0.11)
healthBack.Position = UDim2.fromScale(0.04, 0.73)
healthBack.BackgroundColor3 = Color3.fromRGB(50, 25, 32)
healthBack.BorderSizePixel = 0
healthBack.Parent = header
corner(healthBack, 7)

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = danger
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
corner(healthFill, 7)

local healthText = label(header, "100 HP", UDim2.fromScale(0.18, 0.12), UDim2.fromScale(0.64, 0.72), Enum.Font.GothamBold, 11)
healthText.TextXAlignment = Enum.TextXAlignment.Right

local awBack = Instance.new("Frame")
awBack.Name = "AwakeningBar"
awBack.Size = UDim2.fromScale(0.58, 0.09)
awBack.Position = UDim2.fromScale(0.04, 0.87)
awBack.BackgroundColor3 = Color3.fromRGB(35, 26, 51)
awBack.BorderSizePixel = 0
awBack.Parent = header
corner(awBack, 7)

local awFill = Instance.new("Frame")
awFill.Size = UDim2.fromScale(0, 1)
awFill.BackgroundColor3 = accent
awFill.BorderSizePixel = 0
awFill.Parent = awBack
corner(awFill, 7)

local awText = label(header, "AWAKEN 0%", UDim2.fromScale(0.30, 0.11), UDim2.fromScale(0.66, 0.85), Enum.Font.GothamBold, 10)
awText.TextXAlignment = Enum.TextXAlignment.Right

local matchPanel = Instance.new("Frame")
matchPanel.Name = "MatchPanel"
matchPanel.Size = UDim2.fromScale(0.26, 0.07)
matchPanel.Position = UDim2.fromScale(0.50, 0.025)
matchPanel.AnchorPoint = Vector2.new(0.5, 0)
matchPanel.BackgroundColor3 = panel
matchPanel.BackgroundTransparency = 0.18
matchPanel.BorderSizePixel = 0
matchPanel.Parent = gui
corner(matchPanel, 12)
stroke(matchPanel, Color3.fromRGB(90, 94, 112), 1, 0.45)

local matchLabel = label(matchPanel, "OPEN ARENA  •  FIGHT", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Enum.Font.GothamBold, 13)
matchLabel.TextXAlignment = Enum.TextXAlignment.Center
matchLabel.TextColor3 = Color3.fromRGB(205, 204, 222)

local status = label(gui, "READY", UDim2.fromScale(0.42, 0.055), UDim2.fromScale(0.29, 0.70), Enum.Font.GothamBlack, 17)
status.TextXAlignment = Enum.TextXAlignment.Center
status.TextColor3 = Color3.fromRGB(245, 245, 255)
status.ZIndex = 4

local techniqueFrame = Instance.new("Frame")
techniqueFrame.Name = "TechniqueBar"
techniqueFrame.Size = UDim2.fromScale(0.45, 0.18)
techniqueFrame.Position = UDim2.fromScale(0.28, 0.78)
techniqueFrame.BackgroundTransparency = 1
techniqueFrame.Parent = gui

local techniqueLayout = Instance.new("UIGridLayout")
techniqueLayout.CellSize = UDim2.new(0.237, 0, 0.92, 0)
techniqueLayout.CellPadding = UDim2.new(0.017, 0, 0, 0)
techniqueLayout.FillDirectionMaxCells = 4
techniqueLayout.SortOrder = Enum.SortOrder.LayoutOrder
techniqueLayout.Parent = techniqueFrame

local function techniqueButton(name, keyLabel, action, order)
    local b = button(techniqueFrame, name, "", UDim2.new(), UDim2.new(), accent)
    b.LayoutOrder = order
    local key = label(b, keyLabel, UDim2.fromScale(1, 0.30), UDim2.fromScale(0, 0.05), Enum.Font.GothamBlack, 12)
    key.TextXAlignment = Enum.TextXAlignment.Center
    key.TextColor3 = accentBright
    local move = label(b, name, UDim2.fromScale(0.92, 0.42), UDim2.fromScale(0.04, 0.38), Enum.Font.GothamBold, 14)
    move.TextXAlignment = Enum.TextXAlignment.Center
    local hint = label(b, "READY", UDim2.fromScale(0.92, 0.18), UDim2.fromScale(0.04, 0.78), Enum.Font.Gotham, 9)
    hint.TextXAlignment = Enum.TextXAlignment.Center
    b.Activated:Connect(function()
        combatAction:FireServer(action)
    end)
    return b, hint, move
end

local specialButton, specialHint = techniqueButton("SPECIAL", "1", "Special", 1)
local skillButton, skillHint = techniqueButton("SKILL", "2", "Skill", 2)
local awakenButton, awakenHint = techniqueButton("AWAKEN", "3", "Awaken", 3)
local domainButton, domainHint = techniqueButton("DOMAIN", "4", "Domain", 4)

local actionFrame = Instance.new("Frame")
actionFrame.Name = "CombatActions"
actionFrame.Size = UDim2.fromScale(0.28, 0.37)
actionFrame.Position = UDim2.fromScale(0.70, 0.55)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = gui

local m1 = button(actionFrame, "M1", "M1", UDim2.fromScale(0.46, 0.43), UDim2.fromScale(0.27, 0.47), danger)
m1.TextSize = 24
stroke(m1, danger, 2, 0.08)
m1.Activated:Connect(function() combatAction:FireServer("M1") end)

local heavy = button(actionFrame, "Heavy", "HEAVY", UDim2.fromScale(0.30, 0.20), UDim2.fromScale(0.02, 0.18), Color3.fromRGB(190, 190, 205))
heavy.TextSize = 11
heavy.Activated:Connect(function() combatAction:FireServer("Heavy") end)

local grab = button(actionFrame, "Grab", "GRAB", UDim2.fromScale(0.30, 0.20), UDim2.fromScale(0.68, 0.18), Color3.fromRGB(190, 190, 205))
grab.TextSize = 11
grab.Activated:Connect(function() combatAction:FireServer("Grab") end)

local dash = button(actionFrame, "Dash", "DASH", UDim2.fromScale(0.27, 0.20), UDim2.fromScale(0.05, 0.68), accent)
dash.TextSize = 11
dash.Activated:Connect(function() combatAction:FireServer("Dash") end)

local blockButton = button(actionFrame, "Block", "BLOCK", UDim2.fromScale(0.27, 0.20), UDim2.fromScale(0.68, 0.68), Color3.fromRGB(90, 180, 255))
blockButton.TextSize = 11
local mobileBlock = false
blockButton.Activated:Connect(function()
    mobileBlock = not mobileBlock
    blockButton.Text = mobileBlock and "BLOCKING" or "BLOCK"
    combatAction:FireServer(mobileBlock and "BlockStart" or "BlockEnd")
end)

local dodge = button(actionFrame, "Dodge", "DODGE", UDim2.fromScale(0.24, 0.15), UDim2.fromScale(0.38, 0.02), gold)
dodge.TextSize = 10
dodge.Activated:Connect(function() combatAction:FireServer("Dodge") end)

local oneTime = button(actionFrame, "OneTime", "ONE TIME", UDim2.fromScale(0.22, 0.17), UDim2.fromScale(0.39, 0.80), Color3.fromRGB(244, 96, 140))
oneTime.TextSize = 10
oneTime.Activated:Connect(function() combatAction:FireServer("OneTime") end)

local rosterOverlay = Instance.new("Frame")
rosterOverlay.Name = "RosterOverlay"
rosterOverlay.Size = UDim2.fromScale(0.76, 0.76)
rosterOverlay.Position = UDim2.fromScale(0.50, 0.52)
rosterOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
rosterOverlay.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
rosterOverlay.BackgroundTransparency = 0.05
rosterOverlay.BorderSizePixel = 0
rosterOverlay.Visible = false
rosterOverlay.ZIndex = 20
rosterOverlay.Parent = gui
corner(rosterOverlay, 18)
stroke(rosterOverlay, accent, 1.5, 0.35)

local rosterTitle = label(rosterOverlay, "CHOOSE YOUR FIGHTER", UDim2.fromScale(0.72, 0.10), UDim2.fromScale(0.035, 0.025), Enum.Font.GothamBlack, 20)
rosterTitle.ZIndex = 21

local rosterSub = label(rosterOverlay, "24 CHARACTER KITS  •  TAP TO SELECT", UDim2.fromScale(0.72, 0.06), UDim2.fromScale(0.036, 0.12), Enum.Font.Gotham, 11)
rosterSub.TextColor3 = Color3.fromRGB(159, 160, 177)
rosterSub.ZIndex = 21

local closeRoster = button(rosterOverlay, "Close", "×", UDim2.fromScale(0.075, 0.11), UDim2.fromScale(0.89, 0.025), danger)
closeRoster.TextSize = 24
closeRoster.ZIndex = 21

local selectFrame = Instance.new("ScrollingFrame")
selectFrame.Name = "CharacterGrid"
selectFrame.Size = UDim2.fromScale(0.93, 0.78)
selectFrame.Position = UDim2.fromScale(0.035, 0.18)
selectFrame.BackgroundTransparency = 1
selectFrame.BorderSizePixel = 0
selectFrame.ScrollBarThickness = 4
selectFrame.ScrollBarImageTransparency = 0.25
selectFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
selectFrame.CanvasSize = UDim2.fromOffset(0, 0)
selectFrame.ZIndex = 21
selectFrame.Parent = rosterOverlay

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.24, 0, 0, 68)
grid.CellPadding = UDim2.new(0.012, 0, 0, 10)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = selectFrame

local ids = {}
for id in pairs(definitions) do
    table.insert(ids, id)
end
table.sort(ids)

for index, id in ipairs(ids) do
    local definition = definitions[id]
    local b = button(selectFrame, id, definition.Name, UDim2.new(), UDim2.new(), Color3.fromRGB(90, 94, 112))
    b.LayoutOrder = index
    b.TextSize = 13
    b.TextWrapped = true
    b.ZIndex = 22

    local sub = label(b, definition.Unique or "", UDim2.fromScale(0.92, 0.24), UDim2.fromScale(0.04, 0.67), Enum.Font.Gotham, 8)
    sub.TextColor3 = Color3.fromRGB(150, 152, 168)
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
corner(clashFrame, 18)
stroke(clashFrame, gold, 2, 0.12)

local clashTitle = label(clashFrame, "DOMAIN CLASH", UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.05), Enum.Font.GothamBlack, 22)
clashTitle.TextXAlignment = Enum.TextXAlignment.Center
clashTitle.ZIndex = 31

local clashHint = label(clashFrame, "CHOOSE A RESPONSE", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0.27), Enum.Font.Gotham, 10)
clashHint.TextXAlignment = Enum.TextXAlignment.Center
clashHint.TextColor3 = Color3.fromRGB(164, 166, 180)
clashHint.ZIndex = 31

local clashButtons = {}
for i, moveName in ipairs({"CRUSH", "COUNTER", "FEINT", "BREAK"}) do
    local b = button(clashFrame, "Clash"..i, i.."  "..moveName, UDim2.fromScale(0.21, 0.42), UDim2.fromScale(0.025 + (i - 1) * 0.245, 0.46), accent)
    b.TextSize = 11
    b.ZIndex = 31
    clashButtons[i] = b
    b.Activated:Connect(function()
        combatAction:FireServer("ClashMove", i)
    end)
end

local function healthPercent()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.MaxHealth <= 0 then
        return 0
    end
    return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
end

local stateAttributeNames = {
    "Momentum","Infinity","LimitlessState","SlashState","Shikigami","RikaActive","CopySlot","WeaponMode",
    "SoulIntegrity","SwapReady","Jackpot","JackpotRoll","Blood","ElectricalCharge","FrameSequence",
    "TechniqueStock","Heat","Tide","Roots","Evidence","Confiscated","ComedyContext","Frost",
    "Construction","OutputCharge","SkyDistortion","SimpleDomain","PerfectComboStep","OneTimeAttackReady"
}

local function uniqueText()
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local key = player:GetAttribute("UniqueState") or ""

    local values = {
        Yuji = "Momentum "..tostring(player:GetAttribute("Momentum") or 0),
        Gojo = (player:GetAttribute("Infinity") and "Infinity ON" or "Infinity OFF").."  •  "..tostring(player:GetAttribute("LimitlessState") or "Neutral"),
        Sukuna = "State "..tostring(player:GetAttribute("SlashState") or "Dismantle"),
        Megumi = tostring(player:GetAttribute("Shikigami") or "Divine Dogs"),
        Yuta = "Rika "..(player:GetAttribute("RikaActive") and "ON" or "OFF").."  •  Copy "..tostring(player:GetAttribute("CopySlot") or 1),
        Maki = tostring(player:GetAttribute("WeaponMode") or "Katana"),
        Toji = tostring(player:GetAttribute("WeaponMode") or "Katana"),
        Mahito = "Soul "..tostring(math.floor(player:GetAttribute("SoulIntegrity") or 100)),
        Todo = "Swap "..(player:GetAttribute("SwapReady") and "READY" or "USED"),
        Hakari = player:GetAttribute("Jackpot") and "JACKPOT" or ("Roll "..tostring(player:GetAttribute("JackpotRoll") or 0)),
        Choso = "Blood "..tostring(math.floor(player:GetAttribute("Blood") or 100)),
        Kashimo = "Charge "..tostring(math.floor(player:GetAttribute("ElectricalCharge") or 0)),
        Naoya = "Frames "..tostring(player:GetAttribute("FrameSequence") or 0).."/24",
        Kenjaku = "Stock "..tostring(player:GetAttribute("TechniqueStock") or 0),
        Jogo = "Heat "..tostring(math.floor(player:GetAttribute("Heat") or 0)),
        Dagon = "Tide "..tostring(math.floor(player:GetAttribute("Tide") or 0)),
        Hanami = "Roots "..tostring(math.floor(player:GetAttribute("Roots") or 0)),
        Higuruma = "Evidence "..tostring(math.floor(player:GetAttribute("Evidence") or 0)),
        Takaba = "Context "..tostring(math.floor(player:GetAttribute("ComedyContext") or 0)),
        Uraume = "Frost "..tostring(math.floor(player:GetAttribute("Frost") or 0)),
        Yorozu = "Construction "..tostring(player:GetAttribute("Construction") or 0),
        Ryu = "Output "..tostring(math.floor(player:GetAttribute("OutputCharge") or 0)),
        Uro = "Sky "..tostring(math.floor(player:GetAttribute("SkyDistortion") or 0)),
        Kusakabe = "Simple Domain "..(player:GetAttribute("SimpleDomain") and "ON" or "OFF")
    }

    if key ~= "" then
        return key.."  •  "..(values[id] or "")
    end
    return values[id] or ""
end

local function update()
    local aw = player:GetAttribute("Awakening") or 0
    local id = player:GetAttribute("CharacterId") or "Yuji"
    local definition = definitions[id]

    characterLabel.Text = (player:GetAttribute("CharacterName") or (definition and definition.Name) or id)
    uniqueLabel.Text = (definition and definition.Subtitle or "Fighter").."  •  "..uniqueText()

    local hp = math.floor((healthPercent() * 100) + 0.5)
    healthFill.Size = UDim2.fromScale(healthPercent(), 1)
    healthText.Text = tostring(hp).."% HP"

    local awakening = math.clamp(aw / 100, 0, 1)
    awFill.Size = UDim2.fromScale(awakening, 1)
    awText.Text = "AWAKEN "..tostring(math.floor(awakening * 100)).."%"

    local state = "READY"
    if player:GetAttribute("InClash") then
        state = "DOMAIN CLASH"
    elseif player:GetAttribute("AwakeningActive") then
        state = "AWAKENING  •  STEP "..tostring(player:GetAttribute("PerfectComboStep") or 0)
    elseif player:GetAttribute("DomainActive") then
        state = "DOMAIN  •  "..tostring(player:GetAttribute("DomainName") or "")
    elseif player:GetAttribute("ClashOpening") then
        state = "CLASH OPENING"
    end
    status.Text = state

    local hasDomain = definition and definition.Domain ~= nil
    domainButton.Text = hasDomain and "DOMAIN" or "NO DOMAIN"
    domainButton.AutoButtonColor = hasDomain
    domainHint.Text = hasDomain and "READY" or "LOCKED"

    specialHint.Text = "TECHNIQUE"
    skillHint.Text = "TECHNIQUE"
    awakenHint.Text = awakening >= 1 and "READY" or "CHARGE"

    oneTime.Text = player:GetAttribute("OneTimeAttackReady") == false and "USED" or "ONE\nTIME"
end

for _, attr in ipairs({
    "Awakening","CharacterId","CharacterName","CharacterTitle","UniqueState",
    "AwakeningActive","AwakeningName","DomainActive","DomainName","InClash","ClashOpening",
    table.unpack(stateAttributeNames)
}) do
    player:GetAttributeChangedSignal(attr):Connect(update)
end

local function bindHumanoid(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(update)
    update()
end

if player.Character then
    bindHumanoid(player.Character)
end
player.CharacterAdded:Connect(bindHumanoid)
update()

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
        combatAction:FireServer("M1")
        return
    end

    local clashKeyMap = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4
    }

    local clashMove = clashKeyMap[input.KeyCode]
    if clashMove then
        if player:GetAttribute("InClash") then
            combatAction:FireServer("ClashMove", clashMove)
        end
        return
    end

    local action = keyActions[input.KeyCode]
    if action then
        combatAction:FireServer(action)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        combatAction:FireServer("BlockEnd")
    end
end)

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

combatFX.OnClientEvent:Connect(function(kind, position)
    if typeof(position) ~= "Vector3" then
        return
    end

    if kind == "BlackFlash" then
        burst(position, 2.4, 0.05, 0.18)
    elseif kind == "PerfectBlock" then
        burst(position, 1.6, 0.1, 0.12)
    elseif kind == "Hit" then
        burst(position, 0.9, 0.28, 0.09)
    elseif kind == "Awakening" or kind == "CharacterAwakening" then
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
        clashHint.Text = "ROUND "..tostring(payload.round or 1).."  •  CHOOSE A RESPONSE"
        status.Text = "DOMAIN CLASH"
    elseif event == "ClashLocked" then
        clashHint.Text = "LOCKED  •  WAIT FOR RESET"
        status.Text = "CLASH LOCKED"
    elseif event == "ClashPressure" then
        clashHint.Text = "PRESSURE "..tostring(payload.value or payload.opponent or 0)
        status.Text = "CLASH PRESSURE"
    elseif event == "ClashNeutral" then
        clashHint.Text = "NEUTRAL  •  ROUND RESET"
        status.Text = "CLASH NEUTRAL"
    elseif event == "ClashEnd" then
        clashFrame.Visible = false
        update()
    end
end)

serverEvent.OnClientEvent:Connect(function(event)
    if event == "BlackFlashWindow" then
        status.Text = "BLACK FLASH WINDOW"
        task.delay(0.3, update)
    elseif event == "DodgeEvaded" then
        status.Text = "DODGED"
        task.delay(0.35, update)
    end
end)
