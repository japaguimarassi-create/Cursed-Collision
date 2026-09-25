--!strict
export type CombatAction="Light"|"Heavy"|"BlockStart"|"BlockEnd"|"Parry"|"Dash"|"Special"|"Overdrive"|"StyleToggle"|"SprintStart"|"SprintEnd"
export type Profile={SchemaVersion:number,Coins:number,Level:number?,XP:number?,BattleStreakBest:number?,Inventory:{[string]:number},Mastery:{[string]:number},Exploration:number,Reputation:{[string]:number},Quest:{Id:string?,Progress:number,Target:number,Completed:boolean}}
return {}
