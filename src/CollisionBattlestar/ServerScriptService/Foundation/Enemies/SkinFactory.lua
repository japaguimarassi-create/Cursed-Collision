--!strict

local Factory = {}

local function color(values: {number}): Color3
    return Color3.fromRGB(math.floor(values[1]), math.floor(values[2]), math.floor(values[3]))
end

local function weld(root: BasePart, other: BasePart)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = other
    weld.Parent = root
end

function Factory.Apply(model: Model, profile): boolean
    if not model or not profile then return false end
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return false end

    local primary = color(profile.PrimaryColor)
    local secondary = color(profile.SecondaryColor)
    local accent = color(profile.AccentColor)
    local materials = {Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Neon}

    local index = 0
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and child ~= root then
            index += 1
            child.CanCollide = false
            child.CanTouch = false
            child.CanQuery = true
            child.Color = if index % 3 == 1 then primary elseif index % 3 == 2 then secondary else accent
            child.Material = materials[((profile.MaterialVariant - 1) % #materials) + 1]
        end
    end

    if profile.GearVariant >= 2 then
        local gear = Instance.new("Part")
        gear.Name = "CollisionGear"
        gear.Size = Vector3.new(3.8, 0.65, 2.25)
        gear.CFrame = root.CFrame * CFrame.new(0, 2.65, 0)
        gear.Anchored = false
        gear.CanCollide = false
        gear.CanTouch = false
        gear.CanQuery = true
        gear.Color = accent
        gear.Material = Enum.Material.Metal
        gear.Parent = model
        weld(root, gear)
    end

    if profile.AccessoryVariant >= 2 then
        local accessory = Instance.new("Part")
        accessory.Name = "CollisionAccent"
        accessory.Size = Vector3.new(0.45, 2.8, 0.45)
        accessory.CFrame = root.CFrame * CFrame.new(0, 2.2, -1.2)
        accessory.Anchored = false
        accessory.CanCollide = false
        accessory.CanTouch = false
        accessory.CanQuery = true
        accessory.Color = accent
        accessory.Material = Enum.Material.Neon
        accessory.Parent = model
        weld(root, accessory)
    end

    model:SetAttribute("SkinProfileId", profile.ProfileId)
    model:SetAttribute("SkinTheme", profile.ThemeId)
    return true
end

return Factory
