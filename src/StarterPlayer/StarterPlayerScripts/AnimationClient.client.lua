--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.RemoteService):Get()
local CombatAnimation: any = require(script.Parent.Controllers.CombatAnimationManager)
local MovementAnimation: any = require(script.Parent.Controllers.MovementAnimationManager)
local AnimationController: any = require(script.Parent.Controllers.AnimationController)
local CombatHandler: any = require(script.Parent.Controllers.CombatHandler)

local function bindCharacter(character: Model)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or not humanoid:IsA("Humanoid") then
            return
        end

        local animator = humanoid:FindFirstChildOfClass("Animator")

        if not animator then
            local candidate = humanoid:WaitForChild("Animator", 5)
            if candidate and candidate:IsA("Animator") then
                animator = candidate
            end
        end

        if not animator then
            local created = Instance.new("Animator")
            created.Parent = humanoid
        end

        AnimationController:Bind(character)
        MovementAnimation:Bind(character)
    end)
end

local function bind(player: Player)
    if player.Character then
        bindCharacter(player.Character)
    end

    player.CharacterAdded:Connect(bindCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
    bind(player)
end

Players.PlayerAdded:Connect(bind)

Remotes.CombatFX.OnClientEvent:Connect(function(
    kind: string,
    _position: Vector3,
    payload: any
)
    if not payload then
        return
    end

    if kind == "CombatAction"
        and payload.actor
        and payload.actor:IsA("Model") then
        local action = tostring(payload.action or "")

        if action == "M1Start"
            or action == "SkillStart"
            or action == "SpecialStart"
            or action == "Dash" then
            CombatHandler:OnCombatEvent(payload, Remotes.CombatAction)
            return
        end

        CombatAnimation:Play(
            payload.actor,
            action,
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

    if kind == "PerfectBlock"
        and payload.actor
        and payload.actor:IsA("Model") then
        CombatAnimation:Play(
            payload.actor,
            "Parry",
            payload
        )
        return
    end

    if kind == "Death"
        and payload.actor
        and payload.actor:IsA("Model") then
        AnimationController:Play(
            payload.actor,
            "Execution",
            payload
        )
    end
end)

RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                character:SetAttribute(
                    "MovementSpeed",
                    humanoid.MoveDirection.Magnitude
                )
            end
        end
    end
end)
