--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)
local CharacterMoves = require(ReplicatedStorage.Characters.CharacterMoves)
local PlayableRoster = require(ReplicatedStorage.Characters.PlayableRoster)

local CharacterModules = {
    Yuji = require(ReplicatedStorage.Characters.Yuji),
    Gojo = require(ReplicatedStorage.Characters.Gojo),
    Sukuna = require(ReplicatedStorage.Characters.Sukuna),
    Megumi = require(ReplicatedStorage.Characters.Megumi)
}

local CharacterService = {}
local context: any = nil

function CharacterService:Configure(newContext: any)
    context = newContext
end

function CharacterService:GetAvailable()
    local result: {any} = {}

    for _, id in ipairs(PlayableRoster.Order) do
        local definition = Definitions[id]
        if definition and CharacterModules[id] then
            table.insert(result, {
                Id = id,
                Name = definition.Name,
                Subtitle = definition.Subtitle,
                Archetype = definition.Archetype,
                SpecialName = CharacterMoves[id].SpecialName,
                AwakeningName = definition.AwakeningName
            })
        end
    end

    return result
end

function CharacterService:GetId(player: Player): string
    local id = player:GetAttribute("CharacterId")

    if type(id) == "string"
        and PlayableRoster:Contains(id)
        and Definitions[id]
        and CharacterModules[id] then
        return id
    end

    return PlayableRoster.Default
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
    player:SetAttribute("SpecialName", CharacterMoves[id].SpecialName)
    player:SetAttribute("AwakeningName", definition.AwakeningName)

    if module.Init then
        module.Init(player, context)
    end

    return true, "Initialized"
end

function CharacterService:Select(player: Player, id: string): (boolean, string)
    if not PlayableRoster:Contains(id)
        or not Definitions[id]
        or not CharacterModules[id] then
        return false, "UnknownCharacter"
    end

    if player:GetAttribute("CombatStunned") == true
        or player:GetAttribute("Blocking") == true
        or player:GetAttribute("Ragdolled") == true then
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

function CharacterService:OnIncomingDamage(
    player: Player,
    amount: number,
    meta: any
): number
    local module = self:GetModule(player)

    if module and module.OnIncomingDamage then
        return math.max(
            0,
            tonumber(module.OnIncomingDamage(player, context, amount, meta))
                or amount
        )
    end

    return amount
end

function CharacterService:OnM1Hit(
    player: Player,
    combo: number,
    success: boolean
)
    local module = self:GetModule(player)

    if module and module.OnM1Hit then
        module.OnM1Hit(player, context, combo, success)
    end
end

return CharacterService
