--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local Config
local EnemyService
local DataService
local State: RemoteEvent

local wave = 0
local active = false
local spawnRng = Random.new()

local spawnPositions = {
    Vector3.new(-310, 5, -310),
    Vector3.new(310, 5, -310),
    Vector3.new(-310, 5, 310),
    Vector3.new(310, 5, 310),
    Vector3.new(-180, 5, 0),
    Vector3.new(180, 5, 0),
    Vector3.new(0, 5, -180),
    Vector3.new(0, 5, 180),
}

local function broadcast(kind: string, ...)
    State:FireAllClients(kind, ...)
end

local function tierForWave(currentWave: number): number
    if currentWave >= 10 then
        return 3
    elseif currentWave >= 5 then
        return 2
    end
    return 1
end

local function spawnWave(currentWave: number)
    local baseCount = Config.Waves.FirstWaveEnemies + (currentWave - 1) * Config.Waves.EnemyGrowth
    local count = math.min(baseCount, Config.Waves.MaxAliveEnemies)
    local tier = tierForWave(currentWave)

    for index = 1, count do
        local position = spawnPositions[((index - 1) % #spawnPositions) + 1]
        local jitter = Vector3.new(
            spawnRng:NextInteger(-12, 12),
            0,
            spawnRng:NextInteger(-12, 12)
        )

        local elite = Config.Waves.EliteEveryWave and index == count
        EnemyService:Spawn(position + jitter, tier, elite)
    end

    broadcast("WaveStart", currentWave, count, tier)
end

local function calculateWaveBonus(currentWave: number): number
    local reward = Config.Waves.CompletionReward + currentWave * 6
    if currentWave >= 20 then
        reward += 120
    elseif currentWave >= 10 then
        reward += 60
    end

    local bonus = reward
    if Players:GetAttribute("WaveMasterMultiplier") == true then
        bonus *= 1.25
    end

    return math.floor(bonus)
end

function Service:Init(config, enemyService, dataService)
    Config = config
    EnemyService = enemyService
    DataService = dataService

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    task.spawn(function()
        task.wait(3)

        while true do
            if #Players:GetPlayers() == 0 then
                active = false
                EnemyService:Clear()
                wave = 0
                task.wait(2)
                continue
            end

            active = false
            for remaining = Config.Waves.Intermission, 1, -1 do
                broadcast("WaveIntermission", remaining)
                task.wait(1)
            end

            wave += 1
            active = true
            spawnWave(wave)

            while active do
                local alive = EnemyService:Count()
                broadcast("WaveState", wave, alive)

                if alive <= 0 then
                    local reward = calculateWaveBonus(wave)

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player:GetAttribute("DataReady") == true then
                            local multiplier = if player:GetAttribute("Pass_WaveMaster") == true then 1.25 else 1
                            local finalReward = math.floor(reward * multiplier)
                            DataService:AddCredits(player, finalReward)
                            State:FireClient(player, "WaveReward", finalReward, wave)
                        end
                    end

                    active = false
                    broadcast("WaveClear", wave, reward)
                    task.wait(2)
                else
                    task.wait(0.45)
                end
            end
        end
    end)
end

function Service:GetWave(): number
    return wave
end

function Service:IsActive(): boolean
    return active
end

return Service
