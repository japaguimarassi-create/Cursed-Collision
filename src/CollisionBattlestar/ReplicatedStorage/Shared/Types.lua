--!strict
export type CombatAction="Light"|"Heavy"|"BlockStart"|"BlockEnd"|"Parry"|"Dash"|"Special"|"Overdrive"|"StyleToggle"
export type Profile={SchemaVersion:number,Coins:number,Inventory:{[string]:number},Mastery:{[string]:number},Exploration:number,Reputation:{[string]:number},Quest:{Id:string?,Progress:number,Target:number,Completed:boolean}}
return {}
