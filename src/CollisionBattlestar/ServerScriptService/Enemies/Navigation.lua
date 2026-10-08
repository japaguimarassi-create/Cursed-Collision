--!strict

local PathfindingService = game:GetService("PathfindingService")

local Navigation = {}
Navigation.__index = Navigation

function Navigation.new(root: BasePart)
    return setmetatable({
        root = root,
        path = nil,
        waypoints = nil,
        waypointIndex = 1,
        nextComputeAt = 0,
        lastTargetPosition = nil,
    }, Navigation)
end

function Navigation:NeedsRecompute(targetPosition: Vector3, now: number)
    if not self.waypoints or #self.waypoints == 0 then
        return true
    end

    if now >= self.nextComputeAt then
        return true
    end

    if not self.lastTargetPosition then
        return true
    end

    return (targetPosition - self.lastTargetPosition).Magnitude >= 8
end

function Navigation:Compute(targetPosition: Vector3, now: number)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2.5,
        AgentHeight = 6,
        AgentCanJump = false,
        AgentCanClimb = false,
        WaypointSpacing = 5,
    })

    local ok = pcall(function()
        path:ComputeAsync(self.root.Position, targetPosition)
    end)

    self.nextComputeAt = now + 1.25
    self.lastTargetPosition = targetPosition

    if not ok or path.Status ~= Enum.PathStatus.Success then
        self.path = nil
        self.waypoints = nil
        self.waypointIndex = 1
        return false
    end

    self.path = path
    self.waypoints = path:GetWaypoints()
    self.waypointIndex = 1

    return #self.waypoints > 0
end

function Navigation:GetNextPosition(targetPosition: Vector3, now: number)
    if self:NeedsRecompute(targetPosition, now) then
        self:Compute(targetPosition, now)
    end

    local waypoints = self.waypoints
    if not waypoints or #waypoints == 0 then
        return targetPosition
    end

    while self.waypointIndex <= #waypoints do
        local waypoint = waypoints[self.waypointIndex]
        local distance = (waypoint.Position - self.root.Position).Magnitude

        if distance <= 3 then
            self.waypointIndex += 1
        else
            return waypoint.Position
        end
    end

    return targetPosition
end

function Navigation:Destroy()
    self.path = nil
    self.waypoints = nil
end

return Navigation
