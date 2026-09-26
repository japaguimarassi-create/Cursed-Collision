--!strict

local Service = {}

local arenaOrigin = Vector3.new(0, 0, 1700)
local spawnPositions = {
    Vector3.new(-90, 5, 55),
    Vector3.new(90, 5, 55),
    Vector3.new(-90, 5, -55),
    Vector3.new(90, 5, -55),
    Vector3.new(-55, 5, 0),
    Vector3.new(55, 5, 0),
    Vector3.new(0, 5, 65),
    Vector3.new(0, 5, -65),
}

local function createPart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): BasePart
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Material = material
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function Service:Init(_config)
    local old = workspace:FindFirstChild("PvPZone")
    if old then
        old:Destroy()
    end

    local arena = Instance.new("Folder")
    arena.Name = "PvPZone"
    arena.Parent = workspace

    local white = Color3.fromRGB(245, 246, 248)
    local light = Color3.fromRGB(224, 227, 232)
    local dark = Color3.fromRGB(186, 191, 200)

    createPart(
        arena,
        "Floor",
        Vector3.new(260, 3, 190),
        arenaOrigin + Vector3.new(0, -1.5, 0),
        white,
        Enum.Material.SmoothPlastic
    )

    createPart(arena, "NorthWall", Vector3.new(260, 22, 4), arenaOrigin + Vector3.new(0, 11, 95), light, Enum.Material.SmoothPlastic)
    createPart(arena, "SouthWall", Vector3.new(260, 22, 4), arenaOrigin + Vector3.new(0, 11, -95), light, Enum.Material.SmoothPlastic)
    createPart(arena, "WestWall", Vector3.new(4, 22, 190), arenaOrigin + Vector3.new(-130, 11, 0), light, Enum.Material.SmoothPlastic)
    createPart(arena, "EastWall", Vector3.new(4, 22, 190), arenaOrigin + Vector3.new(130, 11, 0), light, Enum.Material.SmoothPlastic)

    local obstacles = {
        {Vector3.new(-70, 8, 0), Vector3.new(18, 16, 18)},
        {Vector3.new(70, 8, 0), Vector3.new(18, 16, 18)},
        {Vector3.new(0, 6, 48), Vector3.new(46, 12, 10)},
        {Vector3.new(0, 6, -48), Vector3.new(46, 12, 10)},
        {Vector3.new(-38, 5, 30), Vector3.new(12, 10, 28)},
        {Vector3.new(38, 5, -30), Vector3.new(12, 10, 28)},
        {Vector3.new(-20, 4, 0), Vector3.new(10, 8, 10)},
        {Vector3.new(20, 4, 0), Vector3.new(10, 8, 10)},
    }

    for index, data in ipairs(obstacles) do
        createPart(
            arena,
            ("Obstacle_%02d"):format(index),
            data[2],
            arenaOrigin + data[1],
            if index % 2 == 0 then light else dark,
            Enum.Material.SmoothPlastic
        )
    end

    local spawns = Instance.new("Folder")
    spawns.Name = "Spawns"
    spawns.Parent = arena

    for index, position in ipairs(spawnPositions) do
        local spawn = createPart(
            spawns,
            ("Spawn_%02d"):format(index),
            Vector3.new(4, 1, 4),
            arenaOrigin + position,
            white,
            Enum.Material.SmoothPlastic
        )
        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.CanQuery = false
    end

    local returnPad = createPart(
        arena,
        "ReturnPad",
        Vector3.new(16, 1, 16),
        arenaOrigin + Vector3.new(0, 0.5, 0),
        Color3.fromRGB(210, 214, 220),
        Enum.Material.SmoothPlastic
    )
    returnPad.Transparency = 0.15

    workspace:SetAttribute("PvPZoneOrigin", arenaOrigin)
end

function Service:GetPvPSpawn(index: number?)
    local arena = workspace:FindFirstChild("PvPZone")
    local spawns = arena and arena:FindFirstChild("Spawns")
    if not spawns then
        return arenaOrigin + Vector3.new(0, 5, 0)
    end

    local parts = {}
    for _, child in ipairs(spawns:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end

    if #parts == 0 then
        return arenaOrigin + Vector3.new(0, 5, 0)
    end

    local slot = ((index or math.random(1, #parts)) - 1) % #parts + 1
    return parts[slot].Position + Vector3.new(0, 3, 0)
end

function Service:GetMainSpawn()
    return Vector3.new(0, 6, 0)
end

return Service
