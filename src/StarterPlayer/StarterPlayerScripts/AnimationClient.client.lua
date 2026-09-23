--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.RemoteService):Get()
local CombatAnimation: any = require(script.Parent.Controllers.CombatAnimationManager)
local MovementAnimation: any = require(script.Parent.Controllers.MovementAnimationManager)
local AnimationController: any = require(script.Parent.Controllers.AnimationController)
local CombatHandler: any = require(script.Parent.Controllers.CombatHandler)

local boundConnections: {[Player]: RBXScriptConnection} = {}

local function bind(player: Player)
    local function bindCharacter(character: Model)
        AnimationController:Bind(character)
        MovementAnimation:Bind(character)
    end

    if player.Character then
        bindCharacter(player.Character)
    end

    if boundConnections[player] then
        boundConnections[player]:Disconnect()
    end

    boundConnections[player] = player.CharacterAdded:Connect(bindCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
    bind(player)
end

Players.PlayerAdded:Connect(bind)

Players.PlayerRemoving:Connect(function(player)
    if boundConnections[player] then
        boundConnections[player]:Disconnect()
        boundConnections[player] = nil
    end
end)

Remotes.CombatFX.OnClientEvent:Connect(function(kind, _, payload)
    if not payload then
        return
    end

    if kind == "CombatAction"
        and payload.actor
        and payload.actor:IsA("Model") then

        local action = tostring(payload.action or "")

        if action == "M1Start" or action == "SkillStart" then
            CombatHandler:OnCombatEvent(payload, Remotes.CombatAction)
            return
        end

        if action == "M1Impact" then
            return
        end

        if action == "Dash"
            or action == "BlockStart"
            or action == "BlockEnd"
            or action == "Special" then
            CombatAnimation:Play(payload.actor, action, payload)
            return
        end
    end

    if kind == "Hit" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(payload.actor, "Hit", payload)
        return
    end

    if kind == "PerfectBlock" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(payload.actor, "Parry", payload)
        return
    end

    if kind == "Death" and payload.actor and payload.actor:IsA("Model") then
        AnimationController:Play(payload.actor, "Execution", payload)
    end
end)

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                character:SetAttribute("MovementSpeed", humanoid.MoveDirection.Magnitude)
            end
        end
    end
end)
