--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local HUDRecovery=require(ReplicatedStorage.Shared.HUDRecovery)

local function boot()
    if HUDRecovery.IsReady() then return true end
    local ok,result=pcall(HUDRecovery.Build)
    if ok and result and result:IsA("ScreenGui") then
        player:SetAttribute("HUDBootstrapReady",true)
        player:SetAttribute("HUDRuntimeError","")
        return true
    end
    player:SetAttribute("HUDBootstrapReady",false)
    player:SetAttribute("HUDRuntimeError",tostring(result or HUDRecovery.GetLastError()))
    return false
end

task.spawn(function()
    for attempt=1,12 do
        if boot() then return end
        task.wait(math.min(.25*attempt,2))
    end
end)

player.CharacterAdded:Connect(function()
    task.defer(boot)
end)
