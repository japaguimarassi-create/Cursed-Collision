local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MonetizationIds"))
local PassService = {}
local ownership = {}
local promptCooldown = {}
local notify
local promptRemote
local applyMovement
local started = false

local ids = MonetizationIds.Passes
local attributes = table.freeze({
    DoubleIncome = "HasDoubleIncome",
    DoubleSpeed = "HasDoubleSpeed",
    VIPFarm = "HasVIPFarm",
    ExtraBarnSlots = "HasExtraBarnSlots",
})

function PassService.Has(player, passName)
    return ownership[player] ~= nil and ownership[player][passName] == true
end

local function setOwnership(player, passName, owns)
    ownership[player] = ownership[player] or {}
    ownership[player][passName] = owns == true
    local attribute = attributes[passName]
    if attribute then
        player:SetAttribute(attribute, owns == true)
    end
    if applyMovement then
        applyMovement(player)
    end
end

function PassService.Load(player)
    if not player or player.Parent ~= Players then
        return false
    end
    local state = {}
    for name in pairs(ids) do
        state[name] = false
    end
    for name, passId in pairs(ids) do
        if type(passId) == "number" and passId > 0 and player.Parent == Players then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            if ok then
                state[name] = owns == true
            else
                warn("StealAnAnimal could not verify pass " .. name)
            end
        end
    end
    if player.Parent ~= Players then
        return false
    end
    ownership[player] = state
    for name, attribute in pairs(attributes) do
        player:SetAttribute(attribute, state[name] == true)
    end
    if applyMovement then
        applyMovement(player)
    end
    return true
end

function PassService.Start(requestRemote, purchasePromptRemote, notifyFunction, movementCallback)
    if started then
        return
    end
    started = true
    promptRemote = purchasePromptRemote
    notify = notifyFunction
    applyMovement = movementCallback

    requestRemote.OnServerEvent:Connect(function(player, passName)
        if not player or player.Parent ~= Players or type(passName) ~= "string" or ids[passName] == nil then
            return
        end
        local now = os.clock()
        if now - (promptCooldown[player] or 0) < 2 then
            return
        end
        promptCooldown[player] = now
        local passId = ids[passName]
        if type(passId) ~= "number" or passId <= 0 then
            notify(player, "Este passe ainda não tem um ID configurado no Creator Dashboard.", "Warning")
            return
        end
        if PassService.Has(player, passName) then
            notify(player, "Você já possui este passe permanente.", "Info")
            return
        end
        promptRemote:FireClient(player, passId)
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
        if not purchased or not player or player.Parent ~= Players then
            return
        end
        local matched
        for name, configuredId in pairs(ids) do
            if configuredId > 0 and configuredId == passId then
                matched = name
                break
            end
        end
        if not matched then
            return
        end
        task.spawn(function()
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            if player.Parent ~= Players then
                return
            end
            if not ok or not owns then
                notify(player, "Não foi possível confirmar a compra agora.", "Warning")
                return
            end
            setOwnership(player, matched, true)
            notify(player, "Passe ativado: " .. matched .. ".", "Success")
        end)
    end)
end

function PassService.RemovePlayer(player)
    ownership[player] = nil
    promptCooldown[player] = nil
end

return PassService
