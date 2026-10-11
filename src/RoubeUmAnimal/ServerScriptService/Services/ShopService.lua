local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayRules"))

local ShopService = {}
local profiles
local animalService
local passService
local notify
local requestRemote
local cooldowns = {}
local started = false

function ShopService.Start(profileService, animals, passes, remote, notifyFunction)
    if started then
        return
    end
    started = true
    profiles = profileService
    animalService = animals
    passService = passes
    requestRemote = remote
    notify = notifyFunction

    requestRemote.OnServerEvent:Connect(function(player, statName)
        if statName ~= "Speed" or not profiles.IsLoaded(player) or player:GetAttribute("RebirthInProgress") then
            return
        end
        local now = os.clock()
        if now - (cooldowns[player] or 0) < 0.4 then
            return
        end
        cooldowns[player] = now

        local data = profiles.Get(player)
        local cost = data and Rules.UpgradePrice("Speed", data, Config)
        if not cost then
            notify(player, "Speed is already at the maximum level.", "Info")
            return
        end
        if data.Coins < cost then
            notify(player, "You need " .. tostring(cost) .. " coins for the next speed upgrade.", "Warning")
            return
        end
        local spent = profiles.SpendCoins(player, cost)
        if not spent then
            notify(player, "The upgrade was cancelled because your balance changed.", "Warning")
            return
        end
        local amount = passService.Has(player, "DoubleSpeed") and Config.Training.DoubleSpeedMultiplier or 1
        local upgraded = profiles.AddStat(player, "Speed", amount)
        if not upgraded then
            profiles.AddCoins(player, cost)
            notify(player, "Upgrade failed safely. Your coins were refunded.", "Error")
            return
        end
        animalService.ApplyMovement(player)
        notify(player, "Speed upgraded for " .. tostring(cost) .. " coins.", "Success")
    end)
end

function ShopService.RemovePlayer(player)
    cooldowns[player] = nil
end

return ShopService
