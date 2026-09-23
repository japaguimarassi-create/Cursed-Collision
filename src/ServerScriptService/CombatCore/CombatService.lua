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
        Context = context,
        Abilities = nil,
        ActiveM1 = {}
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
    local character = player.Character
    if not state or not character then
        return false
    end

    local attack = ComboService:Next(player, t)
    if not attack then
        return false
    end

    state.LastAction = "M1"
    state.AbilityToken += 1
    local token = state.AbilityToken
    StateManager:SetPhase(player, "Attacking")

    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    local attackId = tostring(player.UserId)
        .. ":M1:"
        .. tostring(token)

    HitRegistry:Begin(player, attackId)

    state.Vars.ActiveAttackId = attackId

    local record = {
        attackId = attackId,
        token = token,
        combo = attack.Combo,
        character = character,
        confirmed = false,
        attack = attack
    }

    self.ActiveM1[player] = record

    local root = rootOf(player)
    if root then
        self.Context.fx("CombatAction", root.Position, {
            actor = character,
            action = "M1Start",
            combo = attack.Combo,
            variant = attack.Variant,
            attackId = attackId,
            fallbackHitDelay = attack.Startup,
            direction = root.CFrame.LookVector
        })
    end

    -- Fallback: sem um asset de animação/marker válido, o ataque ainda termina
    -- no frame de startup previsto. O HitRegistry impede uma segunda aplicação.
    task.delay(attack.Startup + 0.12, function()
        self:ConfirmM1Hit(player, attackId, token, "ServerFallback")
    end)

    task.delay(attack.Startup + attack.Active + attack.Recovery + 0.05, function()
        local latest = self.ActiveM1[player]
        if latest ~= record then
            return
        end

        HitRegistry:End(player, attackId)
        self.ActiveM1[player] = nil

        local current = StateManager:Get(player)
        if current and current.Vars.ActiveAttackId == attackId then
            current.Vars.ActiveAttackId = nil
            current.RecoveryUntil = now() + attack.Recovery

            if current.StunnedUntil <= now()
                and current.Phase == "Attacking" then
                StateManager:SetPhase(player, "Idle")
            end
        end
    end)

    return true
end

function CombatService:ConfirmM1Hit(
    player: Player,
    attackId: string,
    token: number,
    source: string
): boolean
    local record = self.ActiveM1[player]
    local state = StateManager:Get(player)

    if not record
        or record.attackId ~= attackId
        or record.token ~= token
        or record.confirmed
        or not state
        or state.AbilityToken ~= token
        or state.Vars.ActiveAttackId ~= attackId then
        return false
    end

    if not self:IsAlive(player) then
        return false
    end

    record.confirmed = true

    local root = rootOf(player)
    if not root then
        return false
    end

    local targets = HitboxService:TargetsInBox(
        player,
        root.CFrame + root.CFrame.LookVector * record.attack.Offset,
        record.attack.Hitbox,
        32
    )

    local target = targets[1]
    local success = false

    if target and not HitRegistry:Has(player, attackId, target.model) then
        HitRegistry:Add(player, attackId, target.model)

        success = self.Context.damage(
            player,
            target.humanoid,
            record.attack.Damage,
            {
                stun = record.attack.Stun,
                knockback = record.attack.Knockback,
                lift = record.attack.Launch,
                direction = root.CFrame.LookVector,
                final = record.attack.Final,
                launch = record.attack.Launch > 2,
                ragdoll = record.attack.Final,
                ragdollDuration = record.attack.Final
                    and Config.Combat.M1.FinalRagdoll
                    or nil,
                guardBreak = record.attack.Final,
                reaction = record.attack.Final and "Finisher" or "Light",
                tag = "M1_" .. tostring(record.combo)
            }
        )
    end

    CharacterService:OnM1Hit(player, record.combo, success)

    self.Context.fx("CombatMarker", root.Position, {
        actor = player.Character,
        action = "M1Hit",
        attackId = attackId,
        source = source,
        combo = record.combo,
        hit = success
    })

    return success
end

function CombatService:SkillSlot(player: Player, slot: number): boolean
    return self.Abilities:Execute(player, slot)
end

function CombatService:SkillHit(
    player: Player,
    attackId: string,
    token: number,
    source: string
): boolean
    return self.Abilities:ConfirmMarker(player, attackId, token, source)
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
        direction = direction
    })

    task.delay(Config.Combat.Dash.Duration, function()
        local current = StateManager:Get(player)
        if current and current.Phase == "Dashing" then
            current.Phase = "Idle"
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

    state.LastAction = "Special"
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

        if not state.Blocking and state.StunnedUntil <= t then
            if state.Phase == "Attacking" then
                StateManager:SetPhase(player, "Idle")
            end
        end
    end
end

function CombatService:ClearPlayer(player: Player)
    self.Abilities:Cancel(player)

    local record = self.ActiveM1[player]
    if record then
        record.confirmed = true
        HitRegistry:End(player, record.attackId)
        self.ActiveM1[player] = nil
    end
end

return CombatService
