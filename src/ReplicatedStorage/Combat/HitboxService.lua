local Players = game:GetService("Players")

local HitboxService = {}

local function getCharacterRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

function HitboxService.FindTargets(attacker, boxCFrame, boxSize, maxTargets)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {attacker.Character}
    overlap.MaxParts = 80

    local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlap)
    local targets = {}
    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] then
            local player = Players:GetPlayerFromCharacter(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = getCharacterRoot(model)
            if player and player ~= attacker and humanoid and humanoid.Health > 0 and root then
                seen[model] = true
                table.insert(targets, {player = player, humanoid = humanoid, root = root})
                if maxTargets and #targets >= maxTargets then
                    break
                end
            end
        end
    end

    return targets
end

function HitboxService.NearestTargetInFront(attacker, range, width, height)
    local character = attacker.Character
    local root = getCharacterRoot(character)
    if not root then
        return nil
    end

    local center = root.Position + root.CFrame.LookVector * (range * 0.5)
    local targets = HitboxService.FindTargets(
        attacker,
        CFrame.new(center, center + root.CFrame.LookVector),
        Vector3.new(width, height, range),
        1
    )

    return targets[1]
end

function HitboxService.AreaTargets(attacker, position, radius)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {attacker.Character}
    overlap.MaxParts = 120

    local parts = workspace:GetPartBoundsInRadius(position, radius, overlap)
    local targets = {}
    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] then
            local player = Players:GetPlayerFromCharacter(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = getCharacterRoot(model)
            if player and player ~= attacker and humanoid and humanoid.Health > 0 and root then
                seen[model] = true
                table.insert(targets, {player = player, humanoid = humanoid, root = root})
            end
        end
    end

    return targets
end

return HitboxService
