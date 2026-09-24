--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateManager: any = require(script.Parent.StateManager)
local Remotes = require(ReplicatedStorage.Shared.RemoteService):Get()

local UltimateService = {}
local activeTokens: {[Player]: number} = {}

local TRANSFORMATION_DURATION = 15

local function setMeter(player: Player, value: number)
    local normalized = math.clamp(value, 0, 100)
    player:SetAttribute("UltimateMeter", normalized)
    player:SetAttribute("AwakeningMeter", normalized)

    local ready = normalized >= 100
    player:SetAttribute("UltimateReady", ready)
    player:SetAttribute("AwakeningReady", ready)
end

function UltimateService:Init(player: Player)
    setMeter(player, 0)
    player:SetAttribute("UltimateActive", false)
    player:SetAttribute("AwakeningActive", false)
    player:SetAttribute("TransformationActive", false)
    player:SetAttribute("TransformationName", "")
end

function UltimateService:AddMeter(player: Player, damage: number)
    local state = StateManager:Get(player)
    if not state then
        return
    end

    if player:GetAttribute("TransformationActive") == true then
        return
    end

    local amount = math.clamp(tonumber(damage) or 0, 0, 100)
    local current = tonumber(player:GetAttribute("AwakeningMeter"))
        or tonumber(player:GetAttribute("UltimateMeter"))
        or 0

    setMeter(player, current + amount * 0.78)
end

function UltimateService:Activate(player: Player, _kind: string): boolean
    local state = StateManager:Get(player)
    if not state then
        return false
    end

    local meter = tonumber(player:GetAttribute("AwakeningMeter"))
        or tonumber(player:GetAttribute("UltimateMeter"))
        or 0

    if meter < 100 then
        return false
    end

    if player:GetAttribute("TransformationActive") == true
        or player:GetAttribute("AwakeningActive") == true
        or player:GetAttribute("UltimateActive") == true then
        return false
    end

    local now = os.clock()
    if not StateManager:CanAct(player, now) then
        return false
    end

    if not StateManager:SetPhase(player, "Awakening") then
        return false
    end

    state.AbilityToken += 1
    local token = state.AbilityToken
    activeTokens[player] = token

    setMeter(player, 0)
    player:SetAttribute("AwakeningActive", true)
    player:SetAttribute("UltimateActive", true)
    player:SetAttribute("TransformationActive", true)
    player:SetAttribute("TransformationName", player:GetAttribute("AwakeningName") or "Awakening")

    StateManager:SetInvulnerable(player, 0.85, now)

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        Remotes.CombatFX:FireAllClients("Awakening", root.Position, {
            actor = player.Character,
            token = token,
            transformation = true
        })
    end

    task.delay(TRANSFORMATION_DURATION, function()
        if not player.Parent or activeTokens[player] ~= token then
            return
        end

        player:SetAttribute("AwakeningActive", false)
        player:SetAttribute("UltimateActive", false)
        player:SetAttribute("TransformationActive", false)
        player:SetAttribute("TransformationName", "")
        activeTokens[player] = nil

        local latest = StateManager:Get(player)
        if latest and latest.AbilityToken == token and latest.Phase ~= "Dead" then
            StateManager:SetPhase(player, "Idle")
        end
    end)

    return true
end

Players.PlayerAdded:Connect(function(player)
    UltimateService:Init(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    UltimateService:Init(player)
end

Players.PlayerRemoving:Connect(function(player)
    activeTokens[player] = nil
end)

return UltimateService
