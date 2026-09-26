--!strict
local R=game:GetService("ReplicatedStorage")
local U=require(R.Shared.Util)
local Routes=require(R.Shared.MapRouteDefinitions)
local Catalog=require(R.Shared.MapAssetCatalog)
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

local function findCatalogByName(name:string)
	for _,item in ipairs(Catalog.References)do
		if item.Name==name then return item end
	end
	return nil
end

local function loadProp(parent:Instance,catalogName:string,name:string,pos:Vector3,rotation:number):boolean
	local item=findCatalogByName(catalogName)
	if not item then return false end
	local ok,model=pcall(function()
		return Loader.Load(item.Id,parent,name,CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0))
	end)
	if not ok or not model then return false end
	model:SetAttribute("CollisionBattlestarAssetId",item.Id)
	model:SetAttribute("CollisionBattlestarAssetLicense",item.License)
	model:SetAttribute("CollisionBattlestarAssetBudget",item.Budget)
	return true
end

local function buildFallback(details:Folder)
	for index,id in ipairs(Routes.Order)do
		local node=Routes.Nodes[id]
		local p=node.Position
		for _,offset in ipairs({Vector3.new(-70,0,48),Vector3.new(70,0,48),Vector3.new(-70,0,-48)})do
			planter(details,p+offset)
		end
		car(details,p+Vector3.new(-34,0,30),(index%2==0)and 90 or -90)
		sign(details,p+Vector3.new(0,7,-42),node.Name,node.Color)
	end
end

local function buildApprovedAssets(root:Folder):number
	local loaded=0
	local origin=Routes.Nodes.Origin.Position
	local iron=Routes.Nodes.Iron.Position
	local core=Routes.Nodes.Core.Position
	local rift=Routes.Nodes.Rift.Position
	local apex=Routes.Nodes.Apex.Position

	local placements={
		{Catalog="Bus Stop [FREE!]",Name="HeroBusStop_Origin",Position=origin+Vector3.new(58,2,72),Rotation=180},
		{Catalog="Bus Stop Pole",Name="HeroBusPole_Core",Position=core+Vector3.new(58,0,-72),Rotation=90},
		{Catalog="Bus Stop Sign [FREE]",Name="HeroBusSign_Core",Position=core+Vector3.new(58,4,-72),Rotation=90},
		{Catalog="Bench",Name="HeroBench_Neon",Position=Routes.Nodes.Neon.Position+Vector3.new(-72,1,58),Rotation=0},
		{Catalog="Bench",Name="HeroBench_Sky",Position=Routes.Nodes.Sky.Position+Vector3.new(72,1,-58),Rotation=180},
		{Catalog="Dumpster -Free-",Name="HeroDumpster_Iron",Position=iron+Vector3.new(-80,2,-52),Rotation=20},
		{Catalog="Dumpster -Free-",Name="HeroDumpster_Rift",Position=rift+Vector3.new(-78,2,-48),Rotation=-20},
		{Catalog="[FREE] Car Showcase",Name="HeroCar_Origin",Position=origin+Vector3.new(-34,0,30),Rotation=90},
		{Catalog="[FREE] Car Showcase",Name="HeroCar_Apex",Position=apex+Vector3.new(34,0,30),Rotation=-90},
	}
	for _,slot in ipairs(placements)do
		if loadProp(root,slot.Catalog,slot.Name,slot.Position,slot.Rotation)then
			loaded+=1
		end
	end
	return loaded
end

function S.Init()
	local root=workspace:FindFirstChild("CollisionBattlestarWorld")
	local environment=root and root:FindFirstChild("Environment")
	if not environment or not environment:IsA("Folder")then return end
	if environment:FindFirstChild("ProceduralDetails")then return end

	local details=Instance.new("Folder")
	details.Name="ProceduralDetails"
	details:SetAttribute("Role","Fallback")
	details.Parent=environment
	buildFallback(details)

	local approved=Instance.new("Folder")
	approved.Name="ApprovedAssetProps"
	approved:SetAttribute("Role","OptionalExternalAssets")
	approved:SetAttribute("LoadPolicy","BestEffortWithProceduralFallback")
	approved.Parent=environment
	workspace:SetAttribute("CollisionBattlestarExternalAssetStatus","PENDING")

	task.spawn(function()
		local loaded=buildApprovedAssets(approved)
		workspace:SetAttribute("CollisionBattlestarExternalAssetLoaded",loaded)
		workspace:SetAttribute("CollisionBattlestarExternalAssetStatus",loaded>0 and"PARTIAL_OR_READY"or"FALLBACK_ONLY")
	end)
end

return S