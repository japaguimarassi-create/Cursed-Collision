local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Economy.QuestDefinitions)
local DataService = require(ReplicatedStorage.Economy.DataService)

local QuestService = {}

local function utcDay()
    return os.date("!%Y-%m-%d")
end

local function utcWeek()
    return tostring(math.floor(os.time() / 604800))
end

local function ordered(definitions)
    local list = {}
    for id, definition in pairs(definitions) do
        table.insert(list, definition)
    end
    table.sort(list, function(a, b)
        return a.Id < b.Id
    end)
    return list
end

local orderedDaily = ordered(Definitions.Daily)
local orderedWeekly = ordered(Definitions.Weekly)
local orderedGeneral = ordered(Definitions.General)

local function activeSet(list, count, seed)
    local result = {}
    if #list == 0 then
        return result
    end

    local start = (seed % #list) + 1
    for i = 0, math.min(count, #list) - 1 do
        local index = ((start - 1 + i) % #list) + 1
        result[list[index].Id] = true
    end
    return result
end

function QuestService:Initialize(player)
    local data = DataService:Get(player)
    if not data then
        return
    end

    local today = utcDay()
    local week = utcWeek()

    if data.DailyStamp ~= today then
        data.DailyStamp = today
        data.DailyProgress = {}
        data.CompletedDaily = {}
        DataService:MarkDirty(player)
    end

    if data.WeeklyStamp ~= week then
        data.WeeklyStamp = week
        data.WeeklyProgress = {}
        data.CompletedWeekly = {}
        DataService:MarkDirty(player)
    end

    if data.LastLoginRewardStamp ~= today then
        data.LastLoginRewardStamp = today
        DataService:AddCredits(player, 250)
        DataService:MarkDirty(player)
    end
end

function QuestService:GetActive()
    local daySeed = tonumber(os.date("!%Y%m%d")) or 0
    local weekSeed = math.floor(os.time() / 604800)
    local activeDaily = activeSet(orderedDaily, 6, daySeed)
    local activeWeekly = activeSet(orderedWeekly, 6, weekSeed)

    local activeGeneral = {}
    for index, definition in ipairs(orderedGeneral) do
        if index <= 8 then
            activeGeneral[definition.Id] = true
        end
    end

    return activeDaily, activeWeekly, activeGeneral
end

local function progressTable(data, category)
    if category == "Daily" then
        return data.DailyProgress, data.CompletedDaily, Definitions.Daily
    elseif category == "Weekly" then
        return data.WeeklyProgress, data.CompletedWeekly, Definitions.Weekly
    end
    return data.GeneralProgress, data.CompletedGeneral, Definitions.General
end

function QuestService:Record(player, eventName, amount, characterId)
    local data = DataService:Get(player)
    if not data then
        return
    end

    self:Initialize(player)

    local activeDaily, activeWeekly, activeGeneral = self:GetActive()
    local amountNumber = math.max(0, tonumber(amount) or 0)

    local checks = {
        {"Daily", activeDaily},
        {"Weekly", activeWeekly},
        {"General", activeGeneral}
    }

    local changed = false

    for _, check in ipairs(checks) do
        local category = check[1]
        local active = check[2]
        local progress, completed, definitions = progressTable(data, category)

        for questId in pairs(active) do
            local quest = definitions[questId]
            if quest and not completed[questId] then
                local characterMatch = not quest.Character or quest.Character == characterId
                local eventMatch = quest.Event == eventName
                if characterMatch and eventMatch then
                    local previous = tonumber(progress[questId]) or 0
                    local nextValue = math.min(quest.Target, previous + amountNumber)
                    if nextValue ~= previous then
                        progress[questId] = nextValue
                        changed = true

                        if nextValue >= quest.Target then
                            completed[questId] = true
                            DataService:AddCredits(player, quest.Reward)
                        end
                    end
                elseif quest.Event == "Technique" and characterMatch and (eventName == "Special" or eventName == "Skill") then
                    local previous = tonumber(progress[questId]) or 0
                    local nextValue = math.min(quest.Target, previous + 1)
                    if nextValue ~= previous then
                        progress[questId] = nextValue
                        changed = true
                        if nextValue >= quest.Target then
                            completed[questId] = true
                            DataService:AddCredits(player, quest.Reward)
                        end
                    end
                end
            end
        end
    end

    if changed then
        DataService:MarkDirty(player)
    end
end

local function snapshotCategory(definitions, progress, completed, active)
    local list = {}
    for id in pairs(active) do
        local quest = definitions[id]
        if quest then
            table.insert(list, {
                Id = quest.Id,
                Name = quest.Name,
                Description = quest.Description,
                Event = quest.Event,
                Target = quest.Target,
                Progress = math.min(quest.Target, tonumber(progress[id]) or 0),
                Reward = quest.Reward,
                Character = quest.Character,
                Completed = completed[id] == true
            })
        end
    end
    table.sort(list, function(a, b)
        return a.Id < b.Id
    end)
    return list
end

function QuestService:Snapshot(player)
    local data = DataService:Get(player)
    if not data then
        return {
            Daily = {},
            Weekly = {},
            General = {},
            Totals = {Daily=24, Weekly=24, General=24}
        }
    end

    self:Initialize(player)

    local activeDaily, activeWeekly, activeGeneral = self:GetActive()

    return {
        Daily = snapshotCategory(Definitions.Daily, data.DailyProgress, data.CompletedDaily, activeDaily),
        Weekly = snapshotCategory(Definitions.Weekly, data.WeeklyProgress, data.CompletedWeekly, activeWeekly),
        General = snapshotCategory(Definitions.General, data.GeneralProgress, data.CompletedGeneral, activeGeneral),
        Totals = {Daily=#orderedDaily, Weekly=#orderedWeekly, General=#orderedGeneral}
    }
end

function QuestService:ResetAll(player)
    local data = DataService:Get(player)
    if not data then
        return false
    end

    data.DailyProgress = {}
    data.WeeklyProgress = {}
    data.GeneralProgress = {}
    data.CompletedDaily = {}
    data.CompletedWeekly = {}
    data.CompletedGeneral = {}
    data.DailyStamp = utcDay()
    data.WeeklyStamp = utcWeek()
    DataService:MarkDirty(player)
    return true
end

function QuestService:CompleteQuest(player, questId)
    local data = DataService:Get(player)
    if not data then
        return false
    end

    local categories = {
        {"Daily", Definitions.Daily, data.DailyProgress, data.CompletedDaily},
        {"Weekly", Definitions.Weekly, data.WeeklyProgress, data.CompletedWeekly},
        {"General", Definitions.General, data.GeneralProgress, data.CompletedGeneral}
    }

    for _, category in ipairs(categories) do
        local definitions = category[2]
        local progress = category[3]
        local completed = category[4]
        local quest = definitions[questId]
        if quest then
            progress[questId] = quest.Target
            completed[questId] = true
            DataService:AddCredits(player, quest.Reward)
            DataService:MarkDirty(player)
            return true
        end
    end

    return false
end

return QuestService
