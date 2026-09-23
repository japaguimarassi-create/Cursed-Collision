--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local StateManager = require(script.Parent.StateManager)

local CombatMarkerService = {}
CombatMarkerService.__index = CombatMarkerService

export type AttackRecord = {
    AttackId: string,
    Token: number,
    Kind: "Action" | "Ability",
    EarlyAt: number,
    HitAt: number,
    ExpiresAt: number,
    Resolved: boolean,
    Callback: () -> ()
}

type PlayerRecords = {[string]: AttackRecord}

local records: {[Player]: PlayerRecords} = {}

local DEFAULT_EARLY = Config.Combat.MarkerTiming.EarlyGrace
local DEFAULT_LATE = math.clamp(Config.Combat.MarkerTiming.NetworkGrace, 0.18, 0.35)

local function bucket(player: Player): PlayerRecords
    local result = records[player]
    if not result then
        result = {}
        records[player] = result
    end
    return result
end

function CombatMarkerService:Begin(
    player: Player,
    attackId: string,
    token: number,
    hitDelay: number,
    callback: () -> (),
    kind: "Action" | "Ability",
    earlyWindow: number?,
    lateWindow: number?
): boolean
    if attackId == "" or type(callback) ~= "function" then
        return false
    end

    local playerRecords = bucket(player)

    if playerRecords[attackId] then
        return false
    end

    local now = os.clock()
    local early = math.clamp(
        tonumber(earlyWindow) or DEFAULT_EARLY,
        0,
        0.15
    )
    local late = math.clamp(
        tonumber(lateWindow) or DEFAULT_LATE,
        0.08,
        0.35
    )
    local hitAt = now + math.max(0, hitDelay)

    local record: AttackRecord = {
        AttackId = attackId,
        Token = token,
        Kind = kind,
        EarlyAt = hitAt - early,
        HitAt = hitAt,
        ExpiresAt = hitAt + late,
        Resolved = false,
        Callback = callback
    }

    playerRecords[attackId] = record

    task.delay(math.max(0, hitDelay) + late + 0.01, function()
        local currentBucket = records[player]
        local current = currentBucket and currentBucket[attackId]

        if current ~= record or record.Resolved then
            return
        end

        -- O fallback evita que uma animação que não carregou impeça o golpe.
        local currentTime = os.clock()
        if currentTime >= record.HitAt - early then
            record.Resolved = true
            playerRecords[attackId] = nil
            if next(playerRecords) == nil then
                records[player] = nil
            end
            callback()
        end
    end)

    return true
end

function CombatMarkerService:Resolve(player: Player, attackId: string): boolean
    local playerRecords = records[player]
    local record = playerRecords and playerRecords[attackId]

    if not record or record.Resolved then
        return false
    end

    local state = StateManager:Get(player)

    if not state
        or (record.Kind == "Ability" and state.AbilityToken ~= record.Token)
        or (record.Kind == "Action" and state.ActionToken ~= record.Token) then
        playerRecords[attackId] = nil
        if next(playerRecords) == nil then
            records[player] = nil
        end
        return false
    end

    local now = os.clock()

    if not StateManager:CanAct(player, now) then
        return false
    end

    if now < record.EarlyAt then
        return false
    end

    if now > record.ExpiresAt then
        playerRecords[attackId] = nil
        if next(playerRecords) == nil then
            records[player] = nil
        end
        return false
    end

    record.Resolved = true
    playerRecords[attackId] = nil
    if next(playerRecords) == nil then
        records[player] = nil
    end

    record.Callback()
    return true
end

function CombatMarkerService:Cancel(player: Player, attackId: string)
    local playerRecords = records[player]
    if not playerRecords then
        return
    end

    playerRecords[attackId] = nil
    if next(playerRecords) == nil then
        records[player] = nil
    end
end

function CombatMarkerService:Clear(player: Player)
    records[player] = nil
end

return CombatMarkerService
