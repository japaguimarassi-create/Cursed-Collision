local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local CoreKernel = {}

local function setAttribute(core, name, value)
    if core then
        pcall(function()
            core:SetAttribute(name, value)
        end)
    end
end

local function setServiceStatus(core, states, name, state, detail)
    states[name] = { state = state, detail = string.sub(tostring(detail or ""), 1, 180), timestamp = os.time() }
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(states)
    end)
    if ok then
        setAttribute(core, "ServiceStatusJson", string.sub(encoded, 1, 9000))
    end
end

local function safeCall(core, states, name, callback)
    local success, result = pcall(callback)
    if success then
        setServiceStatus(core, states, name, "Ready", "")
        return true, result
    end
    warn("[StealAnAnimal/CoreKernel] " .. name .. " failed: " .. tostring(result))
    setServiceStatus(core, states, name, "Failed", "See server Output for the error.")
    return false, result
end

local function safeRequire(core, states, container, name)
    local module = container and container:FindFirstChild(name)
    if not module or not module:IsA("ModuleScript") then
        setAttribute(core, "BootState", "Degraded")
        setServiceStatus(core, states, name, "Failed", "ModuleScript missing.")
        warn("[StealAnAnimal/CoreKernel] Missing ModuleScript: " .. name)
        return nil
    end
    local ok, result = pcall(require, module)
    if not ok then
        setAttribute(core, "BootState", "Degraded")
        setServiceStatus(core, states, name, "Failed", "Module require failed; see server Output.")
        warn("[StealAnAnimal/CoreKernel] require(" .. name .. ") failed: " .. tostring(result))
        return nil
    end
    setServiceStatus(core, states, name, "Loaded", "")
    return result
end

local NullService = setmetatable({}, {
    __index = function(_, methodName)
        if methodName == "IsLoaded" or methodName == "Has" then
            return function() return false end
        end
        if methodName == "Load" then
            return function() return false end
        end
        return function() return nil end
    end,
})

function CoreKernel.Start()
    local core = ReplicatedStorage:WaitForChild("StealAnimalCore", 20)
    if not core then
        warn("[StealAnAnimal/CoreKernel] Core Shell did not appear within 20 seconds.")
        return false
    end
    local shellDeadline = os.clock() + 20
    while core:GetAttribute("CoreShellReady") ~= true and os.clock() < shellDeadline do
        task.wait(0.1)
    end
    if core:GetAttribute("CoreShellReady") ~= true then
        setAttribute(core, "BootState", "Degraded")
        setAttribute(core, "WorldState", "Degraded")
        setAttribute(core, "LastFailure", "Core Shell did not finish bootstrap; see server Output.")
        return false
    end

    setAttribute(core, "BootState", "Loading")
    setAttribute(core, "WorldState", "Building")
    setAttribute(core, "LastFailure", "")
    local states = {}
    local servicesFolder = script.Parent
    local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
    local configModule = sharedFolder and sharedFolder:FindFirstChild("Config")
    local configOK, Config = pcall(function()
        assert(configModule and configModule:IsA("ModuleScript"), "Shared Config ModuleScript is missing")
        return require(configModule)
    end)
    if not configOK then
        warn("[StealAnAnimal/CoreKernel] Shared Config failed: " .. tostring(Config))
        setAttribute(core, "BootState", "Degraded")
        setAttribute(core, "WorldState", "Degraded")
        setAttribute(core, "LastFailure", "Shared Config failed to load; fallback world retained.")
        setServiceStatus(core, states, "Config", "Failed", "See server Output.")
        return false
    end
    setAttribute(core, "BuildTag", Config.ReleaseTag or Config.GameName or "StealAnAnimal")

    local remotes = ReplicatedStorage:FindFirstChild("RoubeAnimalRemotes")
    local notifyRemote = remotes and remotes:FindFirstChild("Notify")
    local function notify(player, message, messageType)
        if not player or player.Parent ~= Players or not notifyRemote or not notifyRemote:IsA("RemoteEvent") then
            return
        end
        pcall(function()
            notifyRemote:FireClient(player, tostring(message), tostring(messageType or "Info"))
        end)
    end

    local mapProbe = safeRequire(core, states, servicesFolder, "MapProbe")
    if mapProbe and type(mapProbe.Init) == "function" then
        safeCall(core, states, "MapProbe.Init", function()
            assert(mapProbe.Init(core), "MapProbe could not attach the health-report endpoint")
        end)
    end

    local WorldBuilder = safeRequire(core, states, servicesFolder, "WorldBuilder")
    if not WorldBuilder or type(WorldBuilder.Build) ~= "function" then
        setAttribute(core, "BootState", "Degraded")
        setAttribute(core, "WorldState", "Degraded")
        setAttribute(core, "LastFailure", "WorldBuilder is unavailable; safe fallback remains active.")
        return false
    end

    local builtRoot
    local buildOK = safeCall(core, states, "WorldBuilder.Build", function()
        builtRoot = WorldBuilder.Build()
        assert(builtRoot and builtRoot:IsA("Folder"), "WorldBuilder did not return a root Folder")
        assert(builtRoot.Name == "StealAnAnimal" and builtRoot.Parent == Workspace, "WorldBuilder did not activate the staged map")
        assert(builtRoot:GetAttribute("MapReady") == true, "WorldBuilder map readiness checks failed")
    end)
    if not buildOK then
        setAttribute(core, "BootState", "Degraded")
        setAttribute(core, "WorldState", "Degraded")
        setAttribute(core, "LastFailure", "Map build did not pass readiness checks; safe fallback retained.")
        if mapProbe and type(mapProbe.CollectServerReport) == "function" then
            pcall(mapProbe.CollectServerReport)
        end
        return false
    end
    setAttribute(core, "WorldState", "Ready")
    setAttribute(core, "FallbackPresent", false)

    local modules = { WorldBuilder = WorldBuilder, MapProbe = mapProbe }
    if mapProbe and type(mapProbe.StartVirtualPlayer) == "function" then
        local probeStarted = safeCall(core, states, "MapProbe.StartVirtualPlayer", function()
            assert(mapProbe.StartVirtualPlayer(WorldBuilder, Config), "Virtual player scan did not start")
        end)
        if not probeStarted then
            setAttribute(core, "BootState", "Degraded")
        end
    end
    local serviceNames = {
        "ProfileService", "AnimalService", "TrainingService", "ShopService",
        "GuardianService", "AnimalBrain", "StackableProductService", "RebirthService",
        "BarnService", "ProgressionService",
    }
    for _, name in ipairs(serviceNames) do
        modules[name] = safeRequire(core, states, servicesFolder, name)
    end

    local ProfileService = modules.ProfileService or NullService
    local AnimalService = modules.AnimalService or NullService
    local TrainingService = modules.TrainingService or NullService
    local ShopService = modules.ShopService or NullService
    local PassService = NullService
    local GuardianService = modules.GuardianService or NullService
    local AnimalBrain = modules.AnimalBrain or NullService
    local StackableProductService = modules.StackableProductService or NullService
    local RebirthService = modules.RebirthService or NullService
    local BarnService = modules.BarnService or NullService
    local ProgressionService = modules.ProgressionService or NullService

    local function startService(name, callback)
        local ok = safeCall(core, states, name .. ".Start", callback)
        if not ok then
            setAttribute(core, "BootState", "Degraded")
        end
        return ok
    end

    if modules.AnimalService then
        startService("AnimalService", function()
            AnimalService.Start(ProfileService, WorldBuilder, PassService, notify)
        end)
    end
    if modules.ShopService then
        startService("ShopService", function()
            ShopService.Start(ProfileService, AnimalService, PassService, remotes:FindFirstChild("RequestUpgrade"), notify)
        end)
    end
    if modules.TrainingService then
        startService("TrainingService", function()
            TrainingService.Start(ProfileService, WorldBuilder, AnimalService, PassService, notify)
        end)
    end
    if modules.AnimalBrain then
        startService("AnimalBrain.Wildlife", function()
            AnimalBrain.StartWildlife(WorldBuilder, Config)
        end)
    end
    if modules.GuardianService and modules.AnimalBrain then
        startService("GuardianService", function()
            GuardianService.Start(WorldBuilder, AnimalService, notify)
        end)
    end
    if modules.StackableProductService then
        startService("StackableProductService", function()
            StackableProductService.Start(ProfileService, remotes:FindFirstChild("RequestStackableProduct"), remotes:FindFirstChild("PromptStackableProduct"), notify)
        end)
    end
    if modules.RebirthService then
        startService("RebirthService", function()
            RebirthService.Start(ProfileService, AnimalService, remotes:FindFirstChild("RequestRebirth"), notify)
        end)
    end
    if modules.BarnService then
        startService("BarnService", function()
            BarnService.Start(ProfileService, WorldBuilder, AnimalService, PassService, remotes:FindFirstChild("RequestCollectBarnIncome"), notify)
        end)
    end
    if modules.ProgressionService then
        startService("ProgressionService", function()
            ProgressionService.Start(ProfileService, remotes:FindFirstChild("RequestDailyReward"), remotes:FindFirstChild("RequestRedeemCode"), remotes:FindFirstChild("RequestQuest"), notify)
        end)
    end
    if modules.ProfileService and type(ProfileService.StartAutosave) == "function" then
        startService("ProfileService.Autosave", function()
            ProfileService.StartAutosave()
        end)
    end
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

if core:GetAttribute("BootState") ~= "Degraded" then
        setAttribute(core, "BootState", "Ready")
    end
    setAttribute(core, "WorldState", "Ready")
    if mapProbe and type(mapProbe.CollectServerReport) == "function" then
        pcall(mapProbe.CollectServerReport)
    end
    print(Config.GameName .. " server initialized. Core state: " .. tostring(core:GetAttribute("BootState")) .. ".")

end

return CoreKernel
