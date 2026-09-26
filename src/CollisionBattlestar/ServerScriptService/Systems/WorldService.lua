--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Service = {}

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3): BasePart
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanTouch = false
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
    m.Parent = parent
    return m
end

local function building(parent: Instance, rng: Random, origin: Vector3, index: number)
    local width = rng:NextInteger(34, 56)
    local depth = rng:NextInteger(34, 56)
    local height = rng:NextInteger(28, 96)

    local m = model(parent, ("Building_%02d"):format(index))
    local base = part(
        m,
        "Body",
        Vector3.new(width, height, depth),
        CFrame.new(origin + Vector3.new(0, height / 2, 0)),
        Enum.Material.Concrete,
        Color3.fromRGB(rng:NextInteger(48, 78), rng:NextInteger(50, 82), rng:NextInteger(58, 92))
    )

    part(
        m,
        "Roof",
        Vector3.new(width + 2, 2, depth + 2),
        CFrame.new(origin + Vector3.new(0, height + 1, 0)),
        Enum.Material.Metal,
        Color3.fromRGB(20, 24, 32)
    )

    local door = part(
        m,
        "Door",
        Vector3.new(math.min(8, width * 0.25), math.min(12, height * 0.25), 0.4),
        CFrame.new(origin + Vector3.new(0, math.min(8, height * 0.25), -(depth / 2 + 0.2))),
        Enum.Material.Metal,
        Color3.fromRGB(30, 34, 42)
    )

    local windowRows = math.max(1, math.floor(height / 18))
    local windowCols = math.max(1, math.floor(width / 13))

    for row = 1, windowRows do
        for col = 1, windowCols do
            local x = -width / 2 + col * (width / (windowCols + 1))
            local y = 10 + row * 14
            if y < height - 4 then
                part(
                    m,
                    "Window",
                    Vector3.new(4, 5, 0.25),
                    CFrame.new(origin + Vector3.new(x, y, -(depth / 2 + 0.14))),
                    Enum.Material.Glass,
                    Color3.fromRGB(90, 105, 130)
                )
            end
        end
    end

    CollectionService:AddTag(base, "WorldStructure")
end

local function tower(parent: Instance, origin: Vector3, height: number)
    local m = model(parent, "Tower")
    part(
        m,
        "Core",
        Vector3.new(22, height, 22),
        CFrame.new(origin + Vector3.new(0, height / 2, 0)),
        Enum.Material.Brick,
        Color3.fromRGB(34, 38, 48)
    )

    for y = 12, height - 6, 12 do
        part(
            m,
            "Ring",
            Vector3.new(28, 2, 28),
            CFrame.new(origin + Vector3.new(0, y, 0)),
            Enum.Material.Metal,
            Color3.fromRGB(58, 65, 78)
        )
    end
end

local function cover(parent: Instance, origin: Vector3, size: Vector3, rotation: number)
    local m = model(parent, "Cover")
    part(
        m,
        "Wall",
        size,
        CFrame.new(origin) * CFrame.Angles(0, math.rad(rotation), 0),
        Enum.Material.Concrete,
        Color3.fromRGB(72, 76, 84)
    )
end

local function container(parent: Instance, origin: Vector3, rotation: number)
    local m = model(parent, "Container")
    part(
        m,
        "Body",
        Vector3.new(18, 8, 42),
        CFrame.new(origin) * CFrame.Angles(0, math.rad(rotation), 0),
        Enum.Material.Metal,
        Color3.fromRGB(54, 66, 78)
    )
end

local function ramp(parent: Instance, origin: Vector3, length: number, width: number, height: number, rotation: number)
    local m = model(parent, "Ramp")
    local cframe = CFrame.new(origin) * CFrame.Angles(math.rad(-math.deg(math.atan2(height, length))), math.rad(rotation), 0)
    part(
        m,
        "Surface",
        Vector3.new(width, 2, length),
        cframe,
        Enum.Material.Concrete,
        Color3.fromRGB(82, 86, 96)
    )
end

local function spawnPoint(parent: Instance, name: string, position: Vector3)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(4, 1, 4)
    p.Position = position
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.Transparency = 1
    p.Parent = parent
end

function Service:Init(config)
    local old = workspace:FindFirstChild("GeneratedWorld")
    if old then
        old:Destroy()
    end

    local oldSpawns = workspace:FindFirstChild("TagSpawns")
    if oldSpawns then
        oldSpawns:Destroy()
    end

    Lighting.Brightness = 2
    Lighting.ClockTime = 17.4
    Lighting.EnvironmentDiffuseScale = 0.55
    Lighting.EnvironmentSpecularScale = 0.75
    Lighting.GlobalShadows = true

    local world = Instance.new("Folder")
    world.Name = "GeneratedWorld"
    world.Parent = workspace

    local rng = Random.new(config.World.Seed)
    local size = config.World.Size
    local step = config.World.BlockSize
    local road = config.World.RoadWidth

    part(world, "Ground", Vector3.new(size, 2, size), CFrame.new(0, -1, 0), Enum.Material.Asphalt, Color3.fromRGB(32, 34, 40))

    local roads = Instance.new("Folder")
    roads.Name = "Roads"
    roads.Parent = world

    for coordinate = -420, 420, step do
        part(roads, "RoadX", Vector3.new(road, 0.3, size), CFrame.new(coordinate, 0.2, 0), Enum.Material.Slate, Color3.fromRGB(46, 48, 55))
        part(roads, "RoadZ", Vector3.new(size, 0.3, road), CFrame.new(0, 0.2, coordinate), Enum.Material.Slate, Color3.fromRGB(46, 48, 55))
    end

    local structures = Instance.new("Folder")
    structures.Name = "Structures"
    structures.Parent = world

    local buildingIndex = 0
    for x = -4, 4, 2 do
        for z = -4, 4, 2 do
            if x ~= 0 or z ~= 0 then
                buildingIndex += 1
                local origin = Vector3.new(
                    x * step + rng:NextInteger(-9, 9),
                    0,
                    z * step + rng:NextInteger(-9, 9)
                )
                building(structures, rng, origin, buildingIndex)
            end
        end
    end

    tower(structures, Vector3.new(-455, 0, -455), 120)
    tower(structures, Vector3.new(455, 0, -455), 104)
    tower(structures, Vector3.new(-455, 0, 455), 88)
    tower(structures, Vector3.new(455, 0, 455), 136)

    for index = 1, 18 do
        local angle = math.rad(index * 20)
        local radius = 160 + (index % 3) * 35
        local pos = Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
        cover(structures, pos, Vector3.new(8, 6 + (index % 3) * 2, 22), index * 17)
    end

    for index = 0, 7 do
        container(structures, Vector3.new(-290 + index * 82, 4, 260 + (index % 2) * 24), if index % 2 == 0 then 0 else 90)
    end

    for index = 0, 7 do
        ramp(structures, Vector3.new(-250 + index * 72, 1, -270), 28, 18, 10 + (index % 3) * 3, if index % 2 == 0 then 0 else 180)
    end

    local center = model(structures, "CentralPlaza")
    part(center, "Platform", Vector3.new(100, 4, 100), CFrame.new(0, 2, 0), Enum.Material.Concrete, Color3.fromRGB(50, 54, 64))
    for angle = 0, 315, 45 do
        local radians = math.rad(angle)
        local position = Vector3.new(math.cos(radians) * 54, 8, math.sin(radians) * 54)
        part(center, "Pillar", Vector3.new(8, 16, 8), CFrame.new(position), Enum.Material.Marble, Color3.fromRGB(82, 86, 98))
    end

    local bridge = model(structures, "Bridge")
    part(bridge, "Deck", Vector3.new(250, 6, 18), CFrame.new(0, 16, 320), Enum.Material.Metal, Color3.fromRGB(56, 62, 72))
    for x = -100, 100, 50 do
        part(bridge, "Support", Vector3.new(6, 32, 6), CFrame.new(x, 0, 320), Enum.Material.Metal, Color3.fromRGB(42, 48, 58))
    end

    local spawns = Instance.new("Folder")
    spawns.Name = "TagSpawns"
    spawns.Parent = workspace

    local spawnPositions = {
        Vector3.new(-36, 2, -36),
        Vector3.new(36, 2, -36),
        Vector3.new(-36, 2, 36),
        Vector3.new(36, 2, 36),
        Vector3.new(-160, 2, 0),
        Vector3.new(160, 2, 0),
        Vector3.new(0, 2, -160),
        Vector3.new(0, 2, 160),
    }

    for index, position in ipairs(spawnPositions) do
        spawnPoint(spawns, ("Spawn_%02d"):format(index), position)
    end

    local mainSpawn = workspace:FindFirstChild("MainSpawn")
    if mainSpawn then
        mainSpawn:Destroy()
    end

    local start = Instance.new("SpawnLocation")
    start.Name = "MainSpawn"
    start.Size = Vector3.new(18, 1, 18)
    start.Position = Vector3.new(0, 3, 0)
    start.Anchored = true
    start.Neutral = true
    start.Transparency = 1
    start.CanQuery = false
    start.Parent = workspace
end

return Service
