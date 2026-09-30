--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Root=require(script.Parent:WaitForChild("HUD"):WaitForChild("Root"))
local Shop=require(script.Parent:WaitForChild("HUD"):WaitForChild("Shop"))
local Echo=require(script.Parent:WaitForChild("HUD"):WaitForChild("Echo"))
local Onboarding=require(script.Parent:WaitForChild("HUD"):WaitForChild("Onboarding"))
local TestLab=require(script.Parent:WaitForChild("HUD"):WaitForChild("TestLab"))
local Input=require(script.Parent:WaitForChild("InputController"))
local FX=require(script.Parent:WaitForChild("CombatFX"):WaitForChild("Service"))
local Camera=require(script.Parent:WaitForChild("Camera"):WaitForChild("Service"))

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local combatRemote=remotes:WaitForChild("Combat")
local commerceRemote=remotes:WaitForChild("Commerce")
local companionRemote=remotes:WaitForChild("Companion")
local testLabRemote=remotes:WaitForChild("TestLab")

local hud=Root.Create(player)
local input=Input.Bind(player,hud,combatRemote)
local shop=Shop.Create(hud.RootFrame,commerceRemote,player)
local echo=Echo.Create(hud.RootFrame,companionRemote,player)
local onboarding=Onboarding.Create(hud.RootFrame,player)
local testLab=TestLab.Create(hud.RootFrame,testLabRemote,player)

hud:SetShopCallback(function() shop:Toggle() end)
hud:SetCompanionCallback(function() echo:Toggle() end)

FX.Init()
Camera.Init()

local stateConnection=remotes:WaitForChild("State").OnClientEvent:Connect(function(kind:string,a,b)
    hud:ApplyCombatState(kind,a,b)
end)

player.AncestryChanged:Connect(function(_,parent)
    if parent==nil then
        stateConnection:Disconnect()
        input.Unbind()
        shop:Destroy()
        echo:Destroy()
        onboarding:Destroy()
        testLab:Destroy()
        hud:Destroy()
    end
end)
