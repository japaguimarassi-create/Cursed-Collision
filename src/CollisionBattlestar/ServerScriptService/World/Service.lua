--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local ArenaBuilder = require(script.Parent.ArenaBuilder)
local ContentBuilder = require(script.Parent.ContentBuilder)

local WorldService = {}
WorldService.__index = WorldService

function WorldService.new(runtimeState)
    return setmetatable({
        runtimeState = runtimeState,
        world = nil,
    }, WorldService)
end

function WorldService:Start()
    self.world = ArenaBuilder.Build()
    ContentBuilder.Build(self.world)
    workspace:SetAttribute(Constants.WorldReadyAttribute, true)
    self.runtimeState:SetMany({
        worldReady = true,
        phase = "Intermission",
    })
end

function WorldService:GetEnemySpawnPoints(): {BasePart}
    assert(self.world, "world not started")
    local folder = self.world:FindFirstChild("EnemySpawnPoints")
    assert(folder, "enemy spawn folder missing")

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
    local radius = Constants.ArenaRadius - 5
    return Vector2.new(position.X, position.Z).Magnitude <= radius
end

return WorldService
