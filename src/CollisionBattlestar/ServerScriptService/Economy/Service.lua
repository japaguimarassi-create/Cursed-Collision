--!strict

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(playerState)
    return setmetatable({
        playerState = playerState,
    }, EconomyService)
end

function EconomyService:Start()
end

function EconomyService:RewardEnemyDefeat(player: Player, amount: number)
    if not player.Parent then
        return false
    end

    local rewarded = self.playerState:AddCredits(player, amount)
    if not rewarded then
        return false
    end

    self.playerState:MarkKill(player)
    return true
end

function EconomyService:RewardWaveClear(multiplier: number?)
    local safeMultiplier = math.max(0, tonumber(multiplier) or 1)
    local reward = math.floor(Config.Economy.WaveClearReward * safeMultiplier)

    for _, player in ipairs(Players:GetPlayers()) do
        self.playerState:AddCredits(player, reward)
    end
end

function EconomyService:TryUpgrade(player: Player)
    return self.playerState:TryUpgrade(player)
end

return EconomyService
