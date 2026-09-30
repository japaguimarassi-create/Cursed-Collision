--!strict

local PathfindingService = game:GetService("PathfindingService")

local Navigation = {}

function Navigation.NextPoint(origin: Vector3, target: Vector3): Vector3?
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 5,
    })

    local ok = pcall(function()
        path:ComputeAsync(origin, target)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        return target
    end

    local waypoints = path:GetWaypoints()
    if #waypoints >= 2 then
        return waypoints[2].Position
    end
    return target
end

return Navigation