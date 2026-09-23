local Players = game:GetService("Players")

local DomainService = {}
local domains = {}
local context

local function colorFor(id)
    local colors = {
        Yuji = Color3.fromRGB(245, 180, 120),
        Gojo = Color3.fromRGB(110, 170, 255),
        Sukuna = Color3.fromRGB(180, 35, 35),
        Megumi = Color3.fromRGB(55, 55, 90),
        Yuta = Color3.fromRGB(190, 160, 255),
        Mahito = Color3.fromRGB(160, 95, 185),
        Hakari = Color3.fromRGB(245, 215, 90),
        Jogo = Color3.fromRGB(245, 80, 35),
        Dagon = Color3.fromRGB(60, 150, 210),
        Higuruma = Color3.fromRGB(220, 220, 220),
        Kenjaku = Color3.fromRGB(115, 45, 145)
    }
    return colors[id] or Color3.fromRGB(235, 235, 235)
end

local function makeVisual(player, name, radius, duration, characterId)
    local folder = workspace:FindFirstChild("CursedDomains")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CursedDomains"
        folder.Parent = workspace
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local model = Instance.new("Model")
    model.Name = name .. "_" .. player.UserId
    model.Parent = folder

    local shell = Instance.new("Part")
    shell.Name = "DomainShell"
    shell.Anchored = true
    shell.CanCollide = false
    shell.CanTouch = false
    shell.CanQuery = false
    shell.Shape = Enum.PartType.Ball
    shell.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    shell.CFrame = CFrame.new(root.Position)
    shell.Material = Enum.Material.ForceField
    shell.Transparency = characterId == "Sukuna" and 1 or 0.9
    shell.Color = colorFor(characterId)
    shell.Parent = model

    local floor = Instance.new("Part")
    floor.Name = "DomainFloor"
    floor.Anchored = true
    floor.CanCollide = false
    floor.CanTouch = false
    floor.CanQuery = false
    floor.Shape = Enum.PartType.Cylinder
    floor.Size = Vector3.new(0.35, radius * 2, radius * 2)
    floor.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, math.rad(90))
    floor.Material = Enum.Material.Neon
    floor.Transparency = 0.78
    floor.Color = shell.Color
    floor.Parent = model

    if characterId == "Sukuna" then
        for i = 1, 4 do
            local pillar = Instance.new("Part")
            pillar.Name = "ShrinePillar_" .. i
            pillar.Anchored = true
            pillar.CanCollide = false
            pillar.CanTouch = false
            pillar.CanQuery = false
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
                table.insert(targets, {player=player, humanoid=humanoid, root=root})
            end
        end
    end

    return targets
end

local function pulse(entry)
    if not context or not entry.player.Parent or entry.player:GetAttribute("InClash") then
        return
    end

    local targets = getHumanoidsInRadius(entry.center, entry.radius, entry.player)
    local damage, stun, knockback = 2.5, 0.25, 0

    if entry.characterId == "Sukuna" then
        damage, stun, knockback = 2.5, 0.24, 22
    elseif entry.characterId == "Yuji" then
        damage, stun, knockback = 3.5, 0.3, 24
    elseif entry.characterId == "Gojo" then
        damage, stun, knockback = 2, 0.42, 0
    elseif entry.characterId == "Jogo" then
        damage, stun, knockback = 4.5, 0.3, 32
    elseif entry.characterId == "Dagon" then
        damage, stun, knockback = 4, 0.28, 26
    elseif entry.characterId == "Mahito" then
        damage, stun, knockback = 3.8, 0.35, 18
    end

    for _, target in ipairs(targets) do
        if not target.player:GetAttribute("InClash") then
            context.damage(entry.player, target.humanoid, damage, {
                stun = stun,
                knockback = knockback,
                tag = entry.name
            })
        end
    end
end

function DomainService:Configure(newContext)
    context = newContext
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
        player:SetAttribute("DomainActive", false)
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
    if not root or domains[player] then
        return false
    end

    local visual = makeVisual(player, domainName, radius, duration, characterId)
    if not visual then
        return false
    end

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
            pulse(entry)
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
    local state = context and context.getState(player)
    if state then
        state.Clash = active
    end
    if active then
        player:SetAttribute("DomainActive", false)
    end
end

Players.PlayerRemoving:Connect(function(player)
    if domains[player] then
        DomainService:Stop(player)
    end
end)

return DomainService