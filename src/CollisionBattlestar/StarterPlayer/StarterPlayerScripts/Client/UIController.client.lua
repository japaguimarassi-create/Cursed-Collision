--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local rootFolder = script.Parent
local HUD = rootFolder:WaitForChild("HUD", 15)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Root = require(HUD:WaitForChild("Root"))
local Status = require(HUD:WaitForChild("Status"))
local Economy = require(HUD:WaitForChild("Economy"))
local Profile = require(HUD:WaitForChild("Profile"))
local Vitals = require(HUD:WaitForChild("Vitals"))
local Actions = require(HUD:WaitForChild("Actions"))
local Navigation = require(HUD:WaitForChild("Navigation"))
local Feedback = require(HUD:WaitForChild("Feedback"))
local Admin = require(HUD:WaitForChild("Admin"))

local Controller = {}
local initialized = false

local function getRemotes()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if not remotes then
        error("Remotes unavailable")
    end
    local state = remotes:WaitForChild("State", 15)
    local action = remotes:WaitForChild("Action", 15)
    local travel = remotes:WaitForChild("Travel", 15)
    local admin = remotes:WaitForChild("AdminAction", 15)
    if not state or not action or not travel or not admin then
        error("HUD remotes unavailable")
    end
    return state :: RemoteEvent, action :: RemoteEvent, travel :: RemoteEvent, admin :: RemoteEvent
end

local function hideDefaultHealth()
    for _ = 1, 8 do
        local ok = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
        end)
        if ok then
            return
        end
        task.wait(0.1)
    end
end

function Controller:Init()
    if initialized then
        local existing = player.PlayerGui:FindFirstChild("CollisionBattlestarHUD")
        if existing then
            existing.Enabled = true
            player:SetAttribute("CollisionHUDReady", true)
            return existing
        end
        initialized = false
    end

    hideDefaultHealth()
    local stateRemote, actionRemote, travelRemote, adminRemote = getRemotes()
    local gui = Root.Create(player)

    local root = {
        Gui = gui,
        Panel = Root.Pill,
        Pill = Root.Pill,
        Label = Root.Label,
        Button = Root.Button,
        Rounded = Root.Rounded,
        Circle = Root.Circle,
        Stroke = Root.Stroke,
        Progress = Root.Progress,
        AnimateIn = Root.AnimateIn,
    }

    Profile.Mount(root, Config, player)
    local status = Status.Mount(root, Config)
    Economy.Mount(root, Config, player)
    Vitals.Mount(root, Config, player)
    local actions = Actions.Mount(root)
    Navigation.Mount(root, Config, player, travelRemote)
    local feedback = Feedback.Mount(root, Config)
    Admin.Mount(root, Config, player, adminRemote)

    actions.M1.Button.Activated:Connect(function()
        if actions.M1.Activate() then
            actionRemote:FireServer("M1")
        end
    end)

    actions.Dash.Button.Activated:Connect(function()
        if actions.Dash.Activate() then
            actionRemote:FireServer("Dash")
        end
    end)

    local function setWave(wave)
        local value = tonumber(wave) or 0
        status.Wave.Text = ("WAVE %02d"):format(value)
        status.RefreshProgress(value, workspace:GetAttribute("CollisionEnemies") or 0)
    end

    local function setEnemies(enemies)
        local value = tonumber(enemies) or 0
        status.Enemies.Text = ("%d HOSTILES"):format(value)
        status.RefreshProgress(workspace:GetAttribute("CollisionWave") or 0, value)
    end

    stateRemote.OnClientEvent:Connect(function(kind: string, a, b)
        if kind == "WaveIntermission" then
            status.Live.Text = "READY"
            status.Live.TextColor3 = Config.UI.Warning
            status.Countdown.Visible = true
            status.Countdown.Text = ("START IN %ds"):format(tonumber(a) or 0)
            Feedback.Show(feedback, Config, "NEXT WAVE", Config.UI.Warning, 0.9)
        elseif kind == "WaveStart" then
            status.Live.Text = "LIVE"
            status.Live.TextColor3 = Config.UI.Good
            status.Countdown.Visible = false
            setWave(a)
            setEnemies(b)
            Feedback.Show(feedback, Config, "WAVE STARTED", Config.UI.Accent, 0.9)
        elseif kind == "WaveState" then
            status.Live.Text = "LIVE"
            status.Live.TextColor3 = Config.UI.Good
            setWave(a)
            setEnemies(b)
        elseif kind == "Reward" then
            Feedback.Show(feedback, Config, ("+%d CREDITS"):format(tonumber(a) or 0), Config.UI.Good, 0.9)
        elseif kind == "WaveReward" then
            Feedback.Show(feedback, Config, ("WAVE CLEAR  •  +%d"):format(tonumber(a) or 0), Config.UI.Good, 1.4)
        elseif kind == "WaveClear" then
            status.Live.Text = "CLEAR"
            status.Live.TextColor3 = Config.UI.Accent
            status.Countdown.Visible = false
            Feedback.Show(feedback, Config, "AREA CLEAR", Config.UI.Accent, 1.2)
        elseif kind == "ShopMessage" then
            Feedback.Show(feedback, Config, tostring(a), Config.UI.Warning, 1.4)
        elseif kind == "Zone" then
            local pvp = tostring(a) == "PvP"
            status.Live.Text = pvp and "PVP" or "LIVE"
            status.Live.TextColor3 = pvp and Config.UI.Danger or Config.UI.Good
        elseif kind == "PvpHit" then
            Feedback.Show(feedback, Config, ("-%d HP"):format(tonumber(a) or 0), Config.UI.Warning, 0.55)
        elseif kind == "Attack" then
            Feedback.Show(feedback, Config, "STRIKE", Config.UI.Accent, 0.2)
        end
    end)

    workspace:GetAttributeChangedSignal("CollisionWave"):Connect(function()
        setWave(workspace:GetAttribute("CollisionWave") or 0)
    end)

    workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(function()
        setEnemies(workspace:GetAttribute("CollisionEnemies") or 0)
    end)

    setWave(workspace:GetAttribute("CollisionWave") or 0)
    setEnemies(workspace:GetAttribute("CollisionEnemies") or 0)

    player:SetAttribute("CollisionHUDReady", true)
    initialized = true

    task.delay(0.15, function()
        local boot = player.PlayerGui:FindFirstChild("CollisionBattlestarImmediateHUD")
        if boot then
            boot:Destroy()
        end
    end)

    return gui
end

return Controller
