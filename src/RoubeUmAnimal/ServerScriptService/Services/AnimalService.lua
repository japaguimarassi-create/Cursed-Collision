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
local started = false

local function characterState(player)
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

local function getAnimalModel(prompt)
    local animals = worldBuilder.GetAnimalsFolder()
    local current = prompt.Parent
    while current and current ~= animals do
        if current:IsA("Model") and current.Parent == animals then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function scheduleRespawn(animalId, spawnCFrame, delaySeconds)
    task.delay(math.clamp(delaySeconds or Config.AnimalRespawnSeconds, 5, 180), function()
        local animals = worldBuilder.GetAnimalsFolder()
        if not animals or not animals.Parent then
            return
        end
        local success, result = pcall(function()
            return worldBuilder.SpawnAnimal(animalId, spawnCFrame)
        end)
        if not success then
            warn("StealAnAnimal: animal respawn failed for " .. tostring(animalId) .. ": " .. tostring(result))
        end
    end)
end

local function removeVisual(entry)
    if entry.Visual and entry.Visual.Parent then
        pcall(function()
            entry.Visual:Destroy()
        end)
    end
end

local function attachCarriedVisual(sourceModel, player)
    local character, _, root = characterState(player)
    if not character then
        error("Player character is unavailable during capture")
    end
    local visual = sourceModel:Clone()
    for _, object in ipairs(visual:GetDescendants()) do
        if object:IsA("ProximityPrompt")
            or object:IsA("ClickDetector")
            or object:IsA("BillboardGui")
            or object:IsA("Script")
            or object:IsA("LocalScript") then
            object:Destroy()
        end
    end
    local primary = visual.PrimaryPart or visual:FindFirstChild("Body")
    if not primary or not primary:IsA("BasePart") then
        visual:Destroy()
        error("Animal model has no valid primary part")
    end
    visual.PrimaryPart = primary
    visual.Name = "CarriedAnimal"
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

    local anchor = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or root
    visual:PivotTo(anchor.CFrame * CFrame.new(0, 0.1, 1.1) * CFrame.Angles(0, math.rad(180), 0))
    for _, object in ipairs(visual:GetDescendants()) do
        if object:IsA("BasePart") and object ~= primary then
            local weld = Instance.new("WeldConstraint")
            weld.Name = "CarriedAnimalWeld"
            weld.Part0 = primary
            weld.Part1 = object
            weld.Parent = primary
        end
    end
    local attachment = Instance.new("WeldConstraint")
    attachment.Name = "AnimalCarryWeld"
    attachment.Part0 = anchor
    attachment.Part1 = primary
    attachment.Parent = primary
    return visual
end

function AnimalService.ApplyMovement(player)
    local data = profiles.Get(player)
    if not data then
        return
    end
    local speedMultiplier = passService.Has(player, "DoubleSpeed") and Config.Training.DoubleSpeedMultiplier or 1
    local vipBonus = passService.Has(player, "VIPFarm") and Config.VipSpeedBonus or 0
    local baseSpeed = math.clamp(
        (Config.BaseWalkSpeed + data.Speed * Config.SpeedPerLevel) * speedMultiplier + vipBonus,
        Config.BaseWalkSpeed,
        Config.MaximumWalkSpeed
    )
    local effectiveSpeed = baseSpeed
    local entry = carried[player]
    if entry then
        local carrySpeed = Rules.CarrySpeed(
            baseSpeed,
            entry.Weight,
            Config.CarryPenaltyStartWeight,
            Config.CarryPenaltyPerWeight,
            Config.MaximumCarryPenalty,
            Config.MinimumCarrySpeed
        )
        if carrySpeed then
            effectiveSpeed = carrySpeed
        end
    end
    local _, humanoid = characterState(player)
    if humanoid then
        humanoid.WalkSpeed = effectiveSpeed
    end
    player:SetAttribute("BaseWalkSpeed", baseSpeed)
    player:SetAttribute("EffectiveWalkSpeed", effectiveSpeed)
end

function AnimalService.GetCarried(player)
    return carried[player]
end

local function releaseCarried(player, message, messageType)
    local entry = carried[player]
    if not entry then
        player:SetAttribute("CarryingAnimal", false)
        player:SetAttribute("CarriedAnimalName", nil)
        player:SetAttribute("CarriedAnimalWeight", nil)
        player:SetAttribute("CarriedAnimalIncome", nil)
        AnimalService.ApplyMovement(player)
        return false
    end
    carried[player] = nil
    player:SetAttribute("CarryingAnimal", false)
    player:SetAttribute("CarriedAnimalName", nil)
    player:SetAttribute("CarriedAnimalWeight", nil)
    player:SetAttribute("CarriedAnimalIncome", nil)
    removeVisual(entry)
    AnimalService.ApplyMovement(player)
    if message and notify then
        notify(player, message, messageType or "Info")
    end
    return true
end

function AnimalService.Deposit(player)
    local entry = carried[player]
    if not entry or not entry.Busy then
        return false
    end
    return releaseCarried(player)
end

function AnimalService.Lose(player, reason)
    if not carried[player] then
        return false
    end
    return releaseCarried(player, reason or "A guardian caught you. Your carried animal escaped!", "Warning")
end

function AnimalService.RemovePlayer(player)
    releaseCarried(player)
    carried[player] = nil
    lastCapture[player] = nil
end

local function capture(player, prompt)
    if not profiles.IsLoaded(player) or carried[player] or player:GetAttribute("RebirthInProgress") then
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
        notify(player, "Animal not found in the catalogue.", "Error")
        warn("StealAnAnimal: invalid AnimalId on " .. model:GetFullName())
        return
    end
    local _, humanoid, root = characterState(player)
    local primary = model.PrimaryPart or model:FindFirstChild("Body")
    if not humanoid or not root or not primary then
        return
    end
    if (root.Position - primary.Position).Magnitude > math.min(prompt.MaxActivationDistance, Config.MaxInteractionDistance) + 2 then
        return
    end
    if not Rules.CanCapture(carried[player] ~= nil) then
        notify(player, "You can only carry one animal at a time.", "Warning")
        return
    end

    local spawnCFrame = model:GetPivot() * CFrame.new(0, -1.4, 0)
    local visual
    local success, err = pcall(function()
        visual = attachCarriedVisual(model, player)
        carried[player] = {
            AnimalId = spec.Id,
            DisplayName = spec.DisplayName,
            Weight = spec.Weight,
            Rarity = spec.Rarity,
            BaseValue = spec.BaseValue,
            IncomePerSecond = spec.IncomePerSecond,
            RespawnSeconds = spec.RespawnSeconds,
            SpawnCFrame = spawnCFrame,
            Visual = visual,
            Busy = false,
        }
        player:SetAttribute("CarryingAnimal", true)
        player:SetAttribute("CarriedAnimalName", spec.DisplayName)
        player:SetAttribute("CarriedAnimalWeight", spec.Weight)
        player:SetAttribute("CarriedAnimalIncome", spec.IncomePerSecond)
        model:Destroy()
    end)
    if not success then
        warn("StealAnAnimal: capture failed: " .. tostring(err))
        if visual then
            visual:Destroy()
        end
        carried[player] = nil
        player:SetAttribute("CarryingAnimal", false)
        player:SetAttribute("CarriedAnimalName", nil)
        player:SetAttribute("CarriedAnimalWeight", nil)
        player:SetAttribute("CarriedAnimalIncome", nil)
        return
    end

    scheduleRespawn(spec.Id, spawnCFrame, spec.RespawnSeconds)
    profiles.RecordCapture(player)
    AnimalService.ApplyMovement(player)
    notify(player, spec.DisplayName .. " captured! Return to your barn pad to store it and earn coins every second.", "Success")
end

function AnimalService.Start(profileService, builder, passes, notifyFunction)
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
            warn("StealAnAnimal: capture error: " .. tostring(err))
            notify(player, "Could not capture that animal. Try again.", "Error")
        end
    end)
end

return AnimalService
