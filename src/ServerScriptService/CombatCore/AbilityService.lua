--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local AbilityService: any = {}
AbilityService.__index = AbilityService

type Record = {
    token: number,
    attackId: string,
    slot: number,
    move: any,
    started: number,
    hitAt: number,
    hitWindowStart: number,
    hitWindowEnd: number,
    confirmed: boolean,
    cancelled: boolean
}

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {}
    }, AbilityService)
end

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
    local current: Record? = self.Active[player]
    if not current then
        return
    end

    current.cancelled = true
    HitRegistry:End(player, current.attackId)
    self.Active[player] = nil

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == current.attackId then
        state.Vars.ActiveAttackId = nil
    end
end

function AbilityService:Confirm(player: Player, attackId: string): boolean
    local record: Record? = self.Active[player]
    if not record or record.attackId ~= attackId or record.cancelled or record.confirmed then
        return false
    end

    local t = os.clock()

    if t < record.hitWindowStart or t > record.hitWindowEnd then
        return false
    end

    if not StateManager:IsAbilityValid(player, record.token) then
        self:Cancel(player)
        return false
    end

    record.confirmed = true

    local root = rootOf(player)
    if root then
        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = "Skill" .. tostring(record.slot),
            move = record.move.Name,
            phase = "HitFrame",
            attackId = attackId
        })
    end

    local success = CharacterService:SkillSlot(player, record.slot)
    return success
end

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local started = os.clock()

    if not StateManager:CanAct(player, started) then
        return false
    end

    local move = moveOf(player, slot)
    if not move then
        return false
    end

    local key = "Skill" .. tostring(slot)
    if not CooldownService:Ready(player, key, started) then
        return false
    end

    local token = StateManager:BeginAbility(player, key, started)
    if not token then
        return false
    end

    local timeline = Timeline:Get(move)
    local markers = Timeline:Markers(move)
    local attackId = tostring(player.UserId) .. ":" .. key .. ":" .. tostring(token)

    local record: Record = {
        token = token,
        attackId = attackId,
        slot = slot,
        move = move,
        started = started,
        hitAt = started + timeline.Startup,
        hitWindowStart = started + timeline.Startup - 0.05,
        hitWindowEnd = started + timeline.Startup + 0.16,
        confirmed = false,
        cancelled = false
    }

    HitRegistry:Begin(player, attackId)
    CooldownService:Set(player, key, math.clamp(tonumber(move.Cooldown) or 1, 0.25, 10), started)

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
            attackId = attackId,
            slot = slot,
            fallbackHitDelay = timeline.Startup
        })

        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = "SkillStart",
            move = move.Name,
            attackId = attackId,
            slot = slot,
            fallbackHitDelay = timeline.Startup
        })
    end

    task.delay(math.max(0, timeline.Startup + 0.09), function()
        local current: Record? = self.Active[player]
        if current == record and not record.confirmed and not record.cancelled then
            self:Confirm(player, attackId)
        end
    end)

    task.delay(math.max(0, timeline.Total), function()
        local current: Record? = self.Active[player]
        if current ~= record or record.cancelled then
            return
        end

        HitRegistry:End(player, attackId)

        local latestState = StateManager:Get(player)
        if latestState and latestState.Vars.ActiveAttackId == attackId then
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
