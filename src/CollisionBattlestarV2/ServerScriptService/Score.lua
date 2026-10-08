--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.Rules)

local Score = {}
Score.__index = Score

function Score.new(playerService, remotes)
    return setmetatable({
        players = playerService,
        remotes = remotes,
    }, Score)
end

function Score:Add(player: Player, amount: number, reason: string)
    local state = self.players:State(player)
    if not state then
        return false
    end

    local previous = state.profile.Score
    if not self.players:AddScore(player, amount) then
        return false
    end

    local current = self.players:State(player).profile.Score
    local oldLevel = Rules.levelForScore(previous)
    local newLevel = Rules.levelForScore(current)

    if newLevel > oldLevel then
        self.remotes.State:FireClient(player, "LevelUp", {
            level = newLevel,
            score = current,
            reason = reason,
        })
    end

    return true
end

function Score:Enemy(player: Player, reward: number, elite: boolean, boss: boolean)
    local points = math.max(5, math.floor(tonumber(reward) or 0))
    if elite then
        points += 30
    end
    if boss then
        points += 150
    end
    return self:Add(player, points, boss and "boss" or elite and "elite" or "enemy")
end

function Score:Wave(wave: number, boss: boolean)
    local points = 50 + math.floor(wave * 5)
    if boss then
        points += 200
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("CBS_PvP") ~= true then
            self:Add(player, points, "wave")
        end
    end
end

function Score:PVP(player: Player)
    return self:Add(player, 150, "pvp")
end

function Score:Start()
end

function Score:Stop()
end

function Score:Reload()
end

return Score
