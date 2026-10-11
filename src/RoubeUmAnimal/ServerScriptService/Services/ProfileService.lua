local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayRules"))
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local ProfileService = {}
local profiles = {}

local function finiteNumber(value)
    return Rules.IsFinite(value)
end

local function integer(value, minimum, maximum, fallback)
    return Rules.Integer(value, minimum, maximum, fallback)
end

local function defaults()
    return {
        SchemaVersion = 1,
        Coins = 0,
        Speed = 0,
        Strength = 10,
        UpdatedAt = os.time(),
    }
end

local function sanitize(raw)
    raw = type(raw) == "table" and raw or defaults()

    return {
        SchemaVersion = 1,
        Coins = integer(raw.Coins, 0, Config.CoinsLimit, 0),
        Speed = integer(raw.Speed, 0, Config.MaxSpeedLevel, 0),
        Strength = integer(raw.Strength, 1, Config.MaxStrength, 10),
        UpdatedAt = integer(raw.UpdatedAt, 0, 2147483647, os.time()),
    }
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

    local values = {
        Coins = ensureValue("Moedas", data.Coins),
        Speed = ensureValue("Velocidade", data.Speed),
        Strength = ensureValue("Força", data.Strength),
    }

    player:SetAttribute("Coins", data.Coins)
    player:SetAttribute("SpeedLevel", data.Speed)
    player:SetAttribute("Strength", data.Strength)
    player:SetAttribute("DataLoaded", true)

    return values
end

local function mirror(player, profile)
    local data = profile.Data
    local values = profile.Values

    values.Coins.Value = data.Coins
    values.Speed.Value = data.Speed
    values.Strength.Value = data.Strength

    player:SetAttribute("Coins", data.Coins)
    player:SetAttribute("SpeedLevel", data.Speed)
    player:SetAttribute("Strength", data.Strength)
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

                return result
            end)
        end)

        if success
            and type(record) == "table"
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
            warn("RoubeUmAnimal: falha ao carregar UserId " .. player.UserId .. ": " .. tostring(record))
        elseif conflictingLock then
            warn("RoubeUmAnimal: perfil bloqueado por outra sessão para UserId " .. player.UserId)
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
        warn("RoubeUmAnimal: salvamento anterior ainda em andamento para UserId " .. player.UserId)
        return false
    end

    profile.Saving = true
    local key = "Player_" .. tostring(player.UserId)

    local success, result
    for attempt = 1, 3 do
        success, result = pcall(function()
        return Store:UpdateAsync(key, function(current)
            if type(current) ~= "table" then
                return nil
            end

            local lock = current.SessionLock

            if type(lock) ~= "table" or lock.Token ~= profile.SessionId then
                return nil
            end

            current.SchemaVersion = 1
            current.Coins = integer(profile.Data.Coins, 0, Config.CoinsLimit, 0)
            current.Speed = integer(profile.Data.Speed, 0, Config.MaxSpeedLevel, 0)
            current.Strength = integer(profile.Data.Strength, 1, Config.MaxStrength, 10)
            current.UpdatedAt = os.time()

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
        warn("RoubeUmAnimal: falha ao salvar UserId " .. player.UserId .. ": " .. tostring(result))
        return false
    end

    if type(result) ~= "table" then
        warn("RoubeUmAnimal: sessão perdeu autorização de salvamento para UserId " .. player.UserId)
        return false
    end

    if releaseLock and result.SessionLock == nil then
        profile.Loaded = false
    end

    return true
end

function ProfileService.AddCoins(player, amount)
    local profile = profiles[player]

    if not profile or not profile.Loaded or not finiteNumber(amount) or amount < 0 then
        return false, 0
    end

    local before = profile.Data.Coins
    profile.Data.Coins = math.clamp(
        before + math.floor(amount),
        0,
        Config.CoinsLimit
    )

    mirror(player, profile)
    return true, profile.Data.Coins - before
end

function ProfileService.SpendCoins(player, amount)
    local profile = profiles[player]

    if not profile or not profile.Loaded or not finiteNumber(amount) then
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

    if not profile or not profile.Loaded or not finiteNumber(amount) then
        return false
    end

    amount = math.floor(amount)
    if amount <= 0 then
        return false
    end

    if statName == "Speed" then
        profile.Data.Speed = math.clamp(
            profile.Data.Speed + amount,
            0,
            Config.MaxSpeedLevel
        )
    elseif statName == "Strength" then
        profile.Data.Strength = math.clamp(
            profile.Data.Strength + amount,
            1,
            Config.MaxStrength
        )
    else
        return false
    end

    mirror(player, profile)
    return true
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
