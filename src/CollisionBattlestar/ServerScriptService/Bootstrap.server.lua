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

for _, name in ipairs({"State", "FX"}) do
    if not remotes:FindFirstChild(name) then
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotes
    end
end

local Systems = script.Parent:WaitForChild("Systems")
local WorldService = require(Systems:WaitForChild("WorldService"))
local TagService = require(Systems:WaitForChild("TagService"))

WorldService:Init(Config)
TagService:Init(Config)

local function configureCharacter(character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    humanoid.WalkSpeed = Config.Movement.WalkSpeed
    humanoid.JumpPower = Config.Movement.JumpPower
    humanoid:SetAttribute("CombatReady", false)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(configureCharacter)
    if player.Character then
        task.spawn(configureCharacter, player.Character)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(configureCharacter)
    if player.Character then
        task.spawn(configureCharacter, player.Character)
    end
end
