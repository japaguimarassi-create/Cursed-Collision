local ProfileStore = {}

function ProfileStore.new(services)
    local Config = services.Config
    local Catalog = services.Catalog
    local Rules = services.Rules
    local Store = services.DataStore
    local profiles = services.Profiles
    local sessionTokens = services.SessionTokens
    local saveInProgress = services.SaveInProgress
    local leaving = services.Leaving
    local notify = services.Notify
    local SESSION_LEASE_SECONDS = services.SessionLeaseSeconds or 180
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")

    local function defaultProfile()
        return {
            Coins = 0,
            Speed = 0,
            TreadmillLevel = 1,
            Rebirths = 0,
            BarnBank = 0,
            BarnAnimals = {},
            LastIncomeAt = os.time(),
            TotalCaptured = 0,
            TotalDeposited = 0,
            LastDailyClaimDay = 0,
            DailyStreak = 0,
            RedeemedCodes = {},
            QuestClaims = {},
        }
    end
    
    local function sanitizeProfile(raw)
        local data = defaultProfile()
        if type(raw) ~= "table" then
            return data
        end
        local function safeInteger(value, minimum, maximum, fallback)
            local numberValue = tonumber(value)
            if type(numberValue) ~= "number" or numberValue ~= numberValue or numberValue == math.huge or numberValue == -math.huge then
                return fallback
            end
            return math.clamp(math.floor(numberValue), minimum, maximum)
        end
        data.Coins = safeInteger(raw.Coins, 0, Config.CoinsLimit, 0)
        data.Speed = safeInteger(raw.Speed, 0, Config.MaxSpeedPoints, 0)
        data.TreadmillLevel = safeInteger(raw.TreadmillLevel, 1, Config.MaxTreadmillLevel, 1)
        data.Rebirths = safeInteger(raw.Rebirths, 0, Config.MaxRebirths, 0)
        data.BarnBank = safeInteger(raw.BarnBank, 0, Config.CoinsLimit, 0)
        data.LastIncomeAt = safeInteger(raw.LastIncomeAt, 0, 2147483647, os.time())
        data.TotalCaptured = safeInteger(raw.TotalCaptured, 0, 2147483647, 0)
        data.TotalDeposited = safeInteger(raw.TotalDeposited, 0, 2147483647, 0)
        data.LastDailyClaimDay = safeInteger(raw.LastDailyClaimDay, 0, 2147483647, 0)
        data.DailyStreak = safeInteger(raw.DailyStreak, 0, 7, 0)
        for field, source in pairs({ RedeemedCodes = raw.RedeemedCodes, QuestClaims = raw.QuestClaims }) do
            if type(source) == "table" then
                local count = 0
                for key, timestamp in pairs(source) do
                    if type(key) == "string" and #key > 0 and #key <= 64
                        and type(timestamp) == "number" and timestamp == timestamp
                        and timestamp >= 0 and timestamp < math.huge then
                        data[field][key] = math.floor(timestamp)
                        count += 1
                        if count >= 100 then break end
                    end
                end
            end
        end
        if type(raw.BarnAnimals) == "table" then
            for index, entry in ipairs(raw.BarnAnimals) do
                if index > Config.BaseSlots then
                    break
                end
                if type(entry) == "table" and Catalog.Get(entry.Id) then
                    local bornAt = math.max(0, math.floor(tonumber(entry.BornAt) or os.time()))
                    local stage = Rules.StageForAge(math.max(0, os.time() - bornAt), Config)
                    table.insert(data.BarnAnimals, {
                        Uid = tostring(entry.Uid or (entry.Id .. "_" .. tostring(index))),
                        Id = entry.Id,
                        BornAt = bornAt,
                        Stage = stage.Name,
                    })
                end
            end
        end
        return data
    end
    
    local function snapshot(profile)
        local data = {
            Coins = profile.Coins,
            Speed = profile.Speed,
            TreadmillLevel = profile.TreadmillLevel,
            Rebirths = profile.Rebirths,
            BarnBank = profile.BarnBank,
            LastIncomeAt = profile.LastIncomeAt,
            TotalCaptured = profile.TotalCaptured or 0,
            TotalDeposited = profile.TotalDeposited or 0,
            LastDailyClaimDay = profile.LastDailyClaimDay or 0,
            DailyStreak = profile.DailyStreak or 0,
            RedeemedCodes = table.clone(profile.RedeemedCodes or {}),
            QuestClaims = table.clone(profile.QuestClaims or {}),
            BarnAnimals = {},
        }
        for _, animal in ipairs(profile.BarnAnimals) do
            table.insert(data.BarnAnimals, { Uid = animal.Uid, Id = animal.Id, BornAt = animal.BornAt })
        end
        return data
    end
    
    local function acquireSession(player)
        local key = "u_" .. tostring(player.UserId)
        local token = HttpService:GenerateGUID(false)
        for attempt = 1, 5 do
            local ok, record = pcall(function()
                return Store:UpdateAsync(key, function(current)
                    local now = os.time()
                    if type(current) ~= "table" then
                        current = snapshot(defaultProfile())
                    end
                    local lease = current._Session
                    if type(lease) == "table"
                        and lease.Token ~= token
                        and (tonumber(lease.ExpiresAt) or 0) > now then
                        return nil
                    end
                    local nextRecord = {}
                    for field, value in pairs(current) do
                        nextRecord[field] = value
                    end
                    nextRecord._Session = {
                        Token = token,
                        ExpiresAt = now + SESSION_LEASE_SECONDS,
                        JobId = game.JobId,
                    }
                    return nextRecord
                end)
            end)
            if ok and type(record) == "table"
                and type(record._Session) == "table"
                and record._Session.Token == token then
                sessionTokens[player] = token
                return record
            end
            if not ok then
                warn("[StealAnAnimal] Profile lock failed: " .. tostring(record))
                return nil, "unavailable"
            end
            if attempt < 5 then
                task.wait(attempt * 2)
            end
        end
        return nil, "locked"
    end
    
    local function saveProfile(player)
        while saveInProgress[player] do
            task.wait(0.05)
        end
        local profile = profiles[player]
        local token = sessionTokens[player]
        if not profile or not token or profile.Persistent == false then
            return false
        end
        saveInProgress[player] = true
        local data = snapshot(profile)
        local ok, result = pcall(function()
            return Store:UpdateAsync("u_" .. tostring(player.UserId), function(current)
                local lease = type(current) == "table" and current._Session
                if type(lease) ~= "table" or lease.Token ~= token then
                    return nil
                end
                local nextRecord = {}
                for field, value in pairs(data) do
                    nextRecord[field] = value
                end
                nextRecord._Session = {
                    Token = token,
                    ExpiresAt = os.time() + SESSION_LEASE_SECONDS,
                    JobId = game.JobId,
                }
                return nextRecord
            end)
        end)
        saveInProgress[player] = nil
        if not ok then
            warn("[StealAnAnimal] Profile save failed: " .. tostring(result))
            return false
        end
        if type(result) ~= "table" or type(result._Session) ~= "table" or result._Session.Token ~= token then
            profile.Persistent = false
            sessionTokens[player] = nil
            warn("[StealAnAnimal] Profile session lock was lost for " .. tostring(player.UserId))
            if player.Parent == Players and not leaving[player] then
                notify(player, "Seu bloqueio de salvamento foi perdido. A sessão será encerrada para proteger seus dados.", "Error")
                player:Kick("O bloqueio de salvamento foi perdido. Entre novamente para proteger seu progresso.")
            end
            return false
        end
        return true
    end
    
    local function releaseSession(player)
        local token = sessionTokens[player]
        if not token then
            return
        end
        while saveInProgress[player] do
            task.wait(0.05)
        end
        saveInProgress[player] = true
        pcall(function()
            Store:UpdateAsync("u_" .. tostring(player.UserId), function(current)
                local lease = type(current) == "table" and current._Session
                if type(lease) ~= "table" or lease.Token ~= token then
                    return nil
                end
                local nextRecord = {}
                for field, value in pairs(current) do
                    if field ~= "_Session" then
                        nextRecord[field] = value
                    end
                end
                return nextRecord
            end)
        end)
        saveInProgress[player] = nil
        sessionTokens[player] = nil
    end

    return {
        DefaultProfile = defaultProfile,
        SanitizeProfile = sanitizeProfile,
        Snapshot = snapshot,
        AcquireSession = acquireSession,
        SaveProfile = saveProfile,
        ReleaseSession = releaseSession,
    }
end

return ProfileStore
