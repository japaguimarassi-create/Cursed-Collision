--!strict

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local Factory = {}

local function weld(root: BasePart, other: BasePart)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = root
    constraint.Part1 = other
    constraint.Parent = root
end

local function bodyPart(model: Model, root: BasePart, name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material): BasePart
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = root.CFrame * CFrame.new(offset)
    part.Color = color
    part.Material = material
    part.Anchored = false
    part.CanCollide = true
    part.CanTouch = false
    part.CanQuery = true
    part.Parent = model
    weld(root, part)
    return part
end

function Factory.Create(tier: string, spawnCFrame: CFrame): Model
    local stats = Constants.Enemies[tier]
    assert(stats, "Unknown enemy tier: " .. tier)

    local model = Instance.new("Model")
    model.Name = tier .. "_Enemy"
    model:SetAttribute("Enemy", true)
    model:SetAttribute("Tier", tier)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2.4, 3.4, 2.4)
    root.CFrame = spawnCFrame
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = false
    root.CanTouch = false
    root.Parent = model
    model.PrimaryPart = root

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.MaxHealth = stats.MaxHealth
    humanoid.Health = stats.MaxHealth
    humanoid.WalkSpeed = stats.WalkSpeed
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    local baseColor = if tier == "Elite" then Color3.fromRGB(194, 44, 58)
        elseif tier == "Tier3" then Color3.fromRGB(140, 70, 205)
        elseif tier == "Tier2" then Color3.fromRGB(65, 150, 220)
        else Color3.fromRGB(92, 106, 125)

    bodyPart(model, root, "Torso", Vector3.new(3.2, 3.2, 2), Vector3.new(0, 1.8, 0), baseColor, Enum.Material.Metal)
    local head = bodyPart(model, root, "Head", Vector3.new(2.3, 2.3, 2.3), Vector3.new(0, 4.4, 0), baseColor:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.SmoothPlastic)
    bodyPart(model, root, "LeftArm", Vector3.new(1, 3, 1), Vector3.new(-2.1, 1.8, 0), baseColor, Enum.Material.Metal)
    bodyPart(model, root, "RightArm", Vector3.new(1, 3, 1), Vector3.new(2.1, 1.8, 0), baseColor, Enum.Material.Metal)
    bodyPart(model, root, "LeftLeg", Vector3.new(1.2, 3.2, 1.2), Vector3.new(-0.8, -1.8, 0), baseColor, Enum.Material.Metal)
    bodyPart(model, root, "RightLeg", Vector3.new(1.2, 3.2, 1.2), Vector3.new(0.8, -1.8, 0), baseColor, Enum.Material.Metal)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EnemyLabel"
    billboard.Size = UDim2.fromOffset(100, 26)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.7, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = tier == "Elite" and "ELITE" or tier
    label.TextColor3 = tier == "Elite" and Color3.fromRGB(255, 82, 92) or Color3.fromRGB(225, 232, 242)
    label.TextStrokeTransparency = 0.2
    label.Parent = billboard

    if tier == "Elite" then
        local highlight = Instance.new("Highlight")
        highlight.Name = "EliteHighlight"
        highlight.FillColor = Color3.fromRGB(255, 48, 64)
        highlight.FillTransparency = 0.65
        highlight.OutlineColor = Color3.fromRGB(255, 220, 220)
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = model
    end

    model.Parent = workspace:WaitForChild("Enemies")
    model:PivotTo(spawnCFrame)
    return model
end

return Factory