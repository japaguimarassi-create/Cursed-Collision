--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ArenaBuilder = require(script.Parent.ArenaBuilder)
local ContentBuilder = require(script.Parent.ContentBuilder)

local WorldService = {}
WorldService.__index = WorldService

local function configureLighting()
    Lighting.ClockTime = 18.75
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(65, 70, 88)
    Lighting.OutdoorAmbient = Color3.fromRGB(82, 88, 108)
    Lighting.EnvironmentDiffuseScale = 0.45
    Lighting.EnvironmentSpecularScale = 0.25
    Lighting.FogStart = 260
    Lighting.FogEnd = 900

    local atmosphere = Lighting:FindFirstChild("CollisionBattlestarAtmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "CollisionBattlestarAtmosphere"
        atmosphere.Parent = Lighting
    end

    atmosphere.Density = 0.12
    atmosphere.Offset = 0.1
    atmosphere.Color = Color3.fromRGB(170, 190, 215)
    atmosphere.Decay = Color3.fromRGB(55, 65, 90)
    atmosphere.Glare = 0.08
    atmosphere.Haze = 0.65
end

function WorldService.new(runtimeState)
    return setmetatable({
        runtimeState = runtimeState,
        world = nil,
    }, WorldService)
end

function WorldService:Start()
    configureLighting()

    self.world = ArenaBuilder.Build()
    ContentBuilder.Build(self.world)

    workspace:SetAttribute(Constants.WorldReadyAttribute, true)

    self.runtimeState:SetMany({
        worldReady = true,
        phase = "Intermission",
        wave = 0,
        enemiesAlive = 0,
        eliteAlive = false,
        bossId = nil,
        eventId = nil,
    })
end

function WorldService:GetEnemySpawnPoints(): {BasePart}
    assert(self.world, "world not started")

    local folder = self.world:FindFirstChild("EnemySpawnPoints")
    assert(folder and folder:IsA("Folder"), "enemy spawn folder missing")

    local points = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(points, child)
        end
    end

    table.sort(points, function(a, b)
        return a.Name < b.Name
    end)

    return points
end

function WorldService:GetPlayerSpawnCFrame(): CFrame
    assert(self.world, "world not started")

    local spawn = self.world:FindFirstChild("PlayerSpawn")
    assert(spawn and spawn:IsA("SpawnLocation"), "player spawn missing")

    return spawn.CFrame + Vector3.new(0, 4, 0)
end

function WorldService:IsInsideArena(position: Vector3): boolean
    local radius = Constants.ArenaRadius - 7
    return Vector2.new(position.X, position.Z).Magnitude <= radius
end

return WorldService
