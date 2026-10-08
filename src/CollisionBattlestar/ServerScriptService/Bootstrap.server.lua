--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Registry = require(script.Parent.Core.ServiceRegistry)
local RuntimeState = require(script.Parent.Core.RuntimeState)
local PlayerState = require(script.Parent.Core.PlayerState)
local PersistenceService = require(script.Parent.Persistence.Service)
local ProgressionService = require(script.Parent.Progression.Service)
local FriendService = require(script.Parent.Friends.Service)
local CompanionService = require(script.Parent.Companions.Service)
local InventoryService = require(script.Parent.Shop.InventoryService)
local ShopService = require(script.Parent.Shop.Service)
local WorldService = require(script.Parent.World.Service)
local SecurityService = require(script.Parent.Security.Service)
local EconomyService = require(script.Parent.Economy.Service)
local EnemyService = require(script.Parent.Enemies.Service)
local CombatService = require(script.Parent.Combat.Service)
local WaveService = require(script.Parent.Waves.Service)

local function getOrCreateRemote(parent: Instance, className: string, name: string)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing.ClassName == className, "remote class mismatch: " .. name)
        return existing
    end

    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = parent
    return remote
end

local remotesFolder = ReplicatedStorage:FindFirstChild(Constants.RemotesFolder)
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = Constants.RemotesFolder
    remotesFolder.Parent = ReplicatedStorage
end

local remotes = {
    Combat = getOrCreateRemote(remotesFolder, "RemoteEvent", Constants.CombatRemote),
    State = getOrCreateRemote(remotesFolder, "RemoteEvent", Constants.StateRemote),
    FX = getOrCreateRemote(remotesFolder, "RemoteEvent", Constants.FXRemote),
    Commerce = getOrCreateRemote(remotesFolder, "RemoteEvent", "Commerce"),
    Companion = getOrCreateRemote(remotesFolder, "RemoteEvent", "Companion"),
}

local runtimeState = RuntimeState.new()
local persistenceService = PersistenceService.new()
local playerState = PlayerState.new(persistenceService)
local progressionService = ProgressionService.new(playerState)
local registry = Registry.new()

local worldService = WorldService.new(runtimeState)
local securityService = SecurityService.new(worldService, playerState)
local economyService = EconomyService.new(playerState)
local enemyService = EnemyService.new(runtimeState, worldService, economyService)
local combatService = CombatService.new(runtimeState, playerState, securityService, worldService, enemyService, remotes)
local waveService = WaveService.new(runtimeState, worldService, enemyService, economyService)
local friendService = FriendService.new()
local inventoryService = InventoryService.new(playerState)
local companionService = CompanionService.new(playerState, friendService, securityService, remotes)
local shopService = ShopService.new(runtimeState, playerState, progressionService, inventoryService, remotes)

registry:Register("Persistence", persistenceService)
registry:Register("PlayerState", playerState)
registry:Register("Progression", progressionService)
registry:Register("World", worldService)
registry:Register("Security", securityService)
registry:Register("Economy", economyService)
registry:Register("Enemies", enemyService)
registry:Register("Combat", combatService)
registry:Register("Friends", friendService)
registry:Register("Inventory", inventoryService)
registry:Register("Companions", companionService)
registry:Register("Shop", shopService)
registry:Register("Waves", waveService)

runtimeState:GetChangedEvent():Connect(function()
    remotes.State:FireAllClients("Snapshot", runtimeState:Snapshot())
end)

remotes.State.OnServerEvent:Connect(function(player, request)
    if type(request) ~= "table" then
        return
    end

    if request.action == "RequestState" then
        remotes.State:FireClient(player, "Snapshot", runtimeState:Snapshot())
        return
    end

    if request.action == "Upgrade" then
        local success, value = progressionService:Purchase(player, request.upgradeId or "Damage")
        remotes.State:FireClient(player, "UpgradeResult", {
            success = success,
            value = value,
            snapshot = progressionService:GetSnapshot(player),
        })
        return
    end
end)

registry:StartInOrder({
    "Persistence",
    "PlayerState",
    "Progression",
    "World",
    "Security",
    "Economy",
    "Friends",
    "Inventory",
    "Enemies",
    "Combat",
    "Companions",
    "Shop",
    "Waves",
})

for _, player in ipairs(Players:GetPlayers()) do
    task.defer(function()
        remotes.State:FireClient(player, "Snapshot", runtimeState:Snapshot())
    end)
end

workspace:SetAttribute(Constants.WorldReadyAttribute, true)
