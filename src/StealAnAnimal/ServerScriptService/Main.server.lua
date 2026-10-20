local Players = game:GetService("Players")
Players.CharacterAutoLoads = true
Players.RespawnTime = 3
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

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
local rebirthRemote = remote("RequestRebirth")
local dailyRemote = remote("RequestDailyReward")
local codeRemote = remote("RequestRedeemCode")
local questRemote = remote("RequestQuest")
local mapBotRemote = remote("RequestMapBot")
local mapBotReportRemote = remote("MapBotReport")
local botXStatusRemote = remote("BotXStatus")

local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")
local previousRuntimeWorld = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
if previousRuntimeWorld then
    previousRuntimeWorld:Destroy()
end

local world = Instance.new("Folder")
world.Name = "StealAnAnimalRuntimeWorld"
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
local rebirthInProgress = {}
local progressionWriteInProgress = {}
local mapBotCooldowns = {}
local actionCooldowns = {}
local trainingNoticeAt = {}
local treadmillStrips = {}
local treadmillAnimationAccumulator = 0
local playerBases = {}
local carried = {}
local guardians = {}
local wildRecords = {}
local rng = Random.new(20261020)
local SESSION_LEASE_SECONDS = 180
local DAILY_CODES = table.freeze({
    FARMFAMILY = 1000,
    WILDSTART = 1500,
    BARNBOOST = 2500,
})
local QUESTS = table.freeze({
    FirstCapture = { Reward = 250, Label = "Roube seu primeiro animal", Requirement = function(profile) return profile.TotalCaptured >= 1 end },
    FirstBarn = { Reward = 750, Label = "Deposite seu primeiro animal", Requirement = function(profile) return profile.TotalDeposited >= 1 end },
    Collector = { Reward = 1500, Label = "Roube 5 animais", Requirement = function(profile) return profile.TotalCaptured >= 5 end },
    FullBarn = { Reward = 5000, Label = "Encha os 6 espaços do celeiro", Requirement = function(profile) return #profile.BarnAnimals >= Config.BaseSlots end },
})

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
    local scale = giant and 4 or Config.EvolutionStages[stageIndex].Scale
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

    if spec.Shape == "Whale" or spec.Shape == "Dolphin" then
        ball("Body", 2.05, 1.28, 4.1, 0, 1.35, 0)
        ball("Chest", 1.62, 1.05, 1.5, 0, 1.25, -0.78, spec.Accent)
        ball("Head", 1.42, 1.12, 1.45, 0, 1.7, -1.45)
        ball("Muzzle", 1.02, 0.48, 1.18, 0, 1.38, -2.12, spec.Accent)
    elseif spec.Shape == "Ray" then
        ball("Body", 1.55, 0.48, 2.5, 0, 1.08, 0)
        ball("Chest", 0.9, 0.32, 1.0, 0, 1.0, -0.72, spec.Accent)
        ball("Head", 0.95, 0.62, 0.9, 0, 1.25, -1.0)
        ball("Muzzle", 0.48, 0.22, 0.5, 0, 1.08, -1.46, spec.Accent)
    else
        ball("Body", 1.65, 1.25, 2.0, 0, 1.25, 0)
        ball("Chest", 1.18, 1.15, 1.05, 0, 1.35, -0.62, spec.Accent)
        ball("Head", 1.12, 1.08, 1.05, 0, 2.18, -1.05)
        ball("Muzzle", 0.68, 0.48, 0.52, 0, 1.96, -1.62, spec.Accent)
    end
    for _, side in ipairs({ -1, 1 }) do
        ball("EyeWhite", 0.27, 0.31, 0.13, side * 0.29, 2.34, -1.57, Color3.fromRGB(255, 250, 231))
        ball("EyeIris", 0.16, 0.2, 0.08, side * 0.29, 2.33, -1.66, spec.Accent)
        ball("EyePupil", 0.085, 0.13, 0.045, side * 0.29, 2.33, -1.713, Color3.fromRGB(24, 27, 33))
        ball("EyeGlint", 0.045, 0.055, 0.025, side * 0.29 - 0.03, 2.39, -1.735, Color3.fromRGB(255, 255, 255))
        ball("Eyebrow", 0.36, 0.11, 0.11, side * 0.3, 2.58, -1.52, spec.Accent)
        ball("CheekBlush", 0.25, 0.15, 0.06, side * 0.53, 1.92, -1.56, Color3.fromRGB(255, 162, 174))
    end
    ball("Nose", 0.19, 0.15, 0.13, 0, 2.02, -1.9, spec.Shape == "Bird" and Color3.fromRGB(255, 145, 47) or Color3.fromRGB(57, 45, 43))
    ball("Mouth", 0.2, 0.07, 0.06, 0, 1.85, -1.74, Color3.fromRGB(83, 45, 48))
    ball("ChestBadge", 0.34, 0.34, 0.16, 0, 1.24, -1.12, spec.Accent)
    ball("ChestBadgeCore", 0.14, 0.14, 0.08, 0, 1.25, -1.22, Color3.fromRGB(255, 241, 180))

    for _, side in ipairs({ -1, 1 }) do
        if spec.Shape ~= "Whale" and spec.Shape ~= "Dolphin" and spec.Shape ~= "Ray" then
            ball("Ear", 0.32, (spec.Shape == "Fox" or spec.Shape == "Wolf") and 0.75 or 0.55, 0.24, side * 0.38, 2.8, -0.88, spec.Color)
            ball("LegFront", 0.35, 0.72, 0.38, side * 0.48, 0.48, -0.55, spec.Color)
            ball("LegBack", 0.38, 0.68, 0.4, side * 0.48, 0.45, 0.62, spec.Color)
        end
    end

    if spec.Shape == "Bird" then
        for _, side in ipairs({ -1, 1 }) do
            ball("Wing", 0.42, 0.78, 1.0, side * 0.82, 1.52, 0.05, spec.Accent)
        end
        ball("Crest", 0.18, 0.42, 0.18, 0, 2.9, -0.8, spec.Accent)
        if spec.Id == "Hen" then
            ball("HenComb", 0.3, 0.42, 0.23, 0, 2.96, -0.79, Color3.fromRGB(205, 54, 58))
            ball("HenCombPoint", 0.2, 0.29, 0.2, -0.18, 2.91, -0.79, Color3.fromRGB(205, 54, 58))
            ball("HenCombPoint", 0.2, 0.29, 0.2, 0.18, 2.91, -0.79, Color3.fromRGB(205, 54, 58))
            ball("HenWattle", 0.2, 0.32, 0.18, 0, 1.74, -1.55, Color3.fromRGB(205, 54, 58))
            ball("HenBeak", 0.35, 0.21, 0.4, 0, 2.03, -1.77, Color3.fromRGB(255, 157, 45))
        elseif spec.Id == "Swan" then
            ball("SwanNeck", 0.34, 1.15, 0.38, 0, 2.65, -0.98, Color3.fromRGB(250, 248, 238))
            ball("SwanNeckUpper", 0.29, 0.76, 0.3, 0, 3.15, -0.76, Color3.fromRGB(250, 248, 238))
            ball("SwanHead", 0.48, 0.42, 0.48, 0, 3.48, -0.75, Color3.fromRGB(250, 248, 238))
            ball("SwanBeak", 0.44, 0.18, 0.42, 0, 3.42, -1.1, Color3.fromRGB(255, 141, 42))
            ball("SwanMask", 0.16, 0.18, 0.1, 0, 3.48, -1.02, Color3.fromRGB(44, 49, 55))
            for _, side in ipairs({ -1, 1 }) do
                ball("SwanWingFeather", 0.3, 0.65, 0.72, side * 1.0, 1.78, 0.22, Color3.fromRGB(255, 255, 250))
                ball("SwanWingFeather", 0.28, 0.58, 0.68, side * 0.82, 1.6, 0.68, Color3.fromRGB(241, 239, 228))
            end
        elseif spec.Id == "Duckling" then
            ball("DucklingBill", 0.55, 0.24, 0.46, 0, 2.0, -1.72, Color3.fromRGB(255, 151, 36))
            ball("DucklingFoot", 0.38, 0.14, 0.45, -0.26, 0.15, -0.62, Color3.fromRGB(255, 151, 36))
            ball("DucklingFoot", 0.38, 0.14, 0.45, 0.26, 0.15, -0.62, Color3.fromRGB(255, 151, 36))
        end
    elseif spec.Shape == "Fox" or spec.Shape == "Wolf" or spec.Shape == "Lion" then
        ball("Tail", spec.Shape == "Fox" and 0.62 or 0.48, spec.Shape == "Fox" and 0.62 or 0.48, spec.Shape == "Fox" and 1.75 or 1.2, 0, 1.65, 1.2, spec.Accent)
        ball("TailTip", 0.42, 0.42, 0.48, 0, 1.68, 2.0, spec.Shape == "Fox" and Color3.fromRGB(255, 244, 220) or spec.Accent)
        ball("ShoulderPatch", 0.34, 0.35, 0.14, -0.62, 1.62, -0.46, spec.Accent)
        ball("ShoulderPatch", 0.34, 0.35, 0.14, 0.62, 1.62, -0.46, spec.Accent)
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
    elseif spec.Shape == "Bear" then
        for _, side in ipairs({ -1, 1 }) do
            ball("BearEarRound", 0.38, 0.38, 0.28, side * 0.42, 2.7, -0.84, spec.Color)
            ball("BearEarInner", 0.2, 0.2, 0.1, side * 0.42, 2.72, -0.99, spec.Accent)
            ball("BearPaw", 0.43, 0.3, 0.48, side * 0.52, 0.22, -0.58, spec.Accent)
        end
        ball("BearMuzzle", 0.65, 0.42, 0.52, 0, 1.99, -1.67, Color3.fromRGB(235, 223, 202))
        ball("BearNose", 0.22, 0.16, 0.16, 0, 2.05, -1.98, Color3.fromRGB(35, 35, 38))
    elseif spec.Shape == "Whale" then
        ball("WhaleDorsalFin", 0.18, 0.65, 0.75, 0, 2.05, 0.12, spec.Accent)
        ball("WhaleTailStock", 0.44, 0.42, 1.12, 0, 1.2, 2.18, spec.Accent)
        ball("WhaleTailFluke", 1.7, 0.2, 1.05, 0, 1.28, 2.93, spec.Accent)
        ball("WhaleFlipper", 0.32, 0.23, 1.4, -1.13, 0.91, -0.22, spec.Accent)
        ball("WhaleFlipper", 0.32, 0.23, 1.4, 1.13, 0.91, -0.22, spec.Accent)
        ball("WhaleBlowhole", 0.2, 0.08, 0.22, 0, 2.26, -1.05, Color3.fromRGB(61, 79, 93))
        ball("WhaleBelly", 1.45, 0.24, 2.15, 0, 0.82, -0.3, Color3.fromRGB(235, 238, 225))
    elseif spec.Shape == "Dolphin" then
        ball("DolphinDorsalFin", 0.16, 0.52, 0.72, 0, 2.04, 0.12, spec.Accent)
        ball("DolphinTailStock", 0.35, 0.3, 0.95, 0, 1.18, 2.22, spec.Accent)
        ball("DolphinTailFluke", 1.0, 0.18, 0.8, 0, 1.25, 2.88, spec.Accent)
        ball("DolphinFlipper", 0.23, 0.18, 1.05, -0.95, 0.9, -0.15, spec.Accent)
        ball("DolphinFlipper", 0.23, 0.18, 1.05, 0.95, 0.9, -0.15, spec.Accent)
    elseif spec.Shape == "Ray" then
        ball("MantaWing", 1.6, 0.18, 1.85, -1.6, 0.98, 0.18, spec.Accent)
        ball("MantaWing", 1.6, 0.18, 1.85, 1.6, 0.98, 0.18, spec.Accent)
        ball("MantaCephalicLobe", 0.42, 0.18, 0.62, -0.34, 1.08, -1.35, spec.Accent)
        ball("MantaCephalicLobe", 0.42, 0.18, 0.62, 0.34, 1.08, -1.35, spec.Accent)
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

    if spec.Id == "Bunny" then
        for _, side in ipairs({ -1, 1 }) do
            ball("BunnyEar", 0.24, 1.02, 0.2, side * 0.28, 3.12, -0.88, spec.Color)
            ball("BunnyEarInner", 0.11, 0.72, 0.08, side * 0.28, 3.14, -0.995, spec.Accent)
        end
        ball("BunnyCheek", 0.28, 0.22, 0.18, -0.22, 1.92, -1.7, Color3.fromRGB(255, 190, 195))
        ball("BunnyCheek", 0.28, 0.22, 0.18, 0.22, 1.92, -1.7, Color3.fromRGB(255, 190, 195))
    elseif spec.Id == "Lamb" then
        for row = 1, 3 do
            for column = -1, 1 do
                ball("WoolCurl", 0.48, 0.45, 0.48, column * 0.42, 2.0 + (row % 2) * 0.16, 0.25 + row * 0.34, Color3.fromRGB(255, 250, 235))
            end
        end
        ball("WoolForelock", 0.56, 0.4, 0.38, 0, 2.85, -0.9, Color3.fromRGB(255, 250, 235))
    elseif spec.Id == "Meerkat" then
        ball("MeerkatChest", 0.78, 1.25, 0.4, 0, 1.35, -0.82, spec.Accent)
        for _, side in ipairs({ -1, 1 }) do
            ball("MeerkatEyePatch", 0.25, 0.28, 0.12, side * 0.29, 2.33, -1.58, Color3.fromRGB(83, 58, 42))
            ball("MeerkatStripe", 0.12, 0.65, 0.14, side * 0.3, 1.65, 0.55, Color3.fromRGB(117, 77, 46))
        end
    elseif spec.Id == "Otter" then
        ball("OtterTail", 0.42, 0.42, 1.7, 0, 1.0, 1.42, Color3.fromRGB(103, 70, 52))
        for _, side in ipairs({ -1, 1 }) do
            ball("OtterWhisker", 0.42, 0.045, 0.045, side * 0.42, 1.97, -1.83, spec.Accent)
            ball("OtterPaw", 0.38, 0.22, 0.38, side * 0.55, 0.36, -0.8, spec.Accent)
        end
    elseif spec.Id == "Penguin" then
        ball("PenguinBelly", 1.0, 1.15, 0.3, 0, 1.42, -0.88, Color3.fromRGB(250, 247, 233))
        for _, side in ipairs({ -1, 1 }) do
            ball("PenguinFlipper", 0.28, 0.78, 0.85, side * 0.95, 1.45, 0.02, spec.Color)
        end
    elseif spec.Id == "Owl" then
        for _, side in ipairs({ -1, 1 }) do
            ball("OwlBrow", 0.46, 0.16, 0.18, side * 0.3, 2.5, -1.48, spec.Accent)
            ball("OwlFaceDisk", 0.42, 0.46, 0.12, side * 0.28, 2.25, -1.48, Color3.fromRGB(239, 220, 184))
        end
    elseif spec.Id == "Fawn" then
        for row = 1, 2 do
            for column = -1, 1 do
                ball("FawnSpot", 0.14, 0.14, 0.08, column * 0.35, 1.78, 0.25 + row * 0.38, Color3.fromRGB(255, 237, 196))
            end
        end
    elseif spec.Id == "Phoenix" then
        for feather = 1, 5 do
            ball("PhoenixTailFeather", 0.22, 0.26, 1.15, (feather - 3) * 0.2, 1.55, 1.45 + math.abs(feather - 3) * 0.12, feather % 2 == 0 and Color3.fromRGB(255, 209, 72) or Color3.fromRGB(255, 91, 42))
        end
        ball("PhoenixCrest", 0.2, 0.58, 0.22, 0, 3.05, -0.78, Color3.fromRGB(255, 219, 84))
    elseif spec.Id == "Crocodile" then
        for spine = 1, 5 do
            ball("CrocodileScute", 0.24, 0.3, 0.24, 0, 2.0, -0.25 + spine * 0.35, spec.Accent)
        end
        ball("CrocodileJaw", 0.78, 0.24, 0.64, 0, 1.78, -1.55, Color3.fromRGB(174, 193, 111))
    elseif spec.Id == "MantaRay" then
        for gill = 1, 3 do
            ball("MantaGill", 0.1, 0.16, 0.12, -0.28 + gill * 0.14, 0.98, -0.86, Color3.fromRGB(49, 70, 80))
            ball("MantaGill", 0.1, 0.16, 0.12, 0.28 - gill * 0.14, 0.98, -0.86, Color3.fromRGB(49, 70, 80))
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

local function incomeFor(animal, now, rebirths)
    local spec = Catalog.Get(animal.Id)
    if not spec then
        return 0
    end
    local _, stageIndex = stageFor(animal, now)
    local baseIncome = Rules.AnimalIncome(spec.Income, stageIndex, Config)
    return math.floor(baseIncome * Rules.RebirthIncomeMultiplier(rebirths or 0, Config))
end

local function profileIncome(profile, now)
    local total = 0
    for _, animal in ipairs(profile.BarnAnimals) do
        total += incomeFor(animal, now, profile.Rebirths)
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
                    total += Rules.AnimalIncome(spec.Income, index, Config) * Rules.RebirthIncomeMultiplier(profile.Rebirths, Config) * (segmentEnd - segmentStart)
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
        TreadmillLevel = 1,
        Rebirths = 0,
        BarnBank = 0,
        BarnAnimals = {},
        LastIncomeAt = os.time(),
        TotalCaptured = 0,
        TotalDeposited = 0,
        LastDailyClaimDay = 0,
        DailyStreak = 0,
        RedeemedCodes = {},
        QuestClaims = {},
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
    data.Speed = safeInteger(raw.Speed, 0, Config.MaxSpeedPoints, 0)
    data.TreadmillLevel = safeInteger(raw.TreadmillLevel, 1, Config.MaxTreadmillLevel, 1)
    data.Rebirths = safeInteger(raw.Rebirths, 0, Config.MaxRebirths, 0)
    data.BarnBank = safeInteger(raw.BarnBank, 0, Config.CoinsLimit, 0)
    data.LastIncomeAt = safeInteger(raw.LastIncomeAt, 0, 2147483647, os.time())
    data.TotalCaptured = safeInteger(raw.TotalCaptured, 0, 2147483647, 0)
    data.TotalDeposited = safeInteger(raw.TotalDeposited, 0, 2147483647, 0)
    data.LastDailyClaimDay = safeInteger(raw.LastDailyClaimDay, 0, 2147483647, 0)
    data.DailyStreak = safeInteger(raw.DailyStreak, 0, 7, 0)
    for field, source in pairs({ RedeemedCodes = raw.RedeemedCodes, QuestClaims = raw.QuestClaims }) do
        if type(source) == "table" then
            local count = 0
            for key, timestamp in pairs(source) do
                if type(key) == "string" and #key > 0 and #key <= 64
                    and type(timestamp) == "number" and timestamp == timestamp
                    and timestamp >= 0 and timestamp < math.huge then
                    data[field][key] = math.floor(timestamp)
                    count += 1
                    if count >= 100 then break end
                end
            end
        end
    end
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
        TreadmillLevel = profile.TreadmillLevel,
        Rebirths = profile.Rebirths,
        BarnBank = profile.BarnBank,
        LastIncomeAt = profile.LastIncomeAt,
        TotalCaptured = profile.TotalCaptured or 0,
        TotalDeposited = profile.TotalDeposited or 0,
        LastDailyClaimDay = profile.LastDailyClaimDay or 0,
        DailyStreak = profile.DailyStreak or 0,
        RedeemedCodes = table.clone(profile.RedeemedCodes or {}),
        QuestClaims = table.clone(profile.QuestClaims or {}),
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

local function createTreadmill(base, center)
    local treadmill = Instance.new("Model")
    treadmill.Name = "Treadmill"
    treadmill.Parent = base
    local origin = center + Vector3.new(0, 0, -9.5)

    createPart(treadmill, "TreadmillHousing", Vector3.new(7.4, 0.62, 9.2), CFrame.new(origin + Vector3.new(0, 0.38, 0)), Color3.fromRGB(38, 52, 60), Enum.Material.Metal, nil, true)
    createPart(treadmill, "TreadmillBelt", Vector3.new(5.9, 0.14, 7.8), CFrame.new(origin + Vector3.new(0, 0.76, 0)), Color3.fromRGB(32, 43, 49), Enum.Material.DiamondPlate, nil, true)

    for _, side in ipairs({ -1, 1 }) do
        createPart(treadmill, "TreadmillRail", Vector3.new(0.34, 0.95, 8.8), CFrame.new(origin + Vector3.new(side * 3.15, 1.14, 0)), Color3.fromRGB(60, 192, 198), Enum.Material.Metal, nil, true)
        createPart(treadmill, "TreadmillRailLight", Vector3.new(0.08, 0.08, 8.1), CFrame.new(origin + Vector3.new(side * 3.15, 1.65, 0)), Color3.fromRGB(91, 236, 244), Enum.Material.Neon, nil, false)
    end

    for index = 1, 7 do
        local phase = (index - 1) * (Config.TreadmillBeltLength / 7)
        local stripe = createPart(treadmill, "MovingBeltStripe", Vector3.new(5.45, 0.035, 0.11), CFrame.new(origin + Vector3.new(0, 0.86, phase - Config.TreadmillBeltLength / 2)), index % 2 == 0 and Color3.fromRGB(87, 220, 225) or Color3.fromRGB(56, 145, 161), Enum.Material.Neon, nil, false)
        stripe.CastShadow = false
        table.insert(treadmillStrips, { Part = stripe, Origin = origin, Phase = phase, Length = Config.TreadmillBeltLength })
    end

    for _, side in ipairs({ -1, 1 }) do
        local roller = createPart(treadmill, "BeltRoller", Vector3.new(0.28, 5.75, 0.28), CFrame.new(origin + Vector3.new(0, 0.88, side * 3.82)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(126, 147, 154), Enum.Material.Metal, Enum.PartType.Cylinder, false)
        roller.CastShadow = false
    end

    local console = createPart(treadmill, "TreadmillConsole", Vector3.new(2.6, 1.15, 0.38), CFrame.new(origin + Vector3.new(0, 2.05, -3.45)), Color3.fromRGB(35, 67, 72), Enum.Material.Metal, nil, true)
    createPart(treadmill, "ConsoleScreen", Vector3.new(1.95, 0.48, 0.06), CFrame.new(origin + Vector3.new(0, 2.22, -3.68)), Color3.fromRGB(62, 242, 204), Enum.Material.Neon, nil, false)
    addLabel(console, "ESTEIRA DE VELOCIDADE", "CORRA SOBRE A FAIXA PARA TREINAR", Color3.fromRGB(95, 239, 226))

    local upgradePrompt = Instance.new("ProximityPrompt")
    upgradePrompt.Name = "UpgradeTreadmillPrompt"
    upgradePrompt.ActionText = "MELHORAR ESTEIRA"
    upgradePrompt.ObjectText = "Equipamento da sua fazenda"
    upgradePrompt.HoldDuration = 0.35
    upgradePrompt.MaxActivationDistance = 10
    upgradePrompt.RequiresLineOfSight = false
    upgradePrompt:SetAttribute("InteractionType", "UpgradeTreadmill")
    upgradePrompt.Parent = console

    local zone = createPart(treadmill, "TrainingZone", Vector3.new(5.45, 1.3, 6.35), CFrame.new(origin + Vector3.new(0, 4.05, 0)), Color3.fromRGB(0, 0, 0), Enum.Material.SmoothPlastic, nil, false)
    zone.Transparency = 1
    zone.CastShadow = false
    zone.CanTouch = false
    zone.CanQuery = false

    treadmill.PrimaryPart = treadmill:FindFirstChild("TreadmillHousing")
    return treadmill
end

local function createBase(index)
    local basePositions = {
        Vector3.new(-69, 0, -53), Vector3.new(-23, 0, -53), Vector3.new(23, 0, -53), Vector3.new(69, 0, -53),
        Vector3.new(-69, 0, 53), Vector3.new(-23, 0, 53), Vector3.new(23, 0, 53), Vector3.new(69, 0, 53),
    }
    local center = basePositions[index]
    local base = Instance.new("Model")
    base.Name = "Farm_" .. tostring(index)
    base:SetAttribute("BaseIndex", index)
    base:SetAttribute("OwnerUserId", 0)
    base.Parent = basesFolder

    createPart(base, "Floor", Vector3.new(34, 1, 31), CFrame.new(center + Vector3.new(0, -0.3, 0)), Color3.fromRGB(111, 171, 83), Enum.Material.Grass, nil, true)
    local frontSign = center.Z < 0 and 1 or -1
    local fenceColor = Color3.fromRGB(151, 91, 52)
    local function fence(name, size, offset, color)
        local rail = createPart(base, name, size, CFrame.new(center + offset), color or fenceColor, Enum.Material.WoodPlanks, nil, false)
        rail.CastShadow = true
        return rail
    end
    for _, zSide in ipairs({ -1, 1 }) do
        local z = zSide * 14.8
        if zSide == -frontSign then
            fence("PenFenceBackLower", Vector3.new(34, 0.35, 0.45), Vector3.new(0, 0.95, z))
            fence("PenFenceBackUpper", Vector3.new(34, 0.35, 0.45), Vector3.new(0, 2.05, z), Color3.fromRGB(183, 119, 65))
        else
            fence("PenFenceGateLeftLower", Vector3.new(12, 0.35, 0.45), Vector3.new(-11, 0.95, z))
            fence("PenFenceGateRightLower", Vector3.new(12, 0.35, 0.45), Vector3.new(11, 0.95, z))
            fence("PenFenceGateLeftUpper", Vector3.new(12, 0.35, 0.45), Vector3.new(-11, 2.05, z), Color3.fromRGB(183, 119, 65))
            fence("PenFenceGateRightUpper", Vector3.new(12, 0.35, 0.45), Vector3.new(11, 2.05, z), Color3.fromRGB(183, 119, 65))
        end
    end
    for _, xSide in ipairs({ -1, 1 }) do
        local x = xSide * 16.5
        fence("PenFenceSideLower", Vector3.new(0.45, 0.35, 31), Vector3.new(x, 0.95, 0))
        fence("PenFenceSideUpper", Vector3.new(0.45, 0.35, 31), Vector3.new(x, 2.05, 0), Color3.fromRGB(183, 119, 65))
    end
    for _, xSide in ipairs({ -1, 1 }) do
        for _, zSide in ipairs({ -1, 1 }) do
            createPart(base, "PenFencePost", Vector3.new(0.8, 3.2, 0.8), CFrame.new(center + Vector3.new(xSide * 16.4, 1.35, zSide * 14.8)), Color3.fromRGB(124, 73, 42), Enum.Material.Wood, nil, false)
        end
    end
    createPart(base, "BarnBack", Vector3.new(20, 10, 1), CFrame.new(center + Vector3.new(0, 5, 9)), Color3.fromRGB(174, 107, 65), Enum.Material.WoodPlanks, nil, true)
    createPart(base, "BarnLeft", Vector3.new(1, 10, 15), CFrame.new(center + Vector3.new(-9.5, 5, 1.5)), Color3.fromRGB(196, 132, 81), Enum.Material.WoodPlanks, nil, true)
    createPart(base, "BarnRight", Vector3.new(1, 10, 15), CFrame.new(center + Vector3.new(9.5, 5, 1.5)), Color3.fromRGB(196, 132, 81), Enum.Material.WoodPlanks, nil, true)
    createPart(base, "BarnRoofLeft", Vector3.new(12, 0.85, 18), CFrame.new(center + Vector3.new(-5.2, 12.0, 1.5)) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(112, 61, 54), Enum.Material.Slate, nil, true)
    createPart(base, "BarnRoofRight", Vector3.new(12, 0.85, 18), CFrame.new(center + Vector3.new(5.2, 12.0, 1.5)) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(135, 70, 59), Enum.Material.Slate, nil, true)
    createPart(base, "BarnRoofRidge", Vector3.new(0.9, 0.9, 18.5), CFrame.new(center + Vector3.new(0, 14.35, 1.5)), Color3.fromRGB(255, 190, 84), Enum.Material.Metal, nil, false)
    createPart(base, "BarnFrontTrim", Vector3.new(20.5, 0.55, 0.5), CFrame.new(center + Vector3.new(0, 9.65, -6.25)), Color3.fromRGB(239, 205, 147), Enum.Material.Wood, nil, false)
    createPart(base, "BarnDoorFrame", Vector3.new(7.5, 7, 0.65), CFrame.new(center + Vector3.new(0, 3.2, -6.35)), Color3.fromRGB(91, 54, 39), Enum.Material.Wood, nil, false)
    createPart(base, "BarnDoor", Vector3.new(6.4, 6.15, 0.32), CFrame.new(center + Vector3.new(0, 3.1, -6.7)), Color3.fromRGB(198, 139, 78), Enum.Material.WoodPlanks, nil, false)
    for _, side in ipairs({ -1, 1 }) do
        createPart(base, "BarnWindowFrame", Vector3.new(3.4, 2.8, 0.42), CFrame.new(center + Vector3.new(side * 6.5, 6.2, -6.28)), Color3.fromRGB(87, 59, 44), Enum.Material.Wood, nil, false)
        createPart(base, "BarnWindowGlass", Vector3.new(2.7, 2.1, 0.18), CFrame.new(center + Vector3.new(side * 6.5, 6.2, -6.55)), Color3.fromRGB(137, 223, 236), Enum.Material.Glass, nil, false)
        createPart(base, "BarnWindowCross", Vector3.new(0.2, 2.2, 0.24), CFrame.new(center + Vector3.new(side * 6.5, 6.2, -6.7)), Color3.fromRGB(240, 215, 165), Enum.Material.Wood, nil, false)
    end
    local barnLamp = addBall(base, "BarnLamp", Vector3.new(1.2, 1.2, 0.6), center + Vector3.new(0, 7.2, -7.2), Color3.fromRGB(255, 221, 112), Enum.Material.Neon)
    barnLamp.Shape = Enum.PartType.Ball
    createPart(base, "BarnSign", Vector3.new(10, 2, 0.35), CFrame.new(center + Vector3.new(0, 8.35, -6.7)), Color3.fromRGB(75, 52, 42), Enum.Material.Wood, nil, false)
    local sign = base.BarnSign
    addLabel(sign, "SUA FAZENDA", "Bebês crescem aqui", Color3.fromRGB(255, 218, 105))

    local display = Instance.new("Folder")
    display.Name = "StoredAnimals"
    display.Parent = base
    local offsets = {
        Vector3.new(-5.5, 0.35, -1), Vector3.new(0, 0.35, -1), Vector3.new(5.5, 0.35, -1),
        Vector3.new(-5.5, 0.35, 5), Vector3.new(0, 0.35, 5), Vector3.new(5.5, 0.35, 5),
    }
    for slotIndex, offset in ipairs(offsets) do
        local pad = createPart(display, "Slot_" .. tostring(slotIndex), Vector3.new(5.1, 0.25, 5.1), CFrame.new(center + offset), Color3.fromRGB(235, 222, 183), Enum.Material.Sand, nil, false)
        pad:SetAttribute("SlotIndex", slotIndex)
        addLabel(pad, "ESPAÇO " .. tostring(slotIndex), "VAZIO", Color3.fromRGB(255, 218, 105))
    end

    createTreadmill(base, center)

    local deposit = createPart(base, "DepositPad", Vector3.new(7, 0.45, 4), CFrame.new(center + Vector3.new(-12, 0.35, -10)), Color3.fromRGB(78, 235, 128), Enum.Material.Neon, nil, false)
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

    local collect = createPart(base, "CollectPad", Vector3.new(7, 0.45, 4), CFrame.new(center + Vector3.new(12, 0.35, -10)), Color3.fromRGB(255, 203, 65), Enum.Material.Neon, nil, false)
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

    local entryGate = createPart(base, "FarmEntryArch", Vector3.new(0.65, 4.2, 0.65), CFrame.new(center + Vector3.new(0, 2.15, -15.2)), Color3.fromRGB(255, 216, 104), Enum.Material.Neon, nil, false)
    createPart(base, "FarmEntryArchLeft", Vector3.new(0.65, 4.2, 0.65), CFrame.new(center + Vector3.new(-6.5, 2.15, -15.2)), Color3.fromRGB(255, 216, 104), Enum.Material.Neon, nil, false)
    createPart(base, "FarmEntryArchTop", Vector3.new(13.5, 0.65, 0.65), CFrame.new(center + Vector3.new(-3.25, 4.1, -15.2)), Color3.fromRGB(255, 216, 104), Enum.Material.Neon, nil, false)
    entryGate.CanCollide = false
    local farmBeacon = createPart(base, "FarmBeacon", Vector3.new(0.7, 5, 0.7), CFrame.new(center + Vector3.new(14, 2.5, 10)), Color3.fromRGB(122, 245, 136), Enum.Material.Neon, nil, false)
    addBall(base, "FarmBeaconOrb", Vector3.new(2, 2, 2), center + Vector3.new(14, 5.7, 10), Color3.fromRGB(255, 222, 105), Enum.Material.Neon)
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
    local atmosphere = Lighting:FindFirstChild("StealAnimalAtmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "StealAnimalAtmosphere"
    atmosphere.Density = 0.18
    atmosphere.Offset = 0.12
    atmosphere.Color = Color3.fromRGB(199, 235, 196)
    atmosphere.Decay = Color3.fromRGB(105, 147, 159)
    atmosphere.Glare = 0.12
    atmosphere.Haze = 1.2
    atmosphere.Parent = Lighting

    createPart(world, "HubGround", Vector3.new(210, 1, 210), CFrame.new(0, -1, 0), Color3.fromRGB(101, 193, 68), Enum.Material.Grass, nil, true)
    createPart(world, "HubGrassBorder", Vector3.new(198, 0.25, 198), CFrame.new(0, -0.32, 0), Color3.fromRGB(141, 213, 89), Enum.Material.Grass, nil, false)
    createPart(world, "CorridorFloor", Vector3.new(1500, 0.28, 56), CFrame.new(850, -0.38, 0), Color3.fromRGB(91, 181, 74), Enum.Material.Grass, nil, true)
    createPart(world, "MainPath", Vector3.new(1500, 0.35, 12), CFrame.new(850, -0.15, 0), Color3.fromRGB(224, 201, 155), Enum.Material.Cobblestone, nil, true)
    createPart(world, "CentralCarpet", Vector3.new(225, 0.2, 18), CFrame.new(18, 0.14, 0), Color3.fromRGB(210, 62, 64), Enum.Material.Fabric, nil, false)
    createPart(world, "CarpetGoldEdgeNorth", Vector3.new(225, 0.18, 0.55), CFrame.new(18, 0.27, -9.2), Color3.fromRGB(255, 216, 99), Enum.Material.Neon, nil, false)
    createPart(world, "CarpetGoldEdgeSouth", Vector3.new(225, 0.18, 0.55), CFrame.new(18, 0.27, 9.2), Color3.fromRGB(255, 216, 99), Enum.Material.Neon, nil, false)
    for index = 1, 56 do
        local stripeX = -88 + index * 3.8
        createPart(world, "CarpetStripe", Vector3.new(1.25, 0.035, 16.4), CFrame.new(stripeX, 0.255, 0), index % 2 == 0 and Color3.fromRGB(232, 89, 83) or Color3.fromRGB(179, 42, 55), Enum.Material.Fabric, nil, false)
    end
    for index = 1, 62 do
        local stripeX = 120 + index * 22
        if stripeX < 1510 then
            createPart(world, "MainPathTile", Vector3.new(0.7, 0.07, 10.4), CFrame.new(stripeX, 0.045, 0), index % 2 == 0 and Color3.fromRGB(248, 220, 158) or Color3.fromRGB(191, 164, 117), Enum.Material.SmoothPlastic, nil, false)
        end
    end
    for _, side in ipairs({ -1, 1 }) do
        createPart(world, "TrackInnerRail", Vector3.new(1500, 0.45, 0.55), CFrame.new(850, 0.35, side * 6.55), Color3.fromRGB(247, 190, 82), Enum.Material.Metal, nil, false)
        createPart(world, "CorridorEdge", Vector3.new(1500, 0.2, 0.8), CFrame.new(850, 0.04, side * 28), Color3.fromRGB(255, 218, 105), Enum.Material.Neon, nil, false)
    end
    for _, side in ipairs({ -1, 1 }) do
        createPart(world, "CorridorEdge", Vector3.new(1500, 0.2, 0.8), CFrame.new(850, 0.04, side * 28), Color3.fromRGB(255, 218, 105), Enum.Material.Neon, nil, false)
    end
    for _, side in ipairs({ -1, 1 }) do
        createPart(world, "CorridorBoundaryWall", Vector3.new(1500, 18, 2), CFrame.new(850, 8.5, side * 86), Color3.fromRGB(67, 107, 75), Enum.Material.Brick, nil, true)
        createPart(world, "CorridorWallCap", Vector3.new(1500, 0.65, 2.4), CFrame.new(850, 17.8, side * 86), Color3.fromRGB(255, 202, 90), Enum.Material.WoodPlanks, nil, false)
        for pillar = 1, 30 do
            local x = 115 + pillar * 49
            createPart(world, "CorridorPillar", Vector3.new(1.05, 17.2, 2.8), CFrame.new(x, 8.3, side * 85.4), pillar % 4 == 0 and Color3.fromRGB(255, 202, 90) or Color3.fromRGB(90, 148, 89), Enum.Material.Brick, nil, false)
            createPart(world, "CorridorPillarGem", Vector3.new(1.35, 0.75, 3.3), CFrame.new(x, 17.1, side * 85.4), Color3.fromRGB(255, 214, 101), Enum.Material.Neon, nil, false)
        end
    end
    createPart(world, "HubFountainBase", Vector3.new(18, 1, 18), CFrame.new(0, 0, 0), Color3.fromRGB(225, 221, 190), Enum.Material.Marble, nil, true)
    addCylinder(world, "HubFountain", Vector3.new(9, 2.2, 9), CFrame.new(0, 1.4, 0), Color3.fromRGB(90, 194, 221), Enum.Material.Glass, false)
    addBall(world, "FountainGem", Vector3.new(3.5, 3.5, 3.5), Vector3.new(0, 4.2, 0), Color3.fromRGB(115, 234, 255), Enum.Material.Neon)

    for biomeIndex, biome in ipairs(Config.Biomes) do
        createPart(world, biome.Id .. "Ground", Vector3.new(180, 1, 170), CFrame.new(biome.CenterX, -0.5, 0), biome.Ground, biome.Material, nil, true)
        createPart(world, biome.Id .. "Path", Vector3.new(180, 0.32, 56), CFrame.new(biome.CenterX, -0.15, 0), Color3.fromRGB(218, 199, 157), Enum.Material.Cobblestone, nil, true)
        createPart(world, biome.Id .. "ArchTop", Vector3.new(2.4, 2.3, 29), CFrame.new(biome.CenterX - 76, 13, 0), biome.Accent, Enum.Material.Neon, nil, false)
        createPart(world, biome.Id .. "ArchCrown", Vector3.new(8, 1.3, 6), CFrame.new(biome.CenterX - 76, 14.6, 0), Color3.fromRGB(34, 47, 48), Enum.Material.Metal, nil, false)
        addBall(world, biome.Id .. "ArchGem", Vector3.new(3.3, 3.3, 3.3), Vector3.new(biome.CenterX - 76, 16, 0), biome.Accent, Enum.Material.Neon)
        for _, side in ipairs({ -1, 1 }) do
            createPart(world, biome.Id .. "ArchPost", Vector3.new(2.2, 14, 2.2), CFrame.new(biome.CenterX - 76, 6, side * 11.5), biome.Accent, Enum.Material.SmoothPlastic, nil, false)
            createPart(world, biome.Id .. "ArchFoot", Vector3.new(4.4, 1.2, 4.4), CFrame.new(biome.CenterX - 76, 0.6, side * 11.5), Color3.fromRGB(43, 55, 52), Enum.Material.Slate, nil, false)
            addBall(world, biome.Id .. "ArchRune", Vector3.new(1.25, 1.25, 1.25), Vector3.new(biome.CenterX - 76, 7.5, side * 11.5), biome.Accent, Enum.Material.Neon)
        end
        local sign = createPart(world, biome.Id .. "Sign", Vector3.new(18, 3, 0.5), CFrame.new(biome.CenterX - 76, 10, -0.1), Color3.fromRGB(45, 52, 47), Enum.Material.Wood, nil, false)
        addLabel(sign, "FASE " .. tostring(biomeIndex) .. " • " .. biome.Name, "CORREDOR DOS ANIMAIS", biome.Accent)
        local nestZ = biomeIndex % 2 == 0 and -49 or 49
        local nestX = biome.CenterX + 40
        createPart(decorationFolder, biome.Id .. "EggNestBase", Vector3.new(16, 0.5, 12), CFrame.new(nestX, 0.08, nestZ), Color3.fromRGB(112, 75, 49), Enum.Material.WoodPlanks, nil, false)
        for eggIndex = 1, 3 do
            local eggX = nestX + (eggIndex - 2) * 4.2
            local eggColor = eggIndex == 1 and Color3.fromRGB(250, 245, 222) or eggIndex == 2 and biome.Accent or Color3.fromRGB(255, 190, 83)
            createPart(decorationFolder, biome.Id .. "EggPedestal", Vector3.new(3.5, 0.7, 3.5), CFrame.new(eggX, 0.52, nestZ), Color3.fromRGB(72, 57, 47), Enum.Material.Slate, nil, false)
            addBall(decorationFolder, biome.Id .. "WildEgg", Vector3.new(2.6, 3.6, 2.6), Vector3.new(eggX, 2.15, nestZ), eggColor, Enum.Material.SmoothPlastic)
            addBall(decorationFolder, biome.Id .. "EggBand", Vector3.new(2.7, 0.48, 2.7), Vector3.new(eggX, 1.65, nestZ), biome.Accent, Enum.Material.Neon)
            addBall(decorationFolder, biome.Id .. "EggTopGem", Vector3.new(0.75, 0.9, 0.75), Vector3.new(eggX, 3.7, nestZ), Color3.fromRGB(255, 250, 221), Enum.Material.Neon)
            for shard = 1, 5 do
                local angle = math.rad(shard * 72)
                addBall(decorationFolder, biome.Id .. "EggOrbit", Vector3.new(0.26, 0.26, 0.26), Vector3.new(eggX + math.cos(angle) * 2.1, 2.2 + math.sin(angle) * 0.4, nestZ + math.sin(angle) * 2.1), biome.Accent, Enum.Material.Neon)
            end
        end
        local nestSign = createPart(decorationFolder, biome.Id .. "NestSign", Vector3.new(13, 2.4, 0.45), CFrame.new(nestX, 4.4, nestZ - 6.5), Color3.fromRGB(45, 52, 47), Enum.Material.Wood, nil, false)
        addLabel(nestSign, "NINHO " .. tostring(biomeIndex), "OVOS SELVAGENS", biome.Accent)

        if biome.Id == "Meadow" then
            for flower = 1, 9 do
                local x = biome.CenterX + rng:NextNumber(-28, 28)
                local z = (flower % 2 == 0 and 1 or -1) * rng:NextNumber(34, 52)
                addBall(decorationFolder, "MeadowBloom", Vector3.new(1.8, 0.45, 1.8), Vector3.new(x, 0.18, z), flower % 2 == 0 and Color3.fromRGB(255, 194, 92) or Color3.fromRGB(255, 155, 199), Enum.Material.Neon)
            end
        elseif biome.Id == "Lake" then
            for reed = 1, 6 do
                local x = biome.CenterX + rng:NextNumber(-64, 64)
                local z = (reed % 2 == 0 and 1 or -1) * rng:NextNumber(38, 66)
                addCylinder(decorationFolder, "LakeReed", Vector3.new(0.28, 3.2, 0.28), CFrame.new(x, 1.6, z), Color3.fromRGB(89, 152, 82), Enum.Material.Grass, false)
                addBall(decorationFolder, "LakeWater", Vector3.new(8, 0.16, 6), Vector3.new(x + 3, 0.04, z), Color3.fromRGB(85, 187, 215), Enum.Material.Glass)
            end
        elseif biome.Id == "Forest" then
            for mushroom = 1, 5 do
                local x = biome.CenterX + rng:NextNumber(-42, 42)
                local z = (mushroom % 2 == 0 and 1 or -1) * rng:NextNumber(34, 58)
                addCylinder(decorationFolder, "MushroomStem", Vector3.new(0.7, 2.2, 0.7), CFrame.new(x, 1.1, z), Color3.fromRGB(235, 222, 194), Enum.Material.SmoothPlastic, false)
                addBall(decorationFolder, "GiantMushroom", Vector3.new(3.2, 1.1, 3.2), Vector3.new(x, 2.3, z), mushroom % 2 == 0 and Color3.fromRGB(231, 91, 94) or biome.Accent, Enum.Material.SmoothPlastic)
            end
        elseif biome.Id == "Wetlands" then
            for pool = 1, 4 do
                local side = pool % 2 == 0 and 1 or -1
                addBall(decorationFolder, "WetlandPool", Vector3.new(20, 0.18, 14), Vector3.new(biome.CenterX + rng:NextNumber(-46, 46), 0.03, side * rng:NextNumber(38, 58)), Color3.fromRGB(70, 180, 184), Enum.Material.Glass)
            end
        elseif biome.Id == "Frost" then
            for pillar = 1, 4 do
                local x = biome.CenterX + rng:NextNumber(-48, 48)
                local z = (pillar % 2 == 0 and 1 or -1) * rng:NextNumber(34, 60)
                addCylinder(decorationFolder, "IcePillar", Vector3.new(2.2, rng:NextNumber(5, 10), 2.2), CFrame.new(x, 2.8, z), Color3.fromRGB(142, 220, 255), Enum.Material.Ice, false)
            end
        elseif biome.Id == "Savanna" then
            for stone = 1, 5 do
                local x = biome.CenterX + rng:NextNumber(-48, 48)
                local z = (stone % 2 == 0 and 1 or -1) * rng:NextNumber(34, 58)
                addBall(decorationFolder, "SavannaBoulder", Vector3.new(rng:NextNumber(4, 8), rng:NextNumber(3, 6), rng:NextNumber(4, 8)), Vector3.new(x, 1.2, z), Color3.fromRGB(174, 143, 78), Enum.Material.Sand)
            end
        elseif biome.Id == "Ocean" then
            for bubble = 1, 9 do
                local x = biome.CenterX + rng:NextNumber(-68, 68)
                local z = (bubble % 2 == 0 and 1 or -1) * rng:NextNumber(36, 70)
                addBall(decorationFolder, "OceanBubble", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, rng:NextNumber(0.7, 4.2), z), Color3.fromRGB(90, 218, 246), Enum.Material.Glass)
                if bubble % 3 == 0 then
                    addBall(decorationFolder, "OceanCoral", Vector3.new(3.5, 2.8, 3.5), Vector3.new(x + 3, 1.1, z), Color3.fromRGB(80, 149, 155), Enum.Material.Slate)
                end
            end
        elseif biome.Id == "Volcano" then
            for rift = 1, 5 do
                local x = biome.CenterX + rng:NextNumber(-48, 48)
                local z = (rift % 2 == 0 and 1 or -1) * rng:NextNumber(36, 62)
                local lava = createPart(decorationFolder, "LavaRift", Vector3.new(rng:NextNumber(7, 16), 0.18, rng:NextNumber(1.2, 2.6)), CFrame.new(x, 0.06, z) * CFrame.Angles(0, math.rad(rng:NextInteger(-35, 35)), 0), Color3.fromRGB(255, 91, 40), Enum.Material.Neon, nil, false)
                lava.Transparency = 0.08
            end
        end

        for index = 1, 12 do
            local x = biome.CenterX + rng:NextNumber(-62, 62)
            local z = rng:NextNumber(-76, 76)
            if math.abs(z) > 32 and math.abs(x - biome.CenterX) > 15 then
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
            local crystal = addCylinder(decorationFolder, biome.Id .. "Crystal", Vector3.new(2, rng:NextNumber(4, 8), 2), CFrame.new(biome.CenterX + rng:NextNumber(-42, 42), 2.4, (index % 2 == 0 and 1 or -1) * rng:NextNumber(34, 60)) * CFrame.Angles(0, 0, math.rad(rng:NextInteger(-12, 12))), biome.Accent, Enum.Material.Neon, false)
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
    player:SetAttribute("TreadmillLevel", profile.TreadmillLevel)
    player:SetAttribute("TreadmillGain", Rules.TrainingGain(profile.TreadmillLevel, Config))
    player:SetAttribute("BarnBank", profile.BarnBank)
    player:SetAttribute("BarnAnimalCount", #profile.BarnAnimals)
    player:SetAttribute("BarnCapacity", Config.BaseSlots)
    player:SetAttribute("BarnIncomeRate", profileIncome(profile, now))
    player:SetAttribute("Rebirths", profile.Rebirths or 0)
    player:SetAttribute("RebirthMultiplier", Rules.RebirthIncomeMultiplier(profile.Rebirths, Config))
    player:SetAttribute("RebirthCost", Rules.RebirthCost(profile.Rebirths, Config) or 0)
    player:SetAttribute("RebirthRequiredCoins", Config.RebirthCoinsRequired)
    player:SetAttribute("RebirthRequiredSpeed", Rules.RebirthSpeedRequirement(Config) or Config.MaxSpeedPoints)
    player:SetAttribute("DailyStreak", profile.DailyStreak or 0)
    player:SetAttribute("DailyClaimAvailable", (profile.LastDailyClaimDay or 0) < math.floor(os.time() / 86400))
    player:SetAttribute("TotalCaptured", profile.TotalCaptured or 0)
    player:SetAttribute("TotalDeposited", profile.TotalDeposited or 0)
    player:SetAttribute("QuestClaimsJson", HttpService:JSONEncode(profile.QuestClaims or {}))
    player:SetAttribute("TreadmillUpgradeCost", Rules.UpgradeCost(profile.TreadmillLevel, Config) or 0)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    local function setLeaderstat(name, value)
        local item = leaderstats:FindFirstChild(name)
        if not item or not item:IsA("IntValue") then
            if item then item:Destroy() end
            item = Instance.new("IntValue")
            item.Name = name
            item.Parent = leaderstats
        end
        item.Value = math.floor(math.clamp(value, 0, 2147483647))
    end
    setLeaderstat("Coins", profile.Coins)
    setLeaderstat("Speed", profile.Speed)
    setLeaderstat("Rebirths", profile.Rebirths or 0)
    setLeaderstat("Barn Animals", #profile.BarnAnimals)
    local summary = {}
    local multiplier = Rules.RebirthIncomeMultiplier(profile.Rebirths, Config)
    for index, animal in ipairs(profile.BarnAnimals) do
        local spec = Catalog.Get(animal.Id)
        local stage, stageIndex = stageFor(animal, now)
        if spec and stage then
            local rate = math.floor(Rules.AnimalIncome(spec.Income, stageIndex, Config) * multiplier)
            table.insert(summary, tostring(index) .. ". " .. spec.Name .. " • " .. stage.DisplayName .. " • +" .. tostring(rate) .. "/s")
        end
    end
    player:SetAttribute("BarnSummary", #summary > 0 and table.concat(summary, "\n") or "Seu celeiro está vazio. Roube um filhote e leve-o ao celeiro.")
    player:SetAttribute("CarryingAnimal", carried[player] ~= nil)
    local baseSpeed = Rules.MoveSpeed(profile.Speed, Config)
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
                local income = math.floor(Rules.AnimalIncome(spec.Income, stageIndex, Config) * Rules.RebirthIncomeMultiplier(profile.Rebirths, Config))
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
    local position = Vector3.new(biome.CenterX + rng:NextNumber(-28, 28), -0.12, rng:NextNumber(-20, 20))
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
    local guardianSide = biome.Phase % 2 == 0 and 1 or -1
    local position = Vector3.new(biome.CenterX - 50, -0.12, guardianSide * 23)
    local model = createAnimalModel(spec, "Adult", position, true)
    model.Name = "GuardianParent_" .. biome.Id
    model:SetAttribute("GuardianBiome", biome.Id)
    model:SetAttribute("ThreatLevel", biome.Phase)
    model.Parent = guardiansFolder
    local head = model:FindFirstChild("Head")
    addLabel(head or model.PrimaryPart, "GUARDIÃO " .. string.upper(spec.Name), "FASE " .. tostring(biome.Phase) .. " • PROTEGE OS OVOS", biome.Accent)
    local highlight = Instance.new("Highlight")
    highlight.Name = "GuardianRim"
    highlight.Adornee = model
    highlight.FillColor = biome.Accent
    highlight.FillTransparency = 0.78
    highlight.OutlineColor = biome.Accent
    highlight.OutlineTransparency = 0.04
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model
    for shard = 1, 12 do
        local angle = math.rad(shard * 30)
        local auraPosition = position + Vector3.new(math.cos(angle) * 8.6, 0.45, math.sin(angle) * 8.6)
        local aura = addBall(model, "GuardianAuraShard", Vector3.new(1.1, 0.2, 0.2), auraPosition, biome.Accent, Enum.Material.Neon)
        aura.CFrame = CFrame.new(auraPosition) * CFrame.Angles(0, -angle, math.rad(25))
        aura.CanTouch = false
        aura.CanQuery = false
    end
    addBall(model, "GuardianCrownGem", Vector3.new(1.9, 1.9, 1.9), position + Vector3.new(0, 13.3, 0), biome.Accent, Enum.Material.Neon)
    table.insert(guardians, { Model = model, Home = CFrame.new(position), Biome = biome, Spec = spec, Speed = math.min(Config.GuardianSpeed, 12 + biome.Phase * 1.1) })
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
    local profile = profiles[player]
    if profile then
        profile.TotalCaptured = math.min(2147483647, (profile.TotalCaptured or 0) + 1)
    end
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
    profile.TotalDeposited = math.min(2147483647, (profile.TotalDeposited or 0) + 1)
    carried[player] = nil
    if carry.Model and carry.Model.Parent then
        carry.Model:Destroy()
    end
    player:SetAttribute("CarryingAnimal", false)
    updatePlayerAttributes(player)
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

local function upgradeTreadmill(player, prompt)
    local profile = profiles[player]
    if not profile or leaving[player] then
        return
    end

    if prompt then
        local current = prompt.Parent
        local ownerBase
        while current and current ~= basesFolder do
            if current:IsA("Model") and current.Parent == basesFolder then
                ownerBase = current
                break
            end
            current = current.Parent
        end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not ownerBase or ownerBase ~= playerBases[player] or ownerBase:GetAttribute("OwnerUserId") ~= player.UserId
            or not root or (root.Position - prompt.Parent.Position).Magnitude > 15 then
            return
        end
    end

    local cost = Rules.UpgradeCost(profile.TreadmillLevel, Config)
    if not cost then
        notify(player, "Sua esteira já está no nível máximo.", "Info")
        return
    end
    if profile.Coins < cost then
        notify(player, "Você precisa de " .. tostring(cost) .. " moedas para melhorar a esteira.", "Warning")
        return
    end

    profile.Coins -= cost
    profile.TreadmillLevel += 1
    updatePlayerAttributes(player)
    notify(player, "Esteira nível " .. tostring(profile.TreadmillLevel) .. "! Agora você ganha +" .. tostring(Rules.TrainingGain(profile.TreadmillLevel, Config)) .. " de velocidade por segundo correndo nela.", "Success")
end

local function onPrompt(prompt, player)
    if not profiles[player] or leaving[player] or rebirthInProgress[player] or progressionWriteInProgress[player] then
        return
    end
    local interaction = prompt:GetAttribute("InteractionType")
    if interaction ~= "StealAnimal" and interaction ~= "DepositAnimal" and interaction ~= "CollectIncome" and interaction ~= "UpgradeTreadmill" then
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
    elseif interaction == "UpgradeTreadmill" then
        upgradeTreadmill(player, prompt)
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
    if not profiles[player] or leaving[player] or rebirthInProgress[player] or progressionWriteInProgress[player] or not allowAction(player, "upgradeRemote", 0.8) then return end
    local base = playerBases[player]
    local treadmill = base and base:FindFirstChild("Treadmill")
    local console = treadmill and treadmill:FindFirstChild("TreadmillConsole")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not console or not root or (root.Position - console.Position).Magnitude > 15 then
        notify(player, "Vá até a esteira da sua própria fazenda para comprar a melhoria.", "Warning")
        return
    end
    upgradeTreadmill(player, nil)
end)

collectRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or rebirthInProgress[player] or progressionWriteInProgress[player] or not allowAction(player, "collectRemote", 0.6) then return end
    local base = playerBases[player]
    local pad = base and base:FindFirstChild("CollectPad")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not pad or not root or (root.Position - pad.Position).Magnitude > 14 then
        notify(player, "Fique perto da área de coleta da sua própria fazenda.", "Warning")
        return
    end
    collectIncome(player, { Parent = pad })
end)

local function requestRebirth(player)
    local profile = profiles[player]
    if not profile or leaving[player] or rebirthInProgress[player] then
        return
    end
    if carried[player] then
        notify(player, "Leve o animal roubado ao celeiro ou escape primeiro. O renascimento não pode descartar um animal carregado.", "Warning")
        return
    end
    if profile.Persistent == false or not sessionTokens[player] then
        notify(player, "O salvamento não está seguro neste momento. Entre novamente antes de renascer.", "Error")
        return
    end
    local cost = Rules.RebirthCost(profile.Rebirths, Config)
    local requiredSpeed = Rules.RebirthSpeedRequirement(Config) or Config.MaxSpeedPoints
    if not cost then
        notify(player, "Você já alcançou o máximo de renascimentos.", "Info")
        return
    end
    if profile.Speed < requiredSpeed or profile.Coins < cost then
        notify(player, "Renascimento exige velocidade máxima (" .. tostring(requiredSpeed) .. " pontos) e " .. tostring(cost) .. " moedas.", "Warning")
        return
    end
    if progressionWriteInProgress[player] then
        notify(player, "Seu progresso está sendo salvo. Tente novamente.", "Warning")
        return
    end
    if not allowAction(player, "rebirth", 2) then
        return
    end

    rebirthInProgress[player] = true
    player:SetAttribute("RebirthInProgress", true)
    local previous = {
        Coins = profile.Coins,
        Speed = profile.Speed,
        TreadmillLevel = profile.TreadmillLevel,
        Rebirths = profile.Rebirths,
        BarnBank = profile.BarnBank,
        BarnAnimals = profile.BarnAnimals,
        LastIncomeAt = profile.LastIncomeAt,
        Persistent = profile.Persistent,
    }

    profile.Coins = 0
    profile.Speed = 0
    profile.Rebirths += 1
    updatePlayerAttributes(player)
    renderBarn(player)

    local saved = saveProfile(player)
    if not saved then
        local persistenceState = profile.Persistent
        profile.Coins = previous.Coins
        profile.Speed = previous.Speed
        profile.TreadmillLevel = previous.TreadmillLevel
        profile.Rebirths = previous.Rebirths
        profile.BarnBank = previous.BarnBank
        profile.BarnAnimals = previous.BarnAnimals
        profile.LastIncomeAt = previous.LastIncomeAt
        if persistenceState == false then
            profile.Persistent = false
        else
            profile.Persistent = previous.Persistent
        end
        rebirthInProgress[player] = nil
        player:SetAttribute("RebirthInProgress", false)
        updatePlayerAttributes(player)
        renderBarn(player)
        if player.Parent == Players and profile.Persistent ~= false then
            notify(player, "Não foi possível confirmar o salvamento. Seu progresso foi restaurado; tente novamente.", "Error")
        end
        return
    end

    rebirthInProgress[player] = nil
    player:SetAttribute("RebirthInProgress", false)
    local base = playerBases[player]
    local floor = base and base:FindFirstChild("Floor")
    local character = player.Character
    if floor and character and character.Parent then
        character:PivotTo(CFrame.new(floor.Position + Vector3.new(0, 4, 0)))
    end
    notify(player, "RENASCIMENTO " .. tostring(profile.Rebirths) .. " concluído! Bônus permanente de +10% de renda por renascimento. Moedas e velocidade foram reiniciadas; animais, banco e esteira foram preservados.", "Success")
end

rebirthRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or not allowAction(player, "rebirthRemote", 0.5) then
        return
    end
    local ok, err = pcall(requestRebirth, player)
    if not ok then
        rebirthInProgress[player] = nil
        player:SetAttribute("RebirthInProgress", false)
        warn("[StealAnAnimal] Rebirth failed: " .. tostring(err))
        notify(player, "O renascimento falhou com segurança. Seu progresso não deve ser perdido; tente novamente.", "Error")
    end
end)


local function copyProgressionSnapshot(profile)
    local data = snapshot(profile)
    data.Persistent = profile.Persistent
    return data
end

local function restoreProgressionSnapshot(profile, data)
    profile.Coins = data.Coins
    profile.Speed = data.Speed
    profile.TreadmillLevel = data.TreadmillLevel
    profile.Rebirths = data.Rebirths
    profile.BarnBank = data.BarnBank
    profile.LastIncomeAt = data.LastIncomeAt
    profile.TotalCaptured = data.TotalCaptured or 0
    profile.TotalDeposited = data.TotalDeposited or 0
    profile.LastDailyClaimDay = data.LastDailyClaimDay or 0
    profile.DailyStreak = data.DailyStreak or 0
    profile.RedeemedCodes = table.clone(data.RedeemedCodes or {})
    profile.QuestClaims = table.clone(data.QuestClaims or {})
    profile.BarnAnimals = {}
    for _, animal in ipairs(data.BarnAnimals or {}) do
        table.insert(profile.BarnAnimals, { Uid = animal.Uid, Id = animal.Id, BornAt = animal.BornAt })
    end
    if profile.Persistent ~= false then
        profile.Persistent = data.Persistent
    end
end

local function runProgressionWrite(player, mutate)
    local profile = profiles[player]
    if not profile or leaving[player] or profile.Persistent == false or not sessionTokens[player] then
        return false, "profile-not-loaded"
    end
    if progressionWriteInProgress[player] or rebirthInProgress[player] or saveInProgress[player] then
        return false, "profile-busy"
    end
    progressionWriteInProgress[player] = true
    player:SetAttribute("ProgressionWriteInProgress", true)
    local previous = copyProgressionSnapshot(profile)
    local ok, accepted, value, extra = pcall(mutate, profile)
    if not ok or not accepted then
        restoreProgressionSnapshot(profile, previous)
        progressionWriteInProgress[player] = nil
        player:SetAttribute("ProgressionWriteInProgress", false)
        updatePlayerAttributes(player)
        if not ok then
            warn("[StealAnAnimal] Progression write failed: " .. tostring(accepted))
            return false, "datastore-error"
        end
        return false, value or "rejected"
    end
    updatePlayerAttributes(player)
    local saved = saveProfile(player)
    if not saved then
        restoreProgressionSnapshot(profile, previous)
        progressionWriteInProgress[player] = nil
        player:SetAttribute("ProgressionWriteInProgress", false)
        updatePlayerAttributes(player)
        renderBarn(player)
        return false, "datastore-error"
    end
    progressionWriteInProgress[player] = nil
    player:SetAttribute("ProgressionWriteInProgress", false)
    updatePlayerAttributes(player)
    renderBarn(player)
    return true, value, extra
end

dailyRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or not allowAction(player, "daily", 1.5) then return end
    local today = math.floor(os.time() / 86400)
    local ok, value, streak = runProgressionWrite(player, function(profile)
        if (profile.LastDailyClaimDay or 0) >= today then return false, "already-claimed" end
        local nextStreak = (profile.LastDailyClaimDay or 0) == today - 1 and math.min((profile.DailyStreak or 0) + 1, 7) or 1
        local reward = 500 + (nextStreak - 1) * 250
        profile.Coins = math.clamp(profile.Coins + reward, 0, Config.CoinsLimit)
        profile.LastDailyClaimDay = today
        profile.DailyStreak = nextStreak
        return true, reward, nextStreak
    end)
    if ok then
        notify(player, "Recompensa diária: +" .. tostring(value) .. " moedas. Sequência " .. tostring(streak) .. "/7.", "Success")
    else
        local messages = {
            ["already-claimed"] = "Você já coletou a recompensa de hoje.",
            ["profile-busy"] = "Seu progresso está sendo salvo. Tente novamente.",
            ["datastore-error"] = "A recompensa não foi salva; nada foi consumido.",
        }
        notify(player, messages[value] or "Recompensa diária indisponível.", "Warning")
    end
end)

codeRemote.OnServerEvent:Connect(function(player, rawCode)
    if not profiles[player] or leaving[player] or not allowAction(player, "code", 1.5) then return end
    if type(rawCode) ~= "string" or #rawCode > 48 then
        notify(player, "Digite um código válido.", "Warning")
        return
    end
    local code = string.upper(string.gsub(rawCode, "%s+", ""))
    local reward = DAILY_CODES[code]
    if not reward then
        notify(player, "Código inválido ou expirado.", "Warning")
        return
    end
    local ok, value = runProgressionWrite(player, function(profile)
        if profile.RedeemedCodes[code] then return false, "already-redeemed" end
        profile.RedeemedCodes[code] = os.time()
        profile.Coins = math.clamp(profile.Coins + reward, 0, Config.CoinsLimit)
        return true, reward
    end)
    if ok then
        notify(player, "Código " .. code .. " resgatado: +" .. tostring(value) .. " moedas.", "Success")
    else
        local messages = {
            ["already-redeemed"] = "Esse código já foi usado nesta conta.",
            ["profile-busy"] = "Seu progresso está sendo salvo. Tente novamente.",
            ["datastore-error"] = "Não foi possível salvar o código; ele continua disponível.",
        }
        notify(player, messages[value] or "Não foi possível resgatar o código.", "Warning")
    end
end)

questRemote.OnServerEvent:Connect(function(player, questId)
    if not profiles[player] or leaving[player] or type(questId) ~= "string" or not allowAction(player, "quest", 1.5) then return end
    local quest = QUESTS[questId]
    if not quest then return end
    local ok, value = runProgressionWrite(player, function(profile)
        if profile.QuestClaims[questId] then return false, "already-claimed" end
        if not quest.Requirement(profile) then return false, "requirements" end
        profile.QuestClaims[questId] = os.time()
        profile.Coins = math.clamp(profile.Coins + quest.Reward, 0, Config.CoinsLimit)
        return true, quest.Reward
    end)
    if ok then
        notify(player, "Missão concluída: +" .. tostring(value) .. " moedas.", "Success")
    else
        local messages = {
            ["already-claimed"] = "Essa missão já foi resgatada.",
            ["requirements"] = "Complete o objetivo antes de resgatar a recompensa.",
            ["profile-busy"] = "Seu progresso está sendo salvo. Tente novamente.",
            ["datastore-error"] = "A recompensa não foi salva; tente novamente.",
        }
        notify(player, messages[value] or "Missão indisponível.", "Warning")
    end
end)

local function mapSummary()
    local partCount = 0
    for _, item in ipairs(world:GetDescendants()) do
        if item:IsA("BasePart") then partCount += 1 end
    end
    local occupiedFarms = 0
    for _, base in ipairs(basesFolder:GetChildren()) do
        if base:GetAttribute("OwnerUserId") ~= 0 then occupiedFarms += 1 end
    end
    local biomes = 0
    for _, biome in ipairs(Config.Biomes) do
        if world:FindFirstChild(biome.Id .. "Ground", true) then biomes += 1 end
    end
    return {
        Parts = partCount,
        Farms = #basesFolder:GetChildren(),
        OccupiedFarms = occupiedFarms,
        Biomes = biomes,
        WildAnimals = #wildlifeFolder:GetChildren(),
        Guardians = #guardiansFolder:GetChildren(),
    }
end

mapBotRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] then return end
    local now = os.clock()
    if now - (mapBotCooldowns[player] or 0) < 20 then
        notify(player, "O MapBot pode testar novamente em 20 segundos.", "Warning")
        return
    end
    mapBotCooldowns[player] = now
    local base = playerBases[player]
    local pad = base and base:FindFirstChild("CollectPad")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local summary = mapSummary()
    local pathStatus = "SEM PERSONAGEM"
    local waypointCount = 0
    if root and pad then
        local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local success, err = pcall(function()
            path:ComputeAsync(root.Position, pad.Position + Vector3.new(0, 3, 0))
        end)
        if success then
            pathStatus = tostring(path.Status)
            waypointCount = #path:GetWaypoints()
        else
            pathStatus = "ERRO: " .. tostring(err)
        end
    end
    local report = table.concat({
        "MAPBOT • DIAGNÓSTICO",
        "Mapa: " .. ((summary.Parts > 300 and summary.Farms == 8 and summary.Biomes == 8) and "PASSOU" or "INCOMPLETO"),
        "Peças: " .. tostring(summary.Parts),
        "Fazendas: " .. tostring(summary.Farms) .. " (ocupadas " .. tostring(summary.OccupiedFarms) .. ")",
        "Biomas: " .. tostring(summary.Biomes) .. "/8",
        "Animais selvagens: " .. tostring(summary.WildAnimals),
        "Guardiões: " .. tostring(summary.Guardians) .. "/8",
        "Rota até o pad da fazenda: " .. pathStatus,
        "Pontos de caminho: " .. tostring(waypointCount),
    }, "\n")
    mapBotReportRemote:FireClient(player, report, pathStatus == "Success" and "Success" or "Warning")
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

if previewWorld and previewWorld.Parent then
    previewWorld:Destroy()
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
    player:SetAttribute("RebirthInProgress", false)
    player:SetAttribute("ProgressionWriteInProgress", false)
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
    rebirthInProgress[player] = nil
    progressionWriteInProgress[player] = nil
    mapBotCooldowns[player] = nil
    trainingNoticeAt[player] = nil
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
    treadmillAnimationAccumulator += deltaTime
    if treadmillAnimationAccumulator >= 0.1 then
        treadmillAnimationAccumulator = 0
        local elapsed = os.clock() * Config.TreadmillBeltSpeed
        for _, entry in ipairs(treadmillStrips) do
            local part = entry.Part
            if part and part.Parent then
                local offset = ((entry.Phase + elapsed) % entry.Length) - entry.Length / 2
                part.Position = Vector3.new(entry.Origin.X, part.Position.Y, entry.Origin.Z + offset)
            end
        end
    end
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
                            local step = math.min(direction.Magnitude, (guardian.Speed or Config.GuardianSpeed) * Config.GuardianThinkSeconds)
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
            local base = playerBases[player]
            local treadmill = base and base:FindFirstChild("Treadmill")
            local zone = treadmill and treadmill:FindFirstChild("TrainingZone")
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if zone and root and humanoid and humanoid.Health > 0 and not carried[player] and not progressionWriteInProgress[player] and not rebirthInProgress[player] then
                local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
                local inside = math.abs(localPosition.X) <= zone.Size.X / 2
                    and math.abs(localPosition.Y) <= zone.Size.Y / 2
                    and math.abs(localPosition.Z) <= zone.Size.Z / 2
                if inside then
                    local gain = Rules.TrainingGain(profile.TreadmillLevel, Config)
                    local nextSpeed = math.clamp(profile.Speed + gain, 0, Config.MaxSpeedPoints)
                    if nextSpeed > profile.Speed then
                        profile.Speed = nextSpeed
                        updatePlayerAttributes(player)
                        local previousNotice = trainingNoticeAt[player] or 0
                        if now - previousNotice >= Config.TrainingNoticeCooldown then
                            trainingNoticeAt[player] = now
                            notify(player, "Treino na esteira: +" .. tostring(gain) .. " velocidade. Total: " .. tostring(profile.Speed) .. ".", "Success")
                        end
                    end
                end
            end
            if not progressionWriteInProgress[player] and not rebirthInProgress[player] then
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
            if changed then
                renderBarn(player)
                task.spawn(saveProfile, player)
            end
            end
            updatePlayerAttributes(player)
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
