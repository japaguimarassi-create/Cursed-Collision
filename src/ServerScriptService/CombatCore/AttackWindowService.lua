--!strict

export type AttackRecord = {
    Kind: string,
    StartedAt: number,
    OpenAt: number,
    CloseAt: number,
    Consumed: boolean
}

local AttackWindowService = {}

local records: {[Player]: {[string]: AttackRecord}} = {}

local function bucket(player: Player): {[string]: AttackRecord}
    local result = records[player]
    if not result then
        result = {}
        records[player] = result
    end
    return result
end

function AttackWindowService:Begin(
    player: Player,
    attackId: string,
    kind: string,
    startedAt: number,
    openDelay: number,
    closeDelay: number
)
    bucket(player)[attackId] = {
        Kind = kind,
        StartedAt = startedAt,
        OpenAt = startedAt + math.max(0, openDelay),
        CloseAt = startedAt + math.max(openDelay, closeDelay),
        Consumed = false
    }
end

function AttackWindowService:Validate(
    player: Player,
    attackId: string,
    kind: string,
    now: number
): boolean
    local playerRecords = records[player]
    local record = playerRecords and playerRecords[attackId]

    if not record or record.Kind ~= kind or record.Consumed then
        return false
    end

    if now < record.OpenAt or now > record.CloseAt then
        return false
    end

    return true
end

function AttackWindowService:Consume(
    player: Player,
    attackId: string,
    kind: string,
    now: number
): boolean
    if not self:Validate(player, attackId, kind, now) then
        return false
    end

    local record = records[player][attackId]
    record.Consumed = true
    return true
end

function AttackWindowService:Get(player: Player, attackId: string): AttackRecord?
    local playerRecords = records[player]
    return playerRecords and playerRecords[attackId]
end

function AttackWindowService:End(player: Player, attackId: string)
    local playerRecords = records[player]
    if not playerRecords then
        return
    end

    playerRecords[attackId] = nil

    if next(playerRecords) == nil then
        records[player] = nil
    end
end

function AttackWindowService:Clear(player: Player)
    records[player] = nil
end

return AttackWindowService
