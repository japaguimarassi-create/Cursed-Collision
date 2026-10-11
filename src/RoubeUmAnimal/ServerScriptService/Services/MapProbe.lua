local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local MapProbe = {}
local core
local lastRequestByUserId = {}

local BIOMES = { "Meadow", "Forest", "Wetlands", "Snow", "Savannah", "Volcano" }
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
            present = false,
            ready = false,
            role = "Absent",
            farms = 0,
            biomes = 0,
            animals = 0,
            guardians = 0,
            spawnPresent = false,
            buildErrors = {},
        }
    end
    local map = root:FindFirstChild("Map")
    local farmFolder = root:FindFirstChild("Farms")
    local animalFolder = root:FindFirstChild("Animals")
    local guardianFolder = root:FindFirstChild("Guardians")
    local biomeCount = 0
    if map then
        for _, biome in ipairs(BIOMES) do
            if map:FindFirstChild(biome .. "Ground") then
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
        required = { farms = 8, biomes = 6, animals = 23, guardians = 6, remotes = #REMOTES },
        remoteCount = remoteCount,
        missingRemotes = missingRemotes,
        serviceStates = status,
        latestClientProbe = decodeAttribute("LatestClientProbeJson"),
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
