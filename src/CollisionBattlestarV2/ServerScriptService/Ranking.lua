--!strict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Ranking = {}
Ranking.__index = Ranking

local STORE = "CBS2_Ranking_v1"

function Ranking.new(playerService, remotes)
    local store = nil
    local ok, result = pcall(function()
        return DataStoreService:GetOrderedDataStore(STORE)
    end)
    if ok then
        store = result
    end

    return setmetatable({
        players = playerService,
        remotes = remotes,
        store = store,
        lastWrite = {},
        connections = {},
        running = false,
    }, Ranking)
end

function Ranking:Write(player: Player, force: boolean?)
    if not self.store then
        return
    end

    local now = os.clock()
    if not force and now - (self.lastWrite[player] or -math.huge) < 60 then
        return
    end

    local state = self.players:State(player)
    if not state then
        return
    end

    local ok = pcall(function()
        self.store:SetAsync(tostring(player.UserId), state.profile.Score)
    end)

    if ok then
        self.lastWrite[player] = now
    end
end

function Ranking:Top(limit: number)
    local safeLimit = math.clamp(math.floor(tonumber(limit) or 10), 1, 10)

    if self.store then
        local ok, pages = pcall(function()
            return self.store:GetSortedAsync(false, safeLimit)
        end)

        if ok and pages then
            local result = {}
            for rank, item in ipairs(pages:GetCurrentPage()) do
                local userId = tonumber(item.key)
                local name = item.key

                if userId then
                    local nameOk, resolved = pcall(function()
                        return Players:GetNameFromUserIdAsync(userId)
                    end)
                    if nameOk then
                        name = resolved
                    end
                end

                result[#result + 1] = {
                    rank = rank,
                    name = name,
                    score = tonumber(item.value) or 0,
                }
            end
            return result, "global"
        end
    end

    local result = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local state = self.players:State(player)
        if state then
            result[#result + 1] = {
                name = player.DisplayName,
                userId = player.UserId,
                score = state.profile.Score,
            }
        end
    end

    table.sort(result, function(a, b)
        if a.score == b.score then
            return a.userId < b.userId
        end
        return a.score > b.score
    end)

    for rank, entry in ipairs(result) do
        entry.rank = rank
    end

    return result, "server"
end

function Ranking:Start()
    if self.running then
        return
    end
    self.running = true

    for _, player in ipairs(Players:GetPlayers()) do
        self:Write(player, true)
    end

    table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
        self:Write(player)
        self.lastWrite[player] = nil
    end))

    table.insert(self.connections, self.remotes.State.OnServerEvent:Connect(function(player, request)
        if type(request) == "table" and request.action == "Ranking" then
            local top, scope = self:Top(10)
            self.remotes.State:FireClient(player, "Ranking", {
                rows = top,
                scope = scope,
            })
        end
    end))

    task.spawn(function()
        while self.running do
            for _, player in ipairs(Players:GetPlayers()) do
                self:Write(player)
            end
            task.wait(10)
        end
    end)
end

function Ranking:Stop()
    self.running = false
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

function Ranking:Reload()
    return true
end

return Ranking
