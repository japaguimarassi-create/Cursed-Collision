--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "Remotes"
    remotes.Parent = ReplicatedStorage
end

for _, name in ipairs({"Action", "State", "FX"}) do
    if not remotes:FindFirstChild(name) then
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotes
    end
end

local Systems = script.Parent:WaitForChild("Systems")

local DataService = require(Systems:WaitForChild("DataService"))
local EnemyService = require(Systems:WaitForChild("EnemyService"))
local CombatService = require(Systems:WaitForChild("CombatService"))
local WaveService = require(Systems:WaitForChild("WaveService"))
local CompanionService = require(Systems:WaitForChild("CompanionService"))
local MonetizationService = require(Systems:WaitForChild("MonetizationService"))
local WorldService = require(Systems:WaitForChild("WorldService"))
local ShopService = require(Systems:WaitForChild("ShopService"))

WorldService:Init(Config)
DataService:Init(Config)
MonetizationService:Init(Config)
EnemyService:Init(Config, DataService, remotes:WaitForChild("State"))
CombatService:Init(Config, DataService)
WaveService:Init(Config, EnemyService, DataService)
CompanionService:Init(Config, DataService)
ShopService:Init(Config, DataService, MonetizationService)

local function configureCharacter(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local stats = DataService:GetCombatStats(player)

    if stats then
        humanoid.WalkSpeed = stats.WalkSpeed
    else
        humanoid.WalkSpeed = 18
    end

    humanoid.JumpPower = 52
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        local success = DataService:Load(player)
        if not success then
            return
        end

        player.CharacterAdded:Connect(function(character)
            configureCharacter(player, character)
        end)

        if player.Character then
            task.spawn(configureCharacter, player, player.Character)
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        if DataService:Load(player) then
            player.CharacterAdded:Connect(function(character)
                configureCharacter(player, character)
            end)

            if player.Character then
                task.spawn(configureCharacter, player, player.Character)
            end
        end
    end)
end
