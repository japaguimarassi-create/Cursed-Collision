--!strict
export type Clip={Id:string,Speed:number,Priority:Enum.AnimationPriority}
export type Set={Name:string,Source:string,Clips:{[string]:Clip}}
local P={}
P.Sets={
	Vanguard={
		Name="Vanguard",
		Source="Publicly posted battleground combo clips; runtime permission is still validated by Roblox asset loading.",
		Clips={
			M1_1={Id="rbxassetid://18576726303",Speed=1.05,Priority=Enum.AnimationPriority.Action2},
			M1_2={Id="rbxassetid://18576729183",Speed=1.04,Priority=Enum.AnimationPriority.Action2},
			M1_3={Id="rbxassetid://18576731629",Speed=1.0,Priority=Enum.AnimationPriority.Action2},
			Special={Id="rbxassetid://2515090838",Speed=.92,Priority=Enum.AnimationPriority.Action3},
		},
	},
	Impact={
		Name="Impact",
		Source="Publicly posted punch clip plus official Roblox documentation example.",
		Clips={
			M1_1={Id="rbxassetid://17866759652",Speed=1.0,Priority=Enum.AnimationPriority.Action2},
			M1_2={Id="rbxassetid://2515090838",Speed=1.04,Priority=Enum.AnimationPriority.Action2},
			Special={Id="rbxassetid://17866759652",Speed=.84,Priority=Enum.AnimationPriority.Action3},
		},
	},
}
P.Fallback={
	M1_1=false,
	M1_2=false,
	M1_3=false,
	Special=false,
	Dash=false,
	HitTaken=false,
}
return P
