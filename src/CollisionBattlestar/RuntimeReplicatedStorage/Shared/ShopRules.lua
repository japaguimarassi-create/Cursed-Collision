--!strict

local ShopRules = {}

function ShopRules.isValidItem(item: any)
    return type(item) == "table"
        and type(item.ItemId) == "string"
        and item.ItemId ~= ""
        and item.Active == true
end

function ShopRules.isCreditsItem(item: any)
    return ShopRules.isValidItem(item)
        and item.Currency == "Credits"
        and item.Premium == false
end

function ShopRules.canPurchase(item: any, owned: any, balance: number)
    if not ShopRules.isCreditsItem(item) then
        return false, "item_unavailable"
    end

    if type(balance) ~= "number" or balance < 0 then
        return false, "invalid_balance"
    end

    if type(item.Price) ~= "number" or item.Price < 0 or item.Price == math.huge then
        return false, "invalid_price"
    end

    if owned[item.ItemId] == true then
        return false, "already_owned"
    end

    if balance < item.Price then
        return false, "insufficient_credits"
    end

    return true, "ok"
end

function ShopRules.isSafeShopPhase(phase: any)
    return phase == "Intermission" or phase == "Cleared"
end

return table.freeze(ShopRules)
