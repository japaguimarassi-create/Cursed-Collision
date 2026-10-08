--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.ProgressionRules)
local ShopRules = require(ReplicatedStorage.Shared.ShopRules)

local ProgressionService = {}
ProgressionService.__index = ProgressionService

function ProgressionService.new(playerState, runtimeState)
    return setmetatable({
        playerState = playerState,
        runtimeState = runtimeState,
    }, ProgressionService)
end

function ProgressionService:Start()
end

function ProgressionService:Purchase(player: Player, upgradeId: any)
    if not ShopRules.isSafeShopPhase(self.runtimeState.phase) then
        return false, "shop_closed"
    end

    if not Rules.isValidUpgrade(upgradeId) then
        return false, "invalid_upgrade"
    end

    local definition = Rules.getDefinition(upgradeId)
    local currentLevel = self.playerState:GetUpgradeLevel(player, upgradeId)
    local cost = Rules.getCost(upgradeId, currentLevel)

    if cost == math.huge then
        return false, "max_level"
    end

    return self.playerState:TryNamedUpgrade(player, upgradeId, definition, cost)
end

function ProgressionService:GetSnapshot(player: Player)
    local result = {}

    for _, upgradeId in ipairs({"Damage", "MaxHealth", "Dash", "Critical", "Recovery"}) do
        local level = self.playerState:GetUpgradeLevel(player, upgradeId)
        result[upgradeId] = {
            Level = level,
            Cost = Rules.getCost(upgradeId, level),
            MaxLevel = Rules.getMaxLevel(upgradeId),
        }
    end

    return result
end

return ProgressionService
