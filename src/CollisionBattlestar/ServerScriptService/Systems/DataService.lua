--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Service = {}

local store = DataStoreService:GetDataStore("CollisionBattlestar_Profile_v3")

type Profile = {
    Credits: number,
    DamageLevel: number,
    DefenseLevel: number,
    SpeedLevel: number,
    Companions: {[string]: number},
}

local profiles: {[Player]: Profile} = {}
local loaded: {[Player]: boolean} = {}

local function defaults(): Profile
    return {
        Credits = 0,
        DamageLevel = 0,
        DefenseLevel = 0,
        SpeedLevel = 0,
        Companions = {},
    }
end

local function key(player: Player): string
    return ("u_%d"):format(player.UserId)
end

local function sanitize(raw): Profile
    local profile = defaults()

    if type(raw) ~= "table" then
        return profile
    end

    profile.Credits = math.max(0, math.floor(tonumber(raw.Credits) or 0))
    profile.DamageLevel = math.max(0, math.floor(tonumber(raw.DamageLevel) or 0))
    profile.DefenseLevel = math.max(0, math.floor(tonumber(raw.DefenseLevel) or 0))
    profile.SpeedLevel = math.max(0, math.floor(tonumber(raw.SpeedLevel) or 0))

    if type(raw.Companions) == "table" then
        for companionKey, amount in pairs(raw.Companions) do
            if type(companionKey) == "string" and type(amount) == "number" then
                profile.Companions[companionKey] = math.clamp(math.floor(amount), 0, 2)
            end
        end
    end

    return profile
end

local function publish(player: Player, profile: Profile)
    player:SetAttribute("Credits", profile.Credits)
    player:SetAttribute("DamageLevel", profile.DamageLevel)
    player:SetAttribute("DefenseLevel", profile.DefenseLevel)
    player:SetAttribute("SpeedLevel", profile.SpeedLevel)

    for companionKey, amount in pairs(profile.Companions) do
        player:SetAttribute("Companion_" .. companionKey, amount)
    end
end

function Service:Init(_config)
    Players.PlayerRemoving:Connect(function(player)
        self:Save(player)
    end)

    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                self:Save(player)
            end
        end
    end)

    game:BindToClose(function()
        for _, player in ipairs(Players:GetPlayers()) do
            self:Save(player)
        end
    end)
end

function Service:Load(player: Player)
    if loaded[player] then
        return true
    end

    local success, raw = pcall(function()
        return store:GetAsync(key(player))
    end)

    if not success then
        player:SetAttribute("DataReady", false)
        return false
    end

    local profile = sanitize(raw)
    profiles[player] = profile
    loaded[player] = true
    publish(player, profile)
    player:SetAttribute("DataReady", true)
    return true
end

function Service:Get(player: Player): Profile?
    return profiles[player]
end

function Service:CanSpend(player: Player, amount: number): boolean
    local profile = profiles[player]
    return profile ~= nil and profile.Credits >= amount
end

function Service:AddCredits(player: Player, amount: number)
    local profile = profiles[player]
    if not profile then
        return false
    end

    profile.Credits = math.max(0, profile.Credits + math.floor(amount))
    publish(player, profile)
    return true
end

function Service:SpendCredits(player: Player, amount: number): boolean
    local profile = profiles[player]
    if not profile then
        return false
    end

    amount = math.max(0, math.floor(amount))
    if profile.Credits < amount then
        return false
    end

    profile.Credits -= amount
    publish(player, profile)
    return true
end

function Service:IncreaseLevel(player: Player, keyName: string)
    local profile = profiles[player]
    if not profile then
        return false
    end

    if keyName == "Damage" then
        profile.DamageLevel += 1
    elseif keyName == "Defense" then
        profile.DefenseLevel += 1
    elseif keyName == "Speed" then
        profile.SpeedLevel += 1
    else
        return false
    end

    publish(player, profile)
    return true
end

function Service:AddCompanion(player: Player, companionKey: string)
    local profile = profiles[player]
    if not profile then
        return false
    end

    local current = profile.Companions[companionKey] or 0
    if current >= 2 then
        return false
    end

    profile.Companions[companionKey] = current + 1
    player:SetAttribute("Companion_" .. companionKey, current + 1)
    return true
end

function Service:Save(player: Player)
    local profile = profiles[player]
    if not profile or not loaded[player] then
        return false
    end

    local snapshot: Profile = {
        Credits = profile.Credits,
        DamageLevel = profile.DamageLevel,
        DefenseLevel = profile.DefenseLevel,
        SpeedLevel = profile.SpeedLevel,
        Companions = table.clone(profile.Companions),
    }

    local success = pcall(function()
        store:UpdateAsync(key(player), function()
            return snapshot
        end)
    end)

    return success
end

function Service:GetCombatStats(player: Player)
    local profile = profiles[player]
    if not profile then
        return nil
    end

    return {
        DamageLevel = profile.DamageLevel,
        DefenseLevel = profile.DefenseLevel,
        SpeedLevel = profile.SpeedLevel,
        Damage = 1 + profile.DamageLevel * 0.18,
        Defense = math.max(0.25, 1 - profile.DefenseLevel * 0.035),
        WalkSpeed = 18 + profile.SpeedLevel * 1.5,
    }
end

return Service
