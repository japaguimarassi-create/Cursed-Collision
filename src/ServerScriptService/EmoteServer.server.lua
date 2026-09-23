local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager = require(script.Parent.CombatCore.StateManager)

local remotes = RemoteService:Get()

local cooldownUntil: {[Player]: number} = {}
local active: {[Player]: string} = {}

local function clear(player: Player)
    active[player] = nil
    cooldownUntil[player] = nil
end

local function stop(player: Player)
    if active[player] then
        active[player] = nil
        remotes.EmoteEvent:FireAllClients("Stop", {
            UserId = player.UserId
        })
    end
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

    return not state.Blocking
        and state.StunnedUntil <= os.clock()
        and state.RecoveryUntil <= os.clock()
end

local function setup(player: Player)
    player.CharacterAdded:Connect(function()
        clear(player)
    end)
end

Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(player)
    stop(player)
    clear(player)
end)

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
            Duration = emote.Duration,
            Loop = emote.Loop,
            Accent = emote.Accent
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
            if type(id) ~= "string" or not Emotes[id] or data.OwnedEmotes[id] ~= true or seen[id] then
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
