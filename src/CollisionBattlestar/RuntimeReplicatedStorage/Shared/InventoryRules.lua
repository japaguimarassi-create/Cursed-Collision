--!strict

local InventoryRules = {}

function InventoryRules.isOwned(owned: any, itemId: any)
    return type(owned) == "table"
        and type(itemId) == "string"
        and owned[itemId] == true
end

function InventoryRules.canGrant(owned: any, itemId: any)
    if type(itemId) ~= "string" or itemId == "" then
        return false
    end

    return not InventoryRules.isOwned(owned, itemId)
end

function InventoryRules.canEquip(owned: any, itemId: any, slot: any)
    return type(slot) == "string"
        and slot ~= ""
        and InventoryRules.isOwned(owned, itemId)
end

function InventoryRules.grant(owned: any, itemId: string)
    local output = {}

    if type(owned) == "table" then
        for key, value in pairs(owned) do
            output[key] = value
        end
    end

    output[itemId] = true
    return output
end

function InventoryRules.equip(equipped: any, itemId: string, slot: string)
    local output = {}

    if type(equipped) == "table" then
        for key, value in pairs(equipped) do
            output[key] = value
        end
    end

    output[slot] = itemId
    return output
end

return table.freeze(InventoryRules)
