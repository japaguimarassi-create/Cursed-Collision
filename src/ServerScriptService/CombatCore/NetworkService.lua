--!strict

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

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
        or action == "Skill4"
        or action == "Ultimate"
        or action == "Awakening" then
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

    if action == "SelectCharacter" then
        return type(payload) == "string" and #payload <= 32
    end

    if action == "M1Hit" or action == "SkillHit" then
        if type(payload) ~= "table" then
            return false
        end

        if type(payload.attackId) ~= "string"
            or #payload.attackId > Config.AntiCheat.MaxPayloadLength then
            return false
        end

        return type(payload.token) == "number"
            and payload.token >= 0
            and payload.token % 1 == 0
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

function NetworkService:SanitizeMarkerPayload(
    payload: any
): (string?, number?)
    if type(payload) ~= "table" then
        return nil, nil
    end

    local attackId = payload.attackId
    if type(attackId) ~= "string"
        or #attackId > Config.AntiCheat.MaxPayloadLength then
        return nil, nil
    end

    local token = payload.token
    if token ~= nil
        and (
            type(token) ~= "number"
            or token < 0
            or token % 1 ~= 0
        ) then
        return nil, nil
    end

    return attackId, token
end

return NetworkService
