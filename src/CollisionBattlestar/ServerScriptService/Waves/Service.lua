--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Definitions = require(ReplicatedStorage.Shared.Definitions)

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

        self.runtimeState:SetMany({
            phase = "Wave",
            wave = self.wave,
            enemiesAlive = 0,
            eliteAlive = true,
            intermissionEndsAt = 0,
        })

        self:SpawnWave(profile)

        while self.running and self.enemyService:GetActiveCount() > 0 do
            task.wait(0.25)
            self.runtimeState:SetMany({
                enemiesAlive = self.enemyService:GetActiveCount(),
                eliteAlive = self.enemyService:IsEliteAlive(),
            })
        end

        if not self.running then
            break
        end

        self.economyService:RewardWaveClear()

        local endAt = os.clock() + Constants.WaveIntermission
        self.runtimeState:SetMany({
            phase = "Intermission",
            enemiesAlive = 0,
            eliteAlive = false,
            intermissionEndsAt = endAt,
        })

        while self.running and os.clock() < endAt do
            task.wait(0.25)
        end
    end
end

function WaveService:SpawnWave(profile)
    local points = self.worldService:GetEnemySpawnPoints()
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

function WaveService:Stop()
    self.running = false
    if self.defeatConnection then
        self.defeatConnection:Disconnect()
        self.defeatConnection = nil
    end
end

return WaveService
