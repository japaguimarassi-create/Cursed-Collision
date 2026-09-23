--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local StateManager = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local MovementController = require(script.Parent.MovementController)
local ComboService = require(script.Parent.ComboService)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local AbilityService = require(script.Parent.AbilityService)
local CombatMarkerService = require(script.Parent.CombatMarkerService)

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(context: any)
    return setmetatable({
        Context = context,
        Abilities = AbilityService.new(context)
    }, CombatService)
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

    if not StateManager:CanAct(player, t) then
        return false
    end

    if state.Phase == "Blocking"
        or state.Phase == "UsingAbility"
        or state.Phase == "Ultimate"
        or state.Phase == "Awakening" then
        return false
    end

    return state.RecoveryUntil <= t
end

local function finishAttack(
    player: Player,
    attackId: string,
    recovery: number
)
    local latest = StateManager:Get(player)
    if not latest or latest.Vars.ActiveAttackId ~= attackId then
        return
    end

    latest.Vars.ActiveAttackId = nil
    latest.RecoveryUntil = now() + recovery

    if latest.StunnedUntil <= now()
        and latest.RagdollUntil <= now()
        and not latest.Blocking then
        StateManager:SetPhase(player, "Idle")
    end
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

    local token = StateManager:NextActionToken(player)
    if not token then
        return false
    end

    state.LastAction = "M1"
    state.Vars.ActiveAttackId = tostring(player.UserId) .. ":M1:" .. tostring(token)
    state.RecoveryUntil = t + attack.Startup + attack.Active + attack.Recovery
    StateManager:SetPhase(player, "Attacking")

    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    local attackId = state.Vars.ActiveAttackId
    if type(attackId) ~= "string" then
        return false
    end

    HitRegistry:Begin(player, attackId)

    local function resolveHit()
        local current = StateManager:Get(player)
        if not current
            or current.ActionToken ~= token
            or current.Vars.ActiveAttackId ~= attackId
            or current.Phase ~= "Attacking"
            or current.StunnedUntil > now()
            or current.RagdollUntil > now() then
            HitRegistry:End(player, attackId)
            return
        end

        local currentRoot = rootOf(player)
        if not currentRoot then
            HitRegistry:End(player, attackId)
            finishAttack(player, attackId, attack.Recovery)
            return
        end

        local targets = HitboxService:TargetsInBox(
            player,
            currentRoot.CFrame + currentRoot.CFrame.LookVector * attack.Offset,
            attack.Hitbox,
            32
        )

        local target = targets[1]

        if target and not HitRegistry:Has(player, attackId, target.model) then
            HitRegistry:Add(player, attackId, target.model)

            self.Context.damage(
                player,
                target.humanoid,
                attack.Damage,
                {
                    stun = attack.Stun,
                    knockback = attack.Knockback,
                    lift = attack.Launch,
                    direction = currentRoot.CFrame.LookVector,
                    final = attack.Final,
                    launch = attack.Launch > 2,
                    ragdoll = attack.Final,
                    ragdollDuration = attack.Final
                        and Config.Combat.M1.FinalRagdoll
                        or nil,
                    guardBreak = attack.Final,
                    reaction = attack.Final and "Finisher" or "Light",
                    tag = "M1_" .. tostring(attack.Combo)
                }
            )
        end

        HitRegistry:End(player, attackId)
    end

    local armed = CombatMarkerService:Begin(
        player,
        attackId,
        token,
        attack.Startup,
        resolveHit,
        "Action",
        Config.Combat.MarkerTiming.EarlyGrace,
        Config.Combat.MarkerTiming.NetworkGrace,
        root.Position,
        8
    )

    if not armed then
        HitRegistry:End(player, attackId)
        state.Vars.ActiveAttackId = nil
        return false
    end

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Start",
        combo = attack.Combo,
        variant = attack.Variant,
        direction = root.CFrame.LookVector,
        attackId = attackId,
        hitDelay = attack.Startup
    })

    task.delay(attack.Startup + attack.Active + attack.Recovery, function()
        CombatMarkerService:Cancel(player, attackId)
        HitRegistry:End(player, attackId)
        finishAttack(player, attackId, attack.Recovery)
    end)

    return true
end

function CombatService:SkillSlot(player: Player, slot: number): boolean
    return self.Abilities:Execute(player, slot)
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
    state.LastAction = "Dash"
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
        air = humanoidOf(player)
            and (
                humanoidOf(player):GetState() == Enum.HumanoidStateType.Jumping
                or humanoidOf(player):GetState() == Enum.HumanoidStateType.Freefall
            )
    })

    task.delay(Config.Combat.Dash.Duration, function()
        local current = StateManager:Get(player)
        if current and current.Phase == "Dashing" then
            StateManager:SetPhase(player, "Idle")
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

    if active then
        if state.Phase == "Attacking"
            or state.Phase == "UsingAbility"
            or state.Phase == "Dashing"
            or state.Phase == "Ultimate"
            or state.Phase == "Awakening" then
            return false
        end

        if not StateManager:BeginBlock(
            player,
            Config.Combat.PerfectBlock.Window,
            t
        ) then
            return false
        end

        MovementController:Block(player)
    else
        StateManager:EndBlock(player)
        MovementController:Combat(player)
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

    local token = StateManager:NextActionToken(player)
    if not token then
        return false
    end

    local attackId = tostring(player.UserId) .. ":Special:" .. tostring(token)

    CooldownService:Set(player, "Special", cooldown, t)
    StateManager:SetPhase(player, "UsingAbility")
    state.Vars.ActiveAttackId = attackId
    state.LastAction = "Special"

    local hitDelay = 0.12

    local armed = CombatMarkerService:Begin(
        player,
        attackId,
        token,
        hitDelay,
        function()
            local current = StateManager:Get(player)
            if not current
                or current.ActionToken ~= token
                or current.Vars.ActiveAttackId ~= attackId
                or current.Phase ~= "UsingAbility"
                or not StateManager:CanAct(player, os.clock()) then
                return
            end

            CharacterService:Special(player)
        end,
        "Action",
        0.10,
        0.18,
        root.Position,
        8
    )

    if not armed then
        state.Vars.ActiveAttackId = nil
        StateManager:SetPhase(player, "Idle")
        return false
    end

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "SpecialStart",
        attackId = attackId,
        hitDelay = hitDelay,
        move = player:GetAttribute("SpecialName") or "Special"
    })

    task.delay(0.72, function()
        CombatMarkerService:Cancel(player, attackId)
        local current = StateManager:Get(player)
        if current and current.Vars.ActiveAttackId == attackId then
            finishAttack(player, attackId, 0.18)
        end
    end)

    return true
end

function CombatService:StepPlayer(player: Player)
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

        if not state.Blocking
            and state.StunnedUntil <= t
            and state.RagdollUntil <= t
            and state.Phase ~= "Dead" then
            if state.Phase ~= "Dashing"
                and state.Phase ~= "UsingAbility"
                and state.Phase ~= "Attacking" then
                StateManager:SetPhase(player, "Idle")
            end
        end
    end
end

return CombatService
