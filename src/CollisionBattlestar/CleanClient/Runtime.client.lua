--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("CBS_Remotes", 15)

local function new(className, parent)
    local object = Instance.new(className)
    object.Parent = parent
    return object
end

local gui = new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "CollisionBattlestarHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local safe = new("Frame", gui)
safe.Name = "Safe"
safe.Size = UDim2.fromScale(1, 1)
safe.BackgroundTransparency = 1

local function round(object, radius)
    local corner = new("UICorner", object)
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function stroke(object, transparency)
    local outline = new("UIStroke", object)
    outline.Transparency = transparency or 0.35
    outline.Thickness = 1
    return outline
end

local function label(parent, name, text, size, position, textSize)
    local object = new("TextLabel", parent)
    object.Name = name
    object.Text = text
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize or 14
    object.TextColor3 = Color3.fromRGB(237, 243, 250)
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    return object
end

local function button(parent, name, text, size, position, background)
    local object = new("TextButton", parent)
    object.Name = name
    object.Text = text
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = background
    object.TextColor3 = Color3.fromRGB(240, 246, 255)
    object.Font = Enum.Font.GothamBold
    object.TextSize = 13
    object.AutoButtonColor = true
    round(object, 12)
    stroke(object, 0.45)
    return object
end

local header = new("Frame", safe)
header.Name = "Header"
header.Size = UDim2.fromOffset(310, 86)
header.Position = UDim2.fromOffset(14, 12)
header.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
header.BackgroundTransparency = 0.08
round(header, 14)
stroke(header)

local title = label(header, "Title", "COLLISION BATTLESTAR", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 7), 15)
title.TextColor3 = Color3.fromRGB(90, 215, 255)

local healthText = label(header, "Health", "HP 100 / 100", UDim2.fromOffset(126, 22), UDim2.fromOffset(12, 33), 13)
local creditsText = label(header, "Credits", "CREDITS 0", UDim2.fromOffset(145, 22), UDim2.fromOffset(153, 33), 13)

local healthBack = new("Frame", header)
healthBack.Size = UDim2.new(1, -24, 0, 8)
healthBack.Position = UDim2.fromOffset(12, 61)
healthBack.BackgroundColor3 = Color3.fromRGB(45, 54, 68)
round(healthBack, 6)

local healthFill = new("Frame", healthBack)
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(70, 225, 160)
round(healthFill, 6)

local wavePanel = new("Frame", safe)
wavePanel.Name = "Wave"
wavePanel.Size = UDim2.fromOffset(300, 72)
wavePanel.AnchorPoint = Vector2.new(0.5, 0)
wavePanel.Position = UDim2.new(0.5, 0, 0, 14)
wavePanel.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
wavePanel.BackgroundTransparency = 0.08
round(wavePanel, 14)
stroke(wavePanel)

local waveText = label(wavePanel, "WaveText", "WAVE 01", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 7), 22)
waveText.TextXAlignment = Enum.TextXAlignment.Center
local phaseText = label(wavePanel, "Phase", "STARTING", UDim2.new(0.5, -12, 0, 24), UDim2.fromOffset(12, 40), 11)
phaseText.TextXAlignment = Enum.TextXAlignment.Left
phaseText.TextColor3 = Color3.fromRGB(150, 165, 185)
local hostileText = label(wavePanel, "Hostiles", "5 HOSTILES", UDim2.new(0.5, -12, 0, 24), UDim2.new(0.5, 0, 0, 40), 11)
hostileText.TextXAlignment = Enum.TextXAlignment.Right
hostileText.TextColor3 = Color3.fromRGB(255, 215, 110)

local elite = new("Frame", safe)
elite.Name = "Elite"
elite.Size = UDim2.fromOffset(280, 42)
elite.AnchorPoint = Vector2.new(0.5, 0)
elite.Position = UDim2.new(0.5, 0, 0, 92)
elite.BackgroundColor3 = Color3.fromRGB(112, 27, 38)
elite.Visible = false
round(elite, 11)
stroke(elite, 0.2)
local eliteText = label(elite, "Text", "ELITE TARGET", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 14)
eliteText.TextXAlignment = Enum.TextXAlignment.Center
eliteText.TextColor3 = Color3.fromRGB(255, 236, 238)

local nav = new("Frame", safe)
nav.Name = "Navigation"
nav.Size = UDim2.fromOffset(208, 44)
nav.Position = UDim2.new(1, -222, 0, 12)
nav.BackgroundTransparency = 1
local navLayout = new("UIListLayout", nav)
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
navLayout.Padding = UDim.new(0, 6)

local menuButton = button(nav, "Menu", "MENU", UDim2.fromOffset(64, 42), UDim2.fromOffset(), Color3.fromRGB(25, 32, 44))
local shopButton = button(nav, "Shop", "SHOP", UDim2.fromOffset(64, 42), UDim2.fromOffset(), Color3.fromRGB(25, 32, 44))
local echoButton = button(nav, "Echo", "ECHO", UDim2.fromOffset(64, 42), UDim2.fromOffset(), Color3.fromRGB(25, 32, 44))

local actionBar = new("Frame", safe)
actionBar.Name = "Actions"
actionBar.Size = UDim2.fromOffset(230, 104)
actionBar.AnchorPoint = Vector2.new(1, 1)
actionBar.Position = UDim2.new(1, -16, 1, -18)
actionBar.BackgroundTransparency = 1

local attackButton = button(actionBar, "Attack", "ATTACK", UDim2.fromOffset(118, 96), UDim2.fromOffset(112, 0), Color3.fromRGB(40, 92, 125))
attackButton.TextSize = 18
local dashButton = button(actionBar, "Dash", "DASH", UDim2.fromOffset(98, 52), UDim2.fromOffset(0, 22), Color3.fromRGB(54, 70, 92))
dashButton.TextSize = 15

local comboText = label(actionBar, "Combo", "", UDim2.fromOffset(105, 22), UDim2.fromOffset(8, 0), 11)
comboText.TextXAlignment = Enum.TextXAlignment.Center
comboText.TextColor3 = Color3.fromRGB(95, 215, 255)

local toast = new("TextLabel", safe)
toast.Name = "Toast"
toast.Size = UDim2.fromOffset(340, 46)
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -26)
toast.BackgroundColor3 = Color3.fromRGB(18, 23, 32)
toast.BackgroundTransparency = 0.08
toast.TextColor3 = Color3.fromRGB(235, 242, 250)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 13
toast.Visible = false
round(toast, 11)
stroke(toast, 0.45)

local center = new("Frame", safe)
center.Name = "Panels"
center.Size = UDim2.fromOffset(430, 470)
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.Position = UDim2.fromScale(0.5, 0.52)
center.BackgroundColor3 = Color3.fromRGB(18, 23, 32)
center.BackgroundTransparency = 0.04
center.Visible = false
round(center, 16)
stroke(center, 0.28)

local panelTitle = label(center, "PanelTitle", "MENU", UDim2.new(1, -70, 0, 30), UDim2.fromOffset(18, 14), 20)
panelTitle.TextColor3 = Color3.fromRGB(95, 215, 255)
local closeButton = button(center, "Close", "CLOSE", UDim2.fromOffset(70, 34), UDim2.new(1, -86, 0, 12), Color3.fromRGB(38, 46, 60))

local content = new("ScrollingFrame", center)
content.Name = "Content"
content.Size = UDim2.new(1, -28, 1, -70)
content.Position = UDim2.fromOffset(14, 58)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
local contentLayout = new("UIListLayout", content)
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = content

local connecting = new("TextLabel", safe)
connecting.Size = UDim2.fromOffset(420, 42)
connecting.AnchorPoint = Vector2.new(0.5, 0)
connecting.Position = UDim2.new(0.5, 0, 0, 174)
connecting.BackgroundTransparency = 1
connecting.Text = "CONNECTING TO COLLISION CORE..."
connecting.TextColor3 = Color3.fromRGB(145, 164, 186)
connecting.Font = Enum.Font.GothamBold
connecting.TextSize = 13
connecting.Visible = true

local firstSession = new("Frame", safe)
firstSession.Name = "Onboarding"
firstSession.Size = UDim2.fromOffset(440, 300)
firstSession.AnchorPoint = Vector2.new(0.5, 0.5)
firstSession.Position = UDim2.fromScale(0.5, 0.52)
firstSession.BackgroundColor3 = Color3.fromRGB(18, 23, 32)
firstSession.BackgroundTransparency = 0.02
round(firstSession, 18)
stroke(firstSession, 0.25)
local onboardingTitle = label(firstSession, "Title", "THE COLLISION HAS BEGUN", UDim2.new(1, -36, 0, 34), UDim2.fromOffset(18, 18), 22)
onboardingTitle.TextColor3 = Color3.fromRGB(95, 215, 255)
local onboardingBody = label(firstSession, "Body", "FIGHT THE WAVES
HUNT THE RED ELITE
EARN CREDITS
UPGRADE YOUR DAMAGE
BRING A FRIEND ECHO", UDim2.new(1, -36, 0, 150), UDim2.fromOffset(18, 66), 15)
onboardingBody.TextColor3 = Color3.fromRGB(177, 191, 210)
onboardingBody.TextYAlignment = Enum.TextYAlignment.Top
onboardingBody.TextWrapped = true
local enterButton = button(firstSession, "Enter", "ENTER ARENA", UDim2.fromOffset(190, 46), UDim2.new(0.5, -95, 1, -62), Color3.fromRGB(42, 115, 150))
enterButton.TextSize = 15

local state = nil
local initialized = false
local toastToken = 0
local dashToken = 0

local function showToast(message, duration)
    toastToken += 1
    local token = toastToken
    toast.Text = message
    toast.Visible = true
    task.delay(duration or 1.4, function()
        if toastToken == token then
            toast.Visible = false
        end
    end)
end

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function closePanel()
    center.Visible = false
end

local function showMenu()
    closePanel()
    clearContent()
    panelTitle.Text = "MENU"
    local info = new("TextLabel", content)
    info.Size = UDim2.new(1, -8, 0, 90)
    info.BackgroundTransparency = 1
    info.Text = "WAVE SURVIVAL
Every wave adds pressure. The red Elite is the priority target.
Keep moving, chain your attacks, spend Credits between fights."
    info.TextColor3 = Color3.fromRGB(177, 191, 210)
    info.Font = Enum.Font.Gotham
    info.TextSize = 13
    info.TextWrapped = true
    info.TextYAlignment = Enum.TextYAlignment.Top

    local upgrade = button(content, "Upgrade", "UPGRADE DAMAGE", UDim2.new(1, -8, 0, 48), UDim2.fromOffset(), Color3.fromRGB(44, 104, 80))
    upgrade.Activated:Connect(function()
        remotes.Action:FireServer("Upgrade")
    end)

    if state and state.Owner then
        local admin = button(content, "Admin", "OWNER TEST LAB", UDim2.new(1, -8, 0, 48), UDim2.fromOffset(), Color3.fromRGB(99, 44, 52))
        admin.Activated:Connect(function()
            closePanel()
            clearContent()
            center.Visible = true
            panelTitle.Text = "OWNER TEST LAB"
            for _, item in ipairs({
                {"HEAL", "Heal"},
                {"+1000 CREDITS", "Credits"},
                {"CLEAR WAVE", "Clear"},
                {"NEXT WAVE", "NextWave"},
            }) do
                local control = button(content, "Admin_" .. item[2], item[1], UDim2.new(1, -8, 0, 48), UDim2.fromOffset(), Color3.fromRGB(88, 46, 54))
                control.Activated:Connect(function()
                    remotes.Action:FireServer("Admin", item[2])
                end)
            end
        end)
    end

    center.Visible = true
end

local function showShop()
    closePanel()
    clearContent()
    panelTitle.Text = "SHOP"
    if not state then
        return
    end

    local upgrade = button(content, "Upgrade", "UPGRADE DAMAGE • " .. tostring(50 * (2 ^ math.min(state.DamageLevel, 10))) .. " CREDITS", UDim2.new(1, -8, 0, 48), UDim2.fromOffset(), Color3.fromRGB(44, 104, 80))
    upgrade.Activated:Connect(function()
        remotes.Action:FireServer("Upgrade")
    end)

    for _, skin in ipairs(state.Skins or {}) do
        local text = if skin.Owned
            then (skin.Equipped and "EQUIPPED • " or "EQUIP • ") .. skin.Name
            else "BUY • " .. skin.Name .. " • " .. tostring(skin.Price)
        local colorValue = if skin.Equipped then Color3.fromRGB(42, 115, 150)
            elseif skin.Owned then Color3.fromRGB(42, 72, 92)
            else Color3.fromRGB(31, 40, 52)
        local control = button(content, "Skin_" .. skin.Id, text, UDim2.new(1, -8, 0, 54), UDim2.fromOffset(), colorValue)
        control.Activated:Connect(function()
            if skin.Owned then
                remotes.Action:FireServer("EquipSkin", skin.Id)
            else
                remotes.Action:FireServer("BuySkin", skin.Id)
            end
        end)
    end

    center.Visible = true
end

local function renderFriends(friends)
    clearContent()
    panelTitle.Text = "FRIEND ECHO"
    local info = new("TextLabel", content)
    info.Size = UDim2.new(1, -8, 0, 64)
    info.BackgroundTransparency = 1
    info.Text = "Choose a class, then summon an offline friend as your AI ally.
A real friend joining this server disables their Echo."
    info.TextColor3 = Color3.fromRGB(177, 191, 210)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.TextWrapped = true
    info.TextYAlignment = Enum.TextYAlignment.Top

    for _, classId in ipairs({"Vanguard", "Striker", "Guardian", "Support"}) do
        local control = button(content, "Class_" .. classId, classId, UDim2.new(1, -8, 0, 42), UDim2.fromOffset(), Color3.fromRGB(31, 48, 65))
        control.Activated:Connect(function()
            remotes.Action:FireServer("SetEchoClass", classId)
            showToast("Echo class: " .. classId, 1)
        end)
    end

    for _, friend in ipairs(friends or {}) do
        local control = button(content, "Friend_" .. tostring(friend.UserId), friend.Online and "ONLINE • " .. friend.DisplayName or "SUMMON • " .. friend.DisplayName, UDim2.new(1, -8, 0, 48), UDim2.fromOffset(), friend.Online and Color3.fromRGB(42, 46, 56) or Color3.fromRGB(42, 96, 124))
        control.AutoButtonColor = not friend.Online
        if not friend.Online then
            control.Activated:Connect(function()
                local classId = if state then state.EchoClass else "Vanguard"
                remotes.Action:FireServer("SummonEcho", friend.UserId, classId)
            end)
        end
    end

    if state and state.EchoActive then
        local dismiss = button(content, "Dismiss", "DISMISS ACTIVE ECHO", UDim2.new(1, -8, 0, 48), UDim2.fromOffset(), Color3.fromRGB(100, 43, 52))
        dismiss.Activated:Connect(function()
            remotes.Action:FireServer("DismissEcho")
        end)
    end

    center.Visible = true
end

local function resize()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local width = camera.ViewportSize.X
    local compact = UserInputService.TouchEnabled and width < 520
    header.Size = UDim2.fromOffset(compact and 220 or 310, 86)
    wavePanel.Size = UDim2.fromOffset(compact and 250 or 300, 72)
    center.Size = UDim2.fromOffset(math.min(430, math.max(270, width - 24)), 470)
    actionBar.Size = UDim2.fromOffset(compact and 224 or 230, compact and 112 or 104)
    attackButton.Size = UDim2.fromOffset(compact and 112 or 118, compact and 104 or 96)
    attackButton.Position = UDim2.fromOffset(compact and 108 or 112, 0)
    dashButton.Size = UDim2.fromOffset(compact and 94 or 98, 52)
    if compact then
        nav.Position = UDim2.new(1, -206, 0, 12)
        nav.Size = UDim2.fromOffset(198, 44)
        for _, child in ipairs(nav:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.fromOffset(60, 42)
                child.TextSize = 10
            end
        end
        header.Position = UDim2.fromOffset(10, 10)
    else
        nav.Position = UDim2.new(1, -222, 0, 12)
        header.Position = UDim2.fromOffset(14, 12)
        for _, child in ipairs(nav:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.fromOffset(64, 42)
                child.TextSize = 13
            end
        end
    end
end

local function updateSnapshot(nextState)
    state = nextState
    initialized = true
    connecting.Visible = not state.Ready

    waveText.Text = string.format("WAVE %02d", math.max(0, state.Wave or 0))
    hostileText.Text = tostring(state.Alive or 0) .. " HOSTILES"
    creditsText.Text = "CREDITS " .. tostring(state.Credits or 0)
    healthText.Text = string.format("HP %d / %d", math.floor(state.Health or 0), math.floor(state.MaxHealth or 100))
    healthFill.Size = UDim2.fromScale(math.clamp((state.Health or 0) / math.max(1, state.MaxHealth or 100), 0, 1), 1)
    phaseText.Text = string.upper(tostring(state.Phase or "WAITING"))
    phaseText.TextColor3 = if state.Phase == "ACTIVE" then Color3.fromRGB(95, 215, 255)
        elseif state.Phase == "CLEARED" then Color3.fromRGB(85, 226, 155)
        else Color3.fromRGB(160, 175, 195)
    elite.Visible = state.Elite == true

    if state.Ready and not connecting.Visible then
        connecting.Visible = false
    end

    if state.Owner then
        menuButton.Text = "MENU"
    end

    resize()
end

attackButton.Activated:Connect(function()
    if remotes then
        remotes.Action:FireServer("Attack")
    end
end)

dashButton.Activated:Connect(function()
    if remotes then
        remotes.Action:FireServer("Dash")
    end
end)

menuButton.Activated:Connect(showMenu)
shopButton.Activated:Connect(showShop)
echoButton.Activated:Connect(function()
    if not state then
        return
    end
    clearContent()
    panelTitle.Text = "FRIEND ECHO"
    local loading = label(content, "Loading", "LOADING FRIENDS...", UDim2.new(1, -8, 0, 40), UDim2.fromOffset(), 13)
    loading.TextColor3 = Color3.fromRGB(145, 164, 186)
    center.Visible = true
    remotes.Action:FireServer("GetFriends")
end)

closeButton.Activated:Connect(closePanel)
enterButton.Activated:Connect(function()
    firstSession.Visible = false
end)

ContextActionService:BindAction("CBS_Attack", function(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        remotes.Action:FireServer("Attack")
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

ContextActionService:BindAction("CBS_Dash", function(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        remotes.Action:FireServer("Dash")
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)

local function healthConnections(character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then
        return
    end
    humanoid.HealthChanged:Connect(function(value)
        if state then
            state.Health = value
            state.MaxHealth = humanoid.MaxHealth
            healthText.Text = string.format("HP %d / %d", math.floor(value), math.floor(humanoid.MaxHealth))
            healthFill.Size = UDim2.fromScale(math.clamp(value / math.max(1, humanoid.MaxHealth), 0, 1), 1)
        end
    end)
end

player.CharacterAdded:Connect(healthConnections)
if player.Character then
    task.spawn(healthConnections, player.Character)
end

if remotes then
    remotes.State.OnClientEvent:Connect(function(kind, a, b, c)
        if kind == "Snapshot" then
            updateSnapshot(a)
        elseif kind == "Toast" then
            showToast(tostring(a), 1.6)
        elseif kind == "Attack" then
            local combo = math.clamp(tonumber(a) or 1, 1, 3)
            comboText.Text = "COMBO " .. tostring(combo)
            comboText.TextColor3 = b and Color3.fromRGB(95, 215, 255) or Color3.fromRGB(150, 165, 185)
            task.delay(0.55, function()
                comboText.Text = ""
            end)
        elseif kind == "Hit" then
            showToast("HIT • " .. tostring(math.floor(tonumber(a) or 0)), 0.7)
        elseif kind == "Dash" then
            dashToken += 1
            local token = dashToken
            local duration = math.max(0, tonumber(a) or 0)
            local began = os.clock()
            task.spawn(function()
                while dashToken == token do
                    local remaining = math.max(0, duration - (os.clock() - began))
                    dashButton.Text = remaining > 0 and ("DASH " .. string.format("%.1f", remaining)) or "DASH"
                    if remaining <= 0 then
                        break
                    end
                    task.wait(0.05)
                end
                if dashToken == token then
                    dashButton.Text = "DASH"
                end
            end)
        elseif kind == "Friends" then
            renderFriends(a)
        elseif kind == "Echo" then
            if a == "Summoned" then
                showToast("FRIEND ECHO ACTIVE", 1.6)
            elseif a == "Dismissed" then
                showToast("ECHO DISMISSED", 1.3)
            end
        end
    end)
    remotes.Action:FireServer("RequestState")
else
    connecting.Text = "SERVER CONNECTION FAILED"
    showToast("Server connection failed. Rejoin the experience.", 4)
end

task.delay(2.5, function()
    if not initialized then
        connecting.Text = "WAITING FOR SERVER..."
        connecting.TextColor3 = Color3.fromRGB(255, 205, 105)
    end
end)

task.delay(6, function()
    if not initialized then
        connecting.Text = "RECONNECT REQUIRED"
        connecting.TextColor3 = Color3.fromRGB(255, 100, 110)
    end
end)

resize()
