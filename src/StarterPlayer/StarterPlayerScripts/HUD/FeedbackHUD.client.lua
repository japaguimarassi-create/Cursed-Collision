--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Theme = require(script.Parent.HUDTheme)

local player = Players.LocalPlayer
local gui = Theme.CreateGui("CursedCollisionHUD_Feedback", 90)
local root = Theme.Root(gui)

local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
local fx = remotes and remotes:WaitForChild("CombatFX", 15)
if not fx then
    return
end

local function popup(text: string, position: UDim2, kind: string)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.26, 0.055)
    label.Position = position
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 11
    label.TextColor3 =
        kind == "Damage" and Theme.Colors.Health
        or kind == "Parry" and Color3.fromRGB(103, 208, 255)
        or Theme.Colors.Accent
    label.Parent = root

    local target = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale - 0.045, position.Y.Offset)
    TweenService:Create(label, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = target,
        TextTransparency = 1
    }):Play()

    Debris:AddItem(label, 0.45)
end

fx.OnClientEvent:Connect(function(kind, _, payload)
    if type(kind) ~= "string" or type(payload) ~= "table" then
        return
    end

    if kind == "Hit" then
        local amount = tonumber(payload.amount) or tonumber(payload.damage) or 0
        if amount > 0 and payload.target == player.Character then
            popup("-" .. math.floor(amount), UDim2.fromScale(0.58, 0.39), "Damage")
        elseif payload.actor == player.Character then
            popup("HIT", UDim2.fromScale(0.52, 0.39), "Hit")
        end
    elseif kind == "PerfectBlock" and payload.actor == player.Character then
        popup("PERFECT BLOCK", UDim2.fromScale(0.50, 0.30), "Parry")
    elseif kind == "Death" and payload.actor == player.Character then
        popup("ELIMINATED", UDim2.fromScale(0.50, 0.30), "Hit")
    end
end)
