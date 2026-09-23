--!strict

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local Remotes=require(ReplicatedStorage.Shared.RemoteService):Get()
local CombatAnimation=require(script.Parent.Controllers.CombatAnimationManager)
local MovementAnimation=require(script.Parent.Controllers.MovementAnimationManager)
local AnimationController=require(script.Parent.Controllers.AnimationController)

local localPlayer=Players.LocalPlayer

local function bind(player: Player)
    local character=player.Character
    if character then
        AnimationController:Bind(character)
        MovementAnimation:Bind(character)
    end

    player.CharacterAdded:Connect(function(newCharacter)
        AnimationController:Bind(newCharacter)
        MovementAnimation:Bind(newCharacter)
    end)
end

for _,player in ipairs(Players:GetPlayers()) do
    bind(player)
end

Players.PlayerAdded:Connect(bind)

Remotes.CombatFX.OnClientEvent:Connect(function(kind, _, payload)
    if not payload then return end

    if kind=="CombatAction" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(
            payload.actor,
            tostring(payload.action or "Idle"),
            payload
        )
        return
    end

    if kind=="Hit" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(
            payload.actor,
            "Hit",
            payload
        )
        return
    end

    if kind=="PerfectBlock" and payload.actor and payload.actor:IsA("Model") then
        CombatAnimation:Play(payload.actor,"Parry",payload)
        return
    end

    if kind=="Death" and payload.actor and payload.actor:IsA("Model") then
        AnimationController:Play(payload.actor,"Execute",payload)
    end
end)

RunService.RenderStepped:Connect(function()
    for _,player in ipairs(Players:GetPlayers()) do
        local character=player.Character
        if character then
            local humanoid=character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                character:SetAttribute("MovementSpeed",humanoid.MoveDirection.Magnitude)
            end
        end
    end
end)
