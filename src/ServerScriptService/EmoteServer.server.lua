--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager: any = require(script.Parent.CombatCore.StateManager)

local remotes = RemoteService:Get()

type ActiveEmote = {
    Id: string,
    StartedAt: number,
    HealthAtStart: number
}

local active: {[Player]: ActiveEmote} = {}
local cooldownUntil: {[Player]: number} = {}
local healthConnections: {[Player]: RBXScriptConnection} = {}

local function clearHealthConnection(player: Player)
    local connection = healthConnections[player]
    if connection then
        connection:Disconnect()
        healthConnections[player] = nil
    end
end

local function stop(player: Player)
    if not active[player] then
        return
    end

    active[player] = nil
    remotes.EmoteEvent:FireAllClients("Stop", {
        UserId = player.UserId
    })
end

local function isBlocked(player: Player): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return true
    end

    if player:GetAttribute("IsAttacking") == true
        or player:GetAttribute("Stunned") == true
        or player:GetAttribute("CombatStunned") == true
        or player:GetAttribute("Ragdolled") == true
        or player:GetAttribute("IsRagdolled") == true
        or player:GetAttribute("Blocking") == true then
        return true
    end

    local state = StateManager:Get(player)
    if not state then
        return true
    end

    return state.StunnedUntil > os.clock()
        or state.RagdollUntil > os.clock()
        or state.RecoveryUntil > os.clock()
end

local function canUse(player: Player): boolean
    return not isBlocked(player)
end

local function bindCharacter(player: Player, character: Model)
    stop(player)
    clearHealthConnection(player)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    healthConnections[player] = humanoid.HealthChanged:Connect(function(health)
        local current = active[player]
        if current and health < current.HealthAtStart - 0.01 then
            stop(player)
        end
    end)
end

local function setup(player: Player)
    player.CharacterAdded:Connect(function(character)
        bindCharacter(player, character)
    end)

    if player.Character then
        bindCharacter(player, player.Character)
    end
end

Players.PlayerAdded:Connect(setup)

Players.PlayerRemoving:Connect(function(player)
    stop(player)
    clearHealthConnection(player)
    cooldownUntil[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

remotes.EmoteAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string"
        or #action > 24
        or type(payload) ~= "table" then
        return
    end

    if action == "Start" then
        if not canUse(player) then
            return
        end

        local now = os.clock()
        if (cooldownUntil[player] or 0) > now then
            return
        end

        local id = type(payload.Id) == "string" and payload.Id or ""
        local emote = Emotes[id]
        local data = DataService:Get(player)

        if not emote or not data or data.OwnedEmotes[id] ~= true then
            return
        end

        stop(player)

        local humanoid = player.Character
            and player.Character:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            return
        end

        active[player] = {
            Id = id,
            StartedAt = now,
            HealthAtStart = humanoid.Health
        }
        cooldownUntil[player] = now + 0.18

        remotes.EmoteEvent:FireAllClients("Play", {
            UserId = player.UserId,
            Id = id,
            Name = emote.Name,
            Category = emote.Category,
            Duration = emote.Duration,
            Loop = emote.Loop,
            AnimationKey = emote.AnimationKey,
            AnimationId = emote.AnimationId,
            Priority = emote.Priority.Name,
            Accent = emote.Accent
        })

        task.delay(emote.Duration + 0.05, function()
            if player.Parent and active[player] and active[player].Id == id then
                stop(player)
            end
        end)

    elseif action == "Stop" then
        stop(player)

    elseif action == "SetWheel" then
        local data = DataService:Get(player)
        local ids = type(payload.Ids) == "table" and payload.Ids or nil

        if not data or not ids or #ids ~= 5 then
            return
        end

        local nextWheel: {string} = {}
        local seen: {[string]: boolean} = {}

        for index = 1, 5 do
            local id = ids[index]
            if type(id) ~= "string"
                or not Emotes[id]
                or data.OwnedEmotes[id] ~= true
                or seen[id] then
                return
            end

            seen[id] = true
            nextWheel[index] = id
        end

        data.EmoteWheel = nextWheel
        DataService:MarkDirty(player)
    end
end)

RunService.Heartbeat:Connect(function()
    for player, current in pairs(active) do
        if not player.Parent then
            active[player] = nil
            continue
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not humanoid or humanoid.Health <= 0 then
            stop(player)
            continue
        end

        if isBlocked(player)
            or humanoid.MoveDirection.Magnitude > 0.05 then
            stop(player)
            continue
        end

        if humanoid.Health < current.HealthAtStart - 0.01 then
            stop(player)
        end
    end
end)

return nil
