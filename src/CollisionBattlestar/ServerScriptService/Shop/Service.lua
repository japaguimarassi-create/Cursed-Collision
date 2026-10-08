--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopDefinitions = require(ReplicatedStorage.Shared.ShopDefinitions)
local ShopRules = require(ReplicatedStorage.Shared.ShopRules)

local ShopService = {}
ShopService.__index = ShopService

local REQUEST_COOLDOWN = 0.35

function ShopService.new(runtimeState, playerState, progressionService, inventoryService, remotes)
    return setmetatable({
        runtimeState = runtimeState,
        playerState = playerState,
        progressionService = progressionService,
        inventoryService = inventoryService,
        remotes = remotes,
        lastRequests = {} :: {[Player]: number},
    }, ShopService)
end

function ShopService:Start()
    self.remotes.Commerce.OnServerEvent:Connect(function(player, request)
        self:HandleRequest(player, request)
    end)

    game:GetService("Players").PlayerRemoving:Connect(function(player)
        self.lastRequests[player] = nil
    end)
end

function ShopService:CanRequest(player: Player)
    local now = os.clock()
    local previous = self.lastRequests[player] or -math.huge

    if now - previous < REQUEST_COOLDOWN then
        return false
    end

    self.lastRequests[player] = now
    return true
end

function ShopService:HandleRequest(player: Player, request: any)
    if type(request) ~= "table" or not self:CanRequest(player) then
        return
    end

    local action = request.action

    if action == "Catalog" then
        self.remotes.Commerce:FireClient(player, "Catalog", self:GetCatalog(player))
    elseif action == "Purchase" then
        local ok, reason = self:Purchase(player, request.itemId)
        self.remotes.Commerce:FireClient(player, "PurchaseResult", {
            success = ok,
            reason = reason,
            inventory = self.inventoryService:GetSnapshot(player),
            credits = player:GetAttribute("CBS_Credits") or 0,
        })
    elseif action == "Equip" then
        local item = ShopDefinitions.Items[request.itemId]
        local slot = item and item.Slot

        if type(slot) ~= "string" then
            self.remotes.Commerce:FireClient(player, "EquipResult", {
                success = false,
                reason = "invalid_item",
            })
            return
        end

        local ok, reason = self.inventoryService:Equip(player, request.itemId, slot)
        self.remotes.Commerce:FireClient(player, "EquipResult", {
            success = ok,
            reason = reason,
            inventory = self.inventoryService:GetSnapshot(player),
        })
    end
end

function ShopService:GetCatalog(player: Player)
    local catalog = {}

    for itemId, item in pairs(ShopDefinitions.Items) do
        local entry = {
            ItemId = itemId,
            DisplayName = item.DisplayName,
            Category = item.Category,
            Currency = item.Currency,
            Premium = item.Premium,
            Active = item.Active,
            Owned = self.inventoryService:IsOwned(player, itemId),
        }

        if item.Category == "Upgrade" then
            local currentLevel = self.playerState:GetUpgradeLevel(player, item.UpgradeId)
            local Rules = require(ReplicatedStorage.Shared.ProgressionRules)
            entry.Level = currentLevel
            entry.MaxLevel = Rules.getMaxLevel(item.UpgradeId)
            entry.Price = Rules.getCost(item.UpgradeId, currentLevel)
        else
            entry.Price = item.Price
        end

        table.insert(catalog, entry)
    end

    table.sort(catalog, function(a, b)
        if a.Category == b.Category then
            return a.ItemId < b.ItemId
        end
        return a.Category < b.Category
    end)

    return catalog
end

function ShopService:Purchase(player: Player, itemId: any)
    if not ShopRules.isSafeShopPhase(self.runtimeState.phase) then
        return false, "shop_closed"
    end

    if type(itemId) ~= "string" then
        return false, "invalid_item"
    end

    local item = ShopDefinitions.Items[itemId]
    if not item or item.Active ~= true then
        return false, "item_unavailable"
    end

    if item.Category == "Upgrade" then
        return self.progressionService:Purchase(player, item.UpgradeId)
    end

    local profile = self.playerState:GetProfile(player)
    local state = self.playerState:Get(player)

    if not profile or not state then
        return false, "profile_unavailable"
    end

    local balance = state.credits
    local ok, reason = ShopRules.canPurchase(
        item,
        profile.Inventory.Owned,
        balance
    )

    if not ok then
        return false, reason
    end

    if not InventoryRulesSafeGrant(profile, itemId) then
        return false, "inventory_rejected"
    end

    local price = item.Price
    state.credits -= price
    profile.Credits = state.credits
    profile.Inventory.Owned[itemId] = true

    player:SetAttribute("CBS_Credits", state.credits)

    return true, "purchased"
end

function InventoryRulesSafeGrant(profile, itemId)
    if type(profile) ~= "table" or type(profile.Inventory) ~= "table" then
        return false
    end

    local owned = profile.Inventory.Owned
    return type(owned) == "table" and owned[itemId] ~= true
end

return ShopService
