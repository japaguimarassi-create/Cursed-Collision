--!strict

local Players = game:GetService("Players")

local HitboxService = {}

type Target = {
    player: Player?,
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    distance: number
}

local function getRoot(model: Model): BasePart?
    local root = model:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function getHumanoid(model: Model): Humanoid?
    return model:FindFirstChildOfClass("Humanoid")
end

local function getOwner(model: Model): Player?
    return Players:GetPlayerFromCharacter(model)
end

local function collect(attacker: Player, parts: {BasePart}, origin: Vector3): {Target}
    local targets: {Target} = {}
    local seen: {[Model]: boolean} = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")

        if model and not seen[model] then
            local humanoid = getHumanoid(model)
            local root = getRoot(model)

            if humanoid and root and humanoid.Health > 0 then
                seen[model] = true

                table.insert(targets, {
                    player = getOwner(model),
                    model = model,
                    humanoid = humanoid,
                    root = root,
                    distance = (root.Position - origin).Magnitude
                })
            end
        end
    end

    table.sort(targets, function(a: Target, b: Target)
        return a.distance < b.distance
    end)

    return targets
end

function HitboxService:TargetsInBox(
    attacker: Player,
    boxCFrame: CFrame,
    boxSize: Vector3,
    maxParts: number?
): {Target}
    local exclude: {Instance} = {}

    if attacker.Character then
        table.insert(exclude, attacker.Character)
    end

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = exclude
    overlap.MaxParts = math.max(1, math.floor(maxParts or 64))
    overlap.RespectCanCollide = false

    return collect(
        attacker,
        workspace:GetPartBoundsInBox(
            boxCFrame,
            boxSize,
            overlap
        ),
        boxCFrame.Position
    )
end

function HitboxService:TargetsInRadius(
    attacker: Player,
    radius: number
): {Target}
    local character = attacker.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return {}
    end

    local exclude: {Instance} = {character}
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = exclude
    overlap.MaxParts = 96
    overlap.RespectCanCollide = false

    return collect(
        attacker,
        workspace:GetPartBoundsInRadius(
            root.Position,
            math.clamp(radius, 1, 64),
            overlap
        ),
        root.Position
    )
end

function HitboxService:NearestTargetInFront(
    attacker: Player,
    range: number,
    width: number,
    height: number
): Target?
    local character = attacker.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return nil
    end

    local center = root.Position + root.CFrame.LookVector * (range * 0.5)

    local targets = self:TargetsInBox(
        attacker,
        CFrame.lookAt(center, center + root.CFrame.LookVector),
        Vector3.new(width, height, range),
        32
    )

    return targets[1]
end

return HitboxService