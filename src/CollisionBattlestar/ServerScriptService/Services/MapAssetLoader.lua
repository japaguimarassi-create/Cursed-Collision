--!strict
local AssetService=game:GetService("AssetService")

local S={}

local function sanitize(root:Instance)
	for _,item in ipairs(root:GetDescendants())do
		if item:IsA("Script")or item:IsA("LocalScript")or item:IsA("ModuleScript")then
			item:Destroy()
		elseif item:IsA("BasePart")then
			item.Anchored=true
			item.CanTouch=false
			item.CanQuery=false
		end
	end
end

function S.Load(assetId:number,parent:Instance,name:string,cf:CFrame?):Model?
	if assetId<=0 then return nil end
	local ok,result=pcall(function()
		return AssetService:LoadAssetAsync(assetId)
	end)
	if not ok or not result or not result:IsA("Model")then return nil end
	local model=result::Model
	sanitize(model)
	model.Name=name
	if cf then model:PivotTo(cf)end
	model.Parent=parent
	return model
end

return S