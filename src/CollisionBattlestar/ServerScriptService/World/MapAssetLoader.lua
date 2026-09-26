--!strict
local InsertService=game:GetService("InsertService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)
local S={}

local function sanitize(instance:Instance)
	for _,descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored=true
			descendant.CanTouch=false
			descendant.CanQuery=false
		end
	end
end

local function load(root:Folder,name:string,assetId:number,position:Vector3)
	local ok,asset=pcall(function() return InsertService:LoadAsset(assetId) end)
	if not ok or not asset or not asset:IsA("Model") then return false end
	asset.Name=name
	sanitize(asset)
	asset:PivotTo(CFrame.new(position))
	asset.Parent=root
	return true
end

function S.Init(worldRoot:Folder)
	task.spawn(function()
		local props=Instance.new("Folder")
		props.Name="OptionalHeroProps"
		props.Parent=worldRoot
		load(props,"HeroBench",Config.Assets.Bench,Vector3.new(-395,1,-35))
		load(props,"HeroCar",Config.Assets.Car,Vector3.new(235,1,43))
		load(props,"HeroDumpster",Config.Assets.Dumpster,Vector3.new(345,1,-45))
		props:SetAttribute("Loaded",true)
	end)
end
return S
