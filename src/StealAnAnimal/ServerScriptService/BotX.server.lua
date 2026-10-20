local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remoteFolder = ReplicatedStorage:WaitForChild("StealAnimalRemotes", 30)
local statusRemote = remoteFolder and remoteFolder:WaitForChild("BotXStatus", 30)
local AQUA = Color3.fromRGB(91, 234, 255)
local GOLD = Color3.fromRGB(255, 213, 95)
local DARK = Color3.fromRGB(27, 42, 50)

local BOT_COUNT = 3
local SNAPSHOT_SECONDS = 10
local SUMMARY_SECONDS = 30
local MAX_RETAINED_EVENTS = 400
local MAX_REMOTE_EVENTS_PER_SECOND = 30
local BOT_FOLDER_NAME = "BotX_NPCs"
local REMOTE_NAMES = {
    "RequestUpgrade",
    "RequestCollect",
    "RequestRebirth",
    "RequestDailyReward",
    "RequestRedeemCode",
    "RequestQuest",
    "RequestMapBot",
    "MapBotReport",
}
local SKIN = Color3.fromRGB(241, 194, 125)
local SHIRT = Color3.fromRGB(42, 105, 191)
local PANTS = Color3.fromRGB(31, 45, 73)
local BACON_COLORS = {
    Color3.fromRGB(125, 66, 39),
    Color3.fromRGB(157, 79, 45),
    Color3.fromRGB(184, 99, 56),
    Color3.fromRGB(105, 53, 36),
    Color3.fromRGB(205, 122, 69),
}

local active = false
local generation = 0
local sessionId = nil
local sessionStartedAt = 0
local sessionStartedAtIso = nil
local sequence = 0
local retainedEvents = {}
local eventCounts = {}
local droppedEvents = 0
local botModels = {}
local botStates = {}
local playerConnections = {}
local remoteRate = {}
local statusRequestAt = {}
local latestSummaryAt = 0
local lastSnapshotAt = 0
local runtimeWorld = nil
local botFolder = nil

local function roundNumber(value, places)
    local scale = 10 ^ (places or 1)
    return math.floor(value * scale + 0.5) / scale
end

local function safeName(player)
    return player and player.Name or "unknown"
end

local function realPlayerCount()
    return #Players:GetPlayers()
end

local function hasActivePlayer()
    return realPlayerCount() > 0
end

local function encode(value)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(value)
    end)
    return ok and result or "{}"
end

local function record(eventName, actor, details)
    if not active then
        return
    end
    sequence += 1
    local entry = {
        seq = sequence,
        session = sessionId,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        elapsed = roundNumber(os.clock() - sessionStartedAt, 2),
        event = tostring(eventName),
        actor = actor or "server",
        details = details or {},
    }
    eventCounts[entry.event] = (eventCounts[entry.event] or 0) + 1
    table.insert(retainedEvents, entry)
    if #retainedEvents > MAX_RETAINED_EVENTS then
        table.remove(retainedEvents, 1)
        droppedEvents += 1
    end
    print("[BOTX_EVENT]" .. encode(entry))
end

local function summary(reason, includeRecentEvents)
    local botList = {}
    for _, state in ipairs(botStates) do
        local root = state.Root
        table.insert(botList, {
            name = state.Name,
            mode = state.Mode,
            alive = state.Model ~= nil and state.Model.Parent ~= nil and state.Humanoid ~= nil and state.Humanoid.Health > 0,
            position = root and root.Parent and {
                x = roundNumber(root.Position.X),
                y = roundNumber(root.Position.Y),
                z = roundNumber(root.Position.Z),
            } or nil,
        })
    end
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        table.insert(playerList, {
            name = player.Name,
            userId = player.UserId,
            profileLoaded = player:GetAttribute("ProfileLoaded") == true,
            carryingAnimal = player:GetAttribute("CarryingAnimal") == true,
            coins = player:GetAttribute("Coins"),
            barnBank = player:GetAttribute("BarnBank"),
            speedLevel = player:GetAttribute("SpeedLevel"),
            effectiveWalkSpeed = player:GetAttribute("EffectiveWalkSpeed"),
            treadmillLevel = player:GetAttribute("TreadmillLevel"),
            rebirths = player:GetAttribute("Rebirths"),
            totalCaptured = player:GetAttribute("TotalCaptured"),
            totalDeposited = player:GetAttribute("TotalDeposited"),
            health = humanoid and roundNumber(humanoid.Health) or nil,
            position = root and {
                x = roundNumber(root.Position.X),
                y = roundNumber(root.Position.Y),
                z = roundNumber(root.Position.Z),
            } or nil,
        })
    end
    return {
        system = "StealAnAnimal-BotX",
        version = 1,
        session = sessionId,
        reason = reason or "running",
        startedAt = sessionStartedAtIso,
        elapsedSeconds = roundNumber(os.clock() - sessionStartedAt, 2),
        activeRealPlayers = realPlayerCount(),
        activeNpcBots = #botStates,
        players = playerList,
        bots = botList,
        eventSequence = sequence,
        retainedEventCount = #retainedEvents,
        droppedOldEvents = droppedEvents,
        eventCounts = eventCounts,
        recentEvents = includeRecentEvents and retainedEvents or nil,
    }
end

local function printSummary(reason)
    if not active then
        return
    end
    print("[BOTX_SESSION_REPORT]" .. encode(summary(reason or "periodic", reason == "final")))
end

local function pushStatus(targetPlayer, reason)
    if not statusRemote then
        return
    end
    local payload = summary(reason or "status", false)
    if targetPlayer and targetPlayer.Parent == Players then
        statusRemote:FireClient(targetPlayer, payload)
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        statusRemote:FireClient(player, payload)
    end
end

local function makeDetail(parentModel, anchor, name, size, offset, color, shape, material)
    local detail = Instance.new("Part")
    detail.Name = name
    detail.Size = size
    detail.Shape = shape or Enum.PartType.Block
    detail.CFrame = anchor.CFrame * CFrame.new(offset)
    detail.Color = color
    detail.Material = material or Enum.Material.SmoothPlastic
    detail.TopSurface = Enum.SurfaceType.Smooth
    detail.BottomSurface = Enum.SurfaceType.Smooth
    detail.Anchored = false
    detail.CanCollide = false
    detail.CanTouch = false
    detail.CanQuery = false
    detail.Massless = true
    detail.Parent = parentModel
    local weld = Instance.new("WeldConstraint")
    weld.Name = name .. "Weld"
    weld.Part0 = anchor
    weld.Part1 = detail
    weld.Parent = detail
    return detail
end

local function makeFaceAndBadge(model, head, torso)
    for _, side in ipairs({ -1, 1 }) do
        makeDetail(model, head, "BotXEyeWhite", Vector3.new(0.29, 0.29, 0.1), Vector3.new(side * 0.31, 0.02, -0.53), Color3.fromRGB(255, 255, 245), Enum.PartType.Ball)
        makeDetail(model, head, "BotXEyePupil", Vector3.new(0.13, 0.16, 0.06), Vector3.new(side * 0.31, 0.01, -0.595), Color3.fromRGB(28, 31, 39), Enum.PartType.Ball)
        makeDetail(model, head, "BotXEyeGlint", Vector3.new(0.055, 0.055, 0.025), Vector3.new(side * 0.34, 0.065, -0.632), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball)
        makeDetail(model, head, "BotXEyebrow", Vector3.new(0.36, 0.075, 0.09), Vector3.new(side * 0.31, 0.24, -0.51), Color3.fromRGB(100, 60, 37), Enum.PartType.Block)
    end
    makeDetail(model, head, "BotXMouth", Vector3.new(0.25, 0.055, 0.06), Vector3.new(0, -0.2, -0.545), Color3.fromRGB(105, 44, 49), Enum.PartType.Block)
    makeDetail(model, torso, "BotXAnalyzerBadge", Vector3.new(0.68, 0.62, 0.12), Vector3.new(0, 0.24, -0.57), AQUA, Enum.PartType.Block, Enum.Material.Neon)
    makeDetail(model, torso, "BotXBadgeCore", Vector3.new(0.32, 0.32, 0.14), Vector3.new(0, 0.24, -0.66), GOLD, Enum.PartType.Ball, Enum.Material.Neon)
    local plate = Instance.new("BillboardGui")
    plate.Name = "BotXNameplate"
    plate.Size = UDim2.fromOffset(124, 36)
    plate.StudsOffset = Vector3.new(0, 2.25, 0)
    plate.AlwaysOnTop = false
    plate.MaxDistance = 90
    plate.Adornee = head
    plate.Parent = head
    local title = Instance.new("TextLabel")
    title.Name = "Name"
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = DARK
    title.BackgroundTransparency = 0.08
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamBlack
    title.Text = model.Name .. "  •  BOTX"
    title.TextColor3 = AQUA
    title.TextStrokeTransparency = 0.55
    title.TextScaled = true
    title.Parent = plate
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 7)
    titleCorner.Parent = title
    local detail = Instance.new("TextLabel")
    detail.Name = "Status"
    detail.Position = UDim2.new(0, 0, 0, 25)
    detail.Size = UDim2.new(1, 0, 0, 17)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.GothamBold
    detail.Text = "ANALISANDO • NPC"
    detail.TextColor3 = GOLD
    detail.TextStrokeTransparency = 0.45
    detail.TextScaled = true
    detail.Parent = plate
    local highlight = Instance.new("Highlight")
    highlight.Name = "BotXRim"
    highlight.Adornee = model
    highlight.FillColor = AQUA
    highlight.FillTransparency = 0.94
    highlight.OutlineColor = AQUA
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model
end

local function makePart(model, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = name ~= "HumanoidRootPart"
    part.Parent = model
    return part
end

local function connectJoint(parent, name, part0, part1, c0, c1)
    local joint = Instance.new("Motor6D")
    joint.Name = name
    joint.Part0 = part0
    joint.Part1 = part1
    joint.C0 = c0 or part0.CFrame:ToObjectSpace(part1.CFrame)
    joint.C1 = c1 or CFrame.new()
    joint.Parent = part0
    return joint
end

local function addBaconLock(model, head, index, color, offset, size, angles)
    local lock = Instance.new("WedgePart")
    lock.Name = "BaconHairLock" .. tostring(index)
    lock.Size = size
    lock.CFrame = head.CFrame * CFrame.new(offset) * CFrame.Angles(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
    lock.Color = color
    lock.Material = Enum.Material.SmoothPlastic
    lock.Anchored = false
    lock.CanCollide = false
    lock.CanTouch = false
    lock.CanQuery = false
    lock.Massless = true
    lock.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Name = "BaconHairWeld" .. tostring(index)
    weld.Part0 = head
    weld.Part1 = lock
    weld.Parent = lock
end

local function makeBaconHair(model, head)
    addBaconLock(model, head, 1, BACON_COLORS[3], Vector3.new(-0.17, 0.43, -0.03), Vector3.new(0.92, 0.3, 0.62), Vector3.new(-8, 6, -12))
    addBaconLock(model, head, 2, BACON_COLORS[2], Vector3.new(0.34, 0.38, -0.04), Vector3.new(0.58, 0.28, 0.52), Vector3.new(7, -8, 18))
    addBaconLock(model, head, 3, BACON_COLORS[1], Vector3.new(-0.48, 0.19, -0.18), Vector3.new(0.34, 0.64, 0.35), Vector3.new(-5, 0, -24))
    addBaconLock(model, head, 4, BACON_COLORS[4], Vector3.new(-0.18, 0.17, -0.42), Vector3.new(0.33, 0.66, 0.31), Vector3.new(4, -4, -8))
    addBaconLock(model, head, 5, BACON_COLORS[5], Vector3.new(0.14, 0.26, -0.33), Vector3.new(0.31, 0.55, 0.3), Vector3.new(-6, 4, 17))
    addBaconLock(model, head, 6, BACON_COLORS[2], Vector3.new(0.46, 0.08, 0.04), Vector3.new(0.3, 0.48, 0.34), Vector3.new(8, -5, 28))
end

local function groundPosition(index)
    local world = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
    local biome = Config.Biomes[((index - 1) % #Config.Biomes) + 1]
    local ground = world and world:FindFirstChild(biome.Id .. "Ground", true)
    if ground and ground:IsA("BasePart") then
        local lane = ((index - 2) * 6)
        return ground.Position + Vector3.new(0, ground.Size.Y / 2, lane)
    end
    return Vector3.new(biome.CenterX, 0, (index - 2) * 6)
end

local function spawnPosition(index)
    local offsets = {
        Vector3.new(-10, 0, -8),
        Vector3.new(0, 0, 12),
        Vector3.new(10, 0, -8),
    }
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local ground = root.Position - Vector3.new(0, 3, 0)
            return ground + offsets[index]
        end
    end
    return groundPosition(index)
end

local function createBot(index)
    local name = "bot" .. tostring(index)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("IsBotX", true)
    model:SetAttribute("CountsAsPlayer", false)
    model:SetAttribute("BotIndex", index)
    model:SetAttribute("BotSession", sessionId)

    local rootCFrame = CFrame.new(spawnPosition(index) + Vector3.new(0, 3, 0))
    local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 1), rootCFrame, SKIN)
    root.Transparency = 1
    local torso = makePart(model, "Torso", Vector3.new(2, 2, 1), rootCFrame, SHIRT)
    local head = makePart(model, "Head", Vector3.new(2, 1, 1), rootCFrame * CFrame.new(0, 1.5, 0), SKIN)
    local leftArm = makePart(model, "Left Arm", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(-1.5, 0, 0), SKIN)
    local rightArm = makePart(model, "Right Arm", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(1.5, 0, 0), SKIN)
    local leftLeg = makePart(model, "Left Leg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(-0.5, -2, 0), PANTS)
    local rightLeg = makePart(model, "Right Leg", Vector3.new(1, 2, 1), rootCFrame * CFrame.new(0.5, -2, 0), PANTS)
    leftLeg.CanCollide = true
    rightLeg.CanCollide = true

    local rootJoint = connectJoint(root, "RootJoint", root, torso, CFrame.new(), CFrame.new())
    local neck = connectJoint(torso, "Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    local leftShoulder = connectJoint(torso, "Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
    local rightShoulder = connectJoint(torso, "Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
    local leftHip = connectJoint(torso, "Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    local rightHip = connectJoint(torso, "Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
    makeBaconHair(model, head)
    makeFaceAndBadge(model, head, torso)

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.DisplayName = name
    humanoid.NameDisplayDistance = 100
    humanoid.HealthDisplayDistance = 0
    humanoid.WalkSpeed = 12
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.Parent = model

    local animator = Instance.new("Animator")
    animator.Parent = humanoid
    model.PrimaryPart = root
    model.Parent = botFolder

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            pcall(function()
                descendant:SetNetworkOwner(nil)
            end)
        end
    end

    local state = {
        Name = name,
        Index = index,
        Model = model,
        Humanoid = humanoid,
        Root = root,
        Mode = "OBSERVING",
        NextWaypoint = 1,
        Joints = {
            Root = rootJoint,
            Neck = neck,
            LeftShoulder = leftShoulder,
            RightShoulder = rightShoulder,
            LeftHip = leftHip,
            RightHip = rightHip,
        },
        JointBases = {
            Neck = neck.C0,
            LeftShoulder = leftShoulder.C0,
            RightShoulder = rightShoulder.C0,
            LeftHip = leftHip.C0,
            RightHip = rightHip.C0,
        },
    }
    table.insert(botModels, model)
    table.insert(botStates, state)
    humanoid.Died:Connect(function()
        record("npc_died", name, { health = humanoid.Health })
        state.Mode = "DOWN"
    end)
    record("npc_spawned", name, {
        rig = "R6_humanoid",
        appearance = "custom_bacon_hair",
        countsAsPlayer = false,
        position = {
            x = roundNumber(root.Position.X),
            y = roundNumber(root.Position.Y),
            z = roundNumber(root.Position.Z),
        },
    })
    return state
end

local function sessionIsCurrent(id)
    return active and sessionId == id and hasActivePlayer()
end

local function updateBotMode(state, mode)
    state.Mode = mode
    local head = state.Model and state.Model:FindFirstChild("Head")
    local plate = head and head:FindFirstChild("BotXNameplate")
    local status = plate and plate:FindFirstChild("Status", true)
    if status then
        status.Text = mode == "OBSERVING_PLAYER" and "OBSERVANDO JOGADOR" or mode == "OBSERVING" and "OBSERVANDO" or mode == "PATROL" and "PATRULHA" or "ANALISANDO"
    end
end

local function patrol(state, id)
    if state.Index == 1 then
        while sessionIsCurrent(id) and state.Model and state.Model.Parent and state.Humanoid.Health > 0 do
            local targetRoot = nil
            local nearestDistance = math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if root and humanoid and humanoid.Health > 0 then
                    local distance = (root.Position - state.Root.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        targetRoot = root
                    end
                end
            end
            if targetRoot then
                local offset = targetRoot.CFrame.RightVector * 7 + targetRoot.CFrame.LookVector * 4
                local destination = targetRoot.Position + offset
                destination = Vector3.new(destination.X, targetRoot.Position.Y, destination.Z)
                if (state.Root.Position - destination).Magnitude > 4 then
                    updateBotMode(state, "OBSERVING_PLAYER")
                    state.Humanoid:MoveTo(destination)
                else
                    updateBotMode(state, "OBSERVING")
                end
            else
                updateBotMode(state, "OBSERVING")
            end
            task.wait(1.75)
        end
        return
    end
    local route = {}
    for _, biome in ipairs(Config.Biomes) do
        local world = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
        local ground = world and world:FindFirstChild(biome.Id .. "Ground", true)
        if ground and ground:IsA("BasePart") then
            table.insert(route, ground.Position + Vector3.new(0, ground.Size.Y / 2 + 3, (state.Index - 2) * 6))
        end
    end
    if #route == 0 then
        record("npc_route_unavailable", state.Name, { reason = "biome_ground_not_found" })
        return
    end

    while sessionIsCurrent(id) and state.Model and state.Model.Parent and state.Humanoid.Health > 0 do
        local targetIndex = ((state.NextWaypoint - 1) % #route) + 1
        local destination = route[targetIndex]
        updateBotMode(state, "PATROL")
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 10,
        })
        local pathOk = pcall(function()
            path:ComputeAsync(state.Root.Position, destination)
        end)
        local waypoints = {}
        if pathOk and path.Status == Enum.PathStatus.Success then
            waypoints = path:GetWaypoints()
        else
            updateBotMode(state, "DIRECT_FALLBACK")
            record("npc_path_fallback", state.Name, {
                targetWaypoint = targetIndex,
                pathStatus = pathOk and tostring(path.Status) or "compute_error",
            })
            waypoints = { { Position = destination, Action = Enum.PathWaypointAction.Walk } }
        end
        for _, waypoint in ipairs(waypoints) do
            if not sessionIsCurrent(id) or not state.Model.Parent or state.Humanoid.Health <= 0 then
                return
            end
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                state.Humanoid.Jump = true
            end
            state.Humanoid:MoveTo(waypoint.Position)
            local reached = state.Humanoid.MoveToFinished:Wait()
            if not reached then
                record("npc_move_timeout", state.Name, {
                    targetWaypoint = targetIndex,
                    x = roundNumber(waypoint.Position.X),
                    z = roundNumber(waypoint.Position.Z),
                })
                break
            end
        end
        state.NextWaypoint = targetIndex % #route + 1
        task.wait(1.5)
    end
end

local function startSession()
    if active or not hasActivePlayer() then
        return
    end
    active = true
    generation += 1
    sessionId = HttpService:GenerateGUID(false)
    sessionStartedAt = os.clock()
    sessionStartedAtIso = os.date("!%Y-%m-%dT%H:%M:%SZ")
    sequence = 0
    retainedEvents = {}
    eventCounts = {}
    droppedEvents = 0
    latestSummaryAt = sessionStartedAt
    lastSnapshotAt = sessionStartedAt
    runtimeWorld = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
    botFolder = Workspace:FindFirstChild(BOT_FOLDER_NAME)
    if botFolder then
        botFolder:Destroy()
    end
    botFolder = Instance.new("Folder")
    botFolder.Name = BOT_FOLDER_NAME
    botFolder:SetAttribute("CountsAsPlayers", false)
    botFolder:SetAttribute("SessionId", sessionId)
    botFolder.Parent = Workspace
    local currentGeneration = generation
    record("session_started", "server", {
        trigger = "real_player_present",
        activeRealPlayers = realPlayerCount(),
        requestedBots = BOT_COUNT,
        playerServiceContainsNpcBots = false,
    })
    for index = 1, BOT_COUNT do
        local state = createBot(index)
        task.spawn(patrol, state, currentGeneration and sessionId)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        record("player_present_at_start", safeName(player), { userId = player.UserId })
    end
    pushStatus(nil, "session_started")
end

local function stopSession(reason)
    if not active then
        return
    end
    record("session_stopped", "server", {
        reason = reason or "no_real_players",
        activeRealPlayers = realPlayerCount(),
        activeNpcBots = #botStates,
    })
    printSummary("final")
    active = false
    generation += 1
    if botFolder and botFolder.Parent then
        botFolder:Destroy()
    end
    if statusRemote then
        local stopped = {
            system = "StealAnAnimal-BotX",
            version = 1,
            reason = reason or "stopped",
            activeRealPlayers = realPlayerCount(),
            activeNpcBots = 0,
            bots = {},
            elapsedSeconds = roundNumber(os.clock() - sessionStartedAt, 2),
            eventCounts = eventCounts,
        }
        for _, player in ipairs(Players:GetPlayers()) do
            statusRemote:FireClient(player, stopped)
        end
    end
    botFolder = nil
    runtimeWorld = nil
    botModels = {}
    botStates = {}
    playerConnections = {}
    remoteRate = {}
    statusRequestAt = {}
end

local function bindCharacter(player, character)
    if active then
        record("character_spawned", safeName(player), {
            userId = player.UserId,
            character = character.Name,
        })
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(function()
            record("player_died", safeName(player), { userId = player.UserId })
        end)
    end
end

local function bindPlayer(player)
    if playerConnections[player] then
        return
    end
    local connections = {}
    playerConnections[player] = connections
    table.insert(connections, player.CharacterAdded:Connect(function(character)
        bindCharacter(player, character)
    end))
    table.insert(connections, player.CharacterRemoving:Connect(function(character)
        record("character_removing", safeName(player), { userId = player.UserId, character = character.Name })
    end))
    for _, attributeName in ipairs({
        "ProfileLoaded",
        "Coins",
        "BarnBank",
        "SpeedLevel",
        "EffectiveWalkSpeed",
        "TreadmillLevel",
        "Rebirths",
        "TotalCaptured",
        "TotalDeposited",
        "CarryingAnimal",
    }) do
        local previousValue = player:GetAttribute(attributeName)
        table.insert(connections, player:GetAttributeChangedSignal(attributeName):Connect(function()
            local currentValue = player:GetAttribute(attributeName)
            if currentValue ~= previousValue then
                record("player_state_changed", safeName(player), {
                    userId = player.UserId,
                    field = attributeName,
                    previous = previousValue,
                    current = currentValue,
                })
                previousValue = currentValue
            end
        end))
    end
end

local function onPlayerAdded(player)
    bindPlayer(player)
    task.defer(function()
        startSession()
        record("player_joined", safeName(player), { userId = player.UserId })
        if player.Character then
            bindCharacter(player, player.Character)
        end
    end)
end

local function onPlayerRemoving(player)
    record("player_leaving", safeName(player), {
        userId = player.UserId,
        profileLoaded = player:GetAttribute("ProfileLoaded") == true,
    })
    local connections = playerConnections[player]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    playerConnections[player] = nil
    task.defer(function()
        if not hasActivePlayer() then
            stopSession("last_real_player_left")
        end
    end)
end

local function connectGameplayRemotes()
    local folder = ReplicatedStorage:WaitForChild("StealAnimalRemotes", 30)
    if not folder then
        record("remote_audit_unavailable", "server", { reason = "StealAnimalRemotes folder timeout" })
        return
    end
    for _, remoteName in ipairs(REMOTE_NAMES) do
        local item = folder:FindFirstChild(remoteName)
        if item and item:IsA("RemoteEvent") then
            item.OnServerEvent:Connect(function(player, ...)
                if not active or not player or player.Parent ~= Players then
                    return
                end
                local second = os.clock()
                local perPlayer = remoteRate[player]
                if not perPlayer then
                    perPlayer = {}
                    remoteRate[player] = perPlayer
                end
                local rate = perPlayer[remoteName]
                if not rate or second - rate.Start >= 1 then
                    rate = { Start = second, Count = 0 }
                    perPlayer[remoteName] = rate
                end
                rate.Count += 1
                if rate.Count > MAX_REMOTE_EVENTS_PER_SECOND then
                    return
                end
                local argumentTypes = {}
                for index = 1, math.min(select("#", ...), 6) do
                    argumentTypes[index] = typeof(select(index, ...))
                end
                record("remote_action", safeName(player), {
                    userId = player.UserId,
                    remote = remoteName,
                    argumentCount = select("#", ...),
                    argumentTypes = argumentTypes,
                })
            end)
        else
            record("remote_missing", "server", { remote = remoteName })
        end
    end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if not active or not player or player.Parent ~= Players then
        return
    end
    record("interaction", safeName(player), {
        userId = player.UserId,
        prompt = prompt.Name,
        interactionType = prompt:GetAttribute("InteractionType"),
        parent = prompt.Parent and prompt.Parent.Name or "missing",
    })
end)

RunService.Heartbeat:Connect(function()
    if not active then
        return
    end
    local now = os.clock()
    for _, state in ipairs(botStates) do
        local humanoid = state.Humanoid
        local joints = state.Joints
        local bases = state.JointBases
        if state.Model and state.Model.Parent and humanoid and humanoid.Health > 0 and joints and bases then
            local velocity = state.Root and state.Root.Parent and state.Root.AssemblyLinearVelocity.Magnitude or 0
            local moving = humanoid.MoveDirection.Magnitude > 0.05 or velocity > 1.8
            local swing = moving and math.sin(now * 7 + state.Index * 1.8) * 0.62 or 0
            joints.LeftShoulder.C0 = bases.LeftShoulder * CFrame.Angles(swing, 0, 0)
            joints.RightShoulder.C0 = bases.RightShoulder * CFrame.Angles(-swing, 0, 0)
            joints.LeftHip.C0 = bases.LeftHip * CFrame.Angles(-swing * 0.78, 0, 0)
            joints.RightHip.C0 = bases.RightHip * CFrame.Angles(swing * 0.78, 0, 0)
            joints.Neck.C0 = bases.Neck * CFrame.Angles(0, math.sin(now * 1.35 + state.Index) * (moving and 0.045 or 0.09), 0)
        end
    end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

if statusRemote then
    statusRemote.OnServerEvent:Connect(function(player, action)
        if not player or player.Parent ~= Players or action ~= "request" then
            return
        end
        local now = os.clock()
        if now - (statusRequestAt[player] or 0) < 2 then
            return
        end
        statusRequestAt[player] = now
        pushStatus(player, active and "status_request" or "waiting_for_session")
    end)
end

task.spawn(function()
    connectGameplayRemotes()
end)

task.spawn(function()
    while true do
        task.wait(1)
        if not active then
            if hasActivePlayer() then
                startSession()
            end
        elseif not hasActivePlayer() then
            stopSession("no_real_players")
        else
            local now = os.clock()
            if now - lastSnapshotAt >= SNAPSHOT_SECONDS then
                lastSnapshotAt = now
                local snapshot = summary("state_snapshot")
                record("state_snapshot", "server", {
                    activeRealPlayers = snapshot.activeRealPlayers,
                    activeNpcBots = snapshot.activeNpcBots,
                    players = snapshot.players,
                    bots = snapshot.bots,
                })
                pushStatus(nil, "state_snapshot")
            end
            if now - latestSummaryAt >= SUMMARY_SECONDS then
                latestSummaryAt = now
                printSummary("periodic")
            end
        end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
task.defer(startSession)

game:BindToClose(function()
    if active then
        stopSession("server_shutdown")
    end
end)

print("[BOTX] Serviço de NPCs pronto; os bot1..bot3 só são criados quando existe pelo menos um jogador real.")
