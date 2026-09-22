local characters = {
    "Yuji","Gojo","Sukuna","Megumi","Yuta","Maki","Toji","Mahito","Todo","Hakari",
    "Choso","Kashimo","Naoya","Kenjaku","Jogo","Dagon","Hanami","Higuruma","Takaba",
    "Uraume","Yorozu","Ryu","Uro","Kusakabe"
}

local QuestDefinitions = {
    Daily = {},
    Weekly = {},
    General = {}
}

local function addQuest(list, id, name, description, event, target, reward, character)
    list[id] = {
        Id = id,
        Name = name,
        Description = description,
        Event = event,
        Target = target,
        Reward = reward,
        Character = character
    }
end

for index, character in ipairs(characters) do
    local safe = string.lower(character)

    addQuest(
        QuestDefinitions.Daily,
        "daily_" .. safe .. "_technique",
        character .. " • Technique Practice",
        "Use " .. character .. "'s Special or Skill 5 times.",
        "Technique",
        5,
        120 + (index % 5) * 15,
        character
    )

    addQuest(
        QuestDefinitions.Daily,
        "daily_" .. safe .. "_damage",
        character .. " • Pressure",
        "Deal 450 damage while using " .. character .. ".",
        "Damage",
        450,
        160 + (index % 6) * 20,
        character
    )

    addQuest(
        QuestDefinitions.Daily,
        "daily_" .. safe .. "_finish",
        character .. " • Finish the Fight",
        "Get 1 elimination with " .. character .. ".",
        "Kill",
        1,
        240 + (index % 4) * 25,
        character
    )

    addQuest(
        QuestDefinitions.Weekly,
        "weekly_" .. safe .. "_mastery",
        character .. " • Mastery",
        "Deal 3000 damage while using " .. character .. ".",
        "Damage",
        3000,
        800 + (index % 7) * 100,
        character
    )

    addQuest(
        QuestDefinitions.Weekly,
        "weekly_" .. safe .. "_finisher",
        character .. " • Finisher",
        "Get 5 eliminations with " .. character .. ".",
        "Kill",
        5,
        1100 + (index % 6) * 140,
        character
    )

    addQuest(
        QuestDefinitions.Weekly,
        "weekly_" .. safe .. "_awakening",
        character .. " • Awakened",
        "Activate " .. character .. "'s Awakening 3 times.",
        "Awaken",
        3,
        950 + (index % 5) * 120,
        character
    )

    local generalEvents = {"M1","Technique","Damage","Kill","Domain","Awaken"}
    local event = generalEvents[((index - 1) % #generalEvents) + 1]
    local target = event == "Damage" and 7500 or event == "M1" and 120 or event == "Technique" and 35 or event == "Kill" and 10 or event == "Domain" and 8 or 5
    local reward = 1500 + (index % 8) * 175

    addQuest(
        QuestDefinitions.General,
        "general_" .. safe,
        "Character Mastery • " .. character,
        "Complete a long-term " .. character .. " challenge.",
        event,
        target,
        reward,
        character
    )
end

return QuestDefinitions
