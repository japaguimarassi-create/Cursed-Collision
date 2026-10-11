local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ShopService = {}
local profiles
local animalService
local notify
local requestRemote
local cooldowns = {}
local started = false

local function priceFor(stat, data)
    if stat == "Speed" then
        if data.Speed >= Config.MaxSpeedLevel then
            return nil
        end

        return math.min(
            Config.CoinsLimit,
            math.floor(Config.Upgrades.SpeedBaseCost * (Config.Upgrades.SpeedCostGrowth ^ data.Speed))
        )
    end

    if stat == "Strength" then
        if data.Strength >= Config.MaxStrength then
            return nil
        end

        local tier = math.max(0, math.floor((data.Strength - 10) / 5))
        return math.min(
            Config.CoinsLimit,
            math.floor(Config.Upgrades.StrengthBaseCost * (Config.Upgrades.StrengthCostGrowth ^ tier))
        )
    end

    return nil
end

function ShopService.Start(profileService, animals, remote, notifyFunction)
    if started then
        return
    end

    started = true
    profiles = profileService
    animalService = animals
    requestRemote = remote
    notify = notifyFunction

    requestRemote.OnServerEvent:Connect(function(player, stat)
        if type(stat) ~= "string" or (stat ~= "Speed" and stat ~= "Strength") then
            return
        end

        if not profiles.IsLoaded(player) then
            return
        end

        local now = os.clock()
        local last = cooldowns[player] or 0

        if now - last < 0.35 then
            return
        end

        cooldowns[player] = now

        local data = profiles.Get(player)
        local cost = data and priceFor(stat, data)

        if not cost then
            notify(player, "Este atributo já está no nível máximo.", "Info")
            return
        end

        if data.Coins < cost then
            notify(player, "Você precisa de " .. tostring(cost) .. " Moedas.", "Warning")
            return
        end

        local spent = profiles.SpendCoins(player, cost)

        if not spent then
            notify(player, "Saldo insuficiente. A compra foi cancelada.", "Warning")
            return
        end

        local gained = profiles.AddStat(player, stat, stat == "Speed" and 1 or 5)

        if not gained then
            profiles.AddCoins(player, cost)
            notify(player, "Falha no upgrade. As moedas foram devolvidas.", "Error")
            return
        end

        animalService.ApplyMovement(player)

        local statLabel = stat == "Speed" and "Velocidade" or "Força"
        notify(player, statLabel .. " aprimorada por " .. tostring(cost) .. " Moedas.", "Success")
    end)
end

function ShopService.RemovePlayer(player)
    cooldowns[player] = nil
end

return ShopService
