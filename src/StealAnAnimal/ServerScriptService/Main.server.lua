local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("AnimalCatalog"))
local Rules = require(Shared:WaitForChild("GameplayRules"))
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local remotes = ReplicatedStorage:FindFirstChild("StealAnimalRemotes") or Instance.new("Folder")
remotes.Name = "StealAnimalRemotes"
remotes.Parent = ReplicatedStorage

local function remote(name)
    local item = remotes:FindFirstChild(name)
    if not item then
        item = Instance.new("RemoteEvent")
        item.Name = name
        item.Parent = remotes
    end
    return item
end

local notifyRemote = remote("Notify")
local upgradeRemote = remote("RequestUpgrade")
local collectRemote = remote("RequestCollect")

local oldWorld = Workspace:FindFirstChild("StealAnAnimalWorld")
if oldWorld then
    oldWorld:Destroy()
end

local world = Instance.new("Folder")
world.Name = "StealAnAnimalWorld"
world.Parent = Workspace

local basesFolder = Instance.new("Folder")
basesFolder.Name = "PlayerFarms"
basesFolder.Parent = world

local wildlifeFolder = Instance.new("Folder")
wildlifeFolder.Name = "Wildlife"
wildlifeFolder.Parent = world

local guardiansFolder = Instance.new("Folder")
guardiansFolder.Name = "Guardians"
guardiansFolder.Parent = world

local decorationFolder = Instance.new("Folder")
decorationFolder.Name = "Scenery"
decorationFolder.Parent = world

local profiles = {}
local sessionTokens = {}
local saveInProgress = {}
local leaving = {}
local actionCooldowns = {}
local playerBases = {}
local carried = {}
local guardians = {}
local wildRecords = {}
local rng = Random.new(20261020)
local SESSION_LEASE_SECONDS = 180

local function notify(player, message, kind)
    if player and player.Parent == Players then
        notifyRemote:FireClient(player, tostring(message), tostring(kind or "Info"))
    end
end

local function createPart(parent, name, size, cf, color, material, shape, canCollide)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = cf
    item.Color = color
    item.Material = material or Enum.Material.SmoothPlastic
    item.Anchored = true
    item.CanCollide = canCollide == true
    item.CastShadow = true
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    if shape then
        item.Shape = shape
    end
    item.Parent = parent
    return item
end

local function addBall(parent, name, size, position, color, material)
    return createPart(parent, name, size, CFrame.new(position), color, material, Enum.PartType.Ball, false)
end

local function addCylinder(parent, name, size, cf, color, material, canCollide)
    local cylinderSize = Vector3.new(size.Y, size.X, size.Z)
    return createPart(parent, name, cylinderSize, cf * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder, canCollide)
end

local function addLabel(part, title, subtitle, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "AnimalLabel"
    gui.Size = UDim2.fromOffset(190, 58)
    gui.StudsOffset = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 95
    gui.Adornee = part
    gui.Parent = part

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Title"
    nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.Text = title
    nameLabel.TextColor3 = Color3.fromRGB(255, 250, 229)
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.TextScaled = true
    nameLabel.Parent = gui

    local detail = Instance.new("TextLabel")
    detail.Name = "Subtitle"
    detail.Position = UDim2.new(0, 0, 0.55, 0)
    detail.Size = UDim2.new(1, 0, 0.45, 0)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.GothamBold
    detail.Text = subtitle
    detail.TextColor3 = color or Color3.fromRGB(255, 218, 105)
    detail.TextStrokeTransparency = 0.35
    detail.TextScaled = true
    detail.Parent = gui
    return gui
end

local function createAnimalModel(spec, stageName, position, giant)
    local model = Instance.new("Model")
    model.Name = (giant and "Guardian_" or "Animal_") .. spec.Id
    model:SetAttribute("AnimalId", spec.Id)
    model:SetAttribute("Stage", stageName or "Baby")
    local stageIndex = 1
    for index, stage in ipairs(Config.EvolutionStages) do
        if stage.Name == (stageName or "Baby") then
            stageIndex = index
        end
    end
    local scale = giant and 3.25 or Config.EvolutionStages[stageIndex].Scale
    local base = position
    local function point(x, y, z)
        return base + Vector3.new(x * scale, y * scale, z * scale)
    end
    local function ball(name, sx, sy, sz, x, y, z, color)
        return addBall(model, name, Vector3.new(sx * scale, sy * scale, sz * scale), point(x, y, z), color or spec.Color)
    end
    local function block(name, sx, sy, sz, x, y, z, color, rotation)
        return createPart(model, name, Vector3.new(sx * scale, sy * scale, sz * scale), CFrame.new(point(x, y, z)) * (rotation or CFrame.new()), color or spec.Color, Enum.Material.SmoothPlastic, nil, false)
    end

    local core = createPart(model, "ModelRoot", Vector3.new(0.25, 0.25, 0.25), CFrame.new(base), spec.Color, Enum.Material.SmoothPlastic, nil, false)
    core.Transparency = 1
    core.CastShadow = false
    model.PrimaryPart = core

    ball("Body", 1.65, 1.25, 2.0, 0, 1.25, 0)
    ball("Chest", 1.18, 1.15, 1.05, 0, 1.35, -0.62, spec.Accent)
    ball("Head", 1.12, 1.08, 1.05, 0, 2.18, -1.05)
    ball("Muzzle", 0.68, 0.48, 0.52, 0, 1.96, -1.62, spec.Accent)
    ball("EyeLeft", 0.15, 0.18, 0.12, -0.27, 2.32, -1.53, Color3.fromRGB(36, 36, 43))
    ball("EyeRight", 0.15, 0.18, 0.12, 0.27, 2.32, -1.53, Color3.fromRGB(36, 36, 43))
    ball("Nose", 0.19, 0.15, 0.13, 0, 2.02, -1.9, spec.Shape == "Bird" and Color3.fromRGB(255, 145, 47) or Color3.fromRGB(57, 45, 43))

    for _, side in ipairs({ -1, 1 }) do
        ball("Ear", 0.32, (spec.Shape == "Fox" or spec.Shape == "Wolf") and 0.75 or 0.55, 0.24, side * 0.38, 2.8, -0.88, spec.Color)
        ball("LegFront", 0.35, 0.72, 0.38, side * 0.48, 0.48, -0.55, spec.Color)
        ball("LegBack", 0.38, 0.68, 0.4, side * 0.48, 0.45, 0.62, spec.Color)
    end

    if spec.Shape == "Bird" then
        for _, side in ipairs({ -1, 1 }) do
            ball("Wing", 0.42, 0.78, 1.0, side * 0.82, 1.52, 0.05, spec.Accent)
        end
        ball("Crest", 0.18, 0.42, 0.18, 0, 2.9, -0.8, spec.Accent)
    elseif spec.Shape == "Fox" or spec.Shape == "Wolf" or spec.Shape == "Lion" then
        ball("Tail", 0.48, 0.48, 1.2, 0, 1.65, 1.2, spec.Accent)
        if spec.Shape == "Lion" then
            ball("Mane", 1.42, 1.42, 1.2, 0, 2.12, -0.86, spec.Accent)
            ball("Head", 0.88, 0.85, 0.86, 0, 2.22, -1.24, spec.Color)
        end
    elseif spec.Shape == "Deer" or spec.Shape == "Mammoth" or spec.Shape == "Dragon" then
        for _, side in ipairs({ -1, 1 }) do
            local horn = block("Horn", 0.16, spec.Shape == "Mammoth" and 1.1 or 0.8, 0.16, side * 0.32, 3.0, -0.8, spec.Accent, CFrame.Angles(0, 0, math.rad(side * 12)))
            if spec.Shape == "Mammoth" then
                ball("Tusks", 0.2, 0.9, 0.2, side * 0.36, 1.85, -1.62, spec.Accent)
            end
        end
        if spec.Shape == "Dragon" then
            for _, side in ipairs({ -1, 1 }) do
                block("Wing", 0.15, 1.4, 1.4, side * 0.95, 1.9, 0.15, spec.Accent, CFrame.Angles(0, 0, math.rad(side * 35)))
            end
            ball("TailTip", 0.3, 0.3, 0.65, 0, 1.5, 1.85, spec.Accent)
        end
    elseif spec.Shape == "Turtle" then
        ball("Shell", 1.45, 0.82, 1.55, 0, 1.8, 0.1, spec.Accent)
    elseif spec.Shape == "Elephant" then
        block("Trunk", 0.32, 0.82, 0.34, 0, 1.58, -1.85, spec.Accent, CFrame.Angles(math.rad(18), 0, 0))
        for _, side in ipairs({ -1, 1 }) do
            ball("ElephantEar", 0.62, 0.8, 0.18, side * 0.67, 2.15, -0.92, spec.Accent)
        end
    elseif spec.Shape == "Frog" then
        for _, side in ipairs({ -1, 1 }) do
            ball("EyeBulge", 0.32, 0.35, 0.32, side * 0.35, 2.65, -1.22, spec.Accent)
            ball("EyePupil", 0.12, 0.14, 0.1, side * 0.35, 2.67, -1.43, Color3.fromRGB(35, 45, 36))
        end
    elseif spec.Shape == "Hedgehog" then
        for index = 1, 7 do
            ball("Quill", 0.16, 0.55, 0.16, math.cos(index) * 0.48, 2.0, math.sin(index) * 0.48, spec.Accent)
        end
    elseif spec.Shape == "Reptile" then
        ball("Tail", 0.42, 0.4, 1.25, 0, 1.05, 1.25, spec.Accent)
        for index = 1, 3 do
            ball("BackSpine", 0.18, 0.24, 0.18, 0, 2.0, -0.1 + index * 0.36, spec.Accent)
        end
    end

    model.Parent = Workspace
    model:PivotTo(CFrame.new(base))
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
        end
    end
    return model
end

local function stageFor(animal, now)
    local age = math.max(0, now - (tonumber(animal.BornAt) or now))
    local stage, index = Rules.StageForAge(age, Config)
    return stage, index
end

local function incomeFor(animal, now)
    local spec = Catalog.Get(animal.Id)
    if not spec then
        return 0
    end
    local _, stageIndex = stageFor(animal, now)
    return Rules.AnimalIncome(spec.Income, stageIndex, Config)
end

local function profileIncome(profile, now)
    local total = 0
    for _, animal in ipairs(profile.BarnAnimals) do
        total += incomeFor(animal, now)
    end
    return total
end

local function offlineIncome(profile, fromTime, toTime)
    local total = 0
    for _, animal in ipairs(profile.BarnAnimals) do
        local spec = Catalog.Get(animal.Id)
        if spec then
            local bornAt = tonumber(animal.BornAt) or toTime
            local startAge = math.max(0, fromTime - bornAt)
            local endAge = math.max(0, toTime - bornAt)
            for index, stage in ipairs(Config.EvolutionStages) do
                local nextStage = Config.EvolutionStages[index + 1]
                local segmentStart = math.max(startAge, stage.AgeSeconds)
                local segmentEnd = math.min(endAge, nextStage and nextStage.AgeSeconds or endAge)
                if segmentEnd > segmentStart then
                    total += Rules.AnimalIncome(spec.Income, index, Config) * (segmentEnd - segmentStart)
                end
            end
        end
    end
    return math.floor(total)
end

local function defaultProfile()
    return {
        Coins = 0,
        Speed = 0,
        BarnBank = 0,
        BarnAnimals = {},
        LastIncomeAt = os.time(),
    }
end

local function sanitizeProfile(raw)
    local data = defaultProfile()
    if type(raw) ~= "table" then
        return data
    end
    local function safeInteger(value, minimum, maximum, fallback)
        local numberValue = tonumber(value)
        if type(numberValue) ~= "number" or numberValue ~= numberValue or numberValue == math.huge or numberValue == -math.huge then
            return fallback
        end
        return math.clamp(math.floor(numberValue), minimum, maximum)
    end
    data.Coins = safeInteger(raw.Coins, 0, Config.CoinsLimit, 0)
    data.Speed = safeInteger(raw.Speed, 0, Config.MaxSpeedLevel, 0)
    data.BarnBank = safeInteger(raw.BarnBank, 0, Config.CoinsLimit, 0)
    data.LastIncomeAt = safeInteger(raw.LastIncomeAt, 0, 2147483647, os.time()))
    if type(raw.BarnAnimals) == "table" then
        for index, entry in ipairs(raw.BarnAnimals) do
            if index > Config.BaseSlots then
                break
            end
            if type(entry) == "table" and Catalog.Get(entry.Id) then
                local bornAt = math.max(0, math.floor(tonumber(entry.BornAt) or os.time()))
                local stage = Rules.StageForAge(math.max(0, os.time() - bornAt), Config)
                table.insert(data.BarnAnimals, {
                    Uid = tostring(entry.Uid or (entry.Id .. "_" .. tostring(index))),
                    Id = entry.Id,
                    BornAt = bornAt,
                    Stage = stage.Name,
                })
            end
        end
    end
    return data
end

local function snapshot(profile)
    local data = {
        Coins = profile.Coins,
        Speed = profile.Speed,
        BarnBank = profile.BarnBank,
        LastIncomeAt = profile.LastIncomeAt,
        BarnAnimals = {},
    }
    for _, animal in ipairs(profile.BarnAnimals) do
        table.insert(data.BarnAnimals, { Uid = animal.Uid, Id = animal.Id, BornAt = animal.BornAt })
    end
    return data
end

local function acquireSession(player)
    local key = "u_" .. tostring(player.UserId)
    local token = HttpService:GenerateGUID(false)
    for attempt = 1, 5 do
        local ok, record = pcall(function()
            return Store:UpdateAsync(key, function(current)
                local now = os.time()
                if type(current) ~= "table" then
                    current = snapshot(defaultProfile())
                end
                local lease = current._Session
                if type(lease) == "table"
                    and lease.Token ~= token
                    and (tonumber(lease.ExpiresAt) or 0) > now then
                    return nil
                end
                local nextRecord = {}
                for field, value in pairs(current) do
                    nextRecord[field] = value
                end
                nextRecord._Session = {
                    Token = token,
                    ExpiresAt = now + SESSION_LEASE_SECONDS,
                    JobId = game.JobId,
                }
                return nextRecord
            end)
        end)
        if ok and type(record) == "table"
            and type(record._Session) == "table"
            and record._Session.Token == token then
            sessionTokens[player] = token
            return record
        end
        if not ok then
            warn("[StealAnAnimal] Profile lock failed: " .. tostring(record))
            return nil, "unavailable"
        end
        if attempt < 5 then
            task.wait(attempt * 2)
        end
    end
    return nil, "locked"
end

local function saveProfile(player)
    while saveInProgress[player] do
        task.wait(0.05)
    end
    local profile = profiles[player]
    local token = sessionTokens[player]
    if not profile or not token or profile.Persistent == false then
        return false
    end
    saveInProgress[player] = true
    local data = snapshot(profile)
    local ok, result = pcall(function()
        return Store:UpdateAsync("u_" .. tostring(player.UserId), function(current)
            local lease = type(current) == "table" and current._Session
            if type(lease) ~= "table" or lease.Token ~= token then
                return nil
            end
            local nextRecord = {}
            for field, value in pairs(data) do
                nextRecord[field] = value
            end
            nextRecord._Session = {
                Token = token,
                ExpiresAt = os.time() + SESSION_LEASE_SECONDS,
                JobId = game.JobId,
            }
            return nextRecord
        end)
    end)
    saveInProgress[player] = nil
    if not ok then
        warn("[StealAnAnimal] Profile save failed: " .. tostring(result))
        return false
    end
    if type(result) ~= "table" or type(result._Session) ~= "table" or result._Session.Token ~= token then
        profile.Persistent = false
        sessionTokens[player] = nil
        warn("[StealAnAnimal] Profile session lock was lost for " .. tostring(player.UserId))
        if player.Parent == Players and not leaving[player] then
            notify(player, "Seu bloqueio de salvamento foi perdido. A sessão será encerrada para proteger seus dados.", "Error")
            player:Kick("O bloqueio de salvamento foi perdido. Entre novamente para proteger seu progresso.")
        end
        return false
    end
    return true
end

local function releaseSession(player)
    local token = sessionTokens[player]
    if not token then
        return
    end
    while saveInProgress[player] do
        task.wait(0.05)
    end
    saveInProgress[player] = true
    pcall(function()
        Store:UpdateAsync("u_" .. tostring(player.UserId), function(current)
            local lease = type(current) == "table" and current._Session
            if type(lease) ~= "table" or lease.Token ~= token then
                return nil
            end
            local nextRecord = {}
            for field, value in pairs(current) do
                if field ~= "_Session" then
                    nextRecord[field] = value
                end
            end
            return nextRecord
        end)
    end)
    saveInProgress[player] = nil
    sessionTokens[player] = nil
end

local function allowAction(player, action, cooldown)
    local now = os.clock()
    local actions = actionCooldowns[player]
    if not actions then
        actions = {}
        actionCooldowns[player] = actions
    end
    local previous = actions[action] or 0
    if now - previous < cooldown then
        return false
    end
    actions[action] = now
    return true
end

local function createBase(index)
    local angle = (index - 1) * math.pi * 2 / 8
    local center = Vector3.new(math.cos(angle) * 63, 0, math.sin(angle) * 63)
    local base = Instance.new("Model")
    base.Name = "Farm_" .. tostring(index)
    base:SetAttribute("BaseIndex", index)
    base:SetAttribute("OwnerUserId", 0)
    base.Parent = basesFolder

    createPart(base, "Floor", Vector3.new(34, 1, 31), CFrame.new(center + Vector3.new(0, -0.3, 0)), Color3.fromRGB(111, 171, 83), Enum.Material.Grass, nil, true)
    createPart(base, "BarnBack", Vector3.new(20, 10, 1), CFrame.new(center + Vector3.new(0, 5, 9)), Color3.fromRGB(174, 107, 65), Enum.Material.WoodPlanks, nil, true)
    createPart(base, "BarnLeft", Vector3.new(1, 10, 15), CFrame.new(center + Vector3.new(-9.5, 5, 1.5)), Color3.fromRGB(196, 132, 81), Enum.Material.WoodPlanks, nil, true)
    createPart(base, "BarnRight", Vector3.new(1, 10, 15), CFrame.new(center + Vector3.new(9.5, 5, 1.5)), Color3.fromRGB(196, 132, 81), Enum.Material.WoodPlanks, nil, true)
    createPart(base, "BarnRoof", Vector3.new(22, 1.2, 17), CFrame.new(center + Vector3.new(0, 10.3, 1.5)) * CFrame.Angles(0, 0, math.rad(2)), Color3.fromRGB(112, 61, 54), Enum.Material.Slate, nil, true)
    createPart(base, "BarnSign", Vector3.new(10, 2, 0.35), CFrame.new(center + Vector3.new(0, 7.5, -6.7)), Color3.fromRGB(75, 52, 42), Enum.Material.Wood, nil, false)
    local sign = base.BarnSign
    addLabel(sign, "SUA FAZENDA", "Bebês crescem aqui", Color3.fromRGB(255, 218, 105))

    local display = Instance.new("Folder")
    display.Name = "StoredAnimals"
    display.Parent = base
    local offsets = {
        Vector3.new(-5.5, 0.35, -4), Vector3.new(0, 0.35, -4), Vector3.new(5.5, 0.35, -4),
        Vector3.new(-5.5, 0.35, 2), Vector3.new(0, 0.35, 2), Vector3.new(5.5, 0.35, 2),
    }
    for slotIndex, offset in ipairs(offsets) do
        local pad = createPart(display, "Slot_" .. tostring(slotIndex), Vector3.new(5.1, 0.25, 5.1), CFrame.new(center + offset), Color3.fromRGB(235, 222, 183), Enum.Material.Sand, nil, false)
        pad:SetAttribute("SlotIndex", slotIndex)
        addLabel(pad, "ESPAÇO " .. tostring(slotIndex), "VAZIO", Color3.fromRGB(255, 218, 105))
    end

    local deposit = createPart(base, "DepositPad", Vector3.new(7, 0.45, 4), CFrame.new(center + Vector3.new(-12, 0.35, -8)), Color3.fromRGB(78, 235, 128), Enum.Material.Neon, nil, false)
    addLabel(deposit, "GUARDAR ANIMAL", "Leve o bebê para casa", Color3.fromRGB(255, 255, 230))
    local depositPrompt = Instance.new("ProximityPrompt")
    depositPrompt.Name = "DepositPrompt"
    depositPrompt.ActionText = "GUARDAR"
    depositPrompt.ObjectText = "Sua fazenda"
    depositPrompt.HoldDuration = Config.DepositHoldDuration
    depositPrompt.MaxActivationDistance = 12
    depositPrompt.RequiresLineOfSight = false
    depositPrompt:SetAttribute("InteractionType", "DepositAnimal")
    depositPrompt.Parent = deposit

    local collect = createPart(base, "CollectPad", Vector3.new(7, 0.45, 4), CFrame.new(center + Vector3.new(12, 0.35, -8)), Color3.fromRGB(255, 203, 65), Enum.Material.Neon, nil, false)
    addLabel(collect, "COLETAR MOEDAS", "Renda dos animais", Color3.fromRGB(255, 255, 230))
    local collectPrompt = Instance.new("ProximityPrompt")
    collectPrompt.Name = "CollectPrompt"
    collectPrompt.ActionText = "COLETAR"
    collectPrompt.ObjectText = "Moedas da fazenda"
    collectPrompt.HoldDuration = Config.CollectHoldDuration
    collectPrompt.MaxActivationDistance = 12
    collectPrompt.RequiresLineOfSight = false
    collectPrompt:SetAttribute("InteractionType", "CollectIncome")
    collectPrompt.Parent = collect

    for _, fence in ipairs({
        { Vector3.new(0, 0.7, -15), Vector3.new(34, 1.4, 0.6) },
        { Vector3.new(-17, 0.7, 0), Vector3.new(0.6, 1.4, 31) },
        { Vector3.new(17, 0.7, 0), Vector3.new(0.6, 1.4, 31) },
    }) do
        createPart(base, "WhiteFence", fence[2], CFrame.new(center + fence[1]), Color3.fromRGB(242, 233, 204), Enum.Material.WoodPlanks, nil, true)
    end
    base.PrimaryPart = base.Floor
    return base
end

local function buildTree(parent, position, biome, index)
    local trunkHeight = rng:NextNumber(5, 10)
    addCylinder(parent, "TreeTrunk", Vector3.new(rng:NextNumber(1.2, 2), trunkHeight, rng:NextNumber(1.2, 2)), CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), Color3.fromRGB(113, 76, 49), Enum.Material.Wood, true)
    if biome.Id == "Frost" then
        for layer = 1, 3 do
            createPart(parent, "SnowPine", Vector3.new(1, 4.2, 1), CFrame.new(position + Vector3.new(0, trunkHeight + layer * 1.4, 0)) * CFrame.Angles(0, 0, 0), Color3.fromRGB(206, 235, 250), Enum.Material.Ice, Enum.PartType.Ball, false)
        end
    elseif biome.Id == "Volcano" then
        for layer = 1, 3 do
            addBall(parent, "EmberCanopy", Vector3.new(3.5, 2.8, 3.5), position + Vector3.new(0, trunkHeight + layer * 1.1, 0), layer == 2 and biome.Accent or Color3.fromRGB(111, 67, 63), Enum.Material.Slate)
        end
    elseif biome.Id == "Wetlands" then
        addBall(parent, "MossCanopy", Vector3.new(7, 3.5, 7), position + Vector3.new(0, trunkHeight, 0), Color3.fromRGB(70, 133, 108), Enum.Material.Grass)
        addBall(parent, "MossCanopy", Vector3.new(5, 3, 5), position + Vector3.new(2.5, trunkHeight + 1, 0), biome.Accent, Enum.Material.Grass)
    else
        addBall(parent, "TreeCanopy", Vector3.new(7, 5.5, 7), position + Vector3.new(0, trunkHeight, 0), biome.Id == "Savanna" and Color3.fromRGB(194, 165, 75) or Color3.fromRGB(68, 151, 82), Enum.Material.Grass)
        addBall(parent, "TreeCanopy", Vector3.new(5, 4.2, 5), position + Vector3.new(2.5, trunkHeight + 1, 0), biome.Accent, Enum.Material.Grass)
    end
end

local function buildScenery()
    Lighting.ClockTime = 14
    Lighting.Brightness = 2.2
    Lighting.GlobalShadows = true
    Lighting.EnvironmentDiffuseScale = 0.45
    Lighting.EnvironmentSpecularScale = 0.35
    Lighting.Ambient = Color3.fromRGB(132, 147, 135)
    Lighting.OutdoorAmbient = Color3.fromRGB(176, 192, 170)
    Lighting.FogColor = Color3.fromRGB(192, 220, 199)
    Lighting.FogStart = 500
    Lighting.FogEnd = 1550

    createPart(world, "HubGround", Vector3.new(210, 1, 210), CFrame.new(0, -1, 0), Color3.fromRGB(112, 185, 88), Enum.Material.Grass, nil, true)
    createPart(world, "MainPath", Vector3.new(1120, 0.35, 12), CFrame.new(560, -0.2, 0), Color3.fromRGB(207, 185, 139), Enum.Material.Cobblestone, nil, true)
    createPart(world, "HubFountainBase", Vector3.new(18, 1, 18), CFrame.new(0, 0, 0), Color3.fromRGB(225, 221, 190), Enum.Material.Marble, nil, true)
    addCylinder(world, "HubFountain", Vector3.new(9, 2.2, 9), CFrame.new(0, 1.4, 0), Color3.fromRGB(90, 194, 221), Enum.Material.Glass, false)
    addBall(world, "FountainGem", Vector3.new(3.5, 3.5, 3.5), Vector3.new(0, 4.2, 0), Color3.fromRGB(115, 234, 255), Enum.Material.Neon)

    for _, biome in ipairs(Config.Biomes) do
        createPart(world, biome.Id .. "Ground", Vector3.new(150, 1, 180), CFrame.new(biome.CenterX, -0.5, 0), biome.Ground, biome.Material, nil, true)
        createPart(world, biome.Id .. "Path", Vector3.new(150, 0.32, 12), CFrame.new(biome.CenterX, -0.15, 0), Color3.fromRGB(218, 199, 157), Enum.Material.Cobblestone, nil, true)
        createPart(world, biome.Id .. "ArchTop", Vector3.new(25, 2, 2), CFrame.new(biome.CenterX - 63, 13, 0), biome.Accent, Enum.Material.Neon, nil, false)
        for _, side in ipairs({ -1, 1 }) do
            createPart(world, biome.Id .. "ArchPost", Vector3.new(2, 14, 2), CFrame.new(biome.CenterX - 63, 6, side * 11.5), biome.Accent, Enum.Material.SmoothPlastic, nil, false)
        end
        local sign = createPart(world, biome.Id .. "Sign", Vector3.new(18, 3, 0.5), CFrame.new(biome.CenterX - 63, 10, -0.1), Color3.fromRGB(45, 52, 47), Enum.Material.Wood, nil, false)
        addLabel(sign, biome.Name, "EXPLORE • ROUBE • FUJA", biome.Accent)

        for index = 1, 12 do
            local x = biome.CenterX + rng:NextNumber(-62, 62)
            local z = rng:NextNumber(-76, 76)
            if math.abs(z) > 13 and math.abs(x - biome.CenterX) > 15 then
                if index % 3 == 0 then
                    local rockSize = rng:NextNumber(2.2, 5.2)
                    addBall(decorationFolder, biome.Id .. "Rock", Vector3.new(rockSize * 1.4, rockSize, rockSize), Vector3.new(x, rockSize * 0.35, z), biome.Id == "Frost" and Color3.fromRGB(185, 215, 236) or Color3.fromRGB(101, 111, 98), biome.Id == "Frost" and Enum.Material.Ice or Enum.Material.Rock)
                elseif index % 3 == 1 then
                    buildTree(decorationFolder, Vector3.new(x, 0, z), biome, index)
                else
                    local flowerColor = index % 2 == 0 and biome.Accent or Color3.fromRGB(255, 154, 186)
                    addBall(decorationFolder, biome.Id .. "Flower", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, 0.8, z), flowerColor, Enum.Material.Neon)
                    addCylinder(decorationFolder, biome.Id .. "FlowerStem", Vector3.new(0.25, 1.4, 0.25), CFrame.new(x, 0.25, z), Color3.fromRGB(64, 137, 73), Enum.Material.Grass, false)
                end
            end
        end
        for index = 1, 4 do
            local crystal = addCylinder(decorationFolder, biome.Id .. "Crystal", Vector3.new(2, rng:NextNumber(4, 8), 2), CFrame.new(biome.CenterX + rng:NextNumber(-42, 42), 2.4, rng:NextNumber(-60, 60)) * CFrame.Angles(0, 0, math.rad(rng:NextInteger(-12, 12))), biome.Accent, Enum.Material.Neon, false)
            crystal.Transparency = 0.12
        end
    end
end

local function updatePlayerAttributes(player)
    local profile = profiles[player]
    if not profile then
        return
    end
    local now = os.time()
    player:SetAttribute("Coins", profile.Coins)
    player:SetAttribute("SpeedLevel", profile.Speed)
    player:SetAttribute("BarnBank", profile.BarnBank)
    player:SetAttribute("BarnAnimalCount", #profile.BarnAnimals)
    player:SetAttribute("BarnCapacity", Config.BaseSlots)
    player:SetAttribute("BarnIncomeRate", profileIncome(profile, now))
    player:SetAttribute("CarryingAnimal", carried[player] ~= nil)
    local baseSpeed = Config.BaseWalkSpeed + profile.Speed * Config.SpeedPerLevel
    local carry = carried[player]
    if carry then
        local speed = Rules.CarrySpeed(baseSpeed, carry.Spec.Weight, Config)
        baseSpeed = speed or Config.CarrySpeedMinimum
    end
    player:SetAttribute("EffectiveWalkSpeed", baseSpeed)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = baseSpeed
    end
end

local function clearCarry(player)
    local carry = carried[player]
    if not carry then
        return
    end
    carried[player] = nil
    if carry.Model and carry.Model.Parent then
        carry.Model:Destroy()
    end
    player:SetAttribute("CarryingAnimal", false)
    updatePlayerAttributes(player)
end

local function renderBarn(player)
    local profile = profiles[player]
    local base = playerBases[player]
    if not profile or not base then return end
    local display = base:FindFirstChild("StoredAnimals")
    if not display then return end
    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^StoredAnimal_") then
            child:Destroy()
        end
    end
    local slots = {}
    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("BasePart") and child.Name:match("^Slot_") then
            table.insert(slots, child)
        end
    end
    table.sort(slots, function(a, b)
        return (a:GetAttribute("SlotIndex") or 0) < (b:GetAttribute("SlotIndex") or 0)
    end)
    local now = os.time()
    for index, slot in ipairs(slots) do
        local animal = profile.BarnAnimals[index]
        local gui = slot:FindFirstChild("AnimalLabel")
        local title = gui and gui:FindFirstChild("Title", true)
        local subtitle = gui and gui:FindFirstChild("Subtitle", true)
        if animal then
            local spec = Catalog.Get(animal.Id)
            local stage, stageIndex = stageFor(animal, now)
            if spec then
                local model = createAnimalModel(spec, stage.Name, slot.Position + Vector3.new(0, 0.05, 0), false)
                model.Name = "StoredAnimal_" .. tostring(index)
                model.Parent = display
                local income = Rules.AnimalIncome(spec.Income, stageIndex, Config)
                addLabel(model.PrimaryPart, spec.Name, stage.DisplayName .. " • +" .. tostring(income) .. "/s", spec.Accent)
                slot.Color = spec.Color
                slot.Transparency = 0.25
                if title then title.Text = spec.Name end
                if subtitle then subtitle.Text = stage.DisplayName .. " • +" .. tostring(income) .. "/s" end
            end
        else
            slot.Color = Color3.fromRGB(235, 222, 183)
            slot.Transparency = 0
            if title then title.Text = "ESPAÇO " .. tostring(index) end
            if subtitle then subtitle.Text = "VAZIO" end
        end
    end
    updatePlayerAttributes(player)
end

local function assignBase(player)
    for _, base in ipairs(basesFolder:GetChildren()) do
        if base:GetAttribute("OwnerUserId") == 0 then
            base:SetAttribute("OwnerUserId", player.UserId)
            local sign = base:FindFirstChild("BarnSign")
            if sign then
                local oldGui = sign:FindFirstChild("AnimalLabel")
                if oldGui then oldGui:Destroy() end
                addLabel(sign, player.DisplayName .. "'S FARM", "SEUS ANIMAIS CRESCEM AQUI", Color3.fromRGB(255, 218, 105))
            end
            playerBases[player] = base
            local spawn = base:FindFirstChild("Floor")
            if spawn and player.Character then
                player.Character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 4, 0)))
            end
            return base
        end
    end
    return nil
end

local function releaseBase(player)
    local base = playerBases[player]
    if base then
        base:SetAttribute("OwnerUserId", 0)
        playerBases[player] = nil
        local sign = base:FindFirstChild("BarnSign")
        if sign then
            local gui = sign:FindFirstChild("AnimalLabel")
            if gui then gui:Destroy() end
            addLabel(sign, "SUA FAZENDA", "Bebês crescem aqui", Color3.fromRGB(255, 218, 105))
        end
    end
end

local function spawnWild(spec)
    local biome
    for _, entry in ipairs(Config.Biomes) do
        if entry.Id == spec.Biome then biome = entry break end
    end
    if not biome then return end
    local position = Vector3.new(biome.CenterX + rng:NextNumber(-35, 35), 0.15, rng:NextNumber(-42, 42))
    local model = createAnimalModel(spec, "Baby", position, false)
    model.Parent = wildlifeFolder
    local root = model.PrimaryPart
    addLabel(root, spec.Name, spec.Rarity .. " • $" .. tostring(spec.Income) .. "/s base", spec.Accent)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "StealPrompt"
    prompt.ActionText = "ROUBAR"
    prompt.ObjectText = spec.Name .. " • BEBÊ"
    prompt.HoldDuration = Config.CaptureHoldDuration
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("InteractionType", "StealAnimal")
    prompt:SetAttribute("AnimalId", spec.Id)
    prompt.Parent = root
    wildRecords[model] = spec
end

local function makeGuardian(spec, biome)
    local position = Vector3.new(biome.CenterX - 48, -0.12, 0)
    local model = createAnimalModel(spec, "Adult", position, true)
    model.Name = "Guardian_" .. biome.Id
    model.Parent = guardiansFolder
    addLabel(model.PrimaryPart, "GUARDIÃO " .. string.upper(spec.Name), "ELE VAI PERSEGUIR QUEM CARREGA UM ANIMAL", biome.Accent)
    table.insert(guardians, { Model = model, Home = CFrame.new(position), Biome = biome, Spec = spec })
end

local function loadProfile(player)
    local raw, reason = acquireSession(player)
    if not raw then
        if reason == "locked" then
            notify(player, "Seu perfil ainda está ativo em outro servidor. Aguarde alguns segundos e tente novamente.", "Warning")
            player:Kick("Seu perfil ainda está ativo em outro servidor. Entre novamente em instantes.")
        else
            notify(player, "Não foi possível carregar seu salvamento. Tente novamente.", "Error")
            player:Kick("Não foi possível carregar seus dados com segurança. Tente entrar novamente.")
        end
        return false
    end
    if player.Parent ~= Players then
        releaseSession(player)
        return false
    end
    local profile = sanitizeProfile(raw)
    profile.Persistent = true
    local now = os.time()
    local elapsed = math.clamp(now - profile.LastIncomeAt, 0, Config.OfflineIncomeCapSeconds)
    local earnedOffline = offlineIncome(profile, now - elapsed, now)
    profile.BarnBank = math.clamp(profile.BarnBank + earnedOffline, 0, Config.CoinsLimit)
    profile.LastIncomeAt = now
    if player.Parent ~= Players then
        profiles[player] = profile
        saveProfile(player)
        releaseSession(player)
        profiles[player] = nil
        return false
    end
    profiles[player] = profile
    updatePlayerAttributes(player)
    if earnedOffline > 0 then
        notify(player, "Seus animais renderam +" .. tostring(earnedOffline) .. " moedas enquanto você estava fora.", "Success")
    end
    return true
end

local function captureAnimal(player, prompt)
    if not profiles[player] or leaving[player] or carried[player] or player:GetAttribute("RebirthInProgress") then
        if carried[player] then
            notify(player, "Você só pode carregar um animal por vez.", "Warning")
        end
        return
    end
    local model = prompt.Parent and prompt.Parent:FindFirstAncestorOfClass("Model")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local animalRoot = model and model.PrimaryPart
    if not root or not animalRoot or (root.Position - animalRoot.Position).Magnitude > 12 then
        return
    end
    local spec = model and wildRecords[model]
    if not spec or not model:IsDescendantOf(wildlifeFolder) then
        return
    end
    wildRecords[model] = nil
    carried[player] = { Spec = spec, Model = model }
    prompt.Enabled = false
    model.Parent = world
    task.delay(Config.AnimalRespawnSeconds, function()
        spawnWild(spec)
    end)
    player:SetAttribute("CarryingAnimal", true)
    updatePlayerAttributes(player)
    notify(player, "Você roubou " .. spec.Name .. "! Corra para sua fazenda antes que o guardião alcance você.", "Success")
end

local function depositAnimal(player, prompt)
    local triggerPart = prompt.Parent
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not triggerPart or not triggerPart:IsA("BasePart") or not root
        or (root.Position - triggerPart.Position).Magnitude > 15 then
        return
    end
    local base = triggerPart:FindFirstAncestorOfClass("Model")
    if not profiles[player] or leaving[player] or not base
        or playerBases[player] ~= base or base:GetAttribute("OwnerUserId") ~= player.UserId then
        return
    end
    local carry = carried[player]
    if not carry then
        notify(player, "Roube um animal selvagem primeiro.", "Warning")
        return
    end
    local profile = profiles[player]
    if #profile.BarnAnimals >= Config.BaseSlots then
        notify(player, "Seu celeiro está cheio.", "Warning")
        return
    end
    local animal = {
        Uid = tostring(player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(#profile.BarnAnimals + 1),
        Id = carry.Spec.Id,
        BornAt = os.time(),
        Stage = "Baby",
    }
    table.insert(profile.BarnAnimals, animal)
    carried[player] = nil
    if carry.Model and carry.Model.Parent then
        carry.Model:Destroy()
    end
    player:SetAttribute("CarryingAnimal", false)
    renderBarn(player)
    notify(player, carry.Spec.Name .. " chegou em casa como bebê! Cada evolução aumenta sua renda em 50%.", "Success")
end

local function collectIncome(player, prompt)
    local triggerPart = prompt.Parent
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not triggerPart or not triggerPart:IsA("BasePart") or not root
        or (root.Position - triggerPart.Position).Magnitude > 15 then
        return
    end
    local base = triggerPart:FindFirstAncestorOfClass("Model")
    if not profiles[player] or leaving[player] or not base
        or playerBases[player] ~= base or base:GetAttribute("OwnerUserId") ~= player.UserId then
        return
    end
    local profile = profiles[player]
    local amount = math.floor(profile.BarnBank)
    if amount <= 0 then
        notify(player, "O banco do celeiro está vazio. Seus animais continuam produzindo moedas.", "Info")
        return
    end
    local credited = math.min(amount, Config.CoinsLimit - profile.Coins)
    if credited <= 0 then
        notify(player, "Sua carteira atingiu o limite de moedas.", "Warning")
        return
    end
    profile.Coins += credited
    profile.BarnBank -= credited
    updatePlayerAttributes(player)
    notify(player, "Você coletou +" .. tostring(credited) .. " moedas!", "Success")
end

local function onPrompt(prompt, player)
    if not profiles[player] or leaving[player] then
        return
    end
    local interaction = prompt:GetAttribute("InteractionType")
    if interaction ~= "StealAnimal" and interaction ~= "DepositAnimal" and interaction ~= "CollectIncome" then
        return
    end
    if not allowAction(player, interaction, 0.45) then
        return
    end
    if interaction == "StealAnimal" then
        captureAnimal(player, prompt)
    elseif interaction == "DepositAnimal" then
        depositAnimal(player, prompt)
    elseif interaction == "CollectIncome" then
        collectIncome(player, prompt)
    end
end

local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local ok, err = pcall(onPrompt, prompt, player)
    if not ok then
        warn("[StealAnAnimal] Interaction failed: " .. tostring(err))
        notify(player, "A interação falhou com segurança. Tente novamente.", "Error")
    end
end)

upgradeRemote.OnServerEvent:Connect(function(player)
    local profile = profiles[player]
    if not profile or leaving[player] or not allowAction(player, "upgradeRemote", 0.8) then return end
    local cost = Rules.UpgradeCost(profile.Speed, Config)
    if not cost then
        notify(player, "Sua velocidade já chegou ao nível máximo.", "Info")
        return
    end
    if profile.Coins < cost then
        notify(player, "Você precisa de " .. tostring(cost) .. " moedas para melhorar a velocidade.", "Warning")
        return
    end
    profile.Coins -= cost
    profile.Speed += 1
    updatePlayerAttributes(player)
    notify(player, "Velocidade melhorada para o nível " .. tostring(profile.Speed) .. ".", "Success")
end)

collectRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or not allowAction(player, "collectRemote", 0.6) then return end
    local base = playerBases[player]
    local pad = base and base:FindFirstChild("CollectPad")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not pad or not root or (root.Position - pad.Position).Magnitude > 14 then
        notify(player, "Fique perto da área de coleta da sua própria fazenda.", "Warning")
        return
    end
    collectIncome(player, { Parent = pad })
end)

buildScenery()
for index = 1, 8 do
    createBase(index)
end
for _, spec in ipairs(Catalog.All()) do
    spawnWild(spec)
end
for _, biome in ipairs(Config.Biomes) do
    local options = Catalog.ForBiome(biome.Id)
    if #options > 0 then
        makeGuardian(options[#options], biome)
    end
end

local function characterAdded(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.WalkSpeed = Config.BaseWalkSpeed
        humanoid.Died:Connect(function()
            if carried[player] then
                local root = character:FindFirstChild("HumanoidRootPart")
                clearCarry(player)
                notify(player, "O animal escapou quando você caiu. Tente roubá-lo novamente.", "Warning")
            end
        end)
    end
    task.wait(0.25)
    if player.Parent ~= Players then return end
    local base = playerBases[player]
    local floor = base and base:FindFirstChild("Floor")
    if floor and character.Parent then
        character:PivotTo(CFrame.new(floor.Position + Vector3.new(0, 4, 0)))
    end
    updatePlayerAttributes(player)
end

local function playerAdded(player)
    player:SetAttribute("ProfileLoaded", false)
    player:SetAttribute("CarryingAnimal", false)
    local base = assignBase(player)
    if not base then
        player:Kick("Todas as fazendas estão ocupadas. Entre em outro servidor.")
        return
    end
    player.CharacterAdded:Connect(function(character)
        task.spawn(characterAdded, player, character)
    end)
    task.spawn(function()
        local loaded = loadProfile(player)
        if not loaded or player.Parent ~= Players or not profiles[player] then return end
        player:SetAttribute("ProfileLoaded", true)
        renderBarn(player)
        notify(player, "Bem-vindo! Roube animais bebês, fuja dos guardiões e leve-os ao celeiro. Eles crescem até adultos e rendem cada vez mais.", "Success")
        if player.Character then task.spawn(characterAdded, player, player.Character) end
    end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
    leaving[player] = true
    saveProfile(player)
    releaseSession(player)
    clearCarry(player)
    profiles[player] = nil
    playerBases[player] = nil
    actionCooldowns[player] = nil
    releaseBase(player)
    leaving[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(playerAdded, player)
end

local accumulator = 0
local incomeAccumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
    accumulator += deltaTime
    incomeAccumulator += deltaTime
    for player, carry in pairs(carried) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or player.Parent ~= Players then
            clearCarry(player)
        elseif carry.Model and carry.Model.Parent then
            carry.Model:PivotTo(root.CFrame * CFrame.new(0, 1.7, 2.1))
        end
    end

    if accumulator >= Config.GuardianThinkSeconds then
        accumulator = 0
        for _, guardian in ipairs(guardians) do
            local model = guardian.Model
            if model and model.Parent and model.PrimaryPart then
                local targetRoot
                local targetPlayer
                local nearest = Config.GuardianNoticeDistance
                for player in pairs(carried) do
                    local character = player.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local distance = (root.Position - model.PrimaryPart.Position).Magnitude
                        if distance < nearest then
                            nearest = distance
                            targetRoot = root
                            targetPlayer = player
                        end
                    end
                end
                if targetRoot and targetPlayer then
                    if nearest <= Config.GuardianCatchDistance then
                        clearCarry(targetPlayer)
                        notify(targetPlayer, "O guardião alcançou você! O animal escapou.", "Error")
                    else
                        local current = model:GetPivot()
                        local destination = Vector3.new(targetRoot.Position.X, current.Position.Y, targetRoot.Position.Z)
                        local direction = destination - current.Position
                        if direction.Magnitude > 0.1 then
                            local step = math.min(direction.Magnitude, Config.GuardianSpeed * Config.GuardianThinkSeconds)
                            local nextPosition = current.Position + direction.Unit * step
                            model:PivotTo(CFrame.lookAt(nextPosition, destination))
                        end
                    end
                else
                    local current = model:GetPivot()
                    local home = guardian.Home.Position
                    local direction = home - current.Position
                    if direction.Magnitude > 1 then
                        local step = math.min(direction.Magnitude, 6 * Config.GuardianThinkSeconds)
                        model:PivotTo(CFrame.lookAt(current.Position + direction.Unit * step, home))
                    end
                end
            end
        end
    end

    if incomeAccumulator >= 1 then
        incomeAccumulator = 0
        local now = os.time()
        for player, profile in pairs(profiles) do
            local changed = false
            for _, animal in ipairs(profile.BarnAnimals) do
                local stage = stageFor(animal, now)
                if animal.Stage ~= stage.Name then
                    animal.Stage = stage.Name
                    changed = true
                    local spec = Catalog.Get(animal.Id)
                    if spec then
                        notify(player, spec.Name .. " evoluiu para " .. stage.DisplayName .. "! Sua renda aumentou.", "Success")
                    end
                end
            end
            local rate = profileIncome(profile, now)
            profile.BarnBank = math.clamp(profile.BarnBank + rate, 0, Config.CoinsLimit)
            profile.LastIncomeAt = now
            updatePlayerAttributes(player)
            if changed then
                renderBarn(player)
                task.spawn(saveProfile, player)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Config.AutosaveSeconds)
        for player in pairs(profiles) do
            if not leaving[player] then
                task.spawn(saveProfile, player)
            end
        end
    end
end)

game:BindToClose(function()
    local pending = 0
    for player in pairs(profiles) do
        leaving[player] = true
        pending += 1
        task.spawn(function()
            saveProfile(player)
            releaseSession(player)
            pending -= 1
        end)
    end
    local deadline = os.clock() + 20
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)
