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
    if type(name) ~= "string" or name == "" or not service then
        return false
    end

    self.services[name] = service
    table.insert(self.order, name)
    return true
end

function Heart:Get(name: string)
    return self.services[name]
end

function Heart:DisconnectWatchdog()
    if self.heartbeat then
        self.heartbeat:Disconnect()
        self.heartbeat = nil
    end
    self.accumulator = 0
end

function Heart:StopStartedServices(started)
    for index = #started, 1, -1 do
        local name = started[index]
        local service = self.services[name]

        if service and type(service.Stop) == "function" then
            pcall(function()
                service:Stop()
            end)
        end
    end
end

function Heart:Start()
    if self.running then
        return true
    end

    self.running = true

    local started = {}

    for _, name in ipairs(self.order) do
        local service = self.services[name]

        if service and type(service.Start) == "function" then
            local ok, err = pcall(function()
                service:Start()
            end)

            if not ok then
                self.running = false
                self:StopStartedServices(started)

                if self.recovering then
                    self.lastError = ("start.%s: %s"):format(name, tostring(err))
                    return false
                end

                return self:Reload(("start.%s: %s"):format(name, tostring(err)))
            end

            started[#started + 1] = name
        end
    end

    self:DisconnectWatchdog()

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
        if world and workspace:GetAttribute("CBS2_WorldReady") == true
            and not workspace:FindFirstChild("CBS2_World") then
            self:Report("watchdog.world", "world missing")
            return
        end

        local enemies = self.services.Enemies
        if enemies and type(enemies.HealthCheck) == "function" then
            local ok, healthy = pcall(function()
                return enemies:HealthCheck()
            end)

            if not ok or healthy ~= true then
                self:Report(
                    "watchdog.enemies",
                    ok and "enemy service unhealthy" or healthy
                )
                return
            end
        end

        local waves = self.services.Waves
        if waves and type(waves.HealthCheck) == "function" then
            local ok, healthy = pcall(function()
                return waves:HealthCheck()
            end)

            if not ok or healthy ~= true then
                self:Report(
                    "watchdog.waves",
                    ok and "wave service unhealthy" or healthy
                )
            end
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

function Heart:Report(label: string, err: any)
    if self.recovering then
        return false
    end

    self.lastError = ("%s: %s"):format(label, tostring(err))
    return self:Reload(self.lastError)
end

function Heart:Reload(reason: string)
    local now = os.clock()

    if self.recovering then
        return false
    end

    if self.recoveryCount >= Constants.RuntimeRecoveryLimit then
        self.lastError = "runtime recovery limit reached"
        return false
    end

    if now - self.lastRecoveryAt < Constants.RuntimeRecoveryCooldown then
        return false
    end

    self.recovering = true
    self.lastRecoveryAt = now
    self.recoveryCount += 1
    self.generation += 1
    self.lastError = tostring(reason)

    local resumeWave = math.max(1, (self.state.lastCompletedWave or 0) + 1)

    if self.state.phase == "Wave" then
        resumeWave = math.max(1, self.state.wave or 1)
    end

    workspace:SetAttribute("CBS2_RuntimeGeneration", self.generation)
    workspace:SetAttribute("CBS2_RuntimeRecovering", true)
    workspace:SetAttribute("CBS2_RuntimeError", tostring(reason))

    local remotes = ReplicatedStorage:FindFirstChild("CBS2_Remotes")
    local stateRemote = remotes and remotes:FindFirstChild("State")

    if stateRemote and stateRemote:IsA("RemoteEvent") then
        stateRemote:FireAllClients("RuntimeReloading", {
            wave = resumeWave,
            generation = self.generation,
            error = tostring(reason),
        })
    end

    self.running = false
    self:DisconnectWatchdog()

    self:StopStartedServices(self.order)

    local world = self.services.World
    local enemies = self.services.Enemies
    local pvp = self.services.PvP
    local echo = self.services.Echo
    local players = self.services.Players
    local waves = self.services.Waves

    if enemies and type(enemies.Clear) == "function" then
        pcall(function()
            enemies:Clear()
        end)
    end

    if pvp and type(pvp.Reset) == "function" then
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
        local worldOk = pcall(function()
            world:Reload()
        end)

        if not worldOk then
            self.recovering = false
            workspace:SetAttribute("CBS2_RuntimeRecovering", false)
            workspace:SetAttribute("CBS2_RuntimeError", "world recovery failed")
            return false
        end
    end

    if players and type(players.RecoverAll) == "function" then
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

    if waves and type(waves.Resume) == "function" then
        pcall(function()
            waves:Resume(resumeWave)
        end)
    end

    local ok = self:Start()

    self.recovering = false
    workspace:SetAttribute("CBS2_RuntimeRecovering", false)

    if ok then
        workspace:SetAttribute("CBS2_RuntimeError", nil)
    else
        workspace:SetAttribute("CBS2_RuntimeError", tostring(self.lastError or reason))
    end

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
    self:DisconnectWatchdog()
end

return Heart
