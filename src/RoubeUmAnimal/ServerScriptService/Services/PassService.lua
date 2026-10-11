local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PassService = {}
local ownership = {}
local promptCooldown = {}
local notify
local promptRemote
local ids = {}
local started = false
local applyMovement

local function idFor(passName)
    if passName == "DoubleCoins" then
        return ids.DoubleCoins
    end

    if passName == "VIPSpeed" then
        return ids.VIPSpeed
    end

    return 0
end

function PassService.Has(player, passName)
    local values = ownership[player]
    return values ~= nil and values[passName] == true
end

function PassService.Load(player)
    ownership[player] = {
        DoubleCoins = false,
        VIPSpeed = false,
    }

    for name, passId in pairs(ids) do
        if passId > 0 and player.Parent then
            local success, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)

            if success then
                ownership[player][name] = owns == true
            else
                warn("RoubeUmAnimal: não foi possível verificar " .. name .. " para " .. player.UserId)
            end
        end
    end

    player:SetAttribute("HasDoubleCoins", ownership[player].DoubleCoins)
    player:SetAttribute("HasVIPSpeed", ownership[player].VIPSpeed)

    if applyMovement and player.Parent then
        applyMovement(player)
    end
end

function PassService.Start(promptRequestRemote, promptClientRemote, notifyFunction, movementCallback)
    if started then
        return
    end

    started = true
    promptRemote = promptClientRemote
    notify = notifyFunction
    applyMovement = movementCallback

    ids = {
        DoubleCoins = Config.DoubleCoinsGamepassId,
        VIPSpeed = Config.VipSpeedGamepassId,
    }

    promptRequestRemote.OnServerEvent:Connect(function(player, passName)
        if type(passName) ~= "string" or (passName ~= "DoubleCoins" and passName ~= "VIPSpeed") then
            return
        end

        local now = os.clock()
        local lastPrompt = promptCooldown[player] or 0

        if now - lastPrompt < 2 then
            return
        end

        promptCooldown[player] = now

        local passId = idFor(passName)

        if passId <= 0 then
            notify(player, "O criador ainda precisa configurar o ID deste gamepass no Config.lua.", "Warning")
            return
        end

        if PassService.Has(player, passName) then
            notify(player, "Você já possui este gamepass.", "Info")
            return
        end

        promptRemote:FireClient(player, passId)
    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
        if not purchased or not player or not player.Parent then
            return
        end

        local matched = nil

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

            if not success or not owns then
                notify(player, "Compra recebida; a posse ainda não pôde ser confirmada. Aguarde e tente novamente.", "Warning")
                return
            end

            ownership[player] = ownership[player] or {}
            ownership[player][matched] = true
            player:SetAttribute(matched == "DoubleCoins" and "HasDoubleCoins" or "HasVIPSpeed", true)

            if applyMovement then
                applyMovement(player)
            end

            notify(player, "Gamepass ativado: " .. matched .. ".", "Success")
        end)
    end)
end

function PassService.RemovePlayer(player)
    ownership[player] = nil
    promptCooldown[player] = nil
end

return PassService
