local Players = game:GetService("Players")

local DomainService = {}
local domains = {}

local function makeVisual(player, name, radius, duration, characterId)
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
    root.Shape = Enum.PartType.Ball
    root.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    root.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
    root.Material = Enum.Material.ForceField
    root.Transparency = characterId == "Sukuna" and 1 or 0.88
    root.Color = characterId == "Gojo" and Color3.fromRGB(110, 170, 255)
        or characterId == "Sukuna" and Color3.fromRGB(180, 35, 35)
        or Color3.fromRGB(245, 245, 245)
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
    ring.Material = Enum.Material.Neon
    ring.Color = root.Color
    ring.Parent = model

    if characterId == "Sukuna" then
        for i = 1, 4 do
            local pillar = Instance.new("Part")
            pillar.Name = "ShrinePillar_" .. i
            pillar.Anchored = true
            pillar.CanCollide = false
            pillar.Size = Vector3.new(2, 12, 2)
            local angle = math.rad((i - 1) * 90)
            pillar.Position = root.Position + Vector3.new(math.cos(angle) * radius * 0.58, 6, math.sin(angle) * radius * 0.58)
            pillar.Material = Enum.Material.Brick
            pillar.Color = Color3.fromRGB(110, 20, 20)
            pillar.Parent = model
        end
    end

    task.delay(duration + 2, function()
        if model.Parent then
            model:Destroy()
        end
    end)

    return model
end

local function getHumanoidsInRadius(center, radius, owner)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {owner.Character}
    overlap.MaxParts = 160

    local parts = workspace:GetPartBoundsInRadius(center, radius, overlap)
    local targets = {}
    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] then
            local player = Players:GetPlayerFromCharacter(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if player and player ~= owner and humanoid and humanoid.Health > 0 and root then
                seen[model] = true
                table.insert(targets, {player = player, humanoid = humanoid, root = root})
            end
        end
    end

    return targets
end

local function applyDomainPulse(entry)
    local owner = entry.player
    if not owner.Parent or owner:GetAttribute("InClash") then
        return
    end

    local targets = getHumanoidsInRadius(entry.center, entry.radius, owner)
    for _, target in ipairs(targets) do
        if not target.player:GetAttribute("InClash") then
            if entry.characterId == "Gojo" then
                target.humanoid:TakeDamage(2.5)
                local oldSpeed = target.humanoid.WalkSpeed
                target.humanoid.WalkSpeed = math.min(oldSpeed, 6)
                task.delay(0.42, function()
                    if target.humanoid.Parent and target.humanoid.Health > 0 and not target.player:GetAttribute("InClash") then
                        target.humanoid.WalkSpeed = math.max(target.humanoid.WalkSpeed, 16)
                    end
                end)
            elseif entry.characterId == "Sukuna" then
                target.humanoid:TakeDamage(5)
                local direction = (target.root.Position - entry.center)
                if direction.Magnitude > 0 then
                    target.root.AssemblyLinearVelocity = direction.Unit * 42 + Vector3.new(0, 12, 0)
                end
            elseif entry.characterId == "Yuji" then
                target.humanoid:TakeDamage(4)
                local direction = (target.root.Position - entry.center)
                if direction.Magnitude > 0 then
                    target.root.AssemblyLinearVelocity = direction.Unit * 26 + Vector3.new(0, 8, 0)
                end
            end
        end
    end
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
    if player:GetAttribute("InClash") then
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

    local visual = makeVisual(player, domainName, radius, duration, characterId)
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

    task.spawn(function()
        while domains[player] == entry and os.clock() - entry.started < duration do
            applyDomainPulse(entry)
            task.wait(0.5)
        end
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
        if other ~= player and other.Parent == Players and not other:GetAttribute("InClash") then
            if (mine.center - domain.center).Magnitude <= (mine.radius + domain.radius) then
                table.insert(overlaps, domain)
            end
        end
    end

    return overlaps
end

function DomainService:ForceClashState(player, active)
    player:SetAttribute("InClash", active)
    if active then
        player:SetAttribute("DomainActive", false)
    end
end

return DomainService
