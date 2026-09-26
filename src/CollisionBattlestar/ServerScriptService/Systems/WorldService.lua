--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Service = {}

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, transparency: number?, canCollide: boolean?): BasePart
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanTouch = false
    p.CanQuery = true
    p.CanCollide = canCollide ~= false
    p.Transparency = transparency or 0
    p.Material = material
    p.Color = color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function model(parent: Instance, name: string): Model
    local m = Instance.new("Model")
    m.Name = name
    m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    m.Parent = parent
    return m
end

local function neon(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3)
    return part(parent, name, size, cframe, Enum.Material.Neon, color, 0, false)
end

local function building(parent: Instance, rng: Random, origin: Vector3, index: number, district: string)
    local width = rng:NextInteger(42, 68)
    local depth = rng:NextInteger(42, 68)
    local height = rng:NextInteger(34, 104)

    local m = model(parent, district .. "_Building_" .. ("%02d"):format(index))
    local bodyColor = Color3.fromRGB(
        rng:NextInteger(44, 74),
        rng:NextInteger(48, 78),
        rng:NextInteger(58, 90)
    )

    part(
        m,
        "Body",
        Vector3.new(width, height, depth),
        CFrame.new(origin + Vector3.new(0, height / 2, 0)),
        Enum.Material.Concrete,
        bodyColor
    )

    part(
        m,
        "Base",
        Vector3.new(width + 2, 4, depth + 2),
        CFrame.new(origin + Vector3.new(0, 2, 0)),
        Enum.Material.Slate,
        Color3.fromRGB(24, 27, 34)
    )

    part(
        m,
        "Roof",
        Vector3.new(width + 3, 3, depth + 3),
        CFrame.new(origin + Vector3.new(0, height + 1.5, 0)),
        Enum.Material.Metal,
        Color3.fromRGB(18, 22, 30)
    )

    local roofUnit = part(
        m,
        "RoofUnit",
        Vector3.new(math.min(18, width * 0.35), 5, math.min(12, depth * 0.25)),
        CFrame.new(origin + Vector3.new(rng:NextInteger(-8, 8), height + 5, rng:NextInteger(-8, 8))),
        Enum.Material.Metal,
        Color3.fromRGB(33, 37, 46)
    )
    CollectionService:AddTag(roofUnit, "WorldStructure")

    local windowColor = if district == "Industrial" then Color3.fromRGB(112, 126, 116) else Color3.fromRGB(96, 115, 148)
    local rows = math.max(2, math.floor(height / 20))
    local columns = math.max(2, math.floor(width / 18))

    for row = 1, math.min(rows, 4) do
        for col = 1, math.min(columns, 4) do
            local x = -width / 2 + col * (width / (math.min(columns, 4) + 1))
            local y = 9 + row * 16
            if y < height - 5 then
                neon(
                    m,
                    "WindowFront",
                    Vector3.new(5, 3.5, 0.22),
                    CFrame.new(origin + Vector3.new(x, y, -(depth / 2 + 0.13))),
                    windowColor
                )
                neon(
                    m,
                    "WindowBack",
                    Vector3.new(5, 3.5, 0.22),
                    CFrame.new(origin + Vector3.new(x, y, depth / 2 + 0.13)),
                    windowColor
                )
            end
        end
    end

    local doorWidth = math.min(9, width * 0.22)
    part(
        m,
        "Door",
        Vector3.new(doorWidth, 14, 0.5),
        CFrame.new(origin + Vector3.new(0, 7, -(depth / 2 + 0.25))),
        Enum.Material.Metal,
        Color3.fromRGB(30, 34, 42)
    )

    CollectionService:AddTag(m:FindFirstChild("Body") :: BasePart, "WorldStructure")
end

local function road(parent: Instance, axis: "X" | "Z", coordinate: number, width: number, size: number)
    local isX = axis == "X"
    local roadPart = part(
        parent,
        "Road_" .. axis,
        if isX then Vector3.new(size, 0.3, width) else Vector3.new(width, 0.3, size),
        CFrame.new(if isX then 0 else coordinate, 0.2, if isX then coordinate else 0),
        Enum.Material.Asphalt,
        Color3.fromRGB(38, 41, 48)
    )
    roadPart.CanQuery = false
    for offset = -size / 2 + 28, size / 2 - 28, 84 do
        neon(
            parent,
            "Lane",
            if isX then Vector3.new(44, 0.08, 0.35) else Vector3.new(0.35, 0.08, 44),
            CFrame.new(if isX then offset else coordinate, 0.42, if isX then coordinate else offset),
            Color3.fromRGB(118, 124, 132)
        )
    end
end

local function sidewalk(parent: Instance, axis: "X" | "Z", coordinate: number, roadWidth: number, sidewalkWidth: number, size: number)
    local isX = axis == "X"
    local sideA = if isX then Vector3.new(size, 0.5, sidewalkWidth) else Vector3.new(sidewalkWidth, 0.5, size)
    local offsetA = roadWidth / 2 + sidewalkWidth / 2
    for _, direction in ipairs({-1, 1}) do
        local pos = if isX
            then Vector3.new(0, 0.45, coordinate + direction * offsetA)
            else Vector3.new(coordinate + direction * offsetA, 0.45, 0)
        part(parent, "Sidewalk", sideA, CFrame.new(pos), Enum.Material.Concrete, Color3.fromRGB(94, 97, 104))
    end
end

local function barrier(parent: Instance, origin: Vector3, rotation: number)
    local m = model(parent, "Barrier")
    local base = part(m, "Base", Vector3.new(10, 1.8, 3), CFrame.new(origin), Enum.Material.Concrete, Color3.fromRGB(55, 59, 67))
    base.CFrame *= CFrame.Angles(0, math.rad(rotation), 0)
    for x = -3, 3, 3 do
        local post = part(m, "Post", Vector3.new(0.8, 4, 0.8), CFrame.new(origin + Vector3.new(x, 2.5, 0)) * CFrame.Angles(0, math.rad(rotation), 0), Enum.Material.Metal, Color3.fromRGB(40, 44, 52))
    end
end

local function crate(parent: Instance, origin: Vector3, scale: number, rotation: number)
    local m = model(parent, "CrateStack")
    local a = part(m, "A", Vector3.new(6, 6, 6) * scale, CFrame.new(origin) * CFrame.Angles(0, math.rad(rotation), 0), Enum.Material.WoodPlanks, Color3.fromRGB(113, 92, 65))
    part(m, "B", Vector3.new(5, 5, 5) * scale, a.CFrame * CFrame.new(2.7 * scale, 5.2 * scale, 0), Enum.Material.WoodPlanks, Color3.fromRGB(88, 72, 52))
end

local function streetMarker(parent: Instance, origin: Vector3, text: string)
    local m = model(parent, "DistrictMarker")
    part(m, "Post", Vector3.new(1.2, 12, 1.2), CFrame.new(origin + Vector3.new(0, 6, 0)), Enum.Material.Metal, Color3.fromRGB(38, 42, 50))
    local plate = part(m, "Plate", Vector3.new(11, 3.5, 0.35), CFrame.new(origin + Vector3.new(0, 10, 0)), Enum.Material.Metal, Color3.fromRGB(22, 26, 34))
    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.AlwaysOnTop = true
    surface.LightInfluence = 0
    surface.Parent = plate

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 239, 245)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = surface
end

local function arenaCover(parent: Instance, origin: Vector3, size: Vector3, rotation: number)
    local m = model(parent, "ArenaCover")
    local wall = part(
        m,
        "Wall",
        size,
        CFrame.new(origin) * CFrame.Angles(0, math.rad(rotation), 0),
        Enum.Material.Concrete,
        Color3.fromRGB(68, 72, 82)
    )
    CollectionService:AddTag(wall, "ArenaCover")

    local trim = neon(
        m,
        "Trim",
        Vector3.new(size.X, 0.25, 0.25),
        wall.CFrame * CFrame.new(0, size.Y / 2 - 0.2, -size.Z / 2 - 0.15),
        Color3.fromRGB(112, 118, 132)
    )
    trim.CFrame = wall.CFrame * CFrame.new(0, size.Y / 2 - 0.2, -size.Z / 2 - 0.15)
end

local function spawnPoint(parent: Instance, name: string, position: Vector3)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(4, 1, 4)
    p.Position = position
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Transparency = 1
    p.Parent = parent
end

local function addEnemySpawnRing(parent: Instance)
    local radii = {52, 78, 104}
    local index = 0

    for _, radius in ipairs(radii) do
        local count = if radius == 104 then 12 else 8
        for i = 1, count do
            index += 1
            local angle = (i / count) * math.pi * 2 + math.rad(index * 7)
            spawnPoint(
                parent,
                ("EnemySpawn_%02d"):format(index),
                Vector3.new(math.cos(angle) * radius, 9, math.sin(angle) * radius)
            )
        end
    end
end

function Service:Init(config)
    local old = workspace:FindFirstChild("GeneratedWorld")
    if old then
        old:Destroy()
    end

    for _, name in ipairs({"TagSpawns", "ArenaEnemySpawns"}) do
        local oldFolder = workspace:FindFirstChild(name)
        if oldFolder then
            oldFolder:Destroy()
        end
    end

    Lighting.Brightness = 2.2
    Lighting.ClockTime = 17.7
    Lighting.EnvironmentDiffuseScale = 0.6
    Lighting.EnvironmentSpecularScale = 0.7
    Lighting.GlobalShadows = true

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.28
    atmosphere.Offset = 0.08
    atmosphere.Haze = 1.2
    atmosphere.Glare = 0.12
    atmosphere.Color = Color3.fromRGB(196, 204, 220)
    atmosphere.Decay = Color3.fromRGB(90, 98, 116)

    local world = Instance.new("Folder")
    world.Name = "GeneratedWorld"
    world.Parent = workspace

    local rng = Random.new(config.World.Seed)
    local size = config.World.Size
    local roadWidth = config.World.RoadWidth
    local sidewalkWidth = 6

    part(world, "Ground", Vector3.new(size, 2, size), CFrame.new(0, -1, 0), Enum.Material.Asphalt, Color3.fromRGB(26, 29, 35))

    local roads = Instance.new("Folder")
    roads.Name = "Roads"
    roads.Parent = world
    for coordinate = -480, 480, 96 do
        road(roads, "X", coordinate, roadWidth, size)
        sidewalk(roads, "X", coordinate, roadWidth, sidewalkWidth, size)
        road(roads, "Z", coordinate, roadWidth, size)
        sidewalk(roads, "Z", coordinate, roadWidth, sidewalkWidth, size)
    end

    local arena = model(world, "CombatArena")
    part(arena, "ArenaFloor", Vector3.new(228, 4, 228), CFrame.new(0, 1, 0), Enum.Material.Concrete, Color3.fromRGB(46, 50, 59))
    part(arena, "ArenaCore", Vector3.new(128, 3, 128), CFrame.new(0, 4.5, 0), Enum.Material.Metal, Color3.fromRGB(31, 36, 45))
    neon(arena, "CoreLine", Vector3.new(118, 0.3, 4), CFrame.new(0, 6.1, 0), Color3.fromRGB(88, 104, 128))
    neon(arena, "CoreLine2", Vector3.new(4, 0.3, 118), CFrame.new(0, 6.12, 0), Color3.fromRGB(88, 104, 128))

    for _, edge in ipairs({
        {Vector3.new(0, 10, -114), Vector3.new(228, 20, 4)},
        {Vector3.new(0, 10, 114), Vector3.new(228, 20, 4)},
        {Vector3.new(-114, 10, 0), Vector3.new(4, 20, 228)},
        {Vector3.new(114, 10, 0), Vector3.new(4, 20, 228)},
    }) do
        part(arena, "ArenaWall", edge[2], CFrame.new(edge[1]), Enum.Material.Concrete, Color3.fromRGB(35, 39, 47))
    end

    for i = 1, 12 do
        local angle = math.rad(i * 30)
        local radius = 72
        arenaCover(
            arena,
            Vector3.new(math.cos(angle) * radius, 7, math.sin(angle) * radius),
            Vector3.new(18, 14, 6 + (i % 3) * 2),
            i * 13
        )
    end

    for i = 1, 8 do
        local angle = math.rad(i * 45 + 22.5)
        local radius = 94
        local position = Vector3.new(math.cos(angle) * radius, 6, math.sin(angle) * radius)
        local m = model(arena, "ArenaPillar")
        part(m, "Pillar", Vector3.new(8, 12 + (i % 2) * 4, 8), CFrame.new(position), Enum.Material.Brick, Color3.fromRGB(61, 66, 76))
        neon(m, "Signal", Vector3.new(8.5, 0.5, 8.5), CFrame.new(position + Vector3.new(0, 6 + (i % 2) * 2, 0)), Color3.fromRGB(100, 116, 142))
    end

    local structures = Instance.new("Folder")
    structures.Name = "Districts"
    structures.Parent = world

    local buildingIndex = 0
    local districts = {
        {Name = "North", z = -330, x = 0},
        {Name = "South", z = 330, x = 0},
        {Name = "East", z = 0, x = 330},
        {Name = "West", z = 0, x = -330},
    }

    for _, district in ipairs(districts) do
        for localX = -1, 1 do
            for localZ = -1, 1 do
                buildingIndex += 1
                local origin = Vector3.new(
                    district.x + localX * 112 + rng:NextInteger(-18, 18),
                    0,
                    district.z + localZ * 112 + rng:NextInteger(-18, 18)
                )
                building(structures, rng, origin, buildingIndex, if district.Name == "South" then "Industrial" else district.Name)
            end
        end
    end

    local detail = Instance.new("Folder")
    detail.Name = "StreetDetail"
    detail.Parent = world

    for i = 1, 24 do
        local x = rng:NextInteger(-520, 520)
        local z = rng:NextInteger(-520, 520)
        if math.abs(x) > 150 and math.abs(z) > 150 then
            barrier(detail, Vector3.new(x, 1, z), rng:NextInteger(0, 3) * 45)
        end
    end

    for i = 1, 20 do
        local x = rng:NextInteger(-520, 520)
        local z = rng:NextInteger(-520, 520)
        if math.abs(x) > 160 and math.abs(z) > 160 then
            crate(detail, Vector3.new(x, 3, z), rng:NextInteger(8, 12) / 10, rng:NextInteger(0, 3) * 90)
        end
    end

    streetMarker(detail, Vector3.new(-170, 0, -505), "NORTH BLOCK")
    streetMarker(detail, Vector3.new(170, 0, 505), "SOUTH YARD")
    streetMarker(detail, Vector3.new(-505, 0, 170), "WEST MARKET")
    streetMarker(detail, Vector3.new(505, 0, -170), "EAST DISTRICT")

    local overpass = model(structures, "Overpass")
    part(overpass, "Deck", Vector3.new(360, 7, 22), CFrame.new(0, 28, 450), Enum.Material.Metal, Color3.fromRGB(47, 52, 61))
    for x = -150, 150, 50 do
        part(overpass, "Pylon", Vector3.new(7, 56, 7), CFrame.new(x, 0, 450), Enum.Material.Metal, Color3.fromRGB(35, 40, 48))
    end
    neon(overpass, "Edge", Vector3.new(340, 0.35, 0.35), CFrame.new(0, 31.6, 437), Color3.fromRGB(92, 104, 124))

    local ramps = model(structures, "ArenaApproaches")
    for _, data in ipairs({
        {Vector3.new(0, 1, -168), 34},
        {Vector3.new(0, 1, 168), 214},
        {Vector3.new(-168, 1, 0), 304},
        {Vector3.new(168, 1, 0), 124},
    }) do
        local r = part(ramps, "Approach", Vector3.new(44, 2, 34), CFrame.new(data[1]) * CFrame.Angles(0, math.rad(data[2]), 0), Enum.Material.Concrete, Color3.fromRGB(75, 78, 86))
        r.CanQuery = true
    end

    local spawns = Instance.new("Folder")
    spawns.Name = "TagSpawns"
    spawns.Parent = workspace

    for index, position in ipairs({
        Vector3.new(-42, 8, -42),
        Vector3.new(42, 8, -42),
        Vector3.new(-42, 8, 42),
        Vector3.new(42, 8, 42),
    }) do
        spawnPoint(spawns, ("Spawn_%02d"):format(index), position)
    end

    local enemySpawns = Instance.new("Folder")
    enemySpawns.Name = "ArenaEnemySpawns"
    enemySpawns.Parent = workspace
    addEnemySpawnRing(enemySpawns)

    local mainSpawn = workspace:FindFirstChild("MainSpawn")
    if mainSpawn then
        mainSpawn:Destroy()
    end

    local start = Instance.new("SpawnLocation")
    start.Name = "MainSpawn"
    start.Size = Vector3.new(18, 1, 18)
    start.Position = Vector3.new(0, 8, 0)
    start.Anchored = true
    start.Neutral = true
    start.Transparency = 1
    start.CanTouch = false
    start.CanQuery = false
    start.Parent = workspace
end

return Service
