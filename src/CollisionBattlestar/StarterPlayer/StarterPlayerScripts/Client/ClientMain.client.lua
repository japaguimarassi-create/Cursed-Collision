--!strict
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local root=script.Parent
task.spawn(function()
    for attempt=1,14 do
        local ok=pcall(function() require(root:WaitForChild("UIController",10)):Init() end)
        if ok then return end
        task.wait(0.2+attempt*0.04)
    end
end)
task.spawn(function() pcall(function() require(root:WaitForChild("InputController",10)):Init() end) end)
player.CharacterAdded:Connect(function()
    task.defer(function()
        local ok,controller=pcall(function() return require(root:WaitForChild("UIController",10)) end)
        if ok and controller then pcall(function() controller:Init() end) end
    end)
end)