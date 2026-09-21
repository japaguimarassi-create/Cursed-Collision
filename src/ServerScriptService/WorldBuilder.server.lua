local Workspace = game:GetService("Workspace")

local old = Workspace:FindFirstChild("CursedCollisionMap")
if old then
    old:Destroy()
end

local map = Instance.new("Folder")
map.Name = "CursedCollisionMap"
map.Parent = Workspace

local function part(name, size, position, material, canCollide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Material = material or Enum.Material.Concrete
    p.CanCollide = canCollide ~= false
    p.Parent = map
    return p
end

part("Ground", Vector3.new(240, 2, 240), Vector3.new(0, -1, 0), Enum.Material.Asphalt)

for x = -90, 90, 30 do
    part("RoadBlock", Vector3.new(8, 1, 220), Vector3.new(x, 0.1, 0), Enum.Material.Concrete)
end

for z = -90, 90, 30 do
    part("RoadBlock", Vector3.new(220, 1, 8), Vector3.new(0, 0.1, z), Enum.Material.Concrete)
end

local buildingIndex = 0
for x = -90, 90, 30 do
    for z = -90, 90, 30 do
        if math.abs(x) > 20 or math.abs(z) > 20 then
            buildingIndex += 1
            local height = 10 + ((buildingIndex * 7) % 22)
            local width = 18
            local depth = 18
            local p = part(
                "Building_" .. buildingIndex,
                Vector3.new(width, height, depth),
                Vector3.new(x + 9, height * 0.5, z + 9),
                Enum.Material.Brick
            )
            p:SetAttribute("Destructible", true)
            p:SetAttribute("RestoreTime", 12)
        end
    end
end

local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
if not spawn then
    spawn = Instance.new("SpawnLocation")
    spawn.Name = "CursedCollisionSpawn"
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 2, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Parent = Workspace
end

local marker = part("CentralPlaza", Vector3.new(34, 1, 34), Vector3.new(0, 0.5, 0), Enum.Material.Slate)
marker.CanCollide = true
