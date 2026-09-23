--!strict

export type Move = {
    Slot: number?,
    Name: string,
    Type: string,
    Tag: string,
    Range: number?,
    Radius: number?,
    Damage: number,
    Stun: number,
    Knockback: number,
    Cooldown: number,
    Pull: number?,
    GuardBreak: boolean?,
    Launch: boolean?,
    Slam: boolean?,
    Ragdoll: boolean?,
    EnergyCost: number?,
    Startup: number?,
    ActiveTime: number?,
    Recovery: number?,
    Hits: number?,
    HitInterval: number?,
    SecondaryDamage: number?,
    SecondaryDelay: number?,
    Domain: string?,
    DomainRadius: number?,
    DomainDuration: number?,
    BypassInfinity: boolean?,
    LowDamage: boolean?
}

type MoveList = {Move}

local Base: {[string]: MoveList} = {
    Yuji = {
        {Name = "Cursed Strikes", Type = "Melee", Tag = "Yuji_CursedStrikes", Range = 9, Damage = 10, Stun = 0.26, Knockback = 10, Cooldown = 0.75, Hits = 3, HitInterval = 0.07, Startup = 0.08, ActiveTime = 0.22, Recovery = 0.20, EnergyCost = 8},
        {Name = "Crushing Blow", Type = "Melee", Tag = "Yuji_CrushingBlow", Range = 10, Damage = 22, Stun = 0.42, Knockback = 42, Cooldown = 1.35, Launch = true, Startup = 0.16, ActiveTime = 0.08, Recovery = 0.34, EnergyCost = 12},
        {Name = "Divergent Fist", Type = "Melee", Tag = "Yuji_DivergentFist", Range = 9, Damage = 15, SecondaryDamage = 12, SecondaryDelay = 0.17, Stun = 0.38, Knockback = 24, Cooldown = 2.15, Startup = 0.13, ActiveTime = 0.22, Recovery = 0.34, EnergyCost = 16},
        {Name = "Manji Kick", Type = "Melee", Tag = "Yuji_ManjiKick", Range = 9, Damage = 26, Stun = 0.60, Knockback = 58, Cooldown = 4.20, Ragdoll = true, Startup = 0.11, ActiveTime = 0.07, Recovery = 0.46, EnergyCost = 24}
    },
    Gojo = {
        {Name = "Lapse Blue", Type = "Control", Tag = "Gojo_LapseBlue", Range = 22, Damage = 14, Stun = 0.36, Knockback = 8, Pull = 76, Cooldown = 1.45, Startup = 0.16, ActiveTime = 0.08, Recovery = 0.30, EnergyCost = 10},
        {Name = "Reversal Red", Type = "Burst", Tag = "Gojo_ReversalRed", Radius = 12, Damage = 26, Stun = 0.54, Knockback = 76, Cooldown = 2.60, GuardBreak = true, Startup = 0.18, ActiveTime = 0.08, Recovery = 0.38, EnergyCost = 18},
        {Name = "Rapid Punches", Type = "Melee", Tag = "Gojo_RapidPunches", Range = 8, Damage = 8, Stun = 0.28, Knockback = 8, Cooldown = 1.85, Hits = 5, HitInterval = 0.055, Startup = 0.10, ActiveTime = 0.30, Recovery = 0.28, EnergyCost = 16},
        {Name = "Twofold Kick", Type = "Melee", Tag = "Gojo_TwofoldKick", Range = 10, Damage = 24, Stun = 0.48, Knockback = 42, Cooldown = 2.80, Launch = true, Startup = 0.13, ActiveTime = 0.08, Recovery = 0.34, EnergyCost = 20}
    },
    Megumi = {
        {Name = "Divine Dogs", Type = "Melee", Tag = "Megumi_DivineDogs", Range = 11, Damage = 16, Stun = 0.34, Knockback = 24, Cooldown = 1.10, Hits = 2, HitInterval = 0.12, Startup = 0.11, ActiveTime = 0.18, Recovery = 0.28, EnergyCost = 10},
        {Name = "Toad", Type = "Control", Tag = "Megumi_Toad", Range = 17, Damage = 12, Stun = 0.48, Knockback = 12, Pull = 58, Cooldown = 1.70, Startup = 0.17, ActiveTime = 0.07, Recovery = 0.30, EnergyCost = 13},
        {Name = "Nue", Type = "Projectile", Tag = "Megumi_Nue", Range = 28, Damage = 20, Stun = 0.42, Knockback = 38, Cooldown = 2.00, Startup = 0.18, ActiveTime = 0.08, Recovery = 0.28, EnergyCost = 15},
        {Name = "Rabbit Escape", Type = "Area", Tag = "Megumi_RabbitEscape", Radius = 11, Damage = 6, Stun = 0.24, Knockback = 10, Cooldown = 3.10, Hits = 3, HitInterval = 0.16, Startup = 0.10, ActiveTime = 0.52, Recovery = 0.32, EnergyCost = 18}
    },
    Sukuna = {
        {Name = "Dismantle", Type = "Projectile", Tag = "Sukuna_Dismantle", Range = 30, Damage = 17, Stun = 0.30, Knockback = 24, Cooldown = 0.90, Startup = 0.11, ActiveTime = 0.05, Recovery = 0.24, EnergyCost = 9},
        {Name = "Cleave", Type = "Area", Tag = "Sukuna_Cleave", Radius = 10, Damage = 22, Stun = 0.42, Knockback = 36, Cooldown = 1.50, GuardBreak = true, Startup = 0.12, ActiveTime = 0.06, Recovery = 0.30, EnergyCost = 13},
        {Name = "Spiderweb", Type = "Burst", Tag = "Sukuna_Spiderweb", Radius = 13, Damage = 18, Stun = 0.30, Knockback = 18, Cooldown = 2.70, Startup = 0.18, ActiveTime = 0.08, Recovery = 0.35, EnergyCost = 18},
        {Name = "Shrine Slash", Type = "Control", Tag = "Sukuna_ShrineSlash", Range = 18, Damage = 28, Stun = 0.55, Knockback = 48, Cooldown = 4.20, GuardBreak = true, Startup = 0.16, ActiveTime = 0.08, Recovery = 0.40, EnergyCost = 24}
    }
}

local Awakening: {[string]: MoveList} = {
    Yuji = {
        {Name = "Shrine: Dismantle", Type = "Projectile", Tag = "Yuji_Shujuku_Dismantle", Range = 34, Damage = 24, Stun = 0.30, Knockback = 34, Cooldown = 1.05, Startup = 0.10, ActiveTime = 0.04, Recovery = 0.22, BypassInfinity = true},
        {Name = "Piercing Blood", Type = "Projectile", Tag = "Yuji_PiercingBlood", Range = 42, Damage = 32, Stun = 0.45, Knockback = 56, Cooldown = 2.60, Startup = 0.22, ActiveTime = 0.05, Recovery = 0.34},
        {Name = "Blood Hardened Fist", Type = "Melee", Tag = "Yuji_BloodFist", Range = 10, Damage = 28, Stun = 0.48, Knockback = 40, Cooldown = 2.10, Hits = 2, HitInterval = 0.08, Startup = 0.10, ActiveTime = 0.15, Recovery = 0.30},
        {Name = "Black Flash Chain", Type = "Burst", Tag = "Yuji_Shujuku_BlackFlash", Radius = 10, Damage = 48, Stun = 0.78, Knockback = 86, Cooldown = 5.60, GuardBreak = true, Ragdoll = true, Startup = 0.18, ActiveTime = 0.10, Recovery = 0.46}
    },
    Gojo = {
        {Name = "Lapse Blue: MAX", Type = "Control", Tag = "Gojo_MaxBlue", Range = 30, Damage = 25, Stun = 0.44, Knockback = 12, Pull = 110, Cooldown = 1.10, Startup = 0.15, ActiveTime = 0.08, Recovery = 0.26},
        {Name = "Reversal Red: MAX", Type = "Burst", Tag = "Gojo_MaxRed", Radius = 15, Damage = 40, Stun = 0.62, Knockback = 112, Cooldown = 2.10, GuardBreak = true, Startup = 0.20, ActiveTime = 0.08, Recovery = 0.36},
        {Name = "Hollow Purple", Type = "Projectile", Tag = "Gojo_HollowPurple", Range = 55, Damage = 68, Stun = 1.00, Knockback = 150, Cooldown = 7.80, GuardBreak = true, Ragdoll = true, BypassInfinity = true, Startup = 0.42, ActiveTime = 0.05, Recovery = 0.60},
        {Name = "Unlimited Void", Type = "Domain", Tag = "Gojo_UnlimitedVoid", Damage = 0, Stun = 0, Knockback = 0, Cooldown = 10.0, Domain = "UnlimitedVoid", DomainRadius = 22, DomainDuration = 8.0, Startup = 0.34, ActiveTime = 0.05, Recovery = 0.50}
    },
    Megumi = {
        {Name = "Great Serpent", Type = "Control", Tag = "Megumi_GreatSerpent", Range = 24, Damage = 30, Stun = 0.52, Knockback = 34, Pull = 44, Cooldown = 2.10, Startup = 0.18, ActiveTime = 0.08, Recovery = 0.30},
        {Name = "Max Elephant", Type = "Area", Tag = "Megumi_MaxElephant", Radius = 16, Damage = 36, Stun = 0.56, Knockback = 72, Cooldown = 3.10, GuardBreak = true, Startup = 0.22, ActiveTime = 0.10, Recovery = 0.42},
        {Name = "Round Deer", Type = "Area", Tag = "Megumi_RoundDeer", Radius = 12, Damage = 4, Stun = 0.20, Knockback = 0, Cooldown = 4.20, Startup = 0.18, ActiveTime = 0.10, Recovery = 0.34},
        {Name = "Mahoraga", Type = "Utility", Tag = "Megumi_Mahoraga", Damage = 0, Stun = 0, Knockback = 0, Cooldown = 1.40, Startup = 0.20, ActiveTime = 0.05, Recovery = 0.30}
    },
    Sukuna = {
        {Name = "Strong Dismantle", Type = "Projectile", Tag = "Sukuna_StrongDismantle", Range = 42, Damage = 36, Stun = 0.36, Knockback = 58, Cooldown = 1.15, Startup = 0.16, ActiveTime = 0.05, Recovery = 0.25, BypassInfinity = true},
        {Name = "Rush", Type = "Control", Tag = "Sukuna_Rush", Range = 24, Damage = 34, Stun = 0.55, Knockback = 68, Cooldown = 2.40, Pull = 0, GuardBreak = true, Startup = 0.20, ActiveTime = 0.08, Recovery = 0.36},
        {Name = "Fuga", Type = "Projectile", Tag = "Sukuna_Fuga", Range = 40, Damage = 54, Stun = 0.68, Knockback = 92, Cooldown = 4.20, GuardBreak = true, Ragdoll = true, Startup = 0.38, ActiveTime = 0.08, Recovery = 0.50},
        {Name = "Malevolent Shrine", Type = "Domain", Tag = "Sukuna_MalevolentShrine", Damage = 0, Stun = 0, Knockback = 0, Cooldown = 10.0, Domain = "MalevolentShrine", DomainRadius = 25, DomainDuration = 8.0, LowDamage = true, Startup = 0.32, ActiveTime = 0.05, Recovery = 0.52}
    }
}

local function cloneMove(move: Move, slot: number): Move
    local result: Move = {} :: Move
    for key, value in pairs(move) do
        (result :: any)[key] = value
    end
    result.Slot = slot
    return result
end

local Movesets = {}

function Movesets.Get(id: string, isAwakened: boolean?): MoveList
    local source = isAwakened and Awakening[id] or Base[id]
    source = source or Base.Yuji

    local result: MoveList = {}
    for slot, move in ipairs(source) do
        result[slot] = cloneMove(move, slot)
    end

    return result
end

function Movesets.GetMove(id: string, slot: number, isAwakened: boolean?): Move?
    local source = isAwakened and Awakening[id] or Base[id]
    source = source or Base.Yuji
    local move = source[slot]

    if not move then
        return nil
    end

    return cloneMove(move, slot)
end

function Movesets.IsPlayable(id: string): boolean
    return Base[id] ~= nil
end

return Movesets
