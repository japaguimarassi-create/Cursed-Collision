--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataSchema = require(game:GetService("ReplicatedStorage").Shared.DataSchema)
local PersistenceRules = require(game:GetService("ReplicatedStorage").Shared.PersistenceRules)

local STORE_NAME = "CollisionBattlestar_PlayerProfiles_v2"
local LOCK_DURATION = 120
local RENEW_INTERVAL = 45
local MAX_RETRIES = 5

local PersistenceService = {}
PersistenceService.__index = PersistenceService

local function getKey(player: Player)
    return "Player_" .. tostring(player.UserId)
end

local function retry(operation)
    local lastError = nil

    for attempt = 1, MAX_RETRIES do
        local ok, result = pcall(operation)

        if ok then
            return true, result
        end

        lastError = result
        task.wait(math.min(2 ^ (attempt - 1), 8))
    end

    return false, lastError
end

function PersistenceService.new()
    return setmetatable({
        store = DataStoreService:GetDataStore(STORE_NAME),
        profiles = {} :: {[Player]: any},
        sessions = {} :: {[Player]: {sessionId: string, renewTask: thread?}},
        closing = false,
    }, PersistenceService)
end

function PersistenceService:Start()
    Players.PlayerRemoving:Connect(function(player)
        self:SaveAndRelease(player)
    end)

    game:BindToClose(function()
        self.closing = true

        local remaining = 25
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                self:SaveAndRelease(player)
            end)
        end

        while next(self.profiles) ~= nil and remaining > 0 do
            task.wait(1)
            remaining -= 1
        end
    end)
end

function PersistenceService:Load(player: Player)
    if self.profiles[player] then
        return self.profiles[player]
    end

    local sessionId = HttpService:GenerateGUID(false)
    local blocked = false
    local loadedProfile = nil
    local key = getKey(player)

    local success, result = retry(function()
        local value
        local updateSuccess, updateResult = pcall(function()
            return self.store:UpdateAsync(key, function(current)
                local currentData = DataSchema.Migrate(current)
                local lock = type(current) == "table" and current.__Session

                if type(lock) == "table" and not PersistenceRules.canAcquire(
                    lock.SessionId,
                    lock.ExpiresAt,
                    sessionId,
                    os.time()
                ) then
                    blocked = true
                    return nil
                end

                currentData.__Session = PersistenceRules.makeLock(sessionId, os.time(), LOCK_DURATION)
                value = currentData
                return currentData
            end)
        end)

        if not updateSuccess then
            error(updateResult)
        end

        if value == nil then
            if blocked then
                error("PLAYER_SESSION_LOCKED")
            end
            error("PLAYER_PROFILE_NOT_RETURNED")
        end

        return updateResult
    end)

    if not success then
        if RunService:IsStudio() then
            warn(("Persistence fallback for %s: %s"):format(player.Name, tostring(result)))
            loadedProfile = DataSchema.Default()
        else
            return nil, tostring(result)
        end
    else
        loadedProfile = DataSchema.Sanitize(result)
    end

    if not player.Parent then
        return nil, "PLAYER_LEFT_DURING_LOAD"
    end

    self.profiles[player] = loadedProfile
    self.sessions[player] = {
        sessionId = sessionId,
        renewTask = nil,
    }

    self.sessions[player].renewTask = task.spawn(function()
        while self.profiles[player] and player.Parent and not self.closing do
            task.wait(RENEW_INTERVAL)

            if not self.profiles[player] or not self.sessions[player] then
                break
            end

            local currentSession = self.sessions[player]
            local renewOk, renewError = retry(function()
                local result = self.store:UpdateAsync(key, function(current)
                    local data = DataSchema.Migrate(current)
                    local lock = type(current) == "table" and current.__Session

                    if type(lock) == "table" and not PersistenceRules.isOwned(lock.SessionId, currentSession.sessionId) then
                        return nil
                    end

                    data.__Session = PersistenceRules.makeLock(currentSession.sessionId, os.time(), LOCK_DURATION)
                    return data
                end)

                if result == nil then
                    error("SESSION_RENEW_REJECTED")
                end

                return result
            end)

            if not renewOk then
                warn(("Session lock renewal failed for %s: %s"):format(player.Name, tostring(renewError)))
            end
        end
    end)

    return loadedProfile
end

function PersistenceService:Get(player: Player)
    return self.profiles[player]
end

function PersistenceService:Save(player: Player)
    local profile = self.profiles[player]
    local session = self.sessions[player]

    if not profile or not session then
        return false, "profile_unavailable"
    end

    local key = getKey(player)
    local payload = DataSchema.Sanitize(profile)
    local saved = false
    local conflict = false

    local success, result = retry(function()
        local updated = self.store:UpdateAsync(key, function(current)
            local currentLock = type(current) == "table" and current.__Session

            if type(currentLock) == "table" and not PersistenceRules.isOwned(
                currentLock.SessionId,
                session.sessionId
            ) then
                conflict = true
                return nil
            end

            payload.__Session = PersistenceRules.makeLock(session.sessionId, os.time(), LOCK_DURATION)
            return payload
        end)

        if updated == nil then
            if conflict then
                error("PLAYER_SESSION_CONFLICT")
            end
            error("PLAYER_SAVE_REJECTED")
        end

        saved = true
        return updated
    end)

    if not success then
        return false, tostring(result)
    end

    return saved
end

function PersistenceService:Release(player: Player)
    local session = self.sessions[player]
    if not session then
        return false, "session_unavailable"
    end

    local key = getKey(player)
    local released = false

    local success, result = retry(function()
        local updated = self.store:UpdateAsync(key, function(current)
            local currentData = DataSchema.Migrate(current)
            local lock = type(current) == "table" and current.__Session

            if type(lock) == "table" and not PersistenceRules.isOwned(lock.SessionId, session.sessionId) then
                return nil
            end

            currentData.__Session = nil
            released = true
            return currentData
        end)

        if updated == nil and not released then
            error("PLAYER_RELEASE_REJECTED")
        end

        return updated
    end)

    if not success then
        return false, tostring(result)
    end

    return released
end

function PersistenceService:SaveAndRelease(player: Player)
    if not self.profiles[player] then
        return
    end

    self:Save(player)
    self:Release(player)

    local session = self.sessions[player]
    if session and session.renewTask then
        task.cancel(session.renewTask)
    end

    self.sessions[player] = nil
    self.profiles[player] = nil
end

return PersistenceService
