local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DomainService = {}
local domains = {}

local function makeVisual(player, name, radius, duration)
    local folder = workspace:FindFirstChild("CursedDomains")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CursedDomains"
        folder.Parent = workspace
    end

    local model = Instance.new("Model")
    model.Name = name .. "_" .. player.UserId
    model.Parent = folder

    local root = Instance.new("Part")
    root.Name = "DomainCore"
    root.Anchored = true
    root.CanCollide = false
    root.CanQuery = false
    root.Transparency = 0.88
    root.Shape = Enum.PartType.Ball
    root.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    root.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
    root.Parent = model

    local ring = Instance.new("Part")
    ring.Name = "DomainFloor"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanQuery = false
    ring.Transparency = 0.7
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.5, radius * 2, radius * 2)
    ring.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = model

    Debris:AddItem(model, duration + 2)
    return model
end

function DomainService:GetAll()
    return domains
end

function DomainService:Get(player)
    return domains[player]
end

function DomainService:Stop(player)
    local entry = domains[player]
    if not entry then
        return
    end

    domains[player] = nil
    player:SetAttribute("DomainActive", false)
    if entry.visual and entry.visual.Parent then
        entry.visual:Destroy()
    end
end

function DomainService:start(player, domainName, characterId, radius, duration)
    local state = player:GetAttribute("InClash")
    if state then
        return false
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    if domains[player] then
        return false
    end

    local visual = makeVisual(player, domainName, radius, duration)
    local entry = {
        player = player,
        name = domainName,
        characterId = characterId,
        center = root.Position,
        radius = radius,
        started = os.clock(),
        duration = duration,
        visual = visual
    }

    domains[player] = entry
    player:SetAttribute("DomainActive", true)

    task.delay(duration, function()
        if domains[player] == entry then
            self:Stop(player)
        end
    end)

    return true
end

function DomainService:FindOverlaps(player)
    local mine = domains[player]
    if not mine then
        return {}
    end

    local overlaps = {}
    for other, domain in pairs(domains) do
        if other ~= player and other.Parent == Players then
            if (mine.center - domain.center).Magnitude <= (mine.radius + domain.radius) then
                table.insert(overlaps, domain)
            end
        end
    end

    return overlaps
end

function DomainService:ForceClashState(player, active)
    player:SetAttribute("InClash", active)
    player:SetAttribute("DomainActive", not active and player:GetAttribute("DomainActive") or false)
end

return DomainService
