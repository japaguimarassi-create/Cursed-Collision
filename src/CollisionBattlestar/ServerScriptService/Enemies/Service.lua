--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Shared.Definitions)
local EnemySkinDefinitions = require(ReplicatedStorage.Shared.EnemySkinDefinitions)
local EnemySkinRules = require(ReplicatedStorage.Shared.EnemySkinRules)
local BossDefinitions = require(ReplicatedStorage.Shared.BossDefinitions)
local BossRules = require(ReplicatedStorage.Shared.BossRules)
local WaveEventDefinitions = require(ReplicatedStorage.Shared.WaveEventDefinitions)
local Constants = require(ReplicatedStorage.Shared.Constants)
local EnemyFactory = require(script.Parent.EnemyFactory)
local EnemyBrain = require(script.Parent.EnemyBrain)

local EnemyService = {}
EnemyService.__index = EnemyService

function EnemyService.new(runtimeState, worldService, economyService)
    return setmetatable({
        runtimeState = runtimeState,
        worldService = worldService,
        economyService = economyService,
        active = {} :: {[Model]: any},
        defeated = Instance.new("BindableEvent"),
        waveThemeId = "Urban",
        previousSkinByTier = {},
        skinSeed = 0,
        waveBoss = nil,
        waveEvent = nil,
    }, EnemyService)
end

function EnemyService:Start()
end

function EnemyService:GetDefeatedEvent()
    return self.defeated.Event
end

function EnemyService:GetActiveCount()
    local count = 0
    for model in pairs(self.active) do
        if model.Parent then
            count += 1
        end
    end
    return count
end

function EnemyService:GetTargetCandidates(origin: Vector3, radius: number)
    local result = {}
    local maxDistance = math.max(0, tonumber(radius) or 0)
    local maxDistanceSquared = maxDistance * maxDistance

    for model, record in pairs(self.active) do
        if model.Parent and record.humanoid.Health > 0 then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local offset = root.Position - origin
                if offset:Dot(offset) <= maxDistanceSquared then
                    table.insert(result, model)
                end
            end
        end
    end

    return result
end

function EnemyService:IsEliteAlive()
    for model, record in pairs(self.active) do
        if model.Parent and record.definition.IsElite and record.humanoid.Health > 0 then
            return true
        end
    end
    return false
end

function EnemyService:CanTargetPlayer(player: Player, root: BasePart)
    return player:GetAttribute("CBS_PvP") ~= true
        and self.worldService:IsInsideArena(root.Position)
end

function EnemyService:DamagePlayer(player: Player, amount: number, source: Model)
    if not player.Parent or amount <= 0 then
        return false
    end

    if player:GetAttribute("CBS_PvP") == true then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 or not root:IsA("BasePart") then
        return false
    end

    humanoid:TakeDamage(amount)

    local sourceRoot = source.PrimaryPart
    if sourceRoot then
        local direction = root.Position - sourceRoot.Position
        if direction.Magnitude > 0.01 then
            root.AssemblyLinearVelocity = direction.Unit * 18 + Vector3.new(0, 6, 0)
        end
    end

    return true
end

function EnemyService:SetWaveTheme(themeId: string)
    if EnemySkinDefinitions.Themes[themeId] then
        self.waveThemeId = themeId
    else
        self.waveThemeId = "Urban"
    end

    self.previousSkinByTier = {}
end

function EnemyService:SetWaveBoss(boss)
    self.waveBoss = boss
end

function EnemyService:SetWaveEvent(eventId: string?)
    self.waveEvent = eventId and WaveEventDefinitions[eventId] or nil
end

function EnemyService:GetEffectiveDefinition(definition)
    local effective = {
        Id = definition.Id,
        DisplayName = definition.DisplayName,
        Tier = definition.Tier,
        MaxHealth = definition.MaxHealth,
        Damage = definition.Damage,
        Speed = definition.Speed,
        AttackRange = definition.AttackRange,
        AttackCooldown = definition.AttackCooldown,
        Reward = definition.Reward,
        KnockbackResistance = definition.KnockbackResistance,
        IsElite = definition.IsElite,
        IsBoss = false,
    }

    if definition.IsElite and self.waveBoss then
        effective.MaxHealth = BossRules.scale(
            effective.MaxHealth,
            self.waveBoss.HealthMultiplier
        )
        effective.Damage = BossRules.scale(
            effective.Damage,
            self.waveBoss.DamageMultiplier
        )
        effective.Speed = BossRules.scale(
            effective.Speed,
            self.waveBoss.SpeedMultiplier
        )
        effective.Reward = math.floor(
            effective.Reward * math.max(1, self.waveBoss.RewardMultiplier)
        )
        effective.IsBoss = true
    end

    if self.waveEvent then
        effective.Speed = BossRules.scale(
            effective.Speed,
            self.waveEvent.SpeedMultiplier
        )
        effective.Damage = BossRules.scale(
            effective.Damage,
            self.waveEvent.DamageMultiplier
        )
    end

    return effective
end

function EnemyService:Spawn(enemyId: string, wave: number, spawnCFrame: CFrame)
    local baseDefinition = Definitions.Enemies[enemyId]
    if not baseDefinition then
        return nil
    end

    if self:GetActiveCount() >= Constants.MaxActiveEnemies then
        return nil
    end

    local definition = self:GetEffectiveDefinition(baseDefinition)

    self.skinSeed += 1
    local previous = self.previousSkinByTier[definition.Tier]
    local skinProfile = EnemySkinRules.pick(
        self.waveThemeId,
        definition.Tier,
        self.skinSeed,
        previous,
        EnemySkinDefinitions
    )

    if skinProfile then
        self.previousSkinByTier[definition.Tier] = skinProfile.ProfileId
    end

    local model, humanoid, root = EnemyFactory.Create(
        definition,
        spawnCFrame,
        wave,
        skinProfile
    )

    if not model or not humanoid or not root then
        return nil
    end

    model:SetAttribute("CBS_Boss", definition.IsBoss == true)
    model:SetAttribute("CBS_WaveEvent", self.waveEvent and self.waveEvent.Id or nil)

    if definition.IsBoss then
        local bossLabel = Instance.new("BillboardGui")
        bossLabel.Name = "BossLabel"
        bossLabel.Size = UDim2.fromOffset(220, 42)
        bossLabel.StudsOffset = Vector3.new(0, 6, 0)
        bossLabel.AlwaysOnTop = true
        bossLabel.MaxDistance = 120

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Text = self.waveBoss.DisplayName
        text.TextColor3 = Color3.fromRGB(255, 80, 80)
        text.TextStrokeTransparency = 0.35
        text.Font = Enum.Font.GothamBold
        text.TextScaled = true
        text.Parent = bossLabel

        bossLabel.Parent = model:FindFirstChild("Head") or model
    end

    local record = {
        definition = definition,
        humanoid = humanoid,
        brain = nil,
        diedConnection = nil,
    }

    local brain = EnemyBrain.new(
        model,
        humanoid,
        root,
        definition,
        function(player, amount, source)
            self:DamagePlayer(player, amount, source)
        end
    )

    record.brain = brain
    self.active[model] = record

    self.runtimeState:SetMany({
        enemiesAlive = self:GetActiveCount(),
        eliteAlive = self:IsEliteAlive(),
    })

    record.diedConnection = humanoid.Died:Connect(function()
        self:HandleDeath(model)
    end)

    brain:Start()

    return model
end

function EnemyService:HandleDeath(model: Model)
    local record = self.active[model]
    if not record then
        return
    end

    self.active[model] = nil

    if record.brain then
        record.brain:Stop()
    end

    if record.diedConnection then
        record.diedConnection:Disconnect()
    end

    local lastHitUserId = model:GetAttribute("CBS_LastHitUserId")
    if type(lastHitUserId) == "number" then
        local player = Players:GetPlayerByUserId(lastHitUserId)
        if player then
            self.economyService:RewardEnemyDefeat(player, record.definition.Reward)
        end
    end

    local position = model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero

    self.runtimeState:SetMany({
        enemiesAlive = self:GetActiveCount(),
        eliteAlive = self:IsEliteAlive(),
    })

    self.defeated:Fire(
        record.definition.Id,
        record.definition.IsElite,
        position,
        record.definition.IsBoss == true
    )

    task.delay(0.2, function()
        if model.Parent then
            model:Destroy()
        end
    end)
end

function EnemyService:ClearAll()
    local snapshot = {}

    for model, record in pairs(self.active) do
        table.insert(snapshot, {
            model = model,
            record = record,
        })
    end

    for _, entry in ipairs(snapshot) do
        local model = entry.model
        local record = entry.record

        self.active[model] = nil

        if record.brain then
            record.brain:Stop()
        end

        if record.diedConnection then
            record.diedConnection:Disconnect()
        end

        if model.Parent then
            model:Destroy()
        end
    end

    self.runtimeState:SetMany({
        enemiesAlive = 0,
        eliteAlive = false,
    })
end

return EnemyService
