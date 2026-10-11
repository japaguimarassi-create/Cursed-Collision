local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MonetizationIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MonetizationIds"))

local StackableProductService = {}
local profiles
local notify
local promptRemote
local requestCooldown = {}
local processingReceipts = {}
local started = false

local PRODUCTS = table.freeze({
    StackableSpeed = table.freeze({
        StatName = "Speed",
        DisplayName = "Velocidade",
        Amount = Config.StackableProducts.SpeedAmount,
        Maximum = Config.MaxSpeedLevel,
    }),
    StackableStrength = table.freeze({
        StatName = "Strength",
        DisplayName = "Força",
        Amount = Config.StackableProducts.StrengthAmount,
        Maximum = Config.MaxStrength,
    }),
})

local function productIdFor(key)
    local value = MonetizationIds.Products[key]
    return type(value) == "number" and value or 0
end

local function getProductById(productId)
    for key, product in pairs(PRODUCTS) do
        local id = productIdFor(key)
        if id > 0 and id == productId then
            return key, product
        end
    end

    return nil, nil
end

function StackableProductService.Start(profileService, requestProductRemote, promptProductRemote, notifyFunction)
    if started then
        return
    end

    started = true
    profiles = profileService
    promptRemote = promptProductRemote
    notify = notifyFunction

    requestProductRemote.OnServerEvent:Connect(function(player, productKey)
        if type(productKey) ~= "string" or PRODUCTS[productKey] == nil then
            return
        end

        if player.Parent ~= Players or not profiles.IsLoaded(player) then
            return
        end

        local now = os.clock()
        if now - (requestCooldown[player] or 0) < 2 then
            return
        end
        requestCooldown[player] = now

        local product = PRODUCTS[productKey]
        local data = profiles.Get(player)
        if not data then
            return
        end

        if data[product.StatName] >= product.Maximum then
            notify(player, product.DisplayName .. " já está no nível máximo.", "Info")
            return
        end

        local productId = productIdFor(productKey)
        if productId <= 0 then
            notify(player, "Este produto acumulável ainda precisa ser criado no Creator Dashboard e ter seu ID configurado.", "Warning")
            return
        end

        promptRemote:FireClient(player, productId)
    end)

    MarketplaceService.ProcessReceipt = function(receiptInfo)
        if type(receiptInfo) ~= "table"
            or type(receiptInfo.ProductId) ~= "number"
            or type(receiptInfo.PlayerId) ~= "number"
            or type(receiptInfo.PurchaseId) ~= "string"
            or receiptInfo.PurchaseId == "" then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local productKey, product = getProductById(receiptInfo.ProductId)
        if not product then
            warn("RoubeUmAnimal: recibo de Developer Product desconhecido: " .. tostring(receiptInfo.ProductId))
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local purchaseId = receiptInfo.PurchaseId
        if processingReceipts[purchaseId] then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player or not profiles.IsLoaded(player) then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        processingReceipts[purchaseId] = true
        local callSucceeded, granted, amountGranted, duplicate = pcall(
            profiles.GrantStackableProduct,
            player,
            purchaseId,
            product.StatName,
            product.Amount
        )
        processingReceipts[purchaseId] = nil

        if not callSucceeded or not granted then
            warn("RoubeUmAnimal: recibo não persistido para UserId " .. tostring(receiptInfo.PlayerId) .. ": " .. tostring(amountGranted))
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        if not duplicate and amountGranted > 0 then
            notify(player, "Compra confirmada: +" .. tostring(amountGranted) .. " de " .. product.DisplayName .. ". O bônus foi salvo.", "Success")
        elseif not duplicate then
            notify(player, "Compra confirmada, mas o atributo já estava no limite máximo.", "Info")
        end

        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end

function StackableProductService.RemovePlayer(player)
    requestCooldown[player] = nil
end

return StackableProductService
