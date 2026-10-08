--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({
        enabled = true,
    }, Service)
end

function Service:Start()
    for _, player in ipairs(Players:GetPlayers()) do
        self:Log(player, "SessionStart")
    end

    Players.PlayerAdded:Connect(function(player)
        self:Log(player, "SessionStart")
    end)
end

function Service:Log(player: Player, eventName: string, value: number?, fields: {[string]: any}?)
    if not self.enabled or not player or not player.Parent then
        return false
    end

    local success = pcall(function()
        AnalyticsService:LogCustomEvent(
            player,
            eventName,
            value or 1,
            fields or {}
        )
    end)

    return success
end

function Service:LogEconomy(player: Player, amount: number, endingBalance: number, transactionType: string, itemSku: string)
    if not self.enabled or not player or not player.Parent then
        return false
    end

    local success = pcall(function()
        AnalyticsService:LogEconomyEvent(
            player,
            amount >= 0 and Enum.AnalyticsEconomyFlowType.Source or Enum.AnalyticsEconomyFlowType.Sink,
            "Credits",
            math.abs(amount),
            math.max(0, endingBalance),
            transactionType,
            itemSku,
            {}
        )
    end)

    return success
end

return Service
