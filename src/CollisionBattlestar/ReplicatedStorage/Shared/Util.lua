--!strict
local U={}
function U.Root(model:Model?):BasePart?
	local part=model and model:FindFirstChild("HumanoidRootPart")
	return part and part:IsA("BasePart") and part or nil
end
function U.Humanoid(model:Instance?):Humanoid?
	return model and model:FindFirstChildOfClass("Humanoid") or nil
end
function U.Model(instance:Instance):Model?
	local current:Instance?=instance
	while current do
		if current:IsA("Model") then return current end
		current=current.Parent
	end
	return nil
end
function U.Part(parent:Instance,name:string,size:Vector3,cframe:CFrame,material:Enum.Material,color:Color3,anchored:boolean):Part
	local part=Instance.new("Part")
	part.Name=name
	part.Size=size
	part.CFrame=cframe
	part.Material=material
	part.Color=color
	part.Anchored=anchored
	part.TopSurface=Enum.SurfaceType.Smooth
	part.BottomSurface=Enum.SurfaceType.Smooth
	part.Parent=parent
	return part
end
function U.IsAlive(model:Model?):boolean
	local humanoid=U.Humanoid(model)
	return humanoid~=nil and humanoid.Health>0
end
function U.SafeUnit(vector:Vector3,fallback:Vector3):Vector3
	return vector.Magnitude>0.001 and vector.Unit or fallback
end
function U.Round(value:number,decimals:number):number
	local scale=10^decimals
	return math.floor(value*scale+.5)/scale
end
return U
