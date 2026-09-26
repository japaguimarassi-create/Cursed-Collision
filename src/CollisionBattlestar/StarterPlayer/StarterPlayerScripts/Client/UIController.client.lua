--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")).Get()

local Controller = {}

local timerLabel: TextLabel
local roleLabel: TextLabel
local infoLabel: TextLabel

local function round(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function border(parent: Instance)
    local s = Instance.new("UIStroke")
    s.Color = Config.UI.Stroke
    s.Thickness = 1
    s.Transparency = 0.25
    s.Parent = parent
end

local function text(parent: Instance, value: string, size: number)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = Config.UI.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

function Controller:Init()
    local gui = Instance.new("ScreenGui")
    gui.Name = "TagHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local top = Instance.new("Frame")
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.Position = UDim2.fromScale(0.5, 0.035)
    top.Size = UDim2.fromOffset(360, 112)
    top.BackgroundColor3 = Config.UI.Surface
    top.BackgroundTransparency = 0.08
    top.Parent = gui
    round(top, 18)
    border(top)

    timerLabel = text(top, "TAG", 28)
    timerLabel.Size = UDim2.new(1, 0, 0, 42)
    timerLabel.Position = UDim2.fromOffset(0, 6)

    roleLabel = text(top, "AGUARDE", 14)
    roleLabel.Size = UDim2.new(1, 0, 0, 28)
    roleLabel.Position = UDim2.fromOffset(0, 48)
    roleLabel.TextColor3 = Config.UI.Muted

    infoLabel = text(top, "Corra e use as estruturas do mapa para escapar.", 11)
    infoLabel.Size = UDim2.new(1, -24, 0, 26)
    infoLabel.Position = UDim2.fromOffset(12, 78)
    infoLabel.Font = Enum.Font.GothamMedium
    infoLabel.TextColor3 = Config.UI.Muted

    local function roleForUserId(userId: number)
        return player.UserId == userId
    end

    Net.State.OnClientEvent:Connect(function(kind: string, a, b)
        if kind == "Intermission" then
            timerLabel.Text = ("PRÓXIMA RODADA  %02d"):format(tonumber(a) or 0)
            timerLabel.TextColor3 = Config.UI.Text
            roleLabel.Text = "Escolhendo o pegador..."
            roleLabel.TextColor3 = Config.UI.Muted
        elseif kind == "RoundStart" then
            local taggerId = tonumber(b) or 0
            timerLabel.Text = ("%02d"):format(tonumber(a) or 0)
            roleLabel.Text = if roleForUserId(taggerId) then "VOCÊ É O PEGADOR" else "CORRA"
            roleLabel.TextColor3 = if roleForUserId(taggerId) then Config.UI.Danger else Config.UI.Good
            infoLabel.Text = if roleForUserId(taggerId) then "Toque em outro jogador para passar a marca." else "Evite o jogador vermelho."
        elseif kind == "RoundTime" then
            timerLabel.Text = ("%02d"):format(tonumber(a) or 0)
            local taggerId = tonumber(b) or 0
            if roleForUserId(taggerId) then
                roleLabel.Text = "VOCÊ É O PEGADOR"
                roleLabel.TextColor3 = Config.UI.Danger
            else
                roleLabel.Text = "CORRA"
                roleLabel.TextColor3 = Config.UI.Good
            end
        elseif kind == "TagTransfer" then
            local taggerId = tonumber(a) or 0
            timerLabel.TextColor3 = Config.UI.Danger
            roleLabel.Text = if roleForUserId(taggerId) then "VOCÊ É O PEGADOR" else "PEGADOR MUDOU"
            roleLabel.TextColor3 = Config.UI.Danger
            infoLabel.Text = if roleForUserId(taggerId) then "Agora você precisa marcar alguém." else "Fique longe do jogador vermelho."
            TweenService:Create(timerLabel, TweenInfo.new(0.15), {TextTransparency = 0.15}):Play()
        elseif kind == "RoundEnd" then
            timerLabel.Text = "FIM"
            timerLabel.TextColor3 = Config.UI.Text
            roleLabel.Text = "Rodada encerrada"
            roleLabel.TextColor3 = Config.UI.Muted
            infoLabel.Text = ("Jogadores livres: %d"):format(tonumber(a) or 0)
        end
    end)
end

return Controller
