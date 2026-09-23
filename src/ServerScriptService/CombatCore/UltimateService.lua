--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local StateManager: any=require(script.Parent.StateManager)
local Remotes=require(ReplicatedStorage.Shared.RemoteService):Get()

local UltimateService={}
local activeTokens:{[Player]:number}={}

local function setMeter(player: Player, name: string, value: number)
    value=math.clamp(value,0,100)
    player:SetAttribute(name,value)
end

function UltimateService:Init(player: Player)
    setMeter(player,"UltimateMeter",0)
    setMeter(player,"AwakeningMeter",0)
    player:SetAttribute("UltimateReady",false)
    player:SetAttribute("AwakeningReady",false)
    player:SetAttribute("UltimateActive",false)
    player:SetAttribute("AwakeningActive",false)
end

function UltimateService:AddMeter(player: Player, damage: number)
    local state=StateManager:Get(player)
    if not state then return end

    local amount=math.clamp(tonumber(damage) or 0,0,100)
    local ultimate=(tonumber(player:GetAttribute("UltimateMeter")) or 0)+amount*0.82
    local awakening=(tonumber(player:GetAttribute("AwakeningMeter")) or 0)+amount*0.64

    setMeter(player,"UltimateMeter",ultimate)
    setMeter(player,"AwakeningMeter",awakening)
    player:SetAttribute("UltimateReady",ultimate>=100)
    player:SetAttribute("AwakeningReady",awakening>=100)
end

function UltimateService:Activate(player: Player, kind: string): boolean
    local state=StateManager:Get(player)
    if not state then return false end

    local meter=kind=="Awakening"
        and tonumber(player:GetAttribute("AwakeningMeter")) or tonumber(player:GetAttribute("UltimateMeter"))

    if (meter or 0)<100 then return false end
    if player:GetAttribute(kind=="Awakening" and "AwakeningActive" or "UltimateActive")==true then
        return false
    end
    if not StateManager:CanAct(player,os.clock()) then return false end

    local phase: StateManager.Phase = if kind=="Awakening" then "Awakening" else "Ultimate"
    if not StateManager:SetPhase(player,phase) then return false end

    state.AbilityToken+=1
    local token=state.AbilityToken
    activeTokens[player]=token

    if kind=="Awakening" then
        setMeter(player,"AwakeningMeter",0)
        player:SetAttribute("AwakeningReady",false)
        player:SetAttribute("AwakeningActive",true)
        StateManager:SetInvulnerable(player,0.85,os.clock())
    else
        setMeter(player,"UltimateMeter",0)
        player:SetAttribute("UltimateReady",false)
        player:SetAttribute("UltimateActive",true)
        StateManager:SetInvulnerable(player,0.30,os.clock())
    end

    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        Remotes.CombatFX:FireAllClients(kind,root.Position,{
            actor=player.Character,
            token=token
        })
    end

    local duration=kind=="Awakening" and 15 or 4.5

    task.delay(duration,function()
        if not player.Parent or activeTokens[player]~=token then return end

        if kind=="Awakening" then
            player:SetAttribute("AwakeningActive",false)
        else
            player:SetAttribute("UltimateActive",false)
        end

        activeTokens[player]=nil
        local latest=StateManager:Get(player)

        if latest and latest.AbilityToken==token and latest.Phase~="Dead" then
            StateManager:SetPhase(player,"Idle")
        end
    end)

    return true
end

Players.PlayerAdded:Connect(function(player)
    UltimateService:Init(player)
end)

for _,player in ipairs(Players:GetPlayers()) do
    UltimateService:Init(player)
end

Players.PlayerRemoving:Connect(function(player)
    activeTokens[player]=nil
end)

return UltimateService
