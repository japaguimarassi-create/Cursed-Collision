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

local CombatService = {}
CombatService.__index = CombatService

type AttackRecord = {
    AttackId: string,
    Token: number,
    StartedAt: number,
    HitAt: number,
    HitUntil: number,
    HitConsumed: boolean,
    Root: BasePart?
}

function CombatService.new(context: any)
    return setmetatable({
        Context = context,
        Abilities = AbilityService.new(context),
        ActiveM1 = {} :: {[Player]: AttackRecord}
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

local function finishM1(self, player: Player, attackId: string)
    local record = self.ActiveM1[player]
    if not record or record.AttackId ~= attackId then
        return
    end

    HitRegistry:End(player, attackId)
    self.ActiveM1[player] = nil

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == attackId then
        state.Vars.ActiveAttackId = nil
        state.RecoveryUntil = now() + 0.08
        StateManager:SetPhase(player, "Idle")
    end
end

function CombatService:M1(player: Player): boolean
    if not self:CanAttack(player) then
        return false
    end

    local t = now()
    if self.ActiveM1[player] then
        return false
    end

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
    state.AbilityToken += 1
    local token = state.AbilityToken

    if not StateManager:SetPhase(player, "Attacking") then
        return false
    end

    CooldownService:Set(player, "M1", Config.Combat.M1.Cooldown, t)

    local attackId = tostring(player.UserId) .. ":M1:" .. tostring(math.floor(t * 1000000))
    HitRegistry:Begin(player, attackId)
    state.Vars.ActiveAttackId = attackId

    local hitAt = t + attack.Startup
    local hitUntil = hitAt + attack.Active + 0.12

    self.ActiveM1[player] = {
        AttackId = attackId,
        Token = token,
        StartedAt = t,
        HitAt = hitAt,
        HitUntil = hitUntil,
        HitConsumed = false,
        Root = root
    }

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1Start",
        combo = attack.Combo,
        variant = attack.Variant,
        direction = root.CFrame.LookVector,
        attackId = attackId,
        fallbackHitDelay = attack.Startup
    })

    task.delay(attack.Startup + attack.Active + 0.20, function()
        finishM1(self, player, attackId)
    end)

    return true
end

function CombatService:M1Hit(player: Player, payload: {[string]: any}): boolean
    local record = self.ActiveM1[player]
    if not record or record.HitConsumed then
        return false
    end

    if type(payload.attackId) ~= "string" or payload.attackId ~= record.AttackId then
        return false
    end

    local state = StateManager:Get(player)
    local root = rootOf(player)
    if not state or not root or not self:IsAlive(player) then
        return false
    end

    local t = now()
    if state.AbilityToken ~= record.Token
        or t < record.HitAt - 0.11
        or t > record.HitUntil
        or state.StunnedUntil > t
        or state.RagdollUntil > t then
        return false
    end

    record.HitConsumed = true

    local attack = ComboService:Next
    -- Combo data is not advanced here; the original server-side attack context is authoritative.
    local comboNumber = math.clamp(tonumber(player:GetAttribute("ActiveM1Combo")) or state.Combo, 1, 4)
    local comboData = {
        Combo = comboNumber,
        Damage = Config.Combat.M1.Damage[comboNumber],
        Stun = Config.Combat.M1.Stun[comboNumber],
        Knockback = Config.Combat.M1.Knockback[comboNumber],
        Launch = Config.Combat.M1.Lift[comboNumber],
        Final = comboNumber == 4
    }

    local target = HitboxService:TargetsInBox(
        player,
        root.CFrame + root.CFrame.LookVector * Config.Combat.M1.Range * 0.46,
        Vector3.new(Config.Combat.M1.Width, Config.Combat.M1.Height, Config.Combat.M1.Range),
        32
    )[1]

    if target and not HitRegistry:Has(player, record.AttackId, target.model) then
        HitRegistry:Add(player, record.AttackId, target.model)
        self.Context.damage(
            player,
            target.humanoid,
            comboData.Damage,
            {
                stun = comboData.Stun,
                knockback = comboData.Knockback,
                lift = comboData.Launch,
                direction = root.CFrame.LookVector,
                final = comboData.Final,
                launch = comboData.Launch > 2,
                ragdoll = comboData.Final,
                ragdollDuration = comboData.Final and Config.Combat.M1.FinalRagdoll or nil,
                guardBreak = comboData.Final,
                reaction = comboData.Final and "Finisher" or "Light",
                tag = "M1_" .. tostring(comboNumber)
            }
        )
        return true
    end

    return false
end

function CombatService:SkillSlot(player: Player, slot: number): boolean
    return self.Abilities:Execute(player, slot)
end

function CombatService:SkillHit(player: Player, payload: {[string]: any}): boolean
    return self.Abilities:Hit(player, payload)
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

    if active then
        return StateManager:BeginBlock(player, Config.Combat.PerfectBlock.Window, t)
    end

    StateManager:EndBlock(player)
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
        if not state.Blocking and state.StunnedUntil <= t and state.RagdollUntil <= t then
            StateManager:SetPhase(player, "Idle")
        end
    end

    local activeM1 = self.ActiveM1[player]
    if activeM1 and t > activeM1.HitUntil + 0.20 then
        finishM1(self, player, activeM1.AttackId)
    end
end

function CombatService:ClearPlayer(player: Player)
    local activeM1 = self.ActiveM1[player]
    if activeM1 then
        HitRegistry:End(player, activeM1.AttackId)
        self.ActiveM1[player] = nil
    end
    self.Abilities:Cancel(player)
end

return CombatService
