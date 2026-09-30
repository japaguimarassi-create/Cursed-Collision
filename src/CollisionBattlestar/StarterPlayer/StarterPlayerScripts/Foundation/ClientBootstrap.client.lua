--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = require(script.Parent:WaitForChild("HUD"):WaitForChild("Root"))
local Input = require(script.Parent:WaitForChild("InputController"))
local FX = require(script.Parent:WaitForChild("CombatFX"):WaitForChild("Service"))
local Camera = require(script.Parent:WaitForChild("Camera"):WaitForChild("Service"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatRemote = remotes:WaitForChild("Combat")

local hud = Root.Create(player)
local input = Input.Bind(player, hud, combatRemote)

FX.Init()
Camera.Init()

remotes:WaitForChild("State").OnClientEvent:Connect(function(kind: string, a, b)
    hud:ApplyCombatState(kind, a, b)
end)

player.AncestryChanged:Connect(function(_, parent)
    if parent == nil then
        input.Unbind()
        hud:Destroy()
    end
end)
