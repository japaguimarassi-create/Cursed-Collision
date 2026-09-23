--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUDController = require(script.Parent.Controllers.HUDController)
local HUDRegistry = require(script.Parent.Controllers.HUDRegistry)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- O bootstrap é pequeno de propósito: se uma view falhar, o combate não precisa ser reescrito.
local ok, controller = pcall(function()
    return HUDController.new()
end)

if not ok then
    warn("[CursedCollisionHUD] failed to initialize:", controller)
    return
end

HUDRegistry:Set(controller)

playerGui.ChildAdded:Connect(function(child)
    if child.Name == "CursedCollisionCombatHUD" and child ~= controller.Gui then
        child:Destroy()
    end
end)

return nil
