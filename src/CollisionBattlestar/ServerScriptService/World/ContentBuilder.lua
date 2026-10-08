--!strict

local ContentBuilder = {}

local function part(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    transparency: number?
)
    local value = Instance.new("Part")
    value.Name = name
    value.Size = size
    value.CFrame = cframe
    value.Anchored = true
    value.Material = material
    value.Color = color
    value.Transparency = transparency or 0
    value.TopSurface = Enum.SurfaceType.Smooth
    value.BottomSurface = Enum.SurfaceType.Smooth
    value.Parent = parent
    return value
end

local function label(parent: Instance, name: string, title: string)
    local gui = Instance.new("BillboardGui")
    gui.Name = name
    gui.Size = UDim2.fromOffset(240, 54)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 150
    gui.Parent = parent

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(12, 15, 21)
    text.BackgroundTransparency = 0.12
    text.Text = title
    text.TextColor3 = Color3.fromRGB(235, 240, 250)
    text.TextStrokeTransparency = 0.35
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = text
end

local function station(parent: Instance, name: string, position: Vector3, accent: Color3, title: string)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    part(model, "Base", Vector3.new(26, 2, 20), CFrame.new(position + Vector3.new(0, 1, 0)), Color3.fromRGB(43, 47, 58), Enum.Material.Concrete)
    part(model, "Pad", Vector3.new(12, 0.35, 12), CFrame.new(position + Vector3.new(0, 2.18, 0)), accent, Enum.Material.Neon)
    part(model, "Core", Vector3.new(4, 7, 4), CFrame.new(position + Vector3.new(0, 5.5, 0)), Color3.fromRGB(28, 32, 41), Enum.Material.Metal)

    local orb = part(
        model,
        "Orb",
        Vector3.new(2.4, 2.4, 2.4),
        CFrame.new(position + Vector3.new(0, 9, 0)),
        accent,
        Enum.Material.Neon
    )
    orb.Shape = Enum.PartType.Ball
    label(orb, "StationLabel", title)

    for side, x in ipairs({-9, 9}) do
        part(
            model,
            "Pillar" .. tostring(side),
            Vector3.new(1.2, 5, 1.2),
            CFrame.new(position + Vector3.new(x, 4.5, 0)),
            Color3.fromRGB(30, 34, 43),
            Enum.Material.Metal
        )
    end

    return model
end

function ContentBuilder.Build(world: Folder)
    local content = Instance.new("Folder")
    content.Name = "Landmarks"
    content.Parent = world

    part(
        content,
        "NorthPath",
        Vector3.new(16, 0.3, 62),
        CFrame.new(0, 0.22, -31),
        Color3.fromRGB(39, 44, 56),
        Enum.Material.Concrete
    )

    part(
        content,
        "SouthPath",
        Vector3.new(16, 0.3, 62),
        CFrame.new(0, 0.22, 31),
        Color3.fromRGB(39, 44, 56),
        Enum.Material.Concrete
    )

    station(
        content,
        "TrainingDeck",
        Vector3.new(-48, 0, 34),
        Color3.fromRGB(74, 160, 220),
        "TRAINING"
    )

    station(
        content,
        "MarketDeck",
        Vector3.new(48, 0, 34),
        Color3.fromRGB(120, 200, 145),
        "MARKET"
    )

    station(
        content,
        "RiftGate",
        Vector3.new(0, 0, -48),
        Color3.fromRGB(205, 70, 150),
        "RIFT GATE"
    )

    for angleIndex = 0, 7 do
        local angle = angleIndex * math.pi / 4
        local radius = 66
        local pos = Vector3.new(math.cos(angle) * radius, 1.5, math.sin(angle) * radius)

        local beacon = part(
            content,
            "Beacon" .. tostring(angleIndex + 1),
            Vector3.new(1.5, 3, 1.5),
            CFrame.new(pos),
            Color3.fromRGB(70, 130, 180),
            Enum.Material.Neon
        )

        beacon.Shape = Enum.PartType.Cylinder
        beacon.CanCollide = false
    end

    return content
end

return ContentBuilder
