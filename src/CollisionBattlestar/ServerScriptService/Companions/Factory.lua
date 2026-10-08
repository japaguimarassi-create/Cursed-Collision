--!strict

local AvatarResolver = require(script.Parent.AvatarResolver)
local VisualProfiles = require(script.Parent.VisualProfile)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsRules = require(ReplicatedStorage.Shared.PhysicsRules)

local CompanionFactory = {}

local function makeFallback(classId: string)
    local profile = VisualProfiles[classId] or VisualProfiles.Vanguard
    local model = Instance.new("Model")
    model.Name = "Echo_" .. classId

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Parent = model

    local body = Instance.new("Part")
    body.Name = "Core"
    body.Size = Vector3.new(profile.Width, 3.2, 1.8)
    body.Color = profile.Primary
    body.Material = Enum.Material.Metal
    body.CanCollide = false
    body.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2, 2, 2)
    head.Color = profile.Primary:Lerp(Color3.new(1, 1, 1), 0.12)
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = false
    head.Parent = model

    local accent = Instance.new("Part")
    accent.Name = "Accent"
    accent.Size = Vector3.new(profile.Width * 0.8, 0.5, 2)
    accent.Color = profile.Accent
    accent.Material = Enum.Material.Neon
    accent.CanCollide = false
    accent.Parent = model

    root.CFrame = CFrame.new(0, profile.Height * 0.5, 0)
    body.CFrame = CFrame.new(0, 1.8, 0)
    head.CFrame = CFrame.new(0, 3.9, 0)
    accent.CFrame = CFrame.new(0, 2.4, -1)

    for _, part in ipairs({body, head, accent}) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = root
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 80
    humanoid.Health = 80
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.PlatformStand = true
    humanoid.RequiresNeck = false
    humanoid.Parent = model

    model.PrimaryPart = root
    return model
end

local function sanitizeModel(model: Model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("Script")
            or descendant:IsA("LocalScript")
            or descendant:IsA("ModuleScript") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CastShadow = false
            descendant.Massless = true
            PhysicsRules.apply(descendant, PhysicsRules.Echo)
            descendant:SetNetworkOwner(nil)
        end
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.PlatformStand = true
        humanoid.RequiresNeck = false
    end

    if root and root:IsA("BasePart") then
        root.CanCollide = false
        root.CanTouch = false
        root.CanQuery = true
    end

    return humanoid, root
end

function CompanionFactory.Create(friendUserId: number, classId: string, level: number)
    local model = AvatarResolver.Resolve(friendUserId)
    local usedAvatar = model ~= nil

    if not model then
        model = makeFallback(classId)
    else
        model.Name = "Echo_" .. classId
    end

    local humanoid, root = sanitizeModel(model)
    if not humanoid or not root then
        model:Destroy()
        return nil
    end

    model:SetAttribute("CBS_Echo", true)
    model:SetAttribute("CBS_EchoFriendUserId", friendUserId)
    model:SetAttribute("CBS_EchoClassId", classId)
    model:SetAttribute("CBS_EchoLevel", level)
    model:SetAttribute("CBS_EchoAvatarReady", usedAvatar)

    local highlight = Instance.new("Highlight")
    highlight.Name = "EchoHighlight"
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0.25
    highlight.Parent = model

    return model, humanoid, root, usedAvatar
end

return CompanionFactory
