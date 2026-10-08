--!strict

local CombatRules = {}

function CombatRules.nextCombo(previousStep: number, elapsed: number, resetWindow: number, maxSteps: number)
    if elapsed > resetWindow or previousStep < 1 or previousStep >= maxSteps then
        return 1
    end

    return previousStep + 1
end

function CombatRules.comboMultiplier(step: number)
    if step == 1 then
        return 1
    elseif step == 2 then
        return 1.08
    elseif step == 3 then
        return 1.2
    end

    return 1
end

return table.freeze(CombatRules)
