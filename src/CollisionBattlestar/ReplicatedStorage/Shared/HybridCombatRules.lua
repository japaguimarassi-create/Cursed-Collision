--!strict
local R={}
R.Version="legacy-core-hybrid_v1"
R.ComboReset=.85
R.AirborneStates={
	[Enum.HumanoidStateType.Jumping]=true,
	[Enum.HumanoidStateType.Freefall]=true,
	[Enum.HumanoidStateType.FallingDown]=true
}
R.Features={DashCancel=true,AirLauncher=true,SlamFinish=true,WallImpact=true,Parry=true,Ragdoll=true}
function R.IsAirborne(humanoid:Humanoid):boolean return R.AirborneStates[humanoid:GetState()]==true end
function R.IsNearWall(origin:Vector3,direction:Vector3,distance:number,ignore:Instance?):boolean
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	if ignore then params.FilterDescendantsInstances={ignore}end
	local result=workspace:Raycast(origin,direction.Unit*distance,params)
	return result~=nil
end
return R
