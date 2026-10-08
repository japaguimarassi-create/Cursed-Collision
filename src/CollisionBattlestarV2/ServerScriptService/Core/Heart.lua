--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local Heart = {}
Heart.__index = Heart

function Heart.new(runtimeState)
    return setmetatable({
        state = runtimeState,
        services = {},
        order = {},
        running = false,
        recovering = false,
        generation = 0,
        lastRecoveryAt = -math.huge,
        recoveryCount = 0,
        lastError = nil,
        heartbeat = nil,
        accumulator = 0,
    }, Heart)
end

function Heart:Register(name: string, service: any)
    self.services[name] = service
    table.insert(self.order, name)
    return service
end

function Heart:Get(name: string)
    return self.services[name]
end

function Heart:Report(label: string, err: any)
    if self.recovering then
        return false
    end
    self.lastError = ("%s: %s"):format(label, tostring(err))
    return self:Reload(self.lastError)
end

function Heart:Start()
    if self.running then
        return true
    end

    self.running = true

    for _, name in ipairs(self.order) do
        local service = self.services[name]
        if service and type(service.Start) == "function" then
            local ok, err = pcall(function()
                service:Start()
            end)
            if not ok then
                self.running = false
                if self.recovering then
                    return false
                end
                return self:Reload(("start.%s"):format(name), err)
            end
        end
    end

    self.heartbeat = RunService.Heartbeat:Connect(function(dt)
        self.accumulator += dt
        if self.accumulator < Constants.RuntimeHealthInterval then
            return
        end
        self.accumulator = 0

        if not self.running or self.recovering then
            return
        end

        local world = self.services.World
        local enemies = self.services.Enemies
        local waves = self.services.Waves

        if world and workspace:GetAttribute("CBS2_WorldReady") == true then
            local root = workspace:FindFirstChild("CBS2_World")
            if not root then
                self:Report("watchdog.world", "world missing")
                return
            end
        end

        if enemies and type(enemies.HealthCheck) == "function" and not enemies:HealthCheck() then
            self:Report("watchdog.enemies", "enemy service unhealthy")
            return
        end

        if waves and type(waves.HealthCheck) == "function" and not waves:HealthCheck() then
            self:Report("watchdog.waves", "wave service unhealthy")
            return
        end
    end)

    self.state:SetMany({
        phase = "Intermission",
        error = nil,
    })

    workspace:SetAttribute("CBS2_RuntimeGeneration", self.generation)
    workspace:SetAttribute("CBS2_RuntimeRecovering", false)
    return true
end

function Heart:Reload(reason: string, _)
    local now = os.clock()
    if self.recovering then
        return false
    end
    if self.recoveryCount >= Constants.RuntimeRecoveryLimit then
        return false
    end

    if now - self.lastRecoveryAt < Constants.RuntimeRecoveryCooldown then
        return false
    end

    self.recovering = true
    self.lastRecoveryAt = now
    self.recoveryCount += 1
    self.generation += 1

    local resumeWave = math.max(1, (self.state.lastCompletedWave or 0) + 1)
    if self.state.phase == "Wave" then
        resumeWave = math.max(1, self.state.wave or 1)
    end

    workspace:SetAttribute("CBS2_RuntimeGeneration", self.generation)
    workspace:SetAttribute("CBS2_RuntimeRecovering", true)
    workspace:SetAttribute("CBS2_RuntimeError", tostring(reason))

    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("CBS2_Remotes")
    local stateRemote = remotes and remotes:FindFirstChild("State")
    if stateRemote and stateRemote:IsA("RemoteEvent") then
        stateRemote:FireAllClients("RuntimeReloading", {
            wave = resumeWave,
            generation = self.generation,
            error = tostring(reason),
        })
    end

    local reverse = {}
    for index = #self.order, 1, -1 do
        table.insert(reverse, self.order[index])
    end

    for _, name in ipairs(reverse) do
        local service = self.services[name]
        if service and type(service.Stop) == "function" then
            pcall(function()
                service:Stop()
            end)
        end
    end

    local world = self.services.World
    local enemies = self.services.Enemies
    local pvp = self.services.PvP
    local echo = self.services.Echo
    local players = self.services.Players
    local waves = self.services.Waves

    if waves and type(waves.Resume) == "function" then
        pcall(function()
            waves:Resume(resumeWave)
        end)
    end

    if enemies and type(enemies.Clear) == "function" then
        pcall(function()
            enemies:Clear()
        end)
    end
    if pvp and type(pvp:Reset) == "function" then
        pcall(function()
            pvp:Reset()
        end)
    end
    if echo and type(echo.ResetRuntime) == "function" then
        pcall(function()
            echo:ResetRuntime()
        end)
    end
    if world and type(world.Reload) == "function" then
        pcall(function()
            world:Reload()
        end)
    end
    if players and type(players:RecoverAll) == "function" then
        pcall(function()
            players:RecoverAll(world)
        end)
    end

    self.state:SetMany({
        phase = "Intermission",
        wave = math.max(0, resumeWave - 1),
        enemiesAlive = 0,
        boss = false,
        event = nil,
        error = nil,
        generation = self.generation,
        intermissionEndsAt = os.clock() + 1,
    })

    self.running = false
    self.recovering = false

    local ok = false
    if waves and type(waves.Resume) == "function" then
        pcall(function()
            waves:Resume(resumeWave)
        end)
    end

    ok = self:Start()
    workspace:SetAttribute("CBS2_RuntimeRecovering", false)
    workspace:SetAttribute("CBS2_RuntimeError", ok and nil or tostring(reason))

    if stateRemote and stateRemote:IsA("RemoteEvent") then
        stateRemote:FireAllClients(ok and "RuntimeRestored" or "RuntimeFailed", {
            wave = resumeWave,
            generation = self.generation,
        })
    end

    return ok
end

function Heart:Stop()
    self.running = false
    if self.heartbeat then
        self.heartbeat:Disconnect()
        self.heartbeat = nil
    end
end

return Heart
