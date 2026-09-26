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

local fallbackSpawnPositions = {
    Vector3.new(-72, 8, -72),
    Vector3.new(72, 8, -72),
    Vector3.new(-72, 8, 72),
    Vector3.new(72, 8, 72),
}

local function getArenaSpawnPositions(): {Vector3}
    local folder = workspace:FindFirstChild("ArenaEnemySpawns")
    if not folder then
        return fallbackSpawnPositions
    end

    local positions = {}
    for _, instance in ipairs(folder:GetChildren()) do
        if instance:IsA("BasePart") then
            table.insert(positions, instance.Position)
        end
    end

    if #positions == 0 then
        return fallbackSpawnPositions
    end

    return positions
end

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
    local count = math.min(
        Config.Waves.FirstWaveEnemies + (currentWave - 1) * Config.Waves.EnemyGrowth,
        Config.Waves.MaxAliveEnemies
    )
    local tier = tierForWave(currentWave)
    local spawnPositions = getArenaSpawnPositions()

    for index = 1, count do
        local point = spawnPositions[((index - 1) % #spawnPositions) + 1]
        local jitter = Vector3.new(
            spawnRng:NextInteger(-12, 12),
            0,
            spawnRng:NextInteger(-12, 12)
        )
        EnemyService:Spawn(point + jitter, tier, Config.Waves.EliteEveryWave and index == count)
    end

    broadcast("WaveStart", currentWave, count, tier)
end

local function waveReward(currentWave: number): number
    local reward = Config.Waves.CompletionReward + currentWave * 6

    if currentWave >= 20 then
        reward += 120
    elseif currentWave >= 10 then
        reward += 60
    end

    return math.floor(reward)
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
                    local baseReward = waveReward(wave)

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player:GetAttribute("DataReady") == true and player:GetAttribute("Zone") ~= "PvP" then
                            local multiplier = if player:GetAttribute("Pass_ExtraWaveReward") == true then 1.25 else 1
                            local finalReward = math.floor(baseReward * multiplier)
                            DataService:AddCredits(player, finalReward)
                            State:FireClient(player, "WaveReward", finalReward, wave)
                        end
                    end

                    active = false
                    broadcast("WaveClear", wave, baseReward)
                    task.wait(2)
                else
                    task.wait(0.45)
                end
            end
        end
    end)
end

function Service:AdminNextWave()
    if active then
        EnemyService:Clear()
        active = false
    end
    wave += 1
    active = true
    spawnWave(wave)
end

function Service:GetWave(): number
    return wave
end

function Service:IsActive(): boolean
    return active
end

return Service
