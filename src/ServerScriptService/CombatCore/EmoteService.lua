--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager = require(script.Parent.StateManager)

local EmoteService = {}

local remotes = RemoteService:Get()

local cooldownUntil: {[Player]: number} = {}
local active: {[Player]: string} = {}

local function cleanup(player: Player)
    active[player] = nil
    cooldownUntil[player] = nil
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

function EmoteService:CanUse(player: Player): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local state = StateManager:Get(player)
    if not state then
        return false
    end

    if player:GetAttribute("IsAttacking") == true
        or player:GetAttribute("Stunned") == true
        or player:GetAttribute("Ragdolled") == true
        or state.Blocking
        or state.StunnedUntil > os.clock()
        or state.RagdollUntil > os.clock()
        or state.RecoveryUntil > os.clock() then
        return false
    end

    return true
end

function EmoteService:Start(player: Player, id: string): boolean
    local now = os.clock()

    if not self:CanUse(player) or (cooldownUntil[player] or 0) > now then
        return false
    end

    local emote = Emotes[id]
    local data = DataService:Get(player)

    if not emote or not data or data.OwnedEmotes[id] ~= true then
        return false
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
        Accent = emote.Accent
    })

    task.delay(emote.Duration + 0.05, function()
        if player.Parent and active[player] == id then
            stop(player)
        end
    end)

    return true
end

function EmoteService:Stop(player: Player)
    stop(player)
end

function EmoteService:SetWheel(player: Player, ids: {string}): boolean
    local data = DataService:Get(player)
    if not data or #ids ~= 5 then
        return false
    end

    local seen: {[string]: boolean} = {}
    local nextWheel = {}

    for index = 1, 5 do
        local id = ids[index]

        if type(id) ~= "string"
            or not Emotes[id]
            or data.OwnedEmotes[id] ~= true
            or seen[id] then
            return false
        end

        seen[id] = true
        nextWheel[index] = id
    end

    data.EmoteWheel = nextWheel
    DataService:MarkDirty(player)
    return true
end

function EmoteService:Clear(player: Player)
    stop(player)
    cleanup(player)
end

return EmoteService
