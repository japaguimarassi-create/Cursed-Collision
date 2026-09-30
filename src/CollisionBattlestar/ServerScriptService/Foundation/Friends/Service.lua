--!strict

local Players = game:GetService("Players")
local FriendRules = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("FriendRules"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({cache = {}}, Service)
end

function Service:ResolveFriends(player: Player): {any}
    local cached = self.cache[player]
    if cached and os.clock() - cached.at < 60 then
        return cached.friends
    end

    local friends = {}
    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(player.UserId)
    end)
    if ok and pages then
        while true do
            for _, item in ipairs(pages:GetCurrentPage()) do
                if typeof(item.Id) == "number" and item.Id > 0 then
                    table.insert(friends, {
                        UserId = item.Id,
                        Username = tostring(item.Username or ""),
                        DisplayName = tostring(item.DisplayName or item.Username or ""),
                    })
                end
            end
            if pages.IsFinished then
                break
            end
            local advanced = pcall(function()
                pages:AdvanceToNextPageAsync()
            end)
            if not advanced then
                break
            end
        end
    end
    self.cache[player] = {at = os.clock(), friends = friends}
    return friends
end

function Service:IsFriend(player: Player, friendUserId: number): boolean
    local ids = {}
    for _, friend in ipairs(self:ResolveFriends(player)) do
        table.insert(ids, friend.UserId)
    end
    return FriendRules.isEligible(player.UserId, friendUserId, ids)
end

function Service:Invalidate(player: Player)
    self.cache[player] = nil
end

function Service:Start()
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        self:Invalidate(player)
    end)
end

return Service
