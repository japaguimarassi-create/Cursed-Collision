local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Economy.ShopDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local CosmeticService = require(ReplicatedStorage.Economy.CosmeticService)

local ShopService = {}

local function getOwnedTable(data, category)
    if category == "Emotes" then
        return data.OwnedEmotes
    elseif category == "Skins" then
        return data.OwnedSkins
    end
    return nil
end

local function getCatalog(category)
    if category == "Emotes" then
        return Shop.Emotes
    elseif category == "Skins" then
        return Shop.Skins
    end
    return nil
end

function ShopService:Buy(player, category, itemId)
    if not DataService:IsReady(player) then
        return false, "DATA_NOT_READY"
    end

    local data = DataService:Get(player)
    local owned = getOwnedTable(data, category)
    local catalog = getCatalog(category)
    local item = catalog and catalog[itemId]

    if not owned or not item then
        return false, "UNKNOWN_ITEM"
    end

    if owned[itemId] then
        return true, "ALREADY_OWNED"
    end

    local price = math.max(0, math.floor(tonumber(item.Price) or 0))
    if not DataService:SpendCredits(player, price) then
        return false, "NOT_ENOUGH_CREDITS"
    end

    owned[itemId] = true
    DataService:MarkDirty(player)
    DataService:Save(player)
    return true, "PURCHASED"
end

function ShopService:Equip(player, category, itemId)
    if not DataService:IsReady(player) then
        return false, "DATA_NOT_READY"
    end

    local data = DataService:Get(player)
    local owned = getOwnedTable(data, category)
    local catalog = getCatalog(category)
    local item = catalog and catalog[itemId]

    if not owned or not item then
        return false, "UNKNOWN_ITEM"
    end

    if not owned[itemId] then
        return false, "NOT_OWNED"
    end

    if category == "Emotes" then
        data.EquippedEmote = itemId
        player:SetAttribute("EquippedEmote", itemId)
    elseif category == "Skins" then
        if item.Character ~= (player:GetAttribute("CharacterId") or "") then
            return false, "WRONG_CHARACTER"
        end
        data.EquippedSkin = itemId
        if not CosmeticService:ApplySkin(player, itemId) then
            return false, "SKIN_APPLY_FAILED"
        end
    else
        return false, "UNKNOWN_CATEGORY"
    end

    DataService:MarkDirty(player)
    DataService:Save(player)
    return true, "EQUIPPED"
end

function ShopService:GiveAllEmotes(player)
    local data = DataService:Get(player)
    if not data then
        return false
    end

    for id in pairs(Shop.Emotes) do
        data.OwnedEmotes[id] = true
    end
    DataService:MarkDirty(player)
    return true
end

function ShopService:GiveAllSkins(player)
    local data = DataService:Get(player)
    if not data then
        return false
    end

    for id in pairs(Shop.Skins) do
        data.OwnedSkins[id] = true
    end
    DataService:MarkDirty(player)
    return true
end

function ShopService:Snapshot(player)
    local data = DataService:Get(player)
    if not data then
        return {
            Credits = 0,
            OwnedEmotes = {},
            OwnedSkins = {},
            EquippedEmote = "",
            EquippedSkin = ""
        }
    end

    return {
        Credits = data.Credits,
        OwnedEmotes = data.OwnedEmotes,
        OwnedSkins = data.OwnedSkins,
        EquippedEmote = data.EquippedEmote,
        EquippedSkin = data.EquippedSkin
    }
end

return ShopService
