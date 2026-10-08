--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local ArenaBuilder = {}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, transparency: number?)
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

    makePart(
        arena,
        "Floor",
        Vector3.new(Config.Arena.Radius * 2, 4, Config.Arena.Radius * 2),
        CFrame.new(0, -2, 0),
        Enum.Material.Slate,
        Color3.fromRGB(24, 27, 34)
    )

    local wallThickness = 4
    local wallHeight = 14
    local half = Config.Arena.Radius + wallThickness / 2

    makePart(arena, "NorthWall", Vector3.new(Config.Arena.Radius * 2 + wallThickness, wallHeight, wallThickness), CFrame.new(0, wallHeight / 2 - 2, -half), Enum.Material.Metal, Color3.fromRGB(40, 44, 54))
    makePart(arena, "SouthWall", Vector3.new(Config.Arena.Radius * 2 + wallThickness, wallHeight, wallThickness), CFrame.new(0, wallHeight / 2 - 2, half), Enum.Material.Metal, Color3.fromRGB(40, 44, 54))
    makePart(arena, "WestWall", Vector3.new(wallThickness, wallHeight, Config.Arena.Radius * 2), CFrame.new(-half, wallHeight / 2 - 2, 0), Enum.Material.Metal, Color3.fromRGB(40, 44, 54))
    makePart(arena, "EastWall", Vector3.new(wallThickness, wallHeight, Config.Arena.Radius * 2), CFrame.new(half, wallHeight / 2 - 2, 0), Enum.Material.Metal, Color3.fromRGB(40, 44, 54))

    local coverPositions = {
        Vector3.new(-25, 4, -18),
        Vector3.new(25, 4, -18),
        Vector3.new(-25, 4, 18),
        Vector3.new(25, 4, 18),
        Vector3.new(0, 4, -32),
        Vector3.new(0, 4, 32),
    }

    for index, position in ipairs(coverPositions) do
        makePart(
            arena,
            "Cover" .. index,
            Vector3.new(8, 8, 8),
            CFrame.new(position),
            Enum.Material.Concrete,
            Color3.fromRGB(64, 68, 80)
        )
    end

    local center = makePart(
        arena,
        "CenterMarker",
        Vector3.new(18, 0.4, 18),
        CFrame.new(0, 0.2, 0),
        Enum.Material.Neon,
        Color3.fromRGB(120, 30, 70)
    )
    center.CanCollide = false
    center.CanQuery = false

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "EnemySpawnPoints"
    spawnFolder.Parent = world

    for index = 1, 8 do
        local angle = (index - 1) * (math.pi * 2 / 8)
        local position = Vector3.new(
            math.cos(angle) * Config.Arena.SpawnRadius,
            3,
            math.sin(angle) * Config.Arena.SpawnRadius
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
    playerSpawn.Size = Vector3.new(6, 1, 6)
    playerSpawn.CFrame = CFrame.new(0, 2, 0)
    playerSpawn.Anchored = true
    playerSpawn.CanCollide = true
    playerSpawn.Neutral = true
    playerSpawn.Duration = 0
    playerSpawn.Transparency = 1
    playerSpawn.Parent = world

    return world
end

return ArenaBuilder
