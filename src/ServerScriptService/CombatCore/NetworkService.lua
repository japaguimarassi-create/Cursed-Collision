--!strict

local NetworkService = {}

local ACTIONS = {
    M1 = true,
    M1Hit = true,
    Dash = true,
    BlockStart = true,
    BlockEnd = true,
    Special = true,
    Skill1 = true,
    Skill2 = true,
    Skill3 = true,
    Skill4 = true,
    SkillHit = true,
    SelectCharacter = true,
    Ultimate = true,
    Awakening = true
}

function NetworkService:IsKnownAction(action: any): boolean
    return type(action) == "string"
        and #action <= 40
        and ACTIONS[action] == true
end

function NetworkService:ValidatePayload(action: string, payload: any): boolean
    if action == "M1"
        or action == "BlockStart"
        or action == "BlockEnd"
        or action == "Special"
        or action == "Skill1"
        or action == "Skill2"
        or action == "Skill3"
        or action == "Skill4" then
        return payload == nil
    end

    if action == "Dash" then
        return type(payload) == "string"
            and (
                payload == "Forward"
                or payload == "Back"
                or payload == "Left"
                or payload == "Right"
            )
    end

    if action == "M1Hit" or action == "SkillHit" then
        return type(payload) == "table"
            and type(payload.attackId) == "string"
            and #payload.attackId <= 96
    end

    if action == "SelectCharacter" then
        return type(payload) == "string" and #payload <= 32
    end

    if action == "Ultimate" or action == "Awakening" then
        return payload == nil
    end

    return false
end

function NetworkService:SanitizeDashDirection(payload: any): string
    if payload == "Back"
        or payload == "Left"
        or payload == "Right" then
        return payload
    end

    return "Forward"
end

return NetworkService
