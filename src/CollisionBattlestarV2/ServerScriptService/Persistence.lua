--!strict

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Data = require(game:GetService("ReplicatedStorage").Shared.Data)

local STORE_NAME = "CBS2_PlayerProfiles_v1"
local LOCK_SECONDS = 120
local SAVE_INTERVAL = 60

local Persistence = {}
Persistence.__index = Persistence

function Persistence.new()
    local store = nil
    if not RunService:IsStudio() then
        local ok, result = pcall(function()
            return DataStoreService:GetDataStore(STORE_NAME)
        end)
        if ok then
            store = result
        end
    end

    return setmetatable({
        store = store,
        sessions = {},
        running = false,
        connection = nil,
    }, Persistence)
end

function Persistence:Load(player: Player)
    if not self.store then
        return Data.default()
    end

    local key = "u:" .. tostring(player.UserId)
    local sessionId = HttpService:GenerateGUID(false)
    local now = os.time()
    local loaded = nil
    local locked = false

    local ok, result = pcall(function()
        return self.store:UpdateAsync(key, function(old)
            local current = Data.sanitize(old)
            local metadata = type(old) == "table" and old._Session or nil

            if type(metadata) == "table"
                and type(metadata.Id) == "string"
                and type(metadata.ExpiresAt) == "number"
                and metadata.ExpiresAt > now
                and metadata.Id ~= sessionId then
                locked = true
                return nil
            end

            current._Session = {
                Id = sessionId,
                ExpiresAt = now + LOCK_SECONDS,
            }
            loaded = current
            return current
        end)
    end)

    if not ok or not result or locked or not loaded then
        return nil, locked and "session_locked" or tostring(result)
    end

    self.sessions[player] = {
        key = key,
        id = sessionId,
        data = loaded,
        dirty = false,
        lastSave = os.clock(),
    }

    loaded._Session = nil
    return loaded
end

function Persistence:MarkDirty(player: Player)
    local session = self.sessions[player]
    if session then
        session.dirty = true
    end
end

function Persistence:Save(player: Player, release: boolean?)
    local session = self.sessions[player]
    if not session or not self.store then
        return true
    end

    local data = Data.sanitize(session.data)
    local expectedId = session.id
    local now = os.time()
    local wrote = false
    local lost = false

    local ok = pcall(function()
        self.store:UpdateAsync(session.key, function(old)
            local metadata = type(old) == "table" and old._Session or nil
            if type(metadata) ~= "table" or metadata.Id ~= expectedId then
                lost = true
                return nil
            end

            if release then
                data._Session = nil
            else
                data._Session = {
                    Id = expectedId,
                    ExpiresAt = now + LOCK_SECONDS,
                }
            end

            wrote = true
            return data
        end)
    end)

    if not ok or lost or not wrote then
        return false
    end

    session.dirty = false
    session.lastSave = os.clock()

    if release then
        self.sessions[player] = nil
    end

    return true
end

function Persistence:Get(player: Player)
    local session = self.sessions[player]
    return session and session.data or nil
end

function Persistence:Start()
    if self.running then
        return
    end
    self.running = true

    self.connection = game:GetService("Players").PlayerRemoving:Connect(function(player)
        self:Save(player, true)
    end)

    task.spawn(function()
        while self.running do
            for player, session in pairs(self.sessions) do
                if player.Parent and os.clock() - session.lastSave >= SAVE_INTERVAL then
                    self:Save(player, false)
                end
            end
            task.wait(5)
        end
    end)
end

function Persistence:Stop()
    self.running = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

function Persistence:Reload()
    return true
end

return Persistence
