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

for _, name in ipairs({"Action", "State", "FX", "Travel"}) do
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
local ZoneService = require(Systems:WaitForChild("ZoneService"))
local TravelService = require(Systems:WaitForChild("TravelService"))

local OWNER_USER_ID = 0
local AdminRemote = Instance.new("RemoteEvent")
AdminRemote.Name = "AdminAction"
AdminRemote.Parent = remotes

WorldService:Init(Config)
ZoneService:Init(Config)
DataService:Init(Config)
MonetizationService:Init(Config)
TravelService:Init(Config, ZoneService)

AdminRemote.OnServerEvent:Connect(function(player, action)
    if player.UserId ~= OWNER_USER_ID then
        return
    end
    if action == "NextWave" then
        WaveService:AdminNextWave()
    elseif action == "Reward" then
        DataService:AddCredits(player, 1000)
    elseif action == "Heal" then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = humanoid.MaxHealth end
    end
end)
EnemyService:Init(Config, DataService, remotes:WaitForChild("State"))
CombatService:Init(Config, DataService)
WaveService:Init(Config, EnemyService, DataService)
CompanionService:Init(Config, DataService)
ShopService:Init(Config, DataService, MonetizationService)

local function configureCharacter(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local stats = DataService:GetCombatStats(player)

    humanoid.WalkSpeed = stats and stats.WalkSpeed or 18
    humanoid.JumpPower = 52
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        if not DataService:Load(player) then
            return
        end

        player:SetAttribute("Zone", player:GetAttribute("Zone") or "PvE")

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
            player:SetAttribute("Zone", player:GetAttribute("Zone") or "PvE")

            player.CharacterAdded:Connect(function(character)
                configureCharacter(player, character)
            end)

            if player.Character then
                task.spawn(configureCharacter, player, player.Character)
            end
        end
    end)
end
