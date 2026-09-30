--!strict

local AnalyticsService=game:GetService("AnalyticsService")
local RunService=game:GetService("RunService")
local Rules=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("AnalyticsRules"))

local Service={}
Service.__index=Service

local fieldKeys={
    [1]=Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
    [2]=Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
    [3]=Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

function Service.new()
    return setmetatable({enabled=RunService:IsRunning()},Service)
end

function Service:Init() end

function Service:Log(player:Player,eventName:string,value:number,fieldValues:{string}?)
    if not self.enabled or not player or not player.Parent or not Rules.isAllowedEvent(eventName) then return end
    local fields={}
    for index=1,math.min(3,#(fieldValues or {})) do
        fields[fieldKeys[index]]=tostring(fieldValues[index])
    end
    pcall(function()
        AnalyticsService:LogCustomEvent(player,eventName,value,fields)
    end)
end

function Service:Onboarding(player:Player,step:number,name:string)
    if not self.enabled or not player or not player.Parent or step<1 or step>20 then return end
    pcall(function()
        AnalyticsService:LogOnboardingFunnelStepEvent(player,step,name,nil)
    end)
end

return Service
