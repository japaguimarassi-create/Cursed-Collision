--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true

local DEFAULTS = {
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

local function loadConstants()
    local ok, value = pcall(function()
        return require(ReplicatedStorage.Shared.Constants)
    end)

    if ok and type(value) == "table" then
        return value
    end

    warn("Collision Battlestar constants unavailable:", value)
    return DEFAULTS
end

local Constants = loadConstants()

local function constant(name: string)
    local value = Constants[name]
    if value == nil then
        return DEFAULTS[name]
    end
    return value
end

local function remote(parent: Instance, className: string, name: string)
    local existing = parent:FindFirstChild(name)

    if existing then
        if existing.ClassName == className then
            return existing
        end

        existing:Destroy()
    end

    local value = Instance.new(className)
    value.Name = name
    value.Parent = parent
    return value
end

local remotesFolder = ReplicatedStorage:FindFirstChild(constant("RemotesFolder"))
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = constant("RemotesFolder")
    remotesFolder.Parent = ReplicatedStorage
end

local remotes = {
    Combat = remote(remotesFolder, "RemoteEvent", constant("CombatRemote")),
    State = remote(remotesFolder, "RemoteEvent", constant("StateRemote")),
    FX = remote(remotesFolder, "RemoteEvent", constant("FXRemote")),
    Commerce = remote(remotesFolder, "RemoteEvent", constant("CommerceRemote")),
    Companion = remote(remotesFolder, "RemoteEvent", constant("CompanionRemote")),
    PvP = remote(remotesFolder, "RemoteEvent", constant("PvPRemote")),
    Mission = remote(remotesFolder, "RemoteEvent", constant("MissionRemote")),
    Admin = remote(remotesFolder, "RemoteEvent", constant("AdminRemote")),
}

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3)
    local value = Instance.new("Part")
    value.Name = name
    value.Size = size
    value.CFrame = cframe
    value.Anchored = true
    value.Material = material
    value.Color = color
    value.TopSurface = Enum.SurfaceType.Smooth
    value.BottomSurface = Enum.SurfaceType.Smooth
    value.Parent = parent
    return value
end

local function ensureFallbackWorld()
    local existing = workspace:FindFirstChild("CollisionBattlestarWorld")
    if existing then
        return existing
    end

    local world = Instance.new("Folder")
    world.Name = "CollisionBattlestarWorld"
    world.Parent = workspace

    part(
        world,
        "FallbackFloor",
        Vector3.new(180, 4, 180),
        CFrame.new(0, -2, 0),
        Enum.Material.Asphalt,
        Color3.fromRGB(24, 27, 34)
    )

    local edge = 92
    local wallColor = Color3.fromRGB(43, 48, 59)

    part(world, "FallbackNorth", Vector3.new(184, 12, 3), CFrame.new(0, 4, -edge), Enum.Material.Metal, wallColor)
    part(world, "FallbackSouth", Vector3.new(184, 12, 3), CFrame.new(0, 4, edge), Enum.Material.Metal, wallColor)
    part(world, "FallbackWest", Vector3.new(3, 12, 184), CFrame.new(-edge, 4, 0), Enum.Material.Metal, wallColor)
    part(world, "FallbackEast", Vector3.new(3, 12, 184), CFrame.new(edge, 4, 0), Enum.Material.Metal, wallColor)

    local points = Instance.new("Folder")
    points.Name = "EnemySpawnPoints"
    points.Parent = world

    for index = 1, 8 do
        local angle = (index - 1) * math.pi * 2 / 8
        local position = Vector3.new(math.cos(angle) * 58, 2, math.sin(angle) * 58)

        local spawn = part(
            points,
            "FallbackSpawn" .. tostring(index),
            Vector3.new(2, 1, 2),
            CFrame.new(position),
            Enum.Material.SmoothPlastic,
            Color3.new(1, 1, 1)
        )

        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.CanTouch = false
        spawn.CanQuery = false
    end

    local playerSpawn = Instance.new("SpawnLocation")
    playerSpawn.Name = "PlayerSpawn"
    playerSpawn.Size = Vector3.new(8, 1, 8)
    playerSpawn.CFrame = CFrame.new(0, 2, 0)
    playerSpawn.Anchored = true
    playerSpawn.Neutral = true
    playerSpawn.Transparency = 0.12
    playerSpawn.Material = Enum.Material.Neon
    playerSpawn.Color = Color3.fromRGB(85, 165, 215)
    playerSpawn.Parent = world

    workspace:SetAttribute(constant("WorldReadyAttribute"), true)
    return world
end

local fallbackWorld = ensureFallbackWorld()

local function failBoot(stage: string, err: any)
    local message = ("%s: %s"):format(stage, tostring(err))
    warn("Collision Battlestar boot warning:", message)
    workspace:SetAttribute("CBS_ServerBootError", message)
    remotes.State:FireAllClients("BootError", {
        stage = stage,
        message = message,
    })
end

local function requireModule(moduleScript: ModuleScript, label: string)
    local ok, value = pcall(require, moduleScript)

    if not ok then
        error(label .. " -> " .. tostring(value))
    end

    return value
end

local RuntimeState
local runtimeState = requireModule(script.Parent.Core.RuntimeState, "RuntimeState").new()

local MechanicsKernel = requireModule(script.Parent.Core.MechanicsKernel, "MechanicsKernel")
local mechanicsKernel

local worldService
local worldOk, worldResult = pcall(function()
    local WorldService = requireModule(script.Parent.World.Service, "WorldService")
    local service = WorldService.new(runtimeState)
    service:Start()
    return service
end)

if worldOk then
    worldService = worldResult
else
    worldService = {
        world = fallbackWorld,

        GetEnemySpawnPoints = function(self)
            local folder = self.world:FindFirstChild("EnemySpawnPoints")
            local points = {}

            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("BasePart") then
                        table.insert(points, child)
                    end
                end
            end

            return points
        end,

        GetPlayerSpawnCFrame = function(self)
            local spawn = self.world:FindFirstChild("PlayerSpawn")
            if spawn and spawn:IsA("SpawnLocation") then
                return spawn.CFrame + Vector3.new(0, 4, 0)
            end

            return CFrame.new(0, 6, 0)
        end,

        IsInsideArena = function(_, position: Vector3)
            return Vector2.new(position.X, position.Z).Magnitude <= 85
        end,
    }

    runtimeState:SetMany({
        worldReady = true,
        phase = "Intermission",
        wave = 0,
        enemiesAlive = 0,
        eliteAlive = false,
    })

    failBoot("world bootstrap", worldResult)
end

mechanicsKernel = MechanicsKernel.new(runtimeState, remotes)

local Registry = requireModule(script.Parent.Core.ServiceRegistry, "ServiceRegistry")
local registry = Registry.new()

local modulesOk, modules = pcall(function()
    return {
        Persistence = requireModule(script.Parent.Persistence.Service, "PersistenceService"),
        PlayerState = requireModule(script.Parent.Core.PlayerState, "PlayerState"),
        Progression = requireModule(script.Parent.Progression.Service, "ProgressionService"),
        Stats = requireModule(script.Parent.Stats.Service, "StatsService"),
        Recovery = requireModule(script.Parent.Progression.RecoveryService, "RecoveryService"),
        Security = requireModule(script.Parent.Security.Service, "SecurityService"),
        Economy = requireModule(script.Parent.Economy.Service, "EconomyService"),
        Enemies = requireModule(script.Parent.Enemies.Service, "EnemyService"),
        PvP = requireModule(script.Parent.PvP.Service, "PvPService"),
        Combat = requireModule(script.Parent.Combat.Service, "CombatService"),
        Waves = requireModule(script.Parent.Waves.Service, "WaveService"),
    }
end)

if not modulesOk then
    failBoot("core module load", modules)
else
    local PersistenceService = modules.Persistence
    local PlayerState = modules.PlayerState
    local ProgressionService = modules.Progression
    local RecoveryService = modules.Recovery
    local SecurityService = modules.Security
    local EconomyService = modules.Economy
    local EnemyService = modules.Enemies
    local PvPService = modules.PvP
    local CombatService = modules.Combat
    local WaveService = modules.Waves

    local persistenceService = PersistenceService.new()
    local playerState = PlayerState.new(persistenceService)
    local progressionService = ProgressionService.new(playerState, runtimeState)
    local recoveryService = RecoveryService.new(playerState)
    local securityService = SecurityService.new(worldService, playerState)
    local economyService = EconomyService.new(playerState)
    local enemyService = EnemyService.new(runtimeState, worldService, economyService, mechanicsKernel, remotes)
    local statsService = modules.Stats.new(playerState, runtimeState, enemyService)
    local pvpService = PvPService.new(playerState, economyService, worldService, remotes)
    local combatService = CombatService.new(
        runtimeState,
        playerState,
        securityService,
        worldService,
        enemyService,
        remotes,
        pvpService,
        mechanicsKernel
    )
    local waveService = WaveService.new(runtimeState, worldService, enemyService, economyService, mechanicsKernel, remotes)

    registry:Register("Persistence", persistenceService)
    registry:Register("PlayerState", playerState)
    registry:Register("Progression", progressionService)
    registry:Register("Stats", statsService)
    registry:Register("Recovery", recoveryService)
    registry:Register("World", worldService)
    registry:Register("Security", securityService)
    registry:Register("Economy", economyService)
    registry:Register("Enemies", enemyService)
    registry:Register("Combat", combatService)
    registry:Register("PvP", pvpService)
    registry:Register("Waves", waveService)

    mechanicsKernel:Register("World", worldService)
    mechanicsKernel:Register("PlayerState", playerState)
    mechanicsKernel:Register("Stats", statsService)
    mechanicsKernel:Register("Enemies", enemyService)
    mechanicsKernel:Register("Combat", combatService)
    mechanicsKernel:Register("PvP", pvpService)
    mechanicsKernel:Register("Waves", waveService)

    local coreStartOk, coreStartError = pcall(function()
        registry:StartInOrder({
            "Persistence",
            "PlayerState",
            "Progression",
            "Stats",
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
    else
        mechanicsKernel:Start()
    end

    local function startOptional(name: string, factory)
        local ok, service = pcall(factory)

        if not ok then
            warn(("Collision Battlestar optional service failed [%s]: %s"):format(name, tostring(service)))
            return nil
        end

        if service then
            registry:Register(name, service)
            mechanicsKernel:Register(name, service)

            local started, startError = pcall(function()
                registry:Start(name)
            end)

            if not started then
                warn(("Collision Battlestar optional service start failed [%s]: %s"):format(name, tostring(startError)))
                return nil
            end
        end

        return service
    end

    local FriendsModuleOk, FriendsModule = pcall(function()
        return requireModule(script.Parent.Friends.Service, "FriendsService")
    end)

    local FriendService
    if FriendsModuleOk then
        FriendService = startOptional("Friends", function()
            return FriendsModule.new()
        end)
    end

    local InventoryModuleOk, InventoryModule = pcall(function()
        return requireModule(script.Parent.Shop.InventoryService, "InventoryService")
    end)

    local InventoryService
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
            startOptional("Companions", function()
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
            startOptional("Shop", function()
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
        startOptional("Missions", function()
            return MissionModule.new(playerState, enemyService, runtimeState, remotes)
        end)
    end

    local AnalyticsModuleOk, AnalyticsModule = pcall(function()
        return requireModule(script.Parent.Analytics.Service, "AnalyticsService")
    end)

    if AnalyticsModuleOk then
        startOptional("Analytics", function()
            return AnalyticsModule.new()
        end)
    end

    local TestLabModuleOk, TestLabModule = pcall(function()
        return requireModule(script.Parent.Admin.TestLabService, "TestLabService")
    end)

    if TestLabModuleOk then
        startOptional("TestLab", function()
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
        startOptional("Monetization", function()
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
        end
    end)
end

workspace:SetAttribute(constant("WorldReadyAttribute"), true)
