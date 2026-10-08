--!strict

local Missions = {
    WaveHunter = {
        Id = "WaveHunter",
        DisplayName = "Wave Hunter",
        Goal = 5,
        Reward = 200,
        Metric = "Waves",
    },
    EliteBreaker = {
        Id = "EliteBreaker",
        DisplayName = "Elite Breaker",
        Goal = 3,
        Reward = 300,
        Metric = "EliteKills",
    },
    CreditCollector = {
        Id = "CreditCollector",
        DisplayName = "Credit Collector",
        Goal = 1000,
        Reward = 250,
        Metric = "CreditsEarned",
    },
}

return table.freeze(Missions)
