--!strict

local Factory = {}

local function makeFallback(classId: string): Model
    local colors = {
        Vanguard = {Color3.fromRGB(68,78,94), Color3.fromRGB(88,190,255)},
        Striker = {Color3.fromRGB(70,52,96), Color3.fromRGB(190,100,255)},
        Guardian = {Color3.fromRGB(58,86,78), Color3.fromRGB(88,220,172)},
        Support = {Color3.fromRGB(92,82,58), Color3.fromRGB(255,202,96)},
    }
    local palette = colors[classId] or colors.Vanguard
    local model = Instance.new("Model")
    model.Name = "FriendEcho"
    model:SetAttribute("FriendEcho", true)
    model:SetAttribute("ClassId", classId)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2.2, 3.2, 2.2)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 250
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = 13
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model

    for name, size, offset, color in {
        {"Torso", Vector3.new(2.8,3,1.8), Vector3.new(0,1.7,0), palette[1]},
        {"Head", Vector3.new(2,2,2), Vector3.new(0,4.2,0), palette[1]},
        {"LeftArm", Vector3.new(0.8,2.8,0.8), Vector3.new(-1.8,1.7,0), palette[1]},
        {"RightArm", Vector3.new(0.8,2.8,0.8), Vector3.new(1.8,1.7,0), palette[1]},
        {"LeftLeg", Vector3.new(0.9,3,0.9), Vector3.new(-0.65,-1.6,0), palette[1]},
        {"RightLeg", Vector3.new(0.9,3,0.9), Vector3.new(0.65,-1.6,0), palette[1]},
    } do
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.CFrame = root.CFrame * CFrame.new(offset)
        part.Color = color
        part.Material = Enum.Material.SmoothPlastic
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = true
        part.Anchored = false
        part.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = root
    end

    local core = Instance.new("Part")
    core.Name = "EchoCore"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(0.8,0.8,0.8)
    core.CFrame = root.CFrame * CFrame.new(0,2.3,-1)
    core.Color = palette[2]
    core.Material = Enum.Material.Neon
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.Anchored = false
    core.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = core
    weld.Parent = root

    return model
end

function Factory.Create(friendUserId: number, classId: string, avatarModel: Model?, spawnCFrame: CFrame): Model
    local model = if avatarModel then avatarModel else makeFallback(classId)
    model.Name = "Echo_" .. tostring(friendUserId)
    model:SetAttribute("FriendEcho", true)
    model:SetAttribute("FriendUserId", friendUserId)
    model:SetAttribute("ClassId", classId)

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        model = makeFallback(classId)
        model:SetAttribute("FriendEcho", true)
        model:SetAttribute("FriendUserId", friendUserId)
        model:SetAttribute("ClassId", classId)
        root = model:FindFirstChild("HumanoidRootPart")
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = descendant.Name ~= "HumanoidRootPart"
            descendant.Massless = true
        elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant:Destroy()
        end
    end

    if model:FindFirstChildOfClass("Humanoid") then
        local current = model:FindFirstChildOfClass("Humanoid")
        current.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        current.AutoRotate = true
    end

    local head = model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local tag = Instance.new("BillboardGui")
        tag.Name = "EchoLabel"
        tag.Size = UDim2.fromOffset(150, 28)
        tag.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
        tag.AlwaysOnTop = true
        tag.Adornee = head
        tag.Parent = head
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1,1)
        label.BackgroundTransparency = 1
        label.Text = "FRIEND ECHO • " .. classId
        label.TextColor3 = Color3.fromRGB(95,210,255)
        label.TextStrokeTransparency = 0.25
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = tag
    end

    model.Parent = workspace:WaitForChild("Enemies")
    if root and root:IsA("BasePart") then
        model:PivotTo(spawnCFrame)
    end
    return model
end

return Factory
