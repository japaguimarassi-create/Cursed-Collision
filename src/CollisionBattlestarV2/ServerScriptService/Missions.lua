--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Shared.MissionDefinitions)

local Missions = {}
Missions.__index = Missions

function Missions.new(playerService, remotes)
    return setmetatable({
        players = playerService,
        remotes = remotes,
    }, Missions)
end

function Missions:Add(player: Player, id: string, amount: number)
    local state = self.players:State(player)
    local definition = Definitions[id]
    if not state or not definition then
        return
    end

    local old = state.profile.Missions[id] or 0
    local nextValue = math.min(definition.Goal, old + math.max(0, math.floor(amount)))
    if nextValue == old then
        return
    end

    state.profile.Missions[id] = nextValue
    self.players.persistence:MarkDirty(player)

    if nextValue >= definition.Goal then
        self.players:AddCredits(player, definition.Reward)
        self.remotes.State:FireClient(player, "MissionComplete", {
            id = id,
            reward = definition.Reward,
        })
    end
end

function Missions:Enemy(_, elite, boss, killer: Player?)
    if not killer then
        return
    end
    if elite then
        self:Add(killer, "Elites", 1)
    end
    if boss then
        self:Add(killer, "Bosses", 1)
    end
end

function Missions:Wave(wave: number)
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("CBS_PvP") ~= true then
            self:Add(player, "Waves", 1)
        end
    end
end

function Missions:Snapshot(player: Player)
    local state = self.players:State(player)
    if not state then
        return {}
    end

    local out = {}
    for id, definition in pairs(Definitions) do
        out[id] = {
            id = id,
            name = definition.Name,
            progress = state.profile.Missions[id] or 0,
            goal = definition.Goal,
            reward = definition.Reward,
        }
    end
    return out
end

function Missions:Start()
end

function Missions:Stop()
end

function Missions:Reload()
end

return Missions
