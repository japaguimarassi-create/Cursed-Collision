--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local QuestService = require(ReplicatedStorage.Economy.QuestService)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager = require(script.Parent.StateManager)
local MovementController = require(script.Parent.MovementController)
local RagdollService = require(script.Parent.RagdollService)

local DamageService = {}
local context = {}

function DamageService:Configure(newContext)
    context = newContext or {}
end

local function now()
    return os.clock()
end

local function stun(player: Player, duration: number)
    local state = StateManager:Get(player)
    if not state then
        return
    end

    local untilTime = now() + math.max(0, duration)
    state.StunnedUntil = math.max(state.StunnedUntil, untilTime)
    state.Phase = "HitReact"
    MovementController:Stun(player)

    task.delay(math.max(0.03, duration) + 0.04, function()
        if not player.Parent then
            return
        end
        local current = StateManager:Get(player)
        if not current or current.StunnedUntil > now() then
            return
        end
        if not current.Blocking and not current.Clash and not current.Dodging and not current.Awakening then
            current.Phase = "Idle"
            MovementController:Combat(player)
        end
    end)
end

local function rootOfCharacter(character: Model): BasePart?
    local root = character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function detectWall(root: BasePart, direction: Vector3): boolean
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {root.Parent}
    local result = Workspace:Raycast(root.Position, direction.Unit * 3.8, rayParams)
    return result ~= nil
end

function DamageService:Apply(attacker: Player, humanoid: Humanoid, amount: number, meta)
    meta = meta or {}

    if not humanoid or humanoid.Health <= 0 or type(amount) ~= "number" or amount <= 0 then
        return false
    end

    local targetCharacter = humanoid.Parent
    if not targetCharacter or not targetCharacter:IsA("Model") then
        return false
    end

    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    local isDummy = targetCharacter:GetAttribute("TrainingDummy") == true
    if (not targetPlayer and not isDummy) or targetPlayer == attacker then
        return false
    end

    local attackerState = StateManager:Get(attacker)
    local targetState = targetPlayer and StateManager:Get(targetPlayer) or nil
    if not attackerState then
        return false
    end

    local t = now()
    if targetState then
        if targetState.Clash then
            return false
        end

        if targetState.Dodging and targetState.DodgeUntil > t then
            context.fx("DodgeEvaded", targetCharacter, targetPlayer.UserId)
            return false
        end

        if targetState.CounterUntil > t and not meta.bypassCounter then
            targetState.CounterUntil = 0
            local attackerRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
            if attackerRoot then
                attackerRoot.AssemblyLinearVelocity = -attackerRoot.CFrame.LookVector * 24 + Vector3.new(0, 10, 0)
            end
            stun(attacker, Config.Combat.Counter.Stun)
            context.fx("Counter", rootOfCharacter(targetCharacter) and rootOfCharacter(targetCharacter).Position or targetCharacter:GetPivot().Position, {
                actor = targetCharacter,
                attacker = attacker.Character
            })
            return false
        end
    end

    local finalAmount = amount

    if targetState and targetState.PerfectBlockUntil > t and not meta.bypassBlock then
        targetState.PerfectBlockUntil = 0
        stun(attacker, Config.Combat.Block.PerfectStun)
        context.fx("PerfectBlock", targetCharacter:GetPivot().Position, {
            actor = targetCharacter,
            attacker = attacker.Character,
        })
        return false
    end

    if targetState and targetState.Blocking and not meta.guardBreak then
        finalAmount *= (1 - Config.Combat.Block.DamageReduction)
    end

    if targetPlayer then
        finalAmount = tonumber(CharacterService:IncomingDamage(targetPlayer, finalAmount)) or finalAmount
    end

    if finalAmount <= 0 then
        return false
    end

    humanoid:TakeDamage(finalAmount)

    local reaction = meta.reaction or (
        meta.slam and "Slam"
        or meta.launch and "Launcher"
        or meta.knockback and meta.knockback >= 55 and "Heavy"
        or "Light"
    )

    context.fx("HitReaction", targetCharacter, math.clamp(finalAmount / 18, 0.55, 2), reaction)
    context.fx("DamageNumber", targetCharacter, math.max(1, math.floor(finalAmount + 0.5)), meta.tag or reaction)

    local targetRoot = rootOfCharacter(targetCharacter)
    local attackerRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")

    if targetRoot and attackerRoot and not targetRoot.Anchored then
        local delta = targetRoot.Position - attackerRoot.Position
        if delta.Magnitude > 0.01 then
            local direction = delta.Unit
            local velocity = direction * (tonumber(meta.knockback) or 0)

            if meta.launch then
                velocity += Vector3.new(0, tonumber(meta.launchPower) or 54, 0)
            elseif meta.slam then
                velocity = Vector3.new(direction.X * 10, -math.abs(tonumber(meta.slamPower) or 70), direction.Z * 10)
            elseif meta.knockback and meta.knockback > 0 then
                velocity += Vector3.new(0, tonumber(meta.lift) or 8, 0)
            end

            targetRoot.AssemblyLinearVelocity = velocity

            if meta.wallCheck and velocity.Magnitude > 45 and detectWall(targetRoot, direction) then
                humanoid:TakeDamage(math.min(8, humanoid.Health))
                if targetPlayer then
                    stun(targetPlayer, Config.Combat.Wall.Stun)
                end
                RagdollService:Apply(targetCharacter, Config.Combat.Wall.RagdollDuration, "WallImpact")
                context.fx("WallImpact", targetRoot.Position, {
                    actor = targetCharacter,
                    tag = meta.tag or "WallImpact",
                })
            end
        end
    end

    if targetPlayer then
        if meta.stun then
            stun(targetPlayer, meta.stun)
        end
        if meta.ragdoll or reaction == "Slam" or reaction == "Launcher" then
            RagdollService:Apply(targetCharacter, math.clamp(tonumber(meta.ragdollDuration) or 0.55, 0.25, 1.6), reaction)
        end
    end

    if targetRoot then
        context.fx("Hit", targetRoot.Position, {
            tag = meta.tag or reaction,
            reaction = reaction,
            heavy = reaction ~= "Light",
        })
    end

    local attackerCharacterId = attacker:GetAttribute("CharacterId")
    QuestService:Record(attacker, "Damage", finalAmount, attackerCharacterId)

    local awakenGain = tonumber(meta.awakeningGain) or Config.Awakening.GainDamageDealt
    local currentAwakening = attacker:GetAttribute("Awakening") or 0
    if not attacker:GetAttribute("AwakeningActive") then
        attacker:SetAttribute("Awakening", math.clamp(currentAwakening + awakenGain, 0, Config.Awakening.Max))
    end

    if targetPlayer then
        local targetAwakening = targetPlayer:GetAttribute("Awakening") or 0
        if not targetPlayer:GetAttribute("AwakeningActive") then
            targetPlayer:SetAttribute("Awakening", math.clamp(targetAwakening + Config.Awakening.GainDamageTaken, 0, Config.Awakening.Max))
        end
    end

    if humanoid.Health <= 0 then
        if targetPlayer then
            DataService:AddCredits(attacker, 5)
            DataService:AddKill(attacker)
            DataService:AddDeath(targetPlayer)
            QuestService:Record(attacker, "Kill", 1, attackerCharacterId)
            context.fx("KillFeed", Vector3.zero, {
                attackerName = attacker:GetAttribute("CharacterName") or attacker.Name,
                victimName = targetPlayer:GetAttribute("CharacterName") or targetPlayer.Name,
                tag = meta.tag or reaction,
            })
            context.fx("DeathReaction", targetCharacter, {
                actor = targetCharacter,
                reaction = "Death",
            })
            context.account(attacker, "Notice", {
                Message = "+5 Credits • Kill",
                Success = true,
            })
        else
            context.account(attacker, "Notice", {
                Message = "Training Dummy • K.O.",
                Success = true,
            })
        end
    end

    return true
end

return DamageService
