--!strict

local ContentBuilder = {}

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material)
    local value = Instance.new("Part")
    value.Name = name
    value.Size = size
    value.CFrame = cframe
    value.Anchored = true
    value.Material = material
    value.Color = color
    value.TopSurface = Enum.SurfaceType.Smooth
    value.BottomSurface = Enum.SurfaceType.Smooth
    value.Parent = parent
    return value
end

local function sign(parent: Instance, name: string, textValue: string, position: Vector3)
    local anchor = part(
        parent,
        name .. "_Anchor",
        Vector3.new(0.5, 8, 0.5),
        CFrame.new(position + Vector3.new(0, 4, 0)),
        Color3.fromRGB(42, 46, 58),
        Enum.Material.Metal
    )

    local gui = Instance.new("BillboardGui")
    gui.Name = name
    gui.Size = UDim2.fromOffset(220, 52)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 130
    gui.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.25
    label.BackgroundColor3 = Color3.fromRGB(14, 17, 23)
    label.Text = textValue
    label.TextColor3 = Color3.fromRGB(240, 242, 248)
    label.TextStrokeTransparency = 0.4
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
end

function ContentBuilder.Build(world: Folder)
    local content = Instance.new("Folder")
    content.Name = "Landmarks"
    content.Parent = world

    local road = part(
        content,
        "RiftRoad",
        Vector3.new(18, 0.4, 130),
        CFrame.new(0, 0.25, 82),
        Color3.fromRGB(38, 42, 52),
        Enum.Material.Asphalt
    )
    road.CanCollide = true

    for z = 28, 136, 18 do
        local marker = part(
            content,
            "RoadMarker_" .. tostring(z),
            Vector3.new(2, 0.15, 8),
            CFrame.new(0, 0.5, z),
            Color3.fromRGB(100, 105, 120),
            Enum.Material.Neon
        )
        marker.CanCollide = false
    end

    local gate = Instance.new("Model")
    gate.Name = "RiftGate"
    gate.Parent = content

    part(gate, "GateLeft", Vector3.new(4, 16, 4), CFrame.new(-12, 8, 80), Color3.fromRGB(45, 50, 64), Enum.Material.Metal)
    part(gate, "GateRight", Vector3.new(4, 16, 4), CFrame.new(12, 8, 80), Color3.fromRGB(45, 50, 64), Enum.Material.Metal)
    part(gate, "GateTop", Vector3.new(28, 4, 4), CFrame.new(0, 16, 80), Color3.fromRGB(45, 50, 64), Enum.Material.Metal)
    part(gate, "GateCore", Vector3.new(10, 1, 1), CFrame.new(0, 8, 77.5), Color3.fromRGB(95, 205, 255), Enum.Material.Neon)

    sign(content, "RiftGateSign", "RIFT GATE", Vector3.new(0, 0, 80))
    sign(content, "TrainingSign", "TRAINING DECK", Vector3.new(-34, 0, 15))
    sign(content, "MarketSign", "MARKET DECK", Vector3.new(34, 0, 15))

    for side, x in ipairs({-34, 34}) do
        local deck = Instance.new("Model")
        deck.Name = side == 1 and "TrainingDeck" or "MarketDeck"
        deck.Parent = content

        part(deck, "Base", Vector3.new(28, 2, 22), CFrame.new(x, 1, 15), Color3.fromRGB(47, 52, 64), Enum.Material.Concrete)
        part(deck, "Pad", Vector3.new(12, 0.4, 12), CFrame.new(x, 2.2, 15), Color3.fromRGB(90, 170, 215), Enum.Material.Neon)

        for index = 1, 4 do
            local px = x - 9 + ((index - 1) % 2) * 18
            local pz = 8 + math.floor((index - 1) / 2) * 14
            part(deck, "Post" .. index, Vector3.new(1.2, 5, 1.2), CFrame.new(px, 4.5, pz), Color3.fromRGB(32, 36, 45), Enum.Material.Metal)
        end
    end

    return content
end

return ContentBuilder
