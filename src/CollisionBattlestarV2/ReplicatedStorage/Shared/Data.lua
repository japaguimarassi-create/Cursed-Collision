--!strict

local Data = {}
Data.Version = 1

function Data.default()
    return {
        Version = Data.Version,
        Credits = 0,
        Score = 0,
        Kills = 0,
        Waves = 0,
        Upgrades = {
            Damage = 0,
            Health = 0,
            Dash = 0,
        },
        Missions = {
            Waves = 0,
            Elites = 0,
            Bosses = 0,
            Credits = 0,
        },
        Inventory = {
            Owned = {Default = true},
            Equipped = {
                PlayerSkin = "Default",
                AttackFX = "Default",
            },
        },
    }
end

local function int(v: any, fallback: number, max: number)
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
        return fallback
    end
    return math.clamp(math.floor(v), 0, max)
end

function Data.sanitize(source: any)
    local out = Data.default()
    if type(source) ~= "table" then
        return out
    end

    out.Credits = int(source.Credits, 0, 2147483647)
    out.Score = int(source.Score, 0, 9007199254740991)
    out.Kills = int(source.Kills, 0, 2147483647)
    out.Waves = int(source.Waves, 0, 2147483647)

    if type(source.Upgrades) == "table" then
        for id in pairs(out.Upgrades) do
            out.Upgrades[id] = int(source.Upgrades[id], 0, 100)
        end
    end

    if type(source.Missions) == "table" then
        for id in pairs(out.Missions) do
            out.Missions[id] = int(source.Missions[id], 0, 2147483647)
        end
    end

    if type(source.Inventory) == "table" then
        if type(source.Inventory.Owned) == "table" then
            for id, owned in pairs(source.Inventory.Owned) do
                if type(id) == "string" and #id <= 64 and owned == true then
                    out.Inventory.Owned[id] = true
                end
            end
        end
        if type(source.Inventory.Equipped) == "table" then
            for slot, id in pairs(source.Inventory.Equipped) do
                if type(slot) == "string" and type(id) == "string" and #slot <= 64 and #id <= 64 then
                    out.Inventory.Equipped[slot] = id
                end
            end
        end
    end

    out.Version = Data.Version
    return out
end

return table.freeze(Data)
