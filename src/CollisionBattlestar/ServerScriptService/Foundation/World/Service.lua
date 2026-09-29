--!strict

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local SpawnController = require(script.Parent:WaitForChild("SpawnController"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({spawn = nil, prompt = nil, arena = nil}, Service)
end

function Service:Init()
    local old = workspace:FindFirstChild("CollisionArena")
    if old then
        old:Destroy()
    end

    self.arena = Instance.new("Folder")
    self.arena.Name = "CollisionArena"
    self.arena.Parent = workspace

    local playerSpawn, enemySpawns, prompt = ArenaBuilder.Build(self.arena)
    self.spawn = SpawnController.new(playerSpawn, enemySpawns)
    self.prompt = prompt

    Lighting.ClockTime = 17.8
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(55, 62, 78)
    Lighting.OutdoorAmbient = Color3.fromRGB(85, 94, 112)
    Lighting.FogColor = Color3.fromRGB(35, 42, 58)
    Lighting.FogEnd = 600

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere:Destroy()
    end

    atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.18
    atmosphere.Offset = 0.05
    atmosphere.Glare = 0.08
    atmosphere.Haze = 0.15
    atmosphere.Color = Color3.fromRGB(180, 204, 255)
    atmosphere.Decay = Color3.fromRGB(75, 88, 120)
    atmosphere.Parent = Lighting
end

function Service:Start()
    local function spawnPlayer(player: Player, character: Model)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root then
            character:PivotTo(self.spawn:PlayerCFrame())
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            spawnPlayer(player, character)
        end)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function(character)
            spawnPlayer(player, character)
        end)
        if player.Character then
            spawnPlayer(player, player.Character)
        end
    end
end

function Service:GetEnemySpawnCFrame(index: number): CFrame
    return self.spawn:EnemyCFrame(index)
end

function Service:GetUpgradePrompt(): ProximityPrompt
    return self.prompt
end

return Service