--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StateManager = require(script.Parent.StateManager)
local MovementController = require(script.Parent.MovementController)

local DamageService = {}
local context = nil :: any

function DamageService:Configure(newContext)
    context = newContext
end

local function alive(humanoid: Humanoid): boolean
    return humanoid.Parent ~= nil and humanoid.Health > 0
end

function DamageService:Apply(
    attacker: Player,
    target: Humanoid,
    amount: number,
    meta: any
): boolean
    meta = meta or {}

    if not alive(target) or type(amount) ~= "number" or amount <= 0 then
        return false
    end

    local targetModel = target.Parent

    if not targetModel or not targetModel:IsA("Model") then
        return false
    end

    local targetPlayer = Players:GetPlayerFromCharacter(targetModel)

    if targetPlayer == attacker then
        return false
    end

    if targetPlayer then
        local targetState = StateManager:Get(targetPlayer)

        if targetState and targetState.DashUntil > os.clock() then
            return false
        end

        if targetState and targetState.Blocking and not meta.guardBreak then
            amount *= Config.Combat.Block.DamageMultiplier
            target:TakeDamage(amount)

            local root = targetModel:FindFirstChild("HumanoidRootPart")

            if root and root:IsA("BasePart") then
                root.AssemblyLinearVelocity *= 0.25

                context.fx("BlockImpact", root.Position, {
                    actor = targetModel,
                    attacker = attacker.Character,
                    damage = amount
                })
            end

            return true
        end

        if targetState then
            local stunDuration = math.max(0, tonumber(meta.stun) or 0.2)

            StateManager:SetStun(
                targetPlayer,
                stunDuration,
                os.clock()
            )

            MovementController:Stun(targetPlayer)

            task.delay(stunDuration + 0.03, function()
                if not targetPlayer.Parent then
                    return
                end

                local state = StateManager:Get(targetPlayer)

                if state
                    and state.StunnedUntil <= os.clock()
                    and not state.Blocking then
                    StateManager:ClearStunWhenReady(targetPlayer, os.clock())
                    MovementController:Combat(targetPlayer)
                end
            end)
        end
    end

    target:TakeDamage(amount)

    local root = targetModel:FindFirstChild("HumanoidRootPart")

    if root and root:IsA("BasePart") then
        local direction = meta.direction

        if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.01 then
            local attackerCharacter = attacker.Character
            local attackerRoot = attackerCharacter
                and attackerCharacter:FindFirstChild("HumanoidRootPart")

            if attackerRoot and attackerRoot:IsA("BasePart") then
                direction = attackerRoot.CFrame.LookVector
            else
                direction = Vector3.zAxis
            end
        end

        if meta.knockback then
            root.AssemblyLinearVelocity =
                direction.Unit * tonumber(meta.knockback)
                + Vector3.new(0, tonumber(meta.lift) or 0, 0)
        end
    end

    local hitPosition = targetModel:GetPivot().Position

    if root and root:IsA("BasePart") then
        hitPosition = root.Position
    end

    context.fx(
        "Hit",
        hitPosition,
        {
            actor = targetModel,
            attacker = attacker.Character,
            damage = amount,
            reaction = meta.reaction or "Light",
            final = meta.final == true,
            tag = meta.tag or "Hit"
        }
    )

    if target.Health <= 0 then
        context.fx(
            "Death",
            hitPosition,
            {
                actor = targetModel,
                attacker = attacker.Character
            }
        )
    end

    return true
end

return DamageService