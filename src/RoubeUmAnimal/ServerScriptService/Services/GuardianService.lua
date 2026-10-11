local AnimalBrain = require(script.Parent:WaitForChild("AnimalBrain"))

local GuardianService = {}

function GuardianService.Start(builder, animalService, notify)
    return AnimalBrain.StartGuardians(builder, animalService, notify)
end

return GuardianService
