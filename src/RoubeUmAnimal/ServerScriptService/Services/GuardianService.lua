local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GuardianService = {}
local startedGuardians = {}
local lastCaught = {}

local function characterState(player)
    local character = player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then
        return nil, nil, nil
    end

    return character, humanoid, root
end

local function canSee(guardian, character, origin, destination)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { guardian }
    params.IgnoreWater = true

    local success, result = pcall(function()
        return workspace:Raycast(origin, destination - origin, params)
    end)

    if not success then
        return false
    end

    return result == nil or result.Instance:IsDescendantOf(character)
end

local function targetFor(guardian, root, range)
    local closestPlayer
    local closestRoot
    local closestDistance = range

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("CarryingAnimal") then
            local character, humanoid, targetRoot = characterState(player)

            if character and humanoid and targetRoot then
                local distance = (targetRoot.Position - root.Position).Magnitude

                if distance < closestDistance
                    and canSee(guardian, character, root.Position, targetRoot.Position) then
                    closestPlayer = player
                    closestRoot = targetRoot
                    closestDistance = distance
                end
            end
        end
    end

    return closestPlayer, closestRoot, closestDistance
end

local function moveToward(humanoid, root, destination)
    local success, path = pcall(function()
        local result = PathfindingService:CreatePath({
            AgentRadius = Config.Guardian.AgentRadius,
            AgentHeight = Config.Guardian.AgentHeight,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 5,
        })

        result:ComputeAsync(root.Position, destination)
        return result
    end)

    if success and path and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local waypoint = waypoints[math.min(2, #waypoints)]

        if waypoint then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)
            return
        end
    end

    humanoid:MoveTo(destination)
end

local function randomPatrolPoint(origin, radius)
    local angle = math.random() * math.pi * 2
    local distance = math.sqrt(math.random()) * radius

    return origin + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

local function runGuardian(guardian, onCaught, notify)
    local humanoid = guardian:FindFirstChildOfClass("Humanoid")
    local root = guardian:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        warn("StealAnAnimal: guardian creature has no humanoid rig: " .. guardian:GetFullName())
        return
    end

    local origin = root.Position
    local range = math.clamp(guardian:GetAttribute("VisionRange") or Config.Guardian.VisionRange, 10, 180)
    local patrolRadius = math.clamp(guardian:GetAttribute("PatrolRadius") or Config.Guardian.PatrolRadius, 5, 200)
    local patrolSpeed = math.clamp(guardian:GetAttribute("PatrolSpeed") or Config.Guardian.PatrolSpeed, 4, 35)
    local chaseSpeed = math.clamp(guardian:GetAttribute("ChaseSpeed") or Config.Guardian.ChaseSpeed, patrolSpeed, 50)
    local catchDistance = math.clamp(guardian:GetAttribute("CatchDistance") or Config.Guardian.CatchDistance, 2, 12)

    local targetPlayer
    local lastTargetPosition
    local lastRepath = 0
    local patrolGoal
    local nextPatrol = 0

    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    while guardian.Parent and humanoid.Health > 0 do
        local now = os.clock()
        local player, targetRoot, distance = targetFor(guardian, root, range)

        if player and targetRoot then
            local targetChanged = targetPlayer ~= player
            targetPlayer = player
            humanoid.WalkSpeed = chaseSpeed

            if distance <= catchDistance and player:GetAttribute("CarryingAnimal") then
                local last = lastCaught[player.UserId] or 0

                if now - last >= 3 then
                    lastCaught[player.UserId] = now
                    onCaught(player, guardian)
                end
            end

            local targetMoved = not lastTargetPosition
                or (targetRoot.Position - lastTargetPosition).Magnitude >= Config.Guardian.RepathTargetMovement

            if now - lastRepath >= Config.Guardian.RepathInterval
                or targetMoved
                or targetChanged then
                moveToward(humanoid, root, targetRoot.Position)
                lastTargetPosition = targetRoot.Position
                lastRepath = now
            end
        else
            targetPlayer = nil
            lastTargetPosition = nil
            humanoid.WalkSpeed = patrolSpeed

            if not patrolGoal
                or (root.Position - patrolGoal).Magnitude < 5
                or now >= nextPatrol then
                patrolGoal = randomPatrolPoint(origin, patrolRadius)
                nextPatrol = now + math.random(5, 9)
            end

            if now - lastRepath >= Config.Guardian.RepathInterval then
                moveToward(humanoid, root, patrolGoal)
                lastRepath = now
            end
        end

        task.wait(Config.Guardian.ThinkInterval)
    end
end

function GuardianService.Start(builder, animalService, notify)
    local folder = builder.GetGuardiansFolder()

    local function addGuardian(guardian)
        if not guardian:IsA("Model") or startedGuardians[guardian] then
            return
        end

        startedGuardians[guardian] = true

        task.spawn(function()
            runGuardian(guardian, function(player)
                animalService.Lose(player, "The giant guardian caught you. Your carried animal escaped.")
            end, notify)
        end)
    end

    for _, guardian in ipairs(folder:GetChildren()) do
        addGuardian(guardian)
    end

    folder.ChildAdded:Connect(addGuardian)
end

return GuardianService
