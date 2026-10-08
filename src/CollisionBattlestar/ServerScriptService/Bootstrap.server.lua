--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true

local defaultConstants = {
    RemotesFolder = "CollisionBattlestarRemotes",
    CombatRemote = "Combat",
    StateRemote = "State",
    FXRemote = "FX",
    CommerceRemote = "Commerce",
    CompanionRemote = "Companion",
    PvPRemote = "PvP",
    MissionRemote = "Mission",
    AdminRemote = "Admin",
    WorldReadyAttribute = "CBS_WorldReady",
}

local constantsOk, constantsValue = pcall(function()
    return require(ReplicatedStorage.Shared.Constants)
end)

local Constants = constantsOk and constantsValue or defaultConstants

if not constantsOk then
    warn("Collision Battlestar Constants failed to load:", constantsValue)
end

local function getConstant(name: string)
    local value = Constants[name]
    if value == nil then
        return defaultConstants[name]
    end
    return value
end

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

local remotesFolder = ReplicatedStorage:FindFirstChild(getConstant("RemotesFolder"))
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = getConstant("RemotesFolder")
    remotesFolder.Parent = ReplicatedStorage
end

local remotes = {
    Combat = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("CombatRemote")),
    State = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("StateRemote")),
    FX = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("FXRemote")),
    Commerce = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("CommerceRemote")),
    Companion = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("CompanionRemote")),
    PvP = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("PvPRemote")),
    Mission = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("MissionRemote")),
    Admin = getOrCreateRemote(remotesFolder, "RemoteEvent", getConstant("AdminRemote")),
}

local function failBoot(stage: string, err: any)
    local message = ("%s: %s"):format(stage, tostring(err))
    warn("Collision Battlestar server boot failure:", message)
    remotes.State:FireAllClients("BootError", {
        stage = stage,
        message = message,
    })
    workspace:SetAttribute("CBS_ServerBootError", message)
end

local function requireModule(moduleScript: ModuleScript, label: string)
    local ok, value = pcall(require, moduleScript)
    if not ok then
        error(label .. " -> " .. tostring(value))
    end
    return value
end

local RuntimeState
local WorldService
local runtimeState
local worldService

local worldOk, worldError = pcall(function()
    RuntimeState = requireModule(script.Parent.Core.RuntimeState, "RuntimeState")
    WorldService = requireModule(script.Parent.World.Service, "WorldService")

    runtimeState = RuntimeState.new()
    worldService = WorldService.new(runtimeState)
    worldService:Start()
end)

if not worldOk then
    failBoot("world bootstrap", worldError)
    return
end

local Registry = requireModule(script.Parent.Core.ServiceRegistry, "ServiceRegistry")
local registry = Registry.new()

local PersistenceService
local PlayerState
local ProgressionService
local RecoveryService
local SecurityService
local EconomyService
local EnemyService
local PvPService
local CombatService
local WaveService

local coreOk, coreError = pcall(function()
    PersistenceService = requireModule(script.Parent.Persistence.Service, "PersistenceService")
    PlayerState = requireModule(script.Parent.Core.PlayerState, "PlayerState")
    ProgressionService = requireModule(script.Parent.Progression.Service, "ProgressionService")
    RecoveryService = requireModule(script.Parent.Progression.RecoveryService, "RecoveryService")
    SecurityService = requireModule(script.Parent.Security.Service, "SecurityService")
    EconomyService = requireModule(script.Parent.Economy.Service, "EconomyService")
    EnemyService = requireModule(script.Parent.Enemies.Service, "EnemyService")
    PvPService = requireModule(script.Parent.PvP.Service, "PvPService")
    CombatService = requireModule(script.Parent.Combat.Service, "CombatService")
    WaveService = requireModule(script.Parent.Waves.Service, "WaveService")
end)

if not coreOk then
    failBoot("core module load", coreError)
    return
end

local persistenceService = PersistenceService.new()
local playerState = PlayerState.new(persistenceService)
local progressionService = ProgressionService.new(playerState, runtimeState)
local recoveryService = RecoveryService.new(playerState)
local securityService = SecurityService.new(worldService, playerState)
local economyService = EconomyService.new(playerState)
local enemyService = EnemyService.new(runtimeState, worldService, economyService)
local pvpService = PvPService.new(playerState, economyService, worldService, remotes)
local combatService = CombatService.new(
    runtimeState,
    playerState,
    securityService,
    worldService,
    enemyService,
    remotes,
    pvpService
)
local waveService = WaveService.new(runtimeState, worldService, enemyService, economyService)

registry:Register("Persistence", persistenceService)
registry:Register("PlayerState", playerState)
registry:Register("Progression", progressionService)
registry:Register("Recovery", recoveryService)
registry:Register("World", worldService)
registry:Register("Security", securityService)
registry:Register("Economy", economyService)
registry:Register("Enemies", enemyService)
registry:Register("Combat", combatService)
registry:Register("PvP", pvpService)
registry:Register("Waves", waveService)

local coreStartOk, coreStartError = pcall(function()
    registry:StartInOrder({
        "Persistence",
        "PlayerState",
        "Progression",
        "Recovery",
        "Security",
        "Economy",
        "Enemies",
        "PvP",
        "Combat",
        "Waves",
    })
end)

if not coreStartOk then
    failBoot("core service start", coreStartError)
    return
end

local FriendService
local InventoryService
local CompanionService
local ShopService
local MissionService
local AnalyticsService
local TestLabService
local MonetizationService

local function startOptional(name: string, factory)
    local ok, service = pcall(factory)
    if not ok then
        warn(("Collision Battlestar optional service failed [%s]: %s"):format(name, tostring(service)))
        return nil
    end

    if service then
        registry:Register(name, service)
        local startOk, startError = pcall(function()
            registry:Start(name)
        end)

        if not startOk then
            warn(("Collision Battlestar optional service start failed [%s]: %s"):format(name, tostring(startError)))
            return nil
        end
    end

    return service
end

local FriendsModuleOk, FriendsModule = pcall(function()
    return requireModule(script.Parent.Friends.Service, "FriendsService")
end)
if FriendsModuleOk then
    FriendService = startOptional("Friends", function()
        return FriendsModule.new()
    end)
end

local InventoryModuleOk, InventoryModule = pcall(function()
    return requireModule(script.Parent.Shop.InventoryService, "InventoryService")
end)
if InventoryModuleOk then
    InventoryService = startOptional("Inventory", function()
        return InventoryModule.new(playerState)
    end)
end

if FriendService then
    local CompanionModuleOk, CompanionModule = pcall(function()
        return requireModule(script.Parent.Companions.Service, "CompanionService")
    end)

    if CompanionModuleOk then
        CompanionService = startOptional("Companions", function()
            return CompanionModule.new(
                playerState,
                FriendService,
                securityService,
                remotes,
                enemyService
            )
        end)
    end
end

if InventoryService then
    local ShopModuleOk, ShopModule = pcall(function()
        return requireModule(script.Parent.Shop.Service, "ShopService")
    end)

    if ShopModuleOk then
        ShopService = startOptional("Shop", function()
            return ShopModule.new(
                runtimeState,
                playerState,
                progressionService,
                InventoryService,
                remotes
            )
        end)
    end
end

local MissionModuleOk, MissionModule = pcall(function()
    return requireModule(script.Parent.Missions.Service, "MissionService")
end)
if MissionModuleOk then
    MissionService = startOptional("Missions", function()
        return MissionModule.new(playerState, enemyService, runtimeState, remotes)
    end)
end

local AnalyticsModuleOk, AnalyticsModule = pcall(function()
    return requireModule(script.Parent.Analytics.Service, "AnalyticsService")
end)
if AnalyticsModuleOk then
    AnalyticsService = startOptional("Analytics", function()
        return AnalyticsModule.new()
    end)
end

local TestLabModuleOk, TestLabModule = pcall(function()
    return requireModule(script.Parent.Admin.TestLabService, "TestLabService")
end)
if TestLabModuleOk then
    TestLabService = startOptional("TestLab", function()
        return TestLabModule.new(
            playerState,
            enemyService,
            waveService,
            worldService,
            pvpService,
            remotes
        )
    end)
end

local MonetizationModuleOk, MonetizationModule = pcall(function()
    return requireModule(script.Parent.Monetization.Service, "MonetizationService")
end)
if MonetizationModuleOk then
    MonetizationService = startOptional("Monetization", function()
        return MonetizationModule.new()
    end)
end

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

workspace:SetAttribute(getConstant("WorldReadyAttribute"), true)
workspace:SetAttribute("CBS_ServerBootError", nil)
