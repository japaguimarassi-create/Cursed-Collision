local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Workspace = game:GetService("Workspace")
if Workspace:GetAttribute("EnableStealAnimalAudit") ~= true then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StudioTestService = game:GetService("StudioTestService")

local suiteStartedAt = os.clock()
local suiteTimeout = 80
local results = {}
local clientReports = {}
local finished = false
local reportRemote = ReplicatedStorage:FindFirstChild("StealAnimalAuditReport")
if not reportRemote then
    reportRemote = Instance.new("RemoteEvent")
    reportRemote.Name = "StealAnimalAuditReport"
    reportRemote.Parent = ReplicatedStorage
end

local function record(name, passed, detail, warningOnly)
    local status = warningOnly and "WARN" or passed and "PASS" or "FAIL"
    table.insert(results, {
        name = tostring(name),
        status = status,
        detail = tostring(detail or ""),
    })
    print("[STEAL_ANIMAL_AUDIT][" .. status .. "] " .. tostring(name) .. " — " .. tostring(detail or ""))
end

reportRemote.OnServerEvent:Connect(function(player, payload)
    if finished or not Players:FindFirstChild(player.Name) or type(payload) ~= "table" then
        return
    end
    if type(payload.tests) ~= "table" or type(payload.passed) ~= "number" or type(payload.failed) ~= "number" then
        return
    end
    clientReports[player] = payload
    print("[STEAL_ANIMAL_AUDIT] Recebido relatório de cliente simulado: " .. player.Name)
end)

local function waitUntil(predicate, timeout, interval)
    local deadline = os.clock() + timeout
    repeat
        local ok, value = pcall(predicate)
        if ok and value then
            return true
        end
        task.wait(interval or 0.2)
    until os.clock() >= deadline
    local ok, value = pcall(predicate)
    return ok and value == true
end

local function countDescendantsNamed(root, prefix)
    local count = 0
    if not root then return count end
    for _, item in ipairs(root:GetDescendants()) do
        if string.sub(item.Name, 1, #prefix) == prefix then
            count += 1
        end
    end
    return count
end

local function countSlots(farm)
    local stored = farm and farm:FindFirstChild("StoredAnimals")
    if not stored then return 0 end
    local count = 0
    for _, item in ipairs(stored:GetChildren()) do
        if string.match(item.Name, "^Slot_%d+$") then
            count += 1
        end
    end
    return count
end

local function createSummary()
    local passed = 0
    local failed = 0
    local warnings = 0
    for _, item in ipairs(results) do
        if item.status == "PASS" then
            passed += 1
        elseif item.status == "FAIL" then
            failed += 1
        else
            warnings += 1
        end
    end
    local clientList = {}
    for player, payload in pairs(clientReports) do
        table.insert(clientList, {
            client = player.Name,
            passed = payload.passed,
            failed = payload.failed,
            warnings = payload.warnings or 0,
            viewport = payload.viewport,
            touchEnabled = payload.touchEnabled,
            tests = payload.tests,
        })
        if payload.failed > 0 then
            failed += 1
        end
        warnings += payload.warnings or 0
    end
    table.sort(clientList, function(a, b) return a.client < b.client end)
    return {
        suite = "StealAnAnimalStudioAudit",
        version = 1,
        startedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        durationSeconds = math.floor(os.clock() - suiteStartedAt),
        status = failed > 0 and "FAIL" or "PASS",
        passed = passed,
        failed = failed,
        warnings = warnings,
        serverTests = results,
        clients = clientList,
        notes = {
            "Executado apenas em clientes simulados no Roblox Studio.",
            "Os testes não compram produtos, não efetuam renascimento e não alteram moedas.",
            "O DataStore do Studio usa um nome isolado do DataStore da experiência publicada.",
        },
    }
end

local function finish()
    if finished then return end
    finished = true
    local summary = createSummary()
    local encoded = HttpService:JSONEncode(summary)
    print("[STEAL_ANIMAL_AUDIT_REPORT]" .. encoded)
    pcall(function()
        StudioTestService:EndTest(encoded)
    end)
end

task.delay(suiteTimeout, function()
    if not finished then
        record("Limite de tempo da auditoria", false, "A auditoria excedeu " .. tostring(suiteTimeout) .. " segundos.")
        finish()
    end
end)

local function runAudit()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local configModule = shared and shared:FindFirstChild("Config")
    local catalogModule = shared and shared:FindFirstChild("AnimalCatalog")
    local rulesModule = shared and shared:FindFirstChild("GameplayRules")
    local configOk, Config = pcall(require, configModule)
    local catalogOk, Catalog = pcall(require, catalogModule)
    local rulesOk, Rules = pcall(require, rulesModule)

    record("Módulos compartilhados carregam", configOk and catalogOk and rulesOk,
        "Config=" .. tostring(configOk) .. ", AnimalCatalog=" .. tostring(catalogOk) .. ", GameplayRules=" .. tostring(rulesOk))

    if configOk then
        record("Dados do Studio isolados", Config.DataStoreName == "StealAnAnimal_StudioSandbox_v1",
            "DataStore atual: " .. tostring(Config.DataStoreName))
        record("Oito biomas configurados", type(Config.Biomes) == "table" and #Config.Biomes == 8,
            "Biomas encontrados: " .. tostring(type(Config.Biomes) == "table" and #Config.Biomes or 0))
        record("Requisitos de renascimento configurados", Config.RebirthCoinsRequired == 100000 and Config.MaxRebirths == 25,
            "Moedas=" .. tostring(Config.RebirthCoinsRequired) .. ", limite=" .. tostring(Config.MaxRebirths))
    end

    if catalogOk and configOk then
        local allOk, allAnimals = pcall(function() return Catalog.All() end)
        record("Catálogo de espécies acessível", allOk and type(allAnimals) == "table" and #allAnimals >= 28,
            "Espécies encontradas: " .. tostring(allOk and type(allAnimals) == "table" and #allAnimals or 0))
        local coverage = true
        local details = {}
        for _, biome in ipairs(Config.Biomes) do
            local ok, species = pcall(function() return Catalog.ForBiome(biome.Id) end)
            local count = ok and type(species) == "table" and #species or 0
            table.insert(details, biome.Id .. "=" .. tostring(count))
            if count == 0 then coverage = false end
        end
        record("Todos os biomas possuem animais", coverage, table.concat(details, ", "))
    end

    if rulesOk and configOk then
        local costOk, cost = pcall(function() return Rules.RebirthCost(0, Config) end)
        local speedOk, speedRequirement = pcall(function() return Rules.RebirthSpeedRequirement(Config) end)
        record("Regras de renascimento respondem", costOk and cost == Config.RebirthCoinsRequired and speedOk
            and type(speedRequirement) == "number" and speedRequirement > 0,
            "Custo=" .. tostring(cost) .. ", velocidade necessária=" .. tostring(speedRequirement))
        local gainOk, gain = pcall(function() return Rules.TrainingGain(1, Config) end)
        record("Regra de treino responde", gainOk and type(gain) == "number" and gain > 0,
            "Ganho inicial=" .. tostring(gain))
    end

    local remoteFolder = ReplicatedStorage:FindFirstChild("StealAnimalRemotes")
    record("Pasta de remotos existe", remoteFolder ~= nil, "StealAnimalRemotes")
    if remoteFolder then
        local requiredRemotes = {
            "Notify", "RequestUpgrade", "RequestCollect", "RequestRebirth",
            "RequestDailyReward", "RequestRedeemCode", "RequestQuest",
            "RequestMapBot", "MapBotReport",
        }
        local missing = {}
        for _, name in ipairs(requiredRemotes) do
            if not remoteFolder:FindFirstChild(name) then
                table.insert(missing, name)
            end
        end
        record("Todos os remotos de gameplay existem", #missing == 0,
            #missing == 0 and ("Encontrados " .. tostring(#requiredRemotes)) or ("Ausentes: " .. table.concat(missing, ", ")))
    end

    local worldReady = waitUntil(function()
        local world = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
        local farms = world and world:FindFirstChild("PlayerFarms")
        local guardians = world and world:FindFirstChild("Guardians")
        local wildlife = world and world:FindFirstChild("Wildlife")
        return world and farms and guardians and wildlife
            and #farms:GetChildren() == 8
            and #guardians:GetChildren() >= 8
            and #wildlife:GetChildren() > 0
    end, 45, 0.25)

    local world = Workspace:FindFirstChild("StealAnAnimalRuntimeWorld")
    record("Mapa runtime terminou de carregar", worldReady,
        "World=" .. tostring(world ~= nil))
    if world then
        local farms = world:FindFirstChild("PlayerFarms")
        local guardians = world:FindFirstChild("Guardians")
        local wildlife = world:FindFirstChild("Wildlife")
        local scenery = world:FindFirstChild("Scenery")
        record("Pastas principais do mapa existem", farms ~= nil and guardians ~= nil and wildlife ~= nil and scenery ~= nil,
            "Fazendas, guardiões, animais e cenário")
        record("Oito fazendas foram criadas", farms ~= nil and #farms:GetChildren() == 8,
            "Fazendas: " .. tostring(farms and #farms:GetChildren() or 0))
        record("Oito guardiões foram criados", guardians ~= nil and #guardians:GetChildren() >= 8,
            "Guardiões: " .. tostring(guardians and #guardians:GetChildren() or 0))
        local namedGuardians = countDescendantsNamed(guardians, "GuardianParent_")
        record("Há um guardião nomeado para cada bioma", namedGuardians >= 8,
            "Guardians encontrados: " .. tostring(namedGuardians))
        record("Animais aparecem no corredor", wildlife ~= nil and #wildlife:GetChildren() > 0,
            "Animais ativos: " .. tostring(wildlife and #wildlife:GetChildren() or 0))
        record("Cenário contém objetos", scenery ~= nil and #scenery:GetChildren() > 0,
            "Objetos ambientais: " .. tostring(scenery and #scenery:GetChildren() or 0))

        local completeFarms = true
        local farmIssues = {}
        if farms then
            for index = 1, 8 do
                local farm = farms:FindFirstChild("Farm_" .. tostring(index))
                if not farm then
                    completeFarms = false
                    table.insert(farmIssues, "Farm_" .. tostring(index) .. " ausente")
                else
                    local deposit = farm:FindFirstChild("DepositPad")
                    local collect = farm:FindFirstChild("CollectPad")
                    local treadmill = farm:FindFirstChild("Treadmill")
                    local depositPrompt = deposit and deposit:FindFirstChild("DepositPrompt")
                    local collectPrompt = collect and collect:FindFirstChild("CollectPrompt")
                    local slots = countSlots(farm)
                    if not depositPrompt or not collectPrompt or not treadmill or slots ~= 6 then
                        completeFarms = false
                        table.insert(farmIssues, farm.Name .. ": prompts/esteira/espaços=" .. tostring(slots))
                    end
                end
            end
        else
            completeFarms = false
            table.insert(farmIssues, "Pasta PlayerFarms ausente")
        end
        record("Cada fazenda contém depósito, coleta, esteira e seis espaços", completeFarms,
            #farmIssues == 0 and "8 fazendas completas" or table.concat(farmIssues, "; "))
        local depositPromptCount = countDescendantsNamed(farms, "DepositPrompt")
        local collectPromptCount = countDescendantsNamed(farms, "CollectPrompt")
        local promptTypesValid = depositPromptCount == 8 and collectPromptCount == 8
        if farms then
            for _, item in ipairs(farms:GetDescendants()) do
                if item:IsA("ProximityPrompt") and item.Name == "DepositPrompt"
                    and item:GetAttribute("InteractionType") ~= "DepositAnimal" then
                    promptTypesValid = false
                elseif item:IsA("ProximityPrompt") and item.Name == "CollectPrompt"
                    and item:GetAttribute("InteractionType") ~= "CollectIncome" then
                    promptTypesValid = false
                end
            end
        end
        record("Prompts usam os tipos de interação corretos", promptTypesValid,
            "Depósito=" .. tostring(depositPromptCount) .. "/8, coleta=" .. tostring(collectPromptCount) .. "/8")
    end

    local playersReady = waitUntil(function() return #Players:GetPlayers() >= 2 end, 20, 0.25)
    local activePlayers = Players:GetPlayers()
    record("Dois clientes simulados entraram", playersReady,
        "Clientes ativos: " .. tostring(#activePlayers))

    if configOk and type(Config.DataStoreName) == "string" then
        for _, player in ipairs(activePlayers) do
            if player:GetAttribute("ProfileLoaded") == true then
                local hasStats = type(player:GetAttribute("Coins")) == "number"
                    and type(player:GetAttribute("BarnBank")) == "number"
                    and type(player:GetAttribute("Rebirths")) == "number"
                    and type(player:GetAttribute("EffectiveWalkSpeed")) == "number"
                record("Perfil e atributos de " .. player.Name, hasStats,
                    hasStats and "Moedas, banco, renascimentos e velocidade disponíveis" or "Um ou mais atributos do perfil estão ausentes")
            else
                record("Perfil carregado de " .. player.Name, false,
                    "Perfil indisponível; confirme API Services no Studio. Nenhum dado de produção será usado.", true)
            end
        end
    end

    local uniqueOwners = {}
    local uniqueCount = 0
    local farmsFolder = world and world:FindFirstChild("PlayerFarms")
    if farmsFolder then
        for _, player in ipairs(activePlayers) do
            local found = false
            for _, farm in ipairs(farmsFolder:GetChildren()) do
                if farm:GetAttribute("OwnerUserId") == player.UserId then
                    found = true
                    break
                end
            end
            if found and not uniqueOwners[player.UserId] then
                uniqueOwners[player.UserId] = true
                uniqueCount += 1
            end
        end
    end
    record("Clientes ativos possuem fazendas distintas", #activePlayers >= 2 and uniqueCount == #activePlayers,
        "Clientes com fazenda própria: " .. tostring(uniqueCount) .. "/" .. tostring(#activePlayers))

    local reportsReady = waitUntil(function()
        local count = 0
        for _ in pairs(clientReports) do count += 1 end
        return count >= 2
    end, 45, 0.25)
    local reported = 0
    for _ in pairs(clientReports) do reported += 1 end
    record("Bots clientes enviaram relatórios", reportsReady,
        "Relatórios recebidos: " .. tostring(reported) .. "/2")

    for player, payload in pairs(clientReports) do
        record("Testes de interface de " .. player.Name, payload.failed == 0,
            "PASS=" .. tostring(payload.passed) .. ", FAIL=" .. tostring(payload.failed) .. ", WARN=" .. tostring(payload.warnings or 0))
    end
end

local ok, err = xpcall(runAudit, debug.traceback)
if not ok then
    record("Execução do auditador do servidor", false, err)
end
finish()
