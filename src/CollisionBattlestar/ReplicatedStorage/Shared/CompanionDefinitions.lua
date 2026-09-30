--!strict
export type CompanionClass={Id:string,Damage:number,Cooldown:number,Range:number,PreferredDistance:number,ProtectsOwner:boolean,HealAmount:number,HealCooldown:number,HealRange:number}
local Classes:{[string]:CompanionClass}={
    Vanguard={Id="Vanguard",Damage=20,Cooldown=.9,Range=5,PreferredDistance=4,ProtectsOwner=true,HealAmount=0,HealCooldown=0,HealRange=0},
    Striker={Id="Striker",Damage=26,Cooldown=1.1,Range=9,PreferredDistance=8,ProtectsOwner=false,HealAmount=0,HealCooldown=0,HealRange=0},
    Guardian={Id="Guardian",Damage=16,Cooldown=1,Range=5.5,PreferredDistance=5,ProtectsOwner=true,HealAmount=0,HealCooldown=0,HealRange=0},
    Support={Id="Support",Damage=12,Cooldown=1.2,Range=8,PreferredDistance=9,ProtectsOwner=true,HealAmount=8,HealCooldown=4,HealRange=18},
}
return {Classes=table.freeze(Classes)}
