local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatAction = remotes:WaitForChild("CombatAction")
local serverEvent = remotes:WaitForChild("ServerEvent")
local combatFX = remotes:WaitForChild("CombatFX")
local clashEvent = remotes:WaitForChild("ClashEvent")
local selection = remotes:WaitForChild("Selection")

local gui = Instance.new("ScreenGui")
gui.Name = "CursedCollisionUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local top = Instance.new("Frame")
top.Size = UDim2.fromScale(0.34, 0.18)
top.Position = UDim2.fromScale(0.02, 0.03)
top.BackgroundTransparency = 0.28
top.Parent = gui

local characterLabel = Instance.new("TextLabel")
characterLabel.Size = UDim2.fromScale(1, 0.25)
characterLabel.BackgroundTransparency = 1
characterLabel.TextScaled = true
characterLabel.TextXAlignment = Enum.TextXAlignment.Left
characterLabel.Parent = top

local ceBack = Instance.new("Frame")
ceBack.Size = UDim2.fromScale(0.98, 0.2)
ceBack.Position = UDim2.fromScale(0.01, 0.3)
ceBack.Parent = top

local ceFill = Instance.new("Frame")
ceFill.Size = UDim2.fromScale(1, 1)
ceFill.Parent = ceBack

local awBack = Instance.new("Frame")
awBack.Size = UDim2.fromScale(0.98, 0.2)
awBack.Position = UDim2.fromScale(0.01, 0.54)
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
button("BLOCK", "BlockStart", 0.6, 0)
button("DODGE", "Dodge", 0.8, 0)
button("GRAB", "Grab", 0, 0.25)
button("SPECIAL", "Special", 0.2, 0.25)
button("SKILL", "Skill", 0.4, 0.25)
button("AWAKEN", "Awaken", 0.6, 0.25)
button("DOMAIN", "Domain", 0.8, 0.25)
button("ONE TIME", "OneTime", 0, 0.5)

local selectFrame = Instance.new("Frame")
selectFrame.Size = UDim2.fromScale(0.32, 0.28)
selectFrame.Position = UDim2.fromScale(0.02, 0.23)
selectFrame.BackgroundTransparency = 0.3
selectFrame.Parent = gui

local selectTitle = Instance.new("TextLabel")
selectTitle.Size = UDim2.fromScale(1, 0.25)
selectTitle.Text = "CHARACTER"
selectTitle.TextScaled = true
selectTitle.BackgroundTransparency = 1
selectTitle.Parent = selectFrame

local choices = {
    {"YUJI", "Yuji"},
    {"GOJO", "Gojo"},
    {"SUKUNA", "Sukuna"}
}

for i, choice in ipairs(choices) do
    local b = Instance.new("TextButton")
    b.Text = choice[1]
    b.TextScaled = true
    b.Size = UDim2.fromScale(0.3, 0.46)
    b.Position = UDim2.fromScale((i - 1) * 0.33, 0.38)
    b.Parent = selectFrame
    b.Activated:Connect(function()
        selection:FireServer(choice[2])
    end)
end

local clashFrame = Instance.new("Frame")
clashFrame.Size = UDim2.fromScale(0.58, 0.25)
clashFrame.Position = UDim2.fromScale(0.21, 0.36)
clashFrame.BackgroundTransparency = 0.18
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

local function update()
    local ce = player:GetAttribute("CE") or 0
    local maxCE = player:GetAttribute("MaxCE") or 100
    local aw = player:GetAttribute("Awakening") or 0
    characterLabel.Text = (player:GetAttribute("CharacterName") or "Yuji") .. " | " .. (player:GetAttribute("CharacterTitle") or "")
    ceFill.Size = UDim2.fromScale(math.clamp(ce / maxCE, 0, 1), 1)
    awFill.Size = UDim2.fromScale(math.clamp(aw / 100, 0, 1), 1)

    local state = "READY"
    if player:GetAttribute("InClash") then
        state = "DOMAIN CLASH"
    elseif player:GetAttribute("AwakeningActive") then
        state = "AWAKENING"
    elseif player:GetAttribute("DomainActive") then
        state = "DOMAIN"
    end

    status.Text = state

    for i = 1, 4 do
        clashButtons[i].Text = (i .. " • " .. ({"CRUSH","COUNTER","FEINT","BREAK"})[i])
    end
end

for _, attr in ipairs({
    "CE","MaxCE","Awakening","CharacterName","CharacterTitle",
    "InClash","AwakeningActive","DomainActive","LimitlessState","SlashState"
}) do
    player:GetAttributeChangedSignal(attr):Connect(update)
end
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

    if input.KeyCode >= Enum.KeyCode.One and input.KeyCode <= Enum.KeyCode.Four then
        if player:GetAttribute("InClash") then
            combatAction:FireServer("ClashMove", input.KeyCode.Value - Enum.KeyCode.One.Value + 1)
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
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(size, size, size)
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
        burst(position, 2, 0.05, 0.18)
    elseif kind == "PerfectBlock" then
        burst(position, 1.5, 0.1, 0.12)
    elseif kind == "Hit" then
        burst(position, 0.8, 0.25, 0.09)
    elseif kind == "Awakening" or kind == "YujiAwakening" or kind == "GojoAwakening" or kind == "SukunaAwakening" then
        burst(position, 3, 0.18, 0.25)
    elseif kind == "DomainStart" or kind == "DomainClashStart" then
        burst(position, 5, 0.55, 0.45)
    elseif kind == "OneTimeAttack" then
        burst(position, 7, 0.3, 0.5)
    elseif string.find(kind, "Gojo") or string.find(kind, "Sukuna") or string.find(kind, "Yuji") then
        burst(position, 2.5, 0.25, 0.25)
    end
end)

clashEvent.OnClientEvent:Connect(function(event, payload)
    if event == "ClashStart" or event == "ClashReset" then
        clashFrame.Visible = true
        status.Text = "DOMAIN CLASH • ROUND " .. tostring(payload.round or 1)
    elseif event == "ClashLocked" then
        status.Text = "CLASH LOCKED • WAIT"
    elseif event == "ClashPressure" then
        status.Text = "CLASH PRESSURE " .. tostring(payload.value or payload.opponent or 0)
    elseif event == "ClashEnd" then
        clashFrame.Visible = false
        status.Text = "CLASH ENDED"
    end
end)

serverEvent.OnClientEvent:Connect(function(event)
    if event == "BlackFlashWindow" then
        status.Text = "BLACK FLASH WINDOW"
        task.delay(0.25, update)
    elseif event == "DodgeEvaded" then
        status.Text = "DODGED"
        task.delay(0.35, update)
    end
end)
