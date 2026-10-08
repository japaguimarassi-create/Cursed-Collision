--!strict

local PersistenceRules = {}

function PersistenceRules.canAcquire(lockSessionId: any, lockExpiresAt: any, ownSessionId: string, now: number)
    if lockSessionId == nil or lockSessionId == "" then
        return true
    end

    if lockSessionId == ownSessionId then
        return true
    end

    if type(lockExpiresAt) ~= "number" then
        return true
    end

    return lockExpiresAt <= now
end

function PersistenceRules.makeLock(sessionId: string, now: number, duration: number)
    return {
        SessionId = sessionId,
        ExpiresAt = now + math.max(10, duration),
    }
end

function PersistenceRules.isOwned(lockSessionId: any, ownSessionId: string)
    return lockSessionId == ownSessionId
end

return table.freeze(PersistenceRules)
