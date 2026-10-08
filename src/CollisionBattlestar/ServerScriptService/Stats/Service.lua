--!strict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelRules = require(ReplicatedStorage.Shared.LevelRules)

local RANKING_STORE = "CollisionBattlestar_Ranking_v1"
local LEADERBOARD_WRITE_INTERVAL = 20
local MAX_SCORE = 2^53

local StatsService = {}
StatsService.__index = StatsService

function StatsService.new(playerState, runtimeState, enemyService)
    local ok, store = pcall(function()
        return DataStoreService:GetOrderedDataStore(RANKING_STORE)
    end)

    return setmetatable({
        playerState = playerState,
        runtimeState = runtimeState,
        enemyService = enemyService,
        rankingStore = ok and store or nil,
        running = false,
        lastWave = 0,
        lastAwardedWave = 0,
        lastWaveMeta = {},
        pendingRanking = {} :: {[Player]: number},
        lastRankingWrite = {} :: {[Player]: number},
        connections = {},
    }, StatsService)
end

function StatsService:Publish(player: Player)
    local score = self.playerState:GetScore(player)
    local level = LevelRules.levelForScore(score)
    local progress = LevelRules.progress(score)

    player:SetAttribute("CBS_Score", score)
    player:SetAttribute("CBS_Level", level)
    player:SetAttribute("CBS_LevelProgress", progress.Current)
    player:SetAttribute("CBS_LevelRequired", progress.Required)

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local scoreValue = leaderstats:FindFirstChild("Score")
    if not scoreValue then
        scoreValue = Instance.new("IntValue")
        scoreValue.Name = "Score"
        scoreValue.Parent = leaderstats
    end
    scoreValue.Value = math.clamp(math.floor(score), 0, 2147483647)

    local levelValue = leaderstats:FindFirstChild("Level")
    if not levelValue then
        levelValue = Instance.new("IntValue")
        levelValue.Name = "Level"
        levelValue.Parent = leaderstats
    end
    levelValue.Value = math.clamp(level, 1, 2147483647)

    self.pendingRanking[player] = score
end

function StatsService:AddScore(player: Player, amount: number, reason: string?)
    if not player.Parent then
        return false
    end

    local safeAmount = math.floor(tonumber(amount) or 0)
    if safeAmount <= 0 then
        return false
    end

    local current = self.playerState:GetScore(player)
    local added = math.min(safeAmount, math.max(0, MAX_SCORE - current))

    if added <= 0 then
        return false
    end

    if not self.playerState:AddScore(player, added) then
        return false
    end

    self:Publish(player)

    local previousLevel = LevelRules.levelForScore(current)
    local nextLevel = LevelRules.levelForScore(current + added)

    if nextLevel > previousLevel then
        local remoteFolder = ReplicatedStorage:FindFirstChild("CollisionBattlestarRemotes")
        local remote = remoteFolder and remoteFolder:FindFirstChild("State")
        if remote and remote:IsA("RemoteEvent") then
            remote:FireClient(player, "LevelUp", {
                level = nextLevel,
                score = current + added,
                reason = reason or "progress",
            })
        end
    end

    return true, added
end

function StatsService:AwardEnemy(player: Player, reward: number, isElite: boolean, isBoss: boolean)
    local base = math.max(5, math.floor((tonumber(reward) or 0) * 2))
    if isElite then
        base += 40
    end
    if isBoss then
        base += 180
    end

    return self:AddScore(player, base, isBoss and "boss" or isElite and "elite" or "enemy")
end

function StatsService:AwardWave(wave: number, bossId: string?, eventId: string?)
    local safeWave = math.max(1, math.floor(tonumber(wave) or 1))
    local amount = 50 + safeWave * 5

    if bossId then
        amount += 150
    end

    if eventId == "CreditRush" then
        amount += 50
    elseif eventId == "Overdrive" then
        amount += 75
    elseif eventId == "RiftSurge" then
        amount += 40
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("CBS_PvP") ~= true then
            self:AddScore(player, amount, "wave")
        end
    end
end

function StatsService:AwardPvPKill(player: Player)
    return self:AddScore(player, 120, "pvp")
end

function StatsService:Flush(player: Player)
    if not self.rankingStore or not player.Parent then
        return false
    end

    local score = self.playerState:GetScore(player)

    local ok = pcall(function()
        self.rankingStore:SetAsync(tostring(player.UserId), score)
    end)

    if ok then
        self.pendingRanking[player] = nil
        self.lastRankingWrite[player] = os.clock()
    end

    return ok
end

function StatsService:FlushPending()
    for player, _ in pairs(self.pendingRanking) do
        if player.Parent then
            local last = self.lastRankingWrite[player] or -math.huge
            if os.clock() - last >= LEADERBOARD_WRITE_INTERVAL then
                self:Flush(player)
            end
        else
            self.pendingRanking[player] = nil
            self.lastRankingWrite[player] = nil
        end
    end
end

function StatsService:Start()
    if self.running then
        return
    end

    self.running = true

    for _, player in ipairs(Players:GetPlayers()) do
        self:Publish(player)
    end

    table.insert(self.connections, Players.PlayerAdded:Connect(function(player)
        task.defer(function()
            if player.Parent then
                self:Publish(player)
            end
        end)
    end))

    table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
        self:Flush(player)
        self.pendingRanking[player] = nil
        self.lastRankingWrite[player] = nil
    end))

    table.insert(self.connections, self.enemyService:GetDefeatedEvent():Connect(function(_, isElite, _, isBoss, isTestSpawn, killerUserId, reward)
        if isTestSpawn or type(killerUserId) ~= "number" then
            return
        end

        local player = Players:GetPlayerByUserId(killerUserId)
        if player then
            self:AwardEnemy(player, reward, isElite == true, isBoss == true)
        end
    end))

    table.insert(self.connections, self.runtimeState:GetChangedEvent():Connect(function()
        if self.runtimeState.phase == "Wave" then
            self.lastWave = self.runtimeState.wave
            self.lastWaveMeta = {
                bossId = self.runtimeState.bossId,
                eventId = self.runtimeState.eventId,
            }
            return
        end

        if self.runtimeState.phase ~= "Intermission" then
            return
        end

        local completed = self.runtimeState.lastCompletedWave
        if completed <= 0 or completed <= self.lastAwardedWave then
            return
        end

        self.lastAwardedWave = completed
        self:AwardWave(
            completed,
            self.lastWaveMeta.bossId,
            self.lastWaveMeta.eventId
        )
    end))

    task.spawn(function()
        while self.running do
            self:FlushPending()
            task.wait(5)
        end
    end)
end

function StatsService:HealthCheck()
    return self.running
end

function StatsService:Stop()
    self.running = false

    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    table.clear(self.connections)
end

function StatsService:GetSnapshot(player: Player)
    local score = self.playerState:GetScore(player)
    local progress = LevelRules.progress(score)

    return {
        Score = score,
        Level = progress.Level,
        Progress = progress.Current,
        Required = progress.Required,
    }
end

return StatsService
