local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local RemoteService = require(ReplicatedStorage.Shared.RemoteService)

local DomainClashService = {}
local remotes
local domainService
local getState
local combats = {}

local function getKey(a, b)
    local x, y = a.UserId, b.UserId
    if x > y then x, y = y, x end
    return tostring(x) .. ":" .. tostring(y)
end

local function send(player, event, payload)
    if player and player.Parent and remotes then
        remotes.ClashEvent:FireClient(player, event, payload)
    end
end

local function setClash(player, opponent, active)
    if not player or not player.Parent then return end
    player:SetAttribute("InClash", active)
    player:SetAttribute("ClashOpponent", active and opponent.UserId or nil)
    player:SetAttribute("Blocking", false)
    local state = getState and getState(player)
    if state then
        state.Clash = active
        state.Blocking = false
        state.Dodging = false
        if active then
            state.StunnedUntil = 0
        end
    end
end

local function restoreMovement(player)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end

local function finish(state, winner, loser, reason)
    if state.finished then return end
    state.finished = true
    combats[state.key] = nil

    setClash(state.a, state.b, false)
    setClash(state.b, state.a, false)

    if state.a and state.a.Parent then restoreMovement(state.a) end
    if state.b and state.b.Parent then restoreMovement(state.b) end

    if winner and loser and winner.Parent and loser.Parent then
        if domainService then domainService:Stop(loser) end
        winner:SetAttribute("ClashOpening", true)
        loser:SetAttribute("ClashOpening", false)
        send(state.a, "ClashEnd", {winner=winner.UserId, reason=reason})
        send(state.b, "ClashEnd", {winner=winner.UserId, reason=reason})

        local character = loser.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 3
            task.delay(Config.Clash.OpeningStun, function()
                if humanoid.Parent and humanoid.Health > 0 then
                    humanoid.WalkSpeed = 16
                end
                if loser.Parent then
                    loser:SetAttribute("ClashOpening", false)
                end
            end)
        end
    else
        send(state.a, "ClashEnd", {winner=nil, reason=reason})
        send(state.b, "ClashEnd", {winner=nil, reason=reason})
    end
end

local function resetRound(state)
    if state.finished then return end
    state.moves = {}
    state.pressure = {}
    state.round += 1
    state.deadline = os.clock() + Config.Clash.DecisionWindow
    send(state.a, "ClashReset", {round=state.round, moves=Config.Clash.Moves})
    send(state.b, "ClashReset", {round=state.round, moves=Config.Clash.Moves})
end

local function resolve(state)
    local aMove = state.moves[state.a]
    local bMove = state.moves[state.b]
    if not aMove or not bMove then return end

    if aMove == bMove then
        resetRound(state)
        return
    end

    local aBeats = Config.Clash.Beats[aMove] == bMove
    local bBeats = Config.Clash.Beats[bMove] == aMove

    if aBeats then
        finish(state, state.a, state.b, "UniversalMove")
        return
    end
    if bBeats then
        finish(state, state.b, state.a, "UniversalMove")
        return
    end

    local ap = state.pressure[state.a] or 0
    local bp = state.pressure[state.b] or 0
    if ap >= bp + Config.Clash.PressureToConvertNeutral then
        finish(state, state.a, state.b, "PressureOpening")
    elseif bp >= ap + Config.Clash.PressureToConvertNeutral then
        finish(state, state.b, state.a, "PressureOpening")
    else
        send(state.a, "ClashNeutral", {round=state.round})
        send(state.b, "ClashNeutral", {round=state.round})
        resetRound(state)
    end
end

function DomainClashService:Configure(context)
    remotes = RemoteService:Get()
    domainService = context.domain
    getState = context.getState
end

function DomainClashService:TryStart(player)
    if player:GetAttribute("InClash") then return true end

    local overlaps = domainService:FindOverlaps(player)
    local opponentDomain = overlaps[1]
    if not opponentDomain then return false end

    local opponent = opponentDomain.player
    if not opponent or not opponent.Parent or opponent:GetAttribute("InClash") then return false end

    local key = getKey(player, opponent)
    if combats[key] then return true end

    local state = {
        key=key,
        a=player,
        b=opponent,
        moves={},
        pressure={},
        round=1,
        deadline=os.clock() + Config.Clash.DecisionWindow,
        finished=false
    }

    combats[key] = state
    setClash(player, opponent, true)
    setClash(opponent, player, true)

    send(player, "ClashStart", {opponent=opponent.UserId, round=1, moves=Config.Clash.Moves})
    send(opponent, "ClashStart", {opponent=player.UserId, round=1, moves=Config.Clash.Moves})

    task.spawn(function()
        while combats[key] == state and not state.finished do
            if os.clock() > state.deadline then
                resetRound(state)
            end
            task.wait(0.05)
        end
    end)

    return true
end

function DomainClashService:Move(player, move)
    if type(move) ~= "number" or move % 1 ~= 0 or move < 1 or move > 4 then return false end

    local opponentId = player:GetAttribute("ClashOpponent")
    local opponent = opponentId and Players:GetPlayerByUserId(opponentId)
    if not opponent then return false end

    local state = combats[getKey(player, opponent)]
    if not state or state.finished or os.clock() > state.deadline then return false end
    if state.moves[player] then return false end

    state.moves[player] = move
    send(player, "ClashLocked", {move=move, round=state.round})
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
        setClash(state.a, state.b, false)
        setClash(state.b, state.a, false)
        restoreMovement(state.a)
        restoreMovement(state.b)
        send(state.a, "ClashEnd", {winner=nil, reason="Cancelled"})
        send(state.b, "ClashEnd", {winner=nil, reason="Cancelled"})
    end
end

function DomainClashService:Special(player)
    local opponentId = player:GetAttribute("ClashOpponent")
    local opponent = opponentId and Players:GetPlayerByUserId(opponentId)
    if not opponent then return false end

    local state = combats[getKey(player, opponent)]
    if not state or state.finished or os.clock() > state.deadline then return false end

    local pressure = (state.pressure[player] or 0) + Config.Clash.PressurePerSpecial
    state.pressure[player] = pressure
    send(player, "ClashPressure", {value=pressure})
    send(opponent, "ClashPressure", {opponent=pressure})
    return true
end

return DomainClashService