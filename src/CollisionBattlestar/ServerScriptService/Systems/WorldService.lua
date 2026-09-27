--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Service = {}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, transparency: number?, collide: boolean?): BasePart
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanTouch = false
    p.CanQuery = collide ~= false
    p.CanCollide = collide ~= false
    p.Transparency = transparency or 0
    p.Material = material
    p.Color = color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function newModel(parent: Instance, name: string): Model
    local m = Instance.new("Model")
    m.Name = name
    m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    m.Parent = parent
    return m
end

local function neon(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): BasePart
    return makePart(parent, name, size, cframe, Enum.Material.Neon, color, 0, false)
end

local function addLabel(parent: BasePart, textValue: string, accent: Color3)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Sign"
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 32
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
    label.BackgroundTransparency = 0.12
    label.Size = UDim2.fromScale(1, 1)
    label.Text = textValue
    label.TextColor3 = accent
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextStrokeTransparency = 0.7
    label.Parent = gui
end

local function addStreetLamp(parent: Instance, position: Vector3, rotation: number)
    local m = newModel(parent, "StreetLamp")
    local pole = makePart(m, "Pole", Vector3.new(0.75, 13, 0.75), CFrame.new(position + Vector3.new(0, 6.5, 0)), Enum.Material.Metal, Color3.fromRGB(39, 44, 53))
    local arm = makePart(m, "Arm", Vector3.new(5, 0.45, 0.45), CFrame.new(position + Vector3.new(2.1, 12.4, 0)) * CFrame.Angles(0, math.rad(rotation), 0), Enum.Material.Metal, Color3.fromRGB(55, 60, 70))
    local head = neon(m, "Lamp", Vector3.new(1.4, 0.35, 1.4), arm.CFrame * CFrame.new(2.15, -0.25, 0), Color3.fromRGB(214, 231, 255))
    local light = Instance.new("PointLight")
    light.Range = 24
    light.Brightness = 1.65
    light.Color = Color3.fromRGB(205, 221, 255)
    light.Shadows = true
    light.Parent = head
    pole.CFrame *= CFrame.Angles(0, math.rad(rotation), 0)
end

local function addTree(parent: Instance, position: Vector3, scale: number)
    local m = newModel(parent, "StreetTree")
    makePart(m, "Trunk", Vector3.new(1.2, 7, 1.2) * scale, CFrame.new(position + Vector3.new(0, 3.5 * scale, 0)), Enum.Material.Wood, Color3.fromRGB(74, 58, 45))
    local crown = makePart(m, "Crown", Vector3.new(6.5, 6.5, 6.5) * scale, CFrame.new(position + Vector3.new(0, 8 * scale, 0)), Enum.Material.Grass, Color3.fromRGB(55, 85, 67))
    crown.Shape = Enum.PartType.Ball
end

local function makeBuilding(parent: Instance, rng: Random, origin: Vector3, index: number, districtName: string)
    local width = rng:NextInteger(38, 62)
    local depth = rng:NextInteger(38, 62)
    local height = rng:NextInteger(30, 96)
    local m = newModel(parent, ("%s_%02d"):format(districtName, index))

    local palettes = {
        Color3.fromRGB(48, 55, 68),
        Color3.fromRGB(55, 60, 72),
        Color3.fromRGB(62, 67, 78),
        Color3.fromRGB(72, 68, 74),
        Color3.fromRGB(42, 58, 62),
    }
    local bodyColor = palettes[rng:NextInteger(1, #palettes)]
    local accentPool = {
        Color3.fromRGB(95, 181, 255),
        Color3.fromRGB(134, 116, 255),
        Color3.fromRGB(93, 222, 190),
        Color3.fromRGB(255, 181, 100),
        Color3.fromRGB(255, 101, 127),
    }
    local accent = accentPool[rng:NextInteger(1, #accentPool)]

    local body = makePart(m, "Body", Vector3.new(width, height, depth), CFrame.new(origin + Vector3.new(0, height / 2, 0)), Enum.Material.Concrete, bodyColor)
    CollectionService:AddTag(body, "WorldStructure")

    makePart(m, "Podium", Vector3.new(width + 4, 4, depth + 4), CFrame.new(origin + Vector3.new(0, 2, 0)), Enum.Material.Slate, Color3.fromRGB(27, 31, 39))
    makePart(m, "Roof", Vector3.new(width + 2, 2.5, depth + 2), CFrame.new(origin + Vector3.new(0, height + 1.25, 0)), Enum.Material.Metal, Color3.fromRGB(22, 25, 31))

    local floors = math.clamp(math.floor(height / 15), 2, 5)
    local windowColumns = math.clamp(math.floor(width / 14), 2, 4)
    for floor = 1, floors do
        local y = 7 + floor * 15
        if y < height - 3 then
            for column = 1, windowColumns do
                local x = -width / 2 + column * (width / (windowColumns + 1))
                neon(m, "WindowFront", Vector3.new(4.2, 3.2, 0.18), CFrame.new(origin + Vector3.new(x, y, -depth / 2 - 0.12)), accent)
                neon(m, "WindowSide", Vector3.new(0.18, 3.2, 4.2), CFrame.new(origin + Vector3.new(depth / 2 + 0.12, y, x)), accent)
            end
        end
    end

    local door = makePart(m, "Door", Vector3.new(math.min(9, width * 0.2), 13, 0.5), CFrame.new(origin + Vector3.new(0, 6.5, -depth / 2 - 0.28)), Enum.Material.Metal, Color3.fromRGB(20, 24, 30))
    local sign = makePart(m, "Sign", Vector3.new(math.min(20, width * 0.5), 3, 0.35), CFrame.new(origin + Vector3.new(0, math.min(height - 7, 22), -depth / 2 - 0.25)), Enum.Material.Metal, Color3.fromRGB(14, 17, 23))
    addLabel(sign, districtName:upper(), accent)
    door.Parent = m

    if rng:NextNumber() > 0.35 then
        local rooftop = makePart(m, "RoofMachine", Vector3.new(rng:NextInteger(8, 14), rng:NextInteger(3, 6), rng:NextInteger(5, 10)), CFrame.new(origin + Vector3.new(rng:NextInteger(-8, 8), height + 4, rng:NextInteger(-8, 8))), Enum.Material.Metal, Color3.fromRGB(37, 42, 50))
        CollectionService:AddTag(rooftop, "WorldStructure")
    end
end

local function road(parent: Instance, axis: "X" | "Z", coordinate: number, size: number, width: number)
    local alongX = axis == "X"
    makePart(
        parent,
        "Road",
        if alongX then Vector3.new(size, 0.25, width) else Vector3.new(width, 0.25, size),
        if alongX then CFrame.new(0, 0.18, coordinate) else CFrame.new(coordinate, 0.18, 0),
        Enum.Material.Asphalt,
        Color3.fromRGB(31, 34, 42),
        0,
        false
    )

    for offset = -size / 2 + 24, size / 2 - 24, 72 do
        neon(
            parent,
            "LaneMarker",
            if alongX then Vector3.new(34, 0.08, 0.22) else Vector3.new(0.22, 0.08, 34),
            if alongX then CFrame.new(offset, 0.37, coordinate) else CFrame.new(coordinate, 0.37, offset),
            Color3.fromRGB(121, 127, 139)
        )
    end

    for offset = -size / 2 + 50, size / 2 - 50, 120 do
        local position = if alongX then Vector3.new(offset, 0, coordinate) else Vector3.new(coordinate, 0, offset)
        addStreetLamp(parent, position + if alongX then Vector3.new(0, 0, width / 2 + 4) else Vector3.new(width / 2 + 4, 0, 0), if alongX then 90 else 0)
    end
end

local function sidewalk(parent: Instance, axis: "X" | "Z", coordinate: number, size: number, roadWidth: number)
    local alongX = axis == "X"
    for _, side in ipairs({-1, 1}) do
        local center = if alongX
            then Vector3.new(0, 0.48, coordinate + side * (roadWidth / 2 + 5))
            else Vector3.new(coordinate + side * (roadWidth / 2 + 5), 0.48, 0)
        makePart(
            parent,
            "Sidewalk",
            if alongX then Vector3.new(size, 0.75, 9) else Vector3.new(9, 0.75, size),
            CFrame.new(center),
            Enum.Material.Concrete,
            Color3.fromRGB(77, 81, 91)
        )
    end
end

local function crosswalk(parent: Instance, center: Vector3, horizontal: boolean)
    for index = -4, 4 do
        local size = if horizontal then Vector3.new(3.5, 0.08, 20) else Vector3.new(20, 0.08, 3.5)
        local offset = if horizontal then Vector3.new(index * 4.3, 0, 0) else Vector3.new(0, 0, index * 4.3)
        makePart(parent, "Crosswalk", size, CFrame.new(center + offset + Vector3.new(0, 0.08, 0)), Enum.Material.Concrete, Color3.fromRGB(201, 204, 208), 0, false)
    end
end

local function arena(parent: Instance)
    local m = newModel(parent, "CentralCombatPlaza")
    makePart(m, "Floor", Vector3.new(230, 4, 230), CFrame.new(0, 2, 0), Enum.Material.Concrete, Color3.fromRGB(48, 53, 63))
    makePart(m, "Core", Vector3.new(154, 2.5, 154), CFrame.new(0, 5.2, 0), Enum.Material.Metal, Color3.fromRGB(26, 31, 40))
    neon(m, "CoreX", Vector3.new(132, 0.26, 3.2), CFrame.new(0, 6.58, 0), Color3.fromRGB(98, 128, 183))
    neon(m, "CoreZ", Vector3.new(3.2, 0.26, 132), CFrame.new(0, 6.6, 0), Color3.fromRGB(98, 128, 183))

    for _, edge in ipairs({
        {Vector3.new(0, 13, -115), Vector3.new(230, 26, 5)},
        {Vector3.new(0, 13, 115), Vector3.new(230, 26, 5)},
        {Vector3.new(-115, 13, 0), Vector3.new(5, 26, 230)},
        {Vector3.new(115, 13, 0), Vector3.new(5, 26, 230)},
    }) do
        makePart(m, "Boundary", edge[2], CFrame.new(edge[1]), Enum.Material.Concrete, Color3.fromRGB(28, 33, 42))
    end

    for index = 1, 8 do
        local angle = math.rad(index * 45)
        local position = Vector3.new(math.cos(angle) * 82, 6, math.sin(angle) * 82)
        local cover = makePart(m, "Cover", Vector3.new(22, 12 + (index % 2) * 4, 7), CFrame.new(position) * CFrame.Angles(0, angle + math.rad(90), 0), Enum.Material.Concrete, Color3.fromRGB(65, 71, 82))
        CollectionService:AddTag(cover, "ArenaCover")
        neon(m, "CoverTrim", Vector3.new(18, 0.25, 0.25), cover.CFrame * CFrame.new(0, cover.Size.Y / 2 - 0.3, -cover.Size.Z / 2 - 0.2), Color3.fromRGB(102, 127, 177))
    end

    for index = 1, 8 do
        local angle = math.rad(index * 45 + 22.5)
        local position = Vector3.new(math.cos(angle) * 98, 8, math.sin(angle) * 98)
        makePart(m, "Pillar", Vector3.new(8, 16, 8), CFrame.new(position), Enum.Material.Brick, Color3.fromRGB(57, 63, 74))
        neon(m, "PillarCap", Vector3.new(8.4, 0.45, 8.4), CFrame.new(position + Vector3.new(0, 8, 0)), Color3.fromRGB(104, 122, 164))
    end

    local spawn = Instance.new("Folder")
    spawn.Name = "TagSpawns"
    spawn.Parent = workspace
    for index, position in ipairs({
        Vector3.new(-42, 9, -42),
        Vector3.new(42, 9, -42),
        Vector3.new(-42, 9, 42),
        Vector3.new(42, 9, 42),
        Vector3.new(0, 9, -60),
        Vector3.new(0, 9, 60),
        Vector3.new(-60, 9, 0),
        Vector3.new(60, 9, 0),
    }) do
        local marker = makePart(spawn, ("Spawn_%02d"):format(index), Vector3.new(4, 1, 4), CFrame.new(position), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1, false)
        marker.CanQuery = false
    end
end

local function spawnRings()
    local folder = Instance.new("Folder")
    folder.Name = "ArenaEnemySpawns"
    folder.Parent = workspace
    local index = 0
    for _, data in ipairs({{54, 10}, {76, 12}, {100, 16}}) do
        local radius = data[1]
        local count = data[2]
        for step = 1, count do
            index += 1
            local angle = step / count * math.pi * 2 + index * 0.14
            local p = makePart(folder, ("EnemySpawn_%02d"):format(index), Vector3.new(3, 1, 3), CFrame.new(math.cos(angle) * radius, 9, math.sin(angle) * radius), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1, false)
            p.CanQuery = false
        end
    end
end

local function cleanup()
    for _, name in ipairs({"GeneratedWorld", "TagSpawns", "ArenaEnemySpawns", "MainSpawn"}) do
        local old = workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
end

function Service:Init(config)
    cleanup()

    local okStyle = pcall(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
    end)
    if not okStyle then
        pcall(function()
            Lighting.LightingStyle = Enum.LightingStyle.Soft
        end)
    end

    Lighting.Brightness = 2.1
    Lighting.ClockTime = 18.15
    Lighting.ExposureCompensation = -0.12
    Lighting.EnvironmentDiffuseScale = 0.48
    Lighting.EnvironmentSpecularScale = 0.72
    Lighting.GlobalShadows = true
    Lighting.PrioritizeLightingQuality = true

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.16
    atmosphere.Offset = 0.04
    atmosphere.Haze = 1.1
    atmosphere.Glare = 0.14
    atmosphere.Color = Color3.fromRGB(201, 210, 227)
    atmosphere.Decay = Color3.fromRGB(91, 103, 131)

    local color = Lighting:FindFirstChild("CBS_ColorGrade")
    if not color then
        color = Instance.new("ColorCorrectionEffect")
        color.Name = "CBS_ColorGrade"
        color.Parent = Lighting
    end
    color.Brightness = -0.02
    color.Contrast = 0.14
    color.Saturation = -0.04
    color.TintColor = Color3.fromRGB(226, 233, 255)

    local bloom = Lighting:FindFirstChild("CBS_Bloom")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "CBS_Bloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.18
    bloom.Size = 24
    bloom.Threshold = 1.15

    local world = Instance.new("Folder")
    world.Name = "GeneratedWorld"
    world.Parent = workspace

    local city = Instance.new("Folder")
    city.Name = "City"
    city.Parent = world

    local roads = Instance.new("Folder")
    roads.Name = "Roads"
    roads.Parent = city

    local size = math.max(1200, tonumber(config.World.Size) or 1200)
    local roadStep = 240
    local roadWidth = math.max(32, tonumber(config.World.RoadWidth) or 34)

    for coordinate = -480, 480, roadStep do
        road(roads, "X", coordinate, size, roadWidth)
        sidewalk(roads, "X", coordinate, size, roadWidth)
        road(roads, "Z", coordinate, size, roadWidth)
        sidewalk(roads, "Z", coordinate, size, roadWidth)
        crosswalk(roads, Vector3.new(0, 0, coordinate), true)
        crosswalk(roads, Vector3.new(coordinate, 0, 0), false)
    end

    local blocks = Instance.new("Folder")
    blocks.Name = "Blocks"
    blocks.Parent = city

    local rng = Random.new(config.World.Seed)
    local blockCenters = {
        {Vector3.new(-360, 0, -360), "NORTHWEST"},
        {Vector3.new(0, 0, -360), "NORTH"},
        {Vector3.new(360, 0, -360), "NORTHEAST"},
        {Vector3.new(-360, 0, 0), "WEST"},
        {Vector3.new(360, 0, 0), "EAST"},
        {Vector3.new(-360, 0, 360), "SOUTHWEST"},
        {Vector3.new(0, 0, 360), "SOUTH"},
        {Vector3.new(360, 0, 360), "SOUTHEAST"},
    }

    local buildingIndex = 0
    for _, entry in ipairs(blockCenters) do
        local center = entry[1] :: Vector3
        local district = entry[2] :: string
        for x = -1, 1 do
            for z = -1, 1 do
                if not (math.abs(center.X) < 1 and math.abs(center.Z) < 1) then
                    buildingIndex += 1
                    local offset = Vector3.new(x * 54 + rng:NextInteger(-10, 10), 0, z * 54 + rng:NextInteger(-10, 10))
                    makeBuilding(blocks, rng, center + offset, buildingIndex, district)
                end
            end
        end
    end

    local detail = Instance.new("Folder")
    detail.Name = "Landmarks"
    detail.Parent = world

    arena(detail)

    local boulevard = newModel(detail, "BoulevardMonument")
    makePart(boulevard, "Base", Vector3.new(72, 4, 72), CFrame.new(0, 8, -300), Enum.Material.Slate, Color3.fromRGB(35, 40, 49))
    for index = 1, 4 do
        local p = makePart(boulevard, "Pillar", Vector3.new(9, 34, 9), CFrame.new(-20 + index * 13, 27, -300), Enum.Material.Brick, Color3.fromRGB(64, 69, 80))
        neon(boulevard, "PillarLight", Vector3.new(9.2, 0.35, 9.2), CFrame.new(p.Position + Vector3.new(0, 17, 0)), Color3.fromRGB(106, 131, 182))
    end

    local elevated = newModel(detail, "Skybridge")
    makePart(elevated, "Deck", Vector3.new(330, 6, 20), CFrame.new(0, 34, 420), Enum.Material.Metal, Color3.fromRGB(42, 47, 57))
    for x = -125, 125, 50 do
        makePart(elevated, "Support", Vector3.new(5.5, 68, 5.5), CFrame.new(x, 0, 420), Enum.Material.Metal, Color3.fromRGB(33, 38, 47))
    end
    neon(elevated, "Edge", Vector3.new(316, 0.3, 0.3), CFrame.new(0, 37.2, 410), Color3.fromRGB(102, 124, 171))

    for _, position in ipairs({
        Vector3.new(-140, 0, -140), Vector3.new(140, 0, -140),
        Vector3.new(-140, 0, 140), Vector3.new(140, 0, 140),
        Vector3.new(-420, 0, 140), Vector3.new(420, 0, -140),
        Vector3.new(-140, 0, 420), Vector3.new(140, 0, -420),
    }) do
        addTree(detail, position, rng:NextNumber(0.8, 1.2))
    end

    for _, position in ipairs({
        Vector3.new(-96, 0, -96), Vector3.new(96, 0, -96),
        Vector3.new(-96, 0, 96), Vector3.new(96, 0, 96),
    }) do
        addStreetLamp(detail, position, 45)
    end

    spawnRings()

    local start = Instance.new("SpawnLocation")
    start.Name = "MainSpawn"
    start.Size = Vector3.new(18, 1, 18)
    start.Position = Vector3.new(0, 10, 0)
    start.Anchored = true
    start.Neutral = true
    start.Transparency = 1
    start.CanTouch = false
    start.CanQuery = false
    start.Parent = workspace

    workspace:SetAttribute("CBSWorldVersion", "urban-world-v6")
end

return Service
