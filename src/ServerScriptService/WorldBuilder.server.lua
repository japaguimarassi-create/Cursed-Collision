local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local old = Workspace:FindFirstChild("CursedCollisionMap")
if old then
    old:Destroy()
end

local oldSpawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
if oldSpawn and oldSpawn.Name == "CursedCollisionSpawn" then
    oldSpawn:Destroy()
end

local map = Instance.new("Folder")
map.Name = "CursedCollisionMap"
map.Parent = Workspace

local COLORS = {
    Road = Color3.fromRGB(34, 36, 42),
    Sidewalk = Color3.fromRGB(112, 114, 122),
    Concrete = Color3.fromRGB(130, 131, 138),
    Dark = Color3.fromRGB(52, 54, 62),
    Glass = Color3.fromRGB(90, 130, 158),
    Trim = Color3.fromRGB(26, 28, 34),
    Green = Color3.fromRGB(64, 116, 76),
    Accent = Color3.fromRGB(96, 74, 135),
    Red = Color3.fromRGB(150, 52, 61),
    White = Color3.fromRGB(222, 222, 226),
}

local function part(name, size, position, material, color, canCollide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Material = material or Enum.Material.Concrete
    p.Color = color or COLORS.Concrete
    p.CanCollide = canCollide ~= false
    p.CanTouch = p.CanCollide
    p.CastShadow = true
    p.Parent = map
    return p
end

local function cubeBuilding(index, position, size, accentColor)
    local model = Instance.new("Model")
    model.Name = "Building_" .. index
    model.Parent = map

    local body = Instance.new("Part")
    body.Name = "Shell"
    body.Size = size
    body.Position = position
    body.Anchored = true
    body.Material = Enum.Material.Concrete
    body.Color = Color3.fromRGB(94 + (index % 3) * 8, 96 + (index % 4) * 6, 105 + (index % 2) * 7)
    body.CanCollide = true
    body.Parent = model
    body:SetAttribute("Destructible", true)
    body:SetAttribute("RestoreTime", 12)

    local roof = part("Roof", Vector3.new(size.X + 1.5, 1, size.Z + 1.5), position + Vector3.new(0, size.Y * 0.5 + 0.5, 0), Enum.Material.Metal, COLORS.Trim)
    roof.Parent = model

    local stripeCount = math.max(2, math.floor(size.Y / 8))
    for level = 1, stripeCount do
        local y = position.Y - size.Y * 0.5 + level * (size.Y / (stripeCount + 1))
        local windowBand = part(
            "WindowBand",
            Vector3.new(size.X * 0.72, 1.2, 0.35),
            position + Vector3.new(0, y - position.Y, -(size.Z * 0.5 + 0.2)),
            Enum.Material.Glass,
            COLORS.Glass,
            false
        )
        windowBand.Parent = model

        local trimBand = part(
            "TrimBand",
            Vector3.new(size.X * 0.82, 0.35, 0.5),
            position + Vector3.new(0, y - position.Y, -(size.Z * 0.5 + 0.35)),
            Enum.Material.Metal,
            accentColor or COLORS.Trim,
            false
        )
        trimBand.Parent = model
    end

    local sign = part(
        "FacadeSign",
        Vector3.new(size.X * 0.34, 2.4, 0.3),
        position + Vector3.new(size.X * 0.22, size.Y * 0.18, -(size.Z * 0.5 + 0.25)),
        Enum.Material.Neon,
        accentColor or COLORS.Accent,
        false
    )
    sign.Parent = model

    return model
end

local function tree(position, scale)
    local trunk = part(
        "TreeTrunk",
        Vector3.new(1.4 * scale, 6 * scale, 1.4 * scale),
        position + Vector3.new(0, 3 * scale, 0),
        Enum.Material.Wood,
        Color3.fromRGB(78, 52, 38)
    )
    trunk.Shape = Enum.PartType.Cylinder

    local crown = part(
        "TreeCrown",
        Vector3.new(7 * scale, 7 * scale, 7 * scale),
        position + Vector3.new(0, 7 * scale, 0),
        Enum.Material.Grass,
        COLORS.Green,
        false
    )
    crown.Shape = Enum.PartType.Ball
end

local function streetLamp(position, rotation)
    local pole = part(
        "LampPole",
        Vector3.new(0.7, 7, 0.7),
        position + Vector3.new(0, 3.5, 0),
        Enum.Material.Metal,
        Color3.fromRGB(46, 48, 55)
    )
    local arm = part(
        "LampArm",
        Vector3.new(3, 0.35, 0.35),
        position + Vector3.new(1.4, 6.6, 0),
        Enum.Material.Metal,
        Color3.fromRGB(46, 48, 55)
    )
    arm.CFrame = CFrame.new(arm.Position) * CFrame.Angles(0, math.rad(rotation or 0), 0)

    local head = part(
        "LampHead",
        Vector3.new(1.3, 0.45, 1.3),
        position + Vector3.new(2.8, 6.25, 0),
        Enum.Material.Neon,
        Color3.fromRGB(255, 222, 158),
        false
    )
    head.Shape = Enum.PartType.Ball
end

Lighting.ClockTime = 17.4
Lighting.Brightness = 2
Lighting.GlobalShadows = true
Lighting.Technology = Enum.Technology.ShadowMap
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.25
Lighting.OutdoorAmbient = Color3.fromRGB(112, 112, 128)

local atmosphere = Lighting:FindFirstChild("CursedCollisionAtmosphere")
if atmosphere then
    atmosphere:Destroy()
end

atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "CursedCollisionAtmosphere"
atmosphere.Density = 0.16
atmosphere.Haze = 0.7
atmosphere.Glare = 0.08
atmosphere.Offset = 0.1
atmosphere.Parent = Lighting

part("Ground", Vector3.new(360, 2, 360), Vector3.new(0, -1, 0), Enum.Material.Asphalt, Color3.fromRGB(24, 26, 31))

local roadWidth = 24
part("NorthRoad", Vector3.new(360, 0.5, roadWidth), Vector3.new(0, 0.25, -108), Enum.Material.Asphalt, COLORS.Road)
part("SouthRoad", Vector3.new(360, 0.5, roadWidth), Vector3.new(0, 0.25, 108), Enum.Material.Asphalt, COLORS.Road)
part("WestRoad", Vector3.new(roadWidth, 0.5, 360), Vector3.new(-108, 0.25, 0), Enum.Material.Asphalt, COLORS.Road)
part("EastRoad", Vector3.new(roadWidth, 0.5, 360), Vector3.new(108, 0.25, 0), Enum.Material.Asphalt, COLORS.Road)

part("CentralRoadX", Vector3.new(220, 0.5, 16), Vector3.new(0, 0.26, 0), Enum.Material.Asphalt, Color3.fromRGB(28, 30, 36))
part("CentralRoadZ", Vector3.new(16, 0.5, 220), Vector3.new(0, 0.27, 0), Enum.Material.Asphalt, Color3.fromRGB(28, 30, 36))

local sidewalkY = 0.6
part("ArenaPlaza", Vector3.new(92, 1.2, 92), Vector3.new(0, sidewalkY, 0), Enum.Material.Slate, Color3.fromRGB(58, 60, 69))

part("ArenaFloor", Vector3.new(72, 1.1, 72), Vector3.new(0, 1.25, 0), Enum.Material.Concrete, Color3.fromRGB(108, 109, 118))
part("ArenaBorderNorth", Vector3.new(72, 0.8, 1.8), Vector3.new(0, 1.8, -36), Enum.Material.Neon, COLORS.Accent, false)
part("ArenaBorderSouth", Vector3.new(72, 0.8, 1.8), Vector3.new(0, 1.8, 36), Enum.Material.Neon, COLORS.Accent, false)
part("ArenaBorderWest", Vector3.new(1.8, 0.8, 72), Vector3.new(-36, 1.8, 0), Enum.Material.Neon, COLORS.Accent, false)
part("ArenaBorderEast", Vector3.new(1.8, 0.8, 72), Vector3.new(36, 1.8, 0), Enum.Material.Neon, COLORS.Accent, false)

part("ArenaCrossX", Vector3.new(52, 0.15, 2), Vector3.new(0, 1.84, 0), Enum.Material.Neon, COLORS.White, false)
part("ArenaCrossZ", Vector3.new(2, 0.15, 52), Vector3.new(0, 1.85, 0), Enum.Material.Neon, COLORS.White, false)

for _, pos in ipairs({
    Vector3.new(-42, 1.0, -42), Vector3.new(42, 1.0, -42),
    Vector3.new(-42, 1.0, 42), Vector3.new(42, 1.0, 42)
}) do
    local pillar = part("PlazaPillar", Vector3.new(3.5, 6, 3.5), pos, Enum.Material.Concrete, COLORS.Dark)
    pillar.Shape = Enum.PartType.Cylinder
end

local buildingData = {
    {Vector3.new(-68, 18, -68), Vector3.new(30, 36, 30), COLORS.Accent},
    {Vector3.new(68, 24, -68), Vector3.new(30, 48, 30), COLORS.Red},
    {Vector3.new(-68, 15, 68), Vector3.new(30, 30, 30), COLORS.Accent},
    {Vector3.new(68, 20, 68), Vector3.new(30, 40, 30), COLORS.Red},
    {Vector3.new(-68, 12, -20), Vector3.new(28, 24, 28), COLORS.Trim},
    {Vector3.new(68, 17, -20), Vector3.new(28, 34, 28), COLORS.Trim},
    {Vector3.new(-68, 14, 20), Vector3.new(28, 28, 28), COLORS.Red},
    {Vector3.new(68, 13, 20), Vector3.new(28, 26, 28), COLORS.Accent},
    {Vector3.new(-20, 11, -68), Vector3.new(30, 22, 30), COLORS.Trim},
    {Vector3.new(20, 15, -68), Vector3.new(30, 30, 30), COLORS.Accent},
    {Vector3.new(-20, 12, 68), Vector3.new(30, 24, 30), COLORS.Red},
    {Vector3.new(20, 18, 68), Vector3.new(30, 36, 30), COLORS.Trim},
}

for index, data in ipairs(buildingData) do
    cubeBuilding(index, data[1], data[2], data[3])
end

for _, pos in ipairs({
    Vector3.new(-44, 0, -44), Vector3.new(44, 0, -44),
    Vector3.new(-44, 0, 44), Vector3.new(44, 0, 44),
    Vector3.new(-49, 0, 0), Vector3.new(49, 0, 0),
    Vector3.new(0, 0, -49), Vector3.new(0, 0, 49)
}) do
    tree(pos, 1)
end

for _, data in ipairs({
    {Vector3.new(-92, 0, -92), 0},
    {Vector3.new(92, 0, -92), 180},
    {Vector3.new(-92, 0, 92), 90},
    {Vector3.new(92, 0, 92), 270},
}) do
    streetLamp(data[1], data[2])
end

local crosswalkColor = COLORS.White
for _, x in ipairs({-7, -3.5, 0, 3.5, 7}) do
    part("Crosswalk", Vector3.new(2.5, 0.08, 9), Vector3.new(x, 0.72, -18), Enum.Material.SmoothPlastic, crosswalkColor, false)
    part("Crosswalk", Vector3.new(2.5, 0.08, 9), Vector3.new(x, 0.72, 18), Enum.Material.SmoothPlastic, crosswalkColor, false)
end

for _, z in ipairs({-7, -3.5, 0, 3.5, 7}) do
    part("Crosswalk", Vector3.new(9, 0.08, 2.5), Vector3.new(-18, 0.72, z), Enum.Material.SmoothPlastic, crosswalkColor, false)
    part("Crosswalk", Vector3.new(9, 0.08, 2.5), Vector3.new(18, 0.72, z), Enum.Material.SmoothPlastic, crosswalkColor, false)
end

part("NorthWall", Vector3.new(360, 12, 2), Vector3.new(0, 5, -179), Enum.Material.Brick, COLORS.Dark)
part("SouthWall", Vector3.new(360, 12, 2), Vector3.new(0, 5, 179), Enum.Material.Brick, COLORS.Dark)
part("WestWall", Vector3.new(2, 12, 360), Vector3.new(-179, 5, 0), Enum.Material.Brick, COLORS.Dark)
part("EastWall", Vector3.new(2, 12, 360), Vector3.new(179, 5, 0), Enum.Material.Brick, COLORS.Dark)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "CursedCollisionSpawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 3, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Neon
spawn.Color = Color3.fromRGB(105, 75, 150)
spawn.Transparency = 0.35
spawn.Parent = Workspace

local marker = part("SpawnMarker", Vector3.new(18, 0.2, 18), Vector3.new(0, 2.1, 0), Enum.Material.Neon, Color3.fromRGB(75, 58, 105), false)
marker.Shape = Enum.PartType.Cylinder
