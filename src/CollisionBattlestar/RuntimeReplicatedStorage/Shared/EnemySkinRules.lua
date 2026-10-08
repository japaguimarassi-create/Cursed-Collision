--!strict

local Definitions = require(script.Parent.EnemySkinDefinitions)

local EnemySkinRules = {}

local function validTier(tier: any)
    return type(tier) == "number" and tier >= 1 and tier <= 4 and tier == math.floor(tier)
end

function EnemySkinRules.isValidProfile(profile: any)
    return type(profile) == "table"
        and type(profile.ProfileId) == "string"
        and type(profile.ThemeId) == "string"
        and validTier(profile.Tier)
        and Definitions.Themes[profile.ThemeId] ~= nil
end

function EnemySkinRules.validProfiles(themeId: string, tier: number)
    local source = Definitions.Profiles[themeId]
    if not source or not validTier(tier) then
        return {}
    end

    local output = {}
    for _, profile in ipairs(source) do
        if profile.Tier == tier and EnemySkinRules.isValidProfile(profile) then
            table.insert(output, profile)
        end
    end

    return output
end

function EnemySkinRules.pick(themeId: string, tier: number, seed: number, previousProfileId: string?)
    local candidates = EnemySkinRules.validProfiles(themeId, tier)

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
