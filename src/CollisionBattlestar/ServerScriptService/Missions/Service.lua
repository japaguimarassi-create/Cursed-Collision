--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Shared.MissionDefinitions)
local Rules = require(ReplicatedStorage.Shared.MissionRules)

local MissionService = {}
MissionService.__index = MissionService

function MissionService.new(playerState, enemyService, runtimeState, remotes)
    return setmetatable({
        playerState = playerState,
        enemyService = enemyService,
        runtimeState = runtimeState,
        remotes = remotes,
        lastCredits = {} :: {[Player]: number},
        lastWave = 0,
        running = false,
    }, MissionService)
end

function MissionService:Start()
    if self.running then
        return
    end

    self.running = true

    self.defeatConnection = self.enemyService:GetDefeatedEvent():Connect(function(_, isElite)
        for _, player in ipairs(Players:GetPlayers()) do
            if isElite then
                self:AddProgress(player, "EliteBreaker", 1)
            end
        end
    end)

    self.stateConnection = self.runtimeState:GetChangedEvent():Connect(function()
        if self.runtimeState.phase ~= "Intermission" then
            return
        end

        local wave = self.runtimeState.wave
        if wave <= self.lastWave then
            return
        end

        self.lastWave = wave

        for _, player in ipairs(Players:GetPlayers()) do
            self:AddProgress(player, "WaveHunter", 1)
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:WatchPlayer(player)
    end

    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:WatchPlayer(player)
    end)

    self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        self.lastCredits[player] = nil
    end)

    self.remotes.Mission.OnServerEvent:Connect(function(player, request)
        if type(request) == "table" and request.action == "Snapshot" then
            self:Publish(player)
        end
    end)
end

function MissionService:WatchPlayer(player: Player)
    self.lastCredits[player] = player:GetAttribute("CBS_Credits") or 0

    player:GetAttributeChangedSignal("CBS_Credits"):Connect(function()
        local current = player:GetAttribute("CBS_Credits") or 0
        local previous = self.lastCredits[player] or current
        self.lastCredits[player] = current

        local gained = current - previous
        if gained > 0 then
            self:AddProgress(player, "CreditCollector", gained)
        end
    end)
end

function MissionService:AddProgress(player: Player, missionId: string, amount: number)
    local profile = self.playerState:GetProfile(player)
    local definition = Definitions[missionId]

    if not profile or not definition then
        return false
    end

    local mission = profile.Missions[missionId]
    if not Rules.isValid(mission) or mission.Completed then
        return false
    end

    local before = mission.Progress
    mission.Progress = Rules.progress(before, amount, definition.Goal)

    if Rules.shouldComplete(mission.Progress, definition.Goal) then
        mission.Completed = true
        self.playerState:AddCredits(player, definition.Reward)
        self.remotes.Mission:FireClient(player, "Completed", {
            missionId = missionId,
            reward = definition.Reward,
        })
    end

    self:Publish(player)
    return mission.Progress ~= before
end

function MissionService:GetSnapshot(player: Player)
    local profile = self.playerState:GetProfile(player)
    if not profile then
        return {}
    end

    local output = {}

    for missionId, definition in pairs(Definitions) do
        local mission = profile.Missions[missionId]
        output[missionId] = {
            Id = missionId,
            DisplayName = definition.DisplayName,
            Progress = mission.Progress,
            Goal = definition.Goal,
            Reward = definition.Reward,
            Completed = mission.Completed,
        }
    end

    return output
end

function MissionService:Publish(player: Player)
    self.remotes.Mission:FireClient(player, "Snapshot", self:GetSnapshot(player))
end

function MissionService:Stop()
    self.running = false

    if self.defeatConnection then
        self.defeatConnection:Disconnect()
        self.defeatConnection = nil
    end

    if self.stateConnection then
        self.stateConnection:Disconnect()
        self.stateConnection = nil
    end

    if self.playerAddedConnection then
        self.playerAddedConnection:Disconnect()
        self.playerAddedConnection = nil
    end

    if self.playerRemovingConnection then
        self.playerRemovingConnection:Disconnect()
        self.playerRemovingConnection = nil
    end
end

return MissionService
