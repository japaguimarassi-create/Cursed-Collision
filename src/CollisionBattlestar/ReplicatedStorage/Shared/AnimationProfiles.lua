--!strict
export type Clip={Id:string,Speed:number,Priority:Enum.AnimationPriority,Looped:boolean}
export type Set={Name:string,Source:string,Clips:{[string]:Clip}}

local P={}

P.Sets={
	Vanguard={
		Name="Vanguard",
		Source="Collision Battlestar combat profile; public candidate clips plus Roblox-authored/default animation references.",
		Clips={
			Idle={Id="rbxassetid://180435571",Speed=1.0,Priority=Enum.AnimationPriority.Idle,Looped=true},
			Walk={Id="rbxassetid://180426354",Speed=1.0,Priority=Enum.AnimationPriority.Movement,Looped=true},
			Jump={Id="rbxassetid://125750702",Speed=1.0,Priority=Enum.AnimationPriority.Movement,Looped=false},
			Fall={Id="rbxassetid://180436148",Speed=1.0,Priority=Enum.AnimationPriority.Movement,Looped=true},
			M1_1={Id="rbxassetid://522635514",Speed=1.06,Priority=Enum.AnimationPriority.Action2,Looped=false},
			M1_2={Id="rbxassetid://18576729183",Speed=1.08,Priority=Enum.AnimationPriority.Action2,Looped=false},
			M1_3={Id="rbxassetid://18576731629",Speed=1.02,Priority=Enum.AnimationPriority.Action2,Looped=false},
			M1_4={Id="rbxassetid://522638767",Speed=1.0,Priority=Enum.AnimationPriority.Action2,Looped=false},
			Special={Id="rbxassetid://2515090838",Speed=.94,Priority=Enum.AnimationPriority.Action3,Looped=false},
			Dash={Id="rbxassetid://522638767",Speed=1.65,Priority=Enum.AnimationPriority.Action2,Looped=false},
			HitTaken={Id="rbxassetid://522635514",Speed=.72,Priority=Enum.AnimationPriority.Action3,Looped=false},
		},
	},
	Impact={
		Name="Impact",
		Source="Collision Battlestar impact profile; public candidate clips plus Roblox-authored/default animation references.",
		Clips={
			Idle={Id="rbxassetid://180435792",Speed=.98,Priority=Enum.AnimationPriority.Idle,Looped=true},
			Walk={Id="rbxassetid://180426354",Speed=.96,Priority=Enum.AnimationPriority.Movement,Looped=true},
			Jump={Id="rbxassetid://125750702",Speed=1.02,Priority=Enum.AnimationPriority.Movement,Looped=false},
			Fall={Id="rbxassetid://180436148",Speed=1.0,Priority=Enum.AnimationPriority.Movement,Looped=true},
			M1_1={Id="rbxassetid://17866759652",Speed=1.02,Priority=Enum.AnimationPriority.Action2,Looped=false},
			M1_2={Id="rbxassetid://522635514",Speed=1.08,Priority=Enum.AnimationPriority.Action2,Looped=false},
			M1_3={Id="rbxassetid://18576731629",Speed=.98,Priority=Enum.AnimationPriority.Action2,Looped=false},
			M1_4={Id="rbxassetid://522638767",Speed=.96,Priority=Enum.AnimationPriority.Action2,Looped=false},
			Special={Id="rbxassetid://2515090838",Speed=.90,Priority=Enum.AnimationPriority.Action3,Looped=false},
			Dash={Id="rbxassetid://522638767",Speed=1.7,Priority=Enum.AnimationPriority.Action2,Looped=false},
			HitTaken={Id="rbxassetid://522635514",Speed=.68,Priority=Enum.AnimationPriority.Action3,Looped=false},
		},
	},
}

P.Fallback={
	Idle=false,
	Walk=false,
	Jump=false,
	Fall=false,
	M1_1=false,
	M1_2=false,
	M1_3=false,
	M1_4=false,
	Special=false,
	Dash=false,
	HitTaken=false,
}

return P
