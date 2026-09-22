--!strict

local Players = game:GetService("Players")

local MovementController = {}
local player = Players.LocalPlayer

function MovementController:GetDirection(): Vector3
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
        return humanoid.MoveDirection.Unit
    end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
end

function MovementController:GetDashDirection(): string
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return "Forward"
    end

    local move = self:GetDirection()
    local localMove = root.CFrame:VectorToObjectSpace(move)
    if math.abs(localMove.Z) >= math.abs(localMove.X) then
        return localMove.Z < 0 and "Forward" or "Back"
    end
    return localMove.X > 0 and "Right" or "Left"
end

function MovementController:IsAirborne(): boolean
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
end

return MovementController
