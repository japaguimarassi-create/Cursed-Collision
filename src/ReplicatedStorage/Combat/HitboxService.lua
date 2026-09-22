local Players = game:GetService("Players")

local HitboxService = {}

local function getCharacterRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function isValidTarget(attacker, model)
    if not model or model == attacker.Character then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = getCharacterRoot(model)
    if not humanoid or humanoid.Health <= 0 or not root then
        return false
    end

    local player = Players:GetPlayerFromCharacter(model)
    if player then
        return player ~= attacker
    end

    return model:GetAttribute("TrainingDummy") == true
end

function HitboxService.FindTargets(attacker, boxCFrame, boxSize, maxTargets)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {attacker.Character}
    overlap.MaxParts = 120

    local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlap)
    local targets = {}
    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] and isValidTarget(attacker, model) then
            local player = Players:GetPlayerFromCharacter(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = getCharacterRoot(model)
            seen[model] = true
            table.insert(targets, {
                player = player,
                model = model,
                humanoid = humanoid,
                root = root
            })
            if maxTargets and #targets >= maxTargets then
                break
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
    overlap.MaxParts = 180

    local parts = workspace:GetPartBoundsInRadius(position, radius, overlap)
    local targets = {}
    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] and isValidTarget(attacker, model) then
            local player = Players:GetPlayerFromCharacter(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = getCharacterRoot(model)
            seen[model] = true
            table.insert(targets, {
                player = player,
                model = model,
                humanoid = humanoid,
                root = root
            })
        end
    end

    return targets
end

return HitboxService
