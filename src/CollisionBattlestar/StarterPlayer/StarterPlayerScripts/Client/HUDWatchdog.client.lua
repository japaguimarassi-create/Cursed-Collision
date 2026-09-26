--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local scriptParent = script.Parent
local watchdogAlive = true

local function boot()
    for attempt = 1, 12 do
        if not watchdogAlive then
            return
        end

        local existing = player.PlayerGui:FindFirstChild("CollisionBattlestarHUD")
        if existing and existing:IsA("ScreenGui") and existing.Enabled then
            player:SetAttribute("CollisionHUDReady", true)
            return
        end

        local ok = pcall(function()
            local controller = require(scriptParent:WaitForChild("UIController", 15))
            controller:Init()
        end)

        if ok then
            local gui = player.PlayerGui:FindFirstChild("CollisionBattlestarHUD")
            if gui and gui:IsA("ScreenGui") then
                gui.Enabled = true
                player:SetAttribute("CollisionHUDReady", true)
                return
            end
        end

        task.wait(0.75)
    end
end

player.CharacterAdded:Connect(function()
    task.delay(1, boot)
end)

task.spawn(function()
    while watchdogAlive do
        task.wait(3)
        local gui = player.PlayerGui:FindFirstChild("CollisionBattlestarHUD")
        if not gui or not gui:IsA("ScreenGui") then
            boot()
        elseif not gui.Enabled then
            gui.Enabled = true
        end
    end
end)

boot()
