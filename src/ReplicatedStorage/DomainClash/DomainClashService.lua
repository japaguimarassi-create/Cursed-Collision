local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteService = require(ReplicatedStorage.Shared.RemoteService)

local DomainClashService = {}
local remotes
local domainService
local combats = {}

local function getKey(a, b)
    local x, y = a.UserId, b.UserId
    if x > y then
        x, y = y, x
    end
    return tostring(x) .. ":" .. tostring(y)
end

local function sendClash(player, event, payload)
    if remotes then
        remotes.ClashEvent:FireClient(player, event, payload)
    end
end

local function finishClash(state, winner, loser, reason)
    state.finished = true
    combats[state.key] = nil

    if state.a and state.a.Parent then
        state.a:SetAttribute("InClash", false)
        state.a:SetAttribute("ClashOpponent", nil)
    end
    if state.b and state.b.Parent then
        state.b:SetAttribute("InClash", false)
        state.b:SetAttribute("ClashOpponent", nil)
    end

    if winner then
        state.pressure = state.pressure or {}
        winner:SetAttribute("ClashOpening", true)
        if domainService then
            domainService:Stop(loser)
        end
        loser:SetAttribute("ClashOpening", false)
        sendClash(state.a, "ClashEnd", {winner = winner.UserId, reason = reason})
        sendClash(state.b, "ClashEnd", {winner = winner.UserId, reason = reason})

        local loserCharacter = loser.Character
        local hum = loserCharacter and loserCharacter:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 3
            task.delay(Config.Clash.OpeningStun, function()
                if hum.Parent and hum.Health > 0 then
                    hum.WalkSpeed = 16
                end
            end)
        end
    end
end

local function resetRound(state)
    state.moves = {}
    state.pressure = {}
    state.round += 1
    state.deadline = os.clock() + Config.Clash.DecisionWindow

    sendClash(state.a, "ClashReset", {
        round = state.round,
        moves = Config.Clash.Moves
    })
    sendClash(state.b, "ClashReset", {
        round = state.round,
        moves = Config.Clash.Moves
    })
end

local function resolve(state)
    local aMove = state.moves[state.a]
    local bMove = state.moves[state.b]
    if not aMove or not bMove then
        return
    end

    if aMove == bMove then
        resetRound(state)
        return
    end

    local aBeats = Config.Clash.Beats[aMove] == bMove
    local bBeats = Config.Clash.Beats[bMove] == aMove

    if not aBeats and not bBeats then
        local ap = state.pressure[state.a] or 0
        local bp = state.pressure[state.b] or 0
        if ap >= bp + Config.Clash.PressureToConvertNeutral then
            finishClash(state, state.a, state.b, "PressureOpening")
        elseif bp >= ap + Config.Clash.PressureToConvertNeutral then
            finishClash(state, state.b, state.a, "PressureOpening")
        else
            resetRound(state)
        end
        return
    end

    if aBeats then
        finishClash(state, state.a, state.b, "UniversalMove")
    else
        finishClash(state, state.b, state.a, "UniversalMove")
    end
end

function DomainClashService:Configure(context)
    remotes = RemoteService:Get()
    domainService = context.domain
end

function DomainClashService:TryStart(player)
    if player:GetAttribute("InClash") then
        return true
    end

    local overlaps = domainService:FindOverlaps(player)
    local opponentDomain = overlaps[1]
    if not opponentDomain then
        return false
    end

    local opponent = opponentDomain.player
    if opponent:GetAttribute("InClash") then
        return false
    end

    local key = getKey(player, opponent)
    if combats[key] then
        return true
    end

    local state = {
        key = key,
        a = player,
        b = opponent,
        moves = {},
        pressure = {},
        round = 1,
        deadline = os.clock() + Config.Clash.DecisionWindow,
        finished = false
    }

    combats[key] = state

    player:SetAttribute("InClash", true)
    opponent:SetAttribute("InClash", true)
    player:SetAttribute("ClashOpponent", opponent.UserId)
    opponent:SetAttribute("ClashOpponent", player.UserId)

    sendClash(player, "ClashStart", {
        opponent = opponent.UserId,
        round = 1,
        moves = Config.Clash.Moves
    })
    sendClash(opponent, "ClashStart", {
        opponent = player.UserId,
        round = 1,
        moves = Config.Clash.Moves
    })

    return true
end

function DomainClashService:Move(player, move)
    if type(move) ~= "number" or move < 1 or move > 4 or move % 1 ~= 0 then
        return false
    end

    local opponentId = player:GetAttribute("ClashOpponent")
    if not opponentId then
        return false
    end

    local opponent = game.Players:GetPlayerByUserId(opponentId)
    if not opponent then
        return false
    end

    local state = combats[getKey(player, opponent)]
    if not state or state.finished or os.clock() > state.deadline then
        return false
    end

    if state.moves[player] then
        return false
    end

    state.moves[player] = move
    sendClash(player, "ClashLocked", {move = move, round = state.round})

    resolve(state)
    return true
end

function DomainClashService:Cancel(player)
    local pending = {}

    for _, state in pairs(combats) do
        if state.a == player or state.b == player then
            table.insert(pending, state)
        end
    end

    for _, state in ipairs(pending) do
        state.finished = true
        combats[state.key] = nil

        if state.a and state.a.Parent then
            state.a:SetAttribute("InClash", false)
            state.a:SetAttribute("ClashOpponent", nil)
        end
        if state.b and state.b.Parent then
            state.b:SetAttribute("InClash", false)
            state.b:SetAttribute("ClashOpponent", nil)
        end

        sendClash(state.a, "ClashEnd", {winner = nil, reason = "PlayerReset"})
        sendClash(state.b, "ClashEnd", {winner = nil, reason = "PlayerReset"})
    end
end

function DomainClashService:Special(player)
    local opponentId = player:GetAttribute("ClashOpponent")
    if not opponentId then
        return false
    end

    local opponent = game.Players:GetPlayerByUserId(opponentId)
    if not opponent then
        return false
    end

    local state = combats[getKey(player, opponent)]
    if not state or state.finished then
        return false
    end

    local now = os.clock()
    if now > state.deadline then
        return false
    end

    local pressure = state.pressure[player] or 0
    pressure += Config.Clash.PressurePerSpecial
    state.pressure[player] = pressure

    sendClash(player, "ClashPressure", {value = pressure})
    sendClash(opponent, "ClashPressure", {opponent = pressure})
    return true
end

return DomainClashService
