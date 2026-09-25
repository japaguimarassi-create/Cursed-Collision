--!strict
local A={}
export type Definition={Id:string,Looped:boolean,Priority:Enum.AnimationPriority,Speed:number}

local Tracks:{[string]:Definition}={
	Light1={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1},
	Light2={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1.02},
	Light3={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1.04},
	Light4={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1.06},
	Heavy={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1},
	Special={Id="",Looped=false,Priority=Enum.AnimationPriority.Action2,Speed=1},
	Dash={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1},
	Block={Id="",Looped=true,Priority=Enum.AnimationPriority.Action,Speed=1},
	Parry={Id="",Looped=false,Priority=Enum.AnimationPriority.Action2,Speed=1},
	Overdrive={Id="",Looped=true,Priority=Enum.AnimationPriority.Action2,Speed=1},
	BotAttack={Id="",Looped=false,Priority=Enum.AnimationPriority.Action,Speed=1},
	BossAttack={Id="",Looped=false,Priority=Enum.AnimationPriority.Action2,Speed=1},
}

function A.Get(name:string):Definition?
	return A.Tracks[name]
end

function A.GetId(name:string):string?
	local definition=A.Get(name)
	if not definition or definition.Id=="" then return nil end
	return definition.Id
end

A.Tracks=Tracks

return A
