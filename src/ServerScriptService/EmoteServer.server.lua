--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager = require(script.Parent.CombatCore.StateManager)

local remotes = RemoteService:Get()

local cooldownUntil: {[Player]: number} = {}
local active: {[Player]: string} = {}

local function stop(player: Player)
    local id = active[player]
    if not id then
        return
    end

    active[player] = nil

    remotes.EmoteEvent:FireAllClients("Stop", {
        UserId = player.UserId,
        Id = id
    })
end

local function clear(player: Player)
    stop(player)
    cooldownUntil[player] = nil
end

local function canUse(player: Player): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if player:GetAttribute("IsAttacking") == true
        or player:GetAttribute("Stunned") == true
        or player:GetAttribute("Ragdolled") == true
        or player:GetAttribute("Blocking") == true then
        return false
    end

    local state = StateManager:Get(player)
    if not state then
        return false
    end

    local now = os.clock()
    return state.Phase == "Idle"
        or state.Phase == "Running"
end

local function bindStateCancellation(player: Player)
    local watched = {
        "IsAttacking",
        "Stunned",
        "Ragdolled",
        "Blocking"
    }

    for _, attribute in ipairs(watched) do
        player:GetAttributeChangedSignal(attribute):Connect(function()
            if player:GetAttribute(attribute) == true then
                stop(player)
            end
        end)
    end

    player.CharacterAdded:Connect(function()
        clear(player)
    end)
end

Players.PlayerAdded:Connect(bindStateCancellation)
Players.PlayerRemoving:Connect(clear)

for _, player in ipairs(Players:GetPlayers()) do
    bindStateCancellation(player)
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

        if active[player] then
            stop(player)
        end

        active[player] = id
        cooldownUntil[player] = now + 0.18

        remotes.EmoteEvent:FireAllClients("Play", {
            UserId = player.UserId,
            Id = id,
            Name = emote.Name,
            Category = emote.Category,
            AnimationId = emote.AnimationId,
            SoundId = emote.SoundId,
            VFXId = emote.VFXId,
            Duration = emote.Duration,
            Loop = emote.Loop
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

        local nextWheel = {}
        local seen = {}

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
