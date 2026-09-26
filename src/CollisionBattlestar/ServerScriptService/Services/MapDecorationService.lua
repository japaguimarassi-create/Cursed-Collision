--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local U=require(ReplicatedStorage.Shared.Util)
local Routes=require(ReplicatedStorage.Shared.MapRouteDefinitions)
local Catalog=require(ReplicatedStorage.Shared.MapAssetCatalog)
local Loader=require(script.Parent.MapAssetLoader)

local S={}

local function prop(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3,material:Enum.Material):Part
	local p=U.Part(parent,name,size,CFrame.new(pos),material,color,true)
	p.CanTouch=false
	p.CanQuery=false
	return p
end

local function car(parent:Instance,pos:Vector3,rotation:number)
	local cf=CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0)
	local body=prop(parent,"ParkedCarBody",pos+Vector3.new(0,1.2,0),Vector3.new(8,1.6,14),Color3.fromRGB(48,54,66),Enum.Material.Metal)
	body.CFrame=cf*CFrame.new(0,1.2,0)
	local cabin=prop(parent,"ParkedCarCabin",pos+Vector3.new(0,2.9,.7),Vector3.new(5.5,1.8,7),Color3.fromRGB(73,112,139),Enum.Material.Glass)
	cabin.CFrame=cf*CFrame.new(0,2.9,.7)
	cabin.Transparency=.18
end

local function planter(parent:Instance,pos:Vector3)
	prop(parent,"Planter",pos+Vector3.new(0,1,0),Vector3.new(4,2,4),Color3.fromRGB(76,80,88),Enum.Material.Concrete)
	local leaf=prop(parent,"PlanterLeaf",pos+Vector3.new(0,3,0),Vector3.new(3,3,3),Color3.fromRGB(57,112,73),Enum.Material.Grass)
	leaf.Shape=Enum.PartType.Ball
end

local function sign(parent:Instance,pos:Vector3,text:string,color:Color3)
	local part=prop(parent,"RouteSign",pos,Vector3.new(14,4,.5),color,Enum.Material.Neon)
	local gui=Instance.new("BillboardGui")
	gui.Size=UDim2.fromOffset(180,42)
	gui.StudsOffset=Vector3.new(0,2.8,0)
	gui.AlwaysOnTop=true
	gui.Parent=part
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Font=Enum.Font.GothamBold
	label.TextScaled=true
	label.TextColor3=Color3.fromRGB(245,247,252)
	label.TextStrokeTransparency=.45
	label.Text=text
	label.Parent=gui
end

local function runtimeAsset(id:number,parent:Instance,name:string,pos:Vector3,rotation:number)
	task.spawn(function()
		if not parent.Parent then return end
		local model=Loader.Load(id,parent,name,CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0))
		if model then
			model:SetAttribute("CollisionBattlestarExternalAsset",true)
			model:SetAttribute("ApprovedByCatalog",true)
		end
	end)
end

function S.Init()
	local root=workspace:FindFirstChild("CollisionBattlestarWorld")
	local environment=root and root:FindFirstChild("Environment")
	if not environment or not environment:IsA("Folder")then return end
	if environment:FindFirstChild("ProceduralDetails")then return end
	local details=Instance.new("Folder")
	details.Name="ProceduralDetails"
	details.Parent=environment

	local bench=Catalog.GetById(Catalog.Runtime.Bench)
	local dumpster=Catalog.GetById(Catalog.Runtime.Dumpster)
	local blockyCar=Catalog.GetById(Catalog.Runtime.Car)

	for index,id in ipairs(Routes.Order)do
		local node=Routes.Nodes[id]
		local p=node.Position
		for _,offset in ipairs({Vector3.new(-70,0,48),Vector3.new(70,0,48),Vector3.new(-70,0,-48)})do planter(details,p+offset)end
		car(details,p+Vector3.new(-34,0,30),(index%2==0)and 90 or -90)
		sign(details,p+Vector3.new(0,7,-42),node.Name,node.Color)

		if bench and bench.RuntimeApproved then
			runtimeAsset(bench.Id,details,"RuntimeBench_"..id,p+Vector3.new(48,0,34),index%2==0 and 90 or -90)
		end
		if dumpster and dumpster.RuntimeApproved then
			runtimeAsset(dumpster.Id,details,"RuntimeDumpster_"..id,p+Vector3.new(-50,0,-34),0)
		end
		if blockyCar and blockyCar.RuntimeApproved and (index%2==1) then
			runtimeAsset(blockyCar.Id,details,"RuntimeCar_"..id,p+Vector3.new(34,0,30),index%2==0 and 90 or -90)
		end
	end
end

return S
