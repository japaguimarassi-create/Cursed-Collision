--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationController = require(script.Parent.AnimationController)
local Registry = require(ReplicatedStorage.Animation.AnimationRegistry)

local MovementAnimationManager = {}

local bound: {[Model]: RBXScriptConnection} = setmetatable({}, {__mode="k"})

function MovementAnimationManager:Bind(character: Model)
    if bound[character] then return end

    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    bound[character]=RunService.Heartbeat:Connect(function()
        if not character.Parent or humanoid.Health<=0 then
            return
        end

        local speed=humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
        local state=humanoid:GetState()

        if state==Enum.HumanoidStateType.Jumping then
            AnimationController:Play(character,"Jump",{},nil)
        elseif state==Enum.HumanoidStateType.Freefall then
            AnimationController:Play(character,"Fall",{},nil)
        elseif speed>humanoid.WalkSpeed*0.82 then
            if Registry.Sprint and Registry.Sprint.Id>0 then
                AnimationController:Play(character,"Sprint",{},nil)
            end
        elseif speed>0.08 then
            if Registry.Walk and Registry.Walk.Id>0 then
                AnimationController:Play(character,"Walk",{},nil)
            end
        end
    end)
end

function MovementAnimationManager:Unbind(character: Model)
    local connection=bound[character]
    if connection then
        connection:Disconnect()
        bound[character]=nil
    end
end

return MovementAnimationManager
