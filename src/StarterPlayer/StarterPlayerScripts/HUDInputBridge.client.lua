--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actions = require(script.Parent.Controllers.HUDActionBus)
local InputController = require(script.Parent.Controllers.InputController)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)

if not remotes then
    return
end

local combat = remotes:WaitForChild("CombatAction", 15)
local movement = remotes:WaitForChild("MovementRemote", 15)

if not combat or not movement then
    return
end

local function menuOpen(): boolean
    return player:GetAttribute("CCHUD_MenuOpen") == true
end

Actions:Connect(function(action)
    if menuOpen() then
        return
    end

    if action == "BlockToggle" then
        local active = player:GetAttribute("CCHUD_Blocking") == true
        player:SetAttribute("CCHUD_Blocking", not active)
        combat:FireServer(if active then "BlockEnd" else "BlockStart")
        return
    end

    if action == "SprintToggle" then
        local active = player:GetAttribute("CCHUD_Sprinting") == true
        player:SetAttribute("CCHUD_Sprinting", not active)
        movement:FireServer(if active then "SprintEnd" else "SprintStart")
        return
    end

    if action == "Dash" then
        combat:FireServer("Dash", InputController:GetDashDirection())
        return
    end

    combat:FireServer(action)
end)

return nil
