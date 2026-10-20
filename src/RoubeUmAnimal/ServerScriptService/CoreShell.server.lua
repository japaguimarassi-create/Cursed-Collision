local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local function ensureInstance(parent, name, className)
    local current = parent:FindFirstChild(name)
    if current and current.ClassName == className then
        return current
    end
    if current then
        current:Destroy()
    end
    local instance = Instance.new(className)
    instance.Name = name
    instance.Parent = parent
    return instance
end

local core = ensureInstance(ReplicatedStorage, "StealAnimalCore", "Folder")
core:SetAttribute("CoreShellReady", false)
core:SetAttribute("BootState", "Bootstrapping")
core:SetAttribute("WorldState", "Bootstrapping")
core:SetAttribute("BootStartedAt", os.time())
core:SetAttribute("BuildTag", "StealAnAnimal-core-shell")
core:SetAttribute("LastFailure", "")
core:SetAttribute("ServiceStatusJson", "{}")

local diagnostics = ensureInstance(core, "Diagnostics", "Folder")
local clientProbeRemote = ensureInstance(diagnostics, "ClientProbeReport", "RemoteEvent")
local healthReportRemote = ensureInstance(diagnostics, "RequestHealthReport", "RemoteFunction")

local remotes = ensureInstance(ReplicatedStorage, "RoubeAnimalRemotes", "Folder")
local remoteNames = {
    "Notify", "RequestUpgrade",
    "RequestStackableProduct", "PromptStackableProduct", "RequestRebirth",
    "RequestDailyReward", "RequestRedeemCode", "RequestQuest", "RequestCollectBarnIncome",
}
for _, name in ipairs(remoteNames) do
    ensureInstance(remotes, name, "RemoteEvent")
end

local function ensureFallbackWorld()
    local root = Workspace:FindFirstChild("StealAnAnimal")
    if not root then
        root = Instance.new("Folder")
        root.Name = "StealAnAnimal"
        root.Parent = Workspace
        root:SetAttribute("CoreFallback", true)
        root:SetAttribute("RootRole", "Fallback")
        root:SetAttribute("MapReady", nil)
    end

    local map = ensureInstance(root, "Map", "Folder")
    ensureInstance(root, "Farms", "Folder")
    ensureInstance(root, "Animals", "Folder")
    ensureInstance(root, "Guardians", "Folder")
    ensureInstance(root, "Training", "Folder")

    if not map:FindFirstChild("FallbackGround") and not map:FindFirstChild("HubGround") then
        local ground = Instance.new("Part")
        ground.Name = "FallbackGround"
        ground.Anchored = true
        ground.Size = Vector3.new(180, 2, 180)
        ground.CFrame = CFrame.new(0, -1, 0)
        ground.Color = Color3.fromRGB(126, 190, 91)
        ground.Material = Enum.Material.Grass
        ground.TopSurface = Enum.SurfaceType.Smooth
        ground.BottomSurface = Enum.SurfaceType.Smooth
        ground.Parent = map
        ground:SetAttribute("CoreFallback", true)
    end

    if not map:FindFirstChild("WorldSpawn") then
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "WorldSpawn"
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Duration = 0
        spawn.Size = Vector3.new(8, 1, 8)
        spawn.Position = Vector3.new(0, 1, 0)
        spawn.Color = Color3.fromRGB(79, 207, 112)
        spawn.Material = Enum.Material.Neon
        spawn.Transparency = 0.2
        spawn.Parent = map
        spawn:SetAttribute("CoreFallback", true)
    end

    if root:GetAttribute("MapReady") ~= true then
        root:SetAttribute("RootRole", "Fallback")
        root:SetAttribute("CoreFallback", true)
    end
    return root
end

local fallbackRoot = ensureFallbackWorld()
core:SetAttribute("FallbackPresent", fallbackRoot:GetAttribute("CoreFallback") == true)

local probesByUserId = {}
local lastProbeAt = {}
clientProbeRemote.OnServerEvent:Connect(function(player, payload)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or type(payload) ~= "table" then
        return
    end
    local now = os.clock()
    if now - (lastProbeAt[player.UserId] or 0) < 0.8 then
        return
    end
    lastProbeAt[player.UserId] = now

    local report = {
        phase = (payload.phase == "HudReady" and "HudReady") or (payload.phase == "Refresh" and "Refresh") or "Bootstrap",
        timestamp = os.time(),
        hudPresent = payload.hudPresent == true,
        mainHudReady = payload.mainHudReady == true,
        activeRootPresent = payload.activeRootPresent == true,
        mapReady = payload.mapReady == true,
        remoteFolderPresent = payload.remoteFolderPresent == true,
        viewportWidth = math.clamp(math.floor(tonumber(payload.viewportWidth) or 0), 0, 10000),
        viewportHeight = math.clamp(math.floor(tonumber(payload.viewportHeight) or 0), 0, 10000),
    }
    probesByUserId[player.UserId] = report
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(report)
    end)
    if ok then
        core:SetAttribute("LatestClientProbeJson", encoded)
    end
    local count = 0
    for _ in pairs(probesByUserId) do
        count += 1
    end
    core:SetAttribute("ClientProbeCount", count)
end)

local lastHealthRequest = {}
healthReportRemote.OnServerInvoke = function(player)
    local now = os.clock()
    if player and now - (lastHealthRequest[player.UserId] or 0) < 1 then
        return { ok = false, error = "RATE_LIMITED" }
    end
    if player then
        lastHealthRequest[player.UserId] = now
    end
    return {
        ok = true,
        bootState = core:GetAttribute("BootState"),
        worldState = core:GetAttribute("WorldState"),
        buildTag = core:GetAttribute("BuildTag"),
        lastFailure = core:GetAttribute("LastFailure"),
        fallbackPresent = core:GetAttribute("FallbackPresent") == true,
    }
end

Players.PlayerRemoving:Connect(function(player)
    probesByUserId[player.UserId] = nil
    lastProbeAt[player.UserId] = nil
    lastHealthRequest[player.UserId] = nil
    local count = 0
    for _ in pairs(probesByUserId) do
        count += 1
    end
    core:SetAttribute("ClientProbeCount", count)
end)

task.spawn(function()
    while core.Parent do
        local previousRemotes = remotes
        remotes = ensureInstance(ReplicatedStorage, "RoubeAnimalRemotes", "Folder")
        local remotesRepaired = previousRemotes ~= remotes
        for _, name in ipairs(remoteNames) do
            local previousRemote = remotes:FindFirstChild(name)
            local currentRemote = ensureInstance(remotes, name, "RemoteEvent")
            if previousRemote ~= currentRemote then
                remotesRepaired = true
            end
        end
        if remotesRepaired and core:GetAttribute("BootState") == "Ready" then
            core:SetAttribute("BootState", "Degraded")
            core:SetAttribute("LastFailure", "A gameplay remote was restored after startup. Service listeners may need a new server session.")
        end

        local activeRoot = Workspace:FindFirstChild("StealAnAnimal")
        if not activeRoot then
            local wasReady = core:GetAttribute("WorldState") == "Ready"
            local restored = ensureFallbackWorld()
            core:SetAttribute("FallbackPresent", restored:GetAttribute("CoreFallback") == true)
            if wasReady then
                core:SetAttribute("BootState", "Degraded")
                core:SetAttribute("WorldState", "Degraded")
                core:SetAttribute("LastFailure", "Active map root disappeared; fallback world restored.")
            end
        elseif activeRoot:GetAttribute("MapReady") ~= true then
            local wasReady = core:GetAttribute("WorldState") == "Ready" and activeRoot:GetAttribute("CoreFallback") ~= true
            ensureFallbackWorld()
            core:SetAttribute("FallbackPresent", true)
            if wasReady then
                core:SetAttribute("BootState", "Degraded")
                core:SetAttribute("WorldState", "Degraded")
                core:SetAttribute("LastFailure", "Active map lost readiness; fallback floor/spawn checked.")
            end
        else
            core:SetAttribute("FallbackPresent", false)
        end
        task.wait(5)
    end
end)

core:SetAttribute("CoreShellReady", true)
core:SetAttribute("BootState", "ShellReady")
print("[StealAnAnimal/CoreShell] Bootstrap remotes, fallback and diagnostics are ready.")
