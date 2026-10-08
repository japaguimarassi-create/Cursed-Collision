--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local AIKernel = {}
AIKernel.__index = AIKernel

local AIConfig = Config.AI

function AIKernel.new(onFatal)
    return setmetatable({
        onFatal = onFatal,
        records = {} :: {[Model]: any},
        running = false,
        wave = 0,
        skill = 0.25,
        profile = nil,
        targetCache = {},
        nextTargetRefreshAt = 0,
        fatalPending = nil,
        generation = 0,
        loopToken = 0,
        schedulerConnection = nil,
    }, AIKernel)
end

function AIKernel:BuildProfile(wave: number)
    local clampedWave = math.max(0, math.floor(tonumber(wave) or 0))
    local skill = math.clamp(
        AIConfig.BaseSkill + clampedWave * AIConfig.SkillPerWave,
        AIConfig.BaseSkill,
        AIConfig.MaxSkill
    )

    return {
        Wave = clampedWave,
        Skill = skill,
        ReactionInterval = math.max(
            AIConfig.MinThinkInterval,
            AIConfig.BaseThinkInterval - math.min(
                AIConfig.BaseThinkInterval - AIConfig.MinThinkInterval,
                clampedWave * AIConfig.ThinkImprovementPerWave
            )
        ),
        TargetRefreshInterval = AIConfig.TargetRefreshInterval,
        PredictionTime = AIConfig.BasePredictionTime + math.min(
            AIConfig.MaxPredictionTime - AIConfig.BasePredictionTime,
            clampedWave * AIConfig.PredictionPerWave
        ),
        TargetStickiness = 0.08 + math.min(0.28, clampedWave * 0.012),
        AttackConfidence = 0.45 + skill * 0.45,
    }
end

function AIKernel:SetWave(wave: number)
    self.wave = math.max(0, math.floor(tonumber(wave) or 0))
    self.profile = self:BuildProfile(self.wave)
    self.generation += 1

    for model, record in pairs(self.records) do
        if model.Parent then
            record.memory.wave = self.wave
            record.memory.skill = self.profile.Skill
            record.memory.generation = self.generation
            model:SetAttribute("CBS_AIWave", self.wave)
            model:SetAttribute("CBS_AILevel", math.floor(self.profile.Skill * 100 + 0.5))

            if record.brain and type(record.brain.SetWaveProfile) == "function" then
                record.brain:SetWaveProfile(self.profile)
            end
        end
    end
end

function AIKernel:RefreshTargets(now: number)
    if now < self.nextTargetRefreshAt then
        return
    end

    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Parent and player:GetAttribute("CBS_PvP") ~= true then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if humanoid
                and root
                and root:IsA("BasePart")
                and humanoid.Health > 0 then

                targets[#targets + 1] = {
                    player = player,
                    humanoid = humanoid,
                    root = root,
                }
            end
        end
    end

    self.targetCache = targets
    self.nextTargetRefreshAt = now + TARGET_REFRESH_INTERVAL
end

function AIKernel:Register(model: Model, brain, definition, wave: number)
    if not model or not brain then
        return false
    end

    local count = 0
    for registeredModel in pairs(self.records) do
        if registeredModel.Parent then
            count += 1
        else
            self:Unregister(registeredModel)
        end
    end

    if count >= AIConfig.MaxActiveEnemies then
        return false
    end

    local profile = self.profile or self:BuildProfile(wave or self.wave)

    local memory = {
        wave = self.wave,
        skill = profile.Skill,
        generation = self.generation,
        attacks = 0,
        hits = 0,
        misses = 0,
        errors = 0,
        lastTargetUserId = nil,
        lastTargetAt = -math.huge,
        confidence = profile.AttackConfidence,
    }

    self.records[model] = {
        brain = brain,
        definition = definition,
        memory = memory,
        slot = count + 1,
        nextThinkAt = os.clock() + ((count % 4) * 0.02),
    }

    model:SetAttribute("CBS_AIWave", self.wave)
    model:SetAttribute("CBS_AILevel", math.floor(profile.Skill * 100 + 0.5))

    brain:SetMemory(memory)
    brain:SetWaveProfile(profile)
    brain:Start()

    return true
end

function AIKernel:Unregister(model: Model)
    local record = self.records[model]
    if not record then
        return
    end

    self.records[model] = nil

    if record.brain and type(record.brain.Stop) == "function" then
        record.brain:Stop()
    end
end

function AIKernel:ProcessRecord(model: Model, record, now: number)
    if not model.Parent
        or not record.brain
        or not record.brain:IsAlive() then

        self:Unregister(model)
        return
    end

    if now < record.nextThinkAt then
        return
    end

    record.nextThinkAt = now + (self.profile and self.profile.ReactionInterval or 0.24)

    local ok, result = pcall(function()
        return record.brain:Step(now, self.targetCache, self.profile)
    end)

    if not ok then
        record.memory.errors += 1
        record.brain:Reset()

        if record.memory.errors >= AIConfig.MaxNpcErrors then
            self.fatalPending = "npc ai failure: " .. tostring(model.Name) .. ": " .. tostring(result)
        end
        return
    end

    if result and result.attack then
        record.memory.attacks += 1
        if result.hit then
            record.memory.hits += 1
        else
            record.memory.misses += 1
        end

        local delta = (record.memory.hits - record.memory.misses) * 0.015
        record.memory.confidence = math.clamp(
            (self.profile and self.profile.AttackConfidence or 0.5) + delta,
            0.2,
            0.95
        )
    end

    if result and result.targetUserId then
        record.memory.lastTargetUserId = result.targetUserId
        record.memory.lastTargetAt = now
    end
end

function AIKernel:Start()
    if self.running then
        return
    end

    self.running = true
    self.loopToken += 1
    local token = self.loopToken

    self.schedulerConnection = task.spawn(function()
        while self.running and self.loopToken == token do
            local now = os.clock()
            self:RefreshTargets(now)

            self.fatalPending = nil

            for model, record in pairs(self.records) do
                self:ProcessRecord(model, record, now)
                if self.fatalPending then
                    break
                end
            end

            if self.fatalPending then
                local reason = self.fatalPending
                self.fatalPending = nil

                if type(self.onFatal) == "function" then
                    pcall(self.onFatal, "ai.kernel", reason)
                end
            end

            task.wait(AIConfig.SchedulerInterval)
        end
    end)
end

function AIKernel:Stop()
    self.running = false
    self.loopToken += 1

    for model in pairs(self.records) do
        self:Unregister(model)
    end

    self.schedulerConnection = nil
end

function AIKernel:Reset()
    self.targetCache = {}
    self.nextTargetRefreshAt = 0
    self.fatalPending = nil
    self.generation += 1
end

function AIKernel:HealthCheck()
    local count = 0

    for model, record in pairs(self.records) do
        if not model.Parent or not record.brain then
            return false
        end

        count += 1
    end

    return count <= AIConfig.MaxActiveEnemies
end

function AIKernel:GetSnapshot()
    local count = 0
    for model in pairs(self.records) do
        if model.Parent then
            count += 1
        end
    end

    return {
        wave = self.wave,
        active = count,
        maxActive = AIConfig.MaxActiveEnemies,
        skill = self.profile and self.profile.Skill or self.skill,
        generation = self.generation,
    }
end

return AIKernel
