local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayRules"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalCatalog"))
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local ProfileService = {}
local profiles = {}

local function finiteNumber(value)
    return Rules.IsFinite(value)
end

local function integer(value, minimum, maximum, fallback)
    return Rules.Integer(value, minimum, maximum, fallback)
end

local function sanitizeTimestampMap(raw, maximumEntries)
    if type(raw) ~= "table" then
        return {}
    end
    local result = {}
    local entries = {}
    for key, timestamp in pairs(raw) do
        if type(key) == "string" and #key > 0 and #key <= 120
            and finiteNumber(timestamp) and timestamp >= 0 then
            table.insert(entries, { Key = key, Timestamp = math.floor(timestamp) })
        end
    end
    table.sort(entries, function(a, b)
        return a.Timestamp > b.Timestamp
    end)
    for index = 1, math.min(#entries, maximumEntries or 200) do
        local entry = entries[index]
        result[entry.Key] = entry.Timestamp
    end
    return result
end

local function sanitizeBarnAnimals(raw)
    local animals = {}
    if type(raw) ~= "table" then
        return animals
    end
    local maxStored = Config.Barn.BaseSlots + Config.Barn.ExtraBarnSlots
    for _, animalId in ipairs(raw) do
        if #animals >= maxStored then
            break
        end
        if type(animalId) == "string" and Catalog.Get(animalId) then
            table.insert(animals, animalId)
        end
    end
    return animals
end

local function defaults()
    return {
        SchemaVersion = Config.SchemaVersion,
        Coins = 0,
        Speed = 0,
        Rebirths = 0,
        BarnAnimals = {},
        BarnBank = 0,
        LastIncomeAt = os.time(),
        TotalCaptured = 0,
        TotalDeposited = 0,
        ProcessedPurchases = {},
        ProcessedBarnDeposits = {},
        RedeemedCodes = {},
        QuestClaims = {},
        LastDailyClaimDay = 0,
        DailyStreak = 0,
        UpdatedAt = os.time(),
    }
end

local function sanitize(raw)
    raw = type(raw) == "table" and raw or defaults()
    local fallback = defaults()
    return {
        SchemaVersion = Config.SchemaVersion,
        Coins = integer(raw.Coins, 0, Config.CoinsLimit, 0),
        Speed = integer(raw.Speed, 0, Config.MaxSpeedLevel, 0),
        Rebirths = integer(raw.Rebirths, 0, Config.MaxRebirths, 0),
        BarnAnimals = sanitizeBarnAnimals(raw.BarnAnimals),
        BarnBank = integer(raw.BarnBank, 0, Config.CoinsLimit, 0),
        LastIncomeAt = integer(raw.LastIncomeAt, 0, 2147483647, integer(raw.UpdatedAt, 0, 2147483647, fallback.LastIncomeAt)),
        TotalCaptured = integer(raw.TotalCaptured, 0, 2147483647, 0),
        TotalDeposited = integer(raw.TotalDeposited, 0, 2147483647, 0),
        ProcessedPurchases = sanitizeTimestampMap(raw.ProcessedPurchases, 500),
        ProcessedBarnDeposits = sanitizeTimestampMap(raw.ProcessedBarnDeposits, Config.Barn.MaximumDepositLedger),
        RedeemedCodes = sanitizeTimestampMap(raw.RedeemedCodes, 100),
        QuestClaims = sanitizeTimestampMap(raw.QuestClaims, 100),
        LastDailyClaimDay = integer(raw.LastDailyClaimDay, 0, 2147483647, 0),
        DailyStreak = integer(raw.DailyStreak, 0, 7, 0),
        UpdatedAt = integer(raw.UpdatedAt, 0, 2147483647, os.time()),
    }
end

local function copyMap(target, key, source)
    local combined = sanitizeTimestampMap(target[key], 500)
    for entryKey, timestamp in pairs(source or {}) do
        if type(entryKey) == "string" and finiteNumber(timestamp) and timestamp >= 0 then
            combined[entryKey] = math.floor(timestamp)
        end
    end
    target[key] = combined
end

local function writeData(current, data)
    current.SchemaVersion = Config.SchemaVersion
    current.Coins = integer(data.Coins, 0, Config.CoinsLimit, 0)
    current.Speed = integer(data.Speed, 0, Config.MaxSpeedLevel, 0)
    current.Rebirths = integer(data.Rebirths, 0, Config.MaxRebirths, 0)
    current.BarnAnimals = table.clone(sanitizeBarnAnimals(data.BarnAnimals))
    current.BarnBank = integer(data.BarnBank, 0, Config.CoinsLimit, 0)
    current.LastIncomeAt = integer(data.LastIncomeAt, 0, 2147483647, os.time())
    current.TotalCaptured = integer(data.TotalCaptured, 0, 2147483647, 0)
    current.TotalDeposited = integer(data.TotalDeposited, 0, 2147483647, 0)
    current.LastDailyClaimDay = integer(data.LastDailyClaimDay, 0, 2147483647, 0)
    current.DailyStreak = integer(data.DailyStreak, 0, 7, 0)
    copyMap(current, "ProcessedPurchases", data.ProcessedPurchases)
    copyMap(current, "ProcessedBarnDeposits", data.ProcessedBarnDeposits)
    copyMap(current, "RedeemedCodes", data.RedeemedCodes)
    copyMap(current, "QuestClaims", data.QuestClaims)
    current.Strength = nil
    return current
end

local function ensureLeaderstats(player, data)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and not leaderstats:IsA("Folder") then
        leaderstats:Destroy()
        leaderstats = nil
    end
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    for _, legacyName in ipairs({ "Força", "Velocidade", "Moedas", "Renascimentos" }) do
        local legacy = leaderstats:FindFirstChild(legacyName)
        if legacy then
            legacy:Destroy()
        end
    end

    local function ensureValue(name, value)
        local item = leaderstats:FindFirstChild(name)
        if item and not item:IsA("IntValue") then
            item:Destroy()
            item = nil
        end
        if not item then
            item = Instance.new("IntValue")
            item.Name = name
            item.Parent = leaderstats
        end
        item.Value = value
        return item
    end

    return {
        Coins = ensureValue("Coins", data.Coins),
        Speed = ensureValue("Speed", data.Speed),
        Animals = ensureValue("Barn Animals", #data.BarnAnimals),
        Rebirths = ensureValue("Rebirths", data.Rebirths),
    }
end

local function mirror(player, profile)
    local data = profile.Data
    local values = profile.Values
    values.Coins.Value = data.Coins
    values.Speed.Value = data.Speed
    values.Animals.Value = #data.BarnAnimals
    values.Rebirths.Value = data.Rebirths
    player:SetAttribute("DataLoaded", true)
    player:SetAttribute("Coins", data.Coins)
    player:SetAttribute("SpeedLevel", data.Speed)
    player:SetAttribute("Rebirths", data.Rebirths)
    player:SetAttribute("BarnAnimalCount", #data.BarnAnimals)
    player:SetAttribute("BarnBank", data.BarnBank)
    player:SetAttribute("TotalCaptured", data.TotalCaptured)
    player:SetAttribute("TotalDeposited", data.TotalDeposited)
    player:SetAttribute("LastDailyClaimDay", data.LastDailyClaimDay)
    player:SetAttribute("DailyStreak", data.DailyStreak)
    player:SetAttribute("BarnAnimalsJson", HttpService:JSONEncode(data.BarnAnimals))
end

function ProfileService.Sync(player)
    local profile = profiles[player]
    if not profile or not profile.Loaded then
        return false
    end
    mirror(player, profile)
    return true
end

function ProfileService.IsLoaded(player)
    local profile = profiles[player]
    return profile ~= nil and profile.Loaded == true
end

function ProfileService.Get(player)
    local profile = profiles[player]
    if not profile or not profile.Loaded then
        return nil
    end
    return profile.Data
end

function ProfileService.Load(player)
    if profiles[player] and profiles[player].Loaded then
        return true
    end

    local profile = {
        SessionId = HttpService:GenerateGUID(false),
        Data = defaults(),
        Values = nil,
        Loaded = false,
        Saving = false,
        Leaving = false,
    }
    profiles[player] = profile
    local key = "Player_" .. tostring(player.UserId)

    for attempt = 1, Config.ProfileLoadAttempts do
        if player.Parent ~= Players then
            return false
        end
        local conflictingLock = false
        local success, record = pcall(function()
            return Store:UpdateAsync(key, function(current)
                local now = os.time()
                local existing = type(current) == "table" and current or defaults()
                local lock = existing.SessionLock
                if type(lock) == "table"
                    and lock.Token ~= profile.SessionId
                    and finiteNumber(lock.ExpiresAt)
                    and lock.ExpiresAt > now then
                    conflictingLock = true
                    return nil
                end
                local result = sanitize(existing)
                result.SessionLock = {
                    Token = profile.SessionId,
                    ExpiresAt = now + Config.SessionLockSeconds,
                }
                result.Strength = nil
                return result
            end)
        end)

        if success and type(record) == "table"
            and type(record.SessionLock) == "table"
            and record.SessionLock.Token == profile.SessionId then
            if player.Parent ~= Players or profiles[player] ~= profile then
                pcall(function()
                    Store:UpdateAsync(key, function(current)
                        if type(current) == "table"
                            and type(current.SessionLock) == "table"
                            and current.SessionLock.Token == profile.SessionId then
                            current.SessionLock = nil
                            return current
                        end
                        return nil
                    end)
                end)
                return false
            end
            profile.Data = sanitize(record)
            profile.Values = ensureLeaderstats(player, profile.Data)
            profile.Loaded = true
            mirror(player, profile)
            return true
        end

        if not success then
            warn("StealAnAnimal: profile load failed for UserId " .. player.UserId .. ": " .. tostring(record))
        elseif conflictingLock then
            warn("StealAnAnimal: active session lock for UserId " .. player.UserId)
        end
        if attempt < Config.ProfileLoadAttempts then
            task.wait(math.min(attempt * 2, 8))
        end
    end
    return false
end

function ProfileService.Save(player, releaseLock)
    local profile = profiles[player]
    if not profile or not profile.Loaded then
        return false
    end

    local deadline = os.clock() + 15
    while profile.Saving and os.clock() < deadline do
        task.wait(0.1)
    end
    if profile.Saving then
        warn("StealAnAnimal: prior save still running for UserId " .. player.UserId)
        return false
    end

    profile.Saving = true
    local key = "Player_" .. tostring(player.UserId)
    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
            return Store:UpdateAsync(key, function(current)
                if type(current) ~= "table"
                    or type(current.SessionLock) ~= "table"
                    or current.SessionLock.Token ~= profile.SessionId then
                    return nil
                end
                writeData(current, profile.Data)
                if releaseLock then
                    current.SessionLock = nil
                else
                    current.SessionLock = {
                        Token = profile.SessionId,
                        ExpiresAt = os.time() + Config.SessionLockSeconds,
                    }
                end
                return current
            end)
        end)
        if success then
            break
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    profile.Saving = false

    if not success then
        warn("StealAnAnimal: profile save failed for UserId " .. player.UserId .. ": " .. tostring(result))
        return false
    end
    if type(result) ~= "table" then
        warn("StealAnAnimal: session lost save authorization for UserId " .. player.UserId)
        return false
    end
    if releaseLock and result.SessionLock == nil then
        profile.Loaded = false
    end
    return true
end

function ProfileService.AddCoins(player, amount)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Saving
        or not finiteNumber(amount) or amount < 0 then
        return false, 0
    end
    local before = profile.Data.Coins
    profile.Data.Coins = math.clamp(before + math.floor(amount), 0, Config.CoinsLimit)
    mirror(player, profile)
    return true, profile.Data.Coins - before
end

function ProfileService.SpendCoins(player, amount)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Saving or not finiteNumber(amount) then
        return false
    end
    amount = math.floor(amount)
    if amount < 0 or profile.Data.Coins < amount then
        return false
    end
    profile.Data.Coins -= amount
    mirror(player, profile)
    return true
end

function ProfileService.AddStat(player, statName, amount)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Saving
        or statName ~= "Speed" or not finiteNumber(amount) then
        return false
    end
    amount = math.floor(amount)
    if amount <= 0 then
        return false
    end
    profile.Data.Speed = math.clamp(profile.Data.Speed + amount, 0, Config.MaxSpeedLevel)
    mirror(player, profile)
    return true
end

function ProfileService.RecordCapture(player)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Saving then
        return false
    end
    profile.Data.TotalCaptured = math.min(2147483647, profile.Data.TotalCaptured + 1)
    mirror(player, profile)
    return true
end

local function waitForWrite(profile)
    local deadline = os.clock() + 15
    while profile.Saving and os.clock() < deadline do
        task.wait(0.1)
    end
    return not profile.Saving and profile.Loaded and not profile.Leaving
end

local function transact(player, mutator)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Leaving then
        return false, "profile-not-loaded"
    end
    if not waitForWrite(profile) then
        return false, "profile-busy"
    end
    profile.Saving = true
    local key = "Player_" .. tostring(player.UserId)
    local callbackState = {}
    local success, record = pcall(function()
        return Store:UpdateAsync(key, function(current)
            callbackState = {}
            if type(current) ~= "table"
                or type(current.SessionLock) ~= "table"
                or current.SessionLock.Token ~= profile.SessionId then
                callbackState.error = "session-lock"
                return nil
            end
            local accepted, reason = mutator(current, profile.Data, callbackState)
            if not accepted then
                callbackState.error = reason or "rejected"
                return nil
            end
            current.Strength = nil
            current.SchemaVersion = Config.SchemaVersion
            current.UpdatedAt = os.time()
            current.SessionLock = {
                Token = profile.SessionId,
                ExpiresAt = os.time() + Config.SessionLockSeconds,
            }
            return current
        end)
    end)
    profile.Saving = false

    if not success then
        warn("StealAnAnimal: atomic update failed for UserId " .. player.UserId .. ": " .. tostring(record))
        return false, "datastore-error"
    end
    if type(record) ~= "table"
        or type(record.SessionLock) ~= "table"
        or record.SessionLock.Token ~= profile.SessionId then
        return false, callbackState.error or "session-lock"
    end
    profile.Data = sanitize(record)
    mirror(player, profile)
    return true, callbackState
end

function ProfileService.ClaimOfflineIncome(player, passMultiplier, capSeconds)
    if not finiteNumber(passMultiplier) or passMultiplier < 1 or passMultiplier > 10
        or not finiteNumber(capSeconds) or capSeconds < 0 or capSeconds > 86400 then
        return false, 0, "invalid-parameters"
    end
    local now = os.time()
    local success, result = transact(player, function(current, data, state)
        local lastSaved = integer(current.LastIncomeAt, 0, 2147483647, now)
        writeData(current, data)
        local elapsed = math.clamp(now - lastSaved, 0, math.floor(capSeconds))
        local animals = sanitizeBarnAnimals(current.BarnAnimals)
        local rate = 0
        for _, animalId in ipairs(animals) do
            local spec = Catalog.Get(animalId)
            if spec then
                rate += spec.IncomePerSecond
            end
        end
        local rebirths = integer(current.Rebirths, 0, Config.MaxRebirths, 0)
        local multiplier = passMultiplier * (1 + rebirths * Config.RebirthIncomeBonusPerRebirth)
        local earned = math.clamp(math.floor(rate * multiplier * elapsed), 0, Config.CoinsLimit)
        current.BarnBank = math.clamp(integer(current.BarnBank, 0, Config.CoinsLimit, 0) + earned, 0, Config.CoinsLimit)
        current.LastIncomeAt = now
        state.amount = earned
        state.seconds = elapsed
        state.rate = rate
        return true
    end)
    if not success then
        return false, 0, result
    end
    return true, result.amount or 0, result.seconds or 0, result.rate or 0
end

function ProfileService.AccrueBarnIncome(player, amount, timestamp)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Saving or profile.Leaving
        or not finiteNumber(amount) or amount < 0 or amount ~= math.floor(amount) then
        return false
    end
    profile.Data.LastIncomeAt = integer(timestamp, 0, 2147483647, os.time())
    if amount > 0 then
        profile.Data.BarnBank = math.clamp(profile.Data.BarnBank + amount, 0, Config.CoinsLimit)
        mirror(player, profile)
    end
    return true
end

function ProfileService.AddBarnAnimal(player, animalId, capacity, depositId)
    if not Catalog.Get(animalId) or type(depositId) ~= "string" or #depositId < 1 or #depositId > 120 then
        return false, "invalid-animal"
    end
    local profile = profiles[player]
    if not profile or not profile.Loaded then
        return false, "profile-not-loaded"
    end

    local success, result = transact(player, function(current, data, state)
        local processed = sanitizeTimestampMap(current.ProcessedBarnDeposits, Config.Barn.MaximumDepositLedger)
        if processed[depositId] then
            state.duplicate = true
            return true
        end
        writeData(current, data)
        local animals = sanitizeBarnAnimals(current.BarnAnimals)
        if #animals >= capacity then
            return false, "barn-full"
        end
        table.insert(animals, animalId)
        current.BarnAnimals = animals
        current.TotalDeposited = math.min(2147483647, integer(current.TotalDeposited, 0, 2147483647, 0) + 1)
        processed[depositId] = os.time()
        current.ProcessedBarnDeposits = sanitizeTimestampMap(processed, Config.Barn.MaximumDepositLedger)
        state.animalCount = #animals
        return true
    end)
    if not success then
        return false, result
    end
    return true, result.animalCount or #profile.Data.BarnAnimals, result.duplicate == true
end

function ProfileService.CollectBarnIncome(player)
    local profile = profiles[player]
    if not profile or not profile.Loaded then
        return false, 0, "profile-not-loaded"
    end
    local available = math.floor(profile.Data.BarnBank)
    if available <= 0 then
        return true, 0
    end
    local success, result = transact(player, function(current, data, state)
        writeData(current, data)
        local bank = integer(data.BarnBank, 0, Config.CoinsLimit, 0)
        local coins = integer(data.Coins, 0, Config.CoinsLimit, 0)
        local credited = math.min(bank, Config.CoinsLimit - coins)
        current.Coins = coins + credited
        current.BarnBank = bank - credited
        state.amount = credited
        return true
    end)
    if not success then
        return false, 0, result
    end
    return true, result.amount or 0
end

function ProfileService.GrantStackableProduct(player, purchaseId, statName, amount)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Leaving
        or type(purchaseId) ~= "string" or purchaseId == "" or #purchaseId > 120
        or (statName ~= "Speed" and statName ~= "Coins")
        or not finiteNumber(amount) or amount < 1 or amount > Config.CoinsLimit
        or amount ~= math.floor(amount) then
        return false, 0, false
    end

    local success, result = transact(player, function(current, data, state)
        local processed = sanitizeTimestampMap(current.ProcessedPurchases, 500)
        if processed[purchaseId] then
            state.duplicate = true
            state.amount = 0
            return true
        end
        writeData(current, data)
        local maximum = statName == "Speed" and Config.MaxSpeedLevel or Config.CoinsLimit
        local before = integer(current[statName], 0, maximum, 0)
        local after = math.clamp(before + amount, 0, maximum)
        current[statName] = after
        processed[purchaseId] = os.time()
        current.ProcessedPurchases = sanitizeTimestampMap(processed, 500)
        state.amount = after - before
        return true
    end)

    if not success then
        return false, 0, false
    end
    return true, result.amount or 0, result.duplicate == true
end

function ProfileService.RedeemCode(player, code, reward)
    local profile = profiles[player]
    if not profile or not profile.Loaded or type(code) ~= "string"
        or #code < 1 or #code > 48 or not finiteNumber(reward) or reward < 0 then
        return false, "invalid-code"
    end
    code = string.upper(code)
    local success, result = transact(player, function(current, data, state)
        local redeemed = sanitizeTimestampMap(current.RedeemedCodes, 100)
        if redeemed[code] then
            return false, "already-redeemed"
        end
        writeData(current, data)
        current.Coins = math.clamp(integer(current.Coins, 0, Config.CoinsLimit, 0) + math.floor(reward), 0, Config.CoinsLimit)
        redeemed[code] = os.time()
        current.RedeemedCodes = redeemed
        state.reward = math.floor(reward)
        return true
    end)
    if not success then
        return false, result
    end
    return true, result.reward or 0
end

function ProfileService.ClaimDailyReward(player)
    local profile = profiles[player]
    if not profile or not profile.Loaded then
        return false, "profile-not-loaded"
    end
    local today = math.floor(os.time() / 86400)
    local success, result = transact(player, function(current, data, state)
        if integer(current.LastDailyClaimDay, 0, 2147483647, 0) >= today then
            return false, "already-claimed"
        end
        writeData(current, data)
        local previousDay = integer(current.LastDailyClaimDay, 0, 2147483647, 0)
        local previousStreak = integer(current.DailyStreak, 0, 7, 0)
        local streak = previousDay == today - 1 and math.min(previousStreak + 1, 7) or 1
        local reward = 500 + (streak - 1) * 250
        current.Coins = math.clamp(integer(current.Coins, 0, Config.CoinsLimit, 0) + reward, 0, Config.CoinsLimit)
        current.LastDailyClaimDay = today
        current.DailyStreak = streak
        state.reward = reward
        state.streak = streak
        return true
    end)
    if not success then
        return false, result
    end
    return true, result.reward, result.streak
end

function ProfileService.ClaimQuest(player, questId)
    local profile = profiles[player]
    if not profile or not profile.Loaded or type(questId) ~= "string" then
        return false, "invalid-quest"
    end
    local quests = {
        FirstCapture = { Reward = 250, Requirement = function(data) return data.TotalCaptured >= 1 end },
        FirstBarn = { Reward = 750, Requirement = function(data) return data.TotalDeposited >= 1 end },
        Collector = { Reward = 1500, Requirement = function(data) return data.TotalCaptured >= 5 end },
        FullBarn = { Reward = 5000, Requirement = function(data) return #data.BarnAnimals >= Config.Barn.BaseSlots end },
    }
    local quest = quests[questId]
    if not quest then
        return false, "invalid-quest"
    end

    local success, result = transact(player, function(current, data, state)
        local claims = sanitizeTimestampMap(current.QuestClaims, 100)
        if claims[questId] then
            return false, "already-claimed"
        end
        writeData(current, data)
        local currentData = sanitize(current)
        if not quest.Requirement(currentData) then
            return false, "requirements"
        end
        current.Coins = math.clamp(integer(current.Coins, 0, Config.CoinsLimit, 0) + quest.Reward, 0, Config.CoinsLimit)
        claims[questId] = os.time()
        current.QuestClaims = claims
        state.reward = quest.Reward
        return true
    end)
    if not success then
        return false, result
    end
    return true, result.reward or quest.Reward
end

function ProfileService.PerformRebirth(player)
    local profile = profiles[player]
    if not profile or not profile.Loaded or profile.Leaving then
        return false, "profile-not-loaded"
    end
    if player:GetAttribute("CarryingAnimal") == true then
        return false, "carrying-animal"
    end
    if profile.Data.Speed < Config.MaxSpeedLevel or profile.Data.Coins < Config.RebirthCoinsRequired then
        return false, "requirements"
    end
    if profile.Data.Rebirths >= Config.MaxRebirths then
        return false, "max-rebirths"
    end

    local success, result = transact(player, function(current, data, state)
        writeData(current, data)
        local speed = integer(current.Speed, 0, Config.MaxSpeedLevel, 0)
        local coins = integer(current.Coins, 0, Config.CoinsLimit, 0)
        local rebirths = integer(current.Rebirths, 0, Config.MaxRebirths, 0)
        if speed < Config.MaxSpeedLevel or coins < Config.RebirthCoinsRequired then
            return false, "requirements"
        end
        if rebirths >= Config.MaxRebirths then
            return false, "max-rebirths"
        end
        current.Speed = 0
        current.Coins = 0
        current.Rebirths = rebirths + 1
        state.rebirths = current.Rebirths
        return true
    end)
    if not success then
        return false, result
    end
    return true, result.rebirths or profile.Data.Rebirths
end

function ProfileService.Remove(player)
    profiles[player] = nil
end

function ProfileService.StartAutosave()
    task.spawn(function()
        while true do
            task.wait(Config.AutosaveSeconds)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(function()
                    local profile = profiles[player]
                    if profile and profile.Loaded and not profile.Leaving then
                        ProfileService.Save(player, false)
                    end
                end)
                task.wait(0.1)
            end
        end
    end)
end

function ProfileService.MarkLeaving(player)
    local profile = profiles[player]
    if profile then
        profile.Leaving = true
    end
end

return ProfileService
