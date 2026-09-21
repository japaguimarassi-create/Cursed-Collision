local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)

local CharacterModules = {
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
            Subtitle = definition.Subtitle,
            Unique = definition.Unique,
            Domain = definition.Domain,
            Awakening = definition.AwakeningName
        })
    end
    table.sort(result, function(a, b)
        return a.Id < b.Id
    end)
    return result
end

function CharacterService:GetId(player)
    local id = player:GetAttribute("CharacterId")
    return Definitions[id] and id or "Yuji"
end

function CharacterService:GetModule(player)
    return CharacterModules[self:GetId(player)]
end

function CharacterService:GetCooldown(player, action)
    local module = self:GetModule(player)
    if module and module.GetCooldown then
        return module.GetCooldown(action)
    end
    return 0.6
end

function CharacterService:Initialize(player)
    local id = self:GetId(player)
    local definition = Definitions[id] or Definitions.Yuji
    local state = ctx.getState(player)

    state.CharacterId = definition.Id
    state.Momentum = 0
    state.BlackFlashWindow = nil
    state.Infinity = false
    state.InfinityBreakUntil = 0
    state.LimitlessState = "Neutral"
    state.SlashAdaptation = "Dismantle"
    state.Clash = false
    state.Domain = false

    player:SetAttribute("CharacterId", definition.Id)
    player:SetAttribute("CharacterName", definition.Name)
    player:SetAttribute("CharacterTitle", definition.Subtitle)
    player:SetAttribute("UniqueState", definition.Unique)
    player:SetAttribute("AwakeningName", definition.AwakeningName)
    player:SetAttribute("DomainName", definition.Domain or "None")
    player:SetAttribute("Awakening", 0)
    player:SetAttribute("AwakeningActive", false)
    player:SetAttribute("DomainActive", false)
    player:SetAttribute("InClash", false)
    player:SetAttribute("ClashOpponent", nil)
    player:SetAttribute("ClashOpening", false)

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

    if not state or state.Clash or state.Domain or state.Awakening then
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

function CharacterService:Special(player, action)
    local module = self:GetModule(player)
    if not module then
        return false
    end
    if action == "Special" and module.Special then
        return module.Special(player, ctx)
    elseif action == "Skill" and module.Skill then
        return module.Skill(player, ctx)
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