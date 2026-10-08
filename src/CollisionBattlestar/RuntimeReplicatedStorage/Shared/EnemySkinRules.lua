--!strict

local EnemySkinRules = {}

local function validTier(tier: any)
    return type(tier) == "number" and tier >= 1 and tier <= 4 and tier == math.floor(tier)
end

function EnemySkinRules.isValidProfile(profile: any, definitions)
    if type(profile) ~= "table"
        or type(profile.ProfileId) ~= "string"
        or type(profile.ThemeId) ~= "string"
        or not validTier(profile.Tier) then
        return false
    end

    if type(definitions) == "table" and definitions.Themes then
        return definitions.Themes[profile.ThemeId] ~= nil
    end

    return true
end

function EnemySkinRules.validProfiles(themeId: string, tier: number, definitions)
    if type(definitions) ~= "table" or type(definitions.Profiles) ~= "table" then
        return {}
    end

    local source = definitions.Profiles[themeId]
    if type(source) ~= "table" or not validTier(tier) then
        return {}
    end

    local output = {}
    for _, profile in ipairs(source) do
        if profile.Tier == tier and EnemySkinRules.isValidProfile(profile, definitions) then
            table.insert(output, profile)
        end
    end

    return output
end

function EnemySkinRules.pick(themeId: string, tier: number, seed: number, previousProfileId: string?, definitions)
    local candidates = EnemySkinRules.validProfiles(themeId, tier, definitions)

    if #candidates == 0 then
        return nil
    end

    local index = (math.abs(math.floor(seed)) % #candidates) + 1
    local chosen = candidates[index]

    if #candidates > 1 and chosen.ProfileId == previousProfileId then
        chosen = candidates[(index % #candidates) + 1]
    end

    return chosen
end

return table.freeze(EnemySkinRules)
