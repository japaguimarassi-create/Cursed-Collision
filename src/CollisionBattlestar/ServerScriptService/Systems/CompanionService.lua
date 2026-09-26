--!strict

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local Service = {}

local Config
local DataService

type ActiveCompanion = {
    Model: Model,
    Key: string,
}

local active: {[Player]: {ActiveCompanion}} = {}
local nextAttack: {[Model]: number} = {}

local function definitionFor(key: string)
    for _, definition in ipairs(Config.Shop.Companions) do
        if definition.Key == key then
            return definition
        end
    end
    return nil
end

local function ownedDefinitions(player: Player)
    local profile = DataService:Get(player)
    if not profile then
        return {}
    end

    local result = {}
    for index, definition in ipairs(Config.Shop.Companions) do
        local amount = profile.Companions[definition.Key] or 0
        if amount > 0 or (definition.Key == "Scout" and player:GetAttribute("Pass_StarterCompanion") == true) then
            table.insert(result, {
                index = index,
                definition = definition,
            })
        end
    end

    return result
end

local function createCompanion(player: Player, definition)
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not playerRoot:IsA("BasePart") then
        return nil
    end

    local model = Instance.new("Model")
    model.Name = "Companion_" .. definition.Key
    model.Parent = workspace

    local body = Instance.new("Part")
    body.Name = "HumanoidRootPart"
    body.Size = Vector3.new(2.4, 3.1, 2)
    body.CFrame = playerRoot.CFrame * CFrame.new(5, 2, 5)
    body.Material = Enum.Material.Metal
    body.Color = Color3.fromRGB(80, 170, 220)
    body.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2, 2, 2)
    head.CFrame = body.CFrame * CFrame.new(0, 2.5, 0)
    head.Material = Enum.Material.Neon
    head.Color = Color3.fromRGB(170, 235, 255)
    head.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = head
    weld.Parent = body

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = definition.Health
    humanoid.Health = definition.Health
    humanoid.WalkSpeed = definition.Speed
    humanoid.JumpPower = 44
    humanoid.Parent = model

    model.PrimaryPart = body
    model:SetAttribute("Companion", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("CompanionKey", definition.Key)
    model:SetAttribute("Damage", definition.Damage)

    CollectionService:AddTag(model, "CompanionNPC")

    body:SetNetworkOwner(nil)

    humanoid.Died:Connect(function()
        nextAttack[model] = nil
        task.delay(1, function()
            if model.Parent then
                model:Destroy()
            end
        end)
    end)

    return model
end

local function refresh(player: Player)
    for _, state in ipairs(active[player] or {}) do
        if state.Model.Parent then
            state.Model:Destroy()
        end
    end

    active[player] = {}

    local owned = ownedDefinitions(player)
    local slots = if player:GetAttribute("Pass_SecondCompanion") == true then 2 else 1

    local startIndex = math.max(1, #owned - slots + 1)
    for index = #owned, startIndex, -1 do
        local definition = owned[index].definition
        local model = createCompanion(player, definition)
        if model then
            table.insert(active[player], {
                Model = model,
                Key = definition.Key,
            })
        end
    end
end

local function nearestEnemy(position: Vector3, maxDistance: number): Model?
    local best
    local bestDistance = maxDistance

    for _, enemy in ipairs(CollectionService:GetTagged("EnemyNPC")) do
        if enemy:IsA("Model") and enemy.PrimaryPart then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local distance = (enemy.PrimaryPart.Position - position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    best = enemy
                end
            end
        end
    end

    return best
end

local function think(player: Player, state: ActiveCompanion)
    local model = state.Model
    if not model.Parent or not model.PrimaryPart then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not playerRoot:IsA("BasePart") then
        return
    end

    local definition = definitionFor(state.Key)
    if not definition then
        return
    end

    local enemy = nearestEnemy(model.PrimaryPart.Position, definition.AttackRange + 20)

    if enemy and enemy.PrimaryPart then
        local distance = (enemy.PrimaryPart.Position - model.PrimaryPart.Position).Magnitude

        if distance <= definition.AttackRange then
            local nextTime = nextAttack[model] or 0
            if os.clock() >= nextTime then
                local targetHumanoid = enemy:FindFirstChildOfClass("Humanoid")
                if targetHumanoid and targetHumanoid.Health > 0 then
                    targetHumanoid:SetAttribute("LastAttackerUserId", player.UserId)
                    targetHumanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
                    targetHumanoid:TakeDamage(definition.Damage)
                    nextAttack[model] = os.clock() + definition.AttackCooldown
                end
            end
            humanoid:MoveTo(model.PrimaryPart.Position)
            return
        end

        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4,
        })

        local success = pcall(function()
            path:ComputeAsync(model.PrimaryPart.Position, enemy.PrimaryPart.Position)
        end)

        if success and path.Status == Enum.PathStatus.Success then
            local points = path:GetWaypoints()
            local point = points[math.min(2, #points)]
            if point then
                if point.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end
                humanoid:MoveTo(point.Position)
                return
            end
        end

        humanoid:MoveTo(enemy.PrimaryPart.Position)
        return
    end

    humanoid:MoveTo(playerRoot.Position + Vector3.new(5, 0, 5))
end

function Service:Init(config, dataService)
    Config = config
    DataService = dataService

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            refresh(player)
        end)

        player:GetAttributeChangedSignal("DataReady"):Connect(function()
            if player:GetAttribute("DataReady") == true then
                refresh(player)
            end
        end)

        for _, key in ipairs({"Pass_SecondCompanion", "Pass_StarterCompanion"}) do
            player:GetAttributeChangedSignal(key):Connect(function()
                refresh(player)
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        for _, state in ipairs(active[player] or {}) do
            if state.Model.Parent then
                state.Model:Destroy()
            end
        end
        active[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(refresh, player)
    end

    task.spawn(function()
        while true do
            for player, states in pairs(active) do
                if player.Parent then
                    for _, state in ipairs(states) do
                        think(player, state)
                    end
                end
            end
            task.wait(0.18)
        end
    end)
end

return Service
