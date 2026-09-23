--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StateManager: any = require(script.Parent.StateManager)
local MovementController: any = require(script.Parent.MovementController)
local RagdollService: any = require(script.Parent.RagdollService)
local GamePassService: any = require(ReplicatedStorage.Monetization.GamePassService)
local UltimateService: any = require(script.Parent.UltimateService)
local EmoteService: any = require(script.Parent.EmoteService)
local CharacterService: any = require(ReplicatedStorage.Characters.CharacterService)

local DamageService = {}
local context: any = nil

function DamageService:Configure(newContext: any)
    context = newContext
end

local function alive(humanoid: Humanoid): boolean
    return humanoid.Parent ~= nil and humanoid.Health > 0
end

local function impactReaction(meta: any): string
    if meta.ragdoll then
        return "Ragdoll"
    end
    if meta.final then
        return "Finisher"
    end
    if meta.slam then
        return "Slam"
    end
    if meta.launch then
        return "Launch"
    end
    if meta.guardBreak then
        return "Heavy"
    end
    return meta.reaction or "Light"
end

function DamageService:Apply(
    attacker: Player,
    target: Humanoid,
    amount: number,
    meta: any
): boolean
    meta = type(meta) == "table" and meta or {}

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

    -- Dano confirmado encerra emote imediatamente no servidor.
    if targetPlayer then
        EmoteService:Stop(targetPlayer)
    end

    local now = os.clock()

    if targetPlayer then
        local targetState: any = StateManager:Get(targetPlayer)

        if targetState then
            if targetState.InvulnerableUntil > now
                or targetState.DashUntil > now
                or targetState.Phase == "Dead" then
                return false
            end

            if targetState.Blocking and not meta.guardBreak then
                if targetState.PerfectBlockUntil > now then
                    local attackerState: any = StateManager:Get(attacker)
                    if attackerState then
                        EmoteService:Stop(attacker)
                        StateManager:SetStun(
                            attacker,
                            Config.Combat.PerfectBlock.Stun,
                            now
                        )
                    end

                    local root = targetModel:FindFirstChild("HumanoidRootPart")
                    if root and root:IsA("BasePart") then
                        context.fx("PerfectBlock", root.Position, {
                            actor = targetModel,
                            attacker = attacker.Character,
                            reaction = "Parry",
                            stun = Config.Combat.PerfectBlock.Stun
                        })
                    end

                    return false
                end

                amount *= Config.Combat.Block.DamageMultiplier
                target:TakeDamage(amount)
                EmoteService:Stop(targetPlayer)

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

            amount = CharacterService:OnIncomingDamage(
                targetPlayer,
                amount,
                meta
            )

            if amount <= 0 then
                return false
            end

            StateManager:SetStun(
                targetPlayer,
                math.max(0, tonumber(meta.stun) or 0.2),
                now
            )
            MovementController:Stun(targetPlayer)
        end
    end

    target:TakeDamage(amount)
    if targetPlayer then
        EmoteService:Stop(targetPlayer)
    end
    UltimateService:AddMeter(attacker, amount)

    local root = targetModel:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        local direction = meta.direction

        if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.01 then
            local attackerRoot = attacker.Character
                and attacker.Character:FindFirstChild("HumanoidRootPart")

            direction = if attackerRoot and attackerRoot:IsA("BasePart")
                then attackerRoot.CFrame.LookVector
                else Vector3.zAxis
        end

        if meta.knockback then
            local strength = math.max(0, tonumber(meta.knockback) or 0)
            local lift = tonumber(meta.lift) or 0

            root.AssemblyLinearVelocity =
                direction.Unit * strength
                + Vector3.new(0, lift, 0)
        end

        if meta.slam then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X * 0.35,
                -math.max(10, tonumber(meta.slamForce) or 45),
                root.AssemblyLinearVelocity.Z * 0.35
            )
        end
    end

    if targetPlayer and (meta.ragdoll or meta.final and meta.ragdoll ~= false) then
        RagdollService:Apply(
            targetPlayer,
            tonumber(meta.ragdollDuration) or Config.Combat.M1.FinalRagdoll,
            impactReaction(meta)
        )
    end

    local hitPosition = targetModel:GetPivot().Position
    if root and root:IsA("BasePart") then
        hitPosition = root.Position
    end

    context.fx("Hit", hitPosition, {
        actor = targetModel,
        attacker = attacker.Character,
        damage = amount,
        reaction = impactReaction(meta),
        final = meta.final == true,
        guardBreak = meta.guardBreak == true,
        ragdoll = meta.ragdoll == true,
        tag = meta.tag or "Hit"
    })

    if target.Health <= 0 then
        if targetPlayer then
            local state = StateManager:Get(targetPlayer)
            if state then
                state.Phase = "Dead"
                state.Blocking = false
                StateManager:Sync(targetPlayer)
            end
        end

        context.fx("Death", hitPosition, {
            actor = targetModel,
            attacker = attacker.Character
        })

        GamePassService:NotifyKill(attacker)
    end

    return true
end

return DamageService
