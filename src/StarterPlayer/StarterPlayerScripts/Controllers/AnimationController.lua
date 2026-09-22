-- Client animation controller

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatAnimationService = require(ReplicatedStorage.Combat.CombatAnimationService)

local AnimationController = {}

local function optionsFor(comboOrOptions, power)
    if type(comboOrOptions) == "table" then
        return comboOrOptions
    end

    local options = {}
    if type(comboOrOptions) == "number" then
        options.combo = comboOrOptions
    end
    if type(power) == "number" then
        options.power = power
    end
    return options
end

function AnimationController:PlayAttack(character, move, comboOrOptions, power)
    return CombatAnimationService.PlayAttack(character, move, optionsFor(comboOrOptions, power))
end

function AnimationController:PlaySkill(character, skill, options)
    return CombatAnimationService.PlaySkill(character, skill, type(options) == "table" and options or {})
end

function AnimationController:PlayDomain(character, options)
    return CombatAnimationService.PlayDomain(character, type(options) == "table" and options or {})
end

function AnimationController:HitReact(character, intensity, reaction)
    return CombatAnimationService.HitReact(character, intensity, reaction)
end

function AnimationController:ResetJoints(character, duration)
    return CombatAnimationService.ResetJoints(character, duration)
end

function AnimationController:Cancel(character)
    return CombatAnimationService.Cancel(character)
end

function AnimationController:StartIdleCombat(character, intensity)
    return CombatAnimationService.StartIdleCombat(character, intensity)
end

function AnimationController:StopIdleCombat(character)
    return CombatAnimationService.StopIdleCombat(character)
end

return AnimationController
