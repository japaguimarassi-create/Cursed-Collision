--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage.Shared.RemoteService)
local Emotes = require(ReplicatedStorage.Emotes.EmoteDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)
local StateManager = require(script.Parent.StateManager)

local EmoteService = {}

local remotes = RemoteService:Get()

local playerConnections: {[Player]: {RBXScriptConnection}} = {}
local characterConnections: {[Player]: {RBXScriptConnection}} = {}
local cooldownUntil: {[Player]: number} = {}
local wheelEditUntil: {[Player]: number} = {}
local active: {[Player]: string} = {}

local function disconnectList(list: {[Player]: {RBXScriptConnection}}, player: Player)
    local connections = list[player]
    if not connections then
        return
    end

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    list[player] = nil
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

local function watchPlayerAttribute(player: Player, attribute: string)
    table.insert(playerConnections[player], player:GetAttributeChangedSignal(attribute):Connect(function()
        if player:GetAttribute(attribute) == true then
            stop(player)
        end
    end))
end

local function watchCharacter(player: Player, character: Model)
    disconnectList(characterConnections, player)
    characterConnections[player] = {}

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local previousHealth = humanoid.Health
    table.insert(characterConnections[player], humanoid.HealthChanged:Connect(function(health)
        if health < previousHealth - 0.001 then
            stop(player)
        end
        previousHealth = health
    end))

    table.insert(characterConnections[player], humanoid.Running:Connect(function(speed)
        if speed > 0.08 or humanoid.MoveDirection.Magnitude > 0.08 then
            stop(player)
        end
    end))

    table.insert(characterConnections[player], humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping
            or newState == Enum.HumanoidStateType.Freefall
            or newState == Enum.HumanoidStateType.Dead then
            stop(player)
        end
    end))

    for _, attribute in ipairs({
        "IsAttacking",
        "Stunned",
        "Ragdolled",
        "Blocking"
    }) do
        table.insert(characterConnections[player], character:GetAttributeChangedSignal(attribute):Connect(function()
            if character:GetAttribute(attribute) == true then
                stop(player)
            end
        end))
    end
end

function EmoteService:BindPlayer(player: Player)
    disconnectList(playerConnections, player)
    disconnectList(characterConnections, player)

    playerConnections[player] = {}
    characterConnections[player] = {}

    for _, attribute in ipairs({
        "IsAttacking",
        "Stunned",
        "Ragdolled",
        "Blocking"
    }) do
        watchPlayerAttribute(player, attribute)
    end

    if player.Character then
        watchCharacter(player, player.Character)
    end

    table.insert(playerConnections[player], player.CharacterAdded:Connect(function(character)
        stop(player)
        watchCharacter(player, character)
    end))
end

function EmoteService:CanUse(player: Player): boolean
    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local state = StateManager:Get(player)

    if not humanoid or humanoid.Health <= 0 or not state then
        return false
    end

    if player:GetAttribute("IsAttacking") == true
        or player:GetAttribute("Stunned") == true
        or player:GetAttribute("Ragdolled") == true
        or player:GetAttribute("Blocking") == true
        or character:GetAttribute("IsAttacking") == true
        or character:GetAttribute("Stunned") == true
        or character:GetAttribute("Ragdolled") == true
        or character:GetAttribute("Blocking") == true
        or state.StunnedUntil > os.clock()
        or state.RagdollUntil > os.clock()
        or state.RecoveryUntil > os.clock() then
        return false
    end

    return state.Phase == "Idle" or state.Phase == "Running"
end

function EmoteService:Start(player: Player, id: string): boolean
    local now = os.clock()
    local emote = Emotes[id]
    local data = DataService:Get(player)

    if not emote
        or not data
        or data.OwnedEmotes[id] ~= true
        or not self:CanUse(player)
        or (cooldownUntil[player] or 0) > now then
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
        AnimationId = emote.AnimationId,
        Duration = emote.Duration,
        Loop = emote.Loop,
        Priority = emote.Priority.Name,
        EnergyCost = emote.EnergyCost
    })

    task.delay(emote.Duration + 0.08, function()
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

    local now = os.clock()
    if (wheelEditUntil[player] or 0) > now then
        return false
    end

    local seen: {[string]: boolean} = {}
    local nextWheel: {string} = {}

    for index = 1, 5 do
        local id = ids[index]

        if #id > 64
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
    wheelEditUntil[player] = now + 0.50
    return true
end

function EmoteService:Clear(player: Player)
    stop(player)
    disconnectList(playerConnections, player)
    disconnectList(characterConnections, player)
    cooldownUntil[player] = nil
    wheelEditUntil[player] = nil
    active[player] = nil
end

return EmoteService
