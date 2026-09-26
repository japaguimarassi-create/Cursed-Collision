--!strict

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local root = script.Parent

task.spawn(function()
    for attempt = 1, 10 do
        local ok = pcall(function()
            local UIController = require(root:WaitForChild("UIController", 10))
            UIController:Init()
        end)

        if ok then
            local playerGui = player:WaitForChild("PlayerGui")
            local boot = playerGui:FindFirstChild("CollisionBattlestarImmediateHUD")
            if boot then
                boot:Destroy()
            end
            return
        end

        task.wait(0.25)
    end
end)

task.spawn(function()
    for attempt = 1, 8 do
        local ok = pcall(function()
            local InputController = require(root:WaitForChild("InputController", 10))
            InputController:Init()
        end)

        if ok then
            return
        end

        task.wait(0.5)
    end
end)
