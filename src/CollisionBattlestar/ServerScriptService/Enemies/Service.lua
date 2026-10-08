--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Shared.Definitions)
local EnemySkinDefinitions = require(ReplicatedStorage.Shared.EnemySkinDefinitions)
local EnemySkinRules = require(ReplicatedStorage.Shared.EnemySkinRules)
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
        serial = 0,
        waveThemeId = "Urban",
        previousSkinByTier = {},
        skinSeed = 0,
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

function EnemyService:IsEliteAlive()
    for model, record in pairs(self.active) do
        if model.Parent and record.definition.IsElite and record.humanoid.Health > 0 then
            return true
        end
    end
    return false
end

function EnemyService:DamagePlayer(player: Player, amount: number, source: Model)
    if not player.Parent or amount <= 0 then
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

function EnemyService:Spawn(enemyId: string, wave: number, spawnCFrame: CFrame)
    local definition = Definitions.Enemies[enemyId]
    if not definition then
        return nil
    end

    if self:GetActiveCount() >= Constants.MaxActiveEnemies then
        return nil
    end

    self.skinSeed += 1
    local selfSeed = self.skinSeed
    local previous = self.previousSkinByTier[definition.Tier]
    local skinProfile = EnemySkinRules.pick(
        self.waveThemeId,
        definition.Tier,
        selfSeed,
        previous,
        EnemySkinDefinitions
    )

    if skinProfile then
        self.previousSkinByTier[definition.Tier] = skinProfile.ProfileId
    end

    local model, humanoid, root = EnemyFactory.Create(definition, spawnCFrame, wave, skinProfile)
    if not model or not humanoid or not root then
        return nil
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

    self.defeated:Fire(record.definition.Id, record.definition.IsElite, position)

    task.delay(0.2, function()
        if model.Parent then
            model:Destroy()
        end
    end)
end

function EnemyService:ClearAll()
    local snapshot = {}
    for model, record in pairs(self.active) do
        table.insert(snapshot, {model = model, record = record})
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
