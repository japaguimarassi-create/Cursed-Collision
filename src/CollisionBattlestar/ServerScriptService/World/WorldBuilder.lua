--!strict
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local U=require(ReplicatedStorage.Shared.Util)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Config=require(ReplicatedStorage.Shared.Config)
local AssetLoader=require(script.Parent.MapAssetLoader)
local S={}
local root:Folder?
local rng=Random.new(260926)

local function makePart(parent:Instance,name:string,size:Vector3,pos:Vector3,material:Enum.Material,color:Color3,collide:boolean?,transparency:number?)
	local p=U.Part(parent,name,size,CFrame.new(pos),material,color,true)
	p.CanCollide=collide~=false
	p.CanTouch=false
	p.CanQuery=collide~=false
	p.Transparency=transparency or 0
	return p
end

local function neon(parent:Instance,name:string,size:Vector3,pos:Vector3,color:Color3)
	return makePart(parent,name,size,pos,Enum.Material.Neon,color,false,.05)
end

local function road(parent:Instance,name:string,size:Vector3,pos:Vector3)
	return makePart(parent,name,size,pos,Enum.Material.Asphalt,Color3.fromRGB(25,28,34),true)
end

local function laneMark(parent:Instance,name:string,size:Vector3,pos:Vector3)
	return makePart(parent,name,size,pos,Enum.Material.SmoothPlastic,Color3.fromRGB(214,219,225),false,.05)
end

local function curb(parent:Instance,name:string,size:Vector3,pos:Vector3)
	return makePart(parent,name,size,pos,Enum.Material.Concrete,Color3.fromRGB(105,110,119),true)
end

local function tree(parent:Instance,pos:Vector3,index:number)
	makePart(parent,"TreeTrunk_"..index,Vector3.new(2.1,8,2.1),pos+Vector3.new(0,4,0),Enum.Material.Wood,Color3.fromRGB(93,62,43),true)
	local crown=Instance.new("Part")
	crown.Name="TreeCrown_"..index
	crown.Shape=Enum.PartType.Ball
	crown.Size=Vector3.new(13,11,13)
	crown.CFrame=CFrame.new(pos+Vector3.new(0,10,0))
	crown.Anchored=true
	crown.CanCollide=false
	crown.CanTouch=false
	crown.CanQuery=false
	crown.Material=Enum.Material.Grass
	crown.Color=Color3.fromRGB(33,112,71)
	crown.Parent=parent
end

local function streetLight(parent:Instance,pos:Vector3,index:number)
	makePart(parent,"LampPole_"..index,Vector3.new(1,12,1),pos+Vector3.new(0,6,0),Enum.Material.Metal,Color3.fromRGB(53,58,66),true)
	neon(parent,"Lamp_"..index,Vector3.new(2.6,.35,2.6),pos+Vector3.new(0,12,0),Color3.fromRGB(216,230,255))
end

local function building(parent:Instance,name:string,pos:Vector3,size:Vector3,accent:Color3,style:number)
	makePart(parent,name,size,Vector3.new(pos.X,pos.Y+size.Y/2,pos.Z),Enum.Material.Concrete,Color3.fromRGB(54+style*5,59+style*4,68+style*3),true)
	makePart(parent,name.."_Roof",Vector3.new(size.X+2,1.2,size.Z+2),Vector3.new(pos.X,pos.Y+size.Y+.6,pos.Z),Enum.Material.Metal,Color3.fromRGB(30,33,39),true)
	neon(parent,name.."_Band",Vector3.new(math.max(8,size.X*.64),.7,.55),Vector3.new(pos.X,pos.Y+size.Y*.58,pos.Z-size.Z/2-.45),accent)
	local levels=math.max(2,math.floor(size.Y/12))
	local windowsPerSide=math.clamp(math.floor(size.X/11),3,6)
	for level=1,levels do
		local y=pos.Y+5+(level-1)*11
		for column=1,windowsPerSide do
			local x=pos.X-size.X/2+6+(column-1)*(size.X-12)/math.max(1,windowsPerSide-1)
			local lit=rng:NextNumber()<.42
			local wc=lit and accent or Color3.fromRGB(56,77,93)
			neon(parent,name.."_W_F_"..level.."_"..column,Vector3.new(4.2,3.2,.18),Vector3.new(x,y,pos.Z-size.Z/2-.18),wc)
			if level<levels and style%2==0 then
				neon(parent,name.."_W_B_"..level.."_"..column,Vector3.new(4.2,3.2,.18),Vector3.new(x,y,pos.Z+size.Z/2+.18),wc)
			end
		end
	end
	if size.Y>=46 then
		makePart(parent,name.."_RoofAccess",Vector3.new(12,5,10),Vector3.new(pos.X,pos.Y+size.Y+3,pos.Z),Enum.Material.Concrete,Color3.fromRGB(44,47,54),true)
	end
end

local function shop(parent:Instance,name:string,pos:Vector3,accent:Color3)
	makePart(parent,name,Vector3.new(34,17,24),Vector3.new(pos.X,8.5,pos.Z),Enum.Material.Concrete,Color3.fromRGB(65,70,79),true)
	neon(parent,name.."_Sign",Vector3.new(25,3,.35),Vector3.new(pos.X,14,pos.Z-12.3),accent)
	makePart(parent,name.."_Door",Vector3.new(7,10,.25),Vector3.new(pos.X,5,pos.Z-12.45),Enum.Material.Glass,Color3.fromRGB(25,35,45),false,.12)
	for x=-9,9,18 do
		neon(parent,name.."_Window"..x,Vector3.new(7,5,.2),Vector3.new(pos.X+x,8,pos.Z-12.5),Color3.fromRGB(65,110,135))
	end
end

local function crosswalk(parent:Instance,x:number,z:number,vertical:boolean,index:number)
	for i=1,7 do
		local offset=(i-4)*4.2
		if vertical then
			laneMark(parent,"Crosswalk_"..index.."_"..i,Vector3.new(3.1,.12,26),Vector3.new(x+offset,.58,z))
		else
			laneMark(parent,"Crosswalk_"..index.."_"..i,Vector3.new(26,.12,3.1),Vector3.new(x,.58,z+offset))
		end
	end
end

local function plaza(parent:Instance,pos:Vector3,node:any)
	makePart(parent,node.Id.."_Plaza",Vector3.new(150,1,118),Vector3.new(pos.X,.52,pos.Z),Enum.Material.Slate,Color3.fromRGB(39,44,52),true)
	neon(parent,node.Id.."_Beacon",Vector3.new(14,1,14),Vector3.new(pos.X,1.1,pos.Z),node.Color)
	for i=1,4 do streetLight(parent,pos+Vector3.new((i-2.5)*42,0,-48),100+i) end
	makePart(parent,node.Id.."_Anchor",Vector3.new(36,4,4),Vector3.new(pos.X,4,pos.Z-45),Enum.Material.Metal,Color3.fromRGB(24,27,32),true)
	neon(parent,node.Id.."_RouteGlow",Vector3.new(24,.35,.35),Vector3.new(pos.X,6.2,pos.Z-45),node.Color)
end

local function buildDistrict(parent:Instance,node:any,index:number)
	plaza(parent,node.Position,node)
	local baseX=node.Position.X
	for sideIndex=-1,1,2 do
		for column=-1,1 do
			local z=sideIndex*165
			local x=baseX+column*66
			local h=rng:NextInteger(24,58)
			if math.abs(column)==1 or index%2==0 then
				building(parent,node.Id.."_Block_"..sideIndex.."_"..column.."_"..index,Vector3.new(x,0,z),Vector3.new(rng:NextInteger(38,56),h,rng:NextInteger(34,48)),node.Color,index+column+2)
			end
		end
	end
	shop(parent,node.Id.."_Shop",Vector3.new(baseX+66,0,95),node.Color)
	shop(parent,node.Id.."_Cafe",Vector3.new(baseX-66,0,-95),Color3.fromRGB(244,169,91))
	for i=1,4 do
		tree(parent,Vector3.new(baseX+(i-2.5)*38,0,125),index*10+i)
		tree(parent,Vector3.new(baseX+(i-2.5)*38,0,-125),index*20+i)
	end
end

local function buildRoadNetwork(parent:Instance)
	road(parent,"MainRoad",Vector3.new(Config.Map.Width,1.2,Config.Map.RoadWidth),Vector3.new(0,0,0))
	road(parent,"NorthRoad",Vector3.new(Config.Map.Width,1.2,44),Vector3.new(0,0,185))
	road(parent,"SouthRoad",Vector3.new(Config.Map.Width,1.2,44),Vector3.new(0,0,-185))
	for x=-520,390,130 do
		curb(parent,"CurbN_"..x,Vector3.new(120,1.4,3),Vector3.new(x,1,-34))
		curb(parent,"CurbS_"..x,Vector3.new(120,1.4,3),Vector3.new(x,1,34))
		for dash=1,5 do
			laneMark(parent,"Lane_"..x.."_"..dash,Vector3.new(18,.12,1.2),Vector3.new(x-48+(dash-1)*24,.66,0))
		end
	end
	crosswalk(parent,-260,0,false,1)
	crosswalk(parent,0,0,false,2)
	crosswalk(parent,270,0,false,3)
	for x=-390,390,130 do
		streetLight(parent,Vector3.new(x,0,42),300+x)
		streetLight(parent,Vector3.new(x,0,-42),400+x)
	end
end

local function lighting()
	Lighting.ClockTime=17.8
	Lighting.Brightness=2.1
	Lighting.GlobalShadows=true
	Lighting.EnvironmentDiffuseScale=.6
	Lighting.EnvironmentSpecularScale=.55
	Lighting.Ambient=Color3.fromRGB(54,61,78)
	Lighting.OutdoorAmbient=Color3.fromRGB(61,70,84)
end

local function build():Folder
	local old=workspace:FindFirstChild("CollisionBattlestarWorld")
	if old then old:Destroy() end
	local newRoot=Instance.new("Folder")
	newRoot.Name="CollisionBattlestarWorld"
	newRoot.Parent=workspace
	local map=Instance.new("Folder")
	map.Name="Map"
	map.Parent=newRoot
	local spawns=Instance.new("Folder")
	spawns.Name="Spawns"
	spawns.Parent=newRoot

	makePart(map,"WorldGround",Vector3.new(Config.Map.Width,2,Config.Map.Depth),Vector3.new(0,-2,0),Enum.Material.Grass,Color3.fromRGB(37,42,42),true)
	buildRoadNetwork(map)
	for _,id in ipairs(Routes.Order) do
		local node=Routes.Nodes[id]
		if not node then error("Missing route node: "..id) end
		buildDistrict(map,node,table.find(Routes.Order,id) or 1)
	end
	makePart(map,"RiverWallNorth",Vector3.new(1320,10,8),Vector3.new(0,5,370),Enum.Material.Brick,Color3.fromRGB(45,50,58),true)
	makePart(map,"RiverWallSouth",Vector3.new(1320,10,8),Vector3.new(0,5,-370),Enum.Material.Brick,Color3.fromRGB(45,50,58),true)

	for index,id in ipairs(Routes.Order) do
		local node=Routes.Nodes[id]
		local spawn=Instance.new("SpawnLocation")
		spawn.Name="BattleSpawn_"..index
		spawn.Size=Vector3.new(9,1,9)
		spawn.CFrame=CFrame.new(node.Spawn)
		spawn.Anchored=true
		spawn.Neutral=true
		spawn.Duration=0
		spawn.Transparency=1
		spawn.CanCollide=true
		spawn.CanTouch=false
		spawn.CanQuery=false
		spawn.Parent=spawns
	end

	newRoot:SetAttribute("MapVersion",Routes.Version)
	newRoot:SetAttribute("MapLoaded",true)
	lighting()
	return newRoot
end

local function verify(newRoot:Folder):boolean
	local map=newRoot:FindFirstChild("Map")
	local spawns=newRoot:FindFirstChild("Spawns")
	if not map or not spawns then return false end
	local count=0
	for _,id in ipairs(Routes.Order) do
		if map:FindFirstChild(id.."_Plaza") then count+=1 end
	end
	local spawnCount=0
	for _,item in ipairs(spawns:GetChildren()) do
		if item:IsA("SpawnLocation") then spawnCount+=1 end
	end
	return count==#Routes.Order and spawnCount==#Routes.Order and map:FindFirstChild("WorldGround")~=nil
end

function S.Init()
	if root and root.Parent and verify(root) then return true end
	return S.Rebuild()
end

function S.Rebuild():boolean
	workspace:SetAttribute("CollisionBattlestarMapReady",false)
	workspace:SetAttribute("CollisionBattlestarMapError","building")
	root=nil
	local ok,result=pcall(build)
	if not ok or not result or not verify(result) then
		if result and result:IsA("Folder") then result:Destroy() end
		workspace:SetAttribute("CollisionBattlestarMapError",tostring(result or "map verification failed"))
		return false
	end
	root=result
	workspace:SetAttribute("CollisionBattlestarMapError","")
	workspace:SetAttribute("CollisionBattlestarMapReady",true)
	workspace:SetAttribute("CollisionBattlestarMapVersion",Routes.Version)
	AssetLoader.Init(root)
	return true
end

function S.Verify():boolean
	return root~=nil and root.Parent==workspace and verify(root)
end

function S.GetRoot():Folder? return root end
return S
