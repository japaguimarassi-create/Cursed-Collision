--!strict

local ArenaBuilder = {}

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, material: Enum.Material, color: Color3)
    local value = Instance.new("Part")
    value.Name = name
    value.Size = size
    value.Position = position
    value.Anchored = true
    value.Material = material
    value.Color = color
    value.TopSurface = Enum.SurfaceType.Smooth
    value.BottomSurface = Enum.SurfaceType.Smooth
    value.Parent = parent
    return value
end

function ArenaBuilder.Build()
    local old = workspace:FindFirstChild("CollisionBattlestarPvP")
    if old then
        old:Destroy()
    end

    local world = Instance.new("Folder")
    world.Name = "CollisionBattlestarPvP"
    world.Parent = workspace

    part(
        world,
        "Floor",
        Vector3.new(150, 4, 110),
        Vector3.new(0, -2, 190),
        Enum.Material.SmoothPlastic,
        Color3.fromRGB(226, 229, 235)
    )

    part(
        world,
        "NorthWall",
        Vector3.new(154, 14, 4),
        Vector3.new(0, 5, 245),
        Enum.Material.Glass,
        Color3.fromRGB(235, 240, 248)
    )

    part(
        world,
        "SouthWall",
        Vector3.new(154, 14, 4),
        Vector3.new(0, 5, 135),
        Enum.Material.Glass,
        Color3.fromRGB(235, 240, 248)
    )

    part(
        world,
        "EastWall",
        Vector3.new(4, 14, 110),
        Vector3.new(75, 5, 190),
        Enum.Material.Glass,
        Color3.fromRGB(235, 240, 248)
    )

    part(
        world,
        "WestWall",
        Vector3.new(4, 14, 110),
        Vector3.new(-75, 5, 190),
        Enum.Material.Glass,
        Color3.fromRGB(235, 240, 248)
    )

    local spawns = Instance.new("Folder")
    spawns.Name = "Spawns"
    spawns.Parent = world

    local positions = {
        Vector3.new(-50, 3, 160),
        Vector3.new(50, 3, 160),
        Vector3.new(-50, 3, 220),
        Vector3.new(50, 3, 220),
        Vector3.new(0, 3, 190),
    }

    for index, position in ipairs(positions) do
        local value = Instance.new("Part")
        value.Name = "Spawn" .. index
        value.Size = Vector3.new(4, 1, 4)
        value.Position = position
        value.Anchored = true
        value.CanCollide = false
        value.CanTouch = false
        value.CanQuery = false
        value.Transparency = 1
        value.Parent = spawns
    end

    return world
end

return ArenaBuilder
