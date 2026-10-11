local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimalCatalog"))

local BarnService = {}
local profiles
local worldBuilder
local animalService
local passService
local notify
local lastTick = {}
local fractionalIncome = {}
local promptCooldown = {}
local started = false

local function incomeRate(data)
    local rate = 0
    for _, animalId in ipairs(data.BarnAnimals) do
        local spec = Catalog.Get(animalId)
        if spec then
            rate += spec.IncomePerSecond
        end
    end
    return rate
end

local function passMultiplier(player)
    local multiplier = 1
    if passService.Has(player, "DoubleIncome") then
        multiplier *= 2
    end
    if passService.Has(player, "VIPFarm") then
        multiplier *= 1.25
    end
    return multiplier
end

local function capacityFor(player)
    return Config.Barn.BaseSlots
        + (passService.Has(player, "ExtraBarnSlots") and Config.Barn.ExtraBarnSlots or 0)
end

function BarnService.RefreshPlayer(player)
    if not profiles.IsLoaded(player) then
        return false
    end
    local data = profiles.Get(player)
    if not data then
        return false
    end
    worldBuilder.SetBarnAnimals(player, data.BarnAnimals)
    player:SetAttribute("BarnCapacity", capacityFor(player))
    player:SetAttribute("BarnIncomeRate", math.floor(incomeRate(data) * passMultiplier(player) * (1 + data.Rebirths * Config.RebirthIncomeBonusPerRebirth)))
    player:SetAttribute("BarnAnimalCount", #data.BarnAnimals)
    player:SetAttribute("BarnBank", data.BarnBank)
    profiles.Sync(player)
    return true
end

function BarnService.InitializePlayer(player)
    if not profiles.IsLoaded(player) or player.Parent ~= Players then
        return false
    end
    local success, earned, elapsed, rate = profiles.ClaimOfflineIncome(
        player,
        passMultiplier(player),
        Config.Barn.OfflineIncomeCapSeconds
    )
    if not success then
        warn("StealAnAnimal: could not claim offline barn income: " .. tostring(earned))
    elseif earned > 0 then
        notify(player, "Your barn earned +" .. tostring(earned) .. " coins while you were away.", "Success")
    end
    lastTick[player] = os.clock()
    fractionalIncome[player] = 0
    BarnService.RefreshPlayer(player)
    return success, earned, elapsed, rate
end

local function addPrompt(base, pad, actionText, objectText, interactionType, holdDuration)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = interactionType .. "Prompt"
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = holdDuration
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("InteractionType", interactionType)
    prompt:SetAttribute("BaseIndex", pad:GetAttribute("BaseIndex"))
    prompt.Parent = pad
    return prompt
end

local function validAtPad(player, base, pad)
    if player.Parent ~= Players or base:GetAttribute("OwnerUserId") ~= player.UserId then
        return false
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end
    if (root.Position - pad.Position).Magnitude > math.min(Config.MaxInteractionDistance, 12) then
        return false
    end
    return true
end

local function deposit(player, prompt)
    if not profiles.IsLoaded(player) then
        return
    end
    local pad = prompt.Parent
    local base = pad and pad:FindFirstAncestorOfClass("Model")
    if not pad or not base or not pad:IsA("BasePart") or not base:IsDescendantOf(worldBuilder.GetBasesFolder()) then
        return
    end
    if not validAtPad(player, base, pad) then
        return
    end
    local now = os.clock()
    if now - (promptCooldown[player] or 0) < Config.Barn.DepositCooldown then
        return
    end
    promptCooldown[player] = now

    local entry = animalService.GetCarried(player)
    if not entry or entry.Busy then
        notify(player, "Carry a wild animal here first.", "Warning")
        return
    end
    local capacity = capacityFor(player)
    local data = profiles.Get(player)
    if not data then
        return
    end
    if #data.BarnAnimals >= capacity then
        notify(player, "Your barn is full. Collect coins or unlock more barn slots.", "Warning")
        return
    end

    entry.Busy = true
    local success, count, duplicate = profiles.AddBarnAnimal(player, entry.AnimalId, capacity, HttpService:GenerateGUID(false))
    if not success then
        entry.Busy = false
        notify(player, count == "barn-full" and "Your barn is full." or "Animal storage failed safely. Keep holding your animal and try again.", "Error")
        return
    end

    animalService.Deposit(player)
    BarnService.RefreshPlayer(player)
    local spec = Catalog.Get(entry.AnimalId)
    local income = spec and spec.IncomePerSecond or 0
    notify(player, (spec and spec.DisplayName or entry.DisplayName) .. " is now in your barn! +" .. tostring(income) .. " coins/second.", "Success")
end

local function collect(player, prompt)
    if not profiles.IsLoaded(player) then
        return
    end
    local pad = prompt.Parent
    local base = pad and pad:FindFirstAncestorOfClass("Model")
    if not pad or not base or not pad:IsA("BasePart") or not base:IsDescendantOf(worldBuilder.GetBasesFolder()) then
        return
    end
    if not validAtPad(player, base, pad) then
        return
    end
    local now = os.clock()
    if now - (promptCooldown[player] or 0) < Config.Barn.CollectionCooldown then
        return
    end
    promptCooldown[player] = now
    local success, amount, reason = profiles.CollectBarnIncome(player)
    if not success then
        notify(player, "Unable to collect your saved income yet. Try again.", "Error")
        return
    end
    BarnService.RefreshPlayer(player)
    if amount > 0 then
        notify(player, "Collected " .. tostring(amount) .. " coins from your barn!", "Success")
    else
        notify(player, "Your barn bank is empty. Your animals are still earning.", "Info")
    end
end

function BarnService.Start(profileService, builder, animals, passes, notifyFunction)
    if started then
        return
    end
    started = true
    profiles = profileService
    worldBuilder = builder
    animalService = animals
    passService = passes
    notify = notifyFunction

    for _, entry in ipairs(builder.GetDepositPads()) do
        addPrompt(entry.Base, entry.Pad, "STORE ANIMAL", "Your Barn", "DepositAnimal", 0.55)
    end
    for _, entry in ipairs(builder.GetIncomePads()) do
        addPrompt(entry.Base, entry.Pad, "COLLECT COINS", "Barn Income", "CollectBarnIncome", 0.25)
    end

    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        local interactionType = prompt:GetAttribute("InteractionType")
        if interactionType == "DepositAnimal" then
            local ok, err = pcall(deposit, player, prompt)
            if not ok then
                warn("StealAnAnimal: barn deposit error: " .. tostring(err))
                notify(player, "The barn could not store your animal. Try again.", "Error")
            end
        elseif interactionType == "CollectBarnIncome" then
            local ok, err = pcall(collect, player, prompt)
            if not ok then
                warn("StealAnAnimal: income collection error: " .. tostring(err))
                notify(player, "Income collection failed safely. Try again.", "Error")
            end
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        for _, attribute in ipairs({ "HasDoubleIncome", "HasVIPFarm", "HasExtraBarnSlots" }) do
            player:GetAttributeChangedSignal(attribute):Connect(function()
                BarnService.RefreshPlayer(player)
            end)
        end
    end
    Players.PlayerAdded:Connect(function(player)
        for _, attribute in ipairs({ "HasDoubleIncome", "HasVIPFarm", "HasExtraBarnSlots" }) do
            player:GetAttributeChangedSignal(attribute):Connect(function()
                BarnService.RefreshPlayer(player)
            end)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(Config.Barn.IncomeTickSeconds)
            for _, player in ipairs(Players:GetPlayers()) do
                if profiles.IsLoaded(player) and player:GetAttribute("DataLoaded") then
                    local now = os.clock()
                    local previous = lastTick[player] or now
                    local elapsed = math.clamp(now - previous, 0, 5)
                    lastTick[player] = now
                    local data = profiles.Get(player)
                    if data then
                        local rate = incomeRate(data) * passMultiplier(player)
                            * (1 + data.Rebirths * Config.RebirthIncomeBonusPerRebirth)
                        local accumulated = (fractionalIncome[player] or 0) + rate * elapsed
                        local whole = math.floor(accumulated)
                        local credited = profiles.AccrueBarnIncome(player, whole, os.time())
                        if credited then
                            fractionalIncome[player] = accumulated - whole
                        else
                            fractionalIncome[player] = math.min(accumulated, Config.CoinsLimit)
                        end
                        if whole > 0 then
                            player:SetAttribute("BarnIncomeRate", math.floor(rate))
                        end
                    end
                end
            end
        end
    end)
end

function BarnService.RemovePlayer(player)
    lastTick[player] = nil
    fractionalIncome[player] = nil
    promptCooldown[player] = nil
end

return BarnService
