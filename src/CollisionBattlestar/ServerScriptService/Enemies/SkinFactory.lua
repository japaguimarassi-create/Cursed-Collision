--!strict

local SkinFactory = {}

local function color3(value: any, fallback: Color3)
    if type(value) ~= "table" then
        return fallback
    end

    return Color3.fromRGB(
        math.clamp(tonumber(value[1]) or 255, 0, 255),
        math.clamp(tonumber(value[2]) or 255, 0, 255),
        math.clamp(tonumber(value[3]) or 255, 0, 255)
    )
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
    local tier = tonumber(profile.Tier) or 1

    core.Color = primary
    head.Color = primary:Lerp(Color3.new(1, 1, 1), 0.12)

    if profile.HeadVariant == "Visor" then
        addGear(model, "SkinVisor", Vector3.new(1.65, 0.45, 1.85), Vector3.new(0, 4.15, -0.82), accent, Enum.Material.Glass)
    elseif profile.HeadVariant == "Mask" then
        addGear(model, "SkinMask", Vector3.new(1.7, 1.05, 0.38), Vector3.new(0, 3.75, -0.95), secondary, Enum.Material.Metal)
    elseif profile.HeadVariant == "Crest" then
        addGear(model, "SkinHeadCrest", Vector3.new(0.48, 1.15, 0.3), Vector3.new(0, 4.95, 0), accent, Enum.Material.Neon)
    end

    if profile.GearVariant == "Harness" then
        addGear(model, "SkinHarness", Vector3.new(3.7, 0.45, 0.45), Vector3.new(0, 2, -1.05), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "HarnessAlt" then
        addGear(model, "SkinHarnessAlt", Vector3.new(2.2, 1.6, 0.35), Vector3.new(0, 1.8, -1.15), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "Plate" then
        addGear(model, "SkinPlateL", Vector3.new(1.1, 2.1, 0.45), Vector3.new(-2.0, 1.6, 0), secondary, Enum.Material.Metal)
        addGear(model, "SkinPlateR", Vector3.new(1.1, 2.1, 0.45), Vector3.new(2.0, 1.6, 0), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "PlateAlt" then
        addGear(model, "SkinPlateAlt", Vector3.new(3.6, 0.6, 0.5), Vector3.new(0, 2.7, 0), secondary, Enum.Material.DiamondPlate)
    elseif profile.GearVariant == "Shoulder" then
        addGear(model, "SkinShoulderL", Vector3.new(1.4, 0.8, 1.4), Vector3.new(-2.0, 2.6, 0), secondary, Enum.Material.Metal)
        addGear(model, "SkinShoulderR", Vector3.new(1.4, 0.8, 1.4), Vector3.new(2.0, 2.6, 0), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "ShoulderAlt" then
        addGear(model, "SkinShoulderAlt", Vector3.new(3.9, 0.5, 0.5), Vector3.new(0, 2.7, -0.9), secondary, Enum.Material.Metal)
    elseif profile.GearVariant == "Commander" then
        addGear(model, "SkinCommandBand", Vector3.new(3.8, 0.5, 0.5), Vector3.new(0, 3.1, -0.95), secondary, Enum.Material.Metal)
        addGear(model, "SkinCrest", Vector3.new(0.55, 1.2, 0.3), Vector3.new(0, 5.0, 0), accent, Enum.Material.Neon)
    elseif profile.GearVariant == "CommanderAlt" then
        addGear(model, "SkinCommandAlt", Vector3.new(3.5, 0.7, 0.5), Vector3.new(0, 3.4, -1.05), secondary, Enum.Material.Metal)
        addGear(model, "SkinCrestAlt", Vector3.new(0.75, 0.75, 0.45), Vector3.new(0, 5.0, 0), accent, Enum.Material.Neon)
    end

    if profile.AccessoryVariant == "Strap" then
        addGear(model, "SkinStrap", Vector3.new(0.35, 2.8, 0.35), Vector3.new(-1.1, 2.2, -1.15), accent, Enum.Material.Fabric)
    elseif profile.AccessoryVariant == "Utility" then
        addGear(model, "SkinUtility", Vector3.new(0.7, 1.0, 0.7), Vector3.new(1.55, 1.0, -1.0), secondary, Enum.Material.Metal)
    elseif profile.AccessoryVariant == "Cloak" then
        addGear(model, "SkinCloak", Vector3.new(2.8, 2.9, 0.18), Vector3.new(0, 2.2, 1.0), secondary, Enum.Material.Fabric)
    elseif profile.AccessoryVariant == "Crown" then
        addGear(model, "SkinCrown", Vector3.new(1.5, 0.3, 1.5), Vector3.new(0, 5.0, 0), accent, Enum.Material.Neon)
    end

    addGear(
        model,
        "SkinAccent",
        Vector3.new(math.max(0.5, 2.8 - tier * 0.2), 0.3, 1.9),
        Vector3.new(0, 1.2 + tier * 0.15, -1.05),
        tier == 4 and Color3.fromRGB(255, 45, 55) or accent,
        Enum.Material.Neon
    )

    model:SetAttribute("CBS_SkinProfileId", profile.ProfileId)
    model:SetAttribute("CBS_SkinThemeId", profile.ThemeId)

    return true
end

return SkinFactory
