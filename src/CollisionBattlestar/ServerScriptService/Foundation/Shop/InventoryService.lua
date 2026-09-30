--!strict

local Rules = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("InventoryRules"))

local Service = {}
Service.__index = Service

function Service.new(playerState)
    return setmetatable({players = playerState}, Service)
end

function Service:Owns(player: Player, itemId: string): boolean
    return self.players:Owns(player, itemId)
end

function Service:Grant(player: Player, itemId: string): boolean
    return self.players:GrantItem(player, itemId)
end

function Service:EquipSkin(player: Player, itemId: string): boolean
    if not self:Owns(player, itemId) then return false end
    if not string.find(itemId, "^Skin_") then return false end
    return self.players:EquipSkin(player, itemId)
end

function Service:CanEquip(player: Player, itemId: string): boolean
    local state = self.players:Get(player)
    return state ~= nil and Rules.canEquip(itemId, state.OwnedItems)
end

return Service
