--!strict

local UserInputService = game:GetService("UserInputService")

local InputController = {}

function InputController:GetMoveVector(): Vector2
    local character = game:GetService("Players").LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
        local move = humanoid.MoveDirection
        return Vector2.new(move.X, move.Z)
    end
    return Vector2.new(0, -1)
end

function InputController:GetDashDirection(): string
    local move = self:GetMoveVector()
    if math.abs(move.Y) >= math.abs(move.X) then
        return move.Y > 0 and "Forward" or "Back"
    end
    return move.X > 0 and "Right" or "Left"
end

function InputController:IsTouch(): boolean
    return UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

return InputController
