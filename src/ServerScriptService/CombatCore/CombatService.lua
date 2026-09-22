--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HitboxService = require(ReplicatedStorage.Combat.HitboxService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local StateManager = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local MovementController = require(script.Parent.MovementController)

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(context)
    return setmetatable({
        Context = context
    }, CombatService)
end

local function now()
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

    return state.StunnedUntil <= t
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

    if t - state.LastM1 > Config.Combat.M1.ComboReset then
        state.Combo = 0
    end

    state.Combo = math.clamp(
        state.Combo + 1,
        1,
        Config.Combat.M1.MaxCombo
    )

    state.LastM1 = t
    state.Phase = "Attack"

    CooldownService:Set(
        player,
        "M1",
        Config.Combat.M1.Cooldown,
        t
    )

    local combo = state.Combo
    local final = combo == Config.Combat.M1.MaxCombo
    local direction = root.CFrame.LookVector

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "M1",
        combo = combo,
        direction = direction
    })

    local target = HitboxService:NearestTargetInFront(
        player,
        Config.Combat.M1.Range,
        Config.Combat.M1.Width,
        Config.Combat.M1.Height
    )

    if not target then
        state.RecoveryUntil = t + (final and 0.28 or 0.11)

        if final then
            state.Combo = 0
        end

        return true
    end

    local success = self.Context.damage(
        player,
        target.humanoid,
        Config.Combat.M1.Damage[combo],
        {
            stun = Config.Combat.M1.Stun[combo],
            knockback = Config.Combat.M1.Knockback[combo],
            lift = Config.Combat.M1.Lift[combo],
            direction = direction,
            final = final,
            reaction = final and "Finisher" or "Light",
            tag = "M1_" .. tostring(combo)
        }
    )

    state.RecoveryUntil = t + (final and 0.28 or 0.11)

    if final then
        state.Combo = 0
    end

    return success
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

    local direction
    local speed

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

    CooldownService:Set(
        player,
        "Dash",
        Config.Combat.Dash.Cooldown,
        t
    )

    state.DashUntil = t + math.min(
        Config.Combat.Dash.Invulnerable,
        Config.Combat.Dash.Duration
    )

    state.Phase = "Dash"

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

        if current and current.Phase == "Dash" then
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
    state.Phase = active and "Block" or "Idle"
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

    state.Phase = "Attack"
    state.RecoveryUntil = t + 0.55

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "Special",
        move = player:GetAttribute("SpecialName") or "Special"
    })

    local success = CharacterService:Special(player)

    if not success then
        CooldownService:Set(
            player,
            "Special",
            math.min(0.35, cooldown),
            t
        )

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
            state.Phase = "Idle"
        end
    end
end

return CombatService