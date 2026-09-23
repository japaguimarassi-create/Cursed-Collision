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

type M1Record = {
    attackId: string,
    token: number,
    started: number,
    hitAt: number,
    hitWindowStart: number,
    hitWindowEnd: number,
    hit: boolean,
    attack: any
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
end

function CombatService:_finishM1(player: Player, record: M1Record)
    HitRegistry:End(player, record.attackId)

    if self.ActiveM1[player] == record then
        self.ActiveM1[player] = nil
    end

    local state = StateManager:Get(player)
    if not state then
        return
    end

    if state.Vars.ActiveAttackId == record.attackId then
        state.Vars.ActiveAttackId = nil
    end

    state.RecoveryUntil = now() + tonumber(record.attack.Recovery or 0.1)
    if not state.Blocking and state.StunnedUntil <= now() then
        StateManager:SetPhase(player, "Idle")
    end
end

function CombatService:ConfirmM1(player: Player, attackId: string): boolean
    local record = self.ActiveM1[player]
    if not record or record.attackId ~= attackId or record.hit then
        return false
    end

    local t = now()
    if t < record.hitWindowStart or t > record.hitWindowEnd then
        return false
    end

    local state = StateManager:Get(player)
    local root = rootOf(player)

    if not state
        or not root
        or state.AbilityToken ~= record.token
        or state.StunnedUntil > t
        or state.RagdollUntil > t
        or state.Phase ~= "Attacking" then
        return false
    end

    record.hit = true

    local attack = record.attack
    local target = HitboxService:TargetsInBox(
        player,
        root.CFrame + root.CFrame.LookVector * attack.Offset,
        attack.Hitbox,
        32
    )[1]

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

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Impact",
        combo = attack.Combo,
        attackId = attackId,
        hit = target ~= nil
    })

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

    if self.ActiveM1[player] then
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
    StateManager:SetPhase(player, "Attacking")
    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    local attackId = tostring(player.UserId) .. ":M1:" .. tostring(math.floor(t * 1000))
    local hitAt = t + attack.Startup

    local record: M1Record = {
        attackId = attackId,
        token = state.AbilityToken,
        started = t,
        hitAt = hitAt,
        hitWindowStart = hitAt - 0.05,
        hitWindowEnd = hitAt + 0.14,
        hit = false,
        attack = attack
    }

    self.ActiveM1[player] = record
    state.Vars.ActiveAttackId = attackId
    HitRegistry:Begin(player, attackId)

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Start",
        combo = attack.Combo,
        variant = attack.Variant,
        direction = root.CFrame.LookVector,
        attackId = attackId,
        fallbackHitDelay = attack.Startup
    })

    task.delay(math.max(0, attack.Startup + 0.08), function()
        if self.ActiveM1[player] == record and not record.hit then
            self:ConfirmM1(player, attackId)
        end
    end)

    task.delay(math.max(0, attack.Startup + attack.Active + attack.Recovery), function()
        if self.ActiveM1[player] == record then
            self:_finishM1(player, record)
        end
    end)

    return true
end

function CombatService:SkillSlot(player: Player, slot: number): boolean
    return self.Abilities:Execute(player, slot)
end

function CombatService:ConfirmSkill(player: Player, attackId: string): boolean
    return self.Abilities:Confirm(player, attackId)
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
        if not StateManager:BeginBlock(player, Config.Combat.PerfectBlock.Window, t) then
            return false
        end
    else
        StateManager:EndBlock(player)
    end

    MovementController:SetSprinting(player, false)

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
