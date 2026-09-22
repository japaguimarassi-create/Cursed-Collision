--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatVFX = require(ReplicatedStorage.Combat.CombatVFX)

local VFXController = {}

function VFXController:CharacterMove(position, payload)
    CombatVFX.CharacterMove(position, payload)
end

function VFXController:Utility(kind, position, payload)
    CombatVFX.Utility(kind, position, payload)
end

function VFXController:Domain(position, characterId, clash)
    CombatVFX.Domain(position, characterId, clash)
end

function VFXController:Awakening(position, characterId)
    CombatVFX.Awakening(position, characterId)
end

return VFXController
