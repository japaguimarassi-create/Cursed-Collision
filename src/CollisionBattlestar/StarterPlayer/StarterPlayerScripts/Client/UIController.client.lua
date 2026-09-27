--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local rootFolder = script.Parent
local HUD = rootFolder:WaitForChild("HUD", 30)

if not HUD then
    error("HUD modules unavailable")
end

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Root = require(HUD:WaitForChild("Root"))
local Status = require(HUD:WaitForChild("Status"))
local Economy = require(HUD:WaitForChild("Economy"))
local Profile = require(HUD:WaitForChild("Profile"))
local Vitals = require(HUD:WaitForChild("Vitals"))
local Actions = require(HUD:WaitForChild("Actions"))
local Feedback = require(HUD:WaitForChild("Feedback"))

local Controller = {}
local initialized = false

local function getRemotes()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if not remotes then
        error("Remotes unavailable")
    end

    local state = remotes:WaitForChild("State", 15)
    local action = remotes:WaitForChild("Action", 15)

    if not state or not action then
        error("Combat remotes unavailable")
    end

    return state :: RemoteEvent, action :: RemoteEvent
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

    local stateRemote, actionRemote = getRemotes()
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

    local function safeMount(name, callback)
        local ok, result = pcall(callback)
        if not ok then
            warn("[CollisionBattlestar][HUD] " .. name .. " failed: " .. tostring(result))
            return nil
        end
        return result
    end

    safeMount("Profile", function()
        Profile.Mount(root, Config, player)
    end)

    local status = safeMount("Status", function()
        return Status.Mount(root, Config)
    end)

    safeMount("Economy", function()
        Economy.Mount(root, Config, player)
    end)

    safeMount("Vitals", function()
        Vitals.Mount(root, Config, player)
    end)

    local actions = safeMount("Actions", function()
        return Actions.Mount(root)
    end)

    local feedback = safeMount("Feedback", function()
        return Feedback.Mount(root, Config)
    end)

    if not status or not actions or not feedback then
        error("Critical HUD modules failed")
    end

    actions.M1.Button.Activated:Connect(function()
        if actions.M1.Activate() then
            actionRemote:FireServer("M1")
        end
    end)

    actions.Dash.Button.Activated:Connect(function()
        if actions.Dash.Activate() then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local direction = humanoid and humanoid.MoveDirection
            if direction and direction.Magnitude > 0.1 then
                direction = Vector3.new(direction.X, 0, direction.Z).Unit
            else
                direction = nil
            end
            actionRemote:FireServer("Dash", direction)
        end
    end)

    local function setWave(wave)
        local value = tonumber(wave) or 0
        status.Wave.Text = ("WAVE %02d"):format(value)
        status.RefreshProgress(value, tonumber(workspace:GetAttribute("CollisionEnemies")) or 0)
    end

    local function setEnemies(enemies)
        local value = tonumber(enemies) or 0
        status.Enemies.Text = ("%d HOSTILES"):format(value)
        status.RefreshProgress(tonumber(workspace:GetAttribute("CollisionWave")) or 0, value)
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
            local comboIndex = tonumber(b) or 0
            Feedback.Show(feedback, Config, comboIndex > 0 and ("STRIKE %d"):format(comboIndex) or "STRIKE", Config.UI.Accent, 0.2)
        elseif kind == "AdminMessage" then
            local tone = tostring(b or "INFO")
            local color = if tone == "BAD" then Config.UI.Danger elseif tone == "GOOD" then Config.UI.Good else Config.UI.Info
            Feedback.Show(feedback, Config, tostring(a), color, 2)
        elseif kind == "AdminAnnouncement" then
            Feedback.Show(feedback, Config, "OWNER  •  " .. tostring(a), Config.UI.Warning, 4)
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
