local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)

local CharacterModules = {
    Yuji = require(ReplicatedStorage.Characters.Yuji),
    Gojo = require(ReplicatedStorage.Characters.Gojo),
    Sukuna = require(ReplicatedStorage.Characters.Sukuna)
}

local CharacterService = {}
local ctx

function CharacterService:Configure(context)
    ctx = context
end

function CharacterService:GetAvailable()
    local result = {}
    for id, definition in pairs(Definitions) do
        table.insert(result, {
            Id = id,
            Name = definition.Name,
            Subtitle = definition.Subtitle
        })
    end
    table.sort(result, function(a, b)
        return a.Id < b.Id
    end)
    return result
end

function CharacterService:GetId(player)
    return player:GetAttribute("CharacterId") or "Yuji"
end

function CharacterService:GetModule(player)
    return CharacterModules[self:GetId(player)]
end

function CharacterService:Initialize(player)
    local id = self:GetId(player)
    local definition = Definitions[id] or Definitions.Yuji
    local state = ctx.getState(player)

    state.CharacterId = definition.Id
    state.Momentum = state.Momentum or 0
    state.BlackFlashWindow = nil
    state.Infinity = false
    state.LimitlessState = "Neutral"
    state.SlashAdaptation = "Neutral"

    player:SetAttribute("CharacterId", definition.Id)
    player:SetAttribute("CharacterName", definition.Name)
    player:SetAttribute("CharacterTitle", definition.Subtitle)
    player:SetAttribute("CE", definition.MaxCE)
    player:SetAttribute("MaxCE", definition.MaxCE)
    player:SetAttribute("Awakening", 0)
    player:SetAttribute("AwakeningActive", false)
    player:SetAttribute("DomainActive", false)
    player:SetAttribute("InClash", false)

    local module = CharacterModules[definition.Id]
    if module and module.Init then
        module.Init(player, ctx)
    end
end

function CharacterService:Select(player, id)
    if not CharacterModules[id] or not Definitions[id] then
        return false, "UnknownCharacter"
    end

    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local state = ctx.getState(player)

    if state.Clash or state.Domain or state.Awakening then
        return false, "Busy"
    end

    if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
        return false, "InCombat"
    end

    player:SetAttribute("CharacterId", id)
    self:Initialize(player)
    ctx.fx("CharacterSelected", ctx.rootPosition(player), id)
    return true
end

function CharacterService:Special(player, action, context)
    local module = self:GetModule(player)
    if not module then
        return false
    end
    if action == "Special" and module.Special then
        return module.Special(player, ctx, context)
    end
    if action == "Skill" and module.Skill then
        return module.Skill(player, ctx, context)
    end
    return false
end

function CharacterService:Awaken(player)
    local module = self:GetModule(player)
    if module and module.Awaken then
        module.Awaken(player, ctx)
        return true
    end
    return false
end

function CharacterService:Domain(player)
    local module = self:GetModule(player)
    if module and module.Domain then
        return module.Domain(player, ctx)
    end
    return false
end

function CharacterService:OneTime(player)
    local module = self:GetModule(player)
    if module and module.OneTime then
        return module.OneTime(player, ctx)
    end
    return false
end

function CharacterService:IncomingDamage(player, amount)
    local module = self:GetModule(player)
    if module and module.OnIncomingDamage then
        return module.OnIncomingDamage(player, ctx, amount)
    end
    return amount
end

return CharacterService
