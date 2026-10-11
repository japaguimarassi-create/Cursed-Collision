local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MonetizationIds"))

local PassService = {}
local ownership = {}
local promptCooldown = {}
local notify
local promptRemote
local ids = MonetizationIds.Passes
local started = false
local applyMovement

local ATTRIBUTE_NAMES = table.freeze({
    DoubleIncome = "HasDoubleIncome",
    DoubleSpeed = "HasDoubleSpeed",
    VIPFarm = "HasVIPFarm",
    ExtraBarnSlots = "HasExtraBarnSlots",
})

function PassService.Has(player, passName)
    local values = ownership[player]
    return values ~= nil and values[passName] == true
end

local function setOwnership(player, passName, owns)
    ownership[player] = ownership[player] or {}
    ownership[player][passName] = owns == true
    local attribute = ATTRIBUTE_NAMES[passName]
    if attribute then
        player:SetAttribute(attribute, owns == true)
    end
    if applyMovement then
        applyMovement(player)
    end
end

function PassService.Load(player)
    if player.Parent ~= Players then
        return false
    end
    local state = {}
    for name in pairs(ids) do
        state[name] = false
    end
    for name, passId in pairs(ids) do
        if type(passId) == "number" and passId > 0 and player.Parent == Players then
            local success, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            if success then
                state[name] = owns == true
            else
                warn("StealAnAnimal: could not verify game pass " .. name .. " for user " .. player.UserId)
            end
        end
    end
    if player.Parent ~= Players then
        return false
    end
    ownership[player] = state
    for passName, attributeName in pairs(ATTRIBUTE_NAMES) do
        player:SetAttribute(attributeName, state[passName] == true)
    end
    if applyMovement then
        applyMovement(player)
    end
    return true
end

function PassService.Start(requestRemote, promptClientRemote, notifyFunction, movementCallback)
    if started then
        return
    end
    started = true
    promptRemote = promptClientRemote
    notify = notifyFunction
    applyMovement = movementCallback

    requestRemote.OnServerEvent:Connect(function(player, passName)
        if player.Parent ~= Players or type(passName) ~= "string" or ids[passName] == nil then
            return
        end
        local now = os.clock()
        if now - (promptCooldown[player] or 0) < 2 then
            return
        end
        promptCooldown[player] = now
        local passId = ids[passName]
        if type(passId) ~= "number" or passId <= 0 then
            notify(player, "This pass is not configured in the Creator Dashboard yet.", "Warning")
            return
        end
        if PassService.Has(player, passName) then
            notify(player, "You already own this permanent pass.", "Info")
            return
        end
        promptRemote:FireClient(player, passId)
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
        if not purchased or not player or player.Parent ~= Players then
            return
        end
        local matched
        for name, passId in pairs(ids) do
            if passId > 0 and passId == gamePassId then
                matched = name
                break
            end
        end
        if not matched then
            return
        end
        task.spawn(function()
            local success, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
            end)
            if player.Parent ~= Players then
                return
            end
            if not success or not owns then
                notify(player, "Purchase ownership could not be confirmed. Try again later.", "Warning")
                return
            end
            setOwnership(player, matched, true)
            notify(player, "Activated pass: " .. matched .. ".", "Success")
        end)
    end)
end

function PassService.RemovePlayer(player)
    ownership[player] = nil
    promptCooldown[player] = nil
end

return PassService
