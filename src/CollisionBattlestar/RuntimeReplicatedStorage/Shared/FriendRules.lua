--!strict

local FriendRules = {}

local VALID_CLASSES = {
    Vanguard = true,
    Striker = true,
    Guardian = true,
    Support = true,
}

function FriendRules.isValidUserId(value: any)
    return type(value) == "number"
        and value == math.floor(value)
        and value > 0
        and value < 2^53
end

function FriendRules.isValidClass(classId: any)
    return type(classId) == "string" and VALID_CLASSES[classId] == true
end

function FriendRules.isFriend(friendUserId: number, friends: {any})
    for _, friend in ipairs(friends) do
        if type(friend) == "table" and friend.Id == friendUserId then
            return true
        end
    end
    return false
end

function FriendRules.canSelect(requesterUserId: any, friendUserId: any, friends: {any}, classId: any)
    if not FriendRules.isValidUserId(requesterUserId) then
        return false, "invalid_requester"
    end

    if not FriendRules.isValidUserId(friendUserId) then
        return false, "invalid_friend"
    end

    if requesterUserId == friendUserId then
        return false, "self_not_allowed"
    end

    if not FriendRules.isValidClass(classId) then
        return false, "invalid_class"
    end

    if not FriendRules.isFriend(friendUserId, friends) then
        return false, "not_friend"
    end

    return true, "ok"
end

function FriendRules.cacheFresh(fetchedAt: number, now: number, maxAge: number)
    return type(fetchedAt) == "number"
        and type(now) == "number"
        and type(maxAge) == "number"
        and now - fetchedAt < maxAge
end

return table.freeze(FriendRules)
