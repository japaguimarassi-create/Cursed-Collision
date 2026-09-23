--!strict

local Players = game:GetService("Players")
local StateManager: any = require(script.Parent.StateManager)

local RagdollService = {}

type Active = {
    token: number,
    motors: {Motor6D},
    created: {Instance},
    collision: {[BasePart]: boolean},
    requiresNeck: boolean,
}

local active: {[Player]: Active} = {}

local function build(player: Player): Active?
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not character or not humanoid or humanoid.Health <= 0 then
        return nil
    end

    local created: {Instance} = {}
    local motors: {Motor6D} = {}
    local collision: {[BasePart]: boolean} = {}

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("Motor6D")
            and object.Part0
            and object.Part1
            and object.Name ~= "RootJoint" then

            local attachment0 = Instance.new("Attachment")
            attachment0.Name = "CC_Ragdoll_A0"
            attachment0.CFrame = object.C0
            attachment0.Parent = object.Part0

            local attachment1 = Instance.new("Attachment")
            attachment1.Name = "CC_Ragdoll_A1"
            attachment1.CFrame = object.C1
            attachment1.Parent = object.Part1

            local socket = Instance.new("BallSocketConstraint")
            socket.Name = "CC_Ragdoll_Socket"
            socket.Attachment0 = attachment0
            socket.Attachment1 = attachment1
            socket.LimitsEnabled = true
            socket.UpperAngle = 55
            socket.TwistLimitsEnabled = true
            socket.TwistLowerAngle = -35
            socket.TwistUpperAngle = 35
            socket.Parent = object.Part0

            table.insert(created, attachment0)
            table.insert(created, attachment1)
            table.insert(created, socket)
            table.insert(motors, object)
        end
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart" then
            collision[object] = object.CanCollide
            object.CanCollide = true
        end
    end

    return {
        token = 0,
        motors = motors,
        created = created,
        collision = collision,
        requiresNeck = humanoid.RequiresNeck,
    }
end

local function restore(player: Player, data: Active)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    for _, motor in ipairs(data.motors) do
        if motor.Parent then
            motor.Enabled = true
        end
    end

    for part, previous in pairs(data.collision) do
        if part.Parent then
            part.CanCollide = previous
        end
    end

    for _, object in ipairs(data.created) do
        if object.Parent then
            object:Destroy()
        end
    end

    if humanoid then
        humanoid.RequiresNeck = data.requiresNeck
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true

        if humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    if character then
        character:SetAttribute("RagdollReason", nil)
    end

    StateManager:ClearStunWhenReady(player, os.clock())
end

function RagdollService:Apply(player: Player, duration: number, reason: string?): boolean
    self:Cancel(player)

    local state = StateManager:Get(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not state or not character or not humanoid or humanoid.Health <= 0 then
        return false
    end

    local data = build(player)
    if not data then
        return false
    end

    local token = (active[player] and active[player].token or 0) + 1
    data.token = token
    active[player] = data

    StateManager:BeginRagdoll(player, duration, os.clock())
    character:SetAttribute("RagdollReason", reason or "Impact")

    humanoid.RequiresNeck = false
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    for _, motor in ipairs(data.motors) do
        motor.Enabled = false
    end

    task.delay(math.max(0.10, duration), function()
        local current = active[player]

        if not current or current.token ~= token or not player.Parent then
            return
        end

        active[player] = nil
        restore(player, current)
    end)

    return true
end

function RagdollService:Cancel(player: Player)
    local data = active[player]

    if not data then
        return
    end

    data.token += 1
    active[player] = nil
    restore(player, data)
end

Players.PlayerRemoving:Connect(function(player)
    active[player] = nil
end)

return RagdollService
