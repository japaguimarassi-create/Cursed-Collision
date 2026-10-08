--!strict

local Constants = require(script.Parent.ReplicatedStorage.Shared.Constants)
local Rules = require(script.Parent.ReplicatedStorage.Shared.Rules)

local Waves = {}
Waves.__index = Waves

function Waves.new(runtimeState, world, enemies, score, remotes, heart)
    return setmetatable({
        state = runtimeState,
        world = world,
        enemies = enemies,
        score = score,
        remotes = remotes,
        heart = heart,
        running = false,
        generation = 0,
        current = 0,
    }, Waves)
end

function Waves:Start()
    if self.running then
        return
    end

    self.running = true
    self.generation += 1
    local generation = self.generation

    task.spawn(function()
        task.wait(1)

        while self.running and self.generation == generation do
            local ok, err = pcall(function()
                self:RunWave()
            end)

            if not ok then
                self.running = false
                if self.heart then
                    self.heart:Report("waves", err)
                end
                return
            end
        end
    end)
end

function Waves:RunWave()
    self.current = math.max(1, self.current + 1)
    local profile = Rules.waveProfile(self.current)

    self.enemies:SetWave(self.current)

    local boss = profile.Boss
    local event = self.current % 5 == 0 and "RiftSurge" or nil

    self.state:SetMany({
        phase = "Wave",
        wave = self.current,
        enemiesAlive = 0,
        boss = boss,
        event = event,
        error = nil,
    })

    self.remotes.FX:FireAllClients("WaveStart", {
        wave = self.current,
        boss = boss,
        event = event,
    })

    local count = profile.Total
    for index = 1, count do
        local id
        if boss and index == count then
            id = "Boss"
        elseif profile.Elite > 0 and index == count then
            id = "Elite"
        elseif self.current >= 4 and index % 4 == 0 then
            id = "Stalker"
        elseif self.current >= 2 and index % 3 == 0 then
            id = "Brute"
        else
            id = "Grunt"
        end

        local model = self.enemies:Spawn(id)
        if not model then
            error("failed to spawn " .. id)
        end
    end

    self.state:Set("enemiesAlive", self.enemies:Count())

    while self.running and self.enemies:Count() > 0 do
        self.state:Set("enemiesAlive", self.enemies:Count())
        task.wait(0.2)
    end

    if not self.running then
        return
    end

    self.score:Wave(self.current, boss)

    self.state:SetMany({
        phase = "Intermission",
        enemiesAlive = 0,
        boss = false,
        lastCompletedWave = self.current,
        intermissionEndsAt = os.clock() + Constants.WaveIntermission,
    })

    while self.running and os.clock() < self.state.intermissionEndsAt do
        task.wait(0.2)
    end
end

function Waves:Restart(wave: number)
    self.current = math.max(0, math.floor(wave) - 1)
    self.running = false
    self.generation += 1
    self:Start()
end

function Waves:HealthCheck()
    return self.running and self.generation > 0
end

function Waves:Stop()
    self.running = false
    self.generation += 1
end

function Waves:Reload()
    self:Stop()
    self:Start()
end

return Waves
