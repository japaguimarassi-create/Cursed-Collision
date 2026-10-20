local Players = game:GetService("Players")
Players.CharacterAutoLoads = true
Players.RespawnTime = 3
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("AnimalCatalog"))
local Rules = require(Shared:WaitForChild("GameplayRules"))
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local remotes = ReplicatedStorage:FindFirstChild("StealAnimalRemotes") or Instance.new("Folder")
remotes.Name = "StealAnimalRemotes"
remotes.Parent = ReplicatedStorage

local function remote(name)
    local item = remotes:FindFirstChild(name)
    if not item then
        item = Instance.new("RemoteEvent")
        item.Name = name
        item.Parent = remotes
    end
    return item
end

local notifyRemote = remote("Notify")
local upgradeRemote = remote("RequestUpgrade")
local collectRemote = remote("RequestCollect")
local rebirthRemote = remote("RequestRebirth")
local dailyRemote = remote("RequestDailyReward")
local codeRemote = remote("RequestRedeemCode")
local questRemote = remote("RequestQuest")
local mapBotRemote = remote("RequestMapBot")
local mapBotReportRemote = remote("MapBotReport")
local botXStatusRemote = remote("BotXStatus")

local previewWorld = Workspace:FindFirstChild("StealAnAnimalWorld")
local previousRuntimeWorld = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
if previousRuntimeWorld then
    previousRuntimeWorld:Destroy()
end

local world = Instance.new("Folder")
world.Name = "StealAnAnimalRuntimeWorld"
world.Parent = Workspace

local basesFolder = Instance.new("Folder")
basesFolder.Name = "PlayerFarms"
basesFolder.Parent = world

local wildlifeFolder = Instance.new("Folder")
wildlifeFolder.Name = "Wildlife"
wildlifeFolder.Parent = world

local guardiansFolder = Instance.new("Folder")
guardiansFolder.Name = "Guardians"
guardiansFolder.Parent = world

local decorationFolder = Instance.new("Folder")
decorationFolder.Name = "Scenery"
decorationFolder.Parent = world

local profiles = {}
local sessionTokens = {}
local saveInProgress = {}
local leaving = {}
local rebirthInProgress = {}
local progressionWriteInProgress = {}
local mapBotCooldowns = {}
local actionCooldowns = {}
local trainingNoticeAt = {}
local treadmillStrips = {}
local treadmillAnimationAccumulator = 0
local playerBases = {}
local playerSetupDone = {}
local carried = {}
local guardians = {}
local wildRecords = {}
local rng = Random.new(20261020)
local SESSION_LEASE_SECONDS = 180
local DAILY_CODES = table.freeze({
    FARMFAMILY = 1000,
    WILDSTART = 1500,
    BARNBOOST = 2500,
})
local QUESTS = table.freeze({
    FirstCapture = { Reward = 250, Label = "Roube seu primeiro animal", Requirement = function(profile) return profile.TotalCaptured >= 1 end },
    FirstBarn = { Reward = 750, Label = "Deposite seu primeiro animal", Requirement = function(profile) return profile.TotalDeposited >= 1 end },
    Collector = { Reward = 1500, Label = "Roube 5 animais", Requirement = function(profile) return profile.TotalCaptured >= 5 end },
    FullBarn = { Reward = 5000, Label = "Encha os 6 espaços do celeiro", Requirement = function(profile) return #profile.BarnAnimals >= Config.BaseSlots end },
})

local function notify(player, message, kind)
    if player and player.Parent == Players then
        notifyRemote:FireClient(player, tostring(message), tostring(kind or "Info"))
    end
end

local WorldBuilder = require(Shared:WaitForChild("WorldBuilder"))
local worldBuilder = WorldBuilder.new({
    Config = Config,
    World = world,
    BasesFolder = basesFolder,
    DecorationFolder = decorationFolder,
    Rng = rng,
    TreadmillStrips = treadmillStrips,
    Lighting = Lighting,
})
local createPart = worldBuilder.CreatePart
local addBall = worldBuilder.AddBall
local addCylinder = worldBuilder.AddCylinder
local addLabel = worldBuilder.AddLabel
local createTreadmill = worldBuilder.CreateTreadmill
local createBase = worldBuilder.CreateBase
local buildScenery = worldBuilder.BuildScenery

local AnimalFactory = require(Shared:WaitForChild("AnimalFactory"))
local animalFactory = AnimalFactory.new({
    Config = Config,
    CreatePart = createPart,
    AddBall = addBall,
})
local createAnimalModel = animalFactory.CreateAnimalModel
local stageFor = animalFactory.StageFor

local function incomeFor(animal, now, rebirths)
    local spec = Catalog.Get(animal.Id)
    if not spec then
        return 0
    end
    local _, stageIndex = stageFor(animal, now)
    local baseIncome = Rules.AnimalIncome(spec.Income, stageIndex, Config)
    return math.floor(baseIncome * Rules.RebirthIncomeMultiplier(rebirths or 0, Config))
end

local function profileIncome(profile, now)
    local total = 0
    for _, animal in ipairs(profile.BarnAnimals) do
        total += incomeFor(animal, now, profile.Rebirths)
    end
    return total
end

local function offlineIncome(profile, fromTime, toTime)
    local total = 0
    for _, animal in ipairs(profile.BarnAnimals) do
        local spec = Catalog.Get(animal.Id)
        if spec then
            local bornAt = tonumber(animal.BornAt) or toTime
            local startAge = math.max(0, fromTime - bornAt)
            local endAge = math.max(0, toTime - bornAt)
            for index, stage in ipairs(Config.EvolutionStages) do
                local nextStage = Config.EvolutionStages[index + 1]
                local segmentStart = math.max(startAge, stage.AgeSeconds)
                local segmentEnd = math.min(endAge, nextStage and nextStage.AgeSeconds or endAge)
                if segmentEnd > segmentStart then
                    total += Rules.AnimalIncome(spec.Income, index, Config) * Rules.RebirthIncomeMultiplier(profile.Rebirths, Config) * (segmentEnd - segmentStart)
                end
            end
        end
    end
    return math.floor(total)
end

local ProfileStore = require(Shared:WaitForChild("ProfileStore"))
local profileStore = ProfileStore.new({
    Config = Config,
    Catalog = Catalog,
    Rules = Rules,
    DataStore = Store,
    Profiles = profiles,
    SessionTokens = sessionTokens,
    SaveInProgress = saveInProgress,
    Leaving = leaving,
    Notify = notify,
    SessionLeaseSeconds = SESSION_LEASE_SECONDS,
})
local defaultProfile = profileStore.DefaultProfile
local sanitizeProfile = profileStore.SanitizeProfile
local snapshot = profileStore.Snapshot
local acquireSession = profileStore.AcquireSession
local saveProfile = profileStore.SaveProfile
local releaseSession = profileStore.ReleaseSession
local abandonSession = profileStore.AbandonSession

local function allowAction(player, action, cooldown)
    local now = os.clock()
    local actions = actionCooldowns[player]
    if not actions then
        actions = {}
        actionCooldowns[player] = actions
    end
    local previous = actions[action] or 0
    if now - previous < cooldown then
        return false
    end
    actions[action] = now
    return true
end

local function updatePlayerAttributes(player)
    local profile = profiles[player]
    if not profile then
        return
    end
    local now = os.time()
    player:SetAttribute("Coins", profile.Coins)
    player:SetAttribute("SpeedLevel", profile.Speed)
    player:SetAttribute("TreadmillLevel", profile.TreadmillLevel)
    player:SetAttribute("TreadmillGain", Rules.TrainingGain(profile.TreadmillLevel, Config))
    player:SetAttribute("BarnBank", profile.BarnBank)
    player:SetAttribute("BarnAnimalCount", #profile.BarnAnimals)
    player:SetAttribute("BarnCapacity", Config.BaseSlots)
    player:SetAttribute("BarnIncomeRate", profileIncome(profile, now))
    player:SetAttribute("Rebirths", profile.Rebirths or 0)
    player:SetAttribute("RebirthMultiplier", Rules.RebirthIncomeMultiplier(profile.Rebirths, Config))
    player:SetAttribute("RebirthCost", Rules.RebirthCost(profile.Rebirths, Config) or 0)
    player:SetAttribute("RebirthRequiredCoins", Config.RebirthCoinsRequired)
    player:SetAttribute("RebirthRequiredSpeed", Rules.RebirthSpeedRequirement(Config) or Config.MaxSpeedPoints)
    player:SetAttribute("DailyStreak", profile.DailyStreak or 0)
    player:SetAttribute("DailyClaimAvailable", (profile.LastDailyClaimDay or 0) < math.floor(os.time() / 86400))
    player:SetAttribute("TotalCaptured", profile.TotalCaptured or 0)
    player:SetAttribute("TotalDeposited", profile.TotalDeposited or 0)
    player:SetAttribute("QuestClaimsJson", HttpService:JSONEncode(profile.QuestClaims or {}))
    player:SetAttribute("TreadmillUpgradeCost", Rules.UpgradeCost(profile.TreadmillLevel, Config) or 0)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    local function setLeaderstat(name, value)
        local item = leaderstats:FindFirstChild(name)
        if not item or not item:IsA("IntValue") then
            if item then item:Destroy() end
            item = Instance.new("IntValue")
            item.Name = name
            item.Parent = leaderstats
        end
        item.Value = math.floor(math.clamp(value, 0, 2147483647))
    end
    setLeaderstat("Coins", profile.Coins)
    setLeaderstat("Speed", profile.Speed)
    setLeaderstat("Rebirths", profile.Rebirths or 0)
    setLeaderstat("Barn Animals", #profile.BarnAnimals)
    local summary = {}
    local multiplier = Rules.RebirthIncomeMultiplier(profile.Rebirths, Config)
    for index, animal in ipairs(profile.BarnAnimals) do
        local spec = Catalog.Get(animal.Id)
        local stage, stageIndex = stageFor(animal, now)
        if spec and stage then
            local rate = math.floor(Rules.AnimalIncome(spec.Income, stageIndex, Config) * multiplier)
            table.insert(summary, tostring(index) .. ". " .. spec.Name .. " • " .. stage.DisplayName .. " • +" .. tostring(rate) .. "/s")
        end
    end
    player:SetAttribute("BarnSummary", #summary > 0 and table.concat(summary, "\n") or "Seu celeiro está vazio. Roube um filhote e leve-o ao celeiro.")
    player:SetAttribute("CarryingAnimal", carried[player] ~= nil)
    local baseSpeed = Rules.MoveSpeed(profile.Speed, Config)
    local carry = carried[player]
    if carry then
        local speed = Rules.CarrySpeed(baseSpeed, carry.Spec.Weight, Config)
        baseSpeed = speed or Config.CarrySpeedMinimum
    end
    player:SetAttribute("EffectiveWalkSpeed", baseSpeed)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = baseSpeed
    end
end

local function clearCarry(player)
    local carry = carried[player]
    if not carry then
        return
    end
    carried[player] = nil
    if carry.Model and carry.Model.Parent then
        carry.Model:Destroy()
    end
    player:SetAttribute("CarryingAnimal", false)
    updatePlayerAttributes(player)
end

local function renderBarn(player)
    local profile = profiles[player]
    local base = playerBases[player]
    if not profile or not base then return end
    local display = base:FindFirstChild("StoredAnimals")
    if not display then return end
    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^StoredAnimal_") then
            child:Destroy()
        end
    end
    local slots = {}
    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("BasePart") and child.Name:match("^Slot_") then
            table.insert(slots, child)
        end
    end
    table.sort(slots, function(a, b)
        return (a:GetAttribute("SlotIndex") or 0) < (b:GetAttribute("SlotIndex") or 0)
    end)
    local now = os.time()
    for index, slot in ipairs(slots) do
        local animal = profile.BarnAnimals[index]
        local gui = slot:FindFirstChild("AnimalLabel")
        local title = gui and gui:FindFirstChild("Title", true)
        local subtitle = gui and gui:FindFirstChild("Subtitle", true)
        if animal then
            local spec = Catalog.Get(animal.Id)
            local stage, stageIndex = stageFor(animal, now)
            if spec then
                local model = createAnimalModel(spec, stage.Name, slot.Position + Vector3.new(0, 0.05, 0), false)
                model.Name = "StoredAnimal_" .. tostring(index)
                model.Parent = display
                local income = math.floor(Rules.AnimalIncome(spec.Income, stageIndex, Config) * Rules.RebirthIncomeMultiplier(profile.Rebirths, Config))
                addLabel(model.PrimaryPart, spec.Name, stage.DisplayName .. " • +" .. tostring(income) .. "/s", spec.Accent, true, 18, 1.2)
                slot.Color = spec.Color
                slot.Transparency = 0.25
                if title then title.Text = spec.Name end
                if subtitle then subtitle.Text = stage.DisplayName .. " • +" .. tostring(income) .. "/s" end
            end
        else
            slot.Color = Color3.fromRGB(235, 222, 183)
            slot.Transparency = 0
            if title then title.Text = "ESPAÇO " .. tostring(index) end
            if subtitle then subtitle.Text = "VAZIO" end
        end
    end
    updatePlayerAttributes(player)
end

local function assignBase(player)
    for _, base in ipairs(basesFolder:GetChildren()) do
        if base:GetAttribute("OwnerUserId") == 0 then
            base:SetAttribute("OwnerUserId", player.UserId)
            local sign = base:FindFirstChild("BarnSign")
            if sign then
                local oldGui = sign:FindFirstChild("AnimalLabel")
                if oldGui then oldGui:Destroy() end
                addLabel(sign, player.DisplayName .. "'S FARM", "SEUS ANIMAIS CRESCEM AQUI", Color3.fromRGB(255, 218, 105), false, 28, 1.7)
            end
            playerBases[player] = base
            local spawn = base:FindFirstChild("Floor")
            if spawn and player.Character then
                player.Character:PivotTo(CFrame.new(spawn.Position + Vector3.new(0, 4, 0)))
            end
            return base
        end
    end
    return nil
end

local function releaseBase(player)
    local base = playerBases[player]
    if base then
        base:SetAttribute("OwnerUserId", 0)
        playerBases[player] = nil
        local sign = base:FindFirstChild("BarnSign")
        if sign then
            local gui = sign:FindFirstChild("AnimalLabel")
            if gui then gui:Destroy() end
            addLabel(sign, "SUA FAZENDA", "Bebês crescem aqui", Color3.fromRGB(255, 218, 105), false, 28, 1.7)
        end
    end
end

local function spawnWild(spec)
    local biome
    for _, entry in ipairs(Config.Biomes) do
        if entry.Id == spec.Biome then biome = entry break end
    end
    if not biome then return end
    local position = Vector3.new(biome.CenterX + rng:NextNumber(-28, 28), -0.12, rng:NextNumber(-20, 20))
    local model = createAnimalModel(spec, "Baby", position, false)
    model.Parent = wildlifeFolder
    local root = model.PrimaryPart
    addLabel(root, spec.Name, spec.Rarity .. " • $" .. tostring(spec.Income) .. "/s base", spec.Accent, true, 18, 1.2)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.Name = "StealPrompt"
    prompt.ActionText = "ROUBAR"
    prompt.ObjectText = spec.Name .. " • BEBÊ"
    prompt.HoldDuration = Config.CaptureHoldDuration
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt:SetAttribute("InteractionType", "StealAnimal")
    prompt:SetAttribute("AnimalId", spec.Id)
    prompt.Parent = root
    wildRecords[model] = spec
end

local function makeGuardian(spec, biome)
    local guardianSide = biome.Phase % 2 == 0 and 1 or -1
    local position = Vector3.new(biome.CenterX - 50, -0.12, guardianSide * 23)
    local model = createAnimalModel(spec, "Adult", position, true)
    model.Name = "GuardianParent_" .. biome.Id
    model:SetAttribute("GuardianBiome", biome.Id)
    model:SetAttribute("ThreatLevel", biome.Phase)
    model.Parent = guardiansFolder
    local head = model:FindFirstChild("Head") or model:FindFirstChild("SwanHead")
    addLabel(head or model.PrimaryPart, "PAI PROTETOR: " .. string.upper(spec.Name), "GUARDIÃO • FASE " .. tostring(biome.Phase) .. " • PROTEGE OS OVOS", biome.Accent, false, 58, 1.4)
    local highlight = Instance.new("Highlight")
    highlight.Name = "GuardianRim"
    highlight.Adornee = model
    highlight.FillColor = biome.Accent
    highlight.FillTransparency = 0.78
    highlight.OutlineColor = biome.Accent
    highlight.OutlineTransparency = 0.04
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model
    for shard = 1, 8 do
        local angle = math.rad(shard * 45)
        local auraPosition = position + Vector3.new(math.cos(angle) * 10.5, 0.45, math.sin(angle) * 10.5)
        local aura = addBall(model, "GuardianAuraShard", Vector3.new(1.1, 0.2, 0.2), auraPosition, biome.Accent, Enum.Material.Neon)
        aura.CFrame = CFrame.new(auraPosition) * CFrame.Angles(0, -angle, math.rad(25))
        aura.CanTouch = false
        aura.CanQuery = false
    end
    addBall(model, "GuardianCrownGem", Vector3.new(1.9, 1.9, 1.9), position + Vector3.new(0, 16.4, 0), biome.Accent, Enum.Material.Neon)
    table.insert(guardians, { Model = model, Home = CFrame.new(position), Biome = biome, Spec = spec, Speed = math.min(Config.GuardianSpeed, 12 + biome.Phase * 1.1) })
end

local function loadProfile(player)
    local raw, reason = acquireSession(player)
    if not raw then
        if reason == "locked" then
            notify(player, "Seu perfil ainda está ativo em outro servidor. Aguarde alguns segundos e tente novamente.", "Warning")
            player:Kick("Seu perfil ainda está ativo em outro servidor. Entre novamente em instantes.")
        else
            notify(player, "Não foi possível carregar seu salvamento. Tente novamente.", "Error")
            player:Kick("Não foi possível carregar seus dados com segurança. Tente entrar novamente.")
        end
        return false
    end
    if player.Parent ~= Players then
        releaseSession(player)
        return false
    end
    local profile = sanitizeProfile(raw)
    profile.Persistent = true
    local now = os.time()
    local elapsed = math.clamp(now - profile.LastIncomeAt, 0, Config.OfflineIncomeCapSeconds)
    local earnedOffline = offlineIncome(profile, now - elapsed, now)
    profile.BarnBank = math.clamp(profile.BarnBank + earnedOffline, 0, Config.CoinsLimit)
    profile.LastIncomeAt = now
    if player.Parent ~= Players then
        profiles[player] = profile
        saveProfile(player)
        releaseSession(player)
        profiles[player] = nil
        return false
    end
    profiles[player] = profile
    updatePlayerAttributes(player)
    if earnedOffline > 0 then
        notify(player, "Seus animais renderam +" .. tostring(earnedOffline) .. " moedas enquanto você estava fora.", "Success")
    end
    return true
end

local function captureAnimal(player, prompt)
    if not profiles[player] or leaving[player] or carried[player] or player:GetAttribute("RebirthInProgress") then
        if carried[player] then
            notify(player, "Você só pode carregar um animal por vez.", "Warning")
        end
        return
    end
    local model = prompt.Parent and prompt.Parent:FindFirstAncestorOfClass("Model")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local animalRoot = model and model.PrimaryPart
    if not root or not animalRoot or (root.Position - animalRoot.Position).Magnitude > 12 then
        return
    end
    local spec = model and wildRecords[model]
    if not spec or not model:IsDescendantOf(wildlifeFolder) then
        return
    end
    wildRecords[model] = nil
    carried[player] = { Spec = spec, Model = model }
    local profile = profiles[player]
    if profile then
        profile.TotalCaptured = math.min(2147483647, (profile.TotalCaptured or 0) + 1)
    end
    prompt.Enabled = false
    model.Parent = world
    task.delay(Config.AnimalRespawnSeconds, function()
        spawnWild(spec)
    end)
    player:SetAttribute("CarryingAnimal", true)
    updatePlayerAttributes(player)
    notify(player, "Você roubou " .. spec.Name .. "! Corra para sua fazenda antes que o guardião alcance você.", "Success")
end

local function depositAnimal(player, prompt)
    local triggerPart = prompt.Parent
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not triggerPart or not triggerPart:IsA("BasePart") or not root
        or (root.Position - triggerPart.Position).Magnitude > 15 then
        return
    end
    local base = triggerPart:FindFirstAncestorOfClass("Model")
    if not profiles[player] or leaving[player] or not base
        or playerBases[player] ~= base or base:GetAttribute("OwnerUserId") ~= player.UserId then
        return
    end
    local carry = carried[player]
    if not carry then
        notify(player, "Roube um animal selvagem primeiro.", "Warning")
        return
    end
    local profile = profiles[player]
    if #profile.BarnAnimals >= Config.BaseSlots then
        notify(player, "Seu celeiro está cheio.", "Warning")
        return
    end
    local animal = {
        Uid = tostring(player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(#profile.BarnAnimals + 1),
        Id = carry.Spec.Id,
        BornAt = os.time(),
        Stage = "Baby",
    }
    table.insert(profile.BarnAnimals, animal)
    profile.TotalDeposited = math.min(2147483647, (profile.TotalDeposited or 0) + 1)
    carried[player] = nil
    if carry.Model and carry.Model.Parent then
        carry.Model:Destroy()
    end
    player:SetAttribute("CarryingAnimal", false)
    updatePlayerAttributes(player)
    renderBarn(player)
    notify(player, carry.Spec.Name .. " chegou em casa como bebê! Cada evolução aumenta sua renda em 50%.", "Success")
end

local function collectIncome(player, prompt)
    local triggerPart = prompt.Parent
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not triggerPart or not triggerPart:IsA("BasePart") or not root
        or (root.Position - triggerPart.Position).Magnitude > 15 then
        return
    end
    local base = triggerPart:FindFirstAncestorOfClass("Model")
    if not profiles[player] or leaving[player] or not base
        or playerBases[player] ~= base or base:GetAttribute("OwnerUserId") ~= player.UserId then
        return
    end
    local profile = profiles[player]
    local amount = math.floor(profile.BarnBank)
    if amount <= 0 then
        notify(player, "O banco do celeiro está vazio. Seus animais continuam produzindo moedas.", "Info")
        return
    end
    local credited = math.min(amount, Config.CoinsLimit - profile.Coins)
    if credited <= 0 then
        notify(player, "Sua carteira atingiu o limite de moedas.", "Warning")
        return
    end
    profile.Coins += credited
    profile.BarnBank -= credited
    updatePlayerAttributes(player)
    notify(player, "Você coletou +" .. tostring(credited) .. " moedas!", "Success")
end

local function upgradeTreadmill(player, prompt)
    local profile = profiles[player]
    if not profile or leaving[player] then
        return
    end

    if prompt then
        local current = prompt.Parent
        local ownerBase
        while current and current ~= basesFolder do
            if current:IsA("Model") and current.Parent == basesFolder then
                ownerBase = current
                break
            end
            current = current.Parent
        end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not ownerBase or ownerBase ~= playerBases[player] or ownerBase:GetAttribute("OwnerUserId") ~= player.UserId
            or not root or (root.Position - prompt.Parent.Position).Magnitude > 15 then
            return
        end
    end

    local cost = Rules.UpgradeCost(profile.TreadmillLevel, Config)
    if not cost then
        notify(player, "Sua esteira já está no nível máximo.", "Info")
        return
    end
    if profile.Coins < cost then
        notify(player, "Você precisa de " .. tostring(cost) .. " moedas para melhorar a esteira.", "Warning")
        return
    end

    profile.Coins -= cost
    profile.TreadmillLevel += 1
    updatePlayerAttributes(player)
    notify(player, "Esteira nível " .. tostring(profile.TreadmillLevel) .. "! Agora você ganha +" .. tostring(Rules.TrainingGain(profile.TreadmillLevel, Config)) .. " de velocidade por segundo correndo nela.", "Success")
end

local function onPrompt(prompt, player)
    if not profiles[player] or leaving[player] or rebirthInProgress[player] or progressionWriteInProgress[player] then
        return
    end
    local interaction = prompt:GetAttribute("InteractionType")
    if interaction ~= "StealAnimal" and interaction ~= "DepositAnimal" and interaction ~= "CollectIncome" and interaction ~= "UpgradeTreadmill" then
        return
    end
    if not allowAction(player, interaction, 0.45) then
        return
    end
    if interaction == "StealAnimal" then
        captureAnimal(player, prompt)
    elseif interaction == "DepositAnimal" then
        depositAnimal(player, prompt)
    elseif interaction == "CollectIncome" then
        collectIncome(player, prompt)
    elseif interaction == "UpgradeTreadmill" then
        upgradeTreadmill(player, prompt)
    end
end

local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local ok, err = pcall(onPrompt, prompt, player)
    if not ok then
        warn("[StealAnAnimal] Interaction failed: " .. tostring(err))
        notify(player, "A interação falhou com segurança. Tente novamente.", "Error")
    end
end)

upgradeRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or rebirthInProgress[player] or progressionWriteInProgress[player] or not allowAction(player, "upgradeRemote", 0.8) then return end
    local base = playerBases[player]
    local treadmill = base and base:FindFirstChild("Treadmill")
    local console = treadmill and treadmill:FindFirstChild("TreadmillConsole")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not console or not root or (root.Position - console.Position).Magnitude > 15 then
        notify(player, "Vá até a esteira da sua própria fazenda para comprar a melhoria.", "Warning")
        return
    end
    upgradeTreadmill(player, nil)
end)

collectRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or rebirthInProgress[player] or progressionWriteInProgress[player] or not allowAction(player, "collectRemote", 0.6) then return end
    local base = playerBases[player]
    local pad = base and base:FindFirstChild("CollectPad")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not pad or not root or (root.Position - pad.Position).Magnitude > 14 then
        notify(player, "Fique perto da área de coleta da sua própria fazenda.", "Warning")
        return
    end
    collectIncome(player, { Parent = pad })
end)

local function requestRebirth(player)
    local profile = profiles[player]
    if not profile or leaving[player] or rebirthInProgress[player] then
        return
    end
    if carried[player] then
        notify(player, "Leve o animal roubado ao celeiro ou escape primeiro. O renascimento não pode descartar um animal carregado.", "Warning")
        return
    end
    if profile.Persistent == false or not sessionTokens[player] then
        notify(player, "O salvamento não está seguro neste momento. Entre novamente antes de renascer.", "Error")
        return
    end
    local cost = Rules.RebirthCost(profile.Rebirths, Config)
    local requiredSpeed = Rules.RebirthSpeedRequirement(Config) or Config.MaxSpeedPoints
    if not cost then
        notify(player, "Você já alcançou o máximo de renascimentos.", "Info")
        return
    end
    if profile.Speed < requiredSpeed or profile.Coins < cost then
        notify(player, "Renascimento exige velocidade máxima (" .. tostring(requiredSpeed) .. " pontos) e " .. tostring(cost) .. " moedas.", "Warning")
        return
    end
    if progressionWriteInProgress[player] then
        notify(player, "Seu progresso está sendo salvo. Tente novamente.", "Warning")
        return
    end
    if not allowAction(player, "rebirth", 2) then
        return
    end

    rebirthInProgress[player] = true
    player:SetAttribute("RebirthInProgress", true)
    local previous = {
        Coins = profile.Coins,
        Speed = profile.Speed,
        TreadmillLevel = profile.TreadmillLevel,
        Rebirths = profile.Rebirths,
        BarnBank = profile.BarnBank,
        BarnAnimals = profile.BarnAnimals,
        LastIncomeAt = profile.LastIncomeAt,
        Persistent = profile.Persistent,
    }

    profile.Coins = 0
    profile.Speed = 0
    profile.Rebirths += 1
    updatePlayerAttributes(player)
    renderBarn(player)

    local saved = saveProfile(player)
    if not saved then
        local persistenceState = profile.Persistent
        profile.Coins = previous.Coins
        profile.Speed = previous.Speed
        profile.TreadmillLevel = previous.TreadmillLevel
        profile.Rebirths = previous.Rebirths
        profile.BarnBank = previous.BarnBank
        profile.BarnAnimals = previous.BarnAnimals
        profile.LastIncomeAt = previous.LastIncomeAt
        if persistenceState == false then
            profile.Persistent = false
        else
            profile.Persistent = previous.Persistent
        end
        rebirthInProgress[player] = nil
        player:SetAttribute("RebirthInProgress", false)
        updatePlayerAttributes(player)
        renderBarn(player)
        if player.Parent == Players and profile.Persistent ~= false then
            notify(player, "Não foi possível confirmar o salvamento. Seu progresso foi restaurado; tente novamente.", "Error")
        end
        return
    end

    rebirthInProgress[player] = nil
    player:SetAttribute("RebirthInProgress", false)
    local base = playerBases[player]
    local floor = base and base:FindFirstChild("Floor")
    local character = player.Character
    if floor and character and character.Parent then
        character:PivotTo(CFrame.new(floor.Position + Vector3.new(0, 4, 0)))
    end
    notify(player, "RENASCIMENTO " .. tostring(profile.Rebirths) .. " concluído! Bônus permanente de +10% de renda por renascimento. Moedas e velocidade foram reiniciadas; animais, banco e esteira foram preservados.", "Success")
end

rebirthRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or not allowAction(player, "rebirthRemote", 0.5) then
        return
    end
    local ok, err = pcall(requestRebirth, player)
    if not ok then
        rebirthInProgress[player] = nil
        player:SetAttribute("RebirthInProgress", false)
        warn("[StealAnAnimal] Rebirth failed: " .. tostring(err))
        notify(player, "O renascimento falhou com segurança. Seu progresso não deve ser perdido; tente novamente.", "Error")
    end
end)


local function copyProgressionSnapshot(profile)
    local data = snapshot(profile)
    data.Persistent = profile.Persistent
    return data
end

local function restoreProgressionSnapshot(profile, data)
    profile.Coins = data.Coins
    profile.Speed = data.Speed
    profile.TreadmillLevel = data.TreadmillLevel
    profile.Rebirths = data.Rebirths
    profile.BarnBank = data.BarnBank
    profile.LastIncomeAt = data.LastIncomeAt
    profile.TotalCaptured = data.TotalCaptured or 0
    profile.TotalDeposited = data.TotalDeposited or 0
    profile.LastDailyClaimDay = data.LastDailyClaimDay or 0
    profile.DailyStreak = data.DailyStreak or 0
    profile.RedeemedCodes = table.clone(data.RedeemedCodes or {})
    profile.QuestClaims = table.clone(data.QuestClaims or {})
    profile.BarnAnimals = {}
    for _, animal in ipairs(data.BarnAnimals or {}) do
        table.insert(profile.BarnAnimals, { Uid = animal.Uid, Id = animal.Id, BornAt = animal.BornAt })
    end
    if profile.Persistent ~= false then
        profile.Persistent = data.Persistent
    end
end

local function runProgressionWrite(player, mutate)
    local profile = profiles[player]
    if not profile or leaving[player] or profile.Persistent == false or not sessionTokens[player] then
        return false, "profile-not-loaded"
    end
    if progressionWriteInProgress[player] or rebirthInProgress[player] or saveInProgress[player] then
        return false, "profile-busy"
    end
    progressionWriteInProgress[player] = true
    player:SetAttribute("ProgressionWriteInProgress", true)
    local previous = copyProgressionSnapshot(profile)
    local ok, accepted, value, extra = pcall(mutate, profile)
    if not ok or not accepted then
        restoreProgressionSnapshot(profile, previous)
        progressionWriteInProgress[player] = nil
        player:SetAttribute("ProgressionWriteInProgress", false)
        updatePlayerAttributes(player)
        if not ok then
            warn("[StealAnAnimal] Progression write failed: " .. tostring(accepted))
            return false, "datastore-error"
        end
        return false, value or "rejected"
    end
    updatePlayerAttributes(player)
    local saved = saveProfile(player)
    if not saved then
        restoreProgressionSnapshot(profile, previous)
        progressionWriteInProgress[player] = nil
        player:SetAttribute("ProgressionWriteInProgress", false)
        updatePlayerAttributes(player)
        renderBarn(player)
        return false, "datastore-error"
    end
    progressionWriteInProgress[player] = nil
    player:SetAttribute("ProgressionWriteInProgress", false)
    updatePlayerAttributes(player)
    renderBarn(player)
    return true, value, extra
end

dailyRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] or not allowAction(player, "daily", 1.5) then return end
    local today = math.floor(os.time() / 86400)
    local ok, value, streak = runProgressionWrite(player, function(profile)
        if (profile.LastDailyClaimDay or 0) >= today then return false, "already-claimed" end
        local nextStreak = (profile.LastDailyClaimDay or 0) == today - 1 and math.min((profile.DailyStreak or 0) + 1, 7) or 1
        local reward = 500 + (nextStreak - 1) * 250
        profile.Coins = math.clamp(profile.Coins + reward, 0, Config.CoinsLimit)
        profile.LastDailyClaimDay = today
        profile.DailyStreak = nextStreak
        return true, reward, nextStreak
    end)
    if ok then
        notify(player, "Recompensa diária: +" .. tostring(value) .. " moedas. Sequência " .. tostring(streak) .. "/7.", "Success")
    else
        local messages = {
            ["already-claimed"] = "Você já coletou a recompensa de hoje.",
            ["profile-busy"] = "Seu progresso está sendo salvo. Tente novamente.",
            ["datastore-error"] = "A recompensa não foi salva; nada foi consumido.",
        }
        notify(player, messages[value] or "Recompensa diária indisponível.", "Warning")
    end
end)

codeRemote.OnServerEvent:Connect(function(player, rawCode)
    if not profiles[player] or leaving[player] or not allowAction(player, "code", 1.5) then return end
    if type(rawCode) ~= "string" or #rawCode > 48 then
        notify(player, "Digite um código válido.", "Warning")
        return
    end
    local code = string.upper(string.gsub(rawCode, "%s+", ""))
    local reward = DAILY_CODES[code]
    if not reward then
        notify(player, "Código inválido ou expirado.", "Warning")
        return
    end
    local ok, value = runProgressionWrite(player, function(profile)
        if profile.RedeemedCodes[code] then return false, "already-redeemed" end
        profile.RedeemedCodes[code] = os.time()
        profile.Coins = math.clamp(profile.Coins + reward, 0, Config.CoinsLimit)
        return true, reward
    end)
    if ok then
        notify(player, "Código " .. code .. " resgatado: +" .. tostring(value) .. " moedas.", "Success")
    else
        local messages = {
            ["already-redeemed"] = "Esse código já foi usado nesta conta.",
            ["profile-busy"] = "Seu progresso está sendo salvo. Tente novamente.",
            ["datastore-error"] = "Não foi possível salvar o código; ele continua disponível.",
        }
        notify(player, messages[value] or "Não foi possível resgatar o código.", "Warning")
    end
end)

questRemote.OnServerEvent:Connect(function(player, questId)
    if not profiles[player] or leaving[player] or type(questId) ~= "string" or not allowAction(player, "quest", 1.5) then return end
    local quest = QUESTS[questId]
    if not quest then return end
    local ok, value = runProgressionWrite(player, function(profile)
        if profile.QuestClaims[questId] then return false, "already-claimed" end
        if not quest.Requirement(profile) then return false, "requirements" end
        profile.QuestClaims[questId] = os.time()
        profile.Coins = math.clamp(profile.Coins + quest.Reward, 0, Config.CoinsLimit)
        return true, quest.Reward
    end)
    if ok then
        notify(player, "Missão concluída: +" .. tostring(value) .. " moedas.", "Success")
    else
        local messages = {
            ["already-claimed"] = "Essa missão já foi resgatada.",
            ["requirements"] = "Complete o objetivo antes de resgatar a recompensa.",
            ["profile-busy"] = "Seu progresso está sendo salvo. Tente novamente.",
            ["datastore-error"] = "A recompensa não foi salva; tente novamente.",
        }
        notify(player, messages[value] or "Missão indisponível.", "Warning")
    end
end)

local function mapSummary()
    local partCount = 0
    for _, item in ipairs(world:GetDescendants()) do
        if item:IsA("BasePart") then partCount += 1 end
    end
    local occupiedFarms = 0
    for _, base in ipairs(basesFolder:GetChildren()) do
        if base:GetAttribute("OwnerUserId") ~= 0 then occupiedFarms += 1 end
    end
    local biomes = 0
    for _, biome in ipairs(Config.Biomes) do
        if world:FindFirstChild(biome.Id .. "Ground", true) then biomes += 1 end
    end
    return {
        Parts = partCount,
        Farms = #basesFolder:GetChildren(),
        OccupiedFarms = occupiedFarms,
        Biomes = biomes,
        WildAnimals = #wildlifeFolder:GetChildren(),
        Guardians = #guardiansFolder:GetChildren(),
    }
end

mapBotRemote.OnServerEvent:Connect(function(player)
    if not profiles[player] or leaving[player] then return end
    local now = os.clock()
    if now - (mapBotCooldowns[player] or 0) < 20 then
        notify(player, "O MapBot pode testar novamente em 20 segundos.", "Warning")
        return
    end
    mapBotCooldowns[player] = now
    local base = playerBases[player]
    local pad = base and base:FindFirstChild("CollectPad")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local summary = mapSummary()
    local pathStatus = "SEM PERSONAGEM"
    local waypointCount = 0
    if root and pad then
        local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local success, err = pcall(function()
            path:ComputeAsync(root.Position, pad.Position + Vector3.new(0, 3, 0))
        end)
        if success then
            pathStatus = tostring(path.Status)
            waypointCount = #path:GetWaypoints()
        else
            pathStatus = "ERRO: " .. tostring(err)
        end
    end
    local report = table.concat({
        "MAPBOT • DIAGNÓSTICO",
        "Mapa: " .. ((summary.Parts > 300 and summary.Farms == 8 and summary.Biomes == 8) and "PASSOU" or "INCOMPLETO"),
        "Peças: " .. tostring(summary.Parts),
        "Fazendas: " .. tostring(summary.Farms) .. " (ocupadas " .. tostring(summary.OccupiedFarms) .. ")",
        "Biomas: " .. tostring(summary.Biomes) .. "/8",
        "Animais selvagens: " .. tostring(summary.WildAnimals),
        "Guardiões: " .. tostring(summary.Guardians) .. "/8",
        "Rota até o pad da fazenda: " .. pathStatus,
        "Pontos de caminho: " .. tostring(waypointCount),
    }, "\n")
    mapBotReportRemote:FireClient(player, report, pathStatus == "Success" and "Success" or "Warning")
end)

buildScenery()
for index = 1, 8 do
    createBase(index)
end
for _, spec in ipairs(Catalog.All()) do
    spawnWild(spec)
end
for _, biome in ipairs(Config.Biomes) do
    local options = Catalog.ForBiome(biome.Id)
    if #options > 0 then
        makeGuardian(options[#options], biome)
    end
end

if previewWorld and previewWorld.Parent then
    previewWorld:Destroy()
end

local function characterAdded(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.WalkSpeed = Config.BaseWalkSpeed
        humanoid.Died:Connect(function()
            if carried[player] then
                local root = character:FindFirstChild("HumanoidRootPart")
                clearCarry(player)
                notify(player, "O animal escapou quando você caiu. Tente roubá-lo novamente.", "Warning")
            end
        end)
    end
    task.wait(0.25)
    if player.Parent ~= Players then return end
    local base = playerBases[player]
    local floor = base and base:FindFirstChild("Floor")
    if floor and character.Parent then
        character:PivotTo(CFrame.new(floor.Position + Vector3.new(0, 4, 0)))
    end
    updatePlayerAttributes(player)
end

local function playerAdded(player)
    if player.Parent ~= Players or playerSetupDone[player] then return end
    playerSetupDone[player] = true
    player:SetAttribute("ProfileLoaded", false)
    player:SetAttribute("CarryingAnimal", false)
    player:SetAttribute("RebirthInProgress", false)
    player:SetAttribute("ProgressionWriteInProgress", false)
    local base = assignBase(player)
    if not base then
        player:Kick("Todas as fazendas estão ocupadas. Entre em outro servidor.")
        return
    end
    player.CharacterAdded:Connect(function(character)
        task.spawn(characterAdded, player, character)
    end)
    task.spawn(function()
        local loaded = loadProfile(player)
        if not loaded or player.Parent ~= Players or not profiles[player] then return end
        player:SetAttribute("ProfileLoaded", true)
        renderBarn(player)
        notify(player, "Bem-vindo! Roube animais bebês, fuja dos guardiões e leve-os ao celeiro. Eles crescem até adultos e rendem cada vez mais.", "Success")
        if player.Character then task.spawn(characterAdded, player, player.Character) end
    end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
    leaving[player] = true
    local saved = saveProfile(player)
    if saved then
        releaseSession(player)
    else
        abandonSession(player)
    end
    clearCarry(player)
    profiles[player] = nil
    actionCooldowns[player] = nil
    rebirthInProgress[player] = nil
    progressionWriteInProgress[player] = nil
    mapBotCooldowns[player] = nil
    trainingNoticeAt[player] = nil
    releaseBase(player)
    playerSetupDone[player] = nil
    leaving[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(playerAdded, player)
end

local accumulator = 0
local incomeAccumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
    accumulator += deltaTime
    incomeAccumulator += deltaTime
    treadmillAnimationAccumulator += deltaTime
    if treadmillAnimationAccumulator >= 0.1 then
        treadmillAnimationAccumulator = 0
        local elapsed = os.clock() * Config.TreadmillBeltSpeed
        for _, entry in ipairs(treadmillStrips) do
            local part = entry.Part
            if part and part.Parent then
                local offset = ((entry.Phase + elapsed) % entry.Length) - entry.Length / 2
                part.Position = Vector3.new(entry.Origin.X, part.Position.Y, entry.Origin.Z + offset)
            end
        end
    end
    for player, carry in pairs(carried) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or player.Parent ~= Players then
            clearCarry(player)
        elseif carry.Model and carry.Model.Parent then
            carry.Model:PivotTo(root.CFrame * CFrame.new(0, 1.7, 2.1))
        end
    end

    if accumulator >= Config.GuardianThinkSeconds then
        accumulator = 0
        for _, guardian in ipairs(guardians) do
            local model = guardian.Model
            if model and model.Parent and model.PrimaryPart then
                local targetRoot
                local targetPlayer
                local nearest = Config.GuardianNoticeDistance
                for player in pairs(carried) do
                    local character = player.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local distance = (root.Position - model.PrimaryPart.Position).Magnitude
                        if distance < nearest then
                            nearest = distance
                            targetRoot = root
                            targetPlayer = player
                        end
                    end
                end
                if targetRoot and targetPlayer then
                    if nearest <= Config.GuardianCatchDistance then
                        clearCarry(targetPlayer)
                        notify(targetPlayer, "O guardião alcançou você! O animal escapou.", "Error")
                    else
                        local current = model:GetPivot()
                        local destination = Vector3.new(targetRoot.Position.X, current.Position.Y, targetRoot.Position.Z)
                        local direction = destination - current.Position
                        if direction.Magnitude > 0.1 then
                            local step = math.min(direction.Magnitude, (guardian.Speed or Config.GuardianSpeed) * Config.GuardianThinkSeconds)
                            local nextPosition = current.Position + direction.Unit * step
                            model:PivotTo(CFrame.lookAt(nextPosition, destination))
                        end
                    end
                else
                    local current = model:GetPivot()
                    local home = guardian.Home.Position
                    local direction = home - current.Position
                    if direction.Magnitude > 1 then
                        local step = math.min(direction.Magnitude, 6 * Config.GuardianThinkSeconds)
                        model:PivotTo(CFrame.lookAt(current.Position + direction.Unit * step, home))
                    end
                end
            end
        end
    end

    if incomeAccumulator >= 1 then
        incomeAccumulator = 0
        local now = os.time()
        for player, profile in pairs(profiles) do
            local changed = false
            local base = playerBases[player]
            local treadmill = base and base:FindFirstChild("Treadmill")
            local zone = treadmill and treadmill:FindFirstChild("TrainingZone")
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if zone and root and humanoid and humanoid.Health > 0 and not carried[player] and not progressionWriteInProgress[player] and not rebirthInProgress[player] then
                local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
                local inside = math.abs(localPosition.X) <= zone.Size.X / 2
                    and math.abs(localPosition.Y) <= zone.Size.Y / 2
                    and math.abs(localPosition.Z) <= zone.Size.Z / 2
                if inside then
                    local gain = Rules.TrainingGain(profile.TreadmillLevel, Config)
                    local nextSpeed = math.clamp(profile.Speed + gain, 0, Config.MaxSpeedPoints)
                    if nextSpeed > profile.Speed then
                        profile.Speed = nextSpeed
                        updatePlayerAttributes(player)
                        local previousNotice = trainingNoticeAt[player] or 0
                        if now - previousNotice >= Config.TrainingNoticeCooldown then
                            trainingNoticeAt[player] = now
                            notify(player, "Treino na esteira: +" .. tostring(gain) .. " velocidade. Total: " .. tostring(profile.Speed) .. ".", "Success")
                        end
                    end
                end
            end
            if not progressionWriteInProgress[player] and not rebirthInProgress[player] then
            for _, animal in ipairs(profile.BarnAnimals) do
                local stage = stageFor(animal, now)
                if animal.Stage ~= stage.Name then
                    animal.Stage = stage.Name
                    changed = true
                    local spec = Catalog.Get(animal.Id)
                    if spec then
                        notify(player, spec.Name .. " evoluiu para " .. stage.DisplayName .. "! Sua renda aumentou.", "Success")
                    end
                end
            end
            local rate = profileIncome(profile, now)
            profile.BarnBank = math.clamp(profile.BarnBank + rate, 0, Config.CoinsLimit)
            profile.LastIncomeAt = now
            if changed then
                renderBarn(player)
                task.spawn(saveProfile, player)
            end
            end
            updatePlayerAttributes(player)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Config.AutosaveSeconds)
        for player in pairs(profiles) do
            if not leaving[player] then
                task.spawn(saveProfile, player)
            end
        end
    end
end)

game:BindToClose(function()
    local pending = 0
    for player in pairs(profiles) do
        leaving[player] = true
        pending += 1
        task.spawn(function()
            local saved = saveProfile(player)
            if saved then
                releaseSession(player)
            else
                abandonSession(player)
            end
            pending -= 1
        end)
    end
    local deadline = os.clock() + 20
    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)
