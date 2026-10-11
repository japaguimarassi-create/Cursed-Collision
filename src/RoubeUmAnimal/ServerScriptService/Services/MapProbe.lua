local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local MapProbe = {}
local core
local lastRequestByUserId = {}
local virtualPlayerStarted = false
local virtualPlayerModel

local BIOMES = {
    { Name = "Meadow", X = 160 },
    { Name = "Forest", X = 315 },
    { Name = "Wetlands", X = 470 },
    { Name = "Snow", X = 625 },
    { Name = "Savannah", X = 780 },
    { Name = "Volcano", X = 935 },
}
local REMOTES = {
    "Notify", "RequestUpgrade", "RequestGamepass", "PromptGamepass",
    "RequestStackableProduct", "PromptStackableProduct", "RequestRebirth",
    "RequestDailyReward", "RequestRedeemCode", "RequestQuest", "RequestCollectBarnIncome",
}

local function countModels(folder, predicate)
    local count = 0
    if not folder then
        return count
    end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and (not predicate or predicate(child)) then
            count += 1
        end
    end
    return count
end

local function decodeAttribute(name)
    local raw = core and core:GetAttribute(name)
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    local ok, value = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok and type(value) == "table" then
        return value
    end
    return nil
end

local function inspectRoot(root)
    if not root then
        return {
            present = false, ready = false, role = "Absent",
            farms = 0, biomes = 0, animals = 0, guardians = 0,
            spawnPresent = false, buildErrors = {},
        }
    end
    local map = root:FindFirstChild("Map")
    local farmFolder = root:FindFirstChild("Farms")
    local animalFolder = root:FindFirstChild("Animals")
    local guardianFolder = root:FindFirstChild("Guardians")
    local biomeCount = 0
    if map then
        for _, biome in ipairs(BIOMES) do
            if map:FindFirstChild(biome.Name .. "Ground") then
                biomeCount += 1
            end
        end
    end
    local errors = {}
    for name, value in pairs(root:GetAttributes()) do
        if string.sub(name, 1, 9) == "MapError_" and value == true and #errors < 12 then
            table.insert(errors, name)
        end
    end
    table.sort(errors)
    return {
        present = true,
        ready = root:GetAttribute("MapReady") == true,
        role = root:GetAttribute("RootRole") or (root:GetAttribute("CoreFallback") and "Fallback" or "Unknown"),
        farms = farmFolder and #farmFolder:GetChildren() or 0,
        biomes = biomeCount,
        animals = countModels(animalFolder, function(model)
            return type(model:GetAttribute("AnimalId")) == "string"
        end),
        guardians = countModels(guardianFolder, function(model)
            return model:GetAttribute("IsGiantAnimal") == true
        end),
        spawnPresent = map ~= nil and map:FindFirstChild("WorldSpawn") ~= nil,
        buildErrors = errors,
    }
end

local function setVirtualReport(report)
    if not core then
        return
    end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(report)
    end)
    if ok then
        core:SetAttribute("VirtualPlayerReportJson", string.sub(encoded, 1, 8500))
        core:SetAttribute("VirtualPlayerState", tostring(report.status or "Running"))
    end
end

local function createVirtualPlayer(startPosition)
    local diagnostics = Workspace:FindFirstChild("StealAnAnimalDiagnostics")
    if not diagnostics then
        diagnostics = Instance.new("Folder")
        diagnostics.Name = "StealAnAnimalDiagnostics"
        diagnostics.Parent = Workspace
    end
    diagnostics:SetAttribute("VirtualPlayerCount", 1)
    diagnostics:SetAttribute("ContainsRealPlayers", false)

    local existing = diagnostics:FindFirstChild("CoreVirtualPlayer")
    if existing then
        existing:Destroy()
    end
    local model = Instance.new("Model")
    model.Name = "CoreVirtualPlayer"
    model:SetAttribute("IsVirtualPlayer", true)
    model:SetAttribute("CountsAsRealPlayer", false)
    model:SetAttribute("AgentKind", "MapProbe")
    model:SetAttribute("BrainState", "Boot")
    model:SetAttribute("BuildTag", core and core:GetAttribute("BuildTag") or "unknown")

    local function part(name, size, offset, color, material)
        local item = Instance.new("Part")
        item.Name = name
        item.Size = size
        item.CFrame = CFrame.new(startPosition + offset)
        item.Color = color
        item.Material = material or Enum.Material.Neon
        item.Anchored = true
        item.CanCollide = false
        item.CanTouch = false
        item.CanQuery = false
        item.Massless = true
        item.Parent = model
        return item
    end

    local body = part("HumanoidRootPart", Vector3.new(2.2, 2.4, 1.5), Vector3.new(0, 0, 0), Color3.fromRGB(67, 163, 255))
    model.PrimaryPart = body
    part("Head", Vector3.new(1.6, 1.2, 1.5), Vector3.new(0, 1.7, 0), Color3.fromRGB(111, 211, 255))
    part("EyeLeft", Vector3.new(0.25, 0.25, 0.12), Vector3.new(-0.4, 1.85, -0.77), Color3.fromRGB(255, 235, 140))
    part("EyeRight", Vector3.new(0.25, 0.25, 0.12), Vector3.new(0.4, 1.85, -0.77), Color3.fromRGB(255, 235, 140))
    part("LegLeft", Vector3.new(0.45, 0.9, 0.5), Vector3.new(-0.52, -1.55, 0), Color3.fromRGB(52, 103, 178))
    part("LegRight", Vector3.new(0.45, 0.9, 0.5), Vector3.new(0.52, -1.55, 0), Color3.fromRGB(52, 103, 178))

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MapProbeLabel"
    billboard.Size = UDim2.fromOffset(210, 46)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 220
    billboard.Parent = body
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(25, 36, 49)
    label.BackgroundTransparency = 0.12
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = "CORE MAP PROBE"
    label.TextColor3 = Color3.fromRGB(183, 229, 255)
    label.TextScaled = true
    label.Parent = billboard
    local labelCorner = Instance.new("UICorner")
    labelCorner.CornerRadius = UDim.new(0, 8)
    labelCorner.Parent = label

    model.Parent = diagnostics
    model:PivotTo(CFrame.new(startPosition))
    return model, label
end

local function moveAgent(model, label, destination)
    local from = model:GetPivot()
    local rotation = from - from.Position
    local target = CFrame.new(destination) * rotation
    local distance = (destination - from.Position).Magnitude
    local steps = math.clamp(math.ceil(distance / 16), 2, 12)
    for stepIndex = 1, steps do
        if not model.Parent then
            return false
        end
        model:PivotTo(from:Lerp(target, stepIndex / steps))
        task.wait(0.055)
    end
    if label then
        label.Text = "CORE MAP PROBE • MOVING"
    end
    return true
end

function MapProbe.StartVirtualPlayer(builder, config)
    if virtualPlayerStarted then
        return true
    end
    local activeRoot = Workspace:FindFirstChild("StealAnAnimal")
    local map = activeRoot and activeRoot:FindFirstChild("Map")
    if not activeRoot or activeRoot:GetAttribute("MapReady") ~= true or not map then
        return false
    end
    virtualPlayerStarted = true
    local startPosition = Vector3.new(0, 2, 0)
    local agent, label = createVirtualPlayer(startPosition)
    virtualPlayerModel = agent

    task.spawn(function()
        local report = {
            status = "Running",
            countsAsPlayer = false,
            virtualPlayerCount = 1,
            realPlayerCountAtStart = #Players:GetPlayers(),
            startedAt = os.time(),
            startAndReturn = false,
            routes = {},
        }
        setVirtualReport(report)
        task.wait(1.5)

        local currentPosition = startPosition
        local allFloorsPresent = true
        local allPathsSucceeded = true
        local routePlan = {}
        for _, biome in ipairs(BIOMES) do
            table.insert(routePlan, { name = biome.Name, x = biome.X, outbound = true })
        end
        table.insert(routePlan, { name = "WorldSpawn", x = 0, outbound = false })

        for routeIndex, destinationInfo in ipairs(routePlan) do
            local destination = Vector3.new(destinationInfo.x, 2, 0)
            local floorName = destinationInfo.name == "WorldSpawn" and "WorldSpawn" or destinationInfo.name .. "Ground"
            local floorPresent = destinationInfo.name == "WorldSpawn"
                and map:FindFirstChild("WorldSpawn") ~= nil
                or map:FindFirstChild(floorName) ~= nil
            local pathStatus = "NotComputed"
            local waypointCount = 0
            local pathOk = false
            local computeSuccess, path = pcall(function()
                local pathObject = PathfindingService:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    WaypointSpacing = 24,
                })
                pathObject:ComputeAsync(currentPosition, destination)
                return pathObject
            end)
            if computeSuccess and path and path.Status == Enum.PathStatus.Success then
                pathOk = true
                pathStatus = "Success"
                local waypoints = path:GetWaypoints()
                waypointCount = #waypoints
                for _, waypoint in ipairs(waypoints) do
                    if not moveAgent(agent, label, waypoint.Position) then
                        return
                    end
                end
            else
                pathStatus = computeSuccess and path and tostring(path.Status) or "ComputeError"
                allPathsSucceeded = false
                if not moveAgent(agent, label, destination) then
                    return
                end
            end
            if not floorPresent then
                allFloorsPresent = false
            end
            currentPosition = destination
            report.routes[#report.routes + 1] = {
                destination = destinationInfo.name,
                floorPresent = floorPresent,
                pathStatus = pathStatus,
                pathSucceeded = pathOk,
                waypointCount = waypointCount,
                returnedLeg = destinationInfo.outbound == false,
            }
            report.routeIndex = routeIndex
            report.currentDestination = destinationInfo.name
            report.status = "Running"
            if label then
                label.Text = "CORE MAP PROBE • " .. string.upper(destinationInfo.name)
            end
            agent:SetAttribute("RouteIndex", routeIndex)
            agent:SetAttribute("RouteDestination", destinationInfo.name)
            agent:SetAttribute("BrainState", destinationInfo.outbound and "Explore" or "Return")
            setVirtualReport(report)
            task.wait(0.25)
        end

        report.completedAt = os.time()
        report.startAndReturn = (agent:GetPivot().Position - startPosition).Magnitude <= 4
        report.allFloorsPresent = allFloorsPresent
        report.allPathsSucceeded = allPathsSucceeded
        report.status = allFloorsPresent and allPathsSucceeded and report.startAndReturn and "Passed"
            or (allFloorsPresent and "NavigationDegraded" or "MapIncomplete")
        agent:SetAttribute("BrainState", "Returned")
        agent:SetAttribute("ProbeStatus", report.status)
        if label then
            label.Text = report.status == "Passed" and "MAP SCAN COMPLETE" or "MAP SCAN NEEDS REVIEW"
        end
        setVirtualReport(report)
        if not allFloorsPresent then
            warn("[StealAnAnimal/MapProbe] Virtual player found one or more missing map floors.")
        end
        if not allPathsSucceeded then
            warn("[StealAnAnimal/MapProbe] Virtual player found at least one route without a computed path.")
        end
    end)
    return true
end

function MapProbe.CollectServerReport()
    local active = inspectRoot(Workspace:FindFirstChild("StealAnAnimal"))
    local staging = inspectRoot(Workspace:FindFirstChild("StealAnAnimal_Staging"))
    local remoteFolder = ReplicatedStorage:FindFirstChild("RoubeAnimalRemotes")
    local remoteCount = 0
    local missingRemotes = {}
    for _, name in ipairs(REMOTES) do
        local remote = remoteFolder and remoteFolder:FindFirstChild(name)
        if remote and remote:IsA("RemoteEvent") then
            remoteCount += 1
        else
            table.insert(missingRemotes, name)
        end
    end
    local status = decodeAttribute("ServiceStatusJson") or {}
    local report = {
        schemaVersion = 1,
        timestamp = os.time(),
        buildTag = core and core:GetAttribute("BuildTag") or "unknown",
        bootState = core and core:GetAttribute("BootState") or "unknown",
        worldState = core and core:GetAttribute("WorldState") or "unknown",
        lastFailure = core and core:GetAttribute("LastFailure") or "",
        activeRoot = active,
        stagingRoot = staging,
        required = { farms = 8, biomes = 6, animals = 23, guardians = 6, remotes = #REMOTES, virtualPlayers = 1 },
        remoteCount = remoteCount,
        missingRemotes = missingRemotes,
        serviceStates = status,
        latestClientProbe = decodeAttribute("LatestClientProbeJson"),
        virtualPlayer = decodeAttribute("VirtualPlayerReportJson"),
        fallbackPresent = active.present and active.role == "Fallback" or false,
    }
    report.ok = active.ready
        and active.farms == report.required.farms
        and active.biomes == report.required.biomes
        and active.animals >= report.required.animals
        and active.guardians == report.required.guardians
        and active.spawnPresent
        and remoteCount == #REMOTES
        and report.worldState == "Ready"
    report.clientHudReady = report.latestClientProbe ~= nil and report.latestClientProbe.mainHudReady == true
    report.virtualPlayerReady = report.virtualPlayer ~= nil
        and report.virtualPlayer.status == "Passed"
    if core then
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(report)
        end)
        if ok then
            core:SetAttribute("LastHealthReportJson", string.sub(encoded, 1, 9000))
            core:SetAttribute("HealthReportOk", report.ok)
        end
    end
    return report
end

function MapProbe.Init(coreFolder)
    core = coreFolder
    local diagnostics = core:FindFirstChild("Diagnostics")
    local healthRemote = diagnostics and diagnostics:FindFirstChild("RequestHealthReport")
    if not healthRemote or not healthRemote:IsA("RemoteFunction") then
        warn("[StealAnAnimal/MapProbe] RequestHealthReport RemoteFunction is missing.")
        return false
    end
    healthRemote.OnServerInvoke = function(player)
        local now = os.clock()
        if player and now - (lastRequestByUserId[player.UserId] or 0) < 1 then
            return { ok = false, error = "RATE_LIMITED" }
        end
        if player then
            lastRequestByUserId[player.UserId] = now
        end
        return MapProbe.CollectServerReport()
    end
    return true
end

return MapProbe
