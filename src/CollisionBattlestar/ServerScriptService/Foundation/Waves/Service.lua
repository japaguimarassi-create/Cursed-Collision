--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Rules = require(Shared:WaitForChild("WaveRules"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({
        world = nil,
        enemies = nil,
        economy = nil,
        playerState = nil,
        state = nil,
        stateRemote = nil,
        wave = 0,
        phase = "Waiting",
        active = 0,
        elitePresent = false,
        running = false,
    }, Service)
end

function Service:Init(registry, remotes)
    self.world = registry:Get("World")
    self.enemies = registry:Get("Enemies")
    self.economy = registry:Get("Economy")
    self.playerState = registry:Get("PlayerState")
    self.state = registry:Get("RuntimeState")
    self.stateRemote = remotes.State
    self.enemies:SetDefeatHandler(function(model, tier, attackerId)
        self:OnEnemyDefeated(model, tier, attackerId)
    end)
end

function Service:Broadcast()
    self.state:Set(self.wave, self.phase, self.active, self.elitePresent)
    workspace:SetAttribute("CollisionWave", self.wave)
    workspace:SetAttribute("CollisionEnemies", self.active)
    workspace:SetAttribute("CollisionPhase", self.phase)
    workspace:SetAttribute("CollisionElite", self.elitePresent)
    self.stateRemote:FireAllClients("Wave", self.wave, self.active, self.phase, self.elitePresent)

    for _, player in ipairs(Players:GetPlayers()) do
        self.playerState:SetWave(player, self.wave)
    end
end

function Service:spawnWave(wave: number)
    local count = Rules.enemyCount(wave)
    self.active = count
    self.elitePresent = false
    self.phase = "Spawning"
    self:Broadcast()

    task.spawn(function()
        for index = 1, count - 1 do
            if #Players:GetPlayers() == 0 then
                self.enemies:ClearAll()
                self.active = 0
                self.phase = "Waiting"
                self:Broadcast()
                return
            end
            self.enemies:Spawn(Rules.normalTier(wave, index), index)
            task.wait(Constants.Waves.SpawnDelay)
        end

        if #Players:GetPlayers() == 0 then
            self.enemies:ClearAll()
            self.active = 0
            self.phase = "Waiting"
            self:Broadcast()
            return
        end

        self.elitePresent = true
        self.enemies:Spawn("Elite", count)
        self.phase = "Active"
        self:Broadcast()
    end)
end

function Service:beginNextWave()
    if #Players:GetPlayers() == 0 then
        self.enemies:ClearAll()
        self.active = 0
        self.elitePresent = false
        self.phase = "Waiting"
        self:Broadcast()
        return
    end

    self.wave += 1
    self:spawnWave(self.wave)
end

function Service:OnEnemyDefeated(_, tier: string, attackerId)
    self.active = math.max(0, self.active - 1)
    if tier == "Elite" then
        self.elitePresent = false
    end

    if typeof(attackerId) == "number" then
        local player = Players:GetPlayerByUserId(attackerId)
        if player then
            self.economy:GrantEnemyReward(player, tier)
        end
    end

    self:Broadcast()

    if self.phase == "Active" and self.active == 0 then
        local clearedWave = self.wave
        self.phase = "Cleared"
        self:Broadcast()
        self.economy:GrantWaveReward(clearedWave)

        task.delay(Constants.Waves.Intermission, function()
            if #Players:GetPlayers() > 0 and self.phase == "Cleared" and self.wave == clearedWave then
                self:beginNextWave()
            end
        end)
    end
end

function Service:Start()
    Players.PlayerAdded:Connect(function()
        if not self.running then
            self.running = true
            task.delay(2, function()
                if self.wave == 0 and #Players:GetPlayers() > 0 then
                    self:beginNextWave()
                end
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function()
        if #Players:GetPlayers() <= 1 then
            self.enemies:ClearAll()
            self.active = 0
            self.elitePresent = false
            self.phase = "Waiting"
            self:Broadcast()
        end
    end)

    if #Players:GetPlayers() > 0 then
        self.running = true
        task.delay(2, function()
            if self.wave == 0 and #Players:GetPlayers() > 0 then
                self:beginNextWave()
            end
        end)
    end

    self:Broadcast()
end

return Service