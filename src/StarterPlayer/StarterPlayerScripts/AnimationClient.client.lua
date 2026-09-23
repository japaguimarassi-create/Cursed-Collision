--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.RemoteService):Get()
local CombatAnimation: any = require(script.Parent.Controllers.CombatAnimationManager)
local MovementAnimation: any = require(script.Parent.Controllers.MovementAnimationManager)
local AnimationController: any = require(script.Parent.Controllers.AnimationController)
local CombatHandler: any = require(script.Parent.Controllers.CombatHandler)

local function bind(player: Player)
    local character = player.Character
    if character then
        AnimationController:Bind(character)
        MovementAnimation:Bind(character)
    end

    player.CharacterAdded:Connect(function(newCharacter)
        AnimationController:Bind(newCharacter)
        MovementAnimation:Bind(newCharacter)
        CombatHandler:Stop(newCharacter)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    bind(player)
end

Players.PlayerAdded:Connect(bind)

Remotes.CombatFX.OnClientEvent:Connect(function(kind, _, payload)
    if type(payload) ~= "table" then
        return
    end

    if kind == "CombatAction" and payload.actor and payload.actor:IsA("Model") then
        if CombatHandler:OnCombatEvent(payload, Remotes.CombatAction) then
            return
        end

        CombatAnimation:Play(
            payload.actor,
            tostring(payload.action or "Idle"),
            payload
        )
        return
    end

    if kind == "Hit" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(
            payload.actor,
            "Hit",
            payload
        )
        return
    end

    if kind == "PerfectBlock" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(
            payload.actor,
            "Parry",
            payload
        )
        return
    end

    if kind == "Death" and payload.actor and payload.actor:IsA("Model") then
        AnimationController:Play(payload.actor, "Execution", payload)
    end
end)

return nil
