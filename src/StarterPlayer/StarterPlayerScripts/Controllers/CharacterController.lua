--!strict

local Players = game:GetService("Players")

local CharacterController = {}
local player = Players.LocalPlayer

function CharacterController:GetCharacter(): Model?
    return player.Character
end

function CharacterController:GetHumanoid(): Humanoid?
    local character = self:GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

function CharacterController:IsAlive(): boolean
    local humanoid = self:GetHumanoid()
    return humanoid ~= nil and humanoid.Health > 0
end

function CharacterController:IsAirborne(): boolean
    local humanoid = self:GetHumanoid()
    if not humanoid then
        return false
    end
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.FallingDown
end

return CharacterController
