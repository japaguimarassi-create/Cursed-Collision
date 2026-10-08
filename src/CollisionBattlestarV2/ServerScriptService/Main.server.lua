--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = true

local Network = require(ReplicatedStorage.Shared.Network)
local RuntimeState = require(script.Parent.Core.State)
local Heart = require(script.Parent.Core.Heart)
local Persistence = require(script.Parent.Persistence)
local World = require(script.Parent.World)
local PlayerService = require(script.Parent.Players)
local Missions = require(script.Parent.Missions)
local Score = require(script.Parent.Score)
local Enemies = require(script.Parent.Enemies)
local Waves = require(script.Parent.Waves)
local PvP = require(script.Parent.PvP)
local Combat = require(script.Parent.Combat)
local Shop = require(script.Parent.Shop)
local Echo = require(script.Parent.Echo)
local Ranking = require(script.Parent.Ranking)

local remotes = Network.ensure()
local runtime = RuntimeState.new()
local heart = Heart.new(runtime)

local persistence = Persistence.new()
local world = World.new()
local players = PlayerService.new(persistence)
local missions = Missions.new(players, remotes)
local score = Score.new(players, remotes)
local pvp = PvP.new(world, score, remotes)
local enemies = Enemies.new(world, players, score, remotes, heart)
local combat = Combat.new(players, enemies, pvp, remotes, heart)
local waves = Waves.new(runtime, world, enemies, score, remotes, heart, missions)
local shop = Shop.new(players, remotes, runtime)
local echo = Echo.new(players, enemies, remotes)
local ranking = Ranking.new(players, remotes)

heart:Register("Persistence", persistence)
heart:Register("World", world)
heart:Register("Players", players)
heart:Register("Score", score)
heart:Register("Missions", missions)
heart:Register("PvP", pvp)
heart:Register("Echo", echo)
heart:Register("Shop", shop)
heart:Register("Enemies", enemies)
heart:Register("Combat", combat)
heart:Register("Waves", waves)
heart:Register("Ranking", ranking)

local stateRequestAt = {}

enemies:GetDefeated():Connect(function(_, elite, boss, killer)
    missions:Enemy(nil, elite, boss, killer)
end)

runtime:Changed():Connect(function()
    remotes.State:FireAllClients("Snapshot", runtime:Snapshot())
end)

Players.PlayerRemoving:Connect(function(player)
    stateRequestAt[player] = nil
end)

remotes.State.OnServerEvent:Connect(function(player, request)
    if type(request) ~= "table" then
        return
    end

    local now = os.clock()
    if now - (stateRequestAt[player] or -math.huge) < 0.5 then
        return
    end
    stateRequestAt[player] = now

    if request.action == "RequestState" then
        remotes.State:FireClient(player, "Snapshot", runtime:Snapshot())
    elseif request.action == "Missions" then
        remotes.State:FireClient(player, "Missions", missions:Snapshot(player))
    end
end)

local started = heart:Start()

if not started then
    runtime:SetMany({
        phase = "Error",
        error = "runtime failed to start",
    })
else
    workspace:SetAttribute("CBS2_WorldReady", true)
    workspace:SetAttribute("CBS2_RuntimeGeneration", heart.generation)
end

remotes.State:FireAllClients("Snapshot", runtime:Snapshot())

game:BindToClose(function()
    heart:Stop()

    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            persistence:Save(player, true)
        end)
    end
end)
