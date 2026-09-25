--!strict
local Players=game:GetService("Players")
local U=require(game.ReplicatedStorage.Shared.Util)

local S={}
export type TargetInfo={
	Model:Model,
	Humanoid:Humanoid,
	Root:BasePart,
	Player:Player?,
	IsEnemy:boolean,
}

export type QueryOptions={
	MaxTargets:number?,
	LineOfSight:boolean?,
}

local function visible(attacker:Model,target:Model,origin:Vector3,targetPosition:Vector3):boolean
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={attacker}
	params.IgnoreWater=true
	local result=workspace:Raycast(origin,targetPosition-origin,params)
	if not result then return true end
	return U.Model(result.Instance)==target
end

function S.Query(attacker:Model,cf:CFrame,size:Vector3,options:QueryOptions?):{TargetInfo}
	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={attacker}
	params.MaxParts=48
	local maxTargets=options and options.MaxTargets or 12
	local result:{TargetInfo}={}
	local seen:{[Model]:boolean}={}
	for _,part in ipairs(workspace:GetPartBoundsInBox(cf,size,params))do
		local model=U.Model(part)
		if model and model~=attacker and not seen[model]then
			local humanoid=U.Hum(model)
			local root=U.Root(model)
			if humanoid and root and humanoid.Health>0 then
				local player=Players:GetPlayerFromCharacter(model)
				local enemy=model:GetAttribute("Archetype")~=nil and not player
				if (enemy or player) and (not options or not options.LineOfSight or visible(attacker,model,cf.Position,root.Position))then
					seen[model]=true
					table.insert(result,{Model=model,Humanoid=humanoid,Root=root,Player=player,IsEnemy=enemy})
					if #result>=maxTargets then break end
				end
			end
		end
	end
	return result
end

return S
