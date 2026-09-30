--!strict

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3, transparency: number?, canCollide: boolean?): BasePart
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.Material = material
    part.Color = color
    part.Transparency = transparency or 0
    part.CanCollide = canCollide ~= false
    part.CanTouch = false
    part.CanQuery = part.CanCollide
    part.Parent = parent
    return part
end

local function addNeon(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3)
    return makePart(parent, name, size, cframe, Enum.Material.Neon, color, 0, false)
end

local function addSteps(parent: Instance, origin: Vector3, count: number, direction: Vector3, material: Enum.Material, color: Color3)
    for index = 1, count do
        local width = 14
        local depth = 3
        local height = index * 0.45
        local position = origin + direction * (index * 2.2) + Vector3.new(0, height / 2, 0)
        makePart(parent, "Step", Vector3.new(width, height, depth), CFrame.new(position), material, color)
    end
end

local function addCoverCluster(parent: Instance, origin: Vector3, rotation: number, palette: {Color3})
    local base = CFrame.new(origin) * CFrame.Angles(0, rotation, 0)
    local offsets = {
        {Vector3.new(-6, 2.5, -3), Vector3.new(5, 5, 6)},
        {Vector3.new(4, 1.5, -4), Vector3.new(7, 3, 4)},
        {Vector3.new(-2, 2, 5), Vector3.new(5, 4, 4)},
        {Vector3.new(7, 3.5, 5), Vector3.new(4, 7, 5)},
    }
    for index, item in ipairs(offsets) do
        makePart(parent, "Cover_" .. index, item[2], base * CFrame.new(item[1]), Enum.Material.Concrete, palette[(index - 1) % #palette + 1])
    end
    addNeon(parent, "CoverLine", Vector3.new(12, 0.35, 0.35), base * CFrame.new(0, 5.4, -5.4), Color3.fromRGB(55, 214, 255))
end

local function addBrokenFrame(parent: Instance, origin: Vector3, rotation: number)
    local base = CFrame.new(origin) * CFrame.Angles(0, rotation, 0)
    local steel = Color3.fromRGB(76, 85, 100)
    makePart(parent, "FramePost", Vector3.new(2.2, 18, 2.2), base * CFrame.new(-7, 9, 0), Enum.Material.Metal, steel)
    makePart(parent, "FramePost", Vector3.new(2.2, 13, 2.2), base * CFrame.new(7, 6.5, 0), Enum.Material.Metal, steel)
    makePart(parent, "FrameBeam", Vector3.new(16, 2.2, 2.2), base * CFrame.new(0, 15, 0), Enum.Material.Metal, steel)
    addNeon(parent, "FrameLight", Vector3.new(11, 0.25, 0.25), base * CFrame.new(0, 14.1, 1.2), Color3.fromRGB(255, 81, 104))
end

local function addGate(parent: Instance, origin: Vector3, rotation: number, color: Color3)
    local base = CFrame.new(origin) * CFrame.Angles(0, rotation, 0)
    local dark = Color3.fromRGB(34, 40, 51)
    makePart(parent, "GatePost", Vector3.new(3, 12, 3), base * CFrame.new(-8, 6, 0), Enum.Material.Metal, dark)
    makePart(parent, "GatePost", Vector3.new(3, 12, 3), base * CFrame.new(8, 6, 0), Enum.Material.Metal, dark)
    makePart(parent, "GateTop", Vector3.new(19, 3, 3), base * CFrame.new(0, 12, 0), Enum.Material.Metal, dark)
    addNeon(parent, "GateLine", Vector3.new(13, 0.45, 0.45), base * CFrame.new(0, 10.9, 1.6), color)
end

local function addStreetLight(parent: Instance, origin: Vector3, rotation: number, lightColor: Color3)
    local base = CFrame.new(origin) * CFrame.Angles(0, rotation, 0)
    makePart(parent, "LampPost", Vector3.new(1.1, 9, 1.1), base * CFrame.new(0, 4.5, 0), Enum.Material.Metal, Color3.fromRGB(42, 48, 60))
    local head = makePart(parent, "LampHead", Vector3.new(2.6, 0.7, 1.5), base * CFrame.new(0, 8.7, -1.1), Enum.Material.Metal, Color3.fromRGB(70, 77, 91))
    local lamp = makePart(parent, "Lamp", Vector3.new(1.6, 0.35, 0.9), base * CFrame.new(0, 8.35, -1.8), Enum.Material.Neon, lightColor, 0, false)
    local light = Instance.new("PointLight")
    light.Brightness = 1.4
    light.Range = 18
    light.Color = lightColor
    light.Parent = lamp
    head.CanQuery = false
end

local function addBarricade(parent: Instance, origin: Vector3, rotation: number)
    local base = CFrame.new(origin) * CFrame.Angles(0, rotation, 0)
    local dark = Color3.fromRGB(43, 50, 62)
    local accent = Color3.fromRGB(235, 90, 102)
    makePart(parent, "BarricadePost", Vector3.new(1.2, 3.2, 1.2), base * CFrame.new(-4.5, 1.6, 0), Enum.Material.Metal, dark)
    makePart(parent, "BarricadePost", Vector3.new(1.2, 3.2, 1.2), base * CFrame.new(4.5, 1.6, 0), Enum.Material.Metal, dark)
    makePart(parent, "BarricadeBeam", Vector3.new(11, 0.8, 0.8), base * CFrame.new(0, 2.4, 0), Enum.Material.Metal, dark)
    makePart(parent, "BarricadeAccent", Vector3.new(8, 0.22, 0.22), base * CFrame.new(0, 2.9, -0.45), Enum.Material.Neon, accent, 0, false)
end

local function addRaisedPlatform(parent: Instance, origin: Vector3, rotation: number, color: Color3)
    local base = CFrame.new(origin) * CFrame.Angles(0, rotation, 0)
    makePart(parent, "RaisedPlatform", Vector3.new(18, 2, 16), base * CFrame.new(0, 4, 0), Enum.Material.Concrete, Color3.fromRGB(71, 79, 94))
    makePart(parent, "RaisedPlatformTop", Vector3.new(14, 0.7, 12), base * CFrame.new(0, 5.35, 0), Enum.Material.Metal, color)
    addSteps(parent, origin + Vector3.new(0, 0, 7), 5, Vector3.new(0, 0, -1), Enum.Material.Concrete, Color3.fromRGB(82, 90, 105))
    addNeon(parent, "PlatformEdge", Vector3.new(10, 0.25, 0.35), base * CFrame.new(0, 5.75, 5.9), color)
end


local function build(parent: Instance)
    local floor = Color3.fromRGB(49, 56, 68)
    local trim = Color3.fromRGB(31, 36, 47)
    local concrete = Color3.fromRGB(83, 91, 105)
    local cyan = Color3.fromRGB(55, 214, 255)
    local red = Color3.fromRGB(255, 68, 86)
    local green = Color3.fromRGB(91, 242, 168)
    local white = Color3.fromRGB(215, 222, 232)

    makePart(parent, "ArenaFloor", Vector3.new(180, 2, 132), CFrame.new(0, -1, 0), Enum.Material.Slate, floor)
    makePart(parent, "NorthWall", Vector3.new(180, 12, 3), CFrame.new(0, 5, -66), Enum.Material.Concrete, trim)
    makePart(parent, "SouthWall", Vector3.new(180, 12, 3), CFrame.new(0, 5, 66), Enum.Material.Concrete, trim)
    makePart(parent, "WestWall", Vector3.new(3, 12, 132), CFrame.new(-90, 5, 0), Enum.Material.Concrete, trim)
    makePart(parent, "EastWall", Vector3.new(3, 12, 132), CFrame.new(90, 5, 0), Enum.Material.Concrete, trim)

    local center = Instance.new("Model")
    center.Name = "CollisionCore"
    center.Parent = parent
    makePart(center, "Dais", Vector3.new(34, 2, 34), CFrame.new(0, 1, 0), Enum.Material.Concrete, concrete)
    makePart(center, "DaisTop", Vector3.new(26, 1.2, 26), CFrame.new(0, 2.6, 0), Enum.Material.Metal, Color3.fromRGB(38, 45, 57))
    for _, angle in ipairs({0, 90, 180, 270}) do
        local radians = math.rad(angle)
        addNeon(center, "CoreLine", Vector3.new(13, 0.25, 0.5), CFrame.new(math.cos(radians) * 9, 3.25, math.sin(radians) * 9) * CFrame.Angles(0, radians, 0), cyan)
    end

    local orb = Instance.new("Part")
    orb.Shape = Enum.PartType.Ball
    orb.Name = "CoreOrb"
    orb.Size = Vector3.new(5, 5, 5)
    orb.Position = Vector3.new(0, 8, 0)
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanTouch = false
    orb.CanQuery = false
    orb.Material = Enum.Material.Neon
    orb.Color = cyan
    orb.Parent = center

    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 24
    light.Color = cyan
    light.Parent = orb

    addCoverCluster(parent, Vector3.new(-42, 0, -32), math.rad(12), {concrete, Color3.fromRGB(65, 73, 88)})
    addCoverCluster(parent, Vector3.new(42, 0, -32), math.rad(-12), {concrete, Color3.fromRGB(65, 73, 88)})
    addCoverCluster(parent, Vector3.new(-42, 0, 32), math.rad(-15), {concrete, Color3.fromRGB(65, 73, 88)})
    addCoverCluster(parent, Vector3.new(42, 0, 32), math.rad(15), {concrete, Color3.fromRGB(65, 73, 88)})

    addSteps(parent, Vector3.new(-54, 0, -6), 6, Vector3.new(0, 0, 1), Enum.Material.Concrete, concrete)
    addSteps(parent, Vector3.new(54, 0, 6), 6, Vector3.new(0, 0, -1), Enum.Material.Concrete, concrete)

    addBrokenFrame(parent, Vector3.new(-70, 0, -46), math.rad(-8))
    addBrokenFrame(parent, Vector3.new(70, 0, -46), math.rad(8))
    addBrokenFrame(parent, Vector3.new(-70, 0, 46), math.rad(8))
    addBrokenFrame(parent, Vector3.new(70, 0, 46), math.rad(-8))

    addGate(parent, Vector3.new(0, 0, -56), 0, cyan)
    addGate(parent, Vector3.new(0, 0, 56), math.rad(180), green)
    addGate(parent, Vector3.new(-80, 0, 0), math.rad(90), cyan)
    addGate(parent, Vector3.new(80, 0, 0), math.rad(-90), red)

    addStreetLight(parent, Vector3.new(-60, 0, -58), math.rad(15), cyan)
    addStreetLight(parent, Vector3.new(60, 0, -58), math.rad(-15), cyan)
    addStreetLight(parent, Vector3.new(-60, 0, 58), math.rad(-15), green)
    addStreetLight(parent, Vector3.new(60, 0, 58), math.rad(15), green)
    addStreetLight(parent, Vector3.new(-84, 0, 28), math.rad(90), red)
    addStreetLight(parent, Vector3.new(84, 0, -28), math.rad(-90), red)

    addBarricade(parent, Vector3.new(-24, 0, -46), math.rad(8))
    addBarricade(parent, Vector3.new(24, 0, -46), math.rad(-8))
    addBarricade(parent, Vector3.new(-24, 0, 46), math.rad(-8))
    addBarricade(parent, Vector3.new(24, 0, 46), math.rad(8))
    addBarricade(parent, Vector3.new(-72, 0, -20), math.rad(90))
    addBarricade(parent, Vector3.new(72, 0, 20), math.rad(90))
    addBarricade(parent, Vector3.new(-72, 0, 20), math.rad(-90))
    addBarricade(parent, Vector3.new(72, 0, -20), math.rad(-90))

    addRaisedPlatform(parent, Vector3.new(-58, 0, -6), math.rad(8), cyan)
    addRaisedPlatform(parent, Vector3.new(58, 0, 6), math.rad(-8), cyan)
    addRaisedPlatform(parent, Vector3.new(-58, 0, 6), math.rad(-8), red)
    addRaisedPlatform(parent, Vector3.new(58, 0, -6), math.rad(8), red)


    for _, x in ipairs({-24, 24}) do
        makePart(parent, "PlazaStrip", Vector3.new(3, 0.2, 40), CFrame.new(x, 0.15, 0), Enum.Material.Metal, white, 0, false)
    end
    for _, z in ipairs({-22, 22}) do
        makePart(parent, "PlazaStrip", Vector3.new(40, 0.2, 3), CFrame.new(0, 0.16, z), Enum.Material.Metal, white, 0, false)
    end

    local upgrade = makePart(parent, "UpgradeStation", Vector3.new(10, 1, 10), CFrame.new(0, 0.5, 49), Enum.Material.Neon, green)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "UpgradePrompt"
    prompt.ActionText = "Upgrade Damage"
    prompt.ObjectText = "Combat Station"
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = upgrade

    local playerSpawn = makePart(parent, "PlayerSpawn", Vector3.new(8, 1, 8), CFrame.new(0, 0.5, 38), Enum.Material.ForceField, green, 1, false)

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "EnemySpawns"
    spawnFolder.Parent = parent
    for index, position in ipairs({
        Vector3.new(-67, 1, -52),
        Vector3.new(67, 1, -52),
        Vector3.new(-76, 1, -6),
        Vector3.new(76, 1, 6),
        Vector3.new(-67, 1, 52),
        Vector3.new(67, 1, 52),
    }) do
        makePart(spawnFolder, "Spawn_" .. index, Vector3.new(2, 1, 2), CFrame.new(position), Enum.Material.ForceField, red, 1, false)
    end

    return playerSpawn, spawnFolder, prompt
end

return {
    Build = build,
}