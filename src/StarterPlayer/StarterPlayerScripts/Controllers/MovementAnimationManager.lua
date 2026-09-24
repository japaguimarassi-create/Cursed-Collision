--!strict

local RunService = game:GetService("RunService")
local AnimationController: any = require(script.Parent.AnimationController)

local MovementAnimationManager = {}

type Record = {
    connection: RBXScriptConnection,
    last: string,
    accumulator: number
}

local bound: {[Model]: Record} = {}

function MovementAnimationManager:Bind(character: Model)
    if bound[character] then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local record: Record = {
        connection = nil :: any,
        last = "",
        accumulator = 0
    }

    record.connection = RunService.Heartbeat:Connect(function(dt)
        if not character.Parent or humanoid.Health <= 0 then
            return
        end

        record.accumulator += dt
        if record.accumulator < 0.033 then
            return
        end
        record.accumulator = 0

        local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
        local state = humanoid:GetState()
        local nextState = "Idle"

        if state == Enum.HumanoidStateType.Jumping then
            nextState = "Jump"
        elseif state == Enum.HumanoidStateType.Freefall then
            nextState = "Fall"
        elseif speed > humanoid.WalkSpeed * 0.82 then
            nextState = "Sprint"
        elseif speed > 0.08 then
            nextState = "Walk"
        end

        if nextState ~= record.last then
            AnimationController:SetState(character, nextState)
            record.last = nextState
        end

        AnimationController:UpdateLocomotion(character, nextState, speed)
    end)

    bound[character] = record
end

function MovementAnimationManager:Unbind(character: Model)
    local record = bound[character]
    if not record then
        return
    end

    record.connection:Disconnect()
    bound[character] = nil
end

return MovementAnimationManager
