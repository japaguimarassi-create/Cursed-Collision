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
gui.Name = "CursedCollisionUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local top = Instance.new("Frame")
top.Size = UDim2.fromScale(0.42, 0.2)
top.Position = UDim2.fromScale(0.02, 0.03)
top.BackgroundTransparency = 0.2
top.Parent = gui

local characterLabel = Instance.new("TextLabel")
characterLabel.Size = UDim2.fromScale(1, 0.18)
characterLabel.BackgroundTransparency = 1
characterLabel.TextScaled = true
characterLabel.TextXAlignment = Enum.TextXAlignment.Left
characterLabel.Parent = top

local uniqueLabel = Instance.new("TextLabel")
uniqueLabel.Size = UDim2.fromScale(1, 0.18)
uniqueLabel.Position = UDim2.fromScale(0, 0.18)
uniqueLabel.BackgroundTransparency = 1
uniqueLabel.TextScaled = true
uniqueLabel.TextXAlignment = Enum.TextXAlignment.Left
uniqueLabel.Parent = top

local healthBack = Instance.new("Frame")
healthBack.Size = UDim2.fromScale(0.98, 0.16)
healthBack.Position = UDim2.fromScale(0.01, 0.38)
healthBack.Parent = top

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.Parent = healthBack

local awBack = Instance.new("Frame")
awBack.Size = UDim2.fromScale(0.98, 0.16)
awBack.Position = UDim2.fromScale(0.01, 0.58)
awBack.Parent = top

local awFill = Instance.new("Frame")
awFill.Size = UDim2.fromScale(0, 1)
awFill.Parent = awBack

local status = Instance.new("TextLabel")
status.Size = UDim2.fromScale(1, 0.22)
status.Position = UDim2.fromScale(0, 0.78)
status.BackgroundTransparency = 1
status.TextScaled = true
status.Parent = top

local actionFrame = Instance.new("Frame")
actionFrame.Size = UDim2.fromScale(0.42, 0.34)
actionFrame.Position = UDim2.fromScale(0.56, 0.62)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = gui

local function button(name, action, x, y)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = name
    b.TextScaled = true
    b.Size = UDim2.fromScale(0.18, 0.22)
    b.Position = UDim2.fromScale(x, y)
    b.Parent = actionFrame
    b.Activated:Connect(function()
        combatAction:FireServer(action)
    end)
    return b
end

button("M1", "M1", 0, 0)
button("HEAVY", "Heavy", 0.2, 0)
button("DASH", "Dash", 0.4, 0)
local mobileBlock = false
local blockButton = Instance.new("TextButton")
blockButton.Name = "BLOCK"
blockButton.Text = "BLOCK"
blockButton.TextScaled = true
blockButton.Size = UDim2.fromScale(0.18, 0.22)
blockButton.Position = UDim2.fromScale(0.6, 0)
blockButton.Parent = actionFrame
blockButton.Activated:Connect(function()
    mobileBlock = not mobileBlock
    blockButton.Text = mobileBlock and "BLOCKING" or "BLOCK"
    combatAction:FireServer(mobileBlock and "BlockStart" or "BlockEnd")
end)
button("DODGE", "Dodge", 0.8, 0)
button("GRAB", "Grab", 0, 0.25)
button("SPECIAL", "Special", 0.2, 0.25)
button("SKILL", "Skill", 0.4, 0.25)
button("AWAKEN", "Awaken", 0.6, 0.25)
button("DOMAIN", "Domain", 0.8, 0.25)
button("ONE TIME", "OneTime", 0, 0.5)

local selectFrame = Instance.new("ScrollingFrame")
selectFrame.Size = UDim2.fromScale(0.46, 0.5)
selectFrame.Position = UDim2.fromScale(0.02, 0.25)
selectFrame.BackgroundTransparency = 0.25
selectFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
selectFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
selectFrame.ScrollBarThickness = 6
selectFrame.Parent = gui

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromScale(0.23, 0.11)
layout.CellPadding = UDim2.fromScale(0.01, 0.01)
layout.Parent = selectFrame

local selectTitle = Instance.new("TextLabel")
selectTitle.Size = UDim2.new(1, -12, 0, 24)
selectTitle.Position = UDim2.fromOffset(6, 4)
selectTitle.Text = "CHARACTERS • 24"
selectTitle.TextScaled = true
selectTitle.BackgroundTransparency = 0.15
selectTitle.Parent = selectFrame

local ids = {}
for id in pairs(definitions) do table.insert(ids, id) end
table.sort(ids)

for _, id in ipairs(ids) do
    local definition = definitions[id]
    local b = Instance.new("TextButton")
    b.Text = definition.Name:gsub(" ", "\n")
    b.TextScaled = true
    b.BackgroundTransparency = 0.08
    b.Parent = selectFrame
    b.Activated:Connect(function()
        selection:FireServer(id)
    end)
end

local clashFrame = Instance.new("Frame")
clashFrame.Size = UDim2.fromScale(0.58, 0.25)
clashFrame.Position = UDim2.fromScale(0.21, 0.36)
clashFrame.BackgroundTransparency = 0.12
clashFrame.Visible = false
clashFrame.Parent = gui

local clashTitle = Instance.new("TextLabel")
clashTitle.Size = UDim2.fromScale(1, 0.22)
clashTitle.Text = "DOMAIN CLASH"
clashTitle.TextScaled = true
clashTitle.BackgroundTransparency = 1
clashTitle.Parent = clashFrame

local clashButtons = {}
for i = 1, 4 do
    local b = Instance.new("TextButton")
    b.Text = tostring(i)
    b.TextScaled = true
    b.Size = UDim2.fromScale(0.22, 0.54)
    b.Position = UDim2.fromScale((i - 1) * 0.255, 0.32)
    b.Parent = clashFrame
    clashButtons[i] = b
    b.Activated:Connect(function()
        combatAction:FireServer("ClashMove", i)
    end)
end

local function healthPercent()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.MaxHealth <= 0 then return 0 end
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
    local pieces = {key}

    local values = {
        Yuji = "Momentum "..tostring(player:GetAttribute("Momentum") or 0),
        Gojo = (player:GetAttribute("Infinity") and "Infinity ON" or "Infinity OFF").." • "..tostring(player:GetAttribute("LimitlessState") or "Neutral"),
        Sukuna = "State "..tostring(player:GetAttribute("SlashState") or "Dismantle"),
        Megumi = tostring(player:GetAttribute("Shikigami") or "Divine Dogs"),
        Yuta = "Rika "..(player:GetAttribute("RikaActive") and "ON" or "OFF").." • Copy "..tostring(player:GetAttribute("CopySlot") or 1),
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
        Yorozu = "Construction "..tostring(math.floor(player:GetAttribute("Construction") or 0)),
        Ryu = "Output "..tostring(math.floor(player:GetAttribute("OutputCharge") or 0)),
        Uro = "Sky "..tostring(math.floor(player:GetAttribute("SkyDistortion") or 0)),
        Kusakabe = "Simple Domain "..(player:GetAttribute("SimpleDomain") and "ON" or "OFF")
    }

    table.insert(pieces, values[id] or "")
    return table.concat(pieces, " • ")
end

local function update()
    local aw = player:GetAttribute("Awakening") or 0
    local id = player:GetAttribute("CharacterId") or "Yuji"
    characterLabel.Text = (player:GetAttribute("CharacterName") or id).." • "..(player:GetAttribute("AwakeningName") or "")
    uniqueLabel.Text = uniqueText()
    healthFill.Size = UDim2.fromScale(healthPercent(), 1)
    awFill.Size = UDim2.fromScale(math.clamp(aw / 100, 0, 1), 1)

    local state = "READY"
    if player:GetAttribute("InClash") then
        state = "DOMAIN CLASH"
    elseif player:GetAttribute("AwakeningActive") then
        state = "AWAKENING • STEP "..tostring(player:GetAttribute("PerfectComboStep") or 0)
    elseif player:GetAttribute("DomainActive") then
        state = "DOMAIN • "..tostring(player:GetAttribute("DomainName") or "")
    elseif player:GetAttribute("ClashOpening") then
        state = "CLASH OPENING"
    end
    status.Text = state

    local domainName = definitions[id] and definitions[id].Domain
    local domainButton = actionFrame:FindFirstChild("DOMAIN")
    if domainButton then
        domainButton.Text = domainName and "DOMAIN" or "NO DOMAIN"
    end

    for i = 1, 4 do
        clashButtons[i].Text = i.." • "..({"CRUSH","COUNTER","FEINT","BREAK"})[i]
    end
end

for _, attr in ipairs({
    "Awakening","CharacterId","CharacterName","CharacterTitle","CharacterName","CharacterTitle","UniqueState",
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

if player.Character then bindHumanoid(player.Character) end
player.CharacterAdded:Connect(bindHumanoid)
update()

local keyActions = {
    [Enum.KeyCode.R]="Heavy",
    [Enum.KeyCode.Q]="Dash",
    [Enum.KeyCode.F]="BlockStart",
    [Enum.KeyCode.E]="Dodge",
    [Enum.KeyCode.T]="Grab",
    [Enum.KeyCode.Z]="Special",
    [Enum.KeyCode.X]="Skill",
    [Enum.KeyCode.G]="Awaken",
    [Enum.KeyCode.H]="Domain",
    [Enum.KeyCode.J]="OneTime"
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        combatAction:FireServer("M1")
        return
    end
    local clashKeyMap = {
        [Enum.KeyCode.One]=1,
        [Enum.KeyCode.Two]=2,
        [Enum.KeyCode.Three]=3,
        [Enum.KeyCode.Four]=4
    }
    local clashMove = clashKeyMap[input.KeyCode]
    if clashMove then
        if player:GetAttribute("InClash") then combatAction:FireServer("ClashMove", clashMove) end
        return
    end
    local action = keyActions[input.KeyCode]
    if action then combatAction:FireServer(action) end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        combatAction:FireServer("BlockEnd")
    end
end)

local function burst(position, size, transparency, duration)
    if typeof(position) ~= "Vector3" then return end
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
    part.Transparency = transparency
    part.CFrame = CFrame.new(position)
    part.Parent = workspace.CurrentCamera
    local tween = TweenService:Create(part, TweenInfo.new(duration), {
        Size=Vector3.new(size*2.8, size*2.8, size*2.8),
        Transparency=1
    })
    tween:Play()
    Debris:AddItem(part, duration + 0.1)
end

combatFX.OnClientEvent:Connect(function(kind, position)
    if typeof(position) ~= "Vector3" then return end
    if kind == "BlackFlash" then
        burst(position, 2, 0.05, 0.18)
    elseif kind == "PerfectBlock" then
        burst(position, 1.5, 0.1, 0.12)
    elseif kind == "Hit" then
        burst(position, 0.8, 0.25, 0.09)
    elseif kind == "Awakening" or kind == "CharacterAwakening" then
        burst(position, 3, 0.18, 0.25)
    elseif kind == "DomainStart" or kind == "DomainClashStart" then
        burst(position, 5, 0.55, 0.45)
    elseif kind == "OneTimeAttack" then
        burst(position, 7, 0.3, 0.5)
    else
        burst(position, 2.5, 0.25, 0.2)
    end
end)

clashEvent.OnClientEvent:Connect(function(event, payload)
    payload = payload or {}
    if event == "ClashStart" or event == "ClashReset" then
        clashFrame.Visible = true
        status.Text = "DOMAIN CLASH • ROUND "..tostring(payload.round or 1)
    elseif event == "ClashLocked" then
        status.Text = "CLASH LOCKED • WAIT"
    elseif event == "ClashPressure" then
        status.Text = "CLASH PRESSURE "..tostring(payload.value or payload.opponent or 0)
    elseif event == "ClashNeutral" then
        status.Text = "CLASH NEUTRAL • RESET"
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