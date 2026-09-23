--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)

local AbilityService: any = {}
AbilityService.__index = AbilityService

type AbilityRecord = {
    Token: number,
    AttackId: string,
    Slot: number,
    StartedAt: number,
    HitAt: number,
    HitUntil: number,
    HitConsumed: boolean,
    Cancelled: boolean
}

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {} :: {[Player]: AbilityRecord}
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
    local current = self.Active[player]
    if not current then
        return
    end

    current.Cancelled = true
    HitRegistry:End(player, current.AttackId)

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == current.AttackId then
        state.Vars.ActiveAttackId = nil
        state.Vars.ActiveMove = nil
        if state.Phase == "UsingAbility" then
            StateManager:SetPhase(player, "Idle")
        end
    end

    self.Active[player] = nil
end

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local t = os.clock()
    if self.Active[player] or not StateManager:CanAct(player, t) then
        return false
    end

    local move = moveOf(player, slot)
    if not move then
        return false
    end

    local key = "Skill" .. tostring(slot)
    if not CooldownService:Ready(player, key, t) then
        return false
    end

    local token = StateManager:BeginAbility(player, key, t)
    if not token then
        return false
    end

    local timeline = Timeline:Get(move)
    local markers = Timeline:Markers(move)
    local attackId = tostring(player.UserId) .. ":" .. key .. ":" .. tostring(token)

    HitRegistry:Begin(player, attackId)

    local cooldown = math.clamp(tonumber(move.Cooldown) or 1, 0.25, 10)
    CooldownService:Set(player, key, cooldown, t)

    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveMove = move

    local record: AbilityRecord = {
        Token = token,
        AttackId = attackId,
        Slot = slot,
        StartedAt = t,
        HitAt = t + timeline.Startup,
        HitUntil = t + timeline.Startup + timeline.Active + 0.16,
        HitConsumed = false,
        Cancelled = false
    }

    self.Active[player] = record

    local root = rootOf(player)
    if root then
        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = "SkillStart",
            slot = slot,
            move = move.Name,
            phase = "Startup",
            markers = markers,
            attackId = attackId,
            fallbackHitDelay = timeline.Startup
        })
    end

    task.delay(timeline.Total + 0.22, function()
        local current = self.Active[player]
        if current and current.AttackId == attackId then
            self:Finish(player, attackId)
        end
    end)

    return true
end

function AbilityService:Hit(player: Player, payload: {[string]: any}): boolean
    local record = self.Active[player]
    if not record or record.Cancelled or record.HitConsumed then
        return false
    end

    if type(payload.attackId) ~= "string" or payload.attackId ~= record.AttackId then
        return false
    end

    local state = StateManager:Get(player)
    if not state or state.AbilityToken ~= record.Token then
        return false
    end

    local t = os.clock()
    if t < record.HitAt - 0.12
        or t > record.HitUntil
        or state.StunnedUntil > t
        or state.RagdollUntil > t then
        return false
    end

    record.HitConsumed = true
    local success = CharacterService:SkillSlot(player, record.Slot)
    return success
end

function AbilityService:Finish(player: Player, attackId: string)
    local record = self.Active[player]
    if not record or record.AttackId ~= attackId then
        return
    end

    HitRegistry:End(player, attackId)
    self.Active[player] = nil

    local state = StateManager:Get(player)
    if state and state.Vars.ActiveAttackId == attackId then
        state.Vars.ActiveAttackId = nil
        state.Vars.ActiveMove = nil
        if state.AbilityToken == record.Token and state.Phase == "UsingAbility" then
            StateManager:SetPhase(player, "Idle")
        end
    end
end

return AbilityService
