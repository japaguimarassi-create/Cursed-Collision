--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Definitions = require(ReplicatedStorage.Shared.Definitions)
local BossDefinitions = require(ReplicatedStorage.Shared.BossDefinitions)
local BossRules = require(ReplicatedStorage.Shared.BossRules)
local EventDefinitions = require(ReplicatedStorage.Shared.WaveEventDefinitions)
local EventRules = require(ReplicatedStorage.Shared.WaveEventRules)

local WaveService = {}
WaveService.__index = WaveService

function WaveService.new(runtimeState, worldService, enemyService, economyService)
    return setmetatable({
        runtimeState = runtimeState,
        worldService = worldService,
        enemyService = enemyService,
        economyService = economyService,
        running = false,
        wave = 0,
        forceAdvance = false,
        skipNextReward = false,
        defeatConnection = nil,
    }, WaveService)
end

function WaveService:Start()
    if self.running then
        return
    end

    self.running = true

    self.defeatConnection = self.enemyService:GetDefeatedEvent():Connect(function()
        self.runtimeState:SetMany({
            enemiesAlive = self.enemyService:GetActiveCount(),
            eliteAlive = self.enemyService:IsEliteAlive(),
        })
    end)

    task.spawn(function()
        task.wait(2)
        self:RunLoop()
    end)
end

function WaveService:RunLoop()
    while self.running do
        self.wave += 1
        local profile = Definitions.BuildWave(self.wave, Constants.MaxActiveEnemies)
        local boss = BossRules.getForWave(self.wave, BossDefinitions)
        local eventId = EventRules.pick(self.wave, boss ~= nil)

        self.enemyService:SetWaveTheme(profile.ThemeId)
        self.enemyService:SetWaveBoss(boss)
        self.enemyService:SetWaveEvent(eventId)

        self.runtimeState:SetMany({
            phase = "Wave",
            wave = self.wave,
            enemiesAlive = 0,
            eliteAlive = true,
            bossId = boss and boss.Id or nil,
            eventId = eventId,
            intermissionEndsAt = 0,
        })

        self:SpawnWave(profile)

        while self.running and self.enemyService:GetActiveCount() > 0 and not self.forceAdvance do
            task.wait(0.25)
            self.runtimeState:SetMany({
                enemiesAlive = self.enemyService:GetActiveCount(),
                eliteAlive = self.enemyService:IsEliteAlive(),
            })
        end

        if not self.running then
            break
        end

        local forced = self.forceAdvance
        self.forceAdvance = false

        if forced then
            self.skipNextReward = true
            self.enemyService:ClearAll()
        end

        if not self.skipNextReward then
            local rewardMultiplier = 1
            if self.enemyService.waveEvent then
                rewardMultiplier *= math.max(1, self.enemyService.waveEvent.RewardMultiplier or 1)
            end
            if self.enemyService.waveBoss then
                rewardMultiplier *= math.max(1, self.enemyService.waveBoss.RewardMultiplier or 1)
            end

            self.economyService:RewardWaveClear(
                rewardMultiplier
            )
        else
            self.skipNextReward = false
        end

        local endAt = self.forceAdvance
            and os.clock()
            or os.clock() + Constants.WaveIntermission
        self.runtimeState:SetMany({
            phase = "Intermission",
            enemiesAlive = 0,
            eliteAlive = false,
            bossId = nil,
            eventId = nil,
            intermissionEndsAt = endAt,
        })

        while self.running and not self.forceAdvance and os.clock() < endAt do
            task.wait(0.25)
        end

        self.forceAdvance = false
    end
end

function WaveService:SpawnWave(profile)
    local points = self.worldService:GetEnemySpawnPoints()
    if #points == 0 then
        warn("No enemy spawn points available")
        return
    end

    local totalIndex = 0

    local function spawnType(enemyId: string, amount: number)
        for _ = 1, amount do
            if totalIndex >= Constants.MaxActiveEnemies then
                return
            end

            totalIndex += 1
            local point = points[((totalIndex - 1) % #points) + 1]
            local offset = Vector3.new(
                math.random(-3, 3),
                0,
                math.random(-3, 3)
            )

            self.enemyService:Spawn(
                enemyId,
                profile.Number,
                point.CFrame + offset
            )
        end
    end

    spawnType("Grunt", profile.Grunt)
    spawnType("Brute", profile.Brute)
    spawnType("Stalker", profile.Stalker)
    spawnType("Elite", 1)

    self.runtimeState:SetMany({
        enemiesAlive = self.enemyService:GetActiveCount(),
        eliteAlive = self.enemyService:IsEliteAlive(),
    })
end

function WaveService:RequestNextWave()
    if not self.running then
        return false
    end

    self.forceAdvance = true

    if self.runtimeState.phase == "Intermission" then
        self.runtimeState:Set("intermissionEndsAt", 0)
    else
        self.enemyService:ClearAll()
    end

    return true
end

function WaveService:Stop()
    self.running = false
    if self.defeatConnection then
        self.defeatConnection:Disconnect()
        self.defeatConnection = nil
    end
end

return WaveService
