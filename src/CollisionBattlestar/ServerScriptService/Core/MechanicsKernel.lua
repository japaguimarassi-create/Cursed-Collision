--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local MechanicsKernel = {}
MechanicsKernel.__index = MechanicsKernel

local HEARTBEAT_INTERVAL = Config.Runtime.HealthCheckInterval
local RECOVERY_COOLDOWN = Config.Runtime.RecoveryCooldown
local MAX_RECOVERY_FAILURES = Config.Runtime.MaxRecoveryFailures

function MechanicsKernel.new(runtimeState, remotes)
    return setmetatable({
        runtimeState = runtimeState,
        remotes = remotes,
        services = {} :: {[string]: any},
        running = false,
        recovering = false,
        generation = 0,
        errorCount = 0,
        recoveryFailures = 0,
        lastRecoveryAt = -math.huge,
        lastError = nil,
        heartbeatConnection = nil,
        accumulator = 0,
    }, MechanicsKernel)
end

function MechanicsKernel:Register(name: string, service: any)
    if type(name) ~= "string" or name == "" or service == nil then
        return false
    end

    self.services[name] = service
    return true
end

function MechanicsKernel:Get(name: string)
    return self.services[name]
end

function MechanicsKernel:CaptureSnapshot()
    local snapshot = self.runtimeState:Snapshot()

    return {
        runtime = snapshot,
        generation = self.generation,
        capturedAt = os.clock(),
    }
end

function MechanicsKernel:Publish(kind: string, payload: any)
    local ok = pcall(function()
        self.remotes.State:FireAllClients(kind, payload)
    end)

    return ok
end

function MechanicsKernel:Call(label: string, callback)
    local ok, result = pcall(callback)

    if ok then
        return true, result
    end

    self:ReportFailure(label, result)
    return false, result
end

function MechanicsKernel:ReportFailure(label: string, err: any)
    self.errorCount += 1
    self.lastError = ("%s: %s"):format(tostring(label), tostring(err))

    if self.recovering then
        return false
    end

    return self:ReloadAll(self.lastError)
end

function MechanicsKernel:SafeMethod(serviceName: string, methodName: string, ...)
    local service = self.services[serviceName]
    if not service then
        return true
    end

    local method = service[methodName]
    if type(method) ~= "function" then
        return true
    end

    local args = table.pack(...)
    local ok, result = pcall(function()
        return method(service, table.unpack(args, 1, args.n))
    end)

    if not ok then
        self.lastError = ("%s.%s: %s"):format(serviceName, methodName, tostring(result))
    end

    return ok, result
end

function MechanicsKernel:GetResumeWave(snapshot)
    local runtime = snapshot.runtime
    local phase = tostring(runtime.phase or "")

    if phase == "Intermission" then
        return math.max(1, (tonumber(runtime.lastCompletedWave) or 0) + 1)
    end

    return math.max(1, tonumber(runtime.wave) or 1)
end

function MechanicsKernel:ReloadAll(reason: string)
    local now = os.clock()

    if self.recovering then
        return false
    end

    if now - self.lastRecoveryAt < RECOVERY_COOLDOWN then
        return false
    end

    self.recovering = true
    self.lastRecoveryAt = now
    self.generation += 1

    local snapshot = self:CaptureSnapshot()
    local resumeWave = self:GetResumeWave(snapshot)

    workspace:SetAttribute("CBS_RuntimeGeneration", self.generation)
    workspace:SetAttribute("CBS_RuntimeRecovering", true)
    workspace:SetAttribute("CBS_RuntimeLastError", tostring(reason))

    self:Publish("RuntimeReloadStarted", {
        generation = self.generation,
        wave = resumeWave,
        reason = tostring(reason),
    })

    local failed = 0

    local function safe(serviceName: string, methodName: string, ...)
        local ok = self:SafeMethod(serviceName, methodName, ...)
        if not ok then
            failed += 1
        end
        return ok
    end

    safe("Waves", "Stop")
    safe("Companions", "ReloadRuntime", "mechanics_reload")
    safe("PvP", "ResetRuntime")
    safe("Enemies", "ClearAll")
    safe("World", "Start")
    safe("PlayerState", "RecoverCharacters", self:Get("World"))

    self.runtimeState:SetMany({
        worldReady = true,
        phase = "Intermission",
        wave = math.max(0, resumeWave - 1),
        enemiesAlive = 0,
        eliteAlive = false,
        bossId = nil,
        eventId = nil,
        intermissionEndsAt = os.clock() + 1,
    })

    safe("Waves", "Reload", resumeWave)

    self.recoveryFailures = failed
    self.recovering = false

    workspace:SetAttribute("CBS_RuntimeRecovering", false)

    if failed >= MAX_RECOVERY_FAILURES then
        workspace:SetAttribute("CBS_ServerBootError", "runtime recovery failed")
        self:Publish("BootError", {
            stage = "runtime recovery",
            message = "runtime recovery failed",
            generation = self.generation,
        })
        return false
    end

    workspace:SetAttribute("CBS_ServerBootError", nil)
    workspace:SetAttribute("CBS_RuntimeLastError", nil)

    self:Publish("RuntimeReloaded", {
        generation = self.generation,
        wave = resumeWave,
        recoveredAt = os.clock(),
        errorCount = self.errorCount,
    })

    return true
end

function MechanicsKernel:HealthCheck()
    if self.recovering then
        return true
    end

    local world = workspace:FindFirstChild("CollisionBattlestarWorld")
    if workspace:GetAttribute("CBS_WorldReady") == true and not world then
        self:ReportFailure("health.world", "world missing")
        return false
    end

    local enemies = self.services.Enemies
    if enemies and type(enemies.HealthCheck) == "function" then
        local ok, healthy = pcall(function()
            return enemies:HealthCheck()
        end)

        if not ok or healthy == false then
            self:ReportFailure("health.enemies", ok and "enemy health check failed" or healthy)
            return false
        end
    end

    local waves = self.services.Waves
    if waves and type(waves.HealthCheck) == "function" then
        local ok, healthy = pcall(function()
            return waves:HealthCheck()
        end)

        if not ok or healthy == false then
            self:ReportFailure("health.waves", ok and "wave health check failed" or healthy)
            return false
        end
    end

    return true
end

function MechanicsKernel:Startt()
    if self.running then
        return
    end

    self.running = true
    workspace:SetAttribute("CBS_RuntimeGeneration", self.generation)
    workspace:SetAttribute("CBS_RuntimeRecovering", false)

    self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self.accumulator += deltaTime
        if self.accumulator < HEARTBEAT_INTERVAL then
            return
        end

        self.accumulator = 0

        if self.running then
            local ok, err = pcall(function()
                self:HealthCheck()
            end)

            if not ok then
                self:ReportFailure("health.loop", err)
            end
        end
    end)
end

function MechanicsKernel:Stop()
    self.running = false

    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
        self.heartbeatConnection = nil
    end
end

return MechanicsKernel
