--!strict

local Rules = {}

export type Tier = "Tier1" | "Tier2" | "Tier3" | "Elite"

local TIER_STATS = {
    Tier1 = {Health = 70, Damage = 8, Reward = 5, Speed = 11},
    Tier2 = {Health = 125, Damage = 12, Reward = 8, Speed = 12},
    Tier3 = {Health = 210, Damage = 18, Reward = 12, Speed = 13},
    Elite = {Health = 420, Damage = 26, Reward = 35, Speed = 10},
}

local SKINS = {
    Default = {Name = "Default", Price = 0, Primary = Color3.fromRGB(205, 214, 228), Accent = Color3.fromRGB(85, 205, 255)},
    Redline = {Name = "Redline", Price = 125, Primary = Color3.fromRGB(104, 42, 50), Accent = Color3.fromRGB(255, 80, 92)},
    NeonPulse = {Name = "Neon Pulse", Price = 225, Primary = Color3.fromRGB(36, 76, 94), Accent = Color3.fromRGB(48, 235, 224)},
    ArcticCore = {Name = "Arctic Core", Price = 325, Primary = Color3.fromRGB(124, 164, 185), Accent = Color3.fromRGB(190, 240, 255)},
}

local ACTIONS = {
    Attack = true,
    Dash = true,
    Upgrade = true,
    BuySkin = true,
    EquipSkin = true,
    ToggleEcho = true,
    GetFriends = true,
    SummonEcho = true,
    DismissEcho = true,
    RequestState = true,
    Admin = true,
    Respawn = true,
}

function Rules.enemyStats(tier: string)
    return TIER_STATS[tier]
end

function Rules.enemyCount(wave: number): number
    return math.clamp(5 + math.floor(math.max(0, wave - 1) * 1.35), 5, 20)
end

function Rules.normalTier(wave: number, index: number): Tier
    local pressure = wave + math.floor(index / 4)
    if pressure >= 13 then
        return "Tier3"
    end
    if pressure >= 7 then
        return "Tier2"
    end
    return "Tier1"
end

function Rules.waveReward(wave: number): number
    return 25 * math.max(1, wave)
end

function Rules.upgradeCost(level: number): number
    return 50 * (2 ^ math.clamp(level, 0, 10))
end

function Rules.isActionAllowed(action: unknown): boolean
    return type(action) == "string" and ACTIONS[action] == true
end

function Rules.isSkinValid(skinId: unknown): boolean
    return type(skinId) == "string" and SKINS[skinId] ~= nil
end

function Rules.skin(skinId: string)
    return SKINS[skinId]
end

function Rules.skinIds(): {string}
    return {"Default", "Redline", "NeonPulse", "ArcticCore"}
end

function Rules.maxConcurrentEnemies(): number
    return 20
end

function Rules.playerMaxHealth(): number
    return 100
end

function Rules.baseDamage(): {number}
    return {25, 30, 35}
end

function Rules.attackCooldown(): number
    return 0.38
end

function Rules.comboWindow(): number
    return 0.8
end

function Rules.dashCooldown(): number
    return 0.9
end

function Rules.dashSpeed(): number
    return 72
end

return table.freeze(Rules)
