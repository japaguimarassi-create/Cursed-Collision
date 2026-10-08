--!strict

local CompanionRules = {}

local VALID_STATES = {
    Follow = true,
    Acquire = true,
    Position = true,
    Attack = true,
    Protect = true,
    Support = true,
    Retreat = true,
    Recover = true,
    Stunned = true,
    Disabled = true,
}

local ALLOWED_TRANSITIONS = {
    Follow = {Acquire = true, Retreat = true, Disabled = true},
    Acquire = {Position = true, Follow = true, Protect = true, Support = true, Disabled = true},
    Position = {Attack = true, Acquire = true, Follow = true, Protect = true, Support = true, Recover = true, Disabled = true},
    Attack = {Acquire = true, Position = true, Follow = true, Recover = true, Stunned = true, Disabled = true},
    Protect = {Attack = true, Position = true, Follow = true, Recover = true, Disabled = true},
    Support = {Attack = true, Position = true, Follow = true, Recover = true, Disabled = true},
    Retreat = {Recover = true, Follow = true, Disabled = true},
    Recover = {Follow = true, Acquire = true, Disabled = true},
    Stunned = {Recover = true, Disabled = true},
    Disabled = {Follow = true},
}

function CompanionRules.isValidState(state: any)
    return type(state) == "string" and VALID_STATES[state] == true
end

function CompanionRules.canTransition(fromState: any, toState: any)
    if not CompanionRules.isValidState(fromState) or not CompanionRules.isValidState(toState) then
        return false
    end

    if fromState == toState then
        return true
    end

    local transitions = ALLOWED_TRANSITIONS[fromState]
    return transitions and transitions[toState] == true or false
end

function CompanionRules.canSummon(activeCount: number)
    return math.floor(activeCount) < 1
end

function CompanionRules.healAmount(currentHealth: number, maxHealth: number, configuredAmount: number)
    local missing = math.max(0, maxHealth - currentHealth)
    return math.clamp(configuredAmount, 0, missing)
end

function CompanionRules.targetScore(classId: string, candidate: {Distance: number, MaxHealth: number, IsElite: boolean, ThreatensOwner: boolean, NearOwner: boolean})
    local score = 0

    if classId == "Striker" then
        if candidate.IsElite then score += 10000 end
        score += candidate.MaxHealth
        score -= candidate.Distance
    elseif classId == "Vanguard" then
        if candidate.ThreatensOwner then score += 1000 end
        if candidate.NearOwner then score += 500 end
        score -= candidate.Distance
    elseif classId == "Guardian" then
        if candidate.ThreatensOwner then score += 1200 end
        if candidate.NearOwner then score += 600 end
        score -= candidate.Distance
    elseif classId == "Support" then
        if candidate.ThreatensOwner then score += 900 end
        score -= candidate.Distance
    end

    return score
end

return table.freeze(CompanionRules)
