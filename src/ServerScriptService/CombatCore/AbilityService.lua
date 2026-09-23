--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local CombatMarkerService = require(script.Parent.CombatMarkerService)

local AbilityService = {}
AbilityService.__index = AbilityService

type ActiveAbility = {
    Token: number,
    AttackId: string,
    Cancelled: boolean
}

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {} :: {[Player]: ActiveAbility}
    }, AbilityService)
end

local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local function moveOf(player: Player, slot: number)
    local id = player:GetAttribute("CharacterId") or "PotentialMan"
    return Movesets.GetMove(id, slot)
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
end

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local now = os.clock()

    if not StateManager:CanAct(player, now) then
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

    local timeline = Timeline:Get(move)
    local markers = Timeline:Markers(move)
    local attackId = tostring(player.UserId) .. ":" .. key .. ":" .. tostring(token)

    HitRegistry:Begin(player, attackId)

    local cooldown = math.clamp(
        tonumber(move.Cooldown) or 1,
        0.25,
        10
    )

    CooldownService:Set(player, key, cooldown, now)

    local record: ActiveAbility = {
        Token = token,
        AttackId = attackId,
        Cancelled = false
    }

    self.Active[player] = record
    state.Vars.ActiveAttackId = attackId

    local root = rootOf(player)

    if root then
        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = key,
            move = move.Name,
            phase = "Startup",
            markers = markers,
            attackId = attackId
        })

        -- A animação é iniciada pela camada de apresentação; o servidor cria
        -- a janela autoritativa na qual o marcador "Hit" pode confirmar o golpe.
        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = "SkillStart",
            slot = slot,
            move = move.Name,
            attackId = attackId,
            hitDelay = timeline.Startup
        })
    end

    local armed = CombatMarkerService:Begin(
        player,
        attackId,
        token,
        timeline.Startup,
        function()
            if record.Cancelled
                or self.Active[player] ~= record
                or not StateManager:IsAbilityValid(player, token) then
                return
            end

            local currentState = StateManager:Get(player)
            if not currentState
                or currentState.Vars.ActiveAttackId ~= attackId then
                return
            end

            CharacterService:SkillSlot(player, slot)
        end,
        "Ability",
        Config.Combat.MarkerTiming.EarlyGrace,
        Config.Combat.MarkerTiming.NetworkGrace
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

        local latestState = StateManager:Get(player)
        if latestState and latestState.Vars.ActiveAttackId == attackId then
            latestState.Vars.ActiveAttackId = nil

            if StateManager:IsAbilityValid(player, token) then
                latestState.RecoveryUntil = os.clock() + timeline.Recovery
                StateManager:SetPhase(player, "Idle")
            end
        end

        if self.Active[player] == record then
            self.Active[player] = nil
        end
    end)

    return true
end

return AbilityService
