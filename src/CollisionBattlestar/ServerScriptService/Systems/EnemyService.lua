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

local skinRng = Random.new(260926)

local skins = {
    Urban = {
        Shirt = 607785314,
        Pants = 398633812,
        Body = Color3.fromRGB(72, 86, 104),
        Head = Color3.fromRGB(172, 182, 194),
        Accent = Color3.fromRGB(102, 126, 166),
    },
    Street = {
        Shirt = 398633584,
        Pants = 398634487,
        Body = Color3.fromRGB(72, 74, 82),
        Head = Color3.fromRGB(186, 178, 164),
        Accent = Color3.fromRGB(74, 112, 154),
    },
    Rider = {
        Shirt = 144076358,
        Pants = 398633812,
        Body = Color3.fromRGB(48, 57, 68),
        Head = Color3.fromRGB(176, 184, 192),
        Accent = Color3.fromRGB(72, 132, 202),
    },
    Green = {
        Shirt = 382538059,
        Pants = 398633812,
        Body = Color3.fromRGB(52, 78, 62),
        Head = Color3.fromRGB(172, 184, 174),
        Accent = Color3.fromRGB(98, 178, 112),
    },
    Elite = {
        Shirt = 398633584,
        Pants = 398633812,
        Body = Color3.fromRGB(72, 42, 50),
        Head = Color3.fromRGB(210, 188, 184),
        Accent = Color3.fromRGB(232, 76, 70),
    },
}

local regularSkinNames = {"Urban", "Street", "Rider", "Green"}

local function now()
    return os.clock()
end

local function closestPlayer(position: Vector3): Player?
    local best: Player?
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("Zone") ~= "PvP" then
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
    end

    return best
end

local function applyDisplay(model: Model, tier: number, elite: boolean)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local head = model:FindFirstChild("Head")
    if not humanoid or not head or not head:IsA("BasePart") then
        return
    end

    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EnemyTitle"
    billboard.Size = UDim2.fromOffset(150, elite and 38 or 26)
    billboard.StudsOffset = Vector3.new(0, 3.1, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 85
    billboard.Adornee = head
    billboard.Parent = model

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(1, 0.72)
    title.Font = Enum.Font.GothamBold
    title.TextSize = elite and 11 or 9
    title.TextColor3 = if elite then Config.UI.Danger else Config.UI.Text
    title.TextStrokeTransparency = 0.45
    title.Text = if elite then "ELITE" else ("TIER %d"):format(tier)
    title.Parent = billboard

    local back = Instance.new("Frame")
    back.Name = "HealthBack"
    back.Size = UDim2.new(0.78, 0, 0, 5)
    back.Position = UDim2.new(0.11, 0, 0.75, 0)
    back.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
    back.BorderSizePixel = 0
    back.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = back

    local fill = Instance.new("Frame")
    fill.Name = "HealthFill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = if elite then Config.UI.Danger else Config.UI.Good
    fill.BorderSizePixel = 0
    fill.Parent = back

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    humanoid.HealthChanged:Connect(function(health)
        if back.Parent and humanoid.MaxHealth > 0 then
            fill.Size = UDim2.fromScale(math.clamp(health / humanoid.MaxHealth, 0, 1), 1)
        end
    end)
end

local function createHumanoidEnemy(position: Vector3, tier: number, elite: boolean): Model?
    local skinName = if elite then "Elite" else regularSkinNames[skinRng:NextInteger(1, #regularSkinNames)]
    local skin = skins[skinName]

    local description = Instance.new("HumanoidDescription")
    description.Shirt = skin.Shirt
    description.Pants = skin.Pants
    description.HeadColor = skin.Head
    description.TorsoColor = skin.Body
    description.LeftArmColor = skin.Body
    description.RightArmColor = skin.Body
    description.LeftLegColor = skin.Body
    description.RightLegColor = skin.Body
    description.BodyTypeScale = if elite then 0.5 else 0.42
    description.ProportionScale = 0.7
    description.WidthScale = if elite then 1.02 else 0.86
    description.DepthScale = if elite then 0.96 else 0.84
    description.HeightScale = if elite then 1.06 else 1
    description.HeadScale = 0.96

    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
    end)

    if not ok or not model then
        return nil
    end

    model.Name = if elite then "EliteEnemy" else ("Enemy_Tier%d"):format(tier)
    model.Parent = workspace

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        return nil
    end

    model:PivotTo(CFrame.new(position))
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    local baseConfig = if tier >= 3 then Config.Enemies.Tier3 elseif tier == 2 then Config.Enemies.Tier2 else Config.Enemies.Tier1
    local multiplier = if elite then Config.Enemies.Elite else nil

    local health = baseConfig.Health * (multiplier and multiplier.HealthMultiplier or 1)
    local speed = baseConfig.Speed * (multiplier and multiplier.SpeedMultiplier or 1)
    local damage = baseConfig.Damage * (multiplier and multiplier.DamageMultiplier or 1)
    local reward = baseConfig.Reward * (multiplier and multiplier.RewardMultiplier or 1)

    humanoid.MaxHealth = health
    humanoid.Health = health
    humanoid.WalkSpeed = speed
    humanoid.JumpPower = 44
    humanoid.AutoRotate = true

    model.PrimaryPart = root
    model:SetAttribute("Enemy", true)
    model:SetAttribute("Tier", tier)
    model:SetAttribute("Elite", elite)
    model:SetAttribute("Damage", damage)
    model:SetAttribute("Reward", reward)
    model:SetAttribute("Skin", skinName)
    model:SetAttribute("SkinShirtId", skin.Shirt)
    model:SetAttribute("SkinPantsId", skin.Pants)

    CollectionService:AddTag(model, "EnemyNPC")

    local rootPart = root :: BasePart
    rootPart.CanCollide = true
    rootPart.CanTouch = false

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanTouch = false
            descendant:SetNetworkOwner(nil)
        end
    end

    applyDisplay(model, tier, elite)

    if elite then
        local highlight = Instance.new("Highlight")
        highlight.Name = "EliteMarker"
        highlight.FillColor = Config.UI.Danger
        highlight.FillTransparency = 0.48
        highlight.OutlineColor = Color3.fromRGB(255, 235, 235)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Adornee = model
        highlight.Parent = model

        local marker = Instance.new("PointLight")
        marker.Name = "EliteGlow"
        marker.Color = Config.UI.Danger
        marker.Brightness = 1.2
        marker.Range = 9
        marker.Shadows = false
        marker.Parent = rootPart
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
            if attacker and attacker:GetAttribute("Zone") ~= "PvP" then
                local finalReward = rewardAmount

                if elite and attacker:GetAttribute("Pass_EliteBonus") == true then
                    finalReward *= 2
                end

                if attacker:GetAttribute("Pass_VIP") == true then
                    finalReward *= 1.1
                end

                finalReward = math.floor(finalReward)
                DataService:AddCredits(attacker, finalReward)
                stateEvent:FireClient(attacker, "Reward", finalReward, elite)
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
    if target:GetAttribute("Zone") == "PvP" then
        return
    end

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
    return createHumanoidEnemy(position, tier, elite)
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
