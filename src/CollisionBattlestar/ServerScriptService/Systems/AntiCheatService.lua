--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}

local STORE = DataStoreService:GetDataStore("CollisionBattlestar_AntiCheat_v1")
local WEEK = 7 * 24 * 60 * 60
local SEVEN_DAYS = WEEK
local FIFTEEN_DAYS = 15 * 24 * 60 * 60

type Record = {
    Detections: {[string]: {number}},
    LastSevenDayBanAt: number?,
    LastSevenDayBanEndedAt: number?,
    PermanentBanAt: number?,
}

local cache: {[number]: Record} = {}
local movement: {[Player]: {Position: Vector3, Time: number}} = {}
local remoteHits: {[Player]: {Count: number, Window: number}} = {}
local initialized = false

local function key(userId: number): string
    return ("u_%d"):format(userId)
end

local function clean(record: Record, now: number)
    for fingerprint, timestamps in pairs(record.Detections) do
        local kept = {}
        for _, timestamp in ipairs(timestamps) do
            if now - timestamp <= WEEK then
                table.insert(kept, timestamp)
            end
        end
        record.Detections[fingerprint] = kept
    end
end

local function defaultRecord(): Record
    return {
        Detections = {},
        LastSevenDayBanAt = nil,
        LastSevenDayBanEndedAt = nil,
        PermanentBanAt = nil,
    }
end

local function sanitize(raw): Record
    local record = defaultRecord()
    if type(raw) ~= "table" then return record end

    if type(raw.Detections) == "table" then
        for fingerprint, timestamps in pairs(raw.Detections) do
            if type(fingerprint) == "string" and type(timestamps) == "table" then
                local result = {}
                for _, timestamp in ipairs(timestamps) do
                    if type(timestamp) == "number" then
                        table.insert(result, timestamp)
                    end
                end
                record.Detections[fingerprint] = result
            end
        end
    end

    record.LastSevenDayBanAt = type(raw.LastSevenDayBanAt) == "number" and raw.LastSevenDayBanAt or nil
    record.LastSevenDayBanEndedAt = type(raw.LastSevenDayBanEndedAt) == "number" and raw.LastSevenDayBanEndedAt or nil
    record.PermanentBanAt = type(raw.PermanentBanAt) == "number" and raw.PermanentBanAt or nil
    return record
end

local function load(userId: number): Record
    if cache[userId] then return cache[userId] end
    local success, raw = pcall(function()
        return STORE:GetAsync(key(userId))
    end)
    local record = sanitize(success and raw or nil)
    clean(record, os.time())
    cache[userId] = record
    return record
end

local function save(userId: number, record: Record)
    local snapshot = {
        Detections = {},
        LastSevenDayBanAt = record.LastSevenDayBanAt,
        LastSevenDayBanEndedAt = record.LastSevenDayBanEndedAt,
        PermanentBanAt = record.PermanentBanAt,
    }

    for fingerprint, timestamps in pairs(record.Detections) do
        snapshot.Detections[fingerprint] = table.clone(timestamps)
    end

    pcall(function()
        STORE:UpdateAsync(key(userId), function()
            return snapshot
        end)
    end)
end

local function ban(player: Player, duration: number, displayReason: string, privateReason: string): boolean
    if RunService:IsStudio() then
        player:Kick(displayReason)
        return false
    end

    local success = pcall(function()
        Players:BanAsync({
            UserIds = {player.UserId},
            Duration = duration,
            DisplayReason = displayReason,
            PrivateReason = privateReason,
            ApplyToUniverse = true,
            ExcludeAltAccounts = false,
            ApplyDeviceBlock = false,
        })
    end)

    if not success then
        player:Kick(displayReason)
    end

    return success
end

local function fingerprint(reason: string): string
    return reason:sub(1, 80)
end

function Service:Record(player: Player, reason: string, confidence: string?)
    if not player.Parent then return end
    if player:GetAttribute("IsOwner") == true then return end

    local now = os.time()
    local id = player.UserId
    local record = load(id)
    clean(record, now)

    local fp = fingerprint(reason)
    local list = record.Detections[fp] or {}
    table.insert(list, now)
    record.Detections[fp] = list

    local recent = #list
    local withinPostBanWindow = record.LastSevenDayBanEndedAt ~= nil
        and now >= record.LastSevenDayBanEndedAt
        and now <= record.LastSevenDayBanEndedAt + FIFTEEN_DAYS

    if withinPostBanWindow then
        record.PermanentBanAt = now
        save(id, record)
        ban(
            player,
            -1,
            "Permanent restriction: repeated security violation.",
            ("AntiCheat permanent escalation; detection=%s; confidence=%s"):format(fp, confidence or "unknown")
        )
        return
    end

    if recent >= 6 then
        record.LastSevenDayBanAt = now
        record.LastSevenDayBanEndedAt = now + SEVEN_DAYS
        record.Detections[fp] = {}
        save(id, record)
        ban(
            player,
            SEVEN_DAYS,
            "7-day restriction: repeated security violations.",
            ("AntiCheat 7-day escalation; detection=%s; confidence=%s; count=%d"):format(fp, confidence or "unknown", recent)
        )
        return
    end

    save(id, record)
    player:Kick(("Security verification failed: %s"):format(fp))
end

function Service:ValidateAction(player: Player, action: string): boolean
    if type(action) ~= "string" or #action > 24 then
        self:Record(player, "MalformedAction", "high")
        return false
    end

    if action ~= "M1" and action ~= "Dash" then
        self:Record(player, "UnauthorizedAction:" .. action, "high")
        return false
    end

    local bucket = remoteHits[player]
    local now = os.clock()
    if not bucket or now - bucket.Window >= 1 then
        bucket = {Count = 0, Window = now}
        remoteHits[player] = bucket
    end

    bucket.Count += 1
    if bucket.Count > 12 then
        self:Record(player, "ActionRemoteRateLimit", "high")
        return false
    end

    return true
end

local function monitorMovement(player: Player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        movement[player] = nil
        return
    end

    local now = os.clock()
    local previous = movement[player]
    movement[player] = {Position = root.Position, Time = now}

    if not previous or now - previous.Time < 0.45 then return end
    if now - (player:GetAttribute("ServerTeleportAt") or 0) < 2 then return end

    local distance = (root.Position - previous.Position).Magnitude
    local elapsed = now - previous.Time
    local allowedSpeed = math.max(24, humanoid.WalkSpeed + 18)

    if distance > allowedSpeed * elapsed + 18 then
        root.CFrame = CFrame.new(previous.Position, previous.Position + root.CFrame.LookVector)
        root.AssemblyLinearVelocity = Vector3.zero
        Service:Record(player, "ImpossibleMovement", "high")
    end
end

function Service:Init(_config)
    if initialized then return end
    initialized = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes")

    local honeypot = Instance.new("RemoteEvent")
    honeypot.Name = "ClientSyncProbe"
    honeypot:SetAttribute("ServerOnlyDirection", true)
    honeypot.Parent = remotes

    honeypot.OnServerEvent:Connect(function(player)
        self:Record(player, "ServerOnlyRemoteFired", "critical")
    end)

    Players.PlayerAdded:Connect(function(player)
        task.spawn(function()
            load(player.UserId)
        end)
        player.CharacterAdded:Connect(function()
            movement[player] = nil
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        movement[player] = nil
        remoteHits[player] = nil
        cache[player.UserId] = nil
    end)

    task.spawn(function()
        while true do
            for _, player in ipairs(Players:GetPlayers()) do
                monitorMovement(player)
            end
            task.wait(0.5)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(60)
            for userId, record in pairs(cache) do
                clean(record, os.time())
                save(userId, record)
            end
        end
    end)
end

return Service
