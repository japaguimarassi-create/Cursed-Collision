--!strict

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local MAP_NAME = "CursedCollisionMap"
local DETAIL_NAME = "UrbanDetailV3"

local map: Folder?
for _ = 1, 200 do
    local candidate = Workspace:FindFirstChild(MAP_NAME)
    if candidate and candidate:IsA("Folder") then
        map = candidate
        break
    end
    task.wait(0.05)
end

if not map then
    warn("[Cursed Collision] Urban Detail V3 could not find map.")
    return
end

if map:FindFirstChild(DETAIL_NAME) then
    map:FindFirstChild(DETAIL_NAME):Destroy()
end

local details = Instance.new("Folder")
details.Name = DETAIL_NAME
details:SetAttribute("Purpose", "UrbanTraversalAndCombatDetail")
details.Parent = map

local COLORS = {
    Asphalt = Color3.fromRGB(22, 24, 29),
    Concrete = Color3.fromRGB(70, 72, 80),
    Metal = Color3.fromRGB(38, 41, 48),
    White = Color3.fromRGB(230, 231, 236),
    Purple = Color3.fromRGB(139, 95, 205),
    PurpleSoft = Color3.fromRGB(105, 76, 151),
    Crimson = Color3.fromRGB(210, 60, 75),
    Yellow = Color3.fromRGB(231, 195, 91),
    Cyan = Color3.fromRGB(92, 185, 224),
    Glass = Color3.fromRGB(64, 105, 132)
}

local function part(
    parent: Instance,
    name: string,
    size: Vector3,
    position: Vector3,
    material: Enum.Material,
    color: Color3,
    canCollide: boolean?
): Part
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.Position = position
    object.Anchored = true
    object.Material = material
    object.Color = color
    object.CanCollide = canCollide ~= false
    object.CanTouch = object.CanCollide
    object.CanQuery = object.CanCollide
    object.CastShadow = true
    object.Parent = parent
    return object
end

local function visual(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
    local object = part(parent, name, size, position, Enum.Material.Neon, color, false)
    object:SetAttribute("VisualOnly", true)
    object.CanTouch = false
    object.CanQuery = false
    return object
end

local function destructible(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
    local object = part(parent, name, size, position, Enum.Material.Concrete, color, false)
    object:SetAttribute("Destructible", true)
    object:SetAttribute("RestoreTime", 9)
    object:SetAttribute("StructureResistance", 20)
    object:SetAttribute("DamageClass", "Facade")
    return object
end

local function billboard(parent: Instance, adornee: BasePart, text: string, color: Color3)
    local gui = Instance.new("BillboardGui")
    gui.Name = "UrbanSign"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(220, 52)
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.StudsOffset = Vector3.new(0, 0.1, 0)
    gui.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 17
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.72
    label.Parent = gui
end

local function makeTrafficSignal(position: Vector3)
    local model = Instance.new("Model")
    model.Name = "TrafficSignal"
    model.Parent = details

    part(model, "Pole", Vector3.new(0.45, 6.5, 0.45), position + Vector3.new(0, 3.25, 0), Enum.Material.Metal, COLORS.Metal)
    part(model, "Arm", Vector3.new(3.0, 0.32, 0.32), position + Vector3.new(1.5, 6.1, 0), Enum.Material.Metal, COLORS.Metal)

    for index, color in ipairs({COLORS.Red, COLORS.Yellow, COLORS.Cyan}) do
        local light = visual(
            model,
            "Light" .. index,
            Vector3.new(0.32, 0.32, 0.32),
            position + Vector3.new(2.72, 6.1 - index * 0.65, 0),
            color
        )
        light.Shape = Enum.PartType.Ball
    end
end

local function makeBench(position: Vector3, rotation: number)
    local model = Instance.new("Model")
    model.Name = "StreetBench"
    model.Parent = details

    local pivot = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
    local seat = part(model, "Seat", Vector3.new(5.0, 0.42, 1.2), position, Enum.Material.Wood, Color3.fromRGB(92, 67, 49))
    local back = part(model, "Back", Vector3.new(5.0, 1.8, 0.35), position + Vector3.new(0, 1.15, 0.42), Enum.Material.Wood, Color3.fromRGB(76, 56, 45))

    for index, x in ipairs({-1.75, 1.75}) do
        part(model, "Leg" .. index, Vector3.new(0.35, 1.05, 0.45), position + Vector3.new(x, -0.5, 0), Enum.Material.Metal, COLORS.Metal)
    end

    seat.CFrame = pivot * CFrame.new(0, 0.8, 0)
    back.CFrame = pivot * CFrame.new(0, 1.45, 0.42)
end

local function makeDumpster(position: Vector3, accent: Color3)
    local model = Instance.new("Model")
    model.Name = "Dumpster"
    model.Parent = details

    part(model, "Body", Vector3.new(3.6, 2.3, 2.4), position + Vector3.new(0, 1.15, 0), Enum.Material.Metal, COLORS.Metal)
    local lid = part(model, "Lid", Vector3.new(3.7, 0.18, 2.5), position + Vector3.new(0, 2.34, 0), Enum.Material.Metal, accent)
    lid.CFrame = lid.CFrame * CFrame.Angles(math.rad(-8), 0, 0)
    visual(model, "Stripe", Vector3.new(3.65, 0.22, 0.20), position + Vector3.new(0, 1.2, -1.22), accent)
end

local function makeAwning(position: Vector3, rotation: number, accent: Color3)
    local model = Instance.new("Model")
    model.Name = "StoreAwning"
    model.Parent = details

    local pivot = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
    local canopy = part(
        model,
        "Canopy",
        Vector3.new(9, 0.32, 2.2),
        position + Vector3.new(0, 3.6, 0),
        Enum.Material.Metal,
        COLORS.Metal,
        false
    )
    canopy.CFrame = pivot * CFrame.new(0, 3.6, 0.6)
    visual(model, "NeonEdge", Vector3.new(8.6, 0.14, 0.14), position + Vector3.new(0, 3.42, -0.45), accent)

    for x = -3.6, 3.6, 3.6 do
        part(
            model,
            "Support",
            Vector3.new(0.20, 3.5, 0.20),
            position + Vector3.new(x, 1.8, -0.35),
            Enum.Material.Metal,
            COLORS.Metal,
            false
        )
    end
end

local function makeFacadeDetails(building: Model, index: number, center: Vector3, size: Vector3, accent: Color3)
    local frontZ = center.Z - size.Z * 0.5 - 0.28
    local sideX = center.X + size.X * 0.5 + 0.28
    local y = center.Y

    for lane = -1, 1 do
        local panel = destructible(
            building,
            "BreakableFacade",
            Vector3.new(size.X * 0.24, math.min(5.2, size.Y * 0.20), 0.24),
            Vector3.new(center.X + lane * size.X * 0.25, y + lane * 3.0, frontZ),
            Color3.fromRGB(93 + (index * 3) % 18, 94, 102)
        )
        panel:SetAttribute("FacadeAccent", true)
    end

    local trim = visual(
        building,
        "FacadeNeon",
        Vector3.new(size.X * 0.72, 0.16, 0.16),
        Vector3.new(center.X, center.Y + math.min(size.Y * 0.25, 7), frontZ - 0.06),
        accent
    )
    trim:SetAttribute("BuildingIndex", index)

    if index % 2 == 0 then
        local sign = visual(
            building,
            "FacadeSign",
            Vector3.new(size.X * 0.36, 1.6, 0.18),
            Vector3.new(center.X + size.X * 0.18, center.Y + 1.2, frontZ - 0.14),
            accent
        )
        billboard(building, sign, "CURSED DISTRICT", COLORS.White)
    end

    local ventBase = part(
        building,
        "RoofVent",
        Vector3.new(1.8, 0.9, 1.8),
        center + Vector3.new(size.X * 0.24, size.Y * 0.5 + 1.0, size.Z * 0.20),
        Enum.Material.Metal,
        COLORS.Metal,
        true
    )
    ventBase:SetAttribute("Destructible", true)
    ventBase:SetAttribute("RestoreTime", 12)
    ventBase:SetAttribute("StructureResistance", 28)

    visual(
        building,
        "VentLight",
        Vector3.new(1.0, 0.12, 0.12),
        ventBase.Position + Vector3.new(0, 0.55, -0.86),
        accent
    )
end

local buildingData = {
    [1] = {Vector3.new(-70, 18, -70), Vector3.new(30, 36, 30), COLORS.Purple},
    [2] = {Vector3.new(70, 24, -70), Vector3.new(30, 48, 30), COLORS.Crimson},
    [3] = {Vector3.new(-70, 15, 70), Vector3.new(30, 30, 30), COLORS.Purple},
    [4] = {Vector3.new(70, 20, 70), Vector3.new(30, 40, 30), COLORS.Crimson},
    [5] = {Vector3.new(-70, 12, -20), Vector3.new(28, 24, 28), COLORS.Cyan},
    [6] = {Vector3.new(70, 17, -20), Vector3.new(28, 34, 28), COLORS.Purple},
    [7] = {Vector3.new(-70, 14, 20), Vector3.new(28, 28, 28), COLORS.Crimson},
    [8] = {Vector3.new(70, 13, 20), Vector3.new(28, 26, 28), COLORS.Cyan},
    [9] = {Vector3.new(-20, 11, -70), Vector3.new(30, 22, 30), COLORS.Cyan},
    [10] = {Vector3.new(20, 15, -70), Vector3.new(30, 30, 30), COLORS.Purple},
    [11] = {Vector3.new(-20, 12, 70), Vector3.new(30, 24, 30), COLORS.Crimson},
    [12] = {Vector3.new(20, 18, 70), Vector3.new(30, 36, 30), COLORS.Cyan},
    [13] = {Vector3.new(-108, 10, -48), Vector3.new(20, 20, 26), COLORS.Crimson},
    [14] = {Vector3.new(108, 13, -48), Vector3.new(20, 26, 26), COLORS.Purple},
    [15] = {Vector3.new(-108, 14, 48), Vector3.new(20, 28, 26), COLORS.Cyan},
    [16] = {Vector3.new(108, 11, 48), Vector3.new(20, 22, 26), COLORS.Crimson}
}

for index, data in pairs(buildingData) do
    local building = map:FindFirstChild("Building_" .. tostring(index))
    if building and building:IsA("Model") then
        makeFacadeDetails(
            building,
            index,
            data[1],
            data[2],
            data[3]
        )
    end
end

for _, position in ipairs({
    Vector3.new(-14, 0, -14),
    Vector3.new(14, 0, -14),
    Vector3.new(-14, 0, 14),
    Vector3.new(14, 0, 14)
}) do
    makeTrafficSignal(position)
end

for _, data in ipairs({
    {Vector3.new(-49, 0, -48), 0},
    {Vector3.new(49, 0, -48), 180},
    {Vector3.new(-49, 0, 48), 0},
    {Vector3.new(49, 0, 48), 180}
}) do
    makeAwning(data[1], data[2], data[2] == 0 and COLORS.Purple or COLORS.Crimson)
end

for _, data in ipairs({
    {Vector3.new(-55, 0, -36), 0, COLORS.Purple},
    {Vector3.new(55, 0, -36), 180, COLORS.Crimson},
    {Vector3.new(-55, 0, 36), 0, COLORS.Cyan},
    {Vector3.new(55, 0, 36), 180, COLORS.Purple}
}) do
    makeBench(data[1], data[2])
    makeDumpster(data[1] + Vector3.new(7, 0, data[2] == 0 and 1.5 or -1.5), data[3])
end

local skywalk = Instance.new("Model")
skywalk.Name = "Skywalk"
skywalk.Parent = details
skywalk:SetAttribute("Traversal", true)

part(
    skywalk,
    "BridgeDeck",
    Vector3.new(108, 1.0, 7),
    Vector3.new(0, 28, -20),
    Enum.Material.Concrete,
    COLORS.Concrete,
    true
)

for _, x in ipairs({-52, -26, 0, 26, 52}) do
    local railL = part(
        skywalk,
        "RailLeft",
        Vector3.new(0.35, 2.4, 7),
        Vector3.new(x, 29.7, -23.2),
        Enum.Material.Metal,
        COLORS.Metal,
        true
    )
    railL.CFrame = railL.CFrame * CFrame.Angles(0, 0, 0)
    part(
        skywalk,
        "RailRight",
        Vector3.new(0.35, 2.4, 7),
        Vector3.new(x, 29.7, -16.8),
        Enum.Material.Metal,
        COLORS.Metal,
        true
    )
end

visual(
    skywalk,
    "SkywalkStrip",
    Vector3.new(100, 0.10, 0.14),
    Vector3.new(0, 28.58, -20),
    COLORS.Purple
)

for _, x in ipairs({-50, 50}) do
    for _, z in ipairs({-22.6, -17.4}) do
        destructible(
            skywalk,
            "BridgePanel",
            Vector3.new(5, 0.35, 0.70),
            Vector3.new(x, 28.45, z),
            COLORS.Cyan
        )
    end
end

local rooftopArena = Instance.new("Model")
rooftopArena.Name = "RooftopCombatDeck"
rooftopArena.Parent = details
rooftopArena:SetAttribute("Traversal", true)
rooftopArena:SetAttribute("SecondaryFightSpace", true)

part(
    rooftopArena,
    "Deck",
    Vector3.new(42, 0.9, 34),
    Vector3.new(-96, 24, 0),
    Enum.Material.Slate,
    COLORS.Concrete,
    true
)

for _, x in ipairs({-115, -96, -77}) do
    for _, z in ipairs({-14, 14}) do
        part(
            rooftopArena,
            "Rail",
            Vector3.new(0.35, 2.4, 0.35),
            Vector3.new(x, 25.5, z),
            Enum.Material.Metal,
            COLORS.Metal,
            true
        )
    end
end

visual(
    rooftopArena,
    "DeckMark",
    Vector3.new(26, 0.10, 0.18),
    Vector3.new(-96, 24.52, 0),
    COLORS.Crimson
)

local cafe = Instance.new("Model")
cafe.Name = "CornerCafeInterior"
cafe.Parent = details
cafe:SetAttribute("Interior", true)

part(cafe, "Floor", Vector3.new(22, 0.4, 16), Vector3.new(106, 0.5, 0), Enum.Material.Slate, COLORS.Concrete, true)
part(cafe, "BackWall", Vector3.new(22, 6, 0.5), Vector3.new(106, 3.4, 7.75), Enum.Material.Concrete, COLORS.Concrete, true)
part(cafe, "LeftWall", Vector3.new(0.5, 6, 16), Vector3.new(95.25, 3.4, 0), Enum.Material.Concrete, COLORS.Concrete, true)
part(cafe, "RightWall", Vector3.new(0.5, 6, 16), Vector3.new(116.75, 3.4, 0), Enum.Material.Concrete, COLORS.Concrete, true)

local counter = part(cafe, "Counter", Vector3.new(8, 2.8, 1.2), Vector3.new(106, 1.9, 4.9), Enum.Material.Wood, Color3.fromRGB(97, 69, 50), true)
visual(cafe, "CounterLight", Vector3.new(7.4, 0.10, 0.10), counter.Position + Vector3.new(0, 1.46, -0.62), COLORS.Yellow)

for _, x in ipairs({101, 106, 111}) do
    local stool = part(cafe, "Stool", Vector3.new(0.9, 1.5, 0.9), Vector3.new(x, 0.95, 2.8), Enum.Material.Metal, COLORS.Metal, true)
    stool.Shape = Enum.PartType.Cylinder
end

for _, z in ipairs({-5.0, 0, 5.0}) do
    destructible(cafe, "WindowPanel", Vector3.new(0.18, 2.8, 3.3), Vector3.new(95.0, 3.4, z), COLORS.Glass)
end

local markers = Instance.new("Folder")
markers.Name = "TraversalMarkers"
markers.Parent = details

for _, position in ipairs({
    Vector3.new(-52, 1.9, -58),
    Vector3.new(52, 1.9, -58),
    Vector3.new(-52, 1.9, 58),
    Vector3.new(52, 1.9, 58),
    Vector3.new(-96, 24.6, 0),
    Vector3.new(0, 28.7, -20)
}) do
    local marker = visual(markers, "RouteMarker", Vector3.new(1.2, 0.10, 1.2), position, COLORS.Purple)
    marker.Shape = Enum.PartType.Cylinder
    marker.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

map:SetAttribute("MapVersion", "3.0")
map:SetAttribute("DetailPass", "UrbanCombatV3")
map:SetAttribute("TraversalLayer", true)
map:SetAttribute("InteriorLayer", true)
map:SetAttribute("FacadeDestruction", true)

local status = map:FindFirstChild("CursedCollisionMapStatus")
if status and status:IsA("StringValue") then
    status.Value = "Ready"
end

print("[Cursed Collision] Urban Detail V3 loaded.")
