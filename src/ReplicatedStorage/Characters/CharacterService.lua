--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CharacterMoves = require(ReplicatedStorage.Characters.CharacterMoves)

local CharacterModules = {
    PotentialMan = require(ReplicatedStorage.Characters.PotentialMan),
    Yuji = require(ReplicatedStorage.Characters.Yuji),
    Gojo = require(ReplicatedStorage.Characters.Gojo),
    Sukuna = require(ReplicatedStorage.Characters.Sukuna),
    Megumi = require(ReplicatedStorage.Characters.Megumi),
    Yuta = require(ReplicatedStorage.Characters.Yuta),
    Maki = require(ReplicatedStorage.Characters.Maki),
    Toji = require(ReplicatedStorage.Characters.Toji),
    Mahito = require(ReplicatedStorage.Characters.Mahito),
    Todo = require(ReplicatedStorage.Characters.Todo),
    Hakari = require(ReplicatedStorage.Characters.Hakari),
    Choso = require(ReplicatedStorage.Characters.Choso),
    Kashimo = require(ReplicatedStorage.Characters.Kashimo),
    Naoya = require(ReplicatedStorage.Characters.Naoya),
    Kenjaku = require(ReplicatedStorage.Characters.Kenjaku),
    Jogo = require(ReplicatedStorage.Characters.Jogo),
    Dagon = require(ReplicatedStorage.Characters.Dagon),
    Hanami = require(ReplicatedStorage.Characters.Hanami),
    Higuruma = require(ReplicatedStorage.Characters.Higuruma),
    Takaba = require(ReplicatedStorage.Characters.Takaba),
    Uraume = require(ReplicatedStorage.Characters.Uraume),
    Yorozu = require(ReplicatedStorage.Characters.Yorozu),
    Ryu = require(ReplicatedStorage.Characters.Ryu),
    Uro = require(ReplicatedStorage.Characters.Uro),
    Kusakabe = require(ReplicatedStorage.Characters.Kusakabe)
}

local CharacterService = {}
local context: any = nil

function CharacterService:Configure(newContext: any)
    context = newContext
end

function CharacterService:GetAvailable()
    local result: {any} = {}

    for id, definition in pairs(Definitions) do
        if CharacterModules[id] then
            table.insert(result, {
                Id = id,
                Name = definition.Name,
                Subtitle = definition.Subtitle,
                Archetype = definition.Archetype,
                SpecialName = CharacterMoves[id]
                    and CharacterMoves[id].SpecialName
                    or "Special"
            })
        end
    end

    table.sort(result, function(a: any, b: any)
        return a.Id < b.Id
    end)

    return result
end

function CharacterService:GetId(player: Player): string
    local id = player:GetAttribute("CharacterId")

    if type(id) == "string"
        and Definitions[id]
        and CharacterModules[id] then
        return id
    end

    return "PotentialMan"
end

function CharacterService:GetModule(player: Player)
    return CharacterModules[self:GetId(player)]
end

function CharacterService:Initialize(player: Player): (boolean, string)
    local id = self:GetId(player)
    local definition = Definitions[id]
    local module = CharacterModules[id]

    if not definition or not module then
        return false, "InvalidCharacter"
    end

    player:SetAttribute("CharacterId", id)
    player:SetAttribute("CharacterName", definition.Name)
    player:SetAttribute("CharacterTitle", definition.Subtitle)
    player:SetAttribute(
        "SpecialName",
        CharacterMoves[id] and CharacterMoves[id].SpecialName or "Special"
    )

    if module.Init then
        module.Init(player, context)
    end

    return true, "Initialized"
end

function CharacterService:Select(player: Player, id: string): (boolean, string)
    if not Definitions[id] or not CharacterModules[id] then
        return false, "UnknownCharacter"
    end

    if player:GetAttribute("CombatStunned") then
        return false, "Busy"
    end

    player:SetAttribute("CharacterId", id)
    return self:Initialize(player)
end

function CharacterService:GetSpecialCooldown(player: Player): number
    local definition = Definitions[self:GetId(player)]

    return math.clamp(
        tonumber(definition and definition.SpecialCooldown) or 4,
        0.25,
        20
    )
end

function CharacterService:GetSkillCooldown(player: Player, slot: number): number
    local module = self:GetModule(player)

    if not module or not module.GetCooldown then
        return 1
    end

    return module.GetCooldown("Skill", slot)
end

function CharacterService:SkillSlot(player: Player, slot: number): boolean
    local module = self:GetModule(player)

    if not module or not module.SkillSlot then
        return false
    end

    return module.SkillSlot(player, context, slot)
end

function CharacterService:Special(player: Player): boolean
    local module = self:GetModule(player)

    if not module or not module.Special then
        return false
    end

    return module.Special(player, context)
end

return CharacterService