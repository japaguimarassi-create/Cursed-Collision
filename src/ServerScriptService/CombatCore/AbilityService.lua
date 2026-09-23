--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Timeline = require(ReplicatedStorage.Combat.AbilityTimeline)
local HitRegistry = require(ReplicatedStorage.Combat.HitRegistry)
local StateManager = require(script.Parent.StateManager)
local CooldownService = require(script.Parent.CooldownService)
local CharacterService = require(ReplicatedStorage.Characters.CharacterService)

local AbilityService = {}
AbilityService.__index = AbilityService

function AbilityService.new(context: any)
    return setmetatable({
        Context = context,
        Active = setmetatable({}, {__mode = "k"})
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

    current.cancelled = true
    HitRegistry:End(player, current.attackId)
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

    local record = {
        token = token,
        attackId = attackId,
        cancelled = false
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
    end

    task.delay(timeline.Startup, function()
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
                phase = "HitFrame",
                attackId = attackId
            })
        end

        if self.Active[player] == record then
            CharacterService:SkillSlot(player, slot)
        end
    end)

    task.delay(timeline.Total, function()
        if record.cancelled then
            return
        end

        if StateManager:Get(player)
            and StateManager:IsAbilityValid(player, token) then
            StateManager:SetPhase(player, "Idle")
        end

        HitRegistry:End(player, attackId)

        local latestState = StateManager:Get(player)
        if latestState and latestState.Vars.ActiveAttackId == attackId then
            latestState.Vars.ActiveAttackId = nil
        end

        if self.Active[player] == record then
            self.Active[player] = nil
        end
    end)

    return true
end

return AbilityService
