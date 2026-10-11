local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalCatalog"))

local WorldBuilder = {}

local root
local mapFolder
local animalsFolder
local guardiansFolder
local basesFolder
local trainingFolder
local basesByUserId = {}
local allTrainingParts = {}

local COLORS = {
    Grass = Color3.fromRGB(116, 196, 105),
    FarmGrass = Color3.fromRGB(152, 220, 129),
    FarmAccent = Color3.fromRGB(255, 221, 131),
    JungleGrass = Color3.fromRGB(46, 126, 82),
    JungleAccent = Color3.fromRGB(84, 219, 168),
    VolcanoGround = Color3.fromRGB(75, 56, 61),
    Lava = Color3.fromRGB(255, 89, 29),
    Wood = Color3.fromRGB(121, 78, 52),
    Cream = Color3.fromRGB(255, 244, 217),
    Blue = Color3.fromRGB(73, 182, 255),
    Green = Color3.fromRGB(65, 220, 145),
}

local function part(parent, name, size, cframe, color, material, shape, canCollide, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = cframe
    object.Color = color or Color3.fromRGB(255, 255, 255)
    object.Material = material or Enum.Material.SmoothPlastic
    object.Anchored = true
    object.CanCollide = canCollide ~= false
    object.CanTouch = true
    object.CanQuery = true
    object.Transparency = transparency or 0
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth

    if shape then
        object.Shape = shape
    end

    object.Parent = parent
    return object
end

local function createFolder(parent, name)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function addLight(target, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = true
    light.Parent = target
    return light
end

local function createBillboard(parent, text, color, width, height)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WorldLabel"
    gui.Size = UDim2.fromOffset(width or 240, height or 58)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 300
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(25, 33, 43)
    label.BackgroundTransparency = 0.12
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color or COLORS.Cream
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label

    local stroke = Instance.new("UIStroke")
    stroke.Color = color or COLORS.Cream
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = label

    return gui
end

local function createSign(parent, name, position, title, subtitle, accent)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    part(model, "Post", Vector3.new(1.2, 7, 1.2), CFrame.new(position + Vector3.new(0, 3.5, 0)), COLORS.Wood, Enum.Material.WoodPlanks)
    local board = part(model, "Board", Vector3.new(12, 4, 0.8), CFrame.new(position + Vector3.new(0, 7, 0)), Color3.fromRGB(28, 39, 51), Enum.Material.SmoothPlastic)
    local face = Instance.new("SurfaceGui")
    face.Face = Enum.NormalId.Front
    face.CanvasSize = Vector2.new(900, 300)
    face.Parent = board

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0.62, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.Text = title
    titleLabel.TextColor3 = accent or COLORS.Cream
    titleLabel.TextScaled = true
    titleLabel.Parent = face

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, -20, 0.28, 0)
    subtitleLabel.Position = UDim2.new(0, 10, 0.66, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.GothamMedium
    subtitleLabel.Text = subtitle
    subtitleLabel.TextColor3 = COLORS.Cream
    subtitleLabel.TextScaled = true
    subtitleLabel.Parent = face

    return model
end

local function createTree(parent, position, trunkColor, leafColor, scale)
    scale = scale or 1

    local model = Instance.new("Model")
    model.Name = "StylizedTree"
    model.Parent = parent

    part(
        model,
        "Trunk",
        Vector3.new(2 * scale, 7 * scale, 2 * scale),
        CFrame.new(position + Vector3.new(0, 3.5 * scale, 0)),
        trunkColor or COLORS.Wood,
        Enum.Material.Wood
    )

    for index, offset in ipairs({
        Vector3.new(0, 7.4, 0),
        Vector3.new(-1.5, 6.4, 0.3),
        Vector3.new(1.4, 6.5, -0.2),
        Vector3.new(0.2, 8.8, 0),
    }) do
        part(
            model,
            "Canopy_" .. index,
            Vector3.new(5.5 * scale, 5 * scale, 5.5 * scale),
            CFrame.new(position + offset * scale),
            leafColor or COLORS.Grass,
            Enum.Material.SmoothPlastic,
            Enum.PartType.Ball,
            false
        )
    end

    return model
end

local function createRock(parent, position, size, color, rotation)
    local rock = part(
        parent,
        "StylizedRock",
        size,
        CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z),
        color,
        Enum.Material.Slate,
        Enum.PartType.Ball,
        true
    )

    rock.CanTouch = false
    return rock
end

local function createAnimalPart(model, name, size, position, color, shape, material)
    local object = part(
        model,
        name,
        size,
        CFrame.new(position),
        color,
        material or Enum.Material.SmoothPlastic,
        shape or Enum.PartType.Ball,
        true
    )
    object.Anchored = true
    object.CanCollide = false
    object.CanTouch = false
    object.CanQuery = false
    object.Massless = true
    return object
end

local function makeAnimal(speciesId, spawnCFrame)
    local spec = Catalog.Get(speciesId)

    if not spec then
        return nil
    end

    local model = Instance.new("Model")
    model.Name = spec.DisplayName:gsub("%s+", "") .. "_" .. speciesId
    model:SetAttribute("AnimalId", spec.Id)
    model:SetAttribute("DisplayName", spec.DisplayName)
    model:SetAttribute("Weight", spec.Weight)
    model:SetAttribute("RequiredStrength", spec.RequiredStrength)
    model:SetAttribute("BaseValue", spec.BaseValue)
    model:SetAttribute("Rarity", spec.Rarity)
    model:SetAttribute("Biome", spec.Biome)
    model:SetAttribute("RespawnSeconds", spec.RespawnSeconds)

    local origin = spawnCFrame.Position
    local facing = spawnCFrame.Rotation
    local bodySize = spec.Shape == "Bird" and Vector3.new(1.8, 1.8, 1.6) or Vector3.new(2.5, 1.65, 1.6)
    local body = createAnimalPart(model, "Body", bodySize, origin + Vector3.new(0, 1.4, 0), spec.Color)
    model.PrimaryPart = body

    local headSize = spec.Shape == "Bird" and Vector3.new(1.05, 1.05, 1.05) or Vector3.new(1.1, 1.05, 1.1)
    local head = createAnimalPart(model, "Head", headSize, origin + Vector3.new(0, 1.85, -0.95), spec.Color)
    createAnimalPart(model, "Eye_L", Vector3.new(0.16, 0.16, 0.1), origin + Vector3.new(-0.25, 1.98, -1.43), Color3.fromRGB(26, 31, 37))
    createAnimalPart(model, "Eye_R", Vector3.new(0.16, 0.16, 0.1), origin + Vector3.new(0.25, 1.98, -1.43), Color3.fromRGB(26, 31, 37))

    if spec.Shape == "Bird" then
        createAnimalPart(model, "Beak", Vector3.new(0.45, 0.3, 0.5), origin + Vector3.new(0, 1.7, -1.55), spec.Accent, Enum.PartType.Ball)
        createAnimalPart(model, "Wing_L", Vector3.new(0.5, 1.0, 0.9), origin + Vector3.new(-0.85, 1.42, -0.05), spec.Accent)
        createAnimalPart(model, "Wing_R", Vector3.new(0.5, 1.0, 0.9), origin + Vector3.new(0.85, 1.42, -0.05), spec.Accent)
        createAnimalPart(model, "Crest", Vector3.new(0.45, 0.45, 0.35), origin + Vector3.new(0, 2.45, -0.9), spec.Accent)
    else
        createAnimalPart(model, "Muzzle", Vector3.new(0.52, 0.42, 0.5), origin + Vector3.new(0, 1.65, -1.45), spec.Accent)
        createAnimalPart(model, "Ear_L", Vector3.new(0.32, 0.5, 0.25), origin + Vector3.new(-0.4, 2.35, -0.9), spec.Accent)
        createAnimalPart(model, "Ear_R", Vector3.new(0.32, 0.5, 0.25), origin + Vector3.new(0.4, 2.35, -0.9), spec.Accent)

        for _, offset in ipairs({
            Vector3.new(-0.75, 0.55, -0.45),
            Vector3.new(0.75, 0.55, -0.45),
            Vector3.new(-0.75, 0.55, 0.45),
            Vector3.new(0.75, 0.55, 0.45),
        }) do
            createAnimalPart(model, "Leg", Vector3.new(0.48, 0.75, 0.48), origin + offset, spec.Accent, Enum.PartType.Ball)
        end

        createAnimalPart(model, "Tail", Vector3.new(0.45, 0.45, 0.65), origin + Vector3.new(0, 1.35, 0.95), spec.Accent)
    end

    model:PivotTo(CFrame.new(origin + Vector3.new(0, 1.4, 0)) * facing)
    model.Parent = animalsFolder
    return model
end

local function createR6Guardian(position, name, accent, visionRange)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("VisionRange", visionRange or Config.Guardian.VisionRange)
    model:SetAttribute("PatrolRadius", Config.Guardian.PatrolRadius)
    model:SetAttribute("PatrolSpeed", Config.Guardian.PatrolSpeed)
    model:SetAttribute("ChaseSpeed", Config.Guardian.ChaseSpeed)
    model:SetAttribute("CatchDistance", Config.Guardian.CatchDistance)

    local rootPart = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(position + Vector3.new(0, 3, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, nil, false, 1)
    rootPart.Anchored = false
    rootPart.CanTouch = false

    local torso = part(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(position + Vector3.new(0, 3, 0)), accent, Enum.Material.SmoothPlastic)
    local head = part(model, "Head", Vector3.new(2, 1, 1), CFrame.new(position + Vector3.new(0, 4.5, 0)), Color3.fromRGB(242, 205, 164), Enum.Material.SmoothPlastic)
    local leftArm = part(model, "Left Arm", Vector3.new(1, 2, 1), CFrame.new(position + Vector3.new(-1.5, 3, 0)), accent, Enum.Material.SmoothPlastic)
    local rightArm = part(model, "Right Arm", Vector3.new(1, 2, 1), CFrame.new(position + Vector3.new(1.5, 3, 0)), accent, Enum.Material.SmoothPlastic)
    local leftLeg = part(model, "Left Leg", Vector3.new(1, 2, 1), CFrame.new(position + Vector3.new(-0.5, 1, 0)), Color3.fromRGB(37, 46, 59), Enum.Material.SmoothPlastic)
    local rightLeg = part(model, "Right Leg", Vector3.new(1, 2, 1), CFrame.new(position + Vector3.new(0.5, 1, 0)), Color3.fromRGB(37, 46, 59), Enum.Material.SmoothPlastic)

    for _, bodyPart in ipairs({ torso, head, leftArm, rightArm, leftLeg, rightLeg }) do
        bodyPart.Anchored = false
    end

    local function joint(name, parent, part0, part1, c0, c1)
        local motor = Instance.new("Motor6D")
        motor.Name = name
        motor.Part0 = part0
        motor.Part1 = part1
        motor.C0 = c0
        motor.C1 = c1
        motor.Parent = parent
    end

    joint("RootJoint", rootPart, rootPart, torso, CFrame.new(), CFrame.new())
    joint("Neck", torso, torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    joint("Left Shoulder", torso, torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
    joint("Right Shoulder", torso, torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
    joint("Left Hip", torso, torso, leftLeg, CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0))
    joint("Right Hip", torso, torso, rightLeg, CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0))

    local badge = part(model, "GuardianBadge", Vector3.new(0.45, 0.45, 0.15), CFrame.new(position + Vector3.new(0, 3.25, -0.57)), COLORS.FarmAccent, Enum.Material.Neon, Enum.PartType.Ball, false)
    badge.Anchored = false
    local badgeWeld = Instance.new("WeldConstraint")
    badgeWeld.Part0 = torso
    badgeWeld.Part1 = badge
    badgeWeld.Parent = badge

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.DisplayName = "Guardião"
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = Config.Guardian.PatrolSpeed
    humanoid.RequiresNeck = true
    humanoid.Parent = model

    model.PrimaryPart = rootPart
    model.Parent = guardiansFolder
    pcall(function()
        rootPart:SetNetworkOwner(nil)
    end)

    return model
end

local function setupLighting()
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.ClockTime = 14
    Lighting.Brightness = 2.1
    Lighting.ExposureCompensation = 0.05
    Lighting.GlobalShadows = true
    Lighting.EnvironmentDiffuseScale = 0.4
    Lighting.EnvironmentSpecularScale = 0.65
    Lighting.Ambient = Color3.fromRGB(115, 126, 150)
    Lighting.OutdoorAmbient = Color3.fromRGB(163, 185, 194)
    Lighting.FogColor = Color3.fromRGB(199, 225, 236)
    Lighting.FogStart = 700
    Lighting.FogEnd = 1600

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "RoubeAtmosphere"
    atmosphere.Color = Color3.fromRGB(199, 225, 245)
    atmosphere.Decay = Color3.fromRGB(116, 156, 188)
    atmosphere.Density = 0.22
    atmosphere.Offset = 0.1
    atmosphere.Glare = 0.18
    atmosphere.Haze = 1.15
    atmosphere.Parent = Lighting

    local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
    correction.Name = "RoubeColorCorrection"
    correction.Brightness = 0.02
    correction.Contrast = 0.08
    correction.Saturation = 0.14
    correction.TintColor = Color3.fromRGB(255, 247, 232)
    correction.Parent = Lighting

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
    bloom.Name = "RoubeBloom"
    bloom.Intensity = 0.22
    bloom.Size = 28
    bloom.Threshold = 1.05
    bloom.Parent = Lighting

    local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
    rays.Name = "RoubeSunRays"
    rays.Intensity = 0.075
    rays.Spread = 0.72
    rays.Parent = Lighting

    local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
    clouds.Name = "RoubeSoftClouds"
    clouds.Cover = 0.34
    clouds.Density = 0.28
    clouds.Color = Color3.fromRGB(245, 249, 255)
    clouds.Parent = Terrain
end

local function createBiome(parent, biomeName, center, size, groundColor, material, signTitle, subtitle, accent)
    part(parent, biomeName .. "Ground", size, CFrame.new(center), groundColor, material)
    createSign(parent, biomeName .. "Sign", center + Vector3.new(0, 1, -size.Z / 2 + 12), signTitle, subtitle, accent)
end

local function createBase(index, position, angle)
    local base = Instance.new("Model")
    base.Name = string.format("Curral_%02d", index)
    base:SetAttribute("OwnerUserId", 0)
    base.Parent = basesFolder

    part(base, "BaseFloor", Vector3.new(27, 1, 27), CFrame.new(position + Vector3.new(0, 0.4, 0)), Color3.fromRGB(238, 223, 191), Enum.Material.Sand)
    part(base, "BaseTrim", Vector3.new(29, 0.55, 29), CFrame.new(position + Vector3.new(0, 0.05, 0)), COLORS.Wood, Enum.Material.WoodPlanks)

    for _, entry in ipairs({
        { Vector3.new(-13, 2, 0), Vector3.new(1, 3, 25) },
        { Vector3.new(13, 2, 0), Vector3.new(1, 3, 25) },
        { Vector3.new(0, 2, -13), Vector3.new(25, 3, 1) },
        { Vector3.new(-8, 2, 13), Vector3.new(9, 3, 1) },
        { Vector3.new(8, 2, 13), Vector3.new(9, 3, 1) },
    }) do
        part(base, "Fence", entry[2], CFrame.new(position + entry[1]), COLORS.Cream, Enum.Material.WoodPlanks)
    end

    local sign = part(base, "OwnerSign", Vector3.new(10, 3, 0.5), CFrame.new(position + Vector3.new(0, 4.5, -12.5)), Color3.fromRGB(35, 51, 68), Enum.Material.SmoothPlastic)
    createBillboard(sign, "CURRAL " .. index .. "\nVazio", COLORS.Cream, 170, 64)

    local spawn = part(base, "BaseSpawn", Vector3.new(4, 0.4, 4), CFrame.new(position + Vector3.new(0, 1.2, 7)), COLORS.Green, Enum.Material.Neon, nil, false, 0.55)
    spawn.Transparency = 0.65

    local sell = part(base, "SellPart", Vector3.new(7, 1, 5), CFrame.new(position + Vector3.new(0, 1.15, -4)), Color3.fromRGB(50, 220, 137), Enum.Material.Neon)
    sell:SetAttribute("SellSurface", true)
    addLight(sell, Color3.fromRGB(67, 255, 157), 1.2, 13)
    createBillboard(sell, "VENDER ANIMAL", Color3.fromRGB(88, 255, 165), 190, 45)

    local treadmill = part(trainingFolder, "Esteira_" .. index, Vector3.new(17, 0.8, 4.6), CFrame.new(position + Vector3.new(-3.5, 1.2, 5)), Color3.fromRGB(31, 47, 64), Enum.Material.Metal)
    treadmill:SetAttribute("TrainingType", "Treadmill")
    treadmill:SetAttribute("BaseIndex", index)
    table.insert(allTrainingParts, treadmill)

    for lane = -1, 1, 2 do
        part(base, "TreadmillRail", Vector3.new(17, 0.45, 0.35), CFrame.new(position + Vector3.new(-3.5, 1.85, 5 + lane * 2.1)), COLORS.Blue, Enum.Material.Neon, nil, false)
    end

    local bench = part(trainingFolder, "Supino_" .. index, Vector3.new(4, 1, 3), CFrame.new(position + Vector3.new(6, 1.3, 5)), Color3.fromRGB(49, 65, 84), Enum.Material.Metal)
    bench:SetAttribute("TrainingType", "BenchPress")
    bench:SetAttribute("BaseIndex", index)
    table.insert(allTrainingParts, bench)

    part(base, "BenchBar", Vector3.new(5.5, 0.25, 0.25), CFrame.new(position + Vector3.new(6, 3.1, 5)), COLORS.Cream, Enum.Material.Metal)
    for _, offset in ipairs({ -2.15, 2.15 }) do
        part(base, "BenchWeight", Vector3.new(0.7, 1.2, 1.2), CFrame.new(position + Vector3.new(6 + offset, 3.1, 5)), COLORS.Blue, Enum.Material.Neon, Enum.PartType.Cylinder, false)
    end

    local anchor = part(base, "BaseLight", Vector3.new(0.7, 7, 0.7), CFrame.new(position + Vector3.new(-11, 4, -10)), COLORS.Wood, Enum.Material.Metal)
    local lamp = part(base, "Lamp", Vector3.new(1.7, 0.8, 1.7), CFrame.new(position + Vector3.new(-11, 7.7, -10)), Color3.fromRGB(255, 232, 166), Enum.Material.Neon, Enum.PartType.Ball, false)
    addLight(lamp, Color3.fromRGB(255, 220, 150), 0.75, 12)

    base.PrimaryPart = base:FindFirstChild("BaseFloor")
    return base
end


local function createFountain(position)
    local fountain = Instance.new("Model")
    fountain.Name = "Fountain"
    fountain.Parent = mapFolder

    local plinth = part(
        fountain, "FountainPlinth", Vector3.new(2, 9, 9),
        CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(226, 236, 239), Enum.Material.Marble, Enum.PartType.Cylinder
    )

    local basin = part(
        fountain, "FountainBasin", Vector3.new(1.1, 12, 12),
        CFrame.new(position + Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(105, 166, 184), Enum.Material.Slate, Enum.PartType.Cylinder
    )

    local water = part(
        fountain, "FountainWater", Vector3.new(0.35, 9.6, 9.6),
        CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(66, 203, 255), Enum.Material.Neon, Enum.PartType.Cylinder, false, 0.12
    )
    addLight(water, Color3.fromRGB(70, 200, 255), 1.1, 18)

    part(
        fountain, "FountainPillar", Vector3.new(2.3, 1.3, 1.3),
        CFrame.new(position + Vector3.new(0, 4.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(225, 239, 241), Enum.Material.Marble, Enum.PartType.Cylinder
    )

    local jewel = part(
        fountain, "FountainJewel", Vector3.new(2.1, 2.1, 2.1),
        CFrame.new(position + Vector3.new(0, 6, 0)),
        Color3.fromRGB(123, 233, 255), Enum.Material.Neon, Enum.PartType.Ball, false
    )
    addLight(jewel, Color3.fromRGB(85, 215, 255), 1.6, 24)

    local attachment = Instance.new("Attachment")
    attachment.Name = "WaterSparkles"
    attachment.Position = Vector3.new(0, 0.9, 0)
    attachment.Parent = jewel

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "FountainParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(Color3.fromRGB(139, 234, 255), Color3.fromRGB(255, 255, 255))
    emitter.LightEmission = 0.8
    emitter.Rate = 8
    emitter.Lifetime = NumberRange.new(0.55, 1.1)
    emitter.Speed = NumberRange.new(1, 2.5)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Parent = attachment

    return fountain
end

local function buildDecorations()
    createFountain(Vector3.new(0, 0, -20))

    for index = 1, 12 do
        local angle = math.rad(index * 30)
        local position = Vector3.new(math.cos(angle) * 63, 0, math.sin(angle) * 63)
        createTree(mapFolder, position, Color3.fromRGB(122, 83, 51), Color3.fromRGB(83, 183, 91), 0.7)
    end

    for index, x in ipairs({ 120, 140, 185, 205, 124, 205, 150, 196 }) do
        local z = ({ -48, 47, -43, 42, 49, -45, 47, 30 })[index]
        createTree(mapFolder, Vector3.new(x, 0, z), COLORS.Wood, Color3.fromRGB(88, 183, 83), 0.85)
    end

    for index, offset in ipairs({
        Vector3.new(-45, 0, -46),
        Vector3.new(-18, 0, -48),
        Vector3.new(14, 0, -49),
        Vector3.new(42, 0, -42),
        Vector3.new(-46, 0, 43),
        Vector3.new(-18, 0, 48),
        Vector3.new(18, 0, 44),
        Vector3.new(43, 0, 39),
    }) do
        createTree(mapFolder, Vector3.new(320, 0, 0) + offset, Color3.fromRGB(75, 60, 42), Color3.fromRGB(31, 102, 71), 1.1)
    end

    for index, offset in ipairs({
        Vector3.new(-54, 0, -45),
        Vector3.new(-35, 0, -60),
        Vector3.new(0, 0, -63),
        Vector3.new(35, 0, -60),
        Vector3.new(54, 0, -42),
        Vector3.new(57, 0, -10),
        Vector3.new(56, 0, 25),
        Vector3.new(39, 0, 57),
        Vector3.new(10, 0, 62),
        Vector3.new(-20, 0, 62),
        Vector3.new(-48, 0, 54),
        Vector3.new(-59, 0, 16),
    }) do
        local scale = index % 3 == 0 and 0.76 or 0.9
        createTree(mapFolder, Vector3.new(320, 0, 0) + offset, Color3.fromRGB(65, 54, 41), Color3.fromRGB(38, 113, 76), scale)
    end

    createRock(mapFolder, Vector3.new(548, 4, -48), Vector3.new(32, 10, 28), Color3.fromRGB(67, 49, 55), Vector3.new(0.08, 0.4, 0.04))
    createRock(mapFolder, Vector3.new(548, 10, -48), Vector3.new(23, 9, 20), Color3.fromRGB(54, 43, 50), Vector3.new(0.02, 0.8, 0.04))
    createRock(mapFolder, Vector3.new(548, 15, -48), Vector3.new(15, 7, 14), Color3.fromRGB(46, 39, 47), Vector3.new(0.06, 0.2, 0.02))
    local craterGlow = part(mapFolder, "VolcanoCraterGlow", Vector3.new(7, 2, 7), CFrame.new(548, 17.4, -48), COLORS.Lava, Enum.Material.Neon, Enum.PartType.Ball, false)
    addLight(craterGlow, COLORS.Lava, 2.4, 32)

    for index = 1, 10 do
        local angle = math.rad(index * 36)
        local x = 495 + math.cos(angle) * 64
        local z = math.sin(angle) * 63
        createRock(mapFolder, Vector3.new(x, 2, z), Vector3.new(8, 5, 7), Color3.fromRGB(61, 48, 54), Vector3.new(0.2, angle, 0.1))
    end

    local lava = part(
        mapFolder,
        "LavaRiver",
        Vector3.new(110, 0.4, 6),
        CFrame.new(495, 0.25, 59),
        COLORS.Lava,
        Enum.Material.Neon,
        nil,
        false
    )
    addLight(lava, COLORS.Lava, 2.2, 28)
    lava.Touched:Connect(function(hit)
        local character = hit:FindFirstAncestorOfClass("Model")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 then
            local now = os.clock()
            local last = character:GetAttribute("LavaDebounce") or 0

            if now - last >= 1.25 then
                character:SetAttribute("LavaDebounce", now)
                humanoid:TakeDamage(12)
            end
        end
    end)
end

local function applyAnimalPrompt(model)
    if not model or not model:IsA("Model") then
        return
    end

    local head = model:FindFirstChild("Head") or model.PrimaryPart
    if not head then
        return
    end

    local prompt = head:FindFirstChild("AnimalPrompt")

    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "AnimalPrompt"
        prompt.Parent = head
    end

    prompt.ActionText = "Roubar"
    prompt.ObjectText = tostring(model:GetAttribute("DisplayName") or model.Name)
    prompt.HoldDuration = 1
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("InteractionType", "StealAnimal")
end

function WorldBuilder.SpawnAnimal(speciesId, spawnCFrame)
    local model = makeAnimal(speciesId, spawnCFrame)

    if model then
        applyAnimalPrompt(model)
    end

    return model
end

function WorldBuilder.Build()
    local existing = workspace:FindFirstChild("RoubeUmAnimal")

    if existing then
        existing:Destroy()
    end

    root = createFolder(workspace, "RoubeUmAnimal")
    mapFolder = createFolder(root, "Map")
    animalsFolder = createFolder(root, "Animals")
    guardiansFolder = createFolder(root, "Guardians")
    basesFolder = createFolder(root, "Bases")
    trainingFolder = createFolder(root, "Training")
    table.clear(basesByUserId)
    table.clear(allTrainingParts)

    setupLighting()
    workspace.FallenPartsDestroyHeight = -120

    part(mapFolder, "HubGround", Vector3.new(145, 2, 145), CFrame.new(0, -1, 0), COLORS.Grass, Enum.Material.Grass)
    part(mapFolder, "FarmPath", Vector3.new(45, 1, 18), CFrame.new(80, -0.35, 0), Color3.fromRGB(214, 193, 151), Enum.Material.Ground)
    part(mapFolder, "JunglePath", Vector3.new(48, 1, 18), CFrame.new(240, -0.35, 0), Color3.fromRGB(123, 101, 70), Enum.Material.Ground)
    part(mapFolder, "VolcanoPath", Vector3.new(48, 1, 18), CFrame.new(396, -0.35, 0), Color3.fromRGB(78, 65, 71), Enum.Material.Slate)

    createBiome(mapFolder, "Farm", Vector3.new(160, -1, 0), Vector3.new(120, 2, 132), COLORS.FarmGrass, Enum.Material.Grass, "ZONA 1 · FAZENDA", "Animais comuns e raros", Color3.fromRGB(255, 229, 150))
    createBiome(mapFolder, "Jungle", Vector3.new(320, -1, 0), Vector3.new(120, 2, 138), COLORS.JungleGrass, Enum.Material.Grass, "ZONA 2 · SELVA MÍSTICA", "Território dos guardiões", Color3.fromRGB(91, 255, 190))
    createBiome(mapFolder, "Volcano", Vector3.new(495, -1, 0), Vector3.new(150, 2, 145), COLORS.VolcanoGround, Enum.Material.Slate, "ZONA 3 · VULCÃO", "Animais míticos e lava", Color3.fromRGB(255, 113, 64))

    createSign(mapFolder, "HubSign", Vector3.new(0, 0, -65), "ROUBE UM ANIMAL", "Treine · Explore · Escape · Venda", COLORS.Blue)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "WorldSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.Position = Vector3.new(0, 1, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = COLORS.Blue
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.35
    spawn.Parent = mapFolder

    for index = 1, 8 do
        local angle = math.rad((index - 1) * 45)
        local position = Vector3.new(math.cos(angle) * 47, 0, math.sin(angle) * 47)
        createBase(index, position, angle)
    end

    buildDecorations()

    local animalSpawns = {
        { "Chicken", CFrame.new(127, 0, -23) },
        { "Chicken", CFrame.new(145, 0, 28) },
        { "Capybara", CFrame.new(173, 0, -8) },
        { "Goat", CFrame.new(196, 0, 25) },
        { "Capybara", CFrame.new(194, 0, -29) },
        { "Monkey", CFrame.new(286, 0, -28) },
        { "Monkey", CFrame.new(304, 0, 29) },
        { "Macaw", CFrame.new(338, 0, -16) },
        { "Jaguar", CFrame.new(356, 0, 26) },
        { "Panda", CFrame.new(328, 0, 44) },
        { "LavaFox", CFrame.new(447, 0, -33) },
        { "Tiger", CFrame.new(485, 0, -44) },
        { "LavaFox", CFrame.new(516, 0, -30) },
        { "Phoenix", CFrame.new(543, 0, 25) },
        { "Tiger", CFrame.new(482, 0, 46) },
    }

    for _, entry in ipairs(animalSpawns) do
        WorldBuilder.SpawnAnimal(entry[1], entry[2])
    end

    createR6Guardian(Vector3.new(161, 0, 42), "Guardiao_Fazenda", Color3.fromRGB(65, 117, 70), 44)
    createR6Guardian(Vector3.new(320, 0, 45), "Guardiao_Selva", Color3.fromRGB(46, 95, 84), 62)
    createR6Guardian(Vector3.new(501, 0, -30), "Guardiao_Vulcao", Color3.fromRGB(103, 56, 58), 72)

    return root
end

function WorldBuilder.GetRoot()
    return root
end

function WorldBuilder.GetAnimalsFolder()
    return animalsFolder
end

function WorldBuilder.GetGuardiansFolder()
    return guardiansFolder
end

function WorldBuilder.GetBasesFolder()
    return basesFolder
end

function WorldBuilder.GetTrainingFolder()
    return trainingFolder
end

function WorldBuilder.AssignBase(player)
    if basesByUserId[player.UserId] and basesByUserId[player.UserId].Parent then
        return basesByUserId[player.UserId]
    end

    for _, base in ipairs(basesFolder:GetChildren()) do
        if base:IsA("Model") and base:GetAttribute("OwnerUserId") == 0 then
            base:SetAttribute("OwnerUserId", player.UserId)
            basesByUserId[player.UserId] = base
            player:SetAttribute("OwnedBase", base.Name)

            local sign = base:FindFirstChild("OwnerSign")
            local gui = sign and sign:FindFirstChildWhichIsA("BillboardGui")
            local label = gui and gui:FindFirstChildWhichIsA("TextLabel")

            if label then
                label.Text = "CURRAL\n" .. player.DisplayName
            end

            WorldBuilder.TeleportToBase(player)
            return base
        end
    end

    return nil
end

function WorldBuilder.GetOwnedBase(player)
    local base = basesByUserId[player.UserId]

    if base and base.Parent and base:GetAttribute("OwnerUserId") == player.UserId then
        return base
    end

    return nil
end

function WorldBuilder.TeleportToBase(player)
    local base = WorldBuilder.GetOwnedBase(player)

    if not base then
        return false
    end

    local spawnPart = base:FindFirstChild("BaseSpawn")

    if not spawnPart then
        return false
    end

    local character = player.Character

    if character and character.Parent then
        pcall(function()
            character:PivotTo(spawnPart.CFrame * CFrame.new(0, 3, 0))
        end)
        return true
    end

    return false
end

function WorldBuilder.ReleaseBase(player)
    local base = basesByUserId[player.UserId]

    if base and base.Parent then
        base:SetAttribute("OwnerUserId", 0)
    end

    basesByUserId[player.UserId] = nil
    player:SetAttribute("OwnedBase", nil)
end

function WorldBuilder.GetTrainingParts()
    return allTrainingParts
end

return WorldBuilder
