--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)

local CharacterModules = {
    PotentialMan = require(ReplicatedStorage.Characters.PotentialMan)
}

local CharacterService = {}
local context = nil :: any

function CharacterService:Configure(newContext)
    context = newContext
end

function CharacterService:GetAvailable()
    local result = {}

    for id, definition in pairs(Definitions) do
        table.insert(result, {
            Id = id,
            Name = definition.Name,
            Subtitle = definition.Subtitle,
            Archetype = definition.Archetype
        })
    end

    table.sort(result, function(a, b)
        return a.Id < b.Id
    end)

    return result
end

function CharacterService:GetId(player: Player): string
    local id = player:GetAttribute("CharacterId")
    if type(id) == "string" and Definitions[id] then
        return id
    end
    return "PotentialMan"
end

function CharacterService:GetModule(player: Player)
    return CharacterModules[self:GetId(player)]
end

function CharacterService:Initialize(player: Player): boolean
    local id = self:GetId(player)
    local definition = Definitions[id]
    local module = CharacterModules[id]

    if not definition or not module then
        return false
    end

    player:SetAttribute("CharacterId", id)
    player:SetAttribute("CharacterName", definition.Name)
    player:SetAttribute("CharacterTitle", definition.Subtitle)

    if module.Init then
        module.Init(player, context)
    end

    return true
end

function CharacterService:Select(player: Player, id: string)
    if not Definitions[id] or not CharacterModules[id] then
        return false, "UnknownCharacter"
    end

    if player:GetAttribute("CombatStunned") then
        return false, "Busy"
    end

    player:SetAttribute("CharacterId", id)
    self:Initialize(player)
    context.fx("CharacterSelected", context.rootPosition(player), {
        character = id,
        actor = player.Character
    })

    return true, "Selected"
end

function CharacterService:GetSpecialCooldown(player: Player): number
    local definition = Definitions[self:GetId(player)]
    return math.max(0.1, tonumber(definition and definition.SpecialCooldown) or 4.0)
end

function CharacterService:Special(player: Player): boolean
    local module = self:GetModule(player)
    if not module or not module.Special then
        return false
    end

    return module.Special(player, context)
end

return CharacterService