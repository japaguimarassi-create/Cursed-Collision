--!strict
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local U=require(ReplicatedStorage.Shared.Util)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)

local S={}
local root:Folder?

local function part(parent:Instance,name:string,size:Vector3,pos:Vector3,material:Enum.Material,color:Color3,collide:boolean?)
	local p=U.Part(parent,name,size,CFrame.new(pos),material,color,true)
	p.CanCollide=collide~=false
	p.CanTouch=false
	p.CanQuery=collide~=false
	return p
end

local function zone(parent:Instance,node:any)
	local x=node.Position.X
	part(parent,node.Id.."_Floor",Vector3.new(300,2,250),Vector3.new(x,-1,0),Enum.Material.Concrete,Color3.fromRGB(58,62,70))
	part(parent,node.Id.."_Arena",Vector3.new(220,1,150),Vector3.new(x,.5,0),Enum.Material.Slate,Color3.fromRGB(42,46,54))
	for _,z in ipairs({-92,92}) do
		part(parent,node.Id.."_Wall_"..z,Vector3.new(220,14,3),Vector3.new(x,7,z),Enum.Material.Concrete,Color3.fromRGB(73,78,88))
	end
	for _,dx in ipairs({-95,95}) do
		part(parent,node.Id.."_Cover_"..dx,Vector3.new(9,5,18),Vector3.new(x+dx,2.5,0),Enum.Material.Concrete,Color3.fromRGB(67,72,82))
	end
end

local function building(parent:Instance,name:string,pos:Vector3,size:Vector3)
	local body=part(parent,name,size,Vector3.new(pos.X,pos.Y+size.Y/2,pos.Z),Enum.Material.Concrete,Color3.fromRGB(70,75,84))
	part(parent,name.."_Roof",Vector3.new(size.X+2,1,size.Z+2),Vector3.new(pos.X,pos.Y+size.Y+.5,pos.Z),Enum.Material.Metal,Color3.fromRGB(38,42,49),false)
	part(parent,name.."_Accent",Vector3.new(size.X*.65,.6,.6),Vector3.new(pos.X,pos.Y+size.Y*.52,pos.Z-size.Z/2-.4),Enum.Material.Neon,Color3.fromRGB(92,198,255),false)
	body:SetAttribute("StaticEnvironment",true)
end

local function connector(parent:Instance,x:number)
	part(parent,"Connector_"..x,Vector3.new(120,1,54),Vector3.new(x,0,0),Enum.Material.Asphalt,Color3.fromRGB(34,37,43))
end

local function spawn(parent:Instance,index:number,pos:Vector3)
	local s=Instance.new("SpawnLocation")
	s.Name="CollisionSpawn_"..index
	s.Size=Vector3.new(10,1,10)
	s.CFrame=CFrame.new(pos)
	s.Anchored=true
	s.CanCollide=true
	s.CanTouch=false
	s.CanQuery=false
	s.Transparency=1
	s.Neutral=true
	s.Duration=0
	s.Parent=parent
end

local function lighting()
	Lighting.ClockTime=18
	Lighting.Brightness=2
	Lighting.GlobalShadows=true
	Lighting.EnvironmentDiffuseScale=.55
	Lighting.EnvironmentSpecularScale=.45
end

function S.Init()
	if root then return end
	local old=workspace:FindFirstChild("CollisionBattlestarWorld")
	if old then old:Destroy() end

	root=Instance.new("Folder")
	root.Name="CollisionBattlestarWorld"
	root.Parent=workspace

	local map=Instance.new("Folder")
	map.Name="Map"
	map.Parent=root

	local spawns=Instance.new("Folder")
	spawns.Name="Spawns"
	spawns.Parent=root

	part(map,"WorldGround",Vector3.new(1040,2,340),Vector3.new(0,-2,0),Enum.Material.Grass,Color3.fromRGB(44,49,47))
	part(map,"MainRoad",Vector3.new(980,1,58),Vector3.new(0,0,0),Enum.Material.Asphalt,Color3.fromRGB(31,34,40))
	for _,x in ipairs({-270,270}) do connector(map,x) end

	for _,id in ipairs(Routes.Order) do
		local node=Routes.Nodes[id]
		zone(map,node)
	end

	building(map,"OriginHall",Vector3.new(-450,0,-58),Vector3.new(70,34,48))
	building(map,"OriginBlock",Vector3.new(-350,0,58),Vector3.new(62,28,42))
	building(map,"CoreTower",Vector3.new(-82,0,-60),Vector3.new(48,64,44))
	building(map,"CoreBlock",Vector3.new(82,0,60),Vector3.new(54,36,46))
	building(map,"ApexHall",Vector3.new(350,0,-58),Vector3.new(64,40,46))
	building(map,"ApexBlock",Vector3.new(450,0,58),Vector3.new(68,30,44))

	for index,id in ipairs(Routes.Order) do
		spawn(spawns,index,Routes.Nodes[id].Spawn)
	end

	root:SetAttribute("MapVersion",Routes.Version)
	root:SetAttribute("MapLoaded",true)
	workspace:SetAttribute("CollisionBattlestarMapReady",true)
	workspace:SetAttribute("CollisionBattlestarMapError","")
	lighting()
end

function S.GetRoot():Folder?
	return root
end

return S
