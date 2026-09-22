--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatSFX = require(ReplicatedStorage.Combat.CombatSFX)

local SFXController = {}

function SFXController:Universal(kind, position)
    CombatSFX.Universal(kind, position)
end

function SFXController:Ability(position, payload)
    CombatSFX.Ability(position, payload)
end

function SFXController:Impact(position, tag)
    CombatSFX.Impact(position, tag)
end

function SFXController:PerfectBlock(position)
    CombatSFX.PerfectBlock(position)
end

function SFXController:KillConfirm()
    CombatSFX.KillConfirm()
end

return SFXController
