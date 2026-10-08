--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Rules = require(ReplicatedStorage.Shared.Rules)
local Agent = require(script.Parent.Agent)

local AIHeart = {}
AIHeart.__index = AIHeart

function AIHeart.new(onFatal)
    return setmetatable({
        records = {},
        profiles = nil,
        wave = 0,
        running = false,
        generation = 0,
        onFatal = onFatal,
        scheduler = nil,
        targets = {},
        nextTargets = 0,
    }, AIHeart)
end

function AIHeart:SetWave(wave: number)
    self.wave = math.max(0, math.floor(wave))
    self.profiles = Rules.aiProfile(self.wave)
    self.generation += 1

    for model, record in pairs(self.records) do
        if model.Parent then
            record.agent:SetProfile(self.profiles)
            record.agent:SetWave(self.wave)
            record.memory.wave = self.wave
            model:SetAttribute("CBS_AILevel", math.floor(self.profiles.Skill * 100 + 0.5))
        end
    end
end

function AIHeart:RefreshTargets(now: number)
    if now < self.nextTargets then
        return
    end

    table.clear(self.targets)

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if player.Parent
            and player:GetAttribute("CBS_PlayerReady") == true
            and player:GetAttribute("CBS_PvP") ~= true
            and humanoid
            and humanoid.Health > 0
            and root
            and root:IsA("BasePart") then

            self.targets[#self.targets + 1] = {
                player = player,
                humanoid = humanoid,
                root = root,
            }
        end
    end

    self.nextTargets = now + Constants.AITargetRefresh
end

function AIHeart:Register(model: Model, humanoid: Humanoid, root: BasePart, definition, callbacks)
    local count = 0
    for registeredModel in pairs(self.records) do
        if registeredModel.Parent then
            count += 1
        else
            self:Unregister(registeredModel)
        end
    end

    if count >= Constants.MaxNPCs then
        return false
    end

    local profile = self.profiles or Rules.aiProfile(self.wave)

    local memory = {
        wave = self.wave,
        attacks = 0,
        hits = 0,
        misses = 0,
        errors = 0,
        lastTarget = nil,
        confidence = 0.5 + profile.Skill * 0.4,
    }

    local agent = Agent.new(model, humanoid, root, definition, callbacks, memory)
    agent:SetProfile(profile)
    agent:SetWave(self.wave)

    self.records[model] = {
        agent = agent,
        memory = memory,
        nextThink = os.clock() + (count % 4) * 0.02,
    }

    model:SetAttribute("CBS_AI", true)
    model:SetAttribute("CBS_AIWave", self.wave)
    model:SetAttribute("CBS_AILevel", math.floor(profile.Skill * 100 + 0.5))
    return true
end

function AIHeart:Unregister(model: Model)
    local record = self.records[model]
    if not record then
        return
    end
    self.records[model] = nil
    record.agent:Stop()
end

function AIHeart:Clear()
    local list = {}
    for model in pairs(self.records) do
        list[#list + 1] = model
    end
    for _, model in ipairs(list) do
        self:Unregister(model)
    end
    table.clear(self.targets)
end

function AIHeart:Start()
    if self.running then
        return
    end

    self.running = true
    self.scheduler = task.spawn(function()
        while self.running do
            local now = os.clock()
            self:RefreshTargets(now)

            for model, record in pairs(self.records) do
                if not model.Parent then
                    self:Unregister(model)
                elseif now >= record.nextThink then
                    record.nextThink = now + self.profiles.ThinkInterval

                    local ok, err = pcall(function()
                        record.agent:Step(now, self.targets)
                    end)

                    if not ok then
                        record.memory.errors += 1
                        record.agent:Reset()

                        if record.memory.errors >= Constants.AIErrorLimit then
                            local message = ("npc %s ai failure: %s"):format(model.Name, tostring(err))
                            self.running = false
                            if self.onFatal then
                                pcall(self.onFatal, "ai", message)
                            end
                            return
                        end
                    end
                end
            end

            task.wait(Constants.AISchedulerStep)
        end
    end)
end

function AIHeart:HealthCheck()
    local count = 0
    for model, record in pairs(self.records) do
        if not model.Parent or not record.agent:IsAlive() then
            self:Unregister(model)
        else
            count += 1
        end
    end
    return self.running and count <= Constants.MaxNPCs
end

function AIHeart:Stop()
    self.running = false
    local list = {}
    for model in pairs(self.records) do
        list[#list + 1] = model
    end
    for _, model in ipairs(list) do
        self:Unregister(model)
    end
    self.scheduler = nil
end

return AIHeart
