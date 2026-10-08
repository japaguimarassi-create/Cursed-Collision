--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Definitions = require(game:GetService("ReplicatedStorage").Shared.MonetizationDefinitions)

local MonetizationService = {}
MonetizationService.__index = MonetizationService

function MonetizationService.new()
    return setmetatable({
        gamePasses = Definitions.GamePasses,
        products = Definitions.DeveloperProducts,
        productGrants = {},
    }, MonetizationService)
end

function MonetizationService:Start()
    if next(self.products) == nil then
        return
    end

    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return self:ProcessReceipt(receiptInfo)
    end
end

function MonetizationService:IsConfiguredProduct(productId: number)
    for _, configuredId in pairs(self.products) do
        if configuredId == productId and productId > 0 then
            return true
        end
    end

    return false
end

function MonetizationService:PromptDeveloperProduct(player: Player, productId: number)
    if not self:IsConfiguredProduct(productId) then
        return false, "product_not_configured"
    end

    local success, err = pcall(function()
        MarketplaceService:PromptProductPurchase(player, productId)
    end)

    return success, success and "prompted" or tostring(err)
end

function MonetizationService:OwnsGamePass(player: Player, gamePassId: number)
    if type(gamePassId) ~= "number" or gamePassId <= 0 then
        return false
    end

    local success, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
    end)

    return success and owns == true
end

function MonetizationService:ProcessReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    if not self:IsConfiguredProduct(receiptInfo.ProductId) then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local grant = self.productGrants[receiptInfo.ProductId]

    if type(grant) ~= "function" then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local success = pcall(function()
        grant(player, receiptInfo)
    end)

    if success then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

return MonetizationService
