--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ArenaBuilder = {}

local function makePart(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    material: Enum.Material,
    color: Color3,
    transparency: number?
)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.Material = material
    part.Color = color
    part.Transparency = transparency or 0
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CastShadow = false
    part.Parent = parent
    return part
end

function ArenaBuilder.Build()
    local existing = workspace:FindFirstChild("CollisionBattlestarWorld")
    if existing then
        existing:Destroy()
    end

    local world = Instance.new("Folder")
    world.Name = "CollisionBattlestarWorld"
    world.Parent = workspace

    local arena = Instance.new("Folder")
    arena.Name = "Arena"
    arena.Parent = world

    local radius = Config.Arena.Radius
    local floor = makePart(
        arena,
        "Floor",
        Vector3.new(radius * 2, 4, radius * 2),
        CFrame.new(0, -2, 0),
        Enum.Material.Asphalt,
        Color3.fromRGB(23, 26, 33)
    )
    floor.CastShadow = false

    local wallThickness = 3
    local wallHeight = 12
    local wallHalf = radius + wallThickness * 0.5
    local wallColor = Color3.fromRGB(43, 48, 59)

    makePart(arena, "NorthWall", Vector3.new(radius * 2 + wallThickness, wallHeight, wallThickness), CFrame.new(0, wallHeight * 0.5 - 2, -wallHalf), Enum.Material.Metal, wallColor)
    makePart(arena, "SouthWall", Vector3.new(radius * 2 + wallThickness, wallHeight, wallThickness), CFrame.new(0, wallHeight * 0.5 - 2, wallHalf), Enum.Material.Metal, wallColor)
    makePart(arena, "WestWall", Vector3.new(wallThickness, wallHeight, radius * 2), CFrame.new(-wallHalf, wallHeight * 0.5 - 2, 0), Enum.Material.Metal, wallColor)
    makePart(arena, "EastWall", Vector3.new(wallThickness, wallHeight, radius * 2), CFrame.new(wallHalf, wallHeight * 0.5 - 2, 0), Enum.Material.Metal, wallColor)

    local ring = Instance.new("Part")
    ring.Name = "CenterRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.5, 36, 36)
    ring.CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.Material = Enum.Material.Neon
    ring.Color = Color3.fromRGB(110, 35, 78)
    ring.Transparency = 0.25
    ring.Parent = arena

    local center = makePart(
        arena,
        "CenterPlatform",
        Vector3.new(16, 0.5, 16),
        CFrame.new(0, 0.35, 0),
        Enum.Material.Metal,
        Color3.fromRGB(45, 49, 60)
    )

    local coverPositions = {
        Vector3.new(-31, 4, -22),
        Vector3.new(31, 4, -22),
        Vector3.new(-31, 4, 22),
        Vector3.new(31, 4, 22),
        Vector3.new(0, 4, -40),
        Vector3.new(0, 4, 40),
    }

    for index, position in ipairs(coverPositions) do
        makePart(
            arena,
            "Cover" .. index,
            Vector3.new(8, 8, 8),
            CFrame.new(position),
            Enum.Material.Concrete,
            Color3.fromRGB(63, 68, 80)
        )
    end

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "EnemySpawnPoints"
    spawnFolder.Parent = world

    local spawnRadius = math.min(Config.Arena.SpawnRadius, radius - 12)

    for index = 1, 10 do
        local angle = (index - 1) * (math.pi * 2 / 10)
        local position = Vector3.new(
            math.cos(angle) * spawnRadius,
            2,
            math.sin(angle) * spawnRadius
        )

        local point = makePart(
            spawnFolder,
            "Spawn" .. index,
            Vector3.new(2, 1, 2),
            CFrame.new(position),
            Enum.Material.SmoothPlastic,
            Color3.new(1, 1, 1),
            1
        )

        point.CanCollide = false
        point.CanTouch = false
        point.CanQuery = false
    end

    local playerSpawn = Instance.new("SpawnLocation")
    playerSpawn.Name = "PlayerSpawn"
    playerSpawn.Size = Vector3.new(8, 1, 8)
    playerSpawn.CFrame = CFrame.new(0, 2, 0)
    playerSpawn.Anchored = true
    playerSpawn.CanCollide = true
    playerSpawn.Neutral = true
    playerSpawn.Duration = 0
    playerSpawn.Material = Enum.Material.Neon
    playerSpawn.Color = Color3.fromRGB(85, 165, 215)
    playerSpawn.Transparency = 0.12
    playerSpawn.Parent = world

    center.Transparency = 0
    return world
end

return ArenaBuilder
