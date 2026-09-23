--!strict

local AnimationController = require(script.Parent.AnimationController)

local AbilityAnimationManager = {}

function AbilityAnimationManager:Play(character: Model, slot: number, payload: any)
    return AnimationController:Play(
        character,
        "Skill"..tostring(math.clamp(slot,1,4)),
        payload
    )
end

function AbilityAnimationManager:Stop(character: Model, slot: number)
    AnimationController:Stop(character,"Skill"..tostring(math.clamp(slot,1,4)))
end

return AbilityAnimationManager
