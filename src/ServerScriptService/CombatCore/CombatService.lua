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
local CombatMarkerService = require(script.Parent.CombatMarkerService)
local AbilityService = require(script.Parent.AbilityService)
local EmoteService = require(script.Parent.EmoteService)

local CombatService = {}
CombatService.__index = CombatService

type M1Record = {
    AttackId: string,
    Token: number,
    Attack: any,
    Finished: boolean
}

type SpecialRecord = {
    AttackId: string,
    Token: number,
    Finished: boolean
}

function CombatService.new(context: any)
    return setmetatable({
        Context = context,
        Abilities = AbilityService.new(context),
        ActiveM1 = {} :: {[Player]: M1Record},
        ActiveSpecial = {} :: {[Player]: SpecialRecord}
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

function CombatService:_finishM1(player: Player, record: M1Record)
    local active = self.ActiveM1[player]
    if active ~= record or record.Finished then
        return
    end

    record.Finished = true
    HitRegistry:End(player, record.AttackId)
    CombatMarkerService:Cancel(player, record.AttackId)
    self.ActiveM1[player] = nil

    local state = StateManager:Get(player)
    if not state then
        return
    end

    if state.Vars.ActiveAttackId == record.AttackId then
        state.Vars.ActiveAttackId = nil
    end

    state.RecoveryUntil = now() + (tonumber(record.Attack.Recovery) or 0.1)

    if not state.Blocking and state.StunnedUntil <= now() then
        StateManager:SetPhase(player, "Idle")
    end
end

function CombatService:_applyM1(player: Player, attackId: string, attack: any): ()
    local record = self.ActiveM1[player]
    if not record or record.AttackId ~= attackId or record.Finished then
        return
    end

    local state = StateManager:Get(player)
    local root = rootOf(player)
    if not state or not root or record.Token ~= state.ActionToken then
        self:_finishM1(player, record)
        return
    end

    local target = HitboxService:TargetsInBox(
        player,
        root.CFrame + root.CFrame.LookVector * attack.Offset,
        attack.Hitbox,
        32
    )[1]

    local success = false

    if target and not HitRegistry:Has(player, attackId, target.model) then
        HitRegistry:Add(player, attackId, target.model)

        -- O marcador controla o instante do hit; o servidor continua dono do dano.
        success = self.Context.damage(
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

    CharacterService:OnM1Hit(
        player,
        attack.Combo,
        success
    )

    task.delay(
        (tonumber(attack.Active) or 0.05) + (tonumber(attack.Recovery) or 0.1),
        function()
            self:_finishM1(player, record)
        end
    )
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

    EmoteService:Stop(player)

    local token = StateManager:NextActionToken(player)
    if not token then
        return false
    end

    StateManager:SetPhase(player, "Attacking")
    state.LastAction = "M1"
    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    local attackId = tostring(player.UserId)
        .. ":M1:"
        .. tostring(token)
        .. ":"
        .. tostring(math.floor(t * 1000))

    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveMove = attack
    HitRegistry:Begin(player, attackId)

    local animationKey = "M1_" .. tostring(attack.Combo)
    local animationDefinition = AnimationData[animationKey]

    self.ActiveM1[player] = {
        AttackId = attackId,
        Token = token,
        Attack = attack,
        Finished = false
    }

    CombatMarkerService:Begin(
        player,
        attackId,
        token,
        attack.Startup,
        function()
            self:_applyM1(player, attackId, attack)
        end,
        "Action",
        Config.Combat.Marker.EarlyTolerance,
        Config.Combat.Marker.LateTolerance,
        root.Position,
        22
    )

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Start",
        combo = attack.Combo,
        variant = attack.Variant,
        direction = root.CFrame.LookVector,
        attackId = attackId,
        marker = "Hit",
        markerRequired = animationDefinition ~= nil
            and animationDefinition.AnimationId ~= "",
        fallbackHitDelay = attack.Startup
    })

    return true
end

function CombatService:SkillSlot(player: Player, slot: number): boolean
    return self.Abilities:Execute(player, slot)
end

function CombatService:Dash(player: Player, payload: string): boolean
    local state = StateManager:Get(player)
    local root = rootOf(player)
    local humanoid = humanoidOf(player)

    if not state or not root or not humanoid or not self:IsAlive(player) then
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

    local humanoidState = humanoid:GetState()

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "Dash",
        dashDirection = payload,
        direction = direction,
        air = humanoidState == Enum.HumanoidStateType.Jumping
            or humanoidState == Enum.HumanoidStateType.Freefall
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
    if not CooldownService:Ready(
        player,
        "Special",
        t
    ) then
        return false
    end

    EmoteService:Stop(player)

    local token = StateManager:NextActionToken(player)
    if not token then
        return false
    end

    local cooldown = CharacterService:GetSpecialCooldown(player)
    local attackId = tostring(player.UserId)
        .. ":Special:"
        .. tostring(token)
        .. ":"
        .. tostring(math.floor(t * 1000))

    state.Vars.ActiveAttackId = attackId

    StateManager:SetPhase(player, "Attacking")
    state.RecoveryUntil = t + 0.55
    CooldownService:Set(player, "Special", cooldown, t)

    self.ActiveSpecial[player] = {
        AttackId = attackId,
        Token = token,
        Finished = false
    }

    CombatMarkerService:Begin(
        player,
        attackId,
        token,
        0.12,
        function()
            local active = self.ActiveSpecial[player]
            local currentState = StateManager:Get(player)
            if not active or active.Finished or not currentState then
                return
            end

            if currentState.Vars.ActiveAttackId ~= attackId then
                return
            end

            active.Finished = true
            CharacterService:Special(player)
        end,
        "Action",
        Config.Combat.Marker.EarlyTolerance,
        Config.Combat.Marker.LateTolerance,
        root.Position,
        18
    )

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "SpecialStart",
        move = player:GetAttribute("SpecialName") or "Special",
        attackId = attackId,
        marker = "Hit",
        markerRequired = AnimationData.Special.AnimationId ~= "",
        fallbackHitDelay = 0.12
    })

    task.delay(0.68, function()
        local current = StateManager:Get(player)
        local record = self.ActiveSpecial[player]

        if current and record and record.AttackId == attackId then
            record.Finished = true
            CombatMarkerService:Cancel(player, attackId)
            self.ActiveSpecial[player] = nil

            if current.Vars.ActiveAttackId == attackId then
                current.Vars.ActiveAttackId = nil
            end

            if current.StunnedUntil <= now()
                and current.RagdollUntil <= now()
                and current.Phase == "Attacking" then
                StateManager:SetPhase(player, "Idle")
            end
        end
    end)

    return true
end

function CombatService:CancelPlayer(player: Player)
    local m1 = self.ActiveM1[player]
    if m1 then
        self:_finishM1(player, m1)
    end

    local special = self.ActiveSpecial[player]
    if special then
        special.Finished = true
        CombatMarkerService:Cancel(player, special.AttackId)
        self.ActiveSpecial[player] = nil
    end

    self.Abilities:Cancel(player)
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

return CombatService
