--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local Service = {}

local Config
local DataService
local WaveService
local EnemyService
local ShopService
local ZoneService
local Remote: RemoteEvent
local State: RemoteEvent
local ownerUserId = 0
local requestAt: {[Player]: number} = {}
local serverLocked = false
local serverStartedAt = os.clock()
local frozen: {[Player]: boolean} = {}
local god: {[Player]: boolean} = {}
local logs = {}

local function log(action: string, actor: Player, target: Player?)
    table.insert(logs, 1, {
        Time = os.time(),
        Action = action,
        Actor = actor.Name,
        Target = target and target.Name or "-"
    })
    while #logs > 40 do
        table.remove(logs)
    end
end

local function message(player: Player, text: string, tone: string?)
    State:FireClient(player, "AdminMessage", text, tone or "INFO")
end

local function targetFor(userId: any): Player?
    if type(userId) ~= "number" then
        return nil
    end
    return Players:GetPlayerByUserId(math.floor(userId))
end

local function safeText(player: Player, raw: any, maxLength: number): string
    if type(raw) ~= "string" then
        return ""
    end
    local text = string.sub(raw, 1, maxLength)
    if text == "" then
        return ""
    end
    local ok, result = pcall(function()
        local filtered = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
        return filtered:GetNonChatStringForBroadcastAsync()
    end)
    return if ok then result else ""
end

local function characterOf(player: Player)
    local character = player.Character
    if not character then
        return nil, nil, nil
    end
    return character, character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function setMovement(player: Player)
    local character, root, humanoid = characterOf(player)
    if not humanoid then
        return
    end
    if frozen[player] then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    else
        local stats = DataService:GetCombatStats(player)
        humanoid.WalkSpeed = stats and stats.WalkSpeed or 18
        humanoid.JumpPower = 52
        humanoid.AutoRotate = true
    end
    if root and root:IsA("BasePart") then
        root.AssemblyLinearVelocity = if frozen[player] then Vector3.zero else root.AssemblyLinearVelocity
    end
end

local function applyGod(player: Player)
    local _, _, humanoid = characterOf(player)
    if not humanoid then
        return
    end
    if god[player] then
        humanoid.MaxHealth = 1000000
        humanoid.Health = humanoid.MaxHealth
    end
end

local function applyState(player: Player)
    setMovement(player)
    applyGod(player)
end

local function applySkin(player: Player, key: string): boolean
    local skin
    for _, item in ipairs(Config.Shop.Skins) do
        if item.Key == key then
            skin = item
            break
        end
    end
    if not skin then
        return false
    end
    if key == "Default" then
        local _, _, humanoid = characterOf(player)
        if humanoid then
            return pcall(function()
                humanoid:ApplyDescriptionResetAsync(Instance.new("HumanoidDescription"))
            end)
        end
        return false
    end
    local _, _, humanoid = characterOf(player)
    if not humanoid then
        return false
    end
    local description = Instance.new("HumanoidDescription")
    description.Shirt = skin.Shirt or 0
    description.Pants = skin.Pants or 0
    description.HairAccessory = skin.Hair and tostring(skin.Hair) or ""
    description.HatAccessory = skin.Horns and tostring(skin.Horns) or ""
    return pcall(function()
        humanoid:ApplyDescriptionResetAsync(description)
    end)
end

local function clearTarget(player: Player)
    frozen[player] = nil
    god[player] = nil
    player:SetAttribute("AdminFrozen", false)
    player:SetAttribute("AdminGod", false)
end

local function shutdown()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId ~= ownerUserId then
            player:Kick("Server closed by the owner.")
        end
    end
end

local function execute(actor: Player, action: string, userId: any, value: any, rawText: any)
    if actor.UserId ~= ownerUserId then
        return
    end

    local target = targetFor(userId)

    if action == "Kick" then
        if target and target.UserId ~= ownerUserId then
            log(action, actor, target)
            target:Kick("Removed by the owner.")
            message(actor, "PLAYER KICKED", "GOOD")
        end
    elseif action == "Ban" then
        if not target or target.UserId == ownerUserId then
            return
        end
        local duration = if value == "1H" then 3600 elseif value == "1D" then 86400 elseif value == "7D" then 604800 else -1
        local reason = safeText(actor, rawText, 300)
        if reason == "" then
            reason = "Owner moderation action."
        end
        local ok, err = pcall(function()
            Players:BanAsync({
                UserIds = {target.UserId},
                Duration = duration,
                DisplayReason = reason,
                PrivateReason = "Collision Battlestar owner action.",
                ApplyToUniverse = true,
                ExcludeAltAccounts = false,
                ApplyDeviceBlock = false,
            })
        end)
        log(action .. ":" .. tostring(value), actor, target)
        if ok then
            target:Kick(reason)
            message(actor, "PLAYER BANNED", "GOOD")
        else
            message(actor, "BAN FAILED: " .. tostring(err), "BAD")
        end
    elseif action == "Unban" then
        local id = type(userId) == "number" and math.floor(userId) or 0
        if id <= 0 or id == ownerUserId then
            return
        end
        local ok, err = pcall(function()
            Players:UnbanAsync({
                UserIds = {id},
                ApplyToUniverse = true,
            })
        end)
        log(action, actor)
        message(actor, if ok then "PLAYER UNBANNED" else "UNBAN FAILED: " .. tostring(err), if ok then "GOOD" else "BAD")
    elseif action == "Heal" then
        if target then
            local _, _, humanoid = characterOf(target)
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
                log(action, actor, target)
            end
        end
    elseif action == "Kill" then
        if target and target.UserId ~= ownerUserId then
            local _, _, humanoid = characterOf(target)
            if humanoid then
                humanoid.Health = 0
                log(action, actor, target)
            end
        end
    elseif action == "Respawn" then
        if target and target.UserId ~= ownerUserId then
            target:LoadCharacter()
            log(action, actor, target)
        end
    elseif action == "Bring" then
        local actorChar, actorRoot = characterOf(actor)
        local targetChar = target and target.Character
        if actorRoot and actorRoot:IsA("BasePart") and targetChar then
            targetChar:PivotTo(actorRoot.CFrame * CFrame.new(0, 0, -5))
            target:SetAttribute("ServerTeleportAt", os.clock())
            log(action, actor, target)
        end
    elseif action == "Goto" then
        local actorChar = actor.Character
        local targetChar = target and target.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if actorChar and targetRoot and targetRoot:IsA("BasePart") then
            actorChar:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, -5))
            actor:SetAttribute("ServerTeleportAt", os.clock())
            log(action, actor, target)
        end
    elseif action == "Freeze" or action == "Unfreeze" then
        if target then
            frozen[target] = action == "Freeze"
            target:SetAttribute("AdminFrozen", frozen[target])
            setMovement(target)
            log(action, actor, target)
        end
    elseif action == "God" or action == "Normal" then
        if target then
            god[target] = action == "God"
            target:SetAttribute("AdminGod", god[target])
            if god[target] then
                applyGod(target)
            else
                local _, _, humanoid = characterOf(target)
                local stats = DataService:GetCombatStats(target)
                if humanoid then
                    humanoid.MaxHealth = 100
                    humanoid.Health = humanoid.MaxHealth
                end
            end
            log(action, actor, target)
        end
    elseif action == "ZonePvE" or action == "ZonePvP" then
        if target and target.Character then
            local zone = if action == "ZonePvP" then "PvP" else "PvE"
            local position = if zone == "PvP" then ZoneService:GetPvPSpawn() else ZoneService:GetMainSpawn()
            target:SetAttribute("Zone", zone)
            target:SetAttribute("ServerTeleportAt", os.clock())
            target.Character:PivotTo(CFrame.new(position))
            State:FireClient(target, "Zone", zone)
            log(action, actor, target)
        end
    elseif action == "Credits" then
        if target then
            local amount = math.clamp(math.floor(tonumber(value) or 0), -100000000, 100000000)
            local profile = DataService:Get(target)
            if profile then
                DataService:AdminSetCredits(target, math.max(0, profile.Credits + amount))
                DataService:Save(target)
                log(action .. ":" .. tostring(amount), actor, target)
            end
        end
    elseif action == "SetCredits" then
        if target then
            DataService:AdminSetCredits(target, math.clamp(math.floor(tonumber(value) or 0), 0, 1000000000))
            DataService:Save(target)
            log(action, actor, target)
        end
    elseif action == "MaxStats" then
        if target then
            DataService:AdminSetLevel(target, "Damage", 25)
            DataService:AdminSetLevel(target, "Defense", 25)
            DataService:AdminSetLevel(target, "Speed", 12)
            local _, _, humanoid = characterOf(target)
            local stats = DataService:GetCombatStats(target)
            if humanoid and stats then
                humanoid.WalkSpeed = stats.WalkSpeed
            end
            DataService:Save(target)
            log(action, actor, target)
        end
    elseif action == "SetMultiplier" then
        if target and type(value) == "table" then
            DataService:AdminSetMultiplier(target, "Money", tonumber(value.Money) or 1)
            DataService:AdminSetMultiplier(target, "Damage", tonumber(value.Damage) or 1)
            DataService:AdminSetMultiplier(target, "Speed", tonumber(value.Speed) or 1)
            DataService:Save(target)
            log(action, actor, target)
        end
    elseif action == "GrantSkin" then
        if target and type(value) == "string" then
            if DataService:GrantSkin(target, value) then
                log(action .. ":" .. value, actor, target)
                message(actor, "SKIN GRANTED", "GOOD")
            end
        end
    elseif action == "EquipSkin" then
        if target and type(value) == "string" then
            if DataService:EquipSkin(target, value) and applySkin(target, value) then
                DataService:Save(target)
                log(action .. ":" .. value, actor, target)
                message(actor, "SKIN EQUIPPED", "GOOD")
            end
        end
    elseif action == "GrantCompanion" then
        if target and type(value) == "string" then
            if DataService:GrantCompanion(target, value, 2) then
                DataService:Save(target)
                log(action .. ":" .. value, actor, target)
                message(actor, "COMPANION GRANTED", "GOOD")
            end
        end
    elseif action == "NextWave" then
        WaveService:AdminNextWave()
        log(action, actor)
    elseif action == "RestartWave" then
        WaveService:AdminRestartWave()
        log(action, actor)
    elseif action == "SetWave" then
        WaveService:AdminSetWave(math.clamp(math.floor(tonumber(value) or 1), 1, 1000))
        log(action, actor)
    elseif action == "ClearEnemies" then
        EnemyService:Clear()
        log(action, actor)
    elseif action == "SpawnEnemy" then
        local tier = math.clamp(math.floor(tonumber(value) or 1), 1, 3)
        local _, root = characterOf(actor)
        if root and root:IsA("BasePart") then
            EnemyService:Spawn(root.Position + root.CFrame.LookVector * 12, tier, false)
            log(action .. ":" .. tostring(tier), actor)
        end
    elseif action == "SpawnElite" then
        local _, root = characterOf(actor)
        if root and root:IsA("BasePart") then
            EnemyService:Spawn(root.Position + root.CFrame.LookVector * 12, 3, true)
            log(action, actor)
        end
    elseif action == "Announcement" then
        local text = safeText(actor, rawText, 180)
        if text ~= "" then
            State:FireAllClients("AdminAnnouncement", text)
            log(action, actor)
        end
    elseif action == "Lock" or action == "Unlock" then
        serverLocked = action == "Lock"
        workspace:SetAttribute("CollisionServerLocked", serverLocked)
        log(action, actor)
    elseif action == "Shutdown" then
        log(action, actor)
        shutdown()
    elseif action == "TimeDay" then
        Lighting.ClockTime = 14
        log(action, actor)
    elseif action == "TimeNight" then
        Lighting.ClockTime = 0
        log(action, actor)
    elseif action == "Gravity" then
        workspace.Gravity = math.clamp(tonumber(value) or 196.2, 20, 400)
        log(action, actor)
    elseif action == "Status" then
        local memory = 0
        pcall(function()
            memory = Stats:GetTotalMemoryUsageMb()
        end)
        local uptime = math.floor(os.clock() - serverStartedAt)
        message(actor, ("PLAYERS %d  •  WAVE %d  •  ENEMIES %d  •  UPTIME %ds  •  MEMORY %.0fMB  •  LOCK %s"):format(
            #Players:GetPlayers(),
            WaveService:GetWave(),
            EnemyService:Count(),
            uptime,
            memory,
            tostring(serverLocked)
        ), "INFO")
    elseif action == "Logs" then
        local lines = {}
        for index = 1, math.min(#logs, 8) do
            local item = logs[index]
            table.insert(lines, ("%d. %s -> %s"):format(index, item.Action, item.Target))
        end
        message(actor, #lines > 0 and table.concat(lines, "  |  ") or "NO ADMIN LOGS", "INFO")
    end
end

function Service:Init(config, dataService, waveService, enemyService, shopService, zoneService, adminRemote, stateRemote, ownerId: number)
    Config = config
    DataService = dataService
    WaveService = waveService
    EnemyService = enemyService
    ShopService = shopService
    ZoneService = zoneService
    Remote = adminRemote
    State = stateRemote
    ownerUserId = ownerId
    workspace:SetAttribute("CollisionServerLocked", false)

    local function connectPlayer(player: Player)
        frozen[player] = false
        god[player] = false
        player:SetAttribute("AdminFrozen", false)
        player:SetAttribute("AdminGod", false)

        if serverLocked and player.UserId ~= ownerUserId then
            player:Kick("This server is locked by the owner.")
            return
        end

        player.CharacterAdded:Connect(function()
            task.delay(0.2, function()
                if player.Parent then
                    applyState(player)
                end
            end)
        end)
    end

    Players.PlayerAdded:Connect(connectPlayer)
    Players.PlayerRemoving:Connect(function(player)
        requestAt[player] = nil
        frozen[player] = nil
        god[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        connectPlayer(player)
    end

    Remote.OnServerEvent:Connect(function(player, action, userId, value, rawText)
        if player.UserId ~= ownerUserId then
            return
        end
        if type(action) ~= "string" or #action > 32 then
            return
        end
        local now = os.clock()
        if now - (requestAt[player] or 0) < 0.18 then
            return
        end
        requestAt[player] = now
        task.spawn(execute, player, action, userId, value, rawText)
    end)
end

return Service
