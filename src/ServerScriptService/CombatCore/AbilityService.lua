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

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = {}
    }, AbilityService)
end

local function rootOf(player: Player): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function isAwakened(player: Player): boolean
    return player:GetAttribute("AwakeningActive") == true
        or player:GetAttribute("UltimateActive") == true
end

function AbilityService:Cancel(player: Player)
    local current = self.Active[player]
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

function AbilityService:Execute(player: Player, slot: number): boolean
    local state = StateManager:Get(player)
    if not state or slot < 1 or slot > 4 then
        return false
    end

    local now = os.clock()

    if not StateManager:CanAct(player, now) then
        return false
    end

    local id = player:GetAttribute("CharacterId") or "Yuji"
    local move = Movesets.GetMove(id, slot, isAwakened(player))
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
    local attackId = tostring(player.UserId)
        .. ":"
        .. key
        .. ":"
        .. tostring(token)

    HitRegistry:Begin(player, attackId)

    local cooldown = math.clamp(
        tonumber(move.Cooldown) or 1,
        0.25,
        10
    )

    CooldownService:Set(player, key, cooldown, now)

    local record = {
        token = token,
        attackId = attackId,
        slot = slot,
        move = move,
        confirmed = false,
        cancelled = false
    }

    self.Active[player] = record
    state.Vars.ActiveAttackId = attackId
    state.Vars.ActiveMove = move

    local root = rootOf(player)
    if root then
        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = "SkillStart",
            slot = slot,
            move = move.Name,
            attackId = attackId,
            token = token,
            fallbackHitDelay = timeline.Startup,
            markers = markers,
            awakened = isAwakened(player)
        })
    end

    task.delay(timeline.Startup + 0.12, function()
        self:ConfirmMarker(player, attackId, token, "ServerFallback")
    end)

    task.delay(timeline.Total + 0.05, function()
        if self.Active[player] ~= record then
            return
        end

        HitRegistry:End(player, attackId)
        self.Active[player] = nil

        local latest = StateManager:Get(player)
        if latest and latest.Vars.ActiveAttackId == attackId then
            latest.Vars.ActiveAttackId = nil

            if latest.AbilityToken == token
                and latest.Phase == "UsingAbility" then
                StateManager:SetPhase(player, "Idle")
            end
        end
    end)

    return true
end

function AbilityService:ConfirmMarker(
    player: Player,
    attackId: string,
    token: number,
    source: string
): boolean
    local record = self.Active[player]
    local state = StateManager:Get(player)

    if not record
        or record.attackId ~= attackId
        or record.token ~= token
        or record.confirmed
        or record.cancelled
        or not state
        or state.AbilityToken ~= token
        or state.Vars.ActiveAttackId ~= attackId
        or not StateManager:IsAbilityValid(player, token) then
        return false
    end

    record.confirmed = true

    local success = CharacterService:SkillSlot(player, record.slot)
    local root = rootOf(player)

    if root then
        self.Context.fx("CombatMarker", root.Position, {
            actor = player.Character,
            action = "SkillHit",
            slot = record.slot,
            move = record.move.Name,
            attackId = attackId,
            source = source,
            hit = success
        })
    end

    return success
end

return AbilityService
