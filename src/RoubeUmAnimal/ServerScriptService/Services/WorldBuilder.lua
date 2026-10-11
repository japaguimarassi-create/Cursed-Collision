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
local displaySlotsByUserId = {}
local allTrainingParts = {}

local BIOME_CENTERS = {
    Meadow = 160,
    Forest = 315,
    Wetlands = 470,
    Snow = 625,
    Savannah = 780,
    Volcano = 935,
}

local COLORS = {
    Cream = Color3.fromRGB(255, 247, 225),
    Wood = Color3.fromRGB(126, 83, 52),
    DarkWood = Color3.fromRGB(76, 48, 34),
    Gold = Color3.fromRGB(255, 205, 89),
    Meadow = Color3.fromRGB(143, 207, 104),
    Forest = Color3.fromRGB(57, 125, 77),
    Wetlands = Color3.fromRGB(72, 145, 133),
    Snow = Color3.fromRGB(190, 222, 234),
    Savannah = Color3.fromRGB(200, 171, 99),
    Volcano = Color3.fromRGB(72, 55, 62),
    Green = Color3.fromRGB(75, 207, 112),
    Blue = Color3.fromRGB(83, 185, 255),
    Aqua = Color3.fromRGB(78, 222, 220),
    Lava = Color3.fromRGB(255, 89, 46),
    Pink = Color3.fromRGB(255, 137, 171),
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
    object.CanTouch = canCollide ~= false
    object.CanQuery = canCollide ~= false
    object.Transparency = transparency or 0
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    if shape then
        object.Shape = shape
    end
    object.Parent = parent
    return object
end

local function folder(parent, name)
    local object = Instance.new("Folder")
    object.Name = name
    object.Parent = parent
    return object
end

local function addLight(target, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = false
    light.Parent = target
    return light
end

local function addSurfaceLabel(parent, titleText, subtitleText, accent)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WorldLabel"
    gui.Size = UDim2.fromOffset(260, 76)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 400
    gui.Parent = parent

    local card = Instance.new("Frame")
    card.Size = UDim2.fromScale(1, 1)
    card.BackgroundColor3 = Color3.fromRGB(43, 54, 48)
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = 2
    stroke.Parent = card
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Color3.fromRGB(53, 76, 59), Color3.fromRGB(37, 49, 46))
    gradient.Rotation = 90
    gradient.Parent = card

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -14, 0.58, 0)
    title.Position = UDim2.new(0, 7, 0, 3)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = titleText
    title.TextColor3 = accent
    title.TextScaled = true
    title.TextWrapped = true
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -14, 0.32, 0)
    subtitle.Position = UDim2.new(0, 7, 0.61, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.Text = subtitleText
    subtitle.TextColor3 = COLORS.Cream
    subtitle.TextScaled = true
    subtitle.TextWrapped = true
    subtitle.Parent = card
    return gui
end

local function createSign(parent, name, position, titleText, subtitleText, accent)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    part(model, "Post", Vector3.new(1.2, 7, 1.2), CFrame.new(position + Vector3.new(0, 3.5, 0)), COLORS.Wood, Enum.Material.WoodPlanks)
    local board = part(model, "Board", Vector3.new(14, 4.5, 0.9), CFrame.new(position + Vector3.new(0, 7.2, 0)), Color3.fromRGB(43, 54, 48), Enum.Material.SmoothPlastic)
    addSurfaceLabel(board, titleText, subtitleText, accent)
    return model
end

local function createTree(parent, position, trunkColor, leafColor, scale, shapeName)
    scale = scale or 1
    local model = Instance.new("Model")
    model.Name = shapeName or "LowPolyTree"
    model.Parent = parent
    part(model, "Trunk", Vector3.new(2 * scale, 7 * scale, 2 * scale), CFrame.new(position + Vector3.new(0, 3.5 * scale, 0)), trunkColor or COLORS.Wood, Enum.Material.Wood)
    local canopyShape = shapeName == "PineTree" and Enum.PartType.Ball or Enum.PartType.Ball
    if shapeName == "PineTree" then
        for index = 1, 3 do
            part(model, "Needles" .. index, Vector3.new((7 - index) * scale, 4 * scale, (7 - index) * scale), CFrame.new(position + Vector3.new(0, (6 + index * 2) * scale, 0)), leafColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
        end
    elseif shapeName == "Acacia" then
        part(model, "Canopy", Vector3.new(10 * scale, 3 * scale, 7 * scale), CFrame.new(position + Vector3.new(0, 7.8 * scale, 0)), leafColor, Enum.Material.SmoothPlastic, canopyShape, false)
        part(model, "CanopyLeft", Vector3.new(5 * scale, 3 * scale, 5 * scale), CFrame.new(position + Vector3.new(-3 * scale, 7.6 * scale, 0)), leafColor, Enum.Material.SmoothPlastic, canopyShape, false)
        part(model, "CanopyRight", Vector3.new(5 * scale, 3 * scale, 5 * scale), CFrame.new(position + Vector3.new(3 * scale, 7.6 * scale, 0)), leafColor, Enum.Material.SmoothPlastic, canopyShape, false)
    else
        part(model, "CanopyA", Vector3.new(6 * scale, 5 * scale, 6 * scale), CFrame.new(position + Vector3.new(0, 7 * scale, 0)), leafColor, Enum.Material.SmoothPlastic, canopyShape, false)
        part(model, "CanopyB", Vector3.new(4.5 * scale, 4.5 * scale, 4.5 * scale), CFrame.new(position + Vector3.new(-2 * scale, 6 * scale, 1 * scale)), leafColor, Enum.Material.SmoothPlastic, canopyShape, false)
        part(model, "CanopyC", Vector3.new(4.5 * scale, 4.5 * scale, 4.5 * scale), CFrame.new(position + Vector3.new(2 * scale, 6.2 * scale, -1 * scale)), leafColor, Enum.Material.SmoothPlastic, canopyShape, false)
    end
    return model
end

local function createRock(parent, position, size, color, rotation)
    local rock = part(parent, "LowPolyRock", size, CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z), color, Enum.Material.Slate, Enum.PartType.Ball, false)
    rock.CanTouch = false
    rock.CanQuery = false
    return rock
end

local function createFlowerPatch(parent, center, count, palette)
    for index = 1, count do
        local angle = index * 2.399963
        local radius = 2 + (index % 4) * 1.25
        local position = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        part(parent, "FlowerStem", Vector3.new(0.16, 0.9, 0.16), CFrame.new(position + Vector3.new(0, 0.45, 0)), Color3.fromRGB(63, 140, 67), Enum.Material.Grass, nil, false)
        part(parent, "FlowerPetal", Vector3.new(0.72, 0.54, 0.72), CFrame.new(position + Vector3.new(0, 0.98, 0)), palette[(index - 1) % #palette + 1], Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
        part(parent, "FlowerHeart", Vector3.new(0.22, 0.22, 0.22), CFrame.new(position + Vector3.new(0, 1.22, 0)), COLORS.Gold, Enum.Material.Neon, Enum.PartType.Ball, false)
    end
end

local function createReeds(parent, position, scale, color)
    for index = 1, 4 do
        local offset = Vector3.new((index - 2.5) * 0.65, 0, (index % 2 == 0) and 0.5 or -0.5)
        part(parent, "Reed", Vector3.new(0.22, (3 + index % 2) * scale, 0.22), CFrame.new(position + offset + Vector3.new(0, (1.5 + index % 2) * scale, 0)), color or Color3.fromRGB(76, 140, 91), Enum.Material.Grass, nil, false)
    end
end

local function createMushroom(parent, position, capColor, scale)
    scale = scale or 1
    local model = Instance.new("Model")
    model.Name = "ForestMushroom"
    model.Parent = parent
    part(model, "Stem", Vector3.new(1.4 * scale, 2.6 * scale, 1.4 * scale), CFrame.new(position + Vector3.new(0, 1.3 * scale, 0)), Color3.fromRGB(239, 226, 194), Enum.Material.SmoothPlastic, nil, false)
    part(model, "Cap", Vector3.new(4.2 * scale, 1.7 * scale, 4.2 * scale), CFrame.new(position + Vector3.new(0, 2.8 * scale, 0)), capColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
    part(model, "Spot", Vector3.new(0.7 * scale, 0.3 * scale, 0.7 * scale), CFrame.new(position + Vector3.new(-0.6 * scale, 3.35 * scale, -0.7 * scale)), COLORS.Cream, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
end

local function createCrystal(parent, position, color, scale)
    scale = scale or 1
    local model = Instance.new("Model")
    model.Name = "CrystalCluster"
    model.Parent = parent
    for index, entry in ipairs({
        { Vector3.new(-1.2, 1.5, 0), Vector3.new(1.1, 3 * scale, 1.1), -0.14 },
        { Vector3.new(0.1, 2, 0.2), Vector3.new(1.3, 4 * scale, 1.3), 0.09 },
        { Vector3.new(1.5, 1.15, -0.3), Vector3.new(0.9, 2.3 * scale, 0.9), 0.18 },
    }) do
        part(model, "Crystal", entry[2], CFrame.new(position + Vector3.new(entry[1].X, entry[1].Y * scale, entry[1].Z)) * CFrame.Angles(0, 0, entry[3]), color, Enum.Material.Neon, nil, false, 0.1)
    end
end

local function makeAnimalPart(model, name, size, position, color, shape)
    local object = part(model, name, size, CFrame.new(position), color, Enum.Material.SmoothPlastic, shape or Enum.PartType.Ball, false)
    object.CanTouch = false
    object.CanQuery = false
    object.Massless = true
    return object
end

local function makeAnimalModel(speciesId, spawnCFrame, parent, includePrompt)
    local spec = Catalog.Get(speciesId)
    if not spec then
        return nil
    end

    local model = Instance.new("Model")
    model.Name = "Animal_" .. speciesId
    model:SetAttribute("AnimalId", spec.Id)
    model:SetAttribute("DisplayName", spec.DisplayName)
    model:SetAttribute("Weight", spec.Weight)
    model:SetAttribute("BaseValue", spec.BaseValue)
    model:SetAttribute("IncomePerSecond", spec.IncomePerSecond)
    model:SetAttribute("Rarity", spec.Rarity)
    model:SetAttribute("Biome", spec.Biome)
    model:SetAttribute("RespawnSeconds", spec.RespawnSeconds)

    local origin = spawnCFrame.Position
    local bird = spec.Shape == "Bird"
    local reptile = spec.Shape == "Reptile"
    local bodySize = bird and Vector3.new(2, 1.8, 1.7) or reptile and Vector3.new(3.4, 1.2, 1.8) or Vector3.new(2.6, 1.8, 1.8)
    local body = makeAnimalPart(model, "Body", bodySize, origin + Vector3.new(0, 1.4, 0), spec.Color)
    model.PrimaryPart = body

    local headSize = bird and Vector3.new(1, 1, 1) or reptile and Vector3.new(1.4, 0.8, 1.2) or Vector3.new(1.15, 1.1, 1.1)
    makeAnimalPart(model, "Head", headSize, origin + Vector3.new(0, 1.8, -1.05), spec.Color)
    makeAnimalPart(model, "EyeLeft", Vector3.new(0.16, 0.16, 0.1), origin + Vector3.new(-0.24, 1.95, -1.49), Color3.fromRGB(30, 33, 31))
    makeAnimalPart(model, "EyeRight", Vector3.new(0.16, 0.16, 0.1), origin + Vector3.new(0.24, 1.95, -1.49), Color3.fromRGB(30, 33, 31))

    if bird then
        makeAnimalPart(model, "Beak", Vector3.new(0.5, 0.32, 0.46), origin + Vector3.new(0, 1.64, -1.65), spec.Accent, Enum.PartType.Ball)
        makeAnimalPart(model, "WingLeft", Vector3.new(0.5, 1.05, 0.9), origin + Vector3.new(-1, 1.4, 0), spec.Accent)
        makeAnimalPart(model, "WingRight", Vector3.new(0.5, 1.05, 0.9), origin + Vector3.new(1, 1.4, 0), spec.Accent)
        makeAnimalPart(model, "Crest", Vector3.new(0.36, 0.45, 0.36), origin + Vector3.new(0, 2.5, -0.75), spec.Accent)
    else
        makeAnimalPart(model, "Muzzle", Vector3.new(reptile and 1.1 or 0.56, 0.45, 0.55), origin + Vector3.new(0, 1.55, -1.55), spec.Accent)
        makeAnimalPart(model, "EarLeft", Vector3.new(0.33, 0.5, 0.3), origin + Vector3.new(-0.42, 2.36, -0.88), spec.Accent)
        makeAnimalPart(model, "EarRight", Vector3.new(0.33, 0.5, 0.3), origin + Vector3.new(0.42, 2.36, -0.88), spec.Accent)
        for _, offset in ipairs({
            Vector3.new(-0.75, 0.56, -0.45),
            Vector3.new(0.75, 0.56, -0.45),
            Vector3.new(-0.75, 0.56, 0.45),
            Vector3.new(0.75, 0.56, 0.45),
        }) do
            makeAnimalPart(model, "Leg", Vector3.new(0.42, 0.7, 0.42), origin + offset, spec.Accent, Enum.PartType.Ball)
        end
        makeAnimalPart(model, "Tail", Vector3.new(0.45, 0.45, 0.75), origin + Vector3.new(0, 1.3, 0.95), spec.Accent)
    end

    model:PivotTo(CFrame.new(origin + Vector3.new(0, 1.4, 0)) * spawnCFrame.Rotation)
    model.Parent = parent or animalsFolder

    if includePrompt then
        local promptPart = model:FindFirstChild("Head") or model.PrimaryPart
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "AnimalPrompt"
        prompt.ActionText = "STEAL"
        prompt.ObjectText = spec.DisplayName .. "  •  $" .. tostring(spec.IncomePerSecond) .. "/s"
        prompt.HoldDuration = Config.CaptureHoldDuration
        prompt.MaxActivationDistance = 11
        prompt.RequiresLineOfSight = false
        prompt:SetAttribute("InteractionType", "StealAnimal")
        prompt.Parent = promptPart
        addSurfaceLabel(promptPart, spec.DisplayName, "$" .. tostring(spec.IncomePerSecond) .. " per second in your barn", Catalog.BiomeInfo[spec.Biome].Accent)
    end

    return model
end

local function createBarnAnimalDisplay(parent, speciesId, position, slotIndex)
    local model = makeAnimalModel(speciesId, CFrame.new(position + Vector3.new(0, 0.1, 0)), parent, false)
    if not model then
        return nil
    end
    model.Name = "Stored_" .. slotIndex
    model:SetAttribute("IsBarnDisplay", true)
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("ProximityPrompt") or object:IsA("BillboardGui") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
        end
    end
    return model
end

local function createGuardianBeast(position, name, primaryColor, accentColor, scale, visionRange, kind)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("GuardianType", kind or "ForestBeast")
    model:SetAttribute("VisionRange", visionRange or Config.Guardian.VisionRange)
    model:SetAttribute("PatrolRadius", Config.Guardian.PatrolRadius)
    model:SetAttribute("PatrolSpeed", Config.Guardian.PatrolSpeed)
    model:SetAttribute("ChaseSpeed", Config.Guardian.ChaseSpeed)
    model:SetAttribute("CatchDistance", Config.Guardian.CatchDistance)
    model:SetAttribute("IsGiantAnimal", true)

    local rootPart = part(model, "HumanoidRootPart", Vector3.new(3.2, 3.2, 4.2) * scale, CFrame.new(position + Vector3.new(0, 3.2 * scale, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, nil, false, 1)
    rootPart.Anchored = false
    rootPart.CanCollide = false
    rootPart.CanTouch = false

    local body = part(model, "BeastTorso", Vector3.new(7.2, 4.5, 10.5) * scale, CFrame.new(position + Vector3.new(0, 3.25 * scale, 1.2 * scale)), primaryColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    local head = part(model, "BeastHead", Vector3.new(5.6, 4.9, 4.6) * scale, CFrame.new(position + Vector3.new(0, 4.2 * scale, -5.2 * scale)), primaryColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    local muzzle = part(model, "BeastMuzzle", Vector3.new(3.5, 2.2, 2.8) * scale, CFrame.new(position + Vector3.new(0, 3.45 * scale, -7.5 * scale)), accentColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    local eyeLeft = part(model, "BeastEyeLeft", Vector3.new(0.6, 0.6, 0.28) * scale, CFrame.new(position + Vector3.new(-1.15 * scale, 4.7 * scale, -7.1 * scale)), Color3.fromRGB(255, 221, 100), Enum.Material.Neon, Enum.PartType.Ball, false)
    local eyeRight = part(model, "BeastEyeRight", Vector3.new(0.6, 0.6, 0.28) * scale, CFrame.new(position + Vector3.new(1.15 * scale, 4.7 * scale, -7.1 * scale)), Color3.fromRGB(255, 221, 100), Enum.Material.Neon, Enum.PartType.Ball, false)
    local earLeft = part(model, "BeastEarLeft", Vector3.new(1.6, 2.5, 1.5) * scale, CFrame.new(position + Vector3.new(-1.8 * scale, 6.2 * scale, -5.4 * scale)), accentColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
    local earRight = part(model, "BeastEarRight", Vector3.new(1.6, 2.5, 1.5) * scale, CFrame.new(position + Vector3.new(1.8 * scale, 6.2 * scale, -5.4 * scale)), accentColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)

    local legs = {}
    for _, offset in ipairs({
        Vector3.new(-2.2, 1.1, -2.6),
        Vector3.new(2.2, 1.1, -2.6),
        Vector3.new(-2.2, 1.1, 4.2),
        Vector3.new(2.2, 1.1, 4.2),
    }) do
        local leg = part(model, "BeastLeg", Vector3.new(1.7, 3.1, 1.8) * scale, CFrame.new(position + Vector3.new(offset.X * scale, offset.Y * scale, offset.Z * scale)), primaryColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        table.insert(legs, leg)
    end
    local tail = part(model, "BeastTail", Vector3.new(1.2, 1.2, 4.8) * scale, CFrame.new(position + Vector3.new(0, 3.6 * scale, 7.1 * scale)) * CFrame.Angles(math.rad(12), 0, 0), accentColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
    local tusks = {}
    for _, side in ipairs({ -1, 1 }) do
        local tusk = part(model, "BeastTusks", Vector3.new(0.65, 2.5, 0.65) * scale, CFrame.new(position + Vector3.new(side * 1.45 * scale, 2.5 * scale, -7.3 * scale)) * CFrame.Angles(math.rad(-18), 0, side * math.rad(12)), Color3.fromRGB(255, 242, 213), Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
        table.insert(tusks, tusk)
    end

    model.PrimaryPart = rootPart
    local welded = { body, head, muzzle, eyeLeft, eyeRight, earLeft, earRight, tail }
    for _, leg in ipairs(legs) do
        table.insert(welded, leg)
    end
    for _, tusk in ipairs(tusks) do
        table.insert(welded, tusk)
    end

    for _, bodyPart in ipairs(welded) do
        bodyPart.Anchored = false
        bodyPart.Massless = true
        if bodyPart ~= body then
            bodyPart.CanCollide = false
            bodyPart.CanTouch = false
        end
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = rootPart
        weld.Part1 = bodyPart
        weld.Parent = rootPart
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.DisplayName = name:gsub("_", " ")
    humanoid.MaxHealth = 1000
    humanoid.Health = 1000
    humanoid.WalkSpeed = Config.Guardian.PatrolSpeed
    humanoid.RequiresNeck = false
    humanoid.Parent = model
    model.Parent = guardiansFolder

    pcall(function()
        rootPart:SetNetworkOwner(nil)
    end)
    addSurfaceLabel(head, "GIANT GUARDIAN", "Return home with your animal!", accentColor)
    return model
end

local function createGateway(name, center, accent, subtitle)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = mapFolder
    part(model, "PillarLeft", Vector3.new(3, 12, 3), CFrame.new(center + Vector3.new(0, 6, -14)), Color3.fromRGB(59, 67, 60), Enum.Material.Slate)
    part(model, "PillarRight", Vector3.new(3, 12, 3), CFrame.new(center + Vector3.new(0, 6, 14)), Color3.fromRGB(59, 67, 60), Enum.Material.Slate)
    part(model, "LeftEmblem", Vector3.new(2.1, 2.1, 1.3), CFrame.new(center + Vector3.new(0, 10.8, -14)), accent, Enum.Material.Neon, Enum.PartType.Ball, false)
    part(model, "RightEmblem", Vector3.new(2.1, 2.1, 1.3), CFrame.new(center + Vector3.new(0, 10.8, 14)), accent, Enum.Material.Neon, Enum.PartType.Ball, false)
    local beam = part(model, "Header", Vector3.new(2.6, 2, 31), CFrame.new(center + Vector3.new(0, 11.1, 0)), accent, Enum.Material.SmoothPlastic, nil, false)
    addSurfaceLabel(beam, name:gsub("_", " "), subtitle, accent)
    addLight(model.LeftEmblem, accent, 1.1, 20)
    addLight(model.RightEmblem, accent, 1.1, 20)
end

local function createZoneFloor(biomeName, centerX, color, material, title, subtitle, accent)
    part(mapFolder, biomeName .. "Ground", Vector3.new(140, 2, 136), CFrame.new(centerX, -1, 0), color, material)
    createSign(mapFolder, biomeName .. "Sign", Vector3.new(centerX, 0, -55), title, subtitle, accent)
end

local function createBarn(parent, position, index)
    local barn = Instance.new("Model")
    barn.Name = "Barn"
    barn.Parent = parent
    part(barn, "Foundation", Vector3.new(20, 1, 16), CFrame.new(position + Vector3.new(0, 0.5, 0)), COLORS.Cream, Enum.Material.Slate)
    part(barn, "BackWall", Vector3.new(18, 10, 0.8), CFrame.new(position + Vector3.new(0, 5.5, 7.2)), Color3.fromRGB(174, 67, 52), Enum.Material.WoodPlanks)
    part(barn, "SideLeft", Vector3.new(0.8, 10, 14), CFrame.new(position + Vector3.new(-9.2, 5.5, 0)), Color3.fromRGB(190, 75, 57), Enum.Material.WoodPlanks)
    part(barn, "SideRight", Vector3.new(0.8, 10, 14), CFrame.new(position + Vector3.new(9.2, 5.5, 0)), Color3.fromRGB(190, 75, 57), Enum.Material.WoodPlanks)
    part(barn, "FrontWallLeft", Vector3.new(5.5, 10, 0.8), CFrame.new(position + Vector3.new(-6.2, 5.5, -7.2)), Color3.fromRGB(190, 75, 57), Enum.Material.WoodPlanks)
    part(barn, "FrontWallRight", Vector3.new(5.5, 10, 0.8), CFrame.new(position + Vector3.new(6.2, 5.5, -7.2)), Color3.fromRGB(190, 75, 57), Enum.Material.WoodPlanks)
    part(barn, "DoorTop", Vector3.new(6.5, 2, 0.8), CFrame.new(position + Vector3.new(0, 9.5, -7.2)), Color3.fromRGB(143, 48, 42), Enum.Material.WoodPlanks)
    part(barn, "RoofLeft", Vector3.new(11, 1.2, 18), CFrame.new(position + Vector3.new(-4, 11, 0)) * CFrame.Angles(0, 0, math.rad(-16)), Color3.fromRGB(103, 46, 43), Enum.Material.Slate)
    part(barn, "RoofRight", Vector3.new(11, 1.2, 18), CFrame.new(position + Vector3.new(4, 11, 0)) * CFrame.Angles(0, 0, math.rad(16)), Color3.fromRGB(124, 51, 45), Enum.Material.Slate)
    part(barn, "Door", Vector3.new(5.7, 7.8, 0.35), CFrame.new(position + Vector3.new(0, 4.2, -7.65)), Color3.fromRGB(111, 60, 39), Enum.Material.WoodPlanks)
    part(barn, "DoorSlatLeft", Vector3.new(0.3, 7.1, 0.2), CFrame.new(position + Vector3.new(-1.4, 4.2, -7.85)), COLORS.Cream, Enum.Material.WoodPlanks, nil, false)
    part(barn, "DoorSlatRight", Vector3.new(0.3, 7.1, 0.2), CFrame.new(position + Vector3.new(1.4, 4.2, -7.85)), COLORS.Cream, Enum.Material.WoodPlanks, nil, false)
    local sign = part(barn, "BarnSign", Vector3.new(7, 2.2, 0.45), CFrame.new(position + Vector3.new(0, 7.4, -7.8)), Color3.fromRGB(62, 50, 40), Enum.Material.SmoothPlastic, nil, false)
    addSurfaceLabel(sign, "YOUR BARN", "STORE • EARN • COLLECT", COLORS.Gold)
    return barn
end

local function createBase(index, position, angle)
    local base = Instance.new("Model")
    base.Name = string.format("Farm_%02d", index)
    base:SetAttribute("OwnerUserId", 0)
    base.Parent = basesFolder

    part(base, "BaseTrim", Vector3.new(39, 0.55, 39), CFrame.new(position + Vector3.new(0, 0.1, 0)), COLORS.Wood, Enum.Material.WoodPlanks)
    part(base, "BaseFloor", Vector3.new(36, 1, 36), CFrame.new(position + Vector3.new(0, 0.65, 0)), Color3.fromRGB(154, 208, 116), Enum.Material.Grass)

    for _, entry in ipairs({
        { Vector3.new(-17.5, 2.3, 0), Vector3.new(0.8, 3.4, 35) },
        { Vector3.new(17.5, 2.3, 0), Vector3.new(0.8, 3.4, 35) },
        { Vector3.new(0, 2.3, -17.5), Vector3.new(35, 3.4, 0.8) },
        { Vector3.new(-11, 2.3, 17.5), Vector3.new(13, 3.4, 0.8) },
        { Vector3.new(11, 2.3, 17.5), Vector3.new(13, 3.4, 0.8) },
    }) do
        part(base, "WhiteFence", entry[2], CFrame.new(position + entry[1]), COLORS.Cream, Enum.Material.WoodPlanks)
    end

    local sign = part(base, "OwnerSign", Vector3.new(9, 2.6, 0.5), CFrame.new(position + Vector3.new(0, 5.2, -16.3)), Color3.fromRGB(65, 69, 55), Enum.Material.SmoothPlastic, nil, false)
    addSurfaceLabel(sign, "FARM " .. index, "OWNER: FREE", COLORS.Gold)

    local spawn = part(base, "BaseSpawn", Vector3.new(4.5, 0.35, 4.5), CFrame.new(position + Vector3.new(0, 1.4, 12)), COLORS.Green, Enum.Material.Neon, nil, false, 0.4)
    spawn:SetAttribute("IsSpawn", true)

    createBarn(base, position + Vector3.new(0, 1.1, -3.8), index)

    local deposit = part(base, "BarnDepositPad", Vector3.new(7, 0.35, 4), CFrame.new(position + Vector3.new(-7, 1.28, 8)), Color3.fromRGB(72, 211, 113), Enum.Material.Neon, nil, false, 0.12)
    deposit:SetAttribute("BaseIndex", index)
    addSurfaceLabel(deposit, "STORE ANIMAL", "Bring your animal here", Color3.fromRGB(132, 255, 157))
    addLight(deposit, Color3.fromRGB(95, 255, 135), 0.55, 9)

    local collect = part(base, "IncomeCollectPad", Vector3.new(7, 0.35, 4), CFrame.new(position + Vector3.new(7, 1.28, 8)), Color3.fromRGB(255, 198, 71), Enum.Material.Neon, nil, false, 0.12)
    collect:SetAttribute("BaseIndex", index)
    addSurfaceLabel(collect, "COLLECT COINS", "Your animals are earning!", COLORS.Gold)
    addLight(collect, COLORS.Gold, 0.55, 9)

    local treadmill = part(trainingFolder, "Treadmill_" .. index, Vector3.new(10, 0.8, 3.6), CFrame.new(position + Vector3.new(-10, 1.4, -12)), Color3.fromRGB(53, 68, 71), Enum.Material.Metal)
    treadmill:SetAttribute("TrainingType", "Treadmill")
    treadmill:SetAttribute("BaseIndex", index)
    table.insert(allTrainingParts, treadmill)
    for lane = -1, 1, 2 do
        part(base, "TreadmillRail", Vector3.new(10, 0.35, 0.28), CFrame.new(position + Vector3.new(-10, 1.95, -12 + lane * 1.85)), COLORS.Blue, Enum.Material.Neon, nil, false)
    end

    local display = folder(base, "StoredAnimals")
    local slots = {}
    for slotIndex = 1, Config.Barn.BaseSlots + Config.Barn.ExtraPassSlots do
        local column = (slotIndex - 1) % 3
        local row = math.floor((slotIndex - 1) / 3)
        local slotPosition = position + Vector3.new(-10 + column * 10, 1.3, -2 + row * 9)
        local pad = part(display, "AnimalSlot_" .. slotIndex, Vector3.new(5.5, 0.28, 5.5), CFrame.new(slotPosition), Color3.fromRGB(223, 213, 177), Enum.Material.Sand, nil, false, 0.08)
        pad:SetAttribute("SlotIndex", slotIndex)
        local plate = part(display, "SlotLabel_" .. slotIndex, Vector3.new(4.7, 0.22, 0.3), CFrame.new(slotPosition + Vector3.new(0, 0.5, 2.35)), Color3.fromRGB(69, 63, 53), Enum.Material.SmoothPlastic, nil, false)
        addSurfaceLabel(plate, "SLOT " .. slotIndex, "EMPTY", COLORS.Cream)
        table.insert(slots, { Pad = pad, LabelPart = plate, Label = plate:FindFirstChild("WorldLabel") })
    end
    displaySlotsByUserId[index] = slots

    base.PrimaryPart = base:FindFirstChild("BaseFloor")
    return base
end

local function setupLighting()
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.ClockTime = 14.2
    Lighting.Brightness = 2.2
    Lighting.ExposureCompensation = 0.02
    Lighting.GlobalShadows = true
    Lighting.EnvironmentDiffuseScale = 0.45
    Lighting.EnvironmentSpecularScale = 0.35
    Lighting.Ambient = Color3.fromRGB(134, 148, 130)
    Lighting.OutdoorAmbient = Color3.fromRGB(171, 193, 164)
    Lighting.FogColor = Color3.fromRGB(195, 221, 196)
    Lighting.FogStart = 520
    Lighting.FogEnd = 1400

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "StealAnimalAtmosphere"
    atmosphere.Color = Color3.fromRGB(205, 227, 204)
    atmosphere.Decay = Color3.fromRGB(118, 159, 142)
    atmosphere.Density = 0.18
    atmosphere.Offset = 0.05
    atmosphere.Glare = 0.08
    atmosphere.Haze = 0.75
    atmosphere.Parent = Lighting

    local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
    correction.Name = "StealAnimalColorCorrection"
    correction.Brightness = 0.015
    correction.Contrast = 0.08
    correction.Saturation = 0.11
    correction.TintColor = Color3.fromRGB(255, 249, 231)
    correction.Parent = Lighting

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
    bloom.Name = "StealAnimalBloom"
    bloom.Intensity = 0.14
    bloom.Size = 20
    bloom.Threshold = 1.2
    bloom.Parent = Lighting

    local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
    clouds.Name = "StealAnimalClouds"
    clouds.Cover = 0.25
    clouds.Density = 0.22
    clouds.Color = Color3.fromRGB(248, 251, 243)
    clouds.Parent = Terrain
end

local function buildZoneDecorations()
    for index, x in ipairs({ 115, 208, 258, 362, 412, 515, 567, 670, 722, 825, 878, 980 }) do
        local biomeIndex = math.floor((x - 85) / 155) + 1
        local color = biomeIndex <= 1 and COLORS.Gold
            or biomeIndex == 2 and Color3.fromRGB(84, 181, 106)
            or biomeIndex == 3 and COLORS.Aqua
            or biomeIndex == 4 and Color3.fromRGB(135, 217, 246)
            or biomeIndex == 5 and Color3.fromRGB(243, 191, 82)
            or COLORS.Lava
        for _, z in ipairs({ -51, 51 }) do
            createTree(mapFolder, Vector3.new(x, 0, z), COLORS.Wood, color, 0.55 + (index % 3) * 0.12)
        end
    end

    for _, x in ipairs({ 113, 143, 190, 213 }) do
        createFlowerPatch(mapFolder, Vector3.new(x, 0, -34 + (x % 3) * 25), 6, { COLORS.Pink, COLORS.Gold, COLORS.Cream })
    end

    for _, pos in ipairs({
        Vector3.new(274, 0, -38), Vector3.new(296, 0, 44), Vector3.new(348, 0, -44), Vector3.new(371, 0, 38),
    }) do
        createTree(mapFolder, pos, Color3.fromRGB(101, 70, 47), Color3.fromRGB(38, 97, 60), 1.05, "PineTree")
        createMushroom(mapFolder, pos + Vector3.new(7, 0, -4), Color3.fromRGB(203, 92, 215), 0.7)
    end

    for _, pos in ipairs({
        Vector3.new(426, 0, -32), Vector3.new(448, 0, 37), Vector3.new(495, 0, -42), Vector3.new(516, 0, 29),
    }) do
        part(mapFolder, "WetlandPool", Vector3.new(24, 0.18, 15), CFrame.new(pos + Vector3.new(0, 0.03, 0)), Color3.fromRGB(66, 173, 180), Enum.Material.Glass, nil, false, 0.24)
        createReeds(mapFolder, pos + Vector3.new(13, 0, 0), 0.8, Color3.fromRGB(79, 139, 101))
        createRock(mapFolder, pos + Vector3.new(-10, 0.8, 4), Vector3.new(4, 2, 4), Color3.fromRGB(102, 133, 128), Vector3.new(0.2, 0.3, 0.1))
    end

    for _, pos in ipairs({
        Vector3.new(578, 0, -38), Vector3.new(601, 0, 43), Vector3.new(646, 0, -43), Vector3.new(668, 0, 32),
    }) do
        createTree(mapFolder, pos, Color3.fromRGB(90, 107, 116), Color3.fromRGB(131, 198, 219), 1.05, "PineTree")
        createCrystal(mapFolder, pos + Vector3.new(8, 0, -5), Color3.fromRGB(118, 219, 255), 0.9)
    end

    for _, pos in ipairs({
        Vector3.new(728, 0, -43), Vector3.new(754, 0, 44), Vector3.new(802, 0, -39), Vector3.new(828, 0, 40),
    }) do
        createTree(mapFolder, pos, Color3.fromRGB(121, 85, 48), Color3.fromRGB(215, 181, 91), 1.05, "Acacia")
        createRock(mapFolder, pos + Vector3.new(7, 0.9, 6), Vector3.new(5, 2, 4), Color3.fromRGB(152, 131, 85), Vector3.new(0.1, 0.4, 0.1))
    end

    for index, pos in ipairs({
        Vector3.new(884, 0, -43), Vector3.new(905, 0, 36), Vector3.new(960, 0, -40), Vector3.new(984, 0, 40),
    }) do
        createRock(mapFolder, pos + Vector3.new(0, 2, 0), Vector3.new(12, 7, 11), Color3.fromRGB(74, 56, 64), Vector3.new(0.2, index * 0.3, 0.1))
        createCrystal(mapFolder, pos + Vector3.new(7, 0, -4), Color3.fromRGB(255, 102, 65), 1.0)
    end

    for index = 1, 8 do
        local angle = math.rad(index * 45)
        local pos = Vector3.new(math.cos(angle) * 68, 0, math.sin(angle) * 68)
        createTree(mapFolder, pos, COLORS.Wood, Color3.fromRGB(98, 171, 90), 0.75)
    end

    local fountain = Instance.new("Model")
    fountain.Name = "FarmFountain"
    fountain.Parent = mapFolder
    part(fountain, "Basin", Vector3.new(1.1, 12, 12), CFrame.new(0, 1.6, -20) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(135, 176, 173), Enum.Material.Slate, Enum.PartType.Cylinder)
    local water = part(fountain, "Water", Vector3.new(0.25, 9.4, 9.4), CFrame.new(0, 2.5, -20) * CFrame.Angles(0, 0, math.rad(90)), COLORS.Blue, Enum.Material.Neon, Enum.PartType.Cylinder, false, 0.15)
    addLight(water, COLORS.Blue, 0.65, 14)
end

local function addPrompt(target, name, action, objectText, interactionType, holdDuration)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = name
    prompt.ActionText = action
    prompt.ObjectText = objectText
    prompt.HoldDuration = holdDuration or 0.5
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("InteractionType", interactionType)
    prompt.Parent = target
    return prompt
end

function WorldBuilder.SpawnAnimal(speciesId, spawnCFrame)
    local model = makeAnimalModel(speciesId, spawnCFrame, animalsFolder, true)
    return model
end

function WorldBuilder.Build()
    local existing = workspace:FindFirstChild("StealAnAnimal")
    if existing then
        existing:Destroy()
    end

    root = folder(workspace, "StealAnAnimal")
    root:SetAttribute("MapReady", false)
    mapFolder = folder(root, "Map")
    animalsFolder = folder(root, "Animals")
    guardiansFolder = folder(root, "Guardians")
    basesFolder = folder(root, "Farms")
    trainingFolder = folder(root, "Training")
    table.clear(basesByUserId)
    table.clear(displaySlotsByUserId)
    table.clear(allTrainingParts)

    local function step(label, callback)
        local ok, result = xpcall(callback, debug.traceback)
        if not ok then
            warn("[StealAnAnimal] Map step failed (" .. label .. "): " .. tostring(result))
            root:SetAttribute("MapError_" .. label:gsub("%W", ""), true)
            return false
        end
        return true
    end

    step("Lighting", setupLighting)
    workspace.FallenPartsDestroyHeight = -120

    step("Hub", function()
        part(mapFolder, "HubGround", Vector3.new(150, 2, 150), CFrame.new(0, -1, 0), Color3.fromRGB(130, 201, 104), Enum.Material.Grass)
        part(mapFolder, "MainPath", Vector3.new(1090, 0.18, 25), CFrame.new(495, 0.09, 0), Color3.fromRGB(206, 183, 143), Enum.Material.Ground)
        part(mapFolder, "PathEdgeLeft", Vector3.new(1090, 0.2, 0.7), CFrame.new(495, 0.13, -13), COLORS.Gold, Enum.Material.SmoothPlastic, nil, false)
        part(mapFolder, "PathEdgeRight", Vector3.new(1090, 0.2, 0.7), CFrame.new(495, 0.13, 13), COLORS.Gold, Enum.Material.SmoothPlastic, nil, false)
        createSign(mapFolder, "MainWelcomeSign", Vector3.new(0, 0, -63), "STEAL AN ANIMAL", "STEAL • ESCAPE • STORE • EARN", COLORS.Gold)
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "WorldSpawn"
        spawn.Size = Vector3.new(8, 1, 8)
        spawn.Position = Vector3.new(0, 1, 0)
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Duration = 0
        spawn.Color = COLORS.Green
        spawn.Material = Enum.Material.Neon
        spawn.Transparency = 0.35
        spawn.Parent = mapFolder
    end)

    local zones = {
        { "Meadow", 160, COLORS.Meadow, Enum.Material.Grass, "SUNNY MEADOW", "Friendly farm animals", COLORS.Gold },
        { "Forest", 315, COLORS.Forest, Enum.Material.Grass, "WHISPERING FOREST", "Woodland animals", Color3.fromRGB(95, 221, 137) },
        { "Wetlands", 470, COLORS.Wetlands, Enum.Material.Ground, "MISTY WETLANDS", "Water-loving animals", COLORS.Aqua },
        { "Snow", 625, COLORS.Snow, Enum.Material.Snow, "FROST PEAK", "Snow creatures", Color3.fromRGB(138, 223, 255) },
        { "Savannah", 780, COLORS.Savannah, Enum.Material.Ground, "GOLDEN SAVANNA", "Wild giants", Color3.fromRGB(255, 184, 78) },
        { "Volcano", 935, COLORS.Volcano, Enum.Material.Slate, "EMBER VOLCANO", "Legendary creatures", COLORS.Lava },
    }

    for _, zone in ipairs(zones) do
        step(zone[1] .. "Terrain", function()
            createZoneFloor(zone[1], zone[2], zone[3], zone[4], zone[5], zone[6], zone[7])
            createGateway(zone[1] .. "Gateway", Vector3.new(zone[2] - 66, 0, 0), zone[7], zone[5])
        end)
        task.wait()
    end

    for index = 1, 8 do
        local angle = math.rad((index - 1) * 45 + 22.5)
        local position = Vector3.new(math.cos(angle) * 54, 0, math.sin(angle) * 54)
        step("Farm" .. index, function()
            createBase(index, position, angle)
        end)
        task.wait()
    end

    step("Landmarks", buildZoneDecorations)

    local animalSpawns = {
        { "Chicken", CFrame.new(128, 0, -20) },
        { "Goat", CFrame.new(150, 0, 30) },
        { "Rabbit", CFrame.new(180, 0, -30) },
        { "Deer", CFrame.new(202, 0, 20) },
        { "Monkey", CFrame.new(274, 0, -20) },
        { "Macaw", CFrame.new(301, 0, 29) },
        { "Fox", CFrame.new(333, 0, -29) },
        { "Jaguar", CFrame.new(349, 0, 18) },
        { "Panda", CFrame.new(292, 0, 43) },
        { "Wolf", CFrame.new(343, 0, -44) },
        { "Capybara", CFrame.new(426, 0, -21) },
        { "Frog", CFrame.new(454, 0, 24) },
        { "Otter", CFrame.new(492, 0, -27) },
        { "Crocodile", CFrame.new(510, 0, 37) },
        { "Penguin", CFrame.new(580, 0, -26) },
        { "ArcticFox", CFrame.new(615, 0, 28) },
        { "Reindeer", CFrame.new(658, 0, -29) },
        { "Zebra", CFrame.new(731, 0, -21) },
        { "Lion", CFrame.new(758, 0, 27) },
        { "Elephant", CFrame.new(810, 0, -32) },
        { "LavaFox", CFrame.new(887, 0, -24) },
        { "Tiger", CFrame.new(928, 0, 26) },
        { "Phoenix", CFrame.new(970, 0, -23) },
    }

    for index, entry in ipairs(animalSpawns) do
        step("Animal" .. index, function()
            if not WorldBuilder.SpawnAnimal(entry[1], entry[2]) then
                error("Unable to create " .. entry[1])
            end
        end)
        if index % 4 == 0 then
            task.wait()
        end
    end

    local guardians = {
        { Vector3.new(188, 0, 43), "Guardian_MeadowBear", Color3.fromRGB(157, 105, 62), Color3.fromRGB(240, 206, 151), 1.35, 50, "MeadowBear" },
        { Vector3.new(333, 0, 43), "Guardian_ForestWolf", Color3.fromRGB(83, 103, 88), Color3.fromRGB(172, 193, 165), 1.45, 62, "ForestWolf" },
        { Vector3.new(486, 0, 43), "Guardian_WetlandsCroc", Color3.fromRGB(63, 123, 88), Color3.fromRGB(189, 203, 117), 1.5, 66, "WetlandsCroc" },
        { Vector3.new(642, 0, 43), "Guardian_SnowBear", Color3.fromRGB(220, 235, 242), Color3.fromRGB(102, 178, 205), 1.6, 70, "SnowBear" },
        { Vector3.new(800, 0, 43), "Guardian_SavannahLion", Color3.fromRGB(208, 159, 77), Color3.fromRGB(255, 218, 122), 1.65, 74, "SavannahLion" },
        { Vector3.new(951, 0, 43), "Guardian_VolcanoTitan", Color3.fromRGB(84, 52, 58), Color3.fromRGB(255, 110, 56), 1.8, 80, "VolcanoTitan" },
    }

    for index, guardian in ipairs(guardians) do
        step("Guardian" .. index, function()
            createGuardianBeast(guardian[1], guardian[2], guardian[3], guardian[4], guardian[5], guardian[6], guardian[7])
        end)
        task.wait()
    end

    local baseCount = #basesFolder:GetChildren()
    local animalCount = #animalsFolder:GetChildren()
    local biomeCount = 0
    for _, zone in ipairs(zones) do
        if mapFolder:FindFirstChild(zone[1] .. "Ground") then
            biomeCount += 1
        end
    end
    local ready = mapFolder:FindFirstChild("HubGround") ~= nil
        and mapFolder:FindFirstChild("WorldSpawn") ~= nil
        and baseCount == 8
        and biomeCount == 6
        and animalCount >= #Catalog.All()

    root:SetAttribute("MapReady", ready)
    root:SetAttribute("BaseCount", baseCount)
    root:SetAttribute("AnimalCount", animalCount)
    root:SetAttribute("BiomeCount", biomeCount)

    if not ready then
        warn(string.format("[StealAnAnimal] Partial map: farms=%d, animals=%d, biomes=%d", baseCount, animalCount, biomeCount))
        if not mapFolder:FindFirstChild("HubGround") then
            step("FallbackGround", function()
                part(mapFolder, "HubGround", Vector3.new(150, 2, 150), CFrame.new(0, -1, 0), COLORS.Meadow, Enum.Material.Grass)
            end)
        end
        if not mapFolder:FindFirstChild("WorldSpawn") then
            step("FallbackSpawn", function()
                local spawn = Instance.new("SpawnLocation")
                spawn.Name = "WorldSpawn"
                spawn.Size = Vector3.new(8, 1, 8)
                spawn.Position = Vector3.new(0, 1, 0)
                spawn.Anchored = true
                spawn.Neutral = true
                spawn.Parent = mapFolder
            end)
        end
    else
        print(string.format("[StealAnAnimal] World ready: %d animals, %d biomes, %d farms, %d guardians", animalCount, biomeCount, baseCount, #guardians))
    end
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

function WorldBuilder.GetTrainingParts()
    return allTrainingParts
end

function WorldBuilder.AssignBase(player)
    local current = basesByUserId[player.UserId]
    if current and current.Parent and current:GetAttribute("OwnerUserId") == player.UserId then
        return current
    end

    for _, base in ipairs(basesFolder:GetChildren()) do
        if base:IsA("Model") and base:GetAttribute("OwnerUserId") == 0 then
            base:SetAttribute("OwnerUserId", player.UserId)
            basesByUserId[player.UserId] = base
            player:SetAttribute("OwnedBase", base.Name)
            local sign = base:FindFirstChild("OwnerSign")
            local label = sign and sign:FindFirstChildWhichIsA("BillboardGui", true)
            local card = label and label:FindFirstChildWhichIsA("Frame")
            local title = card and card:FindFirstChild("Title")
            local subtitle = card and card:FindFirstChild("Subtitle")
            if title then
                title.Text = "YOUR FARM"
            end
            if subtitle then
                subtitle.Text = player.DisplayName
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
    local character = player.Character
    if not spawnPart or not character or not character.Parent then
        return false
    end
    pcall(function()
        character:PivotTo(spawnPart.CFrame * CFrame.new(0, 3, 0))
    end)
    return true
end

function WorldBuilder.ReleaseBase(player)
    local base = basesByUserId[player.UserId]
    if base and base.Parent then
        base:SetAttribute("OwnerUserId", 0)
        local sign = base:FindFirstChild("OwnerSign")
        local label = sign and sign:FindFirstChildWhichIsA("BillboardGui", true)
        local card = label and label:FindFirstChildWhichIsA("Frame")
        local title = card and card:FindFirstChild("Title")
        local subtitle = card and card:FindFirstChild("Subtitle")
        if title then
            title.Text = "FARM"
        end
        if subtitle then
            subtitle.Text = "OWNER: FREE"
        end
        local display = base:FindFirstChild("StoredAnimals")
        if display then
            for _, child in ipairs(display:GetChildren()) do
                if child:IsA("Model") and child.Name:match("^Stored_") then
                    child:Destroy()
                end
            end
        end
    end
    basesByUserId[player.UserId] = nil
    player:SetAttribute("OwnedBase", nil)
end

function WorldBuilder.SetBarnAnimals(player, animalIds)
    local base = WorldBuilder.GetOwnedBase(player)
    if not base then
        return false
    end
    local display = base:FindFirstChild("StoredAnimals")
    if not display then
        return false
    end
    local slots = {}
    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("BasePart") and child.Name:match("^AnimalSlot_") then
            table.insert(slots, child)
        end
    end
    table.sort(slots, function(a, b)
        return (a:GetAttribute("SlotIndex") or 0) < (b:GetAttribute("SlotIndex") or 0)
    end)

    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^Stored_") then
            child:Destroy()
        end
    end

    local capacity = Config.Barn.BaseSlots
    if player:GetAttribute("HasExtraBarnSlots") == true then
        capacity += Config.Barn.ExtraBarnSlots
    end

    for index, slot in ipairs(slots) do
        local animalId = animalIds[index]
        local labelPart = display:FindFirstChild("SlotLabel_" .. index)
        local label = labelPart and labelPart:FindFirstChildWhichIsA("BillboardGui", true)
        local card = label and label:FindFirstChildWhichIsA("Frame")
        local title = card and card:FindFirstChild("Title")
        local subtitle = card and card:FindFirstChild("Subtitle")
        if animalId and index <= capacity then
            local spec = Catalog.Get(animalId)
            if spec then
                createBarnAnimalDisplay(display, animalId, slot.Position + Vector3.new(0, 0.1, 0), index)
                if title then
                    title.Text = spec.DisplayName
                end
                if subtitle then
                    subtitle.Text = "$" .. tostring(spec.IncomePerSecond) .. "/s"
                end
                slot.Color = spec.Color
                slot.Transparency = 0.08
            end
        elseif index > capacity then
            if title then
                title.Text = "LOCKED SLOT"
            end
            if subtitle then
                subtitle.Text = "VIP UPGRADE"
            end
            slot.Color = Color3.fromRGB(92, 95, 83)
            slot.Transparency = 0.3
        else
            if title then
                title.Text = "SLOT " .. tostring(index)
            end
            if subtitle then
                subtitle.Text = "EMPTY"
            end
            slot.Color = Color3.fromRGB(223, 213, 177)
            slot.Transparency = 0.08
        end
    end
    return true
end

function WorldBuilder.GetDepositPads()
    local results = {}
    for _, base in ipairs(basesFolder:GetChildren()) do
        local pad = base:FindFirstChild("BarnDepositPad", true)
        if pad then
            table.insert(results, { Base = base, Pad = pad })
        end
    end
    return results
end

function WorldBuilder.GetIncomePads()
    local results = {}
    for _, base in ipairs(basesFolder:GetChildren()) do
        local pad = base:FindFirstChild("IncomeCollectPad", true)
        if pad then
            table.insert(results, { Base = base, Pad = pad })
        end
    end
    return results
end

return WorldBuilder
