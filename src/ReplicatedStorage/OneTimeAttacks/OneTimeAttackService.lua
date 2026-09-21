local OneTimeAttackService = {}
local used = {}

function OneTimeAttackService:Initialize(player)
    used[player] = false
    player:SetAttribute("OneTimeAttackReady", false)
    player:SetAttribute("OneTimeAttackUsed", false)
end

function OneTimeAttackService:TryUse(player, characterService)
    if not player:GetAttribute("OneTimeAttackReady") then
        return false
    end
    if used[player] then
        return false
    end
    if not player:GetAttribute("AwakeningActive") then
        return false
    end

    used[player] = true
    player:SetAttribute("OneTimeAttackUsed", true)
    player:SetAttribute("OneTimeAttackReady", false)

    local success = characterService:OneTime(player)
    return success
end

function OneTimeAttackService:End(player)
    used[player] = false
    player:SetAttribute("OneTimeAttackReady", false)
    player:SetAttribute("OneTimeAttackUsed", false)
end

return OneTimeAttackService
