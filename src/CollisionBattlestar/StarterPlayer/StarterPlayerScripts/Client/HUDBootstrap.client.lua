--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local HUDRecovery=require(ReplicatedStorage.Shared.HUDRecovery)

local function boot()
    local ok,result=pcall(function()
        return HUDRecovery.Build()
    end)
    if ok and result then
        player:SetAttribute("HUDBootstrapReady",true)
        return
    end
    player:SetAttribute("HUDBootstrapReady",false)
end

if player.Character then
    task.defer(boot)
else
    task.defer(boot)
end

remotes:WaitForChild("BootFeedback").OnClientEvent:Connect(function(kind:string)
    if kind=="Ready" and not HUDRecovery.IsReady() then
        boot()
    end
end)
