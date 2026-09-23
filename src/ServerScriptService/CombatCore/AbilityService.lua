--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local AnimationData = require(ReplicatedStorage.Animation.AnimationData)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)

local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local CombatMarkerService = require(script.Parent.CombatMarkerService)
local EmoteService = require(script.Parent.EmoteService)

local AbilityService = {}
AbilityService.__index = AbilityService

type ActiveAbility = {
    Token: number,
    AttackId: string,
    Slot: number,
    Cancelled: boolean
}

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {} :: {[Player]: ActiveAbility}
    }, AbilityService)
end


local function moveOf(player: Player, slot: number)
    return CharacterService:GetMove(player, slot)
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

function AbilityService:Cancel(player: Player)
    local current = self.Active[player]
    if not current then
        return
    end

    current.Cancelled = true
    CombatMarkerService:Cancel(player, current.AttackId)
    HitRegistry:End(player, current.AttackId)
    self.Active[player] = nil

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == current.AttackId then
        state.Vars.ActiveAttackId = nil
    end
end

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local now = os.clock()

    if not StateManager:CanAct(player, now)
        or state.Blocking
        or state.RecoveryUntil > now
        or state.Phase == "Attacking"
        or state.Phase == "Dashing"
        or state.Phase == "Ultimate"
        or state.Phase == "Awakening" then
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

    EmoteService:Stop(player)

    local token = StateManager:BeginAbility(player, key, now)
    if not token then
        return false
    end

    local timeline = Timeline:Get(move)
    local markers = Timeline:Markers(move)
    local attackId = tostring(player.UserId)
        .. ":"
        .. key
        .. ":"
        .. tostring(token)
    local animationDefinition = AnimationData[key]

    HitRegistry:Begin(player, attackId)

    local cooldown = math.clamp(
        tonumber(move.Cooldown) or 1,
        0.25,
        10
    )

    CooldownService:Set(player, key, cooldown, now)

    self.Active[player] = {
        Token = token,
        AttackId = attackId,
        Slot = slot,
        Cancelled = false
    }

    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveMove = move

    local root = rootOf(player)
    if not root then
        self:Cancel(player)
        return false
    end

    -- O cliente apenas relata o marcador visual; o servidor valida a janela e executa o hit.
    CombatMarkerService:Begin(
        player,
        attackId,
        token,
        timeline.Startup,
        function()
            local current = self.Active[player]
            local currentState = StateManager:Get(player)
            if not current or current.Cancelled or not currentState then
                return
            end

            if currentState.Vars.ActiveAttackId ~= attackId then
                return
            end

            CharacterService:SkillSlot(player, slot)
        end,
        "Ability",
        Config.Combat.Marker.EarlyTolerance,
        Config.Combat.Marker.LateTolerance,
        root.Position,
        30
    )

    self.Context.fx("AbilityTimeline", root.Position, {
        actor = player.Character,
        action = key,
        move = move.Name,
        phase = "Startup",
        markers = markers,
        attackId = attackId,
        marker = "Hit"
    })

    self.Context.fx("CombatAction", root.Position, {
        actor = player.Character,
        action = "SkillStart",
        slot = slot,
        move = move.Name,
        attackId = attackId,
        phase = "Startup",
        marker = "Hit",
        markerRequired = animationDefinition ~= nil
            and animationDefinition.AnimationId ~= "",
        fallbackHitDelay = timeline.Startup
    })

    task.delay(timeline.Total, function()
        local current = self.Active[player]
        if not current or current.AttackId ~= attackId or current.Cancelled then
            return
        end

        CombatMarkerService:Cancel(player, attackId)
        HitRegistry:End(player, attackId)

        local latestState = StateManager:Get(player)
        if latestState
            and latestState.Vars.ActiveAttackId == attackId then
            latestState.Vars.ActiveAttackId = nil
        end

        if latestState and StateManager:IsAbilityValid(player, token) then
            StateManager:SetPhase(player, "Idle")
        end

        self.Active[player] = nil
    end)

    return true
end

return AbilityService
