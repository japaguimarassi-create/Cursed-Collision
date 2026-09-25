--!strict
local R=game:GetService("ReplicatedStorage")
local U=require(R.Shared.Util)
local Catalog=require(R.Shared.MapAssetCatalog)

local S={}
local function prop(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3,material:Enum.Material):Part
	local p=U.Part(parent,name,size,CFrame.new(pos),material,color,true)
	p.CanTouch=false
	p.CanQuery=false
	return p
end

local function dumpster(parent:Instance,pos:Vector3)
	prop(parent,"DumpsterBody",pos+Vector3.new(0,2,0),Vector3.new(6,4,3),Color3.fromRGB(55,61,70),Enum.Material.Metal)
	prop(parent,"DumpsterLid",pos+Vector3.new(0,4.2,0),Vector3.new(6.2,.35,3.2),Color3.fromRGB(40,45,52),Enum.Material.Metal)
end

local function planter(parent:Instance,pos:Vector3)
	prop(parent,"Planter",pos+Vector3.new(0,1,0),Vector3.new(4,2,4),Color3.fromRGB(76,80,88),Enum.Material.Concrete)
	local leaf=prop(parent,"PlanterLeaf",pos+Vector3.new(0,3,0),Vector3.new(3,3,3),Color3.fromRGB(57,112,73),Enum.Material.Grass)
	leaf.Shape=Enum.PartType.Ball
end

local function car(parent:Instance,pos:Vector3,rotation:number)
	local base=CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0)
	local body=U.Part(parent,"ParkedCarBody",Vector3.new(8,1.6,14),base*CFrame.new(0,1.3,0),Enum.Material.Metal,Color3.fromRGB(48,54,66),true)
	body.CanTouch=false;body.CanQuery=false
	local cabin=U.Part(parent,"ParkedCarCabin",Vector3.new(5.5,1.8,7),base*CFrame.new(0,2.9,.7),Enum.Material.Glass,Color3.fromRGB(73,112,139),true)
	cabin.CanTouch=false;cabin.CanQuery=false;cabin.Transparency=.18
end

local function buildChunk(parent:Instance,index:number)
	local x=index%2==0 and 1 or -1
	local z=index<=2 and 1 or -1
	local base=Vector3.new(x*(145+index*18),0,z*(145+index*14))
	local catalog=Catalog.GetByUse("street props")
	local reference=catalog[1]
	local folder=Instance.new("Folder")
	folder.Name="DetailChunk_"..index
	folder:SetAttribute("ReferenceAssetId",reference and reference.Id or 0)
	folder.Parent=parent
	for i=-1,1 do
		planter(folder,base+Vector3.new(i*24,0,18))
		if i~=0 then dumpster(folder,base+Vector3.new(i*34,0,-18))end
	end
	car(folder,base+Vector3.new(-24,0,-42),z>0 and 0 or 180)
	car(folder,base+Vector3.new(24,0,-42),z>0 and 180 or 0)
end

function S.Init()
	local root=workspace:FindFirstChild("CollisionBattlestarWorld")
	local environment=root and root:FindFirstChild("Environment")
	if not environment or not environment:IsA("Folder")then return end
	if environment:FindFirstChild("ProceduralDetails")then return end
	local details=Instance.new("Folder")
	details.Name="ProceduralDetails"
	details.Parent=environment
	task.spawn(function()
		for index=1,4 do
			if not details.Parent then return end
			buildChunk(details,index)
			task.wait()
		end
	end)
end

return S
