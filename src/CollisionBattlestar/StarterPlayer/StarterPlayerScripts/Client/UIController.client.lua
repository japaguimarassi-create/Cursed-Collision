--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local State = remotes:WaitForChild("State") :: RemoteEvent
local Travel = remotes:WaitForChild("Travel") :: RemoteEvent
local AdminAction = remotes:WaitForChild("AdminAction") :: RemoteEvent

local Controller = {}

local waveLabel: TextLabel
local enemyLabel: TextLabel
local moneyLabel: TextLabel
local levelLabel: TextLabel
local rewardLabel: TextLabel
local travelButton: TextButton

local function rounded(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: Instance)
    local s = Instance.new("UIStroke")
    s.Color = Config.UI.Stroke
    s.Thickness = 1
    s.Transparency = 0.2
    s.Parent = parent
end

local function text(parent: Instance, value: string, size: number)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextColor3 = Config.UI.Text
    t.Font = Enum.Font.GothamBold
    t.TextSize = size
    t.TextXAlignment = Enum.TextXAlignment.Center
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Parent = parent
    return t
end

local function panel(parent: Instance, size: UDim2, position: UDim2)
    local p = Instance.new("Frame")
    p.Size = size
    p.Position = position
    p.BackgroundColor3 = Config.UI.Surface
    p.BackgroundTransparency = 0.06
    p.Parent = parent
    rounded(p, 14)
    stroke(p)
    return p
end

function Controller:Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PvEHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local top = panel(gui, UDim2.fromOffset(330, 96), UDim2.fromScale(0.5, 0.035))
    top.AnchorPoint = Vector2.new(0.5, 0)

    waveLabel = text(top, "WAVE 0", 24)
    waveLabel.Size = UDim2.new(0.5, 0, 0, 44)
    waveLabel.Position = UDim2.fromOffset(8, 3)

    enemyLabel = text(top, "INIMIGOS 0", 12)
    enemyLabel.Size = UDim2.new(0.5, -8, 0, 44)
    enemyLabel.Position = UDim2.new(0.5, 0, 0, 3)
    enemyLabel.TextColor3 = Config.UI.Muted

    moneyLabel = text(top, "0 C", 14)
    moneyLabel.Size = UDim2.new(0.5, -8, 0, 34)
    moneyLabel.Position = UDim2.fromScale(0, 0.53)
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Left

    levelLabel = text(top, "D 0   DEF 0   SPD 0", 11)
    levelLabel.Size = UDim2.new(0.5, -8, 0, 34)
    levelLabel.Position = UDim2.fromScale(0.5, 0.53)
    levelLabel.TextColor3 = Config.UI.Muted

    local rewardPanel = panel(gui, UDim2.fromOffset(300, 54), UDim2.fromScale(0.5, 0.87))
    rewardPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    rewardLabel = text(rewardPanel, "Derrote inimigos para ganhar créditos.", 12)
    rewardLabel.Size = UDim2.fromScale(1, 1)
    rewardLabel.Font = Enum.Font.GothamMedium
    rewardLabel.TextColor3 = Config.UI.Muted

    travelButton = Instance.new("TextButton")
    travelButton.Name = "BattlegroundsButton"
    travelButton.Size = UDim2.fromOffset(152, 46)
    travelButton.Position = UDim2.fromScale(0.03, 0.82)
    travelButton.BackgroundColor3 = Config.UI.Surface
    travelButton.BackgroundTransparency = 0.06
    travelButton.Text = "BATTLEGROUNDS"
    travelButton.TextColor3 = Config.UI.Text
    travelButton.Font = Enum.Font.GothamBold
    travelButton.TextSize = 12
    travelButton.AutoButtonColor = true
    travelButton.Parent = gui
    rounded(travelButton, 13)
    stroke(travelButton)

    local zoneLabel = text(gui, "PVE", 10)
    zoneLabel.Name = "Zone"
    zoneLabel.Size = UDim2.fromOffset(120, 26)
    zoneLabel.Position = UDim2.fromScale(0.03, 0.78)
    zoneLabel.TextXAlignment = Enum.TextXAlignment.Left
    zoneLabel.TextColor3 = Config.UI.Muted
    zoneLabel.Parent = gui

    local function refresh()
        local credits = player:GetAttribute("Credits") or 0
        local damage = player:GetAttribute("DamageLevel") or 0
        local defense = player:GetAttribute("DefenseLevel") or 0
        local speed = player:GetAttribute("SpeedLevel") or 0
        moneyLabel.Text = ("%d C"):format(credits)
        levelLabel.Text = ("D %d   DEF %d   SPD %d"):format(damage, defense, speed)
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

    if player:GetAttribute("IsOwner") == true then
        local adminButton = Instance.new("TextButton")
        adminButton.Name = "AdminMenuButton"
        adminButton.Size = UDim2.fromOffset(140, 42)
        adminButton.Position = UDim2.fromScale(0.03, 0.72)
        adminButton.BackgroundColor3 = Config.UI.Danger
        adminButton.BackgroundTransparency = 0.08
        adminButton.Text = "ADMIN MENU"
        adminButton.TextColor3 = Config.UI.Text
        adminButton.Font = Enum.Font.GothamBold
        adminButton.TextSize = 11
        adminButton.Parent = gui
        rounded(adminButton, 12)
        stroke(adminButton)

        local adminPanel = panel(gui, UDim2.fromOffset(250, 230), UDim2.fromScale(0.03, 0.5))
        adminPanel.Visible = false
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Parent = adminPanel

        local title = text(adminPanel, "ADMIN MENU", 16)
        title.Size = UDim2.new(1, -20, 0, 32)
        title.LayoutOrder = 0

        local function adminAction(label: string, action: string)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -24, 0, 38)
            button.BackgroundColor3 = Config.UI.Surface2
            button.Text = label
            button.TextColor3 = Config.UI.Text
            button.Font = Enum.Font.GothamBold
            button.TextSize = 11
            button.Parent = adminPanel
            rounded(button, 9)
            button.Activated:Connect(function()
                AdminAction:FireServer(action)
            end)
        end

        adminAction("NEXT WAVE", "NextWave")
        adminAction("+1000 CREDITS", "Reward")
        adminAction("HEAL", "Heal")
        adminAction("CLEAR ENEMIES", "Clear")

        adminButton.Activated:Connect(function()
            adminPanel.Visible = not adminPanel.Visible
        end)
    end

    State.OnClientEvent:Connect(function(kind: string, a, b)
        if kind == "WaveIntermission" then
            waveLabel.Text = "PRÓXIMA WAVE"
            enemyLabel.Text = ("%ds"):format(tonumber(a) or 0)
            enemyLabel.TextColor3 = Config.UI.Warning
        elseif kind == "WaveStart" then
            waveLabel.Text = ("WAVE %d"):format(tonumber(a) or 0)
            enemyLabel.Text = ("%d INIMIGOS"):format(tonumber(b) or 0)
            enemyLabel.TextColor3 = Config.UI.Text
            rewardLabel.Text = "ELITE VERMELHO = maior ameaça da wave"
            rewardLabel.TextColor3 = Config.UI.Danger
        elseif kind == "WaveState" then
            waveLabel.Text = ("WAVE %d"):format(tonumber(a) or 0)
            enemyLabel.Text = ("%d INIMIGOS"):format(tonumber(b) or 0)
        elseif kind == "Reward" then
            rewardLabel.Text = ("+%d C"):format(tonumber(a) or 0)
            rewardLabel.TextColor3 = Config.UI.Good
            task.delay(0.8, function()
                if rewardLabel.Parent then
                    rewardLabel.Text = "Derrote inimigos para ganhar créditos."
                    rewardLabel.TextColor3 = Config.UI.Muted
                end
            end)
        elseif kind == "WaveReward" then
            rewardLabel.Text = ("WAVE %d CONCLUÍDA  •  +%d C"):format(tonumber(b) or 0, tonumber(a) or 0)
            rewardLabel.TextColor3 = Config.UI.Good
        elseif kind == "WaveClear" then
            enemyLabel.Text = "LIMPA"
        elseif kind == "ShopMessage" then
            rewardLabel.Text = tostring(a)
            rewardLabel.TextColor3 = Config.UI.Warning
            task.delay(1.5, function()
                if rewardLabel.Parent then
                    rewardLabel.Text = "Derrote inimigos para ganhar créditos."
                    rewardLabel.TextColor3 = Config.UI.Muted
                end
            end)
        elseif kind == "Zone" then
            setZone(tostring(a))
        elseif kind == "PvpHit" then
            rewardLabel.Text = ("-%d HP"):format(tonumber(a) or 0)
            rewardLabel.TextColor3 = Config.UI.Warning
        elseif kind == "Attack" then
            TweenService:Create(rewardLabel, TweenInfo.new(0.08), {TextTransparency = 0.15}):Play()
        end
    end)
end

return Controller
