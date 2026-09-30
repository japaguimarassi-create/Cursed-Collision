--!strict

export type EnemyTier = "Tier1" | "Tier2" | "Tier3" | "Elite"

export type PlayerState = {
    Credits: number,
    DamageLevel: number,
    Wave: number,
    DataReady: boolean,
    ComboIndex: number,
    LastAttackAt: number,
    LastComboAt: number,
}

export type RuntimeState = {
    Wave: number,
    Phase: string,
    ActiveEnemies: number,
    ElitePresent: boolean,
}

return {}