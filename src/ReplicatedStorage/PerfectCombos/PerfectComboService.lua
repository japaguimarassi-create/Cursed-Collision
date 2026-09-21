local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Definitions = require(ReplicatedStorage.Characters.CharacterDefinitions)

local PerfectComboService = {}
local progress = {}

function PerfectComboService:Reset(player)
    progress[player] = nil
    player:SetAttribute("PerfectComboStep", 0)
    player:SetAttribute("OneTimeAttackReady", false)
end

function PerfectComboService:OnAwakening(player)
    self:Reset(player)
end

function PerfectComboService:Record(player, action)
    if not player:GetAttribute("AwakeningActive") then
        return false
    end

    local definition = Definitions[player:GetAttribute("CharacterId") or "Yuji"]
    local sequence = definition and definition.PerfectCombo
    if not sequence then
        return false
    end

    local entry = progress[player]
    if not entry then
        if action ~= sequence[1] then
            return false
        end
        entry = {index = 1, last = os.clock()}
        progress[player] = entry
        player:SetAttribute("PerfectComboStep", 1)
        return false
    end

    if os.clock() - entry.last > Config.PerfectCombo.StepWindow then
        self:Reset(player)
        return false
    end

    local nextIndex = entry.index + 1
    if sequence[nextIndex] ~= action then
        self:Reset(player)
        return false
    end

    entry.index = nextIndex
    entry.last = os.clock()
    player:SetAttribute("PerfectComboStep", entry.index)

    if entry.index >= #sequence then
        player:SetAttribute("OneTimeAttackReady", true)
        return true
    end

    return false
end

function PerfectComboService:End(player)
    self:Reset(player)
end

return PerfectComboService