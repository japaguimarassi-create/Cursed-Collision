--!strict

local Rules = {}

export type Tier = "Tier1" | "Tier2" | "Tier3" | "Elite"

type TierStats = {
    Health: number,
    Damage: number,
    Reward: number,
    Speed: number,
}

type Skin = {
    Name: string,
    Price: number,
    Primary: {number},
    Accent: {number},
}

local tierStats: {[string]: TierStats} = {
    Tier1 = {Health = 70, Damage = 8, Reward = 5, Speed = 11},
    Tier2 = {Health = 125, Damage = 12, Reward = 8, Speed = 12},
    Tier3 = {Health = 210, Damage = 18, Reward = 12, Speed = 13},
    Elite = {Health = 420, Damage = 26, Reward = 35, Speed = 10},
}

local skins: {[string]: Skin} = {
    Default = {Name = "Default", Price = 0, Primary = {205, 214, 228}, Accent = {85, 205, 255}},
    Redline = {Name = "Redline", Price = 125, Primary = {104, 42, 50}, Accent = {255, 80, 92}},
    NeonPulse = {Name = "Neon Pulse", Price = 225, Primary = {36, 76, 94}, Accent = {48, 235, 224}},
    ArcticCore = {Name = "Arctic Core", Price = 325, Primary = {124, 164, 185}, Accent = {190, 240, 255}},
}

local echoClasses = {"Vanguard", "Striker", "Guardian", "Support"}

function Rules.enemyStats(tier: string): TierStats?
    return tierStats[tier]
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

function Rules.playerMaxHealth(): number
    return 100
end

function Rules.baseDamage(combo: number): number
    return ({25, 30, 35})[math.clamp(combo, 1, 3)]
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

function Rules.isValidEchoClass(classId: unknown): boolean
    for _, value in ipairs(echoClasses) do
        if value == classId then
            return true
        end
    end
    return false
end

function Rules.echoClasses(): {string}
    return table.clone(echoClasses)
end

function Rules.skinIds(): {string}
    return {"Default", "Redline", "NeonPulse", "ArcticCore"}
end

function Rules.skin(skinId: string): Skin?
    return skins[skinId]
end

function Rules.isValidSkin(skinId: unknown): boolean
    return type(skinId) == "string" and skins[skinId] ~= nil
end

return table.freeze(Rules)
