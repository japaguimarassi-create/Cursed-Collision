local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent:WaitForChild("Services")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldBuilder = require(Services:WaitForChild("WorldBuilder"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local AnimalService = require(Services:WaitForChild("AnimalService"))
local TrainingService = require(Services:WaitForChild("TrainingService"))
local ShopService = require(Services:WaitForChild("ShopService"))
local PassService = require(Services:WaitForChild("PassService"))
local GuardianService = require(Services:WaitForChild("GuardianService"))
local StackableProductService = require(Services:WaitForChild("StackableProductService"))
local RebirthService = require(Services:WaitForChild("RebirthService"))
local BarnService = require(Services:WaitForChild("BarnService"))
local ProgressionService = require(Services:WaitForChild("ProgressionService"))

local function folder(parent, name)
    local object = parent:FindFirstChild(name)
    if object then
        assert(object:IsA("Folder"), name .. " must be a Folder")
        return object
    end
    object = Instance.new("Folder")
    object.Name = name
    object.Parent = parent
    return object
end

local function remote(parent, name)
    local object = parent:FindFirstChild(name)
    if object then
        assert(object:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
        return object
    end
    object = Instance.new("RemoteEvent")
    object.Name = name
    object.Parent = parent
    return object
end

local remotes = folder(ReplicatedStorage, "RoubeAnimalRemotes")
local notifyRemote = remote(remotes, "Notify")
local upgradeRemote = remote(remotes, "RequestUpgrade")
local passRequestRemote = remote(remotes, "RequestGamepass")
local passPromptRemote = remote(remotes, "PromptGamepass")
local productRequestRemote = remote(remotes, "RequestStackableProduct")
local productPromptRemote = remote(remotes, "PromptStackableProduct")
local rebirthRequestRemote = remote(remotes, "RequestRebirth")
local dailyRewardRemote = remote(remotes, "RequestDailyReward")
local redeemCodeRemote = remote(remotes, "RequestRedeemCode")
local questClaimRemote = remote(remotes, "RequestQuest")

local function notify(player, message, messageType)
    if not player or player.Parent ~= Players then
        return
    end
    pcall(function()
        notifyRemote:FireClient(player, tostring(message), tostring(messageType or "Info"))
    end)
end

WorldBuilder.Build()

AnimalService.Start(ProfileService, WorldBuilder, PassService, notify)
ShopService.Start(ProfileService, AnimalService, PassService, upgradeRemote, notify)
PassService.Start(passRequestRemote, passPromptRemote, notify, AnimalService.ApplyMovement)
TrainingService.Start(ProfileService, WorldBuilder, AnimalService, PassService, notify)
GuardianService.Start(WorldBuilder, AnimalService, notify)
StackableProductService.Start(ProfileService, productRequestRemote, productPromptRemote, notify)
RebirthService.Start(ProfileService, AnimalService, rebirthRequestRemote, notify)
BarnService.Start(ProfileService, WorldBuilder, AnimalService, PassService, notify)
ProgressionService.Start(ProfileService, dailyRewardRemote, redeemCodeRemote, questClaimRemote, notify)
ProfileService.StartAutosave()

local deathConnections = {}
local function characterAdded(player, character)
    local humanoid = character:WaitForChild("Humanoid", 15)
    if not humanoid then
        return
    end
    if deathConnections[player] then
        deathConnections[player]:Disconnect()
    end
    deathConnections[player] = humanoid.Died:Connect(function()
        AnimalService.Lose(player, "The guardian caught you. Your carried animal escaped.")
    end)
    task.spawn(function()
        local deadline = os.clock() + 35
        while player.Parent == Players and not ProfileService.IsLoaded(player) and os.clock() < deadline do
            task.wait(0.25)
        end
        if player.Parent ~= Players or not ProfileService.IsLoaded(player) then
            return
        end
        if not WorldBuilder.GetOwnedBase(player) then
            WorldBuilder.AssignBase(player)
        end
        WorldBuilder.TeleportToBase(player)
        AnimalService.ApplyMovement(player)
    end)
end

local function playerAdded(player)
    player:SetAttribute("DataLoaded", false)
    player:SetAttribute("CarryingAnimal", false)
    player:SetAttribute("HasDoubleIncome", false)
    player:SetAttribute("HasDoubleSpeed", false)
    player:SetAttribute("HasVIPFarm", false)
    player:SetAttribute("HasExtraBarnSlots", false)
    player.CharacterAdded:Connect(function(character)
        task.spawn(characterAdded, player, character)
    end)
    if player.Character then
        task.spawn(characterAdded, player, player.Character)
    end

    task.spawn(function()
        local loaded = ProfileService.Load(player)
        if not loaded then
            if player.Parent == Players then
                player:Kick("Your farm data could not be loaded safely. Please rejoin.")
            end
            return
        end
        if player.Parent ~= Players then
            ProfileService.Save(player, true)
            ProfileService.Remove(player)
            return
        end

        local base = WorldBuilder.AssignBase(player)
        if not base then
            notify(player, "All eight farms are occupied. Please join another server.", "Error")
            player:Kick("All farms are occupied. Please join another server.")
            return
        end

        task.spawn(function()
            local passOk, passErr = pcall(PassService.Load, player)
            if not passOk then
                warn("StealAnAnimal: gamepass loading failed: " .. tostring(passErr))
            end
            if player.Parent ~= Players or not ProfileService.IsLoaded(player) then
                return
            end
            local barnOk, barnErr = pcall(BarnService.InitializePlayer, player)
            if not barnOk then
                warn("StealAnAnimal: barn initialization failed: " .. tostring(barnErr))
                BarnService.RefreshPlayer(player)
            end
            AnimalService.ApplyMovement(player)
            notify(player, "Welcome! Steal a wild animal, escape its giant guardian, and store it in your barn to earn coins.", "Success")
        end)
    end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
    ProfileService.MarkLeaving(player)
    AnimalService.RemovePlayer(player)
    TrainingService.RemovePlayer(player)
    ShopService.RemovePlayer(player)
    PassService.RemovePlayer(player)
    StackableProductService.RemovePlayer(player)
    RebirthService.RemovePlayer(player)
    ProgressionService.RemovePlayer(player)
    BarnService.RemovePlayer(player)
    WorldBuilder.ReleaseBase(player)
    if deathConnections[player] then
        deathConnections[player]:Disconnect()
        deathConnections[player] = nil
    end
    ProfileService.Save(player, true)
    ProfileService.Remove(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(playerAdded, player)
end

game:BindToClose(function()
    local pending = 0
    for _, player in ipairs(Players:GetPlayers()) do
        pending += 1
        task.spawn(function()
            ProfileService.Save(player, true)
            pending -= 1
        end)
    end
    local deadline = os.clock() + 25
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)

print(Config.GameName .. " server initialized.")
