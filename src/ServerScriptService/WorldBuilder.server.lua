local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local MAP_NAME = "CursedCollisionMap"

local previousMap = Workspace:FindFirstChild(MAP_NAME)
if previousMap then
    previousMap:Destroy()
end

local previousSpawn = Workspace:FindFirstChild("CursedCollisionSpawn")
if previousSpawn then
    previousSpawn:Destroy()
end

local map = Instance.new("Folder")
map.Name = MAP_NAME
map:SetAttribute("MapVersion", "2.0")
map:SetAttribute("Style", "UrbanBattlefield")
map:SetAttribute("SupportsDestruction", true)
map.Parent = Workspace

local COLORS = {
    Asphalt = Color3.fromRGB(24, 26, 31),
    Road = Color3.fromRGB(31, 33, 39),
    RoadLine = Color3.fromRGB(194, 194, 184),
    Sidewalk = Color3.fromRGB(92, 94, 102),
    Concrete = Color3.fromRGB(118, 120, 128),
    ConcreteDark = Color3.fromRGB(63, 65, 72),
    Metal = Color3.fromRGB(39, 42, 49),
    Glass = Color3.fromRGB(72, 112, 141),
    Purple = Color3.fromRGB(92, 62, 139),
    PurpleBright = Color3.fromRGB(137, 93, 191),
    Crimson = Color3.fromRGB(139, 44, 55),
    CrimsonBright = Color3.fromRGB(191, 64, 76),
    White = Color3.fromRGB(222, 222, 226),
    Green = Color3.fromRGB(58, 102, 69),
    Yellow = Color3.fromRGB(214, 176, 84),
}

local function makePart(parent, name, size, position, material, color, canCollide)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Anchored = true
    object.Material = material or Enum.Material.Concrete
    object.Color = color or COLORS.Concrete
    object.CanCollide = canCollide ~= false
    object.CanTouch = object.CanCollide
    object.CastShadow = true
    object.Parent = parent or map
    return object
end

local function markDestructible(object, restoreTime)
    object:SetAttribute("Destructible", true)
    object:SetAttribute("RestoreTime", restoreTime or 12)
    object:SetAttribute("DamageClass", "Structure")
end

local function makeBlock(parent, name, position, size, color, restoreTime)
    local block = makePart(parent, name, size, position, Enum.Material.Concrete, color or COLORS.Concrete, true)
    markDestructible(block, restoreTime)
    return block
end

local function makeWindow(parent, name, position, size)
    return makePart(parent, name, size, position, Enum.Material.Glass, COLORS.Glass, false)
end

local function makeBuilding(index, position, size, accentColor)
    local model = Instance.new("Model")
    model.Name = "Building_" .. index
    model.Parent = map
    model:SetAttribute("DistrictBuilding", true)

    local body = makeBlock(
        model,
        "Shell",
        position,
        size,
        Color3.fromRGB(
            82 + ((index * 7) % 24),
            84 + ((index * 5) % 22),
            91 + ((index * 9) % 25)
        ),
        14
    )

    local roof = makePart(
        model,
        "Roof",
        Vector3.new(size.X + 1.5, 1.2, size.Z + 1.5),
        position + Vector3.new(0, size.Y * 0.5 + 0.6, 0),
        Enum.Material.Metal,
        COLORS.Metal
    )
    roof:SetAttribute("Roof", true)

    local roofCap = makePart(
        model,
        "RoofCap",
        Vector3.new(size.X * 0.42, 0.8, size.Z * 0.42),
        position + Vector3.new(0, size.Y * 0.5 + 1.6, 0),
        Enum.Material.Metal,
        COLORS.ConcreteDark
    )

    local floors = math.max(2, math.floor(size.Y / 9))
    local sideSign = (index % 2 == 0) and -1 or 1

    for floorIndex = 1, floors do
        local y = position.Y - size.Y * 0.5 + floorIndex * (size.Y / (floors + 1))
        local frontZ = position.Z - size.Z * 0.5 - 0.24
        local backZ = position.Z + size.Z * 0.5 + 0.24

        makeWindow(model, "FrontWindow", Vector3.new(position.X, y, frontZ), Vector3.new(size.X * 0.66, 1.8, 0.3))
        makeWindow(model, "BackWindow", Vector3.new(position.X, y, backZ), Vector3.new(size.X * 0.66, 1.8, 0.3))

        local stripe = makePart(
            model,
            "FacadeTrim",
            Vector3.new(size.X * 0.78, 0.32, 0.42),
            Vector3.new(position.X, y - 1.35, frontZ - 0.09),
            Enum.Material.Metal,
            accentColor or COLORS.Purple,
            false
        )
        stripe:SetAttribute("VisualOnly", true)

        local sideX = position.X + sideSign * (size.X * 0.5 + 0.24)
        local sideWindow = makeWindow(
            model,
            "SideWindow",
            Vector3.new(sideX, y, position.Z),
            Vector3.new(0.3, 1.8, size.Z * 0.56)
        )
        sideWindow:SetAttribute("VisualOnly", true)
    end

    local sign = makePart(
        model,
        "NeonSign",
        Vector3.new(size.X * 0.38, 2.2, 0.35),
        position + Vector3.new(size.X * 0.18, size.Y * 0.12, -size.Z * 0.5 - 0.34),
        Enum.Material.Neon,
        accentColor or COLORS.PurpleBright,
        false
    )
    sign:SetAttribute("VisualOnly", true)

    return model
end

local function makeTree(position, scale)
    local trunk = makePart(
        map,
        "TreeTrunk",
        Vector3.new(1.4 * scale, 5.5 * scale, 1.4 * scale),
        position + Vector3.new(0, 2.75 * scale, 0),
        Enum.Material.Wood,
        Color3.fromRGB(76, 49, 36)
    )
    trunk.Shape = Enum.PartType.Cylinder
    trunk:SetAttribute("Destructible", true)
    trunk:SetAttribute("RestoreTime", 16)

    local crown = makePart(
        map,
        "TreeCrown",
        Vector3.new(7.2 * scale, 7.2 * scale, 7.2 * scale),
        position + Vector3.new(0, 7.0 * scale, 0),
        Enum.Material.Grass,
        COLORS.Green,
        false
    )
    crown.Shape = Enum.PartType.Ball
end

local function makeStreetLamp(position, rotation)
    local pole = makePart(
        map,
        "LampPole",
        Vector3.new(0.65, 7.5, 0.65),
        position + Vector3.new(0, 3.75, 0),
        Enum.Material.Metal,
        COLORS.Metal
    )

    local arm = makePart(
        map,
        "LampArm",
        Vector3.new(3.2, 0.32, 0.32),
        position + Vector3.new(1.5, 6.95, 0),
        Enum.Material.Metal,
        COLORS.Metal
    )
    arm.CFrame = CFrame.new(arm.Position) * CFrame.Angles(0, math.rad(rotation or 0), 0)

    local head = makePart(
        map,
        "LampHead",
        Vector3.new(1.25, 0.45, 1.25),
        position + Vector3.new(3.0, 6.55, 0),
        Enum.Material.Neon,
        COLORS.Yellow,
        false
    )
    head.Shape = Enum.PartType.Ball
end

local function makeBench(position, rotation)
    local model = Instance.new("Model")
    model.Name = "Bench"
    model.Parent = map

    local seat = makePart(
        model,
        "Seat",
        Vector3.new(5, 0.45, 1.2),
        position + Vector3.new(0, 1.15, 0),
        Enum.Material.Wood,
        Color3.fromRGB(92, 68, 49)
    )

    local back = makePart(
        model,
        "Back",
        Vector3.new(5, 2.0, 0.4),
        position + Vector3.new(0, 2.0, 0.4),
        Enum.Material.Wood,
        Color3.fromRGB(82, 59, 44)
    )

    for _, x in ipairs({-1.8, 1.8}) do
        makePart(
            model,
            "Leg",
            Vector3.new(0.35, 1.15, 0.5),
            position + Vector3.new(x, 0.58, 0),
            Enum.Material.Metal,
            COLORS.Metal
        )
    end

    local pivot = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation or 0), 0)
    seat.CFrame = pivot * CFrame.new(0, 1.15, 0)
    back.CFrame = pivot * CFrame.new(0, 2.0, 0.4)
end

local function makeBarricade(position, rotation)
    local model = Instance.new("Model")
    model.Name = "CombatBarricade"
    model.Parent = map

    local barrier = makeBlock(
        model,
        "Barrier",
        position + Vector3.new(0, 1.3, 0),
        Vector3.new(9, 2.6, 1.1),
        COLORS.ConcreteDark,
        8
    )

    local warning = makePart(
        model,
        "Warning",
        Vector3.new(9.2, 0.18, 1.25),
        position + Vector3.new(0, 2.15, 0),
        Enum.Material.Neon,
        COLORS.CrimsonBright,
        false
    )
    warning:SetAttribute("VisualOnly", true)

    local pivot = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation or 0), 0)
    barrier.CFrame = pivot * CFrame.new(0, 1.3, 0)
    warning.CFrame = pivot * CFrame.new(0, 2.15, 0)
end

local function makeStaircase(position, steps, direction)
    local model = Instance.new("Model")
    model.Name = "RooftopStairs"
    model.Parent = map

    local sign = direction == -1 and -1 or 1

    for step = 1, steps do
        local block = makeBlock(
            model,
            "Step_" .. step,
            position + Vector3.new(0, (step - 1) * 1.1, (step - 1) * 2.0 * sign),
            Vector3.new(5.5, step == steps and 2.2 or 1.1, 2.2),
            COLORS.ConcreteDark,
            10
        )
        block:SetAttribute("Traversal", true)
    end
end

local function addRoadMarkings()
    for _, z in ipairs({-108, 108}) do
        for x = -160, 160, 16 do
            makePart(
                map,
                "RoadDash",
                Vector3.new(7, 0.06, 0.38),
                Vector3.new(x, 0.56, z),
                Enum.Material.SmoothPlastic,
                COLORS.RoadLine,
                false
            )
        end
    end

    for _, x in ipairs({-108, 108}) do
        for z = -160, 160, 16 do
            makePart(
                map,
                "RoadDash",
                Vector3.new(0.38, 0.06, 7),
                Vector3.new(x, 0.57, z),
                Enum.Material.SmoothPlastic,
                COLORS.RoadLine,
                false
            )
        end
    end

    for _, x in ipairs({-7, -3.5, 0, 3.5, 7}) do
        makePart(
            map,
            "Crosswalk",
            Vector3.new(2.35, 0.08, 11),
            Vector3.new(x, 0.75, -24),
            Enum.Material.SmoothPlastic,
            COLORS.White,
            false
        )
        makePart(
            map,
            "Crosswalk",
            Vector3.new(2.35, 0.08, 11),
            Vector3.new(x, 0.75, 24),
            Enum.Material.SmoothPlastic,
            COLORS.White,
            false
        )
    end

    for _, z in ipairs({-7, -3.5, 0, 3.5, 7}) do
        makePart(
            map,
            "Crosswalk",
            Vector3.new(11, 0.08, 2.35),
            Vector3.new(-24, 0.75, z),
            Enum.Material.SmoothPlastic,
            COLORS.White,
            false
        )
        makePart(
            map,
            "Crosswalk",
            Vector3.new(11, 0.08, 2.35),
            Vector3.new(24, 0.75, z),
            Enum.Material.SmoothPlastic,
            COLORS.White,
            false
        )
    end
end

local function addArena()
    makePart(
        map,
        "ArenaPlaza",
        Vector3.new(96, 1.2, 96),
        Vector3.new(0, 0.6, 0),
        Enum.Material.Slate,
        Color3.fromRGB(54, 56, 64)
    )

    makePart(
        map,
        "ArenaFloor",
        Vector3.new(74, 1.1, 74),
        Vector3.new(0, 1.25, 0),
        Enum.Material.Concrete,
        Color3.fromRGB(103, 105, 114)
    )

    for _, data in ipairs({
        {"North", Vector3.new(74, 0.8, 1.8), Vector3.new(0, 1.85, -37)},
        {"South", Vector3.new(74, 0.8, 1.8), Vector3.new(0, 1.85, 37)},
        {"West", Vector3.new(1.8, 0.8, 74), Vector3.new(-37, 1.85, 0)},
        {"East", Vector3.new(1.8, 0.8, 74), Vector3.new(37, 1.85, 0)},
    }) do
        makePart(
            map,
            "ArenaBorder" .. data[1],
            data[2],
            data[3],
            Enum.Material.Neon,
            COLORS.PurpleBright,
            false
        )
    end

    makePart(
        map,
        "ArenaCrossX",
        Vector3.new(54, 0.15, 2),
        Vector3.new(0, 1.86, 0),
        Enum.Material.Neon,
        COLORS.White,
        false
    )

    makePart(
        map,
        "ArenaCrossZ",
        Vector3.new(2, 0.15, 54),
        Vector3.new(0, 1.87, 0),
        Enum.Material.Neon,
        COLORS.White,
        false
    )

    for _, position in ipairs({
        Vector3.new(-45, 1.0, -45),
        Vector3.new(45, 1.0, -45),
        Vector3.new(-45, 1.0, 45),
        Vector3.new(45, 1.0, 45),
    }) do
        local pillar = makePart(
            map,
            "ArenaPillar",
            Vector3.new(3.6, 7, 3.6),
            position,
            Enum.Material.Concrete,
            COLORS.ConcreteDark
        )
        pillar.Shape = Enum.PartType.Cylinder
    end
end

local function addCentralCover()
    for _, data in ipairs({
        {Vector3.new(-17, 3.2, -13), Vector3.new(10, 6.4, 4), COLORS.ConcreteDark},
        {Vector3.new(17, 3.2, -13), Vector3.new(10, 6.4, 4), COLORS.ConcreteDark},
        {Vector3.new(-17, 3.2, 13), Vector3.new(10, 6.4, 4), COLORS.ConcreteDark},
        {Vector3.new(17, 3.2, 13), Vector3.new(10, 6.4, 4), COLORS.ConcreteDark},
    }) do
        makeBlock(map, "ArenaCover", data[1], data[2], data[3], 10)
    end
end

local function addBuildings()
    local buildingData = {
        {1, Vector3.new(-70, 18, -70), Vector3.new(30, 36, 30), COLORS.Purple},
        {2, Vector3.new(70, 24, -70), Vector3.new(30, 48, 30), COLORS.Crimson},
        {3, Vector3.new(-70, 15, 70), Vector3.new(30, 30, 30), COLORS.Purple},
        {4, Vector3.new(70, 20, 70), Vector3.new(30, 40, 30), COLORS.Crimson},
        {5, Vector3.new(-70, 12, -20), Vector3.new(28, 24, 28), COLORS.Metal},
        {6, Vector3.new(70, 17, -20), Vector3.new(28, 34, 28), COLORS.Metal},
        {7, Vector3.new(-70, 14, 20), Vector3.new(28, 28, 28), COLORS.Crimson},
        {8, Vector3.new(70, 13, 20), Vector3.new(28, 26, 28), COLORS.Purple},
        {9, Vector3.new(-20, 11, -70), Vector3.new(30, 22, 30), COLORS.Metal},
        {10, Vector3.new(20, 15, -70), Vector3.new(30, 30, 30), COLORS.Purple},
        {11, Vector3.new(-20, 12, 70), Vector3.new(30, 24, 30), COLORS.Crimson},
        {12, Vector3.new(20, 18, 70), Vector3.new(30, 36, 30), COLORS.Metal},
        {13, Vector3.new(-108, 10, -48), Vector3.new(20, 20, 26), COLORS.Crimson},
        {14, Vector3.new(108, 13, -48), Vector3.new(20, 26, 26), COLORS.Purple},
        {15, Vector3.new(-108, 14, 48), Vector3.new(20, 28, 26), COLORS.Metal},
        {16, Vector3.new(108, 11, 48), Vector3.new(20, 22, 26), COLORS.Crimson},
    }

    for _, data in ipairs(buildingData) do
        makeBuilding(data[1], data[2], data[3], data[4])
    end

    makeStaircase(Vector3.new(-52, 0, -58), 7, 1)
    makeStaircase(Vector3.new(52, 0, -58), 7, 1)
    makeStaircase(Vector3.new(-52, 0, 58), 7, -1)
    makeStaircase(Vector3.new(52, 0, 58), 7, -1)
end

local function addStreetLife()
    for _, position in ipairs({
        Vector3.new(-50, 0, -50),
        Vector3.new(50, 0, -50),
        Vector3.new(-50, 0, 50),
        Vector3.new(50, 0, 50),
        Vector3.new(-52, 0, 0),
        Vector3.new(52, 0, 0),
        Vector3.new(0, 0, -52),
        Vector3.new(0, 0, 52),
    }) do
        makeTree(position, 1)
    end

    for _, data in ipairs({
        {Vector3.new(-126, 0, -126), 0},
        {Vector3.new(126, 0, -126), 180},
        {Vector3.new(-126, 0, 126), 90},
        {Vector3.new(126, 0, 126), 270},
        {Vector3.new(-54, 0, -30), 90},
        {Vector3.new(54, 0, -30), 270},
        {Vector3.new(-54, 0, 30), 90},
        {Vector3.new(54, 0, 30), 270},
    }) do
        makeStreetLamp(data[1], data[2])
    end

    for _, data in ipairs({
        {Vector3.new(-48, 0, -18), 0},
        {Vector3.new(48, 0, 18), 180},
        {Vector3.new(-18, 0, 48), 90},
        {Vector3.new(18, 0, -48), 270},
    }) do
        makeBench(data[1], data[2])
    end

    makeBarricade(Vector3.new(-40, 0, 0), 90)
    makeBarricade(Vector3.new(40, 0, 0), 90)
    makeBarricade(Vector3.new(0, 0, -40), 0)
    makeBarricade(Vector3.new(0, 0, 40), 0)
end

local function addSideAlleys()
    local alleyWalls = {
        {Vector3.new(-118, 4, -82), Vector3.new(2.4, 8, 42)},
        {Vector3.new(-82, 4, -118), Vector3.new(42, 8, 2.4)},
        {Vector3.new(118, 4, -82), Vector3.new(2.4, 8, 42)},
        {Vector3.new(82, 4, -118), Vector3.new(42, 8, 2.4)},
        {Vector3.new(-118, 4, 82), Vector3.new(2.4, 8, 42)},
        {Vector3.new(-82, 4, 118), Vector3.new(42, 8, 2.4)},
        {Vector3.new(118, 4, 82), Vector3.new(2.4, 8, 42)},
        {Vector3.new(82, 4, 118), Vector3.new(42, 8, 2.4)},
    }

    for _, data in ipairs(alleyWalls) do
        makeBlock(map, "AlleyWall", data[1], data[2], COLORS.ConcreteDark, 10)
    end

    for _, position in ipairs({
        Vector3.new(-92, 0, -92),
        Vector3.new(92, 0, -92),
        Vector3.new(-92, 0, 92),
        Vector3.new(92, 0, 92),
    }) do
        makePart(
            map,
            "AlleyPad",
            Vector3.new(28, 0.28, 28),
            position + Vector3.new(0, 0.75, 0),
            Enum.Material.Slate,
            Color3.fromRGB(47, 49, 57)
        )
    end
end

local function addWorldBounds()
    makePart(
        map,
        "Ground",
        Vector3.new(370, 2, 370),
        Vector3.new(0, -1, 0),
        Enum.Material.Asphalt,
        COLORS.Asphalt
    )

    local wallHeight = 16
    makePart(map, "NorthBoundary", Vector3.new(370, wallHeight, 2), Vector3.new(0, wallHeight * 0.5, -184), Enum.Material.Brick, COLORS.Metal)
    makePart(map, "SouthBoundary", Vector3.new(370, wallHeight, 2), Vector3.new(0, wallHeight * 0.5, 184), Enum.Material.Brick, COLORS.Metal)
    makePart(map, "WestBoundary", Vector3.new(2, wallHeight, 370), Vector3.new(-184, wallHeight * 0.5, 0), Enum.Material.Brick, COLORS.Metal)
    makePart(map, "EastBoundary", Vector3.new(2, wallHeight, 370), Vector3.new(184, wallHeight * 0.5, 0), Enum.Material.Brick, COLORS.Metal)
end

local function addRoadNetwork()
    local roadWidth = 24

    makePart(map, "NorthRoad", Vector3.new(370, 0.5, roadWidth), Vector3.new(0, 0.25, -118), Enum.Material.Asphalt, COLORS.Road)
    makePart(map, "SouthRoad", Vector3.new(370, 0.5, roadWidth), Vector3.new(0, 0.25, 118), Enum.Material.Asphalt, COLORS.Road)
    makePart(map, "WestRoad", Vector3.new(roadWidth, 0.5, 370), Vector3.new(-118, 0.25, 0), Enum.Material.Asphalt, COLORS.Road)
    makePart(map, "EastRoad", Vector3.new(roadWidth, 0.5, 370), Vector3.new(118, 0.25, 0), Enum.Material.Asphalt, COLORS.Road)

    makePart(map, "CentralRoadX", Vector3.new(236, 0.5, 16), Vector3.new(0, 0.26, 0), Enum.Material.Asphalt, COLORS.Road)
    makePart(map, "CentralRoadZ", Vector3.new(16, 0.5, 236), Vector3.new(0, 0.27, 0), Enum.Material.Asphalt, COLORS.Road)

    addRoadMarkings()
end

local function configureLighting()
    Lighting.ClockTime = 17.4
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
    Lighting.Technology = Enum.Technology.ShadowMap
    Lighting.EnvironmentDiffuseScale = 0.35
    Lighting.EnvironmentSpecularScale = 0.25
    Lighting.OutdoorAmbient = Color3.fromRGB(104, 105, 121)

    local oldAtmosphere = Lighting:FindFirstChild("CursedCollisionAtmosphere")
    if oldAtmosphere then
        oldAtmosphere:Destroy()
    end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "CursedCollisionAtmosphere"
    atmosphere.Density = 0.14
    atmosphere.Haze = 0.62
    atmosphere.Glare = 0.06
    atmosphere.Offset = 0.08
    atmosphere.Parent = Lighting
end

configureLighting()
addWorldBounds()
addRoadNetwork()
addArena()
addCentralCover()
addBuildings()
addSideAlleys()
addStreetLife()

local spawn = Instance.new("SpawnLocation")
spawn.Name = "CursedCollisionSpawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 3, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Neon
spawn.Color = COLORS.PurpleBright
spawn.Transparency = 0.35
spawn.Parent = Workspace

local marker = makePart(
    map,
    "SpawnMarker",
    Vector3.new(18, 0.2, 18),
    Vector3.new(0, 2.1, 0),
    Enum.Material.Neon,
    COLORS.Purple,
    false
)
marker.Shape = Enum.PartType.Cylinder

local banner = makePart(
    map,
    "CentralBanner",
    Vector3.new(18, 8, 0.35),
    Vector3.new(0, 13, -34),
    Enum.Material.Neon,
    COLORS.CrimsonBright,
    false
)
banner:SetAttribute("VisualOnly", true)

print("[Cursed Collision] Urban battle map generated.")
