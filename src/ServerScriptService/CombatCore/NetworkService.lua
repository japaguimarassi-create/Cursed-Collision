--!strict

local NetworkService = {}

local ACTIONS = {
    M1 = true,
    Heavy = true,
    Grab = true,
    Dash = true,
    DashAttack = true,
    Dodge = true,
    Counter = true,
    Slam = true,
    BlockStart = true,
    BlockEnd = true,
    Special = true,
    Skill = true,
    Awaken = true,
    Domain = true,
    OneTime = true,
    ClashMove = true,
}

function NetworkService:IsKnownAction(action: any): boolean
    return type(action) == "string" and #action <= 32 and ACTIONS[action] == true
end

function NetworkService:ValidatePayload(action: string, payload: any): boolean
    if payload == nil then
        return true
    end

    if action == "ClashMove" then
        return type(payload) == "number" and payload >= 1 and payload <= 4 and payload % 1 == 0
    end

    if action == "Dash" or action == "DashAttack" then
        return type(payload) == "string"
            and (payload == "Forward" or payload == "Back" or payload == "Left" or payload == "Right")
    end

    return type(payload) == "string" or type(payload) == "number" or type(payload) == "boolean"
end

function NetworkService:SanitizeDashDirection(payload: any): string
    if payload == "Back" or payload == "Left" or payload == "Right" then
        return payload
    end
    return "Forward"
end

return NetworkService
