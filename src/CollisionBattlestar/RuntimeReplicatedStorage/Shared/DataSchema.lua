--!strict

local DataSchema = {}

DataSchema.CurrentVersion = 2

local function numberOr(value: any, fallback: number)
    if type(value) == "number" and value == value and value < math.huge and value > -math.huge then
        return value
    end
    return fallback
end

local function nonNegativeInt(value: any, fallback: number, maximum: number)
    local number = math.floor(numberOr(value, fallback))
    return math.clamp(number, 0, maximum)
end

local function defaultUpgrades()
    return {
        Damage = 0,
        MaxHealth = 0,
        Dash = 0,
        Critical = 0,
        Recovery = 0,
    }
end

local function defaultInventory()
    return {
        Owned = {},
        Equipped = {
            PlayerSkin = "Default",
            AttackFX = "Default",
            EchoCosmetic = "Default",
            EliteCosmetic = "Default",
        },
    }
end

function DataSchema.Default()
    return {
        SchemaVersion = DataSchema.CurrentVersion,
        Credits = 0,
        PowerLevel = 1,
        Kills = 0,
        TotalWaves = 0,
        Upgrades = defaultUpgrades(),
        Inventory = defaultInventory(),
        Echoes = {},
    }
end

local function sanitizeOwned(source: any)
    local output = {}

    if type(source) ~= "table" then
        return output
    end

    for itemId, owned in pairs(source) do
        if type(itemId) == "string" and #itemId <= 80 and owned == true then
            output[itemId] = true
        end
    end

    return output
end

local function sanitizeEquipped(source: any)
    local output = defaultInventory().Equipped

    if type(source) ~= "table" then
        return output
    end

    for slot, itemId in pairs(source) do
        if type(slot) == "string" and type(itemId) == "string" and #slot <= 60 and #itemId <= 80 then
            output[slot] = itemId
        end
    end

    return output
end

local function sanitizeEchoes(source: any)
    local output = {}

    if type(source) ~= "table" then
        return output
    end

    for key, echo in pairs(source) do
        if type(key) == "string" and type(echo) == "table" then
            local friendUserId = nonNegativeInt(echo.FriendUserId, 0, 2^53)
            local classId = type(echo.ClassId) == "string" and echo.ClassId or "Vanguard"
            local level = nonNegativeInt(echo.Level, 1, 100)
            local bond = nonNegativeInt(echo.Bond, 0, 1000)
            local cosmetics = {}

            if type(echo.CosmeticIds) == "table" then
                for index, cosmeticId in ipairs(echo.CosmeticIds) do
                    if index <= 16 and type(cosmeticId) == "string" and #cosmeticId <= 80 then
                        table.insert(cosmetics, cosmeticId)
                    end
                end
            end

            if friendUserId > 0 then
                output[key] = {
                    FriendUserId = friendUserId,
                    ClassId = classId,
                    Level = level,
                    Bond = bond,
                    CosmeticIds = cosmetics,
                    Equipped = echo.Equipped == true,
                }
            end
        end
    end

    return output
end

function DataSchema.Sanitize(source: any)
    local data = DataSchema.Default()

    if type(source) ~= "table" then
        return data
    end

    data.SchemaVersion = DataSchema.CurrentVersion
    data.Credits = nonNegativeInt(source.Credits, 0, 2^31 - 1)
    data.PowerLevel = nonNegativeInt(source.PowerLevel, 1, 1000)
    data.Kills = nonNegativeInt(source.Kills, 0, 2^31 - 1)
    data.TotalWaves = nonNegativeInt(source.TotalWaves, 0, 2^31 - 1)

    if type(source.Upgrades) == "table" then
        for upgradeId, defaultValue in pairs(defaultUpgrades()) do
            data.Upgrades[upgradeId] = nonNegativeInt(source.Upgrades[upgradeId], defaultValue, 100)
        end
    end

    if type(source.Inventory) == "table" then
        data.Inventory.Owned = sanitizeOwned(source.Inventory.Owned)
        data.Inventory.Equipped = sanitizeEquipped(source.Inventory.Equipped)
    end

    data.Echoes = sanitizeEchoes(source.Echoes)

    return data
end

function DataSchema.Migrate(source: any)
    if type(source) ~= "table" then
        return DataSchema.Default()
    end

    local schemaVersion = nonNegativeInt(source.SchemaVersion, 0, DataSchema.CurrentVersion)

    if schemaVersion == DataSchema.CurrentVersion then
        return DataSchema.Sanitize(source)
    end

    if schemaVersion == 0 or schemaVersion == 1 then
        local migrated = DataSchema.Sanitize(source)
        local legacyPower = nonNegativeInt(source.PowerLevel, 1, 1000)
        migrated.PowerLevel = math.max(1, legacyPower)
        return migrated
    end

    return DataSchema.Default()
end

return table.freeze(DataSchema)
