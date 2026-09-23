--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local CombatMarkerService = require(script.Parent.CombatMarkerService)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local AbilityService = {}
AbilityService.__index = AbilityService

export type ActiveAbility = {
    Token: number,
    AttackId: string,
    Slot: number,
    StartedAt: number,
    HitAt: number,
    Cancelled: boolean
}

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {} :: {[Player]: ActiveAbility}
    }, AbilityService)
end

local function moveOf(player: Player, slot: number)
    local id = tostring(player:GetAttribute("CharacterId") or "PotentialMan")
    return Movesets.GetMove(id, slot)
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

function AbilityService:Cancel(player: Player)
    local record = self.Active[player]
    if not record then
        return
    end

    record.Cancelled = true
    CombatMarkerService:Cancel(player, record.AttackId)
    HitRegistry:End(player, record.AttackId)
    self.Active[player] = nil

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == record.AttackId then
        state.Vars.ActiveAttackId = nil
        state.Vars.ActiveMove = nil
        if state.Phase == "UsingAbility" then
            StateManager:SetPhase(player, "Idle")
        end
    end
end

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local now = os.clock()

    if self.Active[player] or not StateManager:CanAct(player, now) then
        return false
    end

    local move = moveOf(player, slot)
    if not move then
        return false
    end

    local key = "Skill" .. tostring(slot)
    if not CooldownService:Ready(player, key, now) then
        return false
    end

    local token = StateManager:BeginAbility(player, key, now)
    if not token then
        return false
    end

    local root = rootOf(player)
    if not root then
        return false
    end

    local timeline = Timeline:Get(move)
    local markers = Timeline:Markers(move)
    local attackId = tostring(player.UserId) .. ":" .. key .. ":" .. tostring(token)

    HitRegistry:Begin(player, attackId)

    local cooldown = math.clamp(
        tonumber(move.Cooldown) or 1,
        Config.Combat.Skill.MinCooldown,
        Config.Combat.Skill.MaxCooldown
    )
    CooldownService:Set(player, key, cooldown, now)

    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveMove = move

    local record: ActiveAbility = {
        Token = token,
        AttackId = attackId,
        Slot = slot,
        StartedAt = now,
        HitAt = now + timeline.Startup,
        Cancelled = false
    }

    self.Active[player] = record

    self.Context.fx("AbilityTimeline", root.Position, {
        actor = player.Character,
        action = key,
        slot = slot,
        move = move.Name,
        phase = "Startup",
        markers = markers,
        attackId = attackId
    })

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "SkillStart",
        slot = slot,
        move = move.Name,
        phase = "Startup",
        attackId = attackId,
        hitDelay = timeline.Startup
    })

    local armed = CombatMarkerService:Begin(
        player,
        attackId,
        token,
        timeline.Startup,
        function()
            local currentState = StateManager:Get(player)

            if record.Cancelled
                or self.Active[player] ~= record
                or not currentState
                or currentState.Vars.ActiveAttackId ~= attackId
                or not StateManager:IsAbilityValid(player, token) then
                return
            end

            CharacterService:SkillSlot(player, slot)
        end,
        "Ability",
        Config.Combat.MarkerTiming.EarlyGrace,
        Config.Combat.MarkerTiming.NetworkGrace,
        root.Position,
        18
    )

    if not armed then
        self:Cancel(player)
        return false
    end

    task.delay(timeline.Total, function()
        if record.Cancelled then
            return
        end

        CombatMarkerService:Cancel(player, attackId)
        HitRegistry:End(player, attackId)

        local currentState = StateManager:Get(player)
        if currentState and currentState.Vars.ActiveAttackId == attackId then
            currentState.Vars.ActiveAttackId = nil
            currentState.Vars.ActiveMove = nil
            currentState.RecoveryUntil = os.clock() + timeline.Recovery

            if StateManager:IsAbilityValid(player, token) then
                StateManager:SetPhase(player, "Idle")
            end
        end

        if self.Active[player] == record then
            self.Active[player] = nil
        end
    end)

    return true
end

function AbilityService:ClearPlayer(player: Player)
    self:Cancel(player)
end

return AbilityService
