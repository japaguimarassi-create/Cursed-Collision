--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local MovementController = {}

function MovementController:Set(
    player: Player,
    walkSpeed: number,
    jumpPower: number,
    autoRotate: boolean
)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    humanoid.WalkSpeed = math.clamp(walkSpeed, 0, 64)
    humanoid.JumpPower = math.clamp(jumpPower, 0, 100)
    humanoid.AutoRotate = autoRotate
end

function MovementController:Combat(player: Player)
    self:Set(
        player,
        Config.Movement.WalkSpeed,
        Config.Movement.JumpPower,
        true
    )
end

function MovementController:Block(player: Player)
    self:Set(
        player,
        Config.Combat.Block.WalkSpeed,
        0,
        false
    )
end

function MovementController:Stun(player: Player)
    self:Set(player, 0, 0, false)
end

return MovementController