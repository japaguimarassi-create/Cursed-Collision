--!strict
local A={}

-- Public/free animation packs were verified in the Creator Store, but the public item pages expose pack/model IDs rather than a verified child Animation asset ID that can safely be copied into runtime code. The project also does not declare its player rig type in source. All twelve slots therefore keep Id="" and intentionally use the existing procedural fallback. Sources: https://create.roblox.com/store/asset/75164220659481/Fists-Combat-Animation-Pack-R6-Punch-Fighting and https://create.roblox.com/store/asset/13081191834/R6-Punch-Animation .
export type Definition={Id:string,Looped:boolean,Priority:Enum.AnimationPriority,Speed:number}

local Tracks:{[string]:Definition}={
	-- No direct public animation asset ID was verified for these slots during the 2026-09-26 asset audit.
	-- Verified source pack: Creator Store model 16663903306, "Free R6 battleground animations (v7)".
	-- It is explicitly open source for battleground games, but the page does not expose the contained
	-- animation asset IDs. Those IDs therefore remain empty rather than inventing rbxassetids.
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