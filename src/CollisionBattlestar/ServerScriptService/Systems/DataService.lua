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
    OwnedSkins: {[string]: boolean},
    EquippedSkin: string,
    MoneyMultiplier: number,
    DamageMultiplier: number,
    SpeedMultiplier: number,
    ProcessedPurchases: {[string]: number},
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
        OwnedSkins = {Default = true},
        EquippedSkin = "Default",
        MoneyMultiplier = 1,
        DamageMultiplier = 1,
        SpeedMultiplier = 1,
        ProcessedPurchases = {},
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

    if type(raw.OwnedSkins) == "table" then
        for skinKey, owned in pairs(raw.OwnedSkins) do
            if type(skinKey) == "string" and owned == true then
                profile.OwnedSkins[skinKey] = true
            end
        end
    end

    if type(raw.EquippedSkin) == "string" and #raw.EquippedSkin <= 40 then
        profile.EquippedSkin = raw.EquippedSkin
    end

    profile.MoneyMultiplier = math.max(1, math.floor(tonumber(raw.MoneyMultiplier) or 1))
    profile.DamageMultiplier = math.max(1, math.floor(tonumber(raw.DamageMultiplier) or 1))
    profile.SpeedMultiplier = math.max(1, math.floor(tonumber(raw.SpeedMultiplier) or 1))

    if type(raw.ProcessedPurchases) == "table" then
        for purchaseId, stamp in pairs(raw.ProcessedPurchases) do
            if type(purchaseId) == "string" and type(stamp) == "number" then
                profile.ProcessedPurchases[purchaseId] = stamp
            end
        end
    end

    profile.OwnedSkins.Default = true
    if profile.EquippedSkin ~= "Default" and profile.OwnedSkins[profile.EquippedSkin] ~= true then
        profile.EquippedSkin = "Default"
    end

    return profile
end

local function publish(player: Player, profile: Profile)
    player:SetAttribute("Credits", profile.Credits)
    player:SetAttribute("DamageLevel", profile.DamageLevel)
    player:SetAttribute("DefenseLevel", profile.DefenseLevel)
    player:SetAttribute("SpeedLevel", profile.SpeedLevel)
    player:SetAttribute("MoneyMultiplier", profile.MoneyMultiplier)
    player:SetAttribute("DamageMultiplier", profile.DamageMultiplier)
    player:SetAttribute("SpeedMultiplier", profile.SpeedMultiplier)
    player:SetAttribute("EquippedSkin", profile.EquippedSkin)

    for skinKey, owned in pairs(profile.OwnedSkins) do
        player:SetAttribute("Skin_" .. skinKey, owned)
    end

    for companionKey, amount in pairs(profile.Companions) do
        player:SetAttribute("Companion_" .. companionKey, amount)
    end
end

function Service:Init(_config)
    Players.PlayerRemoving:Connect(function(player)
        self:Save(player)
        profiles[player] = nil
        loaded[player] = nil
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

function Service:AddCredits(player: Player, amount: number, applyMultiplier: boolean?): (boolean, number)
    local profile = profiles[player]
    if not profile then
        return false, 0
    end

    local multiplier = if applyMultiplier == false then 1 else profile.MoneyMultiplier
    local earned = math.floor(math.max(0, amount) * multiplier)
    profile.Credits = math.max(0, profile.Credits + earned)
    publish(player, profile)
    return true, earned
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
    publish(player, profile)
    return true
end

function Service:BuySkin(player: Player, skinKey: string, cost: number)
    local profile = profiles[player]
    if not profile then
        return false, "DATA"
    end
    if profile.OwnedSkins[skinKey] == true then
        return false, "OWNED"
    end
    cost = math.max(0, math.floor(cost))
    if profile.Credits < cost then
        return false, "MONEY"
    end
    profile.Credits -= cost
    profile.OwnedSkins[skinKey] = true
    profile.EquippedSkin = skinKey
    publish(player, profile)
    return true, "OK"
end

function Service:EquipSkin(player: Player, skinKey: string)
    local profile = profiles[player]
    if not profile then
        return false
    end
    if skinKey ~= "Default" and profile.OwnedSkins[skinKey] ~= true then
        return false
    end
    profile.EquippedSkin = skinKey
    publish(player, profile)
    return true
end

function Service:GrantDeveloperProduct(player: Player, product, purchaseId: string)
    local receiptId = tostring(purchaseId)
    local current = profiles[player]

    local success, result = pcall(function()
        return store:UpdateAsync(key(player), function(raw)
            local stored = sanitize(raw)

            if stored.ProcessedPurchases[receiptId] then
                return stored
            end

            local profile = if current then sanitize(current) else stored

            local kind = tostring(product.Kind or "")
            if kind == "Credits" then
                profile.Credits += math.max(0, math.floor(tonumber(product.Amount) or 0))
            elseif kind == "MoneyMultiplier" then
                profile.MoneyMultiplier += 1
            elseif kind == "DamageMultiplier" then
                profile.DamageMultiplier += 1
            elseif kind == "SpeedMultiplier" then
                profile.SpeedMultiplier += 1
            else
                return nil
            end

            profile.ProcessedPurchases[receiptId] = os.time()
            return profile
        end)
    end)

    if not success or type(result) ~= "table" then
        return false
    end

    local profile = sanitize(result)
    profiles[player] = profile
    loaded[player] = true
    publish(player, profile)
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
        OwnedSkins = table.clone(profile.OwnedSkins),
        EquippedSkin = profile.EquippedSkin,
        MoneyMultiplier = profile.MoneyMultiplier,
        DamageMultiplier = profile.DamageMultiplier,
        SpeedMultiplier = profile.SpeedMultiplier,
        ProcessedPurchases = table.clone(profile.ProcessedPurchases),
    }

    return pcall(function()
        store:UpdateAsync(key(player), function()
            return snapshot
        end)
    end)
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
        MoneyMultiplier = profile.MoneyMultiplier,
        DamageMultiplier = profile.DamageMultiplier,
        SpeedMultiplier = profile.SpeedMultiplier,
        Damage = (1 + profile.DamageLevel * 0.18) * profile.DamageMultiplier,
        Defense = math.max(0.25, 1 - profile.DefenseLevel * 0.035),
        WalkSpeed = (18 + profile.SpeedLevel * 1.5) * profile.SpeedMultiplier,
    }
end

return Service
