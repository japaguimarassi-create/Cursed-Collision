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
    EnergyCost: number?
}

type MoveList = {Move}

local Base: {[string]: MoveList} = {
    Yuji = {
        {Name = "Divergent Fist", Type = "Melee", Tag = "Yuji_DivergentFist", Range = 8, Damage = 14, Stun = 0.30, Knockback = 20, Cooldown = 0.55, EnergyCost = 8},
        {Name = "Manji Kick", Type = "Melee", Tag = "Yuji_ManjiKick", Range = 9, Damage = 20, Stun = 0.42, Knockback = 34, Cooldown = 1.20, EnergyCost = 12},
        {Name = "Black Flash", Type = "Melee", Tag = "Yuji_BlackFlash", Range = 9, Damage = 28, Stun = 0.62, Knockback = 58, Cooldown = 3.40, GuardBreak = true, EnergyCost = 22},
        {Name = "Soul Impact", Type = "Burst", Tag = "Yuji_SoulImpact", Radius = 11, Damage = 34, Stun = 0.80, Knockback = 76, Cooldown = 5.50, GuardBreak = true, Ragdoll = true, EnergyCost = 35}
    },
    Gojo = {
        {Name = "Lapse Blue", Type = "Control", Tag = "Gojo_LapseBlue", Range = 20, Damage = 15, Stun = 0.36, Knockback = 8, Pull = 68, Cooldown = 1.45, EnergyCost = 10},
        {Name = "Reversal Red", Type = "Burst", Tag = "Gojo_ReversalRed", Radius = 12, Damage = 25, Stun = 0.54, Knockback = 88, Cooldown = 2.50, GuardBreak = true, EnergyCost = 18},
        {Name = "Rapid Punches", Type = "Melee", Tag = "Gojo_RapidPunches", Range = 8, Damage = 22, Stun = 0.50, Knockback = 26, Cooldown = 1.85, EnergyCost = 16},
        {Name = "Hollow Purple", Type = "Projectile", Tag = "Gojo_HollowPurple", Range = 34, Damage = 50, Stun = 0.95, Knockback = 126, Cooldown = 8.80, GuardBreak = true, Ragdoll = true, EnergyCost = 48}
    },
    Sukuna = {
        {Name = "Dismantle", Type = "Projectile", Tag = "Sukuna_Dismantle", Range = 24, Damage = 17, Stun = 0.32, Knockback = 28, Cooldown = 0.85, EnergyCost = 9},
        {Name = "Cleave", Type = "Area", Tag = "Sukuna_Cleave", Radius = 10, Damage = 22, Stun = 0.46, Knockback = 36, Cooldown = 1.50, GuardBreak = true, EnergyCost = 13},
        {Name = "Flame Arrow", Type = "Projectile", Tag = "Sukuna_FlameArrow", Range = 28, Damage = 34, Stun = 0.58, Knockback = 70, Cooldown = 3.80, GuardBreak = true, EnergyCost = 28},
        {Name = "World Cutting Slash", Type = "Projectile", Tag = "Sukuna_WorldCut", Range = 38, Damage = 58, Stun = 1.05, Knockback = 136, Cooldown = 9.50, GuardBreak = true, Ragdoll = true, EnergyCost = 52}
    },
    Megumi = {
        {Name = "Divine Dog", Type = "Melee", Tag = "Megumi_DivineDog", Range = 11, Damage = 16, Stun = 0.38, Knockback = 30, Cooldown = 0.95, EnergyCost = 10},
        {Name = "Nue", Type = "Projectile", Tag = "Megumi_Nue", Range = 24, Damage = 19, Stun = 0.42, Knockback = 44, Cooldown = 1.85, EnergyCost = 14},
        {Name = "Max Elephant", Type = "Area", Tag = "Megumi_MaxElephant", Radius = 13, Damage = 26, Stun = 0.60, Knockback = 68, Cooldown = 3.60, EnergyCost = 24},
        {Name = "Divine Dog: Totality", Type = "Melee", Tag = "Megumi_Totality", Range = 13, Damage = 34, Stun = 0.76, Knockback = 74, Cooldown = 5.80, GuardBreak = true, Ragdoll = true, EnergyCost = 36}
    }
}

local Awakening: {[string]: MoveList} = {
    Yuji = {
        {Name = "Black Flash Barrage", Type = "Melee", Tag = "Yuji_Awake_Barrage", Range = 9, Damage = 25, Stun = 0.42, Knockback = 30, Cooldown = 0.75, EnergyCost = 0},
        {Name = "Dismantle", Type = "Projectile", Tag = "Yuji_Awake_Dismantle", Range = 24, Damage = 20, Stun = 0.34, Knockback = 34, Cooldown = 1.25, EnergyCost = 0},
        {Name = "Soul Rattle", Type = "Control", Tag = "Yuji_Awake_SoulRattle", Range = 12, Damage = 30, Stun = 0.72, Knockback = 22, Cooldown = 2.40, GuardBreak = true, EnergyCost = 0},
        {Name = "Black Flash: Chain", Type = "Burst", Tag = "Yuji_Awake_Chain", Radius = 12, Damage = 46, Stun = 0.95, Knockback = 104, Cooldown = 6.20, GuardBreak = true, Ragdoll = true, EnergyCost = 0}
    },
    Gojo = {
        {Name = "Blue Barrage", Type = "Control", Tag = "Gojo_Awake_Blue", Range = 22, Damage = 20, Stun = 0.42, Knockback = 20, Pull = 86, Cooldown = 0.90, EnergyCost = 0},
        {Name = "Red Burst", Type = "Burst", Tag = "Gojo_Awake_Red", Radius = 14, Damage = 34, Stun = 0.66, Knockback = 108, Cooldown = 1.90, GuardBreak = true, EnergyCost = 0},
        {Name = "Infinity Rush", Type = "Melee", Tag = "Gojo_Awake_Rush", Range = 10, Damage = 31, Stun = 0.62, Knockback = 54, Cooldown = 1.40, EnergyCost = 0},
        {Name = "Unlimited Void Impact", Type = "Burst", Tag = "Gojo_Awake_Void", Radius = 16, Damage = 54, Stun = 1.10, Knockback = 120, Cooldown = 7.50, GuardBreak = true, Ragdoll = true, EnergyCost = 0}
    },
    Sukuna = {
        {Name = "Dismantle Rain", Type = "Projectile", Tag = "Sukuna_Awake_Rain", Range = 30, Damage = 24, Stun = 0.38, Knockback = 38, Cooldown = 0.90, EnergyCost = 0},
        {Name = "Cleave Storm", Type = "Area", Tag = "Sukuna_Awake_Cleave", Radius = 14, Damage = 30, Stun = 0.60, Knockback = 62, Cooldown = 1.60, GuardBreak = true, EnergyCost = 0},
        {Name = "Divine Flame", Type = "Projectile", Tag = "Sukuna_Awake_Flame", Range = 30, Damage = 42, Stun = 0.66, Knockback = 82, Cooldown = 3.25, GuardBreak = true, EnergyCost = 0},
        {Name = "World Slash: Enma", Type = "Projectile", Tag = "Sukuna_Awake_World", Range = 42, Damage = 66, Stun = 1.20, Knockback = 148, Cooldown = 8.20, GuardBreak = true, Ragdoll = true, EnergyCost = 0}
    },
    Megumi = {
        {Name = "Shadow Hounds", Type = "Melee", Tag = "Megumi_Awake_Hounds", Range = 13, Damage = 22, Stun = 0.46, Knockback = 38, Cooldown = 0.80, EnergyCost = 0},
        {Name = "Winged Nue", Type = "Projectile", Tag = "Megumi_Awake_Nue", Range = 30, Damage = 26, Stun = 0.50, Knockback = 54, Cooldown = 1.40, EnergyCost = 0},
        {Name = "Max Elephant: Flood", Type = "Area", Tag = "Megumi_Awake_Elephant", Radius = 16, Damage = 34, Stun = 0.70, Knockback = 76, Cooldown = 2.90, GuardBreak = true, EnergyCost = 0},
        {Name = "Chimera Shadow Garden", Type = "Area", Tag = "Megumi_Awake_Garden", Radius = 18, Damage = 48, Stun = 0.98, Knockback = 96, Cooldown = 7.20, GuardBreak = true, Ragdoll = true, EnergyCost = 0}
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
    return source[slot]
end

function Movesets.IsPlayable(id: string): boolean
    return Base[id] ~= nil
end

return Movesets
