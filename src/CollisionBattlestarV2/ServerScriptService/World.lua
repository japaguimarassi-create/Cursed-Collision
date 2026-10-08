--!strict

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local PhysicsRules = require(ReplicatedStorage.Shared.PhysicsRules)

local World = {}
World.__index = World

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, material: Enum.Material, color: Color3)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.Material = material
    p.Color = color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = false
    PhysicsRules.apply(p, PhysicsRules.World)
    p.Parent = parent
    return p
end

function World.new()
    return setmetatable({
        root = nil,
        enemySpawns = {},
        playerSpawn = CFrame.new(0, 4, 0),
        pvpRoot = nil,
    }, World)
end

function World:Build()
    local old = Workspace:FindFirstChild("CBS2_World")
    if old then
        old:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = "CBS2_World"
    root.Parent = Workspace

    part(root, "Floor", Vector3.new(136, 4, 136), CFrame.new(0, -2, 0), Enum.Material.Asphalt, Color3.fromRGB(28, 31, 38))
    part(root, "NorthWall", Vector3.new(140, 14, 4), CFrame.new(0, 5, -68), Enum.Material.Concrete, Color3.fromRGB(52, 55, 64))
    part(root, "SouthWall", Vector3.new(140, 14, 4), CFrame.new(0, 5, 68), Enum.Material.Concrete, Color3.fromRGB(52, 55, 64))
    part(root, "WestWall", Vector3.new(4, 14, 140), CFrame.new(-68, 5, 0), Enum.Material.Concrete, Color3.fromRGB(52, 55, 64))
    part(root, "EastWall", Vector3.new(4, 14, 140), CFrame.new(68, 5, 0), Enum.Material.Concrete, Color3.fromRGB(52, 55, 64))

    local coverPositions = {
        Vector3.new(-20, 4, -20),
        Vector3.new(20, 4, -20),
        Vector3.new(-20, 4, 20),
        Vector3.new(20, 4, 20),
    }

    for index, position in ipairs(coverPositions) do
        local cover = part(root, "Cover" .. index, Vector3.new(9, 8, 9), CFrame.new(position), Enum.Material.Metal, Color3.fromRGB(65, 70, 82))
        PhysicsRules.apply(cover, PhysicsRules.World)
    end

    local spawns = Instance.new("Folder")
    spawns.Name = "EnemySpawns"
    spawns.Parent = root

    table.clear(self.enemySpawns)

    for index = 1, 8 do
        local angle = index / 8 * math.pi * 2
        local position = Vector3.new(math.cos(angle) * 50, 1, math.sin(angle) * 50)
        local spawn = part(spawns, "Spawn" .. index, Vector3.new(2, 1, 2), CFrame.new(position), Enum.Material.SmoothPlastic, Color3.new(1, 1, 1))
        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.CanTouch = false
        spawn.CanQuery = false
        table.insert(self.enemySpawns, spawn)
    end

    local playerSpawn = Instance.new("SpawnLocation")
    playerSpawn.Name = "PlayerSpawn"
    playerSpawn.Size = Vector3.new(8, 1, 8)
    playerSpawn.CFrame = self.playerSpawn
    playerSpawn.Anchored = true
    playerSpawn.Neutral = true
    playerSpawn.Material = Enum.Material.Neon
    playerSpawn.Color = Color3.fromRGB(90, 160, 220)
    playerSpawn.Transparency = 0.25
    playerSpawn.Parent = root

    local pvp = Instance.new("Folder")
    pvp.Name = "PVP"
    pvp.Parent = root
    self.pvpRoot = pvp

    local z = Constants.PVPArenaCenterZ
    part(pvp, "Floor", Vector3.new(100, 4, 88), CFrame.new(0, -2, z), Enum.Material.Asphalt, Color3.fromRGB(34, 28, 36))
    part(pvp, "North", Vector3.new(100, 12, 4), CFrame.new(0, 5, z - 44), Enum.Material.Concrete, Color3.fromRGB(60, 50, 68))
    part(pvp, "South", Vector3.new(100, 12, 4), CFrame.new(0, 5, z + 44), Enum.Material.Concrete, Color3.fromRGB(60, 50, 68))
    part(pvp, "West", Vector3.new(4, 12, 88), CFrame.new(-50, 5, z), Enum.Material.Concrete, Color3.fromRGB(60, 50, 68))
    part(pvp, "East", Vector3.new(4, 12, 88), CFrame.new(50, 5, z), Enum.Material.Concrete, Color3.fromRGB(60, 50, 68))

    self.root = root
end

function World:ConfigurePhysics()
    Workspace:RegisterCollisionGroup("CBS_Player")
    Workspace:RegisterCollisionGroup("CBS_NPC")
    Workspace:RegisterCollisionGroup("CBS_Echo")

    Workspace:CollisionGroupSetCollidable("CBS_Player", "CBS_Player", false)
    Workspace:CollisionGroupSetCollidable("CBS_Player", "CBS_NPC", true)
    Workspace:CollisionGroupSetCollidable("CBS_Player", "CBS_Echo", false)
    Workspace:CollisionGroupSetCollidable("CBS_NPC", "CBS_NPC", false)
    Workspace:CollisionGroupSetCollidable("CBS_NPC", "CBS_Echo", false)
    Workspace:CollisionGroupSetCollidable("CBS_Echo", "CBS_Echo", false)
end

function World:Start()
    self:ConfigurePhysics()
    self:Build()

    Lighting.ClockTime = 18.5
    Lighting.Brightness = 2
    Lighting.EnvironmentDiffuseScale = 0.45
    Lighting.EnvironmentSpecularScale = 0.2
    Lighting.FogStart = 220
    Lighting.FogEnd = 700
end

function World:Stop()
end

function World:Reload()
    self:Build()
    return true
end

function World:GetEnemySpawns()
    return self.enemySpawns
end

function World:GetPlayerSpawn()
    return self.playerSpawn
end

function World:IsInArena(position: Vector3)
    return math.abs(position.X) <= Constants.ArenaRadius
        and math.abs(position.Z) <= Constants.ArenaRadius
        and position.Y > -20
        and position.Y < 60
end

function World:IsInPVP(position: Vector3)
    local dz = position.Z - Constants.PVPArenaCenterZ
    return math.abs(position.X) <= Constants.PVPArenaHalfWidth
        and math.abs(dz) <= Constants.PVPArenaHalfDepth
        and position.Y > -20
        and position.Y < 60
end

return World
