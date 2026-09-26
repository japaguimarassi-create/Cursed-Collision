--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ClientFolder = script.Parent
local HUD = script.Parent:WaitForChild("HUD", 15)

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Root = require(HUD:WaitForChild("Root"))
local Status = require(HUD:WaitForChild("Status"))
local Economy = require(HUD:WaitForChild("Economy"))
local Navigation = require(HUD:WaitForChild("Navigation"))
local Feedback = require(HUD:WaitForChild("Feedback"))
local Admin = require(HUD:WaitForChild("Admin"))

local Controller = {}
local initialized = false

local function getRemoteFolder()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if not remotes then
        error("HUD remotes unavailable")
    end
    return remotes
end

function Controller:Init()
    if initialized then
        local existing = player.PlayerGui:FindFirstChild("CollisionBattlestarHUD")
        if existing then
            player:SetAttribute("CollisionHUDReady", true)
            return
        end
        initialized = false
    end

    local remotes = getRemoteFolder()
    local state = remotes:WaitForChild("State", 15)
    local travel = remotes:WaitForChild("Travel", 15)
    local adminRemote = remotes:WaitForChild("AdminAction", 15)
    if not state or not travel or not adminRemote then
        error("HUD required remotes unavailable")
    end

    local rootGui = Root.Create(player)
    local root = {
        Gui = rootGui,
        Panel = Root.Panel,
        Label = Root.Label,
        Button = Root.Button,
        Rounded = Root.Rounded,
        Stroke = Root.Stroke,
    }

    local status = Status.Mount(root, Config)
    local economy = Economy.Mount(root, Config, player)
    Navigation.Mount(root, Config, player, travel)
    local feedback = Feedback.Mount(root, Config)
    Admin.Mount(root, Config, player, adminRemote)

    state.OnClientEvent:Connect(function(kind: string, a, b)
        if kind == "WaveIntermission" then
            status.Wave.Text = "NEXT WAVE"
            status.Enemies.Text = ("%ds"):format(tonumber(a) or 0)
            status.Enemies.TextColor3 = Config.UI.Warning
        elseif kind == "WaveStart" then
            status.Wave.Text = ("WAVE %d"):format(tonumber(a) or 0)
            status.Enemies.Text = ("%d ENEMIES"):format(tonumber(b) or 0)
            status.Enemies.TextColor3 = Config.UI.Text
            Feedback.Show(feedback, Config, "ELITE DETECTED", Config.UI.Danger, 1.6)
        elseif kind == "WaveState" then
            status.Wave.Text = ("WAVE %d"):format(tonumber(a) or 0)
            status.Enemies.Text = ("%d ENEMIES"):format(tonumber(b) or 0)
        elseif kind == "Reward" then
            Feedback.Show(feedback, Config, ("+%d C"):format(tonumber(a) or 0), Config.UI.Good, 1.1)
        elseif kind == "WaveReward" then
            Feedback.Show(feedback, Config, ("WAVE %d CLEAR  •  +%d C"):format(tonumber(b) or 0, tonumber(a) or 0), Config.UI.Good, 2)
        elseif kind == "WaveClear" then
            status.Enemies.Text = "CLEAR"
        elseif kind == "ShopMessage" then
            Feedback.Show(feedback, Config, tostring(a), Config.UI.Warning, 1.5)
        elseif kind == "Zone" then
            status.Zone.Text = tostring(a) == "PvP" and "PVP BATTLEGROUNDS" or "PVE"
        elseif kind == "PvpHit" then
            Feedback.Show(feedback, Config, ("-%d HP"):format(tonumber(a) or 0), Config.UI.Warning, 0.7)
        elseif kind == "Attack" then
            TweenService:Create(feedback, TweenInfo.new(0.08), {TextTransparency = 0.08}):Play()
        end
    end)

    player:GetAttributeChangedSignal("Zone"):Connect(function()
        status.Zone.Text = (player:GetAttribute("Zone") or "PvE") == "PvP" and "PVP BATTLEGROUNDS" or "PVE"
    end)

    player:SetAttribute("CollisionHUDReady", true)
    initialized = true
end

return Controller
