--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationController = require(script.Parent.AnimationController)
local Registry = require(ReplicatedStorage.Animation.AnimationRegistry)

local MovementAnimationManager = {}

local bound: {[Model]: {connection: RBXScriptConnection, last: string}} = setmetatable({}, {__mode="k"}) :: any

function MovementAnimationManager:Bind(character: Model)
    if bound[character] then return end

    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

local record = {last=""}

record.connection=RunService.Heartbeat:Connect(function()
        if not character.Parent or humanoid.Health<=0 then
            return
        end

        local speed=humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
        local state=humanoid:GetState()
        local nextState="Idle"

        if state==Enum.HumanoidStateType.Jumping then
            nextState="Jump"
        elseif state==Enum.HumanoidStateType.Freefall then
            nextState="Fall"
        elseif speed>humanoid.WalkSpeed*0.82 then
            nextState="Sprint"
        elseif speed>0.08 then
            nextState="Walk"
        end

        if nextState~=record.last and Registry[nextState] and Registry[nextState].Id>0 then
            AnimationController:Play(character,nextState,{},nil)
        end

        record.last=nextState
    end)

    bound[character]=record
end

function MovementAnimationManager:Unbind(character: Model)
    local record=bound[character]
    if record then
        record.connection:Disconnect()
        bound[character]=nil
    end
end

return MovementAnimationManager
