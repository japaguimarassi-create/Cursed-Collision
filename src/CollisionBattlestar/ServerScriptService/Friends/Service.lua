--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendRules = require(ReplicatedStorage.Shared.FriendRules)

local CACHE_TTL = 60
local REQUEST_COOLDOWN = 1.5
local MAX_PAGES = 12

local FriendService = {}
FriendService.__index = FriendService

function FriendService.new()
    return setmetatable({
        caches = {} :: {[Player]: {fetchedAt: number, friends: {any}}},
        lastRequests = {} :: {[Player]: number},
    }, FriendService)
end

function FriendService:Start()
    Players.PlayerRemoving:Connect(function(player)
        self.caches[player] = nil
        self.lastRequests[player] = nil
    end)
end

function FriendService:Resolve(player: Player, forceRefresh: boolean?)
    local cached = self.caches[player]
    local now = os.clock()

    if cached and not forceRefresh and FriendRules.cacheFresh(cached.fetchedAt, now, CACHE_TTL) then
        return cached.friends
    end

    local friends = {}
    local success, result = pcall(function()
        local pages = Players:GetFriendsAsync(player.UserId)

        for _ = 1, MAX_PAGES do
            for _, item in ipairs(pages:GetCurrentPage()) do
                if type(item) == "table" and FriendRules.isValidUserId(item.Id) then
                    table.insert(friends, {
                        Id = item.Id,
                        Username = type(item.Username) == "string" and item.Username or "",
                        DisplayName = type(item.DisplayName) == "string" and item.DisplayName or "",
                    })
                end
            end

            if pages.IsFinished then
                break
            end

            pages:AdvanceToNextPageAsync()
        end

        return true
    end)

    if not success then
        if cached then
            return cached.friends, "stale_cache"
        end
        return {}, tostring(result)
    end

    table.sort(friends, function(a, b)
        return a.DisplayName < b.DisplayName
    end)

    self.caches[player] = {
        fetchedAt = now,
        friends = friends,
    }

    return friends
end

function FriendService:CanRequest(player: Player)
    local now = os.clock()
    local last = self.lastRequests[player] or -math.huge

    if now - last < REQUEST_COOLDOWN then
        return false
    end

    self.lastRequests[player] = now
    return true
end

function FriendService:Select(player: Player, friendUserId: any, classId: any)
    if not self:CanRequest(player) then
        return false, "rate_limited"
    end

    local friends = self:Resolve(player, false)
    local ok, reason = FriendRules.canSelect(player.UserId, friendUserId, friends, classId)

    if not ok and reason == "not_friend" then
        friends = self:Resolve(player, true)
        ok, reason = FriendRules.canSelect(player.UserId, friendUserId, friends, classId)
    end

    if not ok then
        return false, reason
    end

    for _, friend in ipairs(friends) do
        if friend.Id == friendUserId then
            return true, friend
        end
    end

    return false, "friend_not_found"
end

return FriendService
