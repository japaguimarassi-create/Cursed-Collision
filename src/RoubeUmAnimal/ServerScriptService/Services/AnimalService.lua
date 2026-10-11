local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalCatalog"))
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayRules"))

local AnimalService = {}

local profiles
local worldBuilder
local passService
local notify
local carried = {}
local lastCapture = {}
local lastSale = {}
local connectedSellParts = {}
local started = false

local function getCharacterState(player)
    local character = player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil, nil, nil
    end

    return character, humanoid, root
end

local function clearVisual(entry)
    if entry.tool then
        pcall(function()
            entry.tool:Destroy()
        end)
    end

    if entry.visual then
        pcall(function()
            entry.visual:Destroy()
        end)
    end
end

function AnimalService.ApplyMovement(player)
    local data = profiles.Get(player)

    if not data then
        return
    end

    local vipBonus = passService and passService.Has(player, "VIPSpeed") and Config.VipSpeedBonus or 0
    local baseSpeed = math.clamp(
        Config.BaseWalkSpeed + data.Speed * Config.SpeedPerLevel + vipBonus,
        Config.BaseWalkSpeed,
        Config.MaximumWalkSpeed
    )

    local effectiveSpeed = baseSpeed
    local entry = carried[player]

    if entry then
        local carrySpeed = Rules.CarrySpeed(
            baseSpeed,
            entry.Weight,
            data.Strength,
            Config.CarryPenaltyStartRatio,
            Config.CarryPenaltyPerRatio,
            Config.MinimumCarrySpeed
        )
        if carrySpeed then
            effectiveSpeed = carrySpeed
        end
    end

    local _, humanoid = getCharacterState(player)

    if humanoid then
        humanoid.WalkSpeed = effectiveSpeed
    end

    player:SetAttribute("BaseWalkSpeed", baseSpeed)
    player:SetAttribute("EffectiveWalkSpeed", effectiveSpeed)
end

local function getAnimalModel(prompt)
    local folder = worldBuilder.GetAnimalsFolder()
    local current = prompt.Parent

    while current and current ~= folder do
        if current:IsA("Model") and current.Parent == folder then
            return current
        end

        current = current.Parent
    end

    return nil
end

local function distanceAllowed(player, targetPosition, maxDistance)
    local _, _, root = getCharacterState(player)

    if not root then
        return false
    end

    return (root.Position - targetPosition).Magnitude <= maxDistance
end

local function attachCarriedVisual(sourceModel, player)
    local character, _, root = getCharacterState(player)

    if not character then
        error("Personagem inválido durante a captura")
    end

    local visual = sourceModel:Clone()

    for _, object in ipairs(visual:GetDescendants()) do
        if object:IsA("ProximityPrompt")
            or object:IsA("ClickDetector")
            or object:IsA("Script")
            or object:IsA("LocalScript") then
            object:Destroy()
        end
    end

    local primary = visual.PrimaryPart or visual:FindFirstChild("Body")

    if not primary or not primary:IsA("BasePart") then
        visual:Destroy()
        error("Modelo de animal sem PrimaryPart")
    end

    visual.PrimaryPart = primary
    visual.Name = "AnimalCarregado"

    local bodyPart = character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or root

    visual.Parent = character

    for _, object in ipairs(visual:GetDescendants()) do
        if object:IsA("BasePart") then
            object.Anchored = false
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.Massless = true
        end
    end

    visual:PivotTo(
        bodyPart.CFrame
        * CFrame.new(0, 0.05, 0.95)
        * CFrame.Angles(0, math.rad(180), 0)
    )

    for _, object in ipairs(visual:GetDescendants()) do
        if object:IsA("BasePart") and object ~= primary then
            local weld = Instance.new("WeldConstraint")
            weld.Name = "AnimalBodyWeld"
            weld.Part0 = primary
            weld.Part1 = object
            weld.Parent = primary
        end
    end

    local attachment = Instance.new("WeldConstraint")
    attachment.Name = "AnimalCarryWeld"
    attachment.Part0 = bodyPart
    attachment.Part1 = primary
    attachment.Parent = primary

    return visual
end

local function createTool(spec)
    local tool = Instance.new("Tool")
    tool.Name = "Animal_" .. spec.Id
    tool.ToolTip = spec.DisplayName
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.ManualActivationOnly = true
    tool:SetAttribute("AnimalId", spec.Id)
    tool:SetAttribute("Weight", spec.Weight)
    tool:SetAttribute("Rarity", spec.Rarity)
    tool:SetAttribute("BaseValue", spec.BaseValue)
    return tool
end

local function scheduleRespawn(speciesId, spawnCFrame, delaySeconds)
    task.delay(math.clamp(delaySeconds or Config.AnimalRespawnSeconds, 5, 180), function()
        if not worldBuilder.GetAnimalsFolder() then
            return
        end

        local success, result = pcall(function()
            return worldBuilder.SpawnAnimal(speciesId, spawnCFrame)
        end)

        if not success then
            warn("RoubeUmAnimal: falha ao reaparecer " .. tostring(speciesId) .. ": " .. tostring(result))
        end
    end)
end

local function releaseCarried(player, respawn, message, messageType)
    local entry = carried[player]

    if not entry then
        player:SetAttribute("CarryingAnimal", false)
        AnimalService.ApplyMovement(player)
        return false
    end

    carried[player] = nil
    player:SetAttribute("CarryingAnimal", false)
    player:SetAttribute("CarriedAnimalName", nil)
    player:SetAttribute("CarriedAnimalWeight", nil)

    clearVisual(entry)
    AnimalService.ApplyMovement(player)

    if respawn then
        scheduleRespawn(entry.AnimalId, entry.SpawnCFrame, entry.RespawnSeconds)
    end

    if message and notify then
        notify(player, message, messageType or "Info")
    end

    return true
end

function AnimalService.GetCarried(player)
    return carried[player]
end

function AnimalService.Lose(player, reason)
    local entry = carried[player]

    if not entry then
        return false
    end

    local message = reason or "Você perdeu o animal."
    return releaseCarried(player, true, message, "Warning")
end

function AnimalService.RemovePlayer(player)
    releaseCarried(player, true, nil)
    carried[player] = nil
    lastCapture[player] = nil
    lastSale[player] = nil
end

local function capture(player, prompt)
    if not profiles.IsLoaded(player) or carried[player] then
        return
    end

    local now = os.clock()

    if now - (lastCapture[player] or 0) < Config.CaptureDebounce then
        return
    end

    lastCapture[player] = now

    local model = getAnimalModel(prompt)

    if not model or not model:IsDescendantOf(worldBuilder.GetAnimalsFolder()) then
        return
    end

    local spec = Catalog.Get(model:GetAttribute("AnimalId"))

    if not spec then
        notify(player, "Animal não catalogado. Avise o administrador.", "Error")
        warn("RoubeUmAnimal: AnimalId inválido em " .. model:GetFullName())
        return
    end

    local _, humanoid, root = getCharacterState(player)
    local primary = model.PrimaryPart or model:FindFirstChild("Body")

    if not humanoid or not root or not primary then
        return
    end

    if not distanceAllowed(player, primary.Position, math.min(prompt.MaxActivationDistance, Config.MaxInteractionDistance) + 2) then
        return
    end

    local data = profiles.Get(player)

    if not data or not Rules.CanCapture(data.Strength, spec.RequiredStrength, carried[player] ~= nil) then
        notify(
            player,
            "Você precisa de Força " .. tostring(spec.RequiredStrength) .. " para roubar " .. spec.DisplayName .. ".",
            "Warning"
        )
        return
    end

    local spawnCFrame = model:GetPivot() * CFrame.new(0, -1.4, 0)
    local tool
    local visual

    local success, err = pcall(function()
        visual = attachCarriedVisual(model, player)
        tool = createTool(spec)
        tool.Parent = player.Character

        carried[player] = {
            AnimalId = spec.Id,
            DisplayName = spec.DisplayName,
            Weight = spec.Weight,
            Rarity = spec.Rarity,
            BaseValue = spec.BaseValue,
            RespawnSeconds = spec.RespawnSeconds,
            SpawnCFrame = spawnCFrame,
            Tool = tool,
            Visual = visual,
            Busy = false,
        }

        player:SetAttribute("CarryingAnimal", true)
        player:SetAttribute("CarriedAnimalName", spec.DisplayName)
        player:SetAttribute("CarriedAnimalWeight", spec.Weight)

        model:Destroy()
    end)

    if not success then
        warn("RoubeUmAnimal: captura falhou: " .. tostring(err))
        if tool then
            tool:Destroy()
        end
        if visual then
            visual:Destroy()
        end
        carried[player] = nil
        player:SetAttribute("CarryingAnimal", false)
        return
    end

    AnimalService.ApplyMovement(player)
    notify(
        player,
        spec.DisplayName .. " capturado! Peso " .. spec.Weight .. ". Corra para seu curral!",
        "Success"
    )
end

local function salePrice(player, entry)
    local multiplier = Catalog.RarityMultipliers[entry.Rarity]

    if not multiplier then
        return 0
    end

    return Rules.SalePrice(
        entry.BaseValue,
        multiplier,
        passService ~= nil and passService.Has(player, "DoubleCoins"),
        Config.CoinsLimit
    )
end

local function sell(player, base, sellPart)
    if not profiles.IsLoaded(player) then
        return
    end

    local entry = carried[player]

    if not entry or entry.Busy then
        return
    end

    if base:GetAttribute("OwnerUserId") ~= player.UserId then
        return
    end

    local _, _, root = getCharacterState(player)

    if not root then
        return
    end

    if (root.Position - sellPart.Position).Magnitude > 11 then
        return
    end

    local now = os.clock()

    if now - (lastSale[player] or 0) < Config.SellDebounce then
        return
    end

    lastSale[player] = now
    entry.Busy = true

    local amount = salePrice(player, entry)

    if not amount or amount <= 0 then
        entry.Busy = false
        notify(player, "O valor deste animal é inválido.", "Error")
        return
    end

    local success, credited = profiles.AddCoins(player, amount)

    if not success or credited <= 0 then
        entry.Busy = false
        notify(player, "Não foi possível registrar as moedas da venda.", "Error")
        return
    end

    local name = entry.DisplayName
    releaseCarried(player, true, nil)

    notify(player, name .. " vendido por " .. tostring(credited) .. " Moedas!", "Success")
end

local function connectSellPart(part)
    if connectedSellParts[part] or not part:IsA("BasePart") or part.Name ~= "SellPart" then
        return
    end

    connectedSellParts[part] = true

    part.Touched:Connect(function(hit)
        local character = hit and hit:FindFirstAncestorOfClass("Model")
        local player = character and Players:GetPlayerFromCharacter(character)

        if not player then
            return
        end

        local base = part:FindFirstAncestorOfClass("Model")

        if not base or not base:IsDescendantOf(worldBuilder.GetBasesFolder()) then
            return
        end

        local success, err = pcall(sell, player, base, part)

        if not success then
            warn("RoubeUmAnimal: erro de venda: " .. tostring(err))
        end
    end)
end

function AnimalService.Start(profileService, builder, passes, remotes, notifyFunction)
    if started then
        return
    end

    started = true
    profiles = profileService
    worldBuilder = builder
    passService = passes
    notify = notifyFunction

    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        if prompt:GetAttribute("InteractionType") ~= "StealAnimal" then
            return
        end

        local success, err = pcall(capture, player, prompt)

        if not success then
            warn("RoubeUmAnimal: erro de captura: " .. tostring(err))
        end
    end)

    local animals = worldBuilder.GetAnimalsFolder()

    for _, model in ipairs(animals:GetChildren()) do
        if model:IsA("Model") then
            local primary = model:FindFirstChild("Head") or model.PrimaryPart
            if primary then
                local prompt = primary:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    prompt:SetAttribute("InteractionType", "StealAnimal")
                end
            end
        end
    end

    local bases = worldBuilder.GetBasesFolder()

    for _, base in ipairs(bases:GetChildren()) do
        for _, object in ipairs(base:GetDescendants()) do
            if object:IsA("BasePart") and object.Name == "SellPart" then
                connectSellPart(object)
            end
        end
    end

    bases.DescendantAdded:Connect(function(object)
        if object:IsA("BasePart") and object.Name == "SellPart" then
            task.defer(connectSellPart, object)
        end
    end)
end

return AnimalService
