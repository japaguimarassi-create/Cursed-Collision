local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local AnimalBrain = {}
local wildlifeRegistry = setmetatable({}, { __mode = "k" })
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

function AnimalBrain.StartGuardians(builder, animalService, notify)
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


local function wildlifeTarget(model, homePosition, homeRadius)
    local currentPosition = model:GetPivot().Position
    local closestRoot
    local closestDistance = 7
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoid.Health > 0 and playerRoot then
            local delta = Vector3.new(currentPosition.X - playerRoot.Position.X, 0, currentPosition.Z - playerRoot.Position.Z)
            local distance = delta.Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestRoot = playerRoot
            end
        end
    end

    local target
    local state
    if closestRoot then
        local away = Vector3.new(currentPosition.X - closestRoot.Position.X, 0, currentPosition.Z - closestRoot.Position.Z)
        if away.Magnitude < 0.01 then
            away = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
        end
        target = currentPosition + away.Unit * math.random(3, 6)
        state = "Flee"
    else
        local angle = math.random() * math.pi * 2
        local distance = math.sqrt(math.random()) * homeRadius
        target = homePosition + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
        state = "Wander"
    end

    local offset = Vector3.new(target.X - homePosition.X, 0, target.Z - homePosition.Z)
    if offset.Magnitude > homeRadius then
        local bounded = offset.Unit * homeRadius
        target = Vector3.new(homePosition.X + bounded.X, currentPosition.Y, homePosition.Z + bounded.Z)
    end
    return Vector3.new(target.X, currentPosition.Y, target.Z), state
end

function AnimalBrain.StartWildlife(builder, config)
    local animals = builder.GetAnimalsFolder()
    if not animals or not animals.Parent then
        error("Animal folder is not ready; wildlife brain cannot start")
    end

    local function attach(model)
        if not model:IsA("Model") or model:GetAttribute("AnimalId") == nil or wildlifeRegistry[model] then
            return
        end
        if model:GetAttribute("IsBarnDisplay") == true then
            return
        end
        wildlifeRegistry[model] = true
        task.spawn(function()
            local home = model:GetAttribute("HomePosition")
            if typeof(home) ~= "Vector3" then
                home = model:GetPivot().Position
                model:SetAttribute("HomePosition", home)
            end
            local radius = math.clamp(tonumber(model:GetAttribute("HomeRadius")) or 10, 4, 18)
            model:SetAttribute("BrainState", "Idle")
            while model.Parent == animals and wildlifeRegistry[model] do
                local ok, result = pcall(function()
                    local current = model:GetPivot()
                    local targetPosition, nextState = wildlifeTarget(model, home, radius)
                    model:SetAttribute("BrainState", nextState)
                    local target = CFrame.new(targetPosition) * (current - current.Position)
                    if (targetPosition - current.Position).Magnitude < 0.4 then
                        return true
                    end
                    local steps = nextState == "Flee" and 7 or 11
                    for stepIndex = 1, steps do
                        if model.Parent ~= animals or not wildlifeRegistry[model] then
                            return false
                        end
                        model:PivotTo(current:Lerp(target, stepIndex / steps))
                        task.wait(nextState == "Flee" and 0.055 or 0.075)
                    end
                    model:SetAttribute("BrainState", "Idle")
                    return true
                end)
                if not ok then
                    warn("[StealAnAnimal/AnimalBrain] Wildlife update failed for " .. model.Name .. ": " .. tostring(result))
                    model:SetAttribute("BrainState", "Disabled")
                    task.wait(2)
                else
                    task.wait(math.random(12, 28) / 10)
                end
            end
            wildlifeRegistry[model] = nil
        end)
    end

    for _, model in ipairs(animals:GetChildren()) do
        attach(model)
    end
    animals.ChildAdded:Connect(attach)
    animals.ChildRemoved:Connect(function(model)
        wildlifeRegistry[model] = nil
    end)
    return true
end

return AnimalBrain
