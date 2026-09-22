--!strict

local EnvironmentService = require(script.Parent.Parent.EnvironmentService)

local DestructionService = {}

function DestructionService:Impact(origin: Vector3, radius: number, power: number): number
    return EnvironmentService:Impact(origin, radius, power)
end

return DestructionService
