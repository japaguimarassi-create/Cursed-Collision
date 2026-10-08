--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

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

    if player:GetAttribute("CBS_PvP") == true then
        return false
    end

    local rewarded = self.playerState:AddCredits(player, amount)
    if not rewarded then
        return false
    end

    self.playerState:MarkKill(player)
    return true
end

function EconomyService:RewardPvPKill(player: Player, amount: number)
    if not player.Parent then
        return false
    end

    local rewarded = self.playerState:AddCredits(player, amount)
    if not rewarded then
        return false
    end

    self.playerState:AddPvPKill(player)
    return true
end

function EconomyService:RewardWaveClear(multiplier: number?)
    local safeMultiplier = math.max(0, tonumber(multiplier) or 1)
    local reward = math.floor(Config.Economy.WaveClearReward * safeMultiplier)

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("CBS_PvP") ~= true then
            self.playerState:AddCredits(player, reward)
        end
    end
end

return EconomyService
