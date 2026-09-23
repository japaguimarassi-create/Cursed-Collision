--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local MovementController = require(script.Parent.MovementController)
local ComboService = require(script.Parent.ComboService)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local AbilityService = require(script.Parent.AbilityService)
local EmoteService = require(script.Parent.EmoteService)

local CombatService = {}
CombatService.__index = CombatService

type M1Record = {
    attackId: string,
    token: number,
    startedAt: number,
    hitWindowStart: number,
    hitWindowEnd: number,
    attack: any,
    resolved: boolean
}

function CombatService.new(context: any)
    return setmetatable({
        Context = context,
        Abilities = AbilityService.new(context),
        ActiveM1 = {} :: {[Player]: M1Record}
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

    return StateManager:CanAct(player, t)
        and state.RecoveryUntil <= t
        and not state.Blocking
        and state.Phase ~= "UsingAbility"
        and state.Phase ~= "Ultimate"
        and state.Phase ~= "Awakening"
end

local function finishM1(self: any, player: Player, record: M1Record)
    local active = self.ActiveM1[player]
    if active ~= record then
        return
    end

    HitRegistry:End(player, record.attackId)
    self.ActiveM1[player] = nil

    local state = StateManager:Get(player)
    if not state then
        return
    end

    if state.Vars.ActiveAttackId == record.attackId then
        state.Vars.ActiveAttackId = nil
    end

    if state.AbilityToken == record.token
        and state.StunnedUntil <= now()
        and state.RagdollUntil <= now()
        and state.Phase == "Attacking" then
        state.RecoveryUntil = now() + tonumber(record.attack.Recovery) or now()
        StateManager:SetPhase(player, "Idle")
    end
end

function CombatService:_ResolveM1(player: Player, attackId: string): boolean
    local record = self.ActiveM1[player]

    if not record or record.attackId ~= attackId or record.resolved then
        return false
    end

    local state = StateManager:Get(player)
    local root = rootOf(player)
    local t = now()

    if not state or not root
        or state.AbilityToken ~= record.token
        or t < record.hitWindowStart
        or t > record.hitWindowEnd
        or state.StunnedUntil > t
        or state.RagdollUntil > t
        or state.Phase == "Dead" then
        return false
    end

    record.resolved = true

    local attack = record.attack
    local targets = HitboxService:TargetsInBox(
        player,
        root.CFrame + root.CFrame.LookVector * attack.Offset,
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
                direction = root.CFrame.LookVector,
                final = attack.Final,
                launch = attack.Launch > 2,
                ragdoll = attack.Final,
                ragdollDuration = attack.Final and Config.Combat.M1.FinalRagdoll or nil,
                guardBreak = attack.Final,
                reaction = attack.Final and "Finisher" or "Light",
                tag = "M1_" .. tostring(attack.Combo)
            }
        )
    end

    task.delay(attack.Active + attack.Recovery, function()
        finishM1(self, player, record)
    end)

    return true
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

    EmoteService:Stop(player)

    local attack = ComboService:Next(player, t)
    if not attack then
        return false
    end

    state.LastAction = "M1"
    StateManager:SetPhase(player, "Attacking")
    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    local attackId = tostring(player.UserId) .. ":M1:" .. tostring(math.floor(t * 1000))
    local hitWindowStart = t + math.max(0.025, attack.Startup - 0.08)
    local hitWindowEnd = t + attack.Startup + 0.32

    state.Vars.ActiveAttackId = attackId
    HitRegistry:Begin(player, attackId)

    local record: M1Record = {
        attackId = attackId,
        token = state.AbilityToken,
        startedAt = t,
        hitWindowStart = hitWindowStart,
        hitWindowEnd = hitWindowEnd,
        attack = attack,
        resolved = false
    }

    self.ActiveM1[player] = record

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Start",
        combo = attack.Combo,
        variant = attack.Variant,
        direction = root.CFrame.LookVector,
        attackId = attackId,
        marker = "Hit",
        markerRequired = AnimationData["M1_" .. tostring(attack.Combo)].AnimationId ~= ""
    })

    task.delay(math.max(0.03, attack.Startup + 0.32), function()
        self:_ResolveM1(player, attackId)
    end)

    return true
end

function CombatService:M1Hit(player: Player, attackId: string): boolean
    return self:_ResolveM1(player, attackId)
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
        or state.RagdollUntil > t
        or state.Blocking
        or state.Phase == "UsingAbility"
        or state.Phase == "Ultimate"
        or state.Phase == "Awakening"
        or not CooldownService:Ready(player, "Dash", t) then
        return false
    end

    EmoteService:Stop(player)

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
        air = humanoidOf(player)
            and (
                humanoidOf(player):GetState() == Enum.HumanoidStateType.Jumping
                or humanoidOf(player):GetState() == Enum.HumanoidStateType.Freefall
            )
            or false
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

    if state.StunnedUntil > t
        or state.RagdollUntil > t
        or state.Blocking == active
        or state.Phase == "UsingAbility"
        or state.Phase == "Ultimate"
        or state.Phase == "Awakening" then
        return false
    end

    if active then
        EmoteService:Stop(player)
        return StateManager:BeginBlock(
            player,
            Config.Combat.PerfectBlock.Window,
            t
        )
    end

    StateManager:EndBlock(player)
    MovementController:Combat(player)

    local root = rootOf(player)
    if root then
        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = "BlockEnd"
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

    EmoteService:Stop(player)

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
        StateManager:SetPhase(player, "Idle")
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

        if not state.Blocking
            and state.StunnedUntil <= t
            and state.RagdollUntil <= t
            and state.Phase == "Attacking" then
            StateManager:SetPhase(player, "Idle")
        end
    end
end

function CombatService:CancelPlayer(player: Player)
    local record = self.ActiveM1[player]
    if record then
        record.resolved = true
        finishM1(self, player, record)
    end
    self.Abilities:Cancel(player)
end

return CombatService
