--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager: any = require(script.Parent.CombatCore.StateManager)

local remotes = RemoteService:Get()

local cooldownUntil: {[Player]: number} = {}
local active: {[Player]: string} = {}
local healthConnections: {[Player]: RBXScriptConnection} = {}
local attributeConnections: {[Player]: {RBXScriptConnection}} = {}

local function stop(player: Player)
    if not active[player] then
        return
    end

    active[player] = nil
    remotes.EmoteEvent:FireAllClients("Stop", {
        UserId = player.UserId
    })
end

local function clear(player: Player)
    stop(player)
    cooldownUntil[player] = nil

    if healthConnections[player] then
        healthConnections[player]:Disconnect()
        healthConnections[player] = nil
    end

    for _, connection in ipairs(attributeConnections[player] or {}) do
        connection:Disconnect()
    end
    attributeConnections[player] = nil
end

local function canUse(player: Player): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local state = StateManager:Get(player)
    if not state then
        return false
    end

    -- O servidor continua sendo a autoridade: em ataque, stun ou ragdoll o emote não inicia.
    if player:GetAttribute("IsAttacking") == true
        or player:GetAttribute("CombatStunned") == true
        or player:GetAttribute("Ragdolled") == true
        or state.Blocking then
        return false
    end

    return state.StunnedUntil <= os.clock()
        and state.RecoveryUntil <= os.clock()
end

local function watchCharacter(player: Player, character: Model)
    clear(player)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        healthConnections[player] = humanoid.HealthChanged:Connect(function(health)
            if healthConnections[player] and health < humanoid.MaxHealth then
                stop(player)
            end
        end)
    end

    local connections: {RBXScriptConnection} = {}

    for _, attribute in ipairs({"IsAttacking", "CombatStunned", "Ragdolled", "Blocking"}) do
        table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(function()
            if player:GetAttribute(attribute) == true then
                stop(player)
            end
        end))
    end

    attributeConnections[player] = connections
end

local function setup(player: Player)
    if player.Character then
        watchCharacter(player, player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        watchCharacter(player, character)
    end)
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(clear)

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

remotes.EmoteAction.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or #action > 24 or type(payload) ~= "table" then
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
        active[player] = id
        cooldownUntil[player] = now + 0.18

        remotes.EmoteEvent:FireAllClients("Play", {
            UserId = player.UserId,
            Id = id,
            Name = emote.Name,
            Category = emote.Category,
            Duration = emote.Duration,
            Loop = emote.Loop,
            AnimationId = emote.AnimationId,
            Priority = emote.Priority
        })

        task.delay(emote.Duration + 0.05, function()
            if player.Parent and active[player] == id then
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

return nil
