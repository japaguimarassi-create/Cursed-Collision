--!strict

return function()
    local Definitions = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/MissionDefinitions")
    local Rules = require("../../src/CollisionBattlestar/RuntimeReplicatedStorage/Shared/MissionRules")

    local mission = {
        Progress = 2,
        Completed = false,
    }

    assert(Rules.isValid(mission) == true)
    mission.Progress = Rules.progress(mission.Progress, 3, Definitions.WaveHunter.Goal)
    assert(mission.Progress == 5)
    assert(Rules.shouldComplete(mission.Progress, Definitions.WaveHunter.Goal) == true)
    assert(Definitions.EliteBreaker.Reward > 0)
end
