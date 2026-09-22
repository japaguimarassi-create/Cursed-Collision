--!strict

local Players = game:GetService("Players")

local HitboxService = {}

export type Target = {
    player: Player?,
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
}

local FRONT_DOT_THRESHOLD = math.cos(math.rad(72))
local MAX_BOX_PARTS = 160
local MAX_RADIUS_PARTS = 220

local function getCharacterRoot(character: Model?): BasePart?
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function getTarget(model: Model): Target?
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = getCharacterRoot(model)
    if not humanoid or humanoid.Health <= 0 or not root then
        return nil
    end

    local player = Players:GetPlayerFromCharacter(model)
    if not player and model:GetAttribute("TrainingDummy") ~= true then
        return nil
    end

    return {
        player = player,
        model = model,
        humanoid = humanoid,
        root = root,
    }
end

local function isValidTarget(attacker: Player, model: Model): boolean
    if model == attacker.Character then
        return false
    end

    local target = getTarget(model)
    if not target then
        return false
    end

    return target.player ~= attacker
end

local function collectParts(attacker: Player, parts: {BasePart}, maxTargets: number?): {Target}
    local targets = {}
    local seen: {[Model]: boolean} = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] and isValidTarget(attacker, model) then
            local target = getTarget(model)
            if target then
                seen[model] = true
                table.insert(targets, target)
            end
        end
    end

    local attackerRoot = getCharacterRoot(attacker.Character)
    if attackerRoot then
        table.sort(targets, function(a, b)
            return (a.root.Position - attackerRoot.Position).Magnitude < (b.root.Position - attackerRoot.Position).Magnitude
        end)
    end

    if maxTargets and #targets > maxTargets then
        for index = #targets, maxTargets + 1, -1 do
            table.remove(targets, index)
        end
    end

    return targets
end

function HitboxService.FindTargets(
    attacker: Player,
    boxCFrame: CFrame,
    boxSize: Vector3,
    maxTargets: number?
): {Target}
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    local character = attacker.Character
    overlap.FilterDescendantsInstances = if character then {character} else {}
    overlap.MaxParts = MAX_BOX_PARTS

    local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlap)
    return collectParts(attacker, parts, maxTargets)
end

function HitboxService.NearestTargetInFront(
    attacker: Player,
    range: number,
    width: number,
    height: number
): Target?
    local character = attacker.Character
    local root = getCharacterRoot(character)
    if not root then
        return nil
    end

    range = math.max(0, tonumber(range) or 0)
    width = math.max(0, tonumber(width) or 0)
    height = math.max(0, tonumber(height) or 0)
    if range <= 0 or width <= 0 or height <= 0 then
        return nil
    end

    local center = root.Position + root.CFrame.LookVector * (range * 0.5)
    local targets = HitboxService.FindTargets(
        attacker,
        CFrame.lookAt(center, center + root.CFrame.LookVector),
        Vector3.new(width, height, range),
        nil
    )

    local best: Target?
    local bestDistance = math.huge

    for _, target in ipairs(targets) do
        local offset = target.root.Position - root.Position
        local distance = offset.Magnitude
        if distance > 0.01 and distance <= range then
            local dot = root.CFrame.LookVector:Dot(offset.Unit)
            if dot >= FRONT_DOT_THRESHOLD and distance < bestDistance then
                best = target
                bestDistance = distance
            end
        end
    end

    return best
end

function HitboxService.AreaTargets(
    attacker: Player,
    position: Vector3,
    radius: number,
    maxTargets: number?
): {Target}
    radius = math.max(0, tonumber(radius) or 0)
    if radius <= 0 then
        return {}
    end

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    local character = attacker.Character
    overlap.FilterDescendantsInstances = if character then {character} else {}
    overlap.MaxParts = MAX_RADIUS_PARTS

    local parts = workspace:GetPartBoundsInRadius(position, radius, overlap)
    local targets = collectParts(attacker, parts, maxTargets)

    table.sort(targets, function(a, b)
        return (a.root.Position - position).Magnitude < (b.root.Position - position).Magnitude
    end)

    return targets
end

return HitboxService
