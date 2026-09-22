local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

local STORE = DataStoreService:GetDataStore("CursedCollisionPlayerData_v2")
local sessions = {}
local dirty = {}
local ready = {}

local DEFAULT = {
    Version = 2,
    Credits = 500,
    OwnedEmotes = {emote_001 = true},
    OwnedSkins = {},
    EquippedEmote = "emote_001",
    EquippedSkin = "",
    DailyProgress = {},
    WeeklyProgress = {},
    GeneralProgress = {},
    CompletedDaily = {},
    CompletedWeekly = {},
    CompletedGeneral = {},
    DailyStamp = "",
    WeeklyStamp = "",
    LastLoginRewardStamp = ""
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = deepCopy(item)
    end
    return result
end

local function normalize(raw)
    local data = deepCopy(DEFAULT)
    if type(raw) ~= "table" then
        return data
    end

    for key, value in pairs(raw) do
        if data[key] ~= nil and type(value) == type(data[key]) then
            data[key] = value
        end
    end

    data.Credits = math.max(0, math.floor(tonumber(data.Credits) or DEFAULT.Credits))
    data.Version = 2
    return data
end

local function keyFor(player)
    return "Player_" .. tostring(player.UserId)
end

function DataService:Initialize(player)
    if sessions[player] then
        return true
    end

    local success, loaded = pcall(function()
        return STORE:GetAsync(keyFor(player))
    end)

    local data = normalize(success and loaded or nil)
    sessions[player] = data
    ready[player] = success
    dirty[player] = not success

    player:SetAttribute("DataReady", success)
    player:SetAttribute("Credits", data.Credits)

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local credits = leaderstats:FindFirstChild("Credits")
    if not credits then
        credits = Instance.new("IntValue")
        credits.Name = "Credits"
        credits.Parent = leaderstats
    end
    credits.Value = data.Credits

    return success
end

function DataService:Get(player)
    return sessions[player]
end

function DataService:IsReady(player)
    return ready[player] == true
end

function DataService:MarkDirty(player)
    if sessions[player] then
        dirty[player] = true
    end
end

function DataService:SetCredits(player, amount)
    local data = sessions[player]
    if not data then
        return false
    end

    data.Credits = math.max(0, math.floor(tonumber(amount) or 0))
    player:SetAttribute("Credits", data.Credits)

    local leaderstats = player:FindFirstChild("leaderstats")
    local credits = leaderstats and leaderstats:FindFirstChild("Credits")
    if credits then
        credits.Value = data.Credits
    end

    dirty[player] = true
    return true
end

function DataService:AddCredits(player, amount)
    local data = sessions[player]
    if not data then
        return false
    end

    return self:SetCredits(player, data.Credits + math.floor(tonumber(amount) or 0))
end

function DataService:SpendCredits(player, amount)
    local data = sessions[player]
    amount = math.floor(tonumber(amount) or 0)
    if not data or amount < 0 or data.Credits < amount then
        return false
    end

    return self:SetCredits(player, data.Credits - amount)
end

function DataService:Save(player)
    local data = sessions[player]
    if not data or not ready[player] then
        return false
    end

    local snapshot = deepCopy(data)
    local success = false

    for attempt = 1, 3 do
        local ok = pcall(function()
            STORE:UpdateAsync(keyFor(player), function()
                return snapshot
            end)
        end)

        if ok then
            success = true
            break
        end

        task.wait(attempt * 0.75)
    end

    if success then
        dirty[player] = false
    end

    return success
end

function DataService:SaveDirty(player)
    if dirty[player] then
        return self:Save(player)
    end
    return true
end

function DataService:PlayerRemoving(player)
    self:SaveDirty(player)
    sessions[player] = nil
    dirty[player] = nil
    ready[player] = nil
end

function DataService:Shutdown()
    for player in pairs(sessions) do
        self:SaveDirty(player)
    end
end

task.spawn(function()
    while true do
        task.wait(60)
        for player in pairs(sessions) do
            if dirty[player] then
                task.spawn(function()
                    DataService:Save(player)
                end)
            end
        end
    end
end)

return DataService
