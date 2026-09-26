--!strict

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local Service = {}

local Config
local DataService
local stateEvent

local enemies: {[Model]: {
    Tier: number,
    Elite: boolean,
    LastAttack: number,
    ThinkAt: number,
}} = {}

local function now()
    return os.clock()
end

local function closestPlayer(position: Vector3): Player?
    local best: Player?
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
            local distance = (root.Position - position).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                best = player
            end
        end
    end

    return best
end

local function makePart(parent: Instance, name: string, size: Vector3, color: Color3): BasePart
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.CanCollide = true
    part.Parent = parent
    return part
end

local function weld(a: BasePart, b: BasePart)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = a
    constraint.Part1 = b
    constraint.Parent = a
end

local function createEnemy(position: Vector3, tier: number, elite: boolean): Model
    local baseConfig = if tier >= 3 then Config.Enemies.Tier3 elseif tier == 2 then Config.Enemies.Tier2 else Config.Enemies.Tier1

    local multiplier = if elite then Config.Enemies.Elite else nil
    local health = baseConfig.Health * (multiplier and multiplier.HealthMultiplier or 1)
    local speed = baseConfig.Speed * (multiplier and multiplier.SpeedMultiplier or 1)
    local damage = baseConfig.Damage * (multiplier and multiplier.DamageMultiplier or 1)
    local reward = baseConfig.Reward * (multiplier and multiplier.RewardMultiplier or 1)

    local model = Instance.new("Model")
    model.Name = if elite then "EliteEnemy" else ("Enemy_Tier%d"):format(tier)
    model.Parent = workspace

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2.6, 3.2, 1.8),
        if elite then Config.UI.Danger else Color3.fromRGB(80, 105 + tier * 20, 125)
    )
    root.Transparency = 0
    root.CanCollide = true
    root.CFrame = CFrame.new(position)

    local torso = makePart(model, "Torso", Vector3.new(3, 3.4, 1.8), root.Color)
    torso.CFrame = root.CFrame * CFrame.new(0, 0.2, 0)
    weld(root, torso)

    local head = makePart(model, "Head", Vector3.new(2.1, 2.1, 2.1), if elite then Color3.fromRGB(255, 100, 105) else Color3.fromRGB(190, 195, 205))
    head.Shape = Enum.PartType.Ball
    head.CFrame = root.CFrame * CFrame.new(0, 2.65, 0)
    weld(root, head)

    local leftArm = makePart(model, "LeftArm", Vector3.new(0.9, 3.2, 0.9), torso.Color)
    leftArm.CFrame = root.CFrame * CFrame.new(-1.95, 0.15, 0)
    weld(root, leftArm)

    local rightArm = makePart(model, "RightArm", Vector3.new(0.9, 3.2, 0.9), torso.Color)
    rightArm.CFrame = root.CFrame * CFrame.new(1.95, 0.15, 0)
    weld(root, rightArm)

    local leftLeg = makePart(model, "LeftLeg", Vector3.new(1.05, 3.4, 1.05), torso.Color)
    leftLeg.CFrame = root.CFrame * CFrame.new(-0.75, -3.2, 0)
    weld(root, leftLeg)

    local rightLeg = makePart(model, "RightLeg", Vector3.new(1.05, 3.4, 1.05), torso.Color)
    rightLeg.CFrame = root.CFrame * CFrame.new(0.75, -3.2, 0)
    weld(root, rightLeg)

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.WalkSpeed = speed
    humanoid.JumpPower = 44
    humanoid.AutoRotate = true
    humanoid.Parent = model

    model.PrimaryPart = root
    model:SetAttribute("Enemy", true)
    model:SetAttribute("Tier", tier)
    model:SetAttribute("Elite", elite)
    model:SetAttribute("Damage", damage)
    model:SetAttribute("Reward", reward)

    CollectionService:AddTag(model, "EnemyNPC")

    if elite then
        local highlight = Instance.new("Highlight")
        highlight.Name = "EliteMarker"
        highlight.FillColor = Config.UI.Danger
        highlight.FillTransparency = 0.35
        highlight.OutlineColor = Color3.fromRGB(255, 235, 235)
        highlight.OutlineTransparency = 0
        highlight.Adornee = model
        highlight.Parent = model

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "EliteLabel"
        billboard.Size = UDim2.fromOffset(120, 28)
        billboard.StudsOffset = Vector3.new(0, 4.4, 0)
        billboard.Adornee = head
        billboard.Parent = model

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Text = "ELITE"
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.TextColor3 = Config.UI.Danger
        label.TextStrokeTransparency = 0.3
        label.Parent = billboard
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant:SetNetworkOwner(nil)
        end
    end

    local runtime = {
        Tier = tier,
        Elite = elite,
        LastAttack = 0,
        ThinkAt = 0,
    }
    enemies[model] = runtime

    humanoid.Died:Connect(function()
        enemies[model] = nil
        local attackerId = humanoid:GetAttribute("LastAttackerUserId")
        local rewardAmount = tonumber(model:GetAttribute("Reward")) or 0

        if type(attackerId) == "number" then
            local attacker = Players:GetPlayerByUserId(attackerId)
            if attacker then
                local multiplierPass = attacker:GetAttribute("Pass_EliteBonus") == true and elite
                local vipPass = attacker:GetAttribute("Pass_VIP") == true
                local finalReward = rewardAmount
                if multiplierPass then
                    finalReward *= 2
                end
                if vipPass then
                    finalReward *= 1.1
                end
                DataService:AddCredits(attacker, math.floor(finalReward))
                stateEvent:FireClient(attacker, "Reward", math.floor(finalReward), elite)
            end
        end

        task.delay(1.2, function()
            if model.Parent then
                model:Destroy()
            end
        end)
    end)

    return model
end

local function attackPlayer(model: Model, runtime, target: Player)
    local root = model.PrimaryPart
    local character = target.Character
    if not root or not character then
        return
    end

    local targetRoot = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetRoot:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return
    end

    local baseDamage = tonumber(model:GetAttribute("Damage")) or 5
    local stats = DataService:GetCombatStats(target)
    local mitigation = stats and stats.Defense or 1
    local damage = math.max(1, baseDamage * mitigation)

    humanoid:TakeDamage(damage)
    runtime.LastAttack = now()
end

local function chase(model: Model, runtime, target: Player)
    local root = model.PrimaryPart
    local character = target.Character
    if not root or not character then
        return
    end

    local targetRoot = character:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetRoot:IsA("BasePart") or not humanoid then
        return
    end

    local distance = (targetRoot.Position - root.Position).Magnitude
    local attackRange = if runtime.Tier >= 3 then 6 elseif runtime.Tier == 2 then 5.5 else 5

    if distance <= attackRange then
        if now() - runtime.LastAttack >= (if runtime.Elite then 0.7 else 1.1) then
            attackPlayer(model, runtime, target)
        end
        humanoid:MoveTo(root.Position)
        return
    end

    if now() < runtime.ThinkAt then
        return
    end

    runtime.ThinkAt = now() + 0.8

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
    })

    local success = pcall(function()
        path:ComputeAsync(root.Position, targetRoot.Position)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local waypoint = waypoints[math.min(2, #waypoints)]
        if waypoint then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid:MoveTo(waypoint.Position)
            return
        end
    end

    humanoid:MoveTo(targetRoot.Position)
end

function Service:Init(config, dataService, stateRemote)
    Config = config
    DataService = dataService
    stateEvent = stateRemote

    task.spawn(function()
        while true do
            for model, runtime in pairs(enemies) do
                if model.Parent then
                    local target = closestPlayer(model:GetPivot().Position)
                    if target then
                        chase(model, runtime, target)
                    end
                else
                    enemies[model] = nil
                end
            end
            task.wait(0.12)
        end
    end)
end

function Service:Spawn(position: Vector3, tier: number, elite: boolean)
    return createEnemy(position, tier, elite)
end

function Service:Count(): number
    local count = 0
    for model in pairs(enemies) do
        if model.Parent then
            count += 1
        end
    end
    return count
end

function Service:Clear()
    for model in pairs(enemies) do
        if model.Parent then
            model:Destroy()
        end
    end
    table.clear(enemies)
end

return Service
