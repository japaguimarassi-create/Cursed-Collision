--!strict
local CollectionService=game:GetService("CollectionService")
local S={}
local function restore(part:BasePart)
	if not part.Parent then return end
	part.Transparency=part:GetAttribute("OriginalTransparency")or 0
part.CanCollide=part:GetAttribute("OriginalCanCollide")~=false
part.CanQuery=part:GetAttribute("OriginalCanQuery")~=false
part:SetAttribute("Broken",false)
end
function S.BreakInBox(cf:CFrame,size:Vector3,strength:number):number
	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances=CollectionService:GetTagged("CombatDestructible")
	params.MaxParts=32
	local hit={}
	local broken=0
	for _,part in workspace:GetPartBoundsInBox(cf,size,params)do
		if not hit[part]and part:GetAttribute("Broken")~=true then
			hit[part]=true
			broken+=1
			part:SetAttribute("Broken",true)
			part:SetAttribute("OriginalTransparency",part.Transparency)
			part:SetAttribute("OriginalCanCollide",part.CanCollide)
			part:SetAttribute("OriginalCanQuery",part.CanQuery)
			part.CanCollide=false
			part.CanQuery=false
			part.Transparency=.65
			local duration=strength>=2 and 8 or 5
			task.delay(duration,function()restore(part)end)
		end
	end
	return broken
end
return S
