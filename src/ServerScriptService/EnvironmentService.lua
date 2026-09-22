local Workspace = game:GetService("Workspace")

local EnvironmentService = {}

local broken = setmetatable({}, {__mode = "k"})

local function isEligible(part)
    if not part or not part:IsA("BasePart") then
        return false
    end
    if not part:GetAttribute("Destructible") then
        return false
    end
    if part:GetAttribute("Foundation") or part:GetAttribute("VisualOnly") or part:GetAttribute("TrainingOnly") then
        return false
    end
    local model = part:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return false
    end
    return true
end

local function hide(part)
    if broken[part] then
        return false
    end

    broken[part] = {
        CFrame = part.CFrame,
        Transparency = part.Transparency,
        CanCollide = part.CanCollide,
        CanTouch = part.CanTouch,
        CanQuery = part.CanQuery
    }

    part.Transparency = 1
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    return true
end

local function restore(part, snapshot)
    if not part or not part.Parent then
        broken[part] = nil
        return
    end

    part.CFrame = snapshot.CFrame
    part.Transparency = snapshot.Transparency
    part.CanCollide = snapshot.CanCollide
    part.CanTouch = snapshot.CanTouch
    part.CanQuery = snapshot.CanQuery
    broken[part] = nil
end

function EnvironmentService:Impact(origin, radius, power)
    if typeof(origin) ~= "Vector3" then
        return 0
    end

    radius = math.clamp(tonumber(radius) or 0, 0, 24)
    power = math.max(0, tonumber(power) or 0)
    if radius <= 0 or power < 20 then
        return 0
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {Workspace:FindFirstChild("CursedCollisionMap") or Workspace}

    local parts = Workspace:GetPartBoundsInRadius(origin, radius, params)
    local changed = 0

    for _, part in ipairs(parts) do
        if isEligible(part) then
            local distance = (part.Position - origin).Magnitude
            local resistance = part:GetAttribute("StructureResistance") or 30
            local effective = power * (1 - math.clamp(distance / math.max(radius, 1), 0, 1))
            if effective >= resistance and hide(part) then
                changed += 1
                local size = part.Size
                local restoreTime = tonumber(part:GetAttribute("RestoreTime")) or 12

                task.delay(restoreTime, function()
                    restore(part, broken[part])
                end)

            end
        end
    end

    return changed
end

return EnvironmentService
