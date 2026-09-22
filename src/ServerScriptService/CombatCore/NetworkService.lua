--!strict

local NetworkService = {}

local ACTIONS = {
    M1 = true,
    Dash = true,
    BlockStart = true,
    BlockEnd = true,
    Special = true,
    SelectCharacter = true
}

function NetworkService:IsKnownAction(action: any): boolean
    return type(action) == "string"
        and #action <= 40
        and ACTIONS[action] == true
end

function NetworkService:ValidatePayload(action: string, payload: any): boolean
    if payload == nil then
        return action ~= "Dash"
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

    return false
end

function NetworkService:SanitizeDashDirection(payload: any): string
    if payload == "Back" or payload == "Left" or payload == "Right" then
        return payload
    end
    return "Forward"
end

return NetworkService