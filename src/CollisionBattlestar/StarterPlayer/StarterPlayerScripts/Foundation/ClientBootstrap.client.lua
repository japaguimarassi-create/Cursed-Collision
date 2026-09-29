--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(script.Parent:WaitForChild("HUD"):WaitForChild("Root"))
local Input = require(script.Parent:WaitForChild("InputController"))
local FX = require(script.Parent:WaitForChild("CombatFX"):WaitForChild("Service"))
local Camera = require(script.Parent:WaitForChild("Camera"):WaitForChild("Service"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("Combat")

local hud = Root.Create(player)
Input.Bind(player, hud, combatRemote)
FX.Init()
Camera.Init()

remotes:WaitForChild("State").OnClientEvent:Connect(function(kind: string, a, b)
    if kind == "Upgrade" then
        hud.Gui:SetAttribute("LastUpgradeLevel", tonumber(a) or 0)
    elseif kind == "UpgradeFailed" then
        hud.Gui:SetAttribute("UpgradeCost", tonumber(a) or 0)
    elseif kind == "Attack" then
        hud.Gui:SetAttribute("LastCombo", tonumber(a) or 0)
        hud.Gui:SetAttribute("LastHit", b == true)
    elseif kind == "Dash" then
        hud.Gui:SetAttribute("DashCooldown", tonumber(a) or 0)
    end
end)