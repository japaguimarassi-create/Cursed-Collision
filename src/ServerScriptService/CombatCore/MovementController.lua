-- Movement controller

local MovementController = {}
MovementController.__index = MovementController

local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_POWER = 50

function MovementController:Set(player: Player, walkSpeed: number?, jumpPower: number?, autoRotate: boolean?)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    if walkSpeed ~= nil then
        humanoid.WalkSpeed = math.clamp(walkSpeed, 0, 64)
    end
    if jumpPower ~= nil then
        humanoid.JumpPower = math.clamp(jumpPower, 0, 100)
    end
    if autoRotate ~= nil then
        humanoid.AutoRotate = autoRotate
    end
end

function MovementController:Combat(player: Player)
    self:Set(player, DEFAULT_WALK_SPEED, DEFAULT_JUMP_POWER, true)
end

function MovementController:Stun(player: Player)
    self:Set(player, 0, 0, false)
end

function MovementController:Block(player: Player)
    self:Set(player, 8, 0, false)
end

function MovementController:Dash(player: Player, velocity: Vector3)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") or root.Anchored then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.new(velocity.X, root.AssemblyLinearVelocity.Y, velocity.Z)
    return true
end

return MovementController
