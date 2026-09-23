--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local MovementController = require(script.Parent.MovementController)
local ComboService = require(script.Parent.ComboService)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local AbilityService = require(script.Parent.AbilityService)

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(context: any)
    local self = setmetatable({
        Context = context
    }, CombatService)

    self.Abilities = AbilityService.new(context)
    return self
end

local function now(): number
    return os.clock()
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function humanoidOf(player: Player): Humanoid?
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

function CombatService:IsAlive(player: Player): boolean
    local humanoid = humanoidOf(player)
    return humanoid ~= nil and humanoid.Health > 0
end

function CombatService:CanAttack(player: Player): boolean
    local state = StateManager:Get(player)
    if not state or not self:IsAlive(player) then
        return false
    end

    local t = now()

    return StateManager:CanAct(player, t)
        and state.RecoveryUntil <= t
        and not state.Blocking
end

function CombatService:M1(player: Player): boolean
    if not self:CanAttack(player) then
        return false
    end

    local t = now()
    if not CooldownService:Ready(player, "M1", t) then
        return false
    end

    local state = StateManager:Get(player)
    local root = rootOf(player)
    if not state or not root then
        return false
    end

    local attack = ComboService:Next(player, t)
    if not attack then
        return false
    end

    state.LastAction = "M1"
    if not StateManager:SetPhase(player, "Attacking") then
        return false
    end

    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    state.Vars.M1Sequence = (tonumber(state.Vars.M1Sequence) or 0) + 1
    local attackId = tostring(player.UserId) .. ":M1:" .. tostring(state.Vars.M1Sequence)
    local activeM1 = {
        attackId = attackId,
        token = state.AbilityToken,
        startedAt = t,
        hitAt = t + attack.Startup,
        hitConfirmed = false,
        hitbox = attack.Hitbox,
        offset = attack.Offset,
        active = attack.Active,
        recovery = attack.Recovery,
        damage = attack.Damage,
        stun = attack.Stun,
        knockback = attack.Knockback,
        launch = attack.Launch,
        final = attack.Final,
        variant = attack.Variant
    }

    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveM1 = activeM1
    HitRegistry:Begin(player, attackId)

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Start",
        attackId = attackId,
        combo = attack.Combo,
        variant = attack.Variant,
        fallbackHitDelay = attack.Startup,
        direction = root.CFrame.LookVector
    })

    task.delay(attack.Startup + attack.Active + attack.Recovery, function()
        local latest = StateManager:Get(player)
        if not latest or latest.Vars.ActiveM1 ~= activeM1 then
            return
        end

        HitRegistry:End(player, attackId)
        latest.Vars.ActiveM1 = nil

        if latest.Vars.ActiveAttackId == attackId then
            latest.Vars.ActiveAttackId = nil
        end

        latest.RecoveryUntil = now() + 0.01

        if latest.StunnedUntil <= now()
            and latest.RagdollUntil <= now()
            and latest.Phase == "Attacking" then
            StateManager:SetPhase(player, "Idle")
        end
    end)

    return true
end

function CombatService:M1Hit(player: Player, attackId: string): boolean
    local state = StateManager:Get(player)
    if not state or type(attackId) ~= "string" then
        return false
    end

    local attack = state.Vars.ActiveM1
    if type(attack) ~= "table" or attack.attackId ~= attackId or attack.hitConfirmed then
        return false
    end

    if not self:IsAlive(player) or not StateManager:IsAbilityValid(player, attack.token) then
        return false
    end

    local t = now()
    local early = Config.Combat.Marker.EarlyTolerance
    local late = Config.Combat.Marker.LateTolerance
    local hitAt = tonumber(attack.hitAt) or t
    local activeDuration = tonumber(attack.active) or 0

    if t < hitAt - early or t > hitAt + activeDuration + late then
        return false
    end

    local root = rootOf(player)
    if not root then
        return false
    end

    attack.hitConfirmed = true

    local offset = tonumber(attack.offset) or 0
    local target = HitboxService:TargetsInBox(
        player,
        root.CFrame + root.CFrame.LookVector * offset,
        attack.hitbox,
        32
    )[1]

    if not target or HitRegistry:Has(player, attackId, target.model) then
        return false
    end

    HitRegistry:Add(player, attackId, target.model)

    return self.Context.damage(
        player,
        target.humanoid,
        tonumber(attack.damage) or 0,
        {
            stun = tonumber(attack.stun) or 0,
            knockback = tonumber(attack.knockback) or 0,
            lift = tonumber(attack.launch) or 0,
            direction = root.CFrame.LookVector,
            final = attack.final == true,
            launch = (tonumber(attack.launch) or 0) > 2,
            ragdoll = attack.final == true,
            ragdollDuration = attack.final and Config.Combat.M1.FinalRagdoll or nil,
            guardBreak = attack.final == true,
            reaction = attack.final and "Finisher" or "Light",
            tag = "M1_" .. tostring(state.Combo)
        }
    )
end

function CombatService:SkillSlot(player: Player, slot: number): boolean
    return self.Abilities:Execute(player, slot)
end

function CombatService:SkillHit(player: Player, attackId: string): boolean
    return self.Abilities:ConfirmHit(player, attackId)
end

function CombatService:Dash(player: Player, payload: string): boolean
    local state = StateManager:Get(player)
    local root = rootOf(player)

    if not state or not root or not self:IsAlive(player) then
        return false
    end

    local t = now()

    if state.StunnedUntil > t
        or state.Blocking
        or not CooldownService:Ready(player, "Dash", t) then
        return false
    end

    local direction: Vector3
    local speed: number

    if payload == "Back" then
        direction = -root.CFrame.LookVector
        speed = Config.Combat.Dash.BackSpeed
    elseif payload == "Left" then
        direction = -root.CFrame.RightVector
        speed = Config.Combat.Dash.SideSpeed
    elseif payload == "Right" then
        direction = root.CFrame.RightVector
        speed = Config.Combat.Dash.SideSpeed
    else
        direction = root.CFrame.LookVector
        speed = Config.Combat.Dash.ForwardSpeed
    end

    CooldownService:Set(player, "Dash", Config.Combat.Dash.Cooldown, t)

    state.DashUntil = t + math.min(
        Config.Combat.Dash.Invulnerable,
        Config.Combat.Dash.Duration
    )

    StateManager:SetPhase(player, "Dashing")
    root.AssemblyLinearVelocity = Vector3.new(
        direction.X * speed,
        root.AssemblyLinearVelocity.Y,
        direction.Z * speed
    )

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "Dash",
        dashDirection = payload,
        direction = direction,
        air = false
    })

    task.delay(Config.Combat.Dash.Duration, function()
        local current = StateManager:Get(player)
        if current and current.Phase == "Dashing" then
            current.Phase = "Idle"
            StateManager:Sync(player)
        end
    end)

    return true
end

function CombatService:SetBlock(player: Player, active: boolean): boolean
    local state = StateManager:Get(player)
    if not state or not self:IsAlive(player) then
        return false
    end

    local t = now()
    if state.StunnedUntil > t or state.Blocking == active then
        return false
    end

    state.Blocking = active
    player:SetAttribute("Blocking", active)

    if active then
        MovementController:Block(player)
    else
        MovementController:Combat(player)
    end

    if active then
        StateManager:SetPhase(player, "Blocking")
    else
        StateManager:EndBlock(player)
    end

    local root = rootOf(player)
    if root then
        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = active and "BlockStart" or "BlockEnd"
        })
    end

    return true
end

function CombatService:Special(player: Player): boolean
    local state = StateManager:Get(player)
    local root = rootOf(player)

    if not state or not root or not self:CanAttack(player) then
        return false
    end

    local t = now()
    local cooldown = CharacterService:GetSpecialCooldown(player)

    if not CooldownService:Ready(player, "Special", t) then
        return false
    end

    CooldownService:Set(player, "Special", cooldown, t)

    StateManager:SetPhase(player, "Attacking")
    state.RecoveryUntil = t + 0.55

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "Special",
        move = player:GetAttribute("SpecialName") or "Special"
    })

    local success = CharacterService:Special(player)

    if not success then
        CooldownService:Set(player, "Special", math.min(0.35, cooldown), t)
        state.RecoveryUntil = t + 0.12
    end

    return success
end

function CombatService:StepPlayer(player: Player): ()
    local state = StateManager:Get(player)
    if not state then
        return
    end

    local t = now()

    StateManager:ClearStunWhenReady(player, t)

    if state.DashUntil > 0 and state.DashUntil <= t then
        state.DashUntil = 0
    end

    if state.RecoveryUntil > 0 and state.RecoveryUntil <= t then
        state.RecoveryUntil = 0

        if not state.Blocking and state.StunnedUntil <= t then
            StateManager:SetPhase(player, "Idle")
        end
    end
end

return CombatService