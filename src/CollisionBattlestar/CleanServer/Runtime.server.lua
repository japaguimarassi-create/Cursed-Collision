--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Rules = require(ReplicatedStorage:WaitForChild("CleanRules"))

Players.CharacterAutoLoads = false

local remotesFolder = ReplicatedStorage:FindFirstChild("CBS_Remotes")
if remotesFolder then
    remotesFolder:Destroy()
end
remotesFolder = Instance.new("Folder")
remotesFolder.Name = "CBS_Remotes"
remotesFolder.Parent = ReplicatedStorage

local Action = Instance.new("RemoteEvent")
Action.Name = "Action"
Action.Parent = remotesFolder

local State = Instance.new("RemoteEvent")
State.Name = "State"
State.Parent = remotesFolder

local WORLD = workspace:FindFirstChild("CollisionBattlestarWorld")
if WORLD then
    WORLD:Destroy()
end
WORLD = Instance.new("Folder")
WORLD.Name = "CollisionBattlestarWorld"
WORLD.Parent = workspace

local ENEMIES = Instance.new("Folder")
ENEMIES.Name = "Enemies"
ENEMIES.Parent = WORLD

local COMPANIONS = Instance.new("Folder")
COMPANIONS.Name = "Companions"
COMPANIONS.Parent = WORLD

local profiles = {}
local persistenceReady = {}
local attackAt = {}
local dashAt = {}
local combo = {}
local comboAt = {}
local echoes = {}
local enemies = {}

local currentWave = 0
local currentPhase = "BOOTING"
local activeEnemies = 0
local eliteAlive = false
local waveToken = 0
local worldReady = false

local STORE
local storeOk = pcall(function()
    STORE = DataStoreService:GetDataStore("CollisionBattlestar_PlayerProfiles_v3")
end)

local function defaultProfile()
    return {
        Credits = 0,
        DamageLevel = 0,
        Kills = 0,
        HighestWave = 0,
        OwnedSkins = {Default = true},
        EquippedSkin = "Default",
        EchoClass = "Vanguard",
    }
end

local function validProfile(data)
    return type(data) == "table"
        and type(data.Credits) == "number"
        and type(data.DamageLevel) == "number"
        and type(data.Kills) == "number"
        and type(data.HighestWave) == "number"
        and type(data.OwnedSkins) == "table"
        and type(data.EquippedSkin) == "string"
        and type(data.EchoClass) == "string"
end

local function migrate(data)
    local profile = defaultProfile()
    if type(data) ~= "table" then
        return profile
    end
    profile.Credits = math.max(0, math.floor(tonumber(data.Credits) or 0))
    profile.DamageLevel = math.clamp(math.floor(tonumber(data.DamageLevel) or 0), 0, 100)
    profile.Kills = math.max(0, math.floor(tonumber(data.Kills) or 0))
    profile.HighestWave = math.max(0, math.floor(tonumber(data.HighestWave) or 0))
    if type(data.OwnedSkins) == "table" then
        profile.OwnedSkins = {Default = true}
        for skinId, owned in pairs(data.OwnedSkins) do
            if type(skinId) == "string" and owned == true and Rules.isValidSkin(skinId) then
                profile.OwnedSkins[skinId] = true
            end
        end
    end
    if Rules.isValidSkin(data.EquippedSkin) and profile.OwnedSkins[data.EquippedSkin] then
        profile.EquippedSkin = data.EquippedSkin
    end
    if Rules.isValidEchoClass(data.EchoClass) then
        profile.EchoClass = data.EchoClass
    end
    return profile
end

local function copyProfile(profile)
    local owned = {}
    for id, value in pairs(profile.OwnedSkins) do
        owned[id] = value
    end
    return {
        Credits = math.max(0, math.floor(profile.Credits)),
        DamageLevel = math.max(0, math.floor(profile.DamageLevel)),
        Kills = math.max(0, math.floor(profile.Kills)),
        HighestWave = math.max(0, math.floor(profile.HighestWave)),
        OwnedSkins = owned,
        EquippedSkin = profile.EquippedSkin,
        EchoClass = profile.EchoClass,
    }
end

local function loadProfile(player)
    if not storeOk or not STORE then
        profiles[player] = defaultProfile()
        persistenceReady[player] = false
        return
    end

    local success, data = pcall(function()
        return STORE:GetAsync("u:" .. tostring(player.UserId))
    end)
    if success then
        profiles[player] = migrate(data)
        persistenceReady[player] = true
    else
        profiles[player] = defaultProfile()
        persistenceReady[player] = false
        warn("[CollisionBattlestar] Data load failed for " .. player.Name)
    end
end

local function saveProfile(player)
    local profile = profiles[player]
    if not profile or not persistenceReady[player] or not STORE then
        return
    end
    local payload = copyProfile(profile)
    local success = pcall(function()
        STORE:UpdateAsync("u:" .. tostring(player.UserId), function()
            return payload
        end)
    end)
    if not success then
        warn("[CollisionBattlestar] Data save failed for " .. player.Name)
    end
end

local function color(values)
    return Color3.fromRGB(values[1], values[2], values[3])
end

local function part(parent, name, size, position, material, partColor, collision)
    local instance = Instance.new("Part")
    instance.Name = name
    instance.Size = size
    instance.Position = position
    instance.Anchored = true
    instance.Material = material
    instance.Color = partColor
    instance.CanCollide = collision ~= false
    instance.CanTouch = false
    instance.CanQuery = collision ~= false
    instance.TopSurface = Enum.SurfaceType.Smooth
    instance.BottomSurface = Enum.SurfaceType.Smooth
    instance.Parent = parent
    return instance
end

local function beam(parent, position, length, colorValue)
    return part(parent, "Beam", Vector3.new(length, 0.25, 0.35), position, Enum.Material.Neon, colorValue, false)
end

local playerSpawn
local upgradePrompt

local function buildWorld()
    Lighting.ClockTime = 18.1
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(72, 82, 96)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 110, 126)
    Lighting.FogColor = Color3.fromRGB(28, 34, 48)
    Lighting.FogEnd = 650

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere:Destroy()
    end
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.16
    atmosphere.Haze = 0.08
    atmosphere.Glare = 0.06
    atmosphere.Color = Color3.fromRGB(190, 215, 255)
    atmosphere.Decay = Color3.fromRGB(68, 82, 112)
    atmosphere.Parent = Lighting

    part(WORLD, "Floor", Vector3.new(164, 2, 112), Vector3.new(0, -1, 0), Enum.Material.Slate, Color3.fromRGB(46, 53, 65))
    part(WORLD, "NorthWall", Vector3.new(164, 10, 3), Vector3.new(0, 4, -56), Enum.Material.Concrete, Color3.fromRGB(30, 35, 46))
    part(WORLD, "SouthWall", Vector3.new(164, 10, 3), Vector3.new(0, 4, 56), Enum.Material.Concrete, Color3.fromRGB(30, 35, 46))
    part(WORLD, "WestWall", Vector3.new(3, 10, 112), Vector3.new(-82, 4, 0), Enum.Material.Concrete, Color3.fromRGB(30, 35, 46))
    part(WORLD, "EastWall", Vector3.new(3, 10, 112), Vector3.new(82, 4, 0), Enum.Material.Concrete, Color3.fromRGB(30, 35, 46))

    local core = Instance.new("Model")
    core.Name = "CollisionCore"
    core.Parent = WORLD
    part(core, "Platform", Vector3.new(32, 2, 32), Vector3.new(0, 0, 0), Enum.Material.Concrete, Color3.fromRGB(70, 78, 92))
    part(core, "Top", Vector3.new(25, 1, 25), Vector3.new(0, 1.5, 0), Enum.Material.Metal, Color3.fromRGB(34, 40, 52))

    local orb = part(core, "Core", Vector3.new(5, 5, 5), Vector3.new(0, 7, 0), Enum.Material.Neon, Color3.fromRGB(60, 215, 255), false)
    orb.Shape = Enum.PartType.Ball
    local coreLight = Instance.new("PointLight")
    coreLight.Brightness = 2
    coreLight.Range = 24
    coreLight.Color = orb.Color
    coreLight.Parent = orb

    for _, data in ipairs({
        {Vector3.new(-60, 0, -40), Color3.fromRGB(75, 90, 108)},
        {Vector3.new(60, 0, -40), Color3.fromRGB(75, 90, 108)},
        {Vector3.new(-60, 0, 40), Color3.fromRGB(75, 90, 108)},
        {Vector3.new(60, 0, 40), Color3.fromRGB(75, 90, 108)},
    }) do
        part(WORLD, "Cover", Vector3.new(13, 5, 9), data[1] + Vector3.new(0, 2.5, 0), Enum.Material.Concrete, data[2], false)
        beam(WORLD, data[1] + Vector3.new(0, 5.15, -4.2), 9, Color3.fromRGB(60, 215, 255))
    end

    local gatePositions = {
        Vector3.new(-64, 2, -48),
        Vector3.new(64, 2, -48),
        Vector3.new(-76, 2, 0),
        Vector3.new(76, 2, 0),
        Vector3.new(-64, 2, 48),
        Vector3.new(64, 2, 48),
    }

    for index, position in ipairs(gatePositions) do
        local gate = Instance.new("Model")
        gate.Name = "EnemyGate_" .. index
        gate.Parent = WORLD
        part(gate, "PostL", Vector3.new(2.5, 9, 2.5), position + Vector3.new(-7, 2.5, 0), Enum.Material.Metal, Color3.fromRGB(34, 40, 52))
        part(gate, "PostR", Vector3.new(2.5, 9, 2.5), position + Vector3.new(7, 2.5, 0), Enum.Material.Metal, Color3.fromRGB(34, 40, 52))
        part(gate, "Top", Vector3.new(17, 2.5, 2.5), position + Vector3.new(0, 7, 0), Enum.Material.Metal, Color3.fromRGB(34, 40, 52))
        beam(gate, position + Vector3.new(0, 6.1, 1.4), 11, Color3.fromRGB(255, 70, 88))
    end

    local station = part(WORLD, "UpgradeStation", Vector3.new(9, 2, 9), Vector3.new(0, 1, 43), Enum.Material.Neon, Color3.fromRGB(84, 236, 158))
    upgradePrompt = Instance.new("ProximityPrompt")
    upgradePrompt.Name = "UpgradePrompt"
    upgradePrompt.ActionText = "UPGRADE DAMAGE"
    upgradePrompt.ObjectText = "COMBAT STATION"
    upgradePrompt.HoldDuration = 0.25
    upgradePrompt.MaxActivationDistance = 11
    upgradePrompt.RequiresLineOfSight = false
    upgradePrompt.Parent = station

    playerSpawn = part(WORLD, "PlayerSpawn", Vector3.new(8, 1, 8), Vector3.new(0, 1, 34), Enum.Material.ForceField, Color3.fromRGB(84, 236, 158), false)
    playerSpawn.Transparency = 0.8

    local sign = part(WORLD, "Sign", Vector3.new(34, 8, 1), Vector3.new(0, 7, 53), Enum.Material.Metal, Color3.fromRGB(27, 32, 44), false)
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.AlwaysOnTop = true
    surface.Parent = sign
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "COLLISION BATTLESTAR"
    text.TextColor3 = Color3.fromRGB(95, 220, 255)
    text.Font = Enum.Font.GothamBlack
    text.TextScaled = true
    text.Parent = surface

    worldReady = true
    workspace:SetAttribute("CBS_WorldReady", true)
end

local function applySkin(player, character)
    local profile = profiles[player]
    if not profile then
        return
    end
    local skin = Rules.skin(profile.EquippedSkin) or Rules.skin("Default")
    local primary = color(skin.Primary)
    local accent = color(skin.Accent)

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            descendant.Color = primary
            descendant.Material = if descendant.Name == "Head" then Enum.Material.SmoothPlastic else Enum.Material.Metal
        end
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        local marker = Instance.new("Highlight")
        marker.Name = "CBS_SkinAccent"
        marker.FillTransparency = 1
        marker.OutlineTransparency = 0.25
        marker.OutlineColor = accent
        marker.DepthMode = Enum.HighlightDepthMode.Occluded
        marker.Parent = character
    end
end

local function snapshot(player)
    local profile = profiles[player] or defaultProfile()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local skins = {}
    for _, skinId in ipairs(Rules.skinIds()) do
        local skin = Rules.skin(skinId)
        table.insert(skins, {
            Id = skinId,
            Name = skin.Name,
            Price = skin.Price,
            Owned = profile.OwnedSkins[skinId] == true,
            Equipped = profile.EquippedSkin == skinId,
        })
    end

    return {
        Ready = worldReady,
        Wave = currentWave,
        Alive = activeEnemies,
        Phase = currentPhase,
        Elite = eliteAlive,
        Credits = profile.Credits,
        DamageLevel = profile.DamageLevel,
        Kills = profile.Kills,
        HighestWave = profile.HighestWave,
        Health = humanoid and humanoid.Health or Rules.playerMaxHealth(),
        MaxHealth = humanoid and humanoid.MaxHealth or Rules.playerMaxHealth(),
        EquippedSkin = profile.EquippedSkin,
        EchoClass = profile.EchoClass,
        EchoActive = echoes[player] ~= nil,
        Skins = skins,
        PersistenceReady = persistenceReady[player] == true,
        Owner = game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId,
    }
end

local function sync(player)
    if player.Parent then
        State:FireClient(player, "Snapshot", snapshot(player))
    end
end

local function syncAll()
    for _, player in ipairs(Players:GetPlayers()) do
        sync(player)
    end
end

local function grantCredits(player, amount)
    local profile = profiles[player]
    if not profile or amount <= 0 then
        return
    end
    profile.Credits += math.floor(amount)
    sync(player)
end

local function spendCredits(player, amount)
    local profile = profiles[player]
    if not profile or amount <= 0 or profile.Credits < amount then
        return false
    end
    profile.Credits -= math.floor(amount)
    sync(player)
    return true
end

local function upgrade(player)
    local profile = profiles[player]
    if not profile then
        return
    end
    local cost = Rules.upgradeCost(profile.DamageLevel)
    if not spendCredits(player, cost) then
        State:FireClient(player, "Toast", "Need " .. tostring(cost) .. " Credits.")
        return
    end
    profile.DamageLevel += 1
    State:FireClient(player, "Toast", "Damage upgraded to LV " .. tostring(profile.DamageLevel))
    sync(player)
end

local function getCharacterParts(player)
    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and root:IsA("BasePart") and humanoid.Health > 0 then
        return character, humanoid, root
    end
end

local function nearestPlayer(position)
    local bestPlayer = nil
    local bestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local _, humanoid, root = getCharacterParts(player)
        if humanoid and root then
            local distance = (root.Position - position).Magnitude
            if distance < bestDistance then
                bestPlayer = player
                bestDistance = distance
            end
        end
    end
    return bestPlayer, bestDistance
end

local function nearestEnemy(position, preferElite)
    local bestModel = nil
    local bestDistance = math.huge
    for model in pairs(enemies) do
        if model.Parent then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                local allowed = not preferElite or model:GetAttribute("Tier") == "Elite"
                if allowed then
                    local distance = (root.Position - position).Magnitude
                    if distance < bestDistance then
                        bestModel = model
                        bestDistance = distance
                    end
                end
            end
        end
    end
    return bestModel, bestDistance
end

local function createEnemy(tier, spawnPosition)
    local stats = Rules.enemyStats(tier)
    if not stats then
        return
    end
    local model = Instance.new("Model")
    model.Name = tier .. "_Enemy"
    model:SetAttribute("CBS_Enemy", true)
    model:SetAttribute("Tier", tier)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2.3, 3.2, 2.3)
    root.Position = spawnPosition + Vector3.new(0, 2, 0)
    root.Transparency = 1
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = false
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = stats.Health
    humanoid.Health = stats.Health
    humanoid.WalkSpeed = stats.Speed
    humanoid.HipHeight = 2
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = false
    humanoid.Parent = model

    local primary = if tier == "Elite" then Color3.fromRGB(209, 42, 55)
        elseif tier == "Tier3" then Color3.fromRGB(148, 82, 205)
        elseif tier == "Tier2" then Color3.fromRGB(63, 145, 219)
        else Color3.fromRGB(92, 105, 122)

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(3, 3.1, 1.9)
    torso.Position = root.Position + Vector3.new(0, 1.7, 0)
    torso.Color = primary
    torso.Material = Enum.Material.Metal
    torso.CanCollide = false
    torso.CanTouch = false
    torso.CanQuery = true
    torso.Massless = true
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2.1, 2.1, 2.1)
    head.Position = root.Position + Vector3.new(0, 4, 0)
    head.Color = primary:Lerp(Color3.new(1, 1, 1), 0.12)
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = false
    head.CanTouch = false
    head.CanQuery = true
    head.Massless = true
    head.Parent = model

    local leftArm = torso:Clone()
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(0.8, 2.8, 0.8)
    leftArm.Position = root.Position + Vector3.new(-1.9, 1.7, 0)
    leftArm.Parent = model

    local rightArm = leftArm:Clone()
    rightArm.Name = "RightArm"
    rightArm.Position = root.Position + Vector3.new(1.9, 1.7, 0)
    rightArm.Parent = model

    local leftLeg = torso:Clone()
    leftLeg.Name = "LeftLeg"
    leftLeg.Size = Vector3.new(1, 3, 1)
    leftLeg.Position = root.Position + Vector3.new(-0.65, -1.4, 0)
    leftLeg.Parent = model

    local rightLeg = leftLeg:Clone()
    rightLeg.Name = "RightLeg"
    rightLeg.Position = root.Position + Vector3.new(0.65, -1.4, 0)
    rightLeg.Parent = model

    for _, child in ipairs({torso, head, leftArm, rightArm, leftLeg, rightLeg}) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = child
        weld.Parent = root
    end

    if tier == "Elite" then
        local highlight = Instance.new("Highlight")
        highlight.Name = "EliteHighlight"
        highlight.FillColor = Color3.fromRGB(255, 55, 68)
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = Color3.fromRGB(255, 215, 220)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = model

        local label = Instance.new("BillboardGui")
        label.Name = "EliteLabel"
        label.Size = UDim2.fromOffset(140, 30)
        label.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
        label.AlwaysOnTop = true
        label.Adornee = head
        label.Parent = head

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Text = "ELITE"
        text.Font = Enum.Font.GothamBlack
        text.TextColor3 = Color3.fromRGB(255, 85, 95)
        text.TextStrokeTransparency = 0.25
        text.TextScaled = true
        text.Parent = label
    end

    model.Parent = ENEMIES

    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    enemies[model] = {
        nextAttack = 0,
    }
    activeEnemies += 1

    humanoid.Died:Connect(function()
        if model:GetAttribute("CBS_Defeated") then
            return
        end
        model:SetAttribute("CBS_Defeated", true)
        activeEnemies = math.max(0, activeEnemies - 1)
        local attackerId = humanoid:GetAttribute("LastAttackerUserId")
        if typeof(attackerId) == "number" then
            local attacker = Players:GetPlayerByUserId(attackerId)
            if attacker and profiles[attacker] then
                profiles[attacker].Kills += 1
                grantCredits(attacker, stats.Reward)
            end
        end
        if tier == "Elite" then
            eliteAlive = false
        end
        enemies[model] = nil
        task.delay(0.2, function()
            if model.Parent then
                model:Destroy()
            end
        end)
        syncAll()
        if activeEnemies == 0 and currentPhase == "ACTIVE" then
            currentPhase = "CLEARED"
            waveToken += 1
            local token = waveToken
            for _, player in ipairs(Players:GetPlayers()) do
                grantCredits(player, Rules.waveReward(currentWave))
                local profile = profiles[player]
                if profile then
                    profile.HighestWave = math.max(profile.HighestWave, currentWave)
                end
            end
            syncAll()
            task.delay(3.5, function()
                if token == waveToken and #Players:GetPlayers() > 0 and activeEnemies == 0 then
                    local next = currentWave + 1
                    currentWave = next
                    currentPhase = "SPAWNING"
                    eliteAlive = false
                    local count = Rules.enemyCount(next)
                    local positions = {
                        Vector3.new(-64, 0, -48),
                        Vector3.new(64, 0, -48),
                        Vector3.new(-76, 0, 0),
                        Vector3.new(76, 0, 0),
                        Vector3.new(-64, 0, 48),
                        Vector3.new(64, 0, 48),
                    }
                    for index = 1, count - 1 do
                        local tierValue = Rules.normalTier(next, index)
                        createEnemy(tierValue, positions[((index - 1) % #positions) + 1])
                    end
                    createEnemy("Elite", positions[((count - 1) % #positions) + 1])
                    eliteAlive = true
                    currentPhase = "ACTIVE"
                    syncAll()
                end
            end)
        end
    end)

    return model
end

local function startFirstWave()
    currentWave = 1
    currentPhase = "SPAWNING"
    eliteAlive = false
    local positions = {
        Vector3.new(-64, 0, -48),
        Vector3.new(64, 0, -48),
        Vector3.new(-76, 0, 0),
        Vector3.new(76, 0, 0),
        Vector3.new(-64, 0, 48),
        Vector3.new(64, 0, 48),
    }
    local count = Rules.enemyCount(currentWave)
    for index = 1, count - 1 do
        createEnemy(Rules.normalTier(currentWave, index), positions[index])
    end
    createEnemy("Elite", positions[count])
    eliteAlive = true
    currentPhase = "ACTIVE"
    syncAll()
end

local function performAttack(player)
    local now = os.clock()
    if now - (attackAt[player] or 0) < Rules.attackCooldown() then
        return
    end

    local character, humanoid, root = getCharacterParts(player)
    if not character or not humanoid or not root then
        return
    end

    local newCombo = if now - (comboAt[player] or 0) <= Rules.comboWindow()
        then math.clamp((combo[player] or 0) + 1, 1, 3)
        else 1
    combo[player] = newCombo
    comboAt[player] = now
    attackAt[player] = now

    local center = root.CFrame * CFrame.new(0, 0, -4)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    overlap.FilterDescendantsInstances = {ENEMIES}
    overlap.MaxParts = 100
    overlap.RespectCanCollide = false

    local bestTarget = nil
    local bestDistance = math.huge
    for _, touched in ipairs(workspace:GetPartBoundsInBox(center, Vector3.new(8, 5, 9), overlap)) do
        local model = touched:FindFirstAncestorOfClass("Model")
        if model and enemies[model] then
            local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
            local targetRoot = model:FindFirstChild("HumanoidRootPart")
            if targetHumanoid and targetRoot and targetHumanoid.Health > 0 then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if distance < bestDistance and distance <= 10 then
                    bestTarget = model
                    bestDistance = distance
                end
            end
        end
    end

    State:FireClient(player, "Attack", newCombo, bestTarget ~= nil)
    if not bestTarget then
        return
    end

    local targetHumanoid = bestTarget:FindFirstChildOfClass("Humanoid")
    local targetRoot = bestTarget:FindFirstChild("HumanoidRootPart")
    if not targetHumanoid or not targetRoot then
        return
    end

    local profile = profiles[player]
    local damage = Rules.baseDamage(newCombo) + ((profile and profile.DamageLevel or 0) * 5)
    targetHumanoid:SetAttribute("LastAttackerUserId", player.UserId)
    targetHumanoid:SetAttribute("LastAttackerAt", workspace:GetServerTimeNow())
    targetHumanoid:TakeDamage(damage)

    local delta = targetRoot.Position - root.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    if horizontal.Magnitude > 0.05 then
        targetRoot.AssemblyLinearVelocity = horizontal.Unit * (newCombo == 3 and 25 or 12) + Vector3.new(0, newCombo == 3 and 12 or 4, 0)
    end

    State:FireClient(player, "Hit", damage)
end

local function performDash(player)
    local now = os.clock()
    if now - (dashAt[player] or 0) < Rules.dashCooldown() then
        return
    end

    local character, humanoid, root = getCharacterParts(player)
    if not character or not humanoid or not root then
        return
    end

    local move = humanoid.MoveDirection
    local direction = Vector3.new(move.X, 0, move.Z)
    if direction.Magnitude < 0.1 then
        local look = root.CFrame.LookVector
        direction = Vector3.new(look.X, 0, look.Z)
    end
    direction = direction.Unit
    dashAt[player] = now

    local vertical = root.AssemblyLinearVelocity.Y
    root.AssemblyLinearVelocity = direction * Rules.dashSpeed() + Vector3.new(0, vertical, 0)
    State:FireClient(player, "Dash", Rules.dashCooldown())
end

local function setSkin(player, skinId)
    local profile = profiles[player]
    if not profile or not Rules.isValidSkin(skinId) or not profile.OwnedSkins[skinId] then
        return false
    end
    profile.EquippedSkin = skinId
    if player.Character then
        applySkin(player, player.Character)
    end
    sync(player)
    return true
end

local function buySkin(player, skinId)
    local profile = profiles[player]
    local skin = if type(skinId) == "string" then Rules.skin(skinId) else nil
    if not profile or not skin or skin.Price <= 0 then
        return
    end
    if profile.OwnedSkins[skinId] then
        setSkin(player, skinId)
        return
    end
    if not spendCredits(player, skin.Price) then
        State:FireClient(player, "Toast", "Need " .. tostring(skin.Price) .. " Credits.")
        return
    end
    profile.OwnedSkins[skinId] = true
    profile.EquippedSkin = skinId
    if player.Character then
        applySkin(player, player.Character)
    end
    State:FireClient(player, "Toast", skin.Name .. " unlocked.")
    sync(player)
end

local function destroyEcho(player, reason)
    local entry = echoes[player]
    if not entry then
        return
    end
    if entry.model and entry.model.Parent then
        entry.model:Destroy()
    end
    echoes[player] = nil
    if player.Parent then
        State:FireClient(player, "Echo", "Dismissed", reason or "Manual")
        sync(player)
    end
end

local function fallbackEcho(classId, friendUserId)
    local model = Instance.new("Model")
    model.Name = "FriendEcho_" .. tostring(friendUserId)
    model:SetAttribute("CBS_Echo", true)
    model:SetAttribute("FriendUserId", friendUserId)
    model:SetAttribute("EchoClass", classId)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2.2, 3.2, 2.2)
    root.Transparency = 1
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = false
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 240
    humanoid.Health = 240
    humanoid.WalkSpeed = 13
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    local colors = {
        Vanguard = Color3.fromRGB(68, 78, 94),
        Striker = Color3.fromRGB(73, 56, 101),
        Guardian = Color3.fromRGB(57, 85, 76),
        Support = Color3.fromRGB(92, 80, 54),
    }
    local accent = {
        Vanguard = Color3.fromRGB(85, 200, 255),
        Striker = Color3.fromRGB(201, 107, 255),
        Guardian = Color3.fromRGB(90, 230, 175),
        Support = Color3.fromRGB(255, 206, 96),
    }
    for name, size, offset in {
        {"Torso", Vector3.new(2.8, 3, 1.8), Vector3.new(0, 1.6, 0)},
        {"Head", Vector3.new(2, 2, 2), Vector3.new(0, 4, 0)},
        {"LeftArm", Vector3.new(0.8, 2.8, 0.8), Vector3.new(-1.7, 1.6, 0)},
        {"RightArm", Vector3.new(0.8, 2.8, 0.8), Vector3.new(1.7, 1.6, 0)},
        {"LeftLeg", Vector3.new(0.9, 3, 0.9), Vector3.new(-0.62, -1.4, 0)},
        {"RightLeg", Vector3.new(0.9, 3, 0.9), Vector3.new(0.62, -1.4, 0)},
    } do
        local body = Instance.new("Part")
        body.Name = name
        body.Size = size
        body.Position = root.Position + offset
        body.Color = colors[classId] or colors.Vanguard
        body.Material = Enum.Material.SmoothPlastic
        body.CanCollide = false
        body.CanTouch = false
        body.CanQuery = true
        body.Massless = true
        body.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = body
        weld.Parent = root
    end

    local core = Instance.new("Part")
    core.Name = "EchoCore"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(0.75, 0.75, 0.75)
    core.Position = root.Position + Vector3.new(0, 2.3, -0.9)
    core.Color = accent[classId] or accent.Vanguard
    core.Material = Enum.Material.Neon
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.Massless = true
    core.Parent = model
    local coreWeld = Instance.new("WeldConstraint")
    coreWeld.Part0 = root
    coreWeld.Part1 = core
    coreWeld.Parent = root

    return model
end

local function makeEcho(player, friendUserId, classId)
    if not Rules.isValidEchoClass(classId) then
        return
    end
    local validFriend = false
    local ok = pcall(function()
        validFriend = player:IsFriendsWithAsync(friendUserId)
    end)
    if not ok or not validFriend then
        State:FireClient(player, "Toast", "Friend verification failed.")
        return
    end

    local online = Players:GetPlayerByUserId(friendUserId)
    if online then
        State:FireClient(player, "Toast", "That friend is already in this server.")
        return
    end

    destroyEcho(player, "Resummon")

    local avatar
    local source = "fallback"
    local avatarOk, avatarResult = pcall(function()
        return Players:CreateHumanoidModelFromUserIdAsync(friendUserId)
    end)
    if avatarOk and avatarResult and avatarResult:IsA("Model") then
        avatar = avatarResult
        source = "avatar"
    else
        avatar = fallbackEcho(classId, friendUserId)
    end

    avatar.Name = "FriendEcho_" .. tostring(friendUserId)
    avatar:SetAttribute("CBS_Echo", true)
    avatar:SetAttribute("FriendUserId", friendUserId)
    avatar:SetAttribute("EchoClass", classId)

    local humanoid = avatar:FindFirstChildOfClass("Humanoid")
    local root = avatar:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        avatar:Destroy()
        avatar = fallbackEcho(classId, friendUserId)
        humanoid = avatar:FindFirstChildOfClass("Humanoid")
        root = avatar:FindFirstChild("HumanoidRootPart")
    end

    for _, descendant in ipairs(avatar:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = descendant.Name ~= "HumanoidRootPart"
            descendant.Massless = true
        elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        end
    end

    local head = avatar:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local tag = Instance.new("BillboardGui")
        tag.Name = "EchoLabel"
        tag.Size = UDim2.fromOffset(160, 28)
        tag.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
        tag.AlwaysOnTop = true
        tag.Adornee = head
        tag.Parent = head
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "FRIEND ECHO • " .. classId
        label.TextColor3 = Color3.fromRGB(95, 215, 255)
        label.TextStrokeTransparency = 0.25
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = tag
    end

    avatar.Parent = COMPANIONS
    local _, _, ownerRoot = getCharacterParts(player)
    if root and root:IsA("BasePart") then
        avatar:PivotTo((ownerRoot and ownerRoot.CFrame or playerSpawn.CFrame) * CFrame.new(-5, 0, 3))
        pcall(function()
            root:SetNetworkOwner(nil)
        end)
    end

    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.AutoRotate = true
        humanoid.MaxHealth = math.max(humanoid.MaxHealth, 200)
        humanoid.Health = humanoid.MaxHealth
    end

    echoes[player] = {
        model = avatar,
        friendUserId = friendUserId,
        classId = classId,
        nextAttack = 0,
        nextHeal = 0,
        source = source,
    }

    State:FireClient(player, "Echo", "Summoned", classId, source)
    sync(player)
end

local function sendFriends(player)
    local ok, pages = pcall(function()
        return Players:GetFriendsAsync(player.UserId)
    end)
    if not ok or not pages then
        State:FireClient(player, "Friends", {})
        State:FireClient(player, "Toast", "Friend list unavailable right now.")
        return
    end

    local friends = {}
    for _, entry in ipairs(pages:GetCurrentPage()) do
        if typeof(entry.Id) == "number" and entry.Id > 0 then
            table.insert(friends, {
                UserId = entry.Id,
                Username = tostring(entry.Username or ""),
                DisplayName = tostring(entry.DisplayName or entry.Username or ""),
                Online = Players:GetPlayerByUserId(entry.Id) ~= nil,
            })
        end
    end
    table.sort(friends, function(a, b)
        return a.DisplayName < b.DisplayName
    end)
    State:FireClient(player, "Friends", friends)
end

local function adminAllowed(player)
    return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function admin(player, command)
    if not adminAllowed(player) or type(command) ~= "string" then
        return
    end
    if command == "Heal" then
        local _, humanoid = getCharacterParts(player)
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
    elseif command == "Credits" then
        grantCredits(player, 1000)
    elseif command == "Clear" then
        waveToken += 1
        for model in pairs(enemies) do
            if model.Parent then
                model:Destroy()
            end
        end
        table.clear(enemies)
        activeEnemies = 0
        eliteAlive = false
        currentPhase = "CLEARED"
        syncAll()
    elseif command == "NextWave" then
        waveToken += 1
        for model in pairs(enemies) do
            if model.Parent then
                model:Destroy()
            end
        end
        table.clear(enemies)
        activeEnemies = 0
        eliteAlive = false
        currentWave += 1
        currentPhase = "SPAWNING"
        local positions = {
            Vector3.new(-64, 0, -48), Vector3.new(64, 0, -48),
            Vector3.new(-76, 0, 0), Vector3.new(76, 0, 0),
            Vector3.new(-64, 0, 48), Vector3.new(64, 0, 48),
        }
        local count = Rules.enemyCount(currentWave)
        for index = 1, count - 1 do
            createEnemy(Rules.normalTier(currentWave, index), positions[((index - 1) % #positions) + 1])
        end
        createEnemy("Elite", positions[((count - 1) % #positions) + 1])
        eliteAlive = true
        currentPhase = "ACTIVE"
        syncAll()
    end
end

local function handleAction(player, action, value, value2)
    if not Rules.isValidEchoClass(action) and not Rules.isValidSkin(action) then
        return
    end
end

local function processAction(player, action, a, b)
    if type(action) ~= "string" then
        return
    end

    if action == "Attack" then
        performAttack(player)
    elseif action == "Dash" then
        performDash(player)
    elseif action == "Upgrade" then
        upgrade(player)
    elseif action == "BuySkin" then
        buySkin(player, a)
    elseif action == "EquipSkin" then
        setSkin(player, a)
    elseif action == "GetFriends" then
        sendFriends(player)
    elseif action == "SummonEcho" then
        if typeof(a) == "number" and type(b) == "string" then
            makeEcho(player, a, b)
        end
    elseif action == "DismissEcho" then
        destroyEcho(player, "Manual")
    elseif action == "SetEchoClass" then
        if type(a) == "string" and Rules.isValidEchoClass(a) and profiles[player] then
            profiles[player].EchoClass = a
            sync(player)
        end
    elseif action == "RequestState" then
        sync(player)
    elseif action == "Admin" then
        admin(player, a)
    elseif action == "Respawn" then
        if not player.Character then
            pcall(function()
                player:LoadCharacter()
            end)
        end
    end
end

local function onCharacterAdded(player, character)
    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 8)
        local humanoid = character:WaitForChild("Humanoid", 8)
        if root and humanoid then
            character:PivotTo(playerSpawn.CFrame + Vector3.new(0, 4, 0))
            humanoid.MaxHealth = Rules.playerMaxHealth()
            humanoid.Health = humanoid.MaxHealth
            humanoid.WalkSpeed = 16
            applySkin(player, character)
            humanoid.Died:Connect(function()
                task.delay(2.5, function()
                    if player.Parent and not player.Character then
                        pcall(function()
                            player:LoadCharacter()
                        end)
                    end
                end)
            end)
        end
        sync(player)
    end)
end

upgradePrompt.Triggered:Connect(function(player)
    upgrade(player)
end)

Action.OnServerEvent:Connect(function(player, action, a, b)
    processAction(player, action, a, b)
end)

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        loadProfile(player)
        player:SetAttribute("CBS_DataReady", true)
        player:SetAttribute("CBS_WorldReady", worldReady)
        player:SetAttribute("CBS_Owner", adminAllowed(player))
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(player, character)
        end)
        if player.Character then
            onCharacterAdded(player, player.Character)
        else
            pcall(function()
                player:LoadCharacter()
            end)
        end
        sync(player)
    end)

    for owner, entry in pairs(echoes) do
        if entry.friendUserId == player.UserId then
            destroyEcho(owner, "FriendJoined")
        end
    end

    if currentWave == 0 and worldReady then
        task.delay(1.2, function()
            if currentWave == 0 and #Players:GetPlayers() > 0 then
                startFirstWave()
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    saveProfile(player)
    destroyEcho(player, "OwnerLeft")
    profiles[player] = nil
    persistenceReady[player] = nil
    attackAt[player] = nil
    dashAt[player] = nil
    combo[player] = nil
    comboAt[player] = nil
end)

buildWorld()

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        loadProfile(player)
        player:SetAttribute("CBS_DataReady", true)
        player:SetAttribute("CBS_WorldReady", worldReady)
        player:SetAttribute("CBS_Owner", adminAllowed(player))
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(player, character)
        end)
        pcall(function()
            player:LoadCharacter()
        end)
        sync(player)
    end)
end

task.delay(1, function()
    if #Players:GetPlayers() > 0 and currentWave == 0 then
        startFirstWave()
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local now = os.clock()

    for model, state in pairs(enemies) do
        if not model.Parent then
            enemies[model] = nil
            activeEnemies = math.max(0, activeEnemies - 1)
        else
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if not humanoid or not root or humanoid.Health <= 0 then
                continue
            end
            local target, distance = nearestPlayer(root.Position)
            if target then
                local _, targetHumanoid, targetRoot = getCharacterParts(target)
                if targetHumanoid and targetRoot then
                    if distance > 4.6 then
                        humanoid:MoveTo(targetRoot.Position)
                    elseif now >= state.nextAttack then
                        state.nextAttack = now + 1.15
                        targetHumanoid:TakeDamage(Rules.enemyStats(model:GetAttribute("Tier") or "Tier1").Damage)
                    end
                end
            end
        end
    end

    for owner, entry in pairs(echoes) do
        local model = entry.model
        if not model or not model.Parent or not owner.Parent then
            destroyEcho(owner, "Invalid")
        else
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            local _, ownerHumanoid, ownerRoot = getCharacterParts(owner)
            if humanoid and root and ownerRoot and ownerHumanoid then
                local followDistance = (root.Position - ownerRoot.Position).Magnitude
                if followDistance > 30 then
                    model:PivotTo(ownerRoot.CFrame * CFrame.new(-5, 0, 3))
                elseif followDistance > 8 then
                    humanoid:MoveTo(ownerRoot.Position - ownerRoot.CFrame.RightVector * 4)
                end

                local classId = entry.classId
                if classId == "Support" and ownerHumanoid.Health < ownerHumanoid.MaxHealth and now >= entry.nextHeal and followDistance <= 18 then
                    entry.nextHeal = now + 4
                    ownerHumanoid.Health = math.min(ownerHumanoid.MaxHealth, ownerHumanoid.Health + 8)
                end

                local preferElite = classId == "Striker"
                local target, distance = nearestEnemy(root.Position, preferElite)
                if not target and preferElite then
                    target, distance = nearestEnemy(root.Position, false)
                end
                if target and distance <= 9 then
                    local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
                    local targetRoot = target:FindFirstChild("HumanoidRootPart")
                    if targetHumanoid and targetRoot and now >= entry.nextAttack then
                        local damage = if classId == "Striker" then 26
                            elseif classId == "Vanguard" then 20
                            elseif classId == "Guardian" then 16
                            else 12
                        entry.nextAttack = now + (if classId == "Vanguard" then 0.9 elseif classId == "Guardian" then 1 else 1.1)
                        targetHumanoid:SetAttribute("LastAttackerUserId", owner.UserId)
                        targetHumanoid:TakeDamage(damage)
                    elseif targetRoot then
                        local delta = root.Position - targetRoot.Position
                        local offset = if delta.Magnitude > 0.05 then delta.Unit * 5 else Vector3.zero
                        humanoid:MoveTo(targetRoot.Position + offset)
                    end
                end
            end
        end
    end

    if math.floor(now * 2) % 2 == 0 then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                sync(player)
            end
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveProfile(player)
    end
end)
