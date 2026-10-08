--!strict

local EnemyFactory = {}

local serial = 0

local SkinFactory = require(script.Parent.SkinFactory)

local TierColors = {
    [1] = Color3.fromRGB(95, 110, 130),
    [2] = Color3.fromRGB(120, 95, 65),
    [3] = Color3.fromRGB(85, 70, 135),
    [4] = Color3.fromRGB(235, 45, 55),
}

local function makePart(parent: Model, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, transparency: number?)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Massless = false
    part.CastShadow = false
    part.Parent = parent
    return part
end

function EnemyFactory.Create(definition, spawnCFrame: CFrame, wave: number, skinProfile)
    local model = Instance.new("Model")
    serial += 1
    model.Name = "Enemy_" .. definition.Id .. "_" .. tostring(serial)
    model:SetAttribute("CBS_Enemy", true)
    model:SetAttribute("CBS_EnemyId", definition.Id)
    model:SetAttribute("CBS_Elite", definition.IsElite)
    model:SetAttribute("CBS_Wave", wave)
    model:SetAttribute("CBS_Reward", definition.Reward)
    model:SetAttribute("CBS_KnockbackResistance", definition.KnockbackResistance)

    local color = TierColors[definition.Tier] or TierColors[1]

    local root = makePart(
        model,
        "HumanoidRootPart",
        Vector3.new(2, 2, 1),
        spawnCFrame,
        Color3.new(1, 1, 1),
        Enum.Material.SmoothPlastic,
        1
    )
    root.CanCollide = false

    local body = makePart(
        model,
        "Core",
        Vector3.new(3.2, 4, 2),
        spawnCFrame * CFrame.new(0, 1, 0),
        color,
        Enum.Material.Metal
    )

    local head = makePart(
        model,
        "Head",
        Vector3.new(2.4, 2.4, 2.4),
        spawnCFrame * CFrame.new(0, 4, 0),
        color:Lerp(Color3.new(1, 1, 1), 0.15),
        Enum.Material.Metal
    )

    local weldBody = Instance.new("WeldConstraint")
    weldBody.Part0 = root
    weldBody.Part1 = body
    weldBody.Parent = root

    local weldHead = Instance.new("WeldConstraint")
    weldHead.Part0 = root
    weldHead.Part1 = head
    weldHead.Parent = root

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = definition.MaxHealth + math.max(0, wave - 1) * (definition.MaxHealth * 0.08)
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = definition.Speed
    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    humanoid.RequiresNeck = false
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = workspace:FindFirstChild("CollisionBattlestarWorld") or workspace

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant:SetNetworkOwner(nil)
        end
    end

    if definition.IsElite then
        local highlight = Instance.new("Highlight")
        highlight.Name = "EliteHighlight"
        highlight.FillColor = Color3.fromRGB(255, 35, 45)
        highlight.OutlineColor = Color3.fromRGB(255, 170, 170)
        highlight.FillTransparency = 0.45
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
    end

    if skinProfile then
        SkinFactory.Apply(model, skinProfile)
    end

    return model, humanoid, root
end

return EnemyFactory
