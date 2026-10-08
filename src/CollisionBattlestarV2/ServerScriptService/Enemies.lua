--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Definitions = require(ReplicatedStorage.Shared.EnemyDefinitions)
local AIHeart = require(script.Parent.AI.Heart)
local PhysicsRules = require(ReplicatedStorage.Shared.PhysicsRules)

local Enemies = {}
Enemies.__index = Enemies

function Enemies.new(world, playerService, scoreService, remotes, heart)
    local self = setmetatable({
        world = world,
        players = playerService,
        score = scoreService,
        remotes = remotes,
        heart = heart,
        active = {},
        defeated = Instance.new("BindableEvent"),
        wave = 0,
        boss = false,
        ai = nil,
    }, Enemies)

    self.ai = AIHeart.new(function(label, err)
        if self.heart then
            self.heart:Report(label, err)
        end
    end)

    return self
end

function Enemies:BuildModel(definition, position)
    local model = Instance.new("Model")
    model.Name = definition.Id
    model:SetAttribute("CBS2_NPC", true)
    model:SetAttribute("CBS2_NPC", true)
    model:SetAttribute("CBS2_Elite", definition.Elite)
    model:SetAttribute("CBS2_Boss", definition.Boss)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = true
    root.CanTouch = false
    root.CanQuery = true
    root.CollisionGroup = "CBS_NPC"
    root.CustomPhysicalProperties = PhysicsRules.NPC
    root.Position = position
    root.Parent = model

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = definition.Boss and Vector3.new(4, 5, 3) or Vector3.new(2.5, 3.2, 2)
    body.CanCollide = false
    body.CanTouch = false
    body.CanQuery = true
    body.CollisionGroup = "CBS_NPC"
    body.CustomPhysicalProperties = PhysicsRules.NPC
    body.Color = definition.Boss and Color3.fromRGB(175, 55, 65)
        or definition.Elite and Color3.fromRGB(170, 80, 220)
        or Color3.fromRGB(90, 100, 120)
    body.Material = Enum.Material.Metal
    body.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = definition.Boss and Vector3.new(3, 3, 3) or Vector3.new(2, 2, 2)
    head.CanCollide = false
    head.CanTouch = false
    head.CanQuery = false
    head.CollisionGroup = "CBS_NPC"
    head.CustomPhysicalProperties = PhysicsRules.NPC
    head.Color = body.Color
    head.Material = Enum.Material.SmoothPlastic
    head.Parent = model

    root.CFrame = CFrame.new(position)
    body.CFrame = root.CFrame * CFrame.new(0, 1.8, 0)
    head.CFrame = root.CFrame * CFrame.new(0, 3.9, 0)

    for _, part in ipairs({body, head}) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = root
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = definition.Health
    humanoid.Health = definition.Health
    humanoid.WalkSpeed = definition.Speed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.RequiresNeck = false
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = workspace:FindFirstChild("CBS2_NPCs") or workspace

    return model, humanoid, root
end

function Enemies:Spawn(id: string)
    if self:Count() >= Constants.MaxNPCs then
        return nil
    end

    local definition = Definitions[id]
    if not definition then
        return nil
    end

    local spawns = self.world:GetEnemySpawns()
    if #spawns == 0 then
        return nil
    end

    local index = (self:Count() % #spawns) + 1
    local basePosition = spawns[index].Position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))
    local model, humanoid, root = self:BuildModel(definition, basePosition)

    local record = {
        definition = definition,
        humanoid = humanoid,
        root = root,
        connection = nil,
    }

    root:SetNetworkOwner(nil)

    self.active[model] = record

    record.connection = humanoid.Died:Connect(function()
        self:OnDeath(model)
    end)

    local registered = self.ai:Register(model, humanoid, root, definition, {
        damagePlayer = function(player, amount)
            return self.players:Damage(player, amount)
        end,
    })

    if not registered then
        self.active[model] = nil
        record.connection:Disconnect()
        model:Destroy()
        return nil
    end

    self.remotes.FX:FireAllClients("Spawn", {
        position = root.Position,
        elite = definition.Elite,
        boss = definition.Boss,
    })

    return model
end

function Enemies:OnDeath(model: Model)
    local record = self.active[model]
    if not record then
        return
    end

    self.active[model] = nil
    self.ai:Unregister(model)

    if record.connection then
        record.connection:Disconnect()
    end

    local killerId = model:GetAttribute("CBS2_LastHitUserId")
    local killer = type(killerId) == "number" and Players:GetPlayerByUserId(killerId) or nil

    if killer then
        self.score:Enemy(killer, record.definition.Reward, record.definition.Elite, record.definition.Boss)
    end

    self.defeated:Fire(
        record.definition.Id,
        record.definition.Elite,
        record.definition.Boss,
        killer
    )

    self.remotes.FX:FireAllClients("Defeat", {
        position = record.root.Position,
        elite = record.definition.Elite,
        boss = record.definition.Boss,
    })

    task.delay(0.15, function()
        if model.Parent then
            model:Destroy()
        end
    end)
end

function Enemies:TakeDamage(player: Player, model: Model, amount: number, critical: boolean)
    local record = self.active[model]
    if not record or not player.Parent then
        return false
    end

    if player:GetAttribute("CBS_PvP") == true then
        return false
    end

    local humanoid = record.humanoid
    if humanoid.Health <= 0 then
        return false
    end

    model:SetAttribute("CBS2_LastHitUserId", player.UserId)
    humanoid:TakeDamage(math.max(0, math.floor(amount)))

    if critical then
        self.remotes.FX:FireAllClients("Critical", {
            position = record.root.Position,
        })
    else
        self.remotes.FX:FireAllClients("Hit", {
            position = record.root.Position,
        })
    end

    return true
end

function Enemies:DamagePlayer(player: Player, amount: number)
    return self.players:Damage(player, amount)
end

function Enemies:Count()
    local count = 0
    for model in pairs(self.active) do
        if model.Parent then
            count += 1
        else
            self.active[model] = nil
            self.ai:Unregister(model)
        end
    end
    return count
end

function Enemies:Clear()
    local models = {}
    for model, record in pairs(self.active) do
        models[#models + 1] = model
        if record.connection then
            record.connection:Disconnect()
        end
    end

    table.clear(self.active)
    self.ai:Clear()

    for _, model in ipairs(models) do
        if model.Parent then
            model:Destroy()
        end
    end
end

function Enemies:SetWave(wave: number)
    self.wave = wave
    self.boss = wave % 10 == 0
    self.ai:SetWave(wave)
end

function Enemies:GetDefeated()
    return self.defeated.Event
end

function Enemies:HealthCheck()
    return self:Count() <= Constants.MaxNPCs
        and self.ai:HealthCheck()
end

function Enemies:Start()
    local folder = workspace:FindFirstChild("CBS2_NPCs")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CBS2_NPCs"
        folder.Parent = workspace
    end

    self.ai:SetWave(self.wave)
    self.ai:Start()
end

function Enemies:Stop()
    self:Clear()
    self.ai:Stop()
end

function Enemies:Reload()
    self:Clear()
    self.ai:SetWave(self.wave)
    self.ai:Start()
end

return Enemies
