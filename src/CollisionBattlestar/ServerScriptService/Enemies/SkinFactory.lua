--!strict

local SkinFactory = {}

local function color3(value: any, fallback: Color3)
    if type(value) ~= "table" then
        return fallback
    end

    local r = math.clamp(tonumber(value[1]) or 255, 0, 255)
    local g = math.clamp(tonumber(value[2]) or 255, 0, 255)
    local b = math.clamp(tonumber(value[3]) or 255, 0, 255)

    return Color3.fromRGB(r, g, b)
end

local function addGear(model: Model, name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return nil
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = root.CFrame * CFrame.new(offset)
    part.Color = color
    part.Material = material
    part.CanCollide = false
    part.CanTouch = false
    part.Massless = true
    part.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = part
    weld.Parent = root

    return part
end

function SkinFactory.Apply(model: Model, profile)
    if type(profile) ~= "table" or type(profile.ProfileId) ~= "string" then
        return false
    end

    local core = model:FindFirstChild("Core")
    local head = model:FindFirstChild("Head")

    if not core or not head or not core:IsA("BasePart") or not head:IsA("BasePart") then
        return false
    end

    local primary = color3(profile.PrimaryColor, Color3.fromRGB(100, 100, 100))
    local secondary = color3(profile.SecondaryColor, Color3.fromRGB(50, 50, 50))
    local accent = color3(profile.AccentColor, Color3.fromRGB(220, 220, 220))

    core.Color = primary
    head.Color = primary:Lerp(Color3.new(1, 1, 1), 0.12)

    local tier = tonumber(profile.Tier) or 1

    if profile.GearVariant == "Harness" then
        addGear(model, "SkinHarness", Vector3.new(3.7, 0.45, 0.45), Vector3.new(0, 2, -1.05), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "Plate" then
        addGear(model, "SkinPlateL", Vector3.new(1.1, 2.1, 0.45), Vector3.new(-2.0, 1.6, 0), secondary, Enum.Material.Metal)
        addGear(model, "SkinPlateR", Vector3.new(1.1, 2.1, 0.45), Vector3.new(2.0, 1.6, 0), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "Shoulder" then
        addGear(model, "SkinShoulderL", Vector3.new(1.4, 0.8, 1.4), Vector3.new(-2.0, 2.6, 0), secondary, Enum.Material.Metal)
        addGear(model, "SkinShoulderR", Vector3.new(1.4, 0.8, 1.4), Vector3.new(2.0, 2.6, 0), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "Commander" then
        addGear(model, "SkinCommandBand", Vector3.new(3.8, 0.5, 0.5), Vector3.new(0, 3.1, -0.95), secondary, Enum.Material.Metal)
        addGear(model, "SkinCrest", Vector3.new(0.55, 1.2, 0.3), Vector3.new(0, 5.0, 0), accent, Enum.Material.Neon)
    end

    local accentPart = addGear(
        model,
        "SkinAccent",
        Vector3.new(math.max(0.5, 2.8 - tier * 0.2), 0.3, 1.9),
        Vector3.new(0, 1.2 + tier * 0.15, -1.05),
        profile.Tier == 4 and Color3.fromRGB(255, 45, 55) or accent,
        Enum.Material.Neon
    )

    if profile.Tier == 4 then
        local highlight = model:FindFirstChild("EliteHighlight")
        if highlight and highlight:IsA("Highlight") then
            highlight.FillColor = Color3.fromRGB(255, 35, 45)
            highlight.OutlineColor = Color3.fromRGB(255, 180, 180)
        end
        core.Color = primary:Lerp(Color3.fromRGB(255, 40, 40), 0.18)
        head.Color = core.Color:Lerp(Color3.new(1, 1, 1), 0.12)
    end

    model:SetAttribute("CBS_SkinProfileId", profile.ProfileId)
    model:SetAttribute("CBS_SkinThemeId", profile.ThemeId)

    return accentPart ~= nil
end

return SkinFactory
