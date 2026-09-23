--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager: any = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)
local Movesets = require(ReplicatedStorage.Characters.CustomMovesets)
local Config = require(ReplicatedStorage.Shared.Config)

type AbilityRecord = {
    token: number,
    attackId: string,
    slot: number,
    startedAt: number,
    hitAt: number,
    hitEnd: number,
    total: number,
    cancelled: boolean,
    hitConfirmed: boolean
}

local AbilityService: any = {}
AbilityService.__index = AbilityService

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
        Config.Combat.Skill.MinCooldown,
        Config.Combat.Skill.MaxCooldown
    )
    CooldownService:Set(player, key, cooldown, now)

    local record: AbilityRecord = {
        token = token,
        attackId = attackId,
        slot = slot,
        startedAt = now,
        hitAt = now + timeline.Startup,
        hitEnd = now + timeline.Startup + timeline.Active + Config.Combat.Marker.LateTolerance,
        total = timeline.Total,
        cancelled = false,
        hitConfirmed = false
    }

    self.Active[player] = record
    state.Vars.ActiveAttackId = attackId

    local root = rootOf(player)
    if root then
        self.Context.fx("CombatAction", root.Position, {
            actor = player.Character,
            action = "SkillStart",
            slot = slot,
            move = move.Name,
            attackId = attackId,
            fallbackHitDelay = timeline.Startup,
            direction = root.CFrame.LookVector
        })

        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = key,
            move = move.Name,
            phase = "Startup",
            markers = markers,
            attackId = attackId
        })
    end

    task.delay(timeline.Startup, function()
        local current = self.Active[player]
        if current ~= record then
            return
        end

        if record.cancelled
            or not StateManager:IsAbilityValid(player, token) then
            self:Cancel(player)
            return
        end

        local currentRoot = rootOf(player)
        if currentRoot then
            self.Context.fx("AbilityTimeline", currentRoot.Position, {
                actor = player.Character,
                action = key,
                move = move.Name,
                phase = "HitWindow",
                attackId = attackId
            })
        end
    end)

    task.delay(timeline.Total, function()
        local current = self.Active[player]
        if current ~= record or record.cancelled then
            return
        end

        HitRegistry:End(player, attackId)

        local latestState = StateManager:Get(player)
        if latestState and latestState.Vars.ActiveAttackId == attackId then
            latestState.Vars.ActiveAttackId = nil

            if latestState.StunnedUntil <= os.clock()
                and latestState.RagdollUntil <= os.clock()
                and latestState.Phase == "UsingAbility" then
                StateManager:SetPhase(player, "Idle")
            end
        end

        self.Active[player] = nil
    end)

    return true
end

function AbilityService:ConfirmHit(player: Player, attackId: string): boolean
    local record = self.Active[player]
    if not record or record.attackId ~= attackId or record.cancelled or record.hitConfirmed then
        return false
    end

    if not StateManager:IsAbilityValid(player, record.token) then
        self:Cancel(player)
        return false
    end

    local now = os.clock()
    local early = Config.Combat.Marker.EarlyTolerance
    local late = Config.Combat.Marker.LateTolerance

    if now < record.hitAt - early or now > record.hitEnd + late then
        return false
    end

    record.hitConfirmed = true

    local success = CharacterService:SkillSlot(player, record.slot)

    local root = rootOf(player)
    if root then
        self.Context.fx("AbilityTimeline", root.Position, {
            actor = player.Character,
            action = "Skill" .. tostring(record.slot),
            phase = "HitConfirmed",
            attackId = attackId,
            success = success
        })
    end

    return success
end

return AbilityService