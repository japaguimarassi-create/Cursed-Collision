--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
if not remotes then
    error("Collision Battlestar HUD: ReplicatedStorage.Remotes not available")
end

local State = remotes:WaitForChild("State", 15)
local Travel = remotes:WaitForChild("Travel", 15)
local AdminAction = remotes:WaitForChild("AdminAction", 15)
if not State or not Travel or not AdminAction then
    error("Collision Battlestar HUD: required remotes unavailable")
end

local Controller = {}
local initialized = false

local waveLabel: TextLabel
local enemyLabel: TextLabel
local moneyLabel: TextLabel
local levelLabel: TextLabel
local rewardLabel: TextLabel
local travelButton: TextButton
local zoneLabel: TextLabel
local rootGui: ScreenGui

local function rounded(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: Instance, transparency: number?)
    local s = Instance.new("UIStroke")
    s.Color = Config.UI.Stroke
    s.Thickness = 1
    s.Transparency = transparency or 0.2
    s.Parent = parent
end

local function text(parent: Instance, value: string, size: number, muted: boolean?)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextColor3 = if muted then Config.UI.Muted else Config.UI.Text
    t.Font = Enum.Font.GothamBold
    t.TextSize = size
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Parent = parent
    return t
end

local function button(parent: Instance, name: string, label: string, size: UDim2)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.BackgroundColor3 = Config.UI.Surface
    b.BackgroundTransparency = 0.04
    b.Text = label
    b.TextColor3 = Config.UI.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = true
    b.Parent = parent
    rounded(b, 12)
    stroke(b, 0.25)
    return b
end

local function panel(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2?)
    local p = Instance.new("Frame")
    p.Size = size
    p.Position = position
    p.AnchorPoint = anchor or Vector2.new(0, 0)
    p.BackgroundColor3 = Config.UI.Surface
    p.BackgroundTransparency = 0.08
    p.Parent = parent
    rounded(p, 16)
    stroke(p, 0.24)
    return p
end

local function addUIScale(gui: ScreenGui)
    local scale = Instance.new("UIScale")
    scale.Name = "ResponsiveScale"
    scale.Parent = gui

    local function refresh()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local viewport = camera.ViewportSize
        local factor = math.min(viewport.X / 1100, viewport.Y / 650)
        scale.Scale = math.clamp(factor, 0.78, 1.08)
    end

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refresh)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
    end
    refresh()
end

function Controller:Init()
    if initialized and rootGui and rootGui.Parent then
        return
    end
    initialized = true

    local playerGui = player:WaitForChild("PlayerGui")
    local previous = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if previous then
        previous:Destroy()
    end

    rootGui = Instance.new("ScreenGui")
    rootGui.Name = "CollisionBattlestarHUD"
    rootGui.ResetOnSpawn = false
    rootGui.DisplayOrder = 50
    rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    rootGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    rootGui.Parent = playerGui
    addUIScale(rootGui)

    local brand = panel(rootGui, UDim2.fromOffset(248, 62), UDim2.fromOffset(18, 18))
    local title = text(brand, "COLLISION BATTLESTAR", 13)
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.fromOffset(11, 5)
    local subtitle = text(brand, "PVE COMBAT", 9, true)
    subtitle.Size = UDim2.new(1, -20, 0, 20)
    subtitle.Position = UDim2.fromOffset(11, 31)

    local status = panel(rootGui, UDim2.fromOffset(290, 62), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0))
    status.Position = UDim2.fromScale(0.5, 0)
    local waveBlock = text(status, "WAVE 0", 22)
    waveBlock.Size = UDim2.new(0.5, -10, 0, 40)
    waveBlock.Position = UDim2.fromOffset(10, 4)
    waveLabel = waveBlock
    local enemyBlock = text(status, "0 ENEMIES", 10, true)
    enemyBlock.Size = UDim2.new(0.5, -10, 0, 40)
    enemyBlock.Position = UDim2.new(0.5, 0, 0, 4)
    enemyBlock.TextXAlignment = Enum.TextXAlignment.Right
    enemyLabel = enemyBlock

    local economy = panel(rootGui, UDim2.fromOffset(228, 62), UDim2.new(1, -18, 0, 18), Vector2.new(1, 0))
    moneyLabel = text(economy, "0 C", 17)
    moneyLabel.Size = UDim2.new(1, -20, 0, 27)
    moneyLabel.Position = UDim2.fromOffset(10, 4)
    local stats = text(economy, "DMG 0  •  DEF 0  •  SPD 0", 9, true)
    stats.Size = UDim2.new(1, -20, 0, 20)
    stats.Position = UDim2.fromOffset(10, 32)
    levelLabel = stats

    local feedback = panel(rootGui, UDim2.fromOffset(360, 54), UDim2.new(0.5, 0, 1, -34), Vector2.new(0.5, 1))
    rewardLabel = text(feedback, "Prepare-se.", 11, true)
    rewardLabel.Size = UDim2.new(1, -18, 1, -8)
    rewardLabel.Position = UDim2.fromOffset(9, 4)
    rewardLabel.TextXAlignment = Enum.TextXAlignment.Center

    zoneLabel = text(rootGui, "PVE", 9, true)
    zoneLabel.Size = UDim2.fromOffset(130, 22)
    zoneLabel.Position = UDim2.new(0, 20, 1, -210)

    local actions = Instance.new("Frame")
    actions.Name = "Navigation"
    actions.BackgroundTransparency = 1
    actions.Size = UDim2.fromOffset(180, 52)
    actions.Position = UDim2.new(1, -198, 1, -190)
    actions.Parent = rootGui

    travelButton = button(actions, "BattlegroundsButton", "BATTLEGROUNDS", UDim2.fromScale(1, 1))
    travelButton.TextSize = 10

    local function refresh()
        local credits = player:GetAttribute("Credits") or 0
        local damage = player:GetAttribute("DamageLevel") or 0
        local defense = player:GetAttribute("DefenseLevel") or 0
        local speed = player:GetAttribute("SpeedLevel") or 0
        moneyLabel.Text = ("%d C"):format(credits)
        levelLabel.Text = ("DMG %d  •  DEF %d  •  SPD %d"):format(damage, defense, speed)
    end

    for _, name in ipairs({"Credits", "DamageLevel", "DefenseLevel", "SpeedLevel"}) do
        player:GetAttributeChangedSignal(name):Connect(refresh)
    end
    refresh()

    local function setZone(zone: string)
        zoneLabel.Text = zone == "PvP" and "PVP BATTLEGROUNDS" or "PVE"
        travelButton.Text = zone == "PvP" and "RETURN TO PVE" or "BATTLEGROUNDS"
        travelButton.TextColor3 = zone == "PvP" and Config.UI.Danger or Config.UI.Text
    end

    travelButton.Activated:Connect(function()
        local zone = player:GetAttribute("Zone") or "PvE"
        Travel:FireServer(zone == "PvP" and "PvE" or "PvP")
    end)
    setZone(player:GetAttribute("Zone") or "PvE")
    player:GetAttributeChangedSignal("Zone"):Connect(function()
        setZone(player:GetAttribute("Zone") or "PvE")
    end)

    local function createAdmin()
        if player:GetAttribute("IsOwner") ~= true then
            return
        end

        local adminButton = button(rootGui, "AdminMenuButton", "ADMIN MENU", UDim2.fromOffset(150, 46))
        adminButton.Position = UDim2.new(0, 20, 1, -154)
        adminButton.BackgroundColor3 = Config.UI.Danger
        adminButton.TextSize = 10

        local adminPanel = panel(rootGui, UDim2.fromOffset(272, 285), UDim2.new(0, 20, 1, -470))
        adminPanel.Visible = false

        local title = text(adminPanel, "ADMIN CONTROL", 15)
        title.Size = UDim2.new(1, -30, 0, 32)
        title.Position = UDim2.fromOffset(15, 10)
        local hint = text(adminPanel, "SERVER AUTHORITY • OWNER", 8, true)
        hint.Size = UDim2.new(1, -30, 0, 18)
        hint.Position = UDim2.fromOffset(15, 38)

        local list = Instance.new("Frame")
        list.BackgroundTransparency = 1
        list.Size = UDim2.new(1, -24, 1, -72)
        list.Position = UDim2.fromOffset(12, 62)
        list.Parent = adminPanel

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = list

        local function action(label: string, key: string, order: number)
            local b = button(list, "Action_" .. key, label, UDim2.new(1, 0, 0, 38))
            b.LayoutOrder = order
            b.Activated:Connect(function()
                AdminAction:FireServer(key)
            end)
        end

        action("NEXT WAVE", "NextWave", 1)
        action("+1000 CREDITS", "Reward", 2)
        action("HEAL PLAYER", "Heal", 3)
        action("CLEAR ENEMIES", "Clear", 4)

        adminButton.Activated:Connect(function()
            adminPanel.Visible = not adminPanel.Visible
        end)
    end

    createAdmin()

    State.OnClientEvent:Connect(function(kind: string, a, b)
        if kind == "WaveIntermission" then
            waveLabel.Text = "NEXT WAVE"
            enemyLabel.Text = ("%ds"):format(tonumber(a) or 0)
            enemyLabel.TextColor3 = Config.UI.Warning
        elseif kind == "WaveStart" then
            waveLabel.Text = ("WAVE %d"):format(tonumber(a) or 0)
            enemyLabel.Text = ("%d ENEMIES"):format(tonumber(b) or 0)
            enemyLabel.TextColor3 = Config.UI.Text
            rewardLabel.Text = "ELITE DETECTED"
            rewardLabel.TextColor3 = Config.UI.Danger
        elseif kind == "WaveState" then
            waveLabel.Text = ("WAVE %d"):format(tonumber(a) or 0)
            enemyLabel.Text = ("%d ENEMIES"):format(tonumber(b) or 0)
        elseif kind == "Reward" then
            rewardLabel.Text = ("+%d C"):format(tonumber(a) or 0)
            rewardLabel.TextColor3 = Config.UI.Good
        elseif kind == "WaveReward" then
            rewardLabel.Text = ("WAVE %d CLEAR  •  +%d C"):format(tonumber(b) or 0, tonumber(a) or 0)
            rewardLabel.TextColor3 = Config.UI.Good
        elseif kind == "WaveClear" then
            enemyLabel.Text = "CLEAR"
            rewardLabel.TextColor3 = Config.UI.Good
        elseif kind == "ShopMessage" then
            rewardLabel.Text = tostring(a)
            rewardLabel.TextColor3 = Config.UI.Warning
        elseif kind == "Zone" then
            setZone(tostring(a))
        elseif kind == "PvpHit" then
            rewardLabel.Text = ("-%d HP"):format(tonumber(a) or 0)
            rewardLabel.TextColor3 = Config.UI.Warning
        elseif kind == "Attack" then
            TweenService:Create(rewardLabel, TweenInfo.new(0.08), {TextTransparency = 0.15}):Play()
            TweenService:Create(rewardLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        end
    end)

    player:GetAttributeChangedSignal("IsOwner"):Connect(function()
        if player:GetAttribute("IsOwner") == true and not rootGui:FindFirstChild("AdminMenuButton") then
            createAdmin()
        end
    end)

    if UserInputService.TouchEnabled then
        rewardLabel.Text = "Use os controles na tela para lutar."
    else
        rewardLabel.Text = "M1 para atacar  •  Shift para dash."
    end
end

return Controller
