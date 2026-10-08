--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataSchema = require(ReplicatedStorage.Shared.DataSchema)
local PersistenceRules = require(ReplicatedStorage.Shared.PersistenceRules)

local STORE_NAME = "CollisionBattlestar_PlayerProfiles_v2"
local LOCK_DURATION = 120
local RENEW_INTERVAL = 45
local AUTOSAVE_INTERVAL = 90
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
        studio = RunService:IsStudio(),
        autosaveTask = nil,
    }, PersistenceService)
end

function PersistenceService:Start()
    Players.PlayerRemoving:Connect(function(player)
        self:SaveAndRelease(player)
    end)

    self.autosaveTask = task.spawn(function()
        while not self.closing do
            task.wait(AUTOSAVE_INTERVAL)

            if self.closing then
                break
            end

            if not self.studio then
                for _, player in ipairs(Players:GetPlayers()) do
                    self:Save(player)
                    task.wait(0.25)
                end
            end
        end
    end)

    game:BindToClose(function()
        self.closing = true

        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                self:SaveAndRelease(player)
            end)
        end

        local deadline = os.clock() + 25
        while next(self.profiles) ~= nil and os.clock() < deadline do
            task.wait(0.25)
        end
    end)
end

function PersistenceService:Load(player: Player)
    if self.profiles[player] then
        return self.profiles[player]
    end

    if self.studio then
        local profile = DataSchema.Default()
        self.profiles[player] = profile
        self.sessions[player] = {
            sessionId = HttpService:GenerateGUID(false),
            renewTask = nil,
        }
        return profile
    end

    local sessionId = HttpService:GenerateGUID(false)
    local blocked = false
    local loadedProfile = nil
    local key = getKey(player)

    local success, result = retry(function()
        local value = nil

        local ok, updateResult = pcall(function()
            return self.store:UpdateAsync(key, function(current)
                if type(current) == "table"
                    and type(current.SchemaVersion) == "number"
                    and current.SchemaVersion > DataSchema.CurrentVersion then
                    error("UNSUPPORTED_PROFILE_VERSION")
                end

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

                currentData.__Session = PersistenceRules.makeLock(
                    sessionId,
                    os.time(),
                    LOCK_DURATION
                )

                value = currentData
                return currentData
            end)
        end)

        if not ok then
            error(updateResult)
        end

        if value == nil then
            error(blocked and "PLAYER_SESSION_LOCKED" or "PLAYER_PROFILE_NOT_RETURNED")
        end

        return updateResult
    end)

    if not success then
        return nil, tostring(result)
    end

    loadedProfile = DataSchema.Sanitize(result)

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

            local session = self.sessions[player]
            if not session or not self.profiles[player] or not player.Parent then
                break
            end

            local ok = retry(function()
                local updated = self.store:UpdateAsync(key, function(current)
                    local lock = type(current) == "table" and current.__Session

                    if type(lock) == "table" and not PersistenceRules.isOwned(
                        lock.SessionId,
                        session.sessionId
                    ) then
                        return nil
                    end

                    local data = DataSchema.Migrate(current)
                    data.__Session = PersistenceRules.makeLock(
                        session.sessionId,
                        os.time(),
                        LOCK_DURATION
                    )
                    return data
                end)

                if updated == nil then
                    error("SESSION_RENEW_REJECTED")
                end
            end)

            if not ok then
                warn(("Session lock renewal failed for %s"):format(player.Name))
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

    if self.studio then
        return true
    end

    local key = getKey(player)
    local payload = DataSchema.Sanitize(profile)
    local conflict = false

    local success, result = retry(function()
        local updated = self.store:UpdateAsync(key, function(current)
            if type(current) == "table"
                and type(current.SchemaVersion) == "number"
                and current.SchemaVersion > DataSchema.CurrentVersion then
                conflict = true
                return nil
            end

            local currentLock = type(current) == "table" and current.__Session
            if type(currentLock) == "table" and not PersistenceRules.isOwned(
                currentLock.SessionId,
                session.sessionId
            ) then
                conflict = true
                return nil
            end

            payload.__Session = PersistenceRules.makeLock(
                session.sessionId,
                os.time(),
                LOCK_DURATION
            )

            return payload
        end)

        if updated == nil then
            error(conflict and "PLAYER_SESSION_CONFLICT" or "PLAYER_SAVE_REJECTED")
        end

        return true
    end)

    if not success then
        return false, tostring(result)
    end

    return true
end

function PersistenceService:Release(player: Player)
    local session = self.sessions[player]

    if not session then
        return false, "session_unavailable"
    end

    if self.studio then
        self.sessions[player] = nil
        self.profiles[player] = nil
        return true
    end

    local key = getKey(player)
    local released = false

    local success, result = retry(function()
        local updated = self.store:UpdateAsync(key, function(current)
            if type(current) == "table"
                and type(current.SchemaVersion) == "number"
                and current.SchemaVersion > DataSchema.CurrentVersion then
                return nil
            end

            local currentData = DataSchema.Migrate(current)
            local lock = type(current) == "table" and current.__Session

            if type(lock) == "table" and not PersistenceRules.isOwned(
                lock.SessionId,
                session.sessionId
            ) then
                return nil
            end

            currentData.__Session = nil
            released = true
            return currentData
        end)

        if updated == nil and not released then
            error("PLAYER_RELEASE_REJECTED")
        end

        return true
    end)

    if not success then
        return false, tostring(result)
    end

    if session.renewTask then
        task.cancel(session.renewTask)
    end

    self.sessions[player] = nil
    self.profiles[player] = nil

    return true
end

function PersistenceService:SaveAndRelease(player: Player)
    if not self.profiles[player] then
        return
    end

    local saved, saveError = self:Save(player)
    if not saved then
        warn(("Profile save failed for %s; retaining lock until expiry: %s"):format(
            player.Name,
            tostring(saveError)
        ))
        return
    end

    self:Release(player)
end

return PersistenceService
