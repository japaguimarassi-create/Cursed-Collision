--!strict

local PhysicsRules = {
    World = PhysicalProperties.new(0.7, 0.8, 0, 1, 1),
    Cover = PhysicalProperties.new(1.2, 0.65, 0, 1, 1),
    Character = PhysicalProperties.new(0.9, 0.55, 0, 1, 1),
    Enemy = PhysicalProperties.new(1.0, 0.45, 0, 1, 1),
    Echo = PhysicalProperties.new(0.8, 0.5, 0, 1, 1),
}

function PhysicsRules.apply(part: BasePart, properties: PhysicalProperties)
    part.CustomPhysicalProperties = properties
    part.AssemblyAngularVelocity = Vector3.zero
end

return table.freeze(PhysicsRules)
