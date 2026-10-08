--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryRules = require(ReplicatedStorage.Shared.InventoryRules)

local InventoryService = {}
InventoryService.__index = InventoryService

local DEFAULTS = {
    PlayerSkin = "Default",
    AttackFX = "Default",
    EchoCosmetic = "Default",
    EliteCosmetic = "Default",
}

function InventoryService.new(playerState)
    return setmetatable({
        playerState = playerState,
    }, InventoryService)
end

function InventoryService:Start()
end

function InventoryService:EnsureDefaults(player: Player)
    local profile = self.playerState:GetProfile(player)
    if not profile then
        return false
    end

    for slot, defaultItem in pairs(DEFAULTS) do
        profile.Inventory.Equipped[slot] = profile.Inventory.Equipped[slot] or defaultItem
    end

    return true
end

function InventoryService:IsOwned(player: Player, itemId: string)
    local profile = self.playerState:GetProfile(player)
    return profile and InventoryRules.isOwned(profile.Inventory.Owned, itemId) or false
end

function InventoryService:Grant(player: Player, itemId: string)
    local profile = self.playerState:GetProfile(player)
    if not profile then
        return false, "profile_unavailable"
    end

    if not InventoryRules.canGrant(profile.Inventory.Owned, itemId) then
        return false, "already_owned"
    end

    profile.Inventory.Owned = InventoryRules.grant(profile.Inventory.Owned, itemId)
    self:PublishAttributes(player)

    return true, "granted"
end

function InventoryService:Equip(player: Player, itemId: string, slot: string)
    local profile = self.playerState:GetProfile(player)
    if not profile then
        return false, "profile_unavailable"
    end

    if not InventoryRules.canEquip(profile.Inventory.Owned, itemId, slot) then
        return false, "not_owned"
    end

    profile.Inventory.Equipped = InventoryRules.equip(profile.Inventory.Equipped, itemId, slot)
    self:PublishAttributes(player)

    return true, "equipped"
end

function InventoryService:GetSnapshot(player: Player)
    local profile = self.playerState:GetProfile(player)
    if not profile then
        return nil
    end

    self:EnsureDefaults(player)

    local owned = {}
    for itemId, value in pairs(profile.Inventory.Owned) do
        if value == true then
            table.insert(owned, itemId)
        end
    end

    table.sort(owned)

    local equipped = {}
    for slot, itemId in pairs(profile.Inventory.Equipped) do
        equipped[slot] = itemId
    end

    return {
        owned = owned,
        equipped = equipped,
    }
end

function InventoryService:PublishAttributes(player: Player)
    player:SetAttribute(
        "CBS_EquippedPlayerSkin",
        self.playerState:GetProfile(player).Inventory.Equipped.PlayerSkin
    )
    player:SetAttribute(
        "CBS_EquippedAttackFX",
        self.playerState:GetProfile(player).Inventory.Equipped.AttackFX
    )
    player:SetAttribute(
        "CBS_EquippedEchoCosmetic",
        self.playerState:GetProfile(player).Inventory.Equipped.EchoCosmetic
    )
    player:SetAttribute(
        "CBS_EquippedEliteCosmetic",
        self.playerState:GetProfile(player).Inventory.Equipped.EliteCosmetic
    )
end

return InventoryService
