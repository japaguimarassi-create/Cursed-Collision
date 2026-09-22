--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterKit = require(ReplicatedStorage.Characters.CharacterKit)

local Factory = {}

function Factory.Build(id: string)
    return CharacterKit.Build(id)
end

return Factory