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

function WaveService.new(runtimeState, worldService, enemyService, economyService, mechanicsKernel)
    return setmetatable({
        runtimeState = runtimeState,
        worldService = worldService,
        enemyService = enemyService,
        economyService = economyService,
        mechanicsKernel = mechanicsKernel,
        running = false,
        wave = 0,
        forceAdvance = false,
        defeatConnection = nil,
        generation = 0,
    }, WaveService)
end

function WaveService:Start()
    if self.running then
        return
    end

    self.running = true
    self.generation += 1

    local generation = self.generation

    self.defeatConnection = self.enemyService:GetDefeatedEvent():Connect(function()
        self.runtimeState:SetMany({
            enemiesAlive = self.enemyService:GetActiveCount(),
            eliteAlive = self.enemyService:IsEliteAlive(),
        })
    end)

    task.spawn(function()
        task.wait(2)

        if self.running and self.generation == generation then
            self:RunLoop(generation)
        end
    end)
end

function WaveService:RunLoop(generation: number)
    while self.running and self.generation == generation do
        local ok, err = pcall(function()
            self:RunOneWave(generation)
        end)

        if not ok then
            self.running = false
            self.generation += 1

            if self.mechanicsKernel then
                self.mechanicsKernel:ReportFailure("waves.loop", err)
            end

            return
        end
    end
end

function WaveService:RunOneWave(generation: number)
    self.wave += 1

    local profile = Definitions.BuildWave(
        self.wave,
        Constants.MaxActiveEnemies
    )

    local boss = BossRules.getForWave(
        self.wave,
        BossDefinitions
    )

    local eventId = EventRules.pick(
        self.wave,
        boss ~= nil
    )

    self.enemyService:SetWaveTheme(profile.ThemeId)
    self.enemyService:SetWaveBoss(boss)
    self.enemyService:SetWaveEvent(eventId)
    self.enemyService:SetWave(self.wave)

    self.runtimeState:SetMany({
        phase = "Wave",
        wave = self.wave,
        enemiesAlive = 0,
        eliteAlive = false,
        bossId = boss and boss.Id or nil,
        eventId = eventId,
        intermissionEndsAt = 0,
    })

    self:SpawnWave(profile)

    while self.running and self.generation == generation do
        local alive = self.enemyService:GetActiveCount()

        self.runtimeState:SetMany({
            enemiesAlive = alive,
            eliteAlive = self.enemyService:IsEliteAlive(),
        })

        if alive <= 0 or self.forceAdvance then
            break
        end

        task.wait(0.25)
    end

    if not self.running or self.generation ~= generation then
        return
    end

    local forced = self.forceAdvance
    self.forceAdvance = false

    if forced then
        self.enemyService:ClearAll()
    else
        local rewardMultiplier = 1

        if self.enemyService.waveEvent then
            rewardMultiplier *= math.max(
                1,
                self.enemyService.waveEvent.RewardMultiplier or 1
            )
        end

        if self.enemyService.waveBoss then
            rewardMultiplier *= math.max(
                1,
                self.enemyService.waveBoss.RewardMultiplier or 1
            )
        end

        self.economyService:RewardWaveClear(rewardMultiplier)
        self.runtimeState:Set("lastCompletedWave", self.wave)
    end

    local endAt = os.clock() + Constants.WaveIntermission

    self.runtimeState:SetMany({
        phase = "Intermission",
        enemiesAlive = 0,
        eliteAlive = false,
        bossId = nil,
        eventId = nil,
        lastCompletedWave = self.runtimeState.lastCompletedWave,
        intermissionEndsAt = endAt,
    })

    while self.running and self.generation == generation and os.clock() < endAt do
        if self.forceAdvance then
            self.forceAdvance = false
            break
        end

        self.runtimeState:Set("intermissionEndsAt", endAt)
        task.wait(0.2)
    end
end

function WaveService:SpawnWave(profile)
    local points = self.worldService:GetEnemySpawnPoints()

    if #points == 0 then
        error("no enemy spawn points available")
    end

    local totalIndex = 0

    local function spawnType(enemyId: string, amount: number)
        for _ = 1, amount do
            if totalIndex >= Constants.MaxActiveEnemies then
                return
            end

            totalIndex += 1

            local point = points[
                ((totalIndex - 1) % #points) + 1
            ]

            local offset = Vector3.new(
                math.random(-3, 3),
                0,
                math.random(-3, 3)
            )

            local model = self.enemyService:Spawn(
                enemyId,
                profile.Number,
                point.CFrame + offset
            )

            if not model then
                error("enemy spawn failed: " .. enemyId)
            end
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

    if self.runtimeState.phase ~= "Intermission" then
        self.enemyService:ClearAll()
    else
        self.runtimeState:Set(
            "intermissionEndsAt",
            os.clock()
        )
    end

    return true
end

function WaveService:Reload(resumeWave: number?)
    self:Stop()

    local nextWave = math.max(1, math.floor(tonumber(resumeWave) or 1))
    self.wave = nextWave - 1
    self.forceAdvance = false

    self.runtimeState:SetMany({
        phase = "Intermission",
        wave = self.wave,
        enemiesAlive = 0,
        eliteAlive = false,
        bossId = nil,
        eventId = nil,
        intermissionEndsAt = os.clock() + 1,
    })

    self:Start()
end

function WaveService:HealthCheck()
    return self.running and self.generation > 0
end

function WaveService:Stop()
    self.running = false
    self.generation += 1
    self.forceAdvance = false

    if self.defeatConnection then
        self.defeatConnection:Disconnect()
        self.defeatConnection = nil
    end
end

return WaveService
