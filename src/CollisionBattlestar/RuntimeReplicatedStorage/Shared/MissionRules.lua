--!strict

local MissionRules = {}

function MissionRules.isValid(mission: any)
    return type(mission) == "table"
        and type(mission.Progress) == "number"
        and type(mission.Completed) == "boolean"
end

function MissionRules.progress(current: number, amount: number, goal: number)
    return math.clamp(math.floor(current + math.max(0, amount)), 0, goal)
end

function MissionRules.shouldComplete(current: number, goal: number)
    return current >= goal
end

return table.freeze(MissionRules)
