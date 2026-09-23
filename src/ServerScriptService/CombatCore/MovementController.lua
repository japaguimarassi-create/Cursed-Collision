--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StateManager: any = require(script.Parent.StateManager)

local MovementController = {}

type SprintState = {
    sprinting: boolean,
    speed: number
}

local sprint: {[Player]: SprintState} = {}

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

function MovementController:SetSprinting(player: Player, active: boolean)
    local record = sprint[player]

    if not record then
        record = {
            sprinting = false,
            speed = Config.Movement.WalkSpeed
        }
        sprint[player] = record
    end

    record.sprinting = active
end

function MovementController:IsSprinting(player: Player): boolean
    local record = sprint[player]
    return record ~= nil and record.sprinting
end

function MovementController:Clear(player: Player)
    sprint[player] = nil
end

function MovementController:Step(player: Player, dt: number)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local state = StateManager:Get(player)
    local record = sprint[player]

    if not humanoid or not state or not record or humanoid.Health <= 0 then
        return
    end

    if state.Phase == "Blocking" then
        record.speed = Config.Combat.Block.WalkSpeed
        humanoid.WalkSpeed = Config.Combat.Block.WalkSpeed
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        return
    end

    if state.Phase == "Stunned"
        or state.Phase == "Ragdolled"
        or state.Phase == "Dead"
        or state.Phase == "UsingAbility"
        or state.Phase == "Ultimate"
        or state.Phase == "Awakening" then
        record.speed = 0
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        return
    end

    local moving = humanoid.MoveDirection.Magnitude > 0.05
    local targetSpeed = if record.sprinting and moving
        then Config.Movement.SprintSpeed
        else Config.Movement.WalkSpeed

    local rate = targetSpeed > record.speed
        and Config.Movement.Acceleration
        or Config.Movement.Deceleration

    record.speed += math.clamp(
        targetSpeed - record.speed,
        -rate * dt,
        rate * dt
    )

    humanoid.WalkSpeed = math.clamp(record.speed, 0, 64)
    humanoid.JumpPower = Config.Movement.JumpPower
    humanoid.AutoRotate = true
end

return MovementController
