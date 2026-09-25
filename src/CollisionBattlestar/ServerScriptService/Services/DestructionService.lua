--!strict
local CollectionService=game:GetService("CollectionService")
local S={}
local function restore(part:BasePart)
	if not part.Parent then return end
	part.Transparency=0;part.CanCollide=true;part.CanQuery=true;part:SetAttribute("Broken",false)
end
function S.BreakInBox(cf:CFrame,size:Vector3,strength:number)
	local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=CollectionService:GetTagged("CombatDestructible")
	local hit={}
	for _,part in workspace:GetPartBoundsInBox(cf,size,params)do
		if not hit[part]then hit[part]=true;part:SetAttribute("Broken",true);part.CanCollide=false;part.CanQuery=false;part.Transparency=.65;local duration=strength>=2 and 8 or 5;task.delay(duration,function()restore(part)end)end
	end
end
return S
