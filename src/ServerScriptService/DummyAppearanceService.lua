--!strict

local Players = game:GetService("Players")

local DummyAppearanceService = {}

export type Options = {
    parent: Instance,
    position: Vector3,
    sourceUserId: number?,
    sourceOutfitId: number?,
    sourceMode: "Creator" | "User" | "Outfit"?,
    fallbackUserId: number?
}

local descriptionCache = setmetatable({}, {__mode = "v"})

local function cacheKey(mode: string, id: number): string
    return mode .. ":" .. tostring(id)
end

local function fetchDescription(options: Options): (HumanoidDescription?, string?)
    local mode = options.sourceMode or "Creator"
    local id = options.sourceUserId or 0

    if mode == "Outfit" then
        local outfitId = options.sourceOutfitId or 0
        if outfitId <= 0 then
            return nil, "MissingOutfitId"
        end

        local key = cacheKey(mode, outfitId)
        local cached = descriptionCache[key]
        if cached then
            return cached:Clone(), nil
        end

        local ok, result = pcall(function()
            return Players:GetHumanoidDescriptionFromOutfitIdAsync(outfitId)
        end)
        if not ok or not result then
            return nil, "OutfitDescriptionFailed:" .. tostring(result)
        end

        descriptionCache[key] = result
        return result:Clone(), nil
    end

    if mode == "Creator" then
        if game.CreatorType == Enum.CreatorType.User then
            id = game.CreatorId
        else
            id = options.fallbackUserId or 1
        end
    end

    if id <= 0 then
        return nil, "MissingUserId"
    end

    local key = cacheKey("User", id)
    local cached = descriptionCache[key]
    if cached then
        return cached:Clone(), nil
    end

    local ok, result = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(id)
    end)
    if not ok or not result then
        return nil, "UserDescriptionFailed:" .. tostring(result)
    end

    descriptionCache[key] = result
    return result:Clone(), nil
end

local function styleDescription(description: HumanoidDescription)
    description.HeightScale = math.clamp(description.HeightScale, 0.96, 1.08)
    description.WidthScale = math.clamp(description.WidthScale, 0.9, 1.02)
    description.DepthScale = math.clamp(description.DepthScale, 0.9, 1.02)
    description.HeadScale = math.clamp(description.HeadScale, 0.92, 1.02)
    description.BodyTypeScale = math.clamp(description.BodyTypeScale, 0, 0.35)
    description.ProportionScale = math.clamp(description.ProportionScale, 0.25, 0.65)
end

local function addTargetPresentation(model: Model)
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")

    if not root or not root:IsA("BasePart") then
        return
    end

    model.PrimaryPart = root
    model:SetAttribute("TrainingDummy", true)
    model:SetAttribute("Respawns", true)
    model:SetAttribute("RealRobloxAvatar", true)
    model:SetAttribute("AppearanceSystem", "HumanoidDescription")

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanQuery = true
            descendant.CanTouch = true
            descendant.CastShadow = true
            pcall(function()
                descendant:SetNetworkOwner(nil)
            end)
        end
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = "Training Dummy"
        humanoid.MaxHealth = 1000
        humanoid.Health = 1000
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        humanoid.BreakJointsOnDeath = false
        humanoid.RequiresNeck = false
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        humanoid.NameDisplayDistance = 90
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "TrainingHighlight"
    highlight.FillColor = Color3.fromRGB(105, 73, 168)
    highlight.FillTransparency = 0.82
    highlight.OutlineColor = Color3.fromRGB(218, 93, 111)
    highlight.OutlineTransparency = 0.12
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Adornee = model
    highlight.Parent = model

    if torso and torso:IsA("BasePart") then
        local core = Instance.new("Part")
        core.Name = "TrainingCore"
        core.Shape = Enum.PartType.Cylinder
        core.Size = Vector3.new(0.72, 0.2, 0.72)
        core.Material = Enum.Material.Neon
        core.Color = Color3.fromRGB(222, 75, 104)
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
        core.Massless = true
        core.CFrame = torso.CFrame * CFrame.new(0, 0.1, -0.76) * CFrame.Angles(0, 0, math.rad(90))
        core.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = torso
        weld.Part1 = core
        weld.Parent = core
    end

    if head and head:IsA("BasePart") then
        local status = Instance.new("BillboardGui")
        status.Name = "DummyStatus"
        status.Adornee = head
        status.Size = UDim2.fromOffset(250, 76)
        status.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
        status.AlwaysOnTop = true
        status.LightInfluence = 0
        status.Parent = head

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
        frame.BackgroundTransparency = 0.12
        frame.BorderSizePixel = 0
        frame.Parent = status

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.fromScale(1, 0.42)
        title.BackgroundTransparency = 1
        title.Text = "TRAINING TARGET"
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 16
        title.TextColor3 = Color3.fromRGB(242, 242, 248)
        title.Parent = frame

        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.fromScale(1, 0.25)
        subtitle.Position = UDim2.fromScale(0, 0.42)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "REAL ROBLOX AVATAR • COMBAT TEST"
        subtitle.Font = Enum.Font.GothamBold
        subtitle.TextSize = 8
        subtitle.TextColor3 = Color3.fromRGB(164, 118, 214)
        subtitle.Parent = frame

        if humanoid then
            humanoid.HealthChanged:Connect(function(health)
                local ratio = math.clamp(health / math.max(humanoid.MaxHealth, 1), 0, 1)
                subtitle.Text = string.format("COMBAT TEST • %d%% HP", math.floor(ratio * 100 + 0.5))
            end)
        end
    end
end

function DummyAppearanceService.Create(options: Options): (Model?, string?)
    local description, descriptionError = fetchDescription(options)
    if not description then
        return nil, descriptionError
    end

    styleDescription(description)

    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(
            description,
            Enum.HumanoidRigType.R15,
            Enum.AssetTypeVerification.Default
        )
    end)

    description:Destroy()

    if not ok or not model then
        return nil, "RigCreationFailed:" .. tostring(model)
    end

    model.Name = "TrainingDummy"
    model.Parent = options.parent
    model:PivotTo(CFrame.new(options.position))
    addTargetPresentation(model)

    return model, nil
end

return DummyAppearanceService
