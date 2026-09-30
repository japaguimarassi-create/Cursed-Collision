--!strict

local State = {}

function State.new()
    return {
        Credits = 0,
        DamageLevel = 0,
        XP = 0,
        TotalKills = 0,
        HighestWave = 0,
        OwnedItems = {},
        EquippedSkin = "Default",
        EquippedEcho = "None",
        Wave = 0,
        DataReady = false,
        ComboIndex = 0,
        LastAttackAt = 0,
        LastComboAt = 0,
    }
end

function State.setReady(state, ready: boolean)
    state.DataReady = ready
end

function State.addCredits(state, amount: number)
    state.Credits = math.max(0, state.Credits + math.max(0, amount))
end

function State.addDamageLevel(state)
    state.DamageLevel += 1
end

return State
