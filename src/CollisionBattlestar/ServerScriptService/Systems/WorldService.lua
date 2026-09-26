--!strict
local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)

local M={}
local world:Folder?
local spawns:{BasePart}={}

local function part(parent:Instance,name:string,size:Vector3,pos:Vector3,color:Color3,material:Enum.Material,collide:boolean,transparency:number?):Part
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.Position=pos;p.Anchored=true;p.CanCollide=collide;p.CanTouch=false;p.CanQuery=collide;p.CastShadow=collide
 p.Material=material;p.Color=color;p.Transparency=transparency or 0;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
 return p
end

local function breakable(parent:Instance,name:string,size:Vector3,pos:Vector3,color:Color3,hp:number):Part
 local p=part(parent,name,size,pos,color,Enum.Material.Concrete,true)
 p:SetAttribute("CBSDestructible",true);p:SetAttribute("HP",hp);p:SetAttribute("MaxHP",hp)
 CollectionService:AddTag(p,"CBS_Destructible")
 return p
end

local function lampSide(i:number):number
 return i%2==0 and 92 or -92
end

local function building(parent:Folder,nodeId:string,index:number,x:number,z:number,h:number,color:Color3,accent:Color3,interior:boolean)
 local model=Instance.new("Model");model.Name=nodeId.."_Building_"..index;model.Parent=parent
 local w=44+(index%3)*8
 local d=40+(index%2)*8
 local y=h/2
 breakable(model,"Back",Vector3.new(w,h,6),Vector3.new(x,y,z+d/2),color,70)
 breakable(model,"FrontLeft",Vector3.new(w*.38,h,6),Vector3.new(x-w*.31,y,z-d/2),color,60)
 breakable(model,"FrontRight",Vector3.new(w*.38,h,6),Vector3.new(x+w*.31,y,z-d/2),color,60)
 breakable(model,"DoorHeader",Vector3.new(w*.24,7,6),Vector3.new(x,y-5,z-d/2),color,40)
 part(model,"Floor",Vector3.new(w,d,1),Vector3.new(x,.5,z),Color3.fromRGB(54,59,69),Enum.Material.Concrete,true)
 part(model,"Roof",Vector3.new(w+3,2,d+3),Vector3.new(x,h+1,z),Color3.fromRGB(20,26,35),Enum.Material.Metal,true)
 if interior then
  part(model,"InteriorBench",Vector3.new(w-12,1,3),Vector3.new(x,4,z),Color3.fromRGB(69,77,88),Enum.Material.Metal,true)
  for col=1,3 do part(model,"InteriorLight_"..col,Vector3.new(8,.3,3),Vector3.new(x+(col-2)*12,18,z),accent,Enum.Material.Neon,false,.15) end
 end
 for i=1,5 do
  part(model,"Step_"..i,Vector3.new(10,2,4),Vector3.new(x-w/2-5+i*2,i*2-1,z-d/2-9),Color3.fromRGB(79,86,97),Enum.Material.Concrete,true)
 end
 for side=-1,1,2 do
  for col=1,3 do
   part(model,"Window_"..side.."_"..col,Vector3.new(7,5,.35),Vector3.new(x+(col-2)*(w/3.4),12,z+side*(d/2+.2)),accent,Enum.Material.Neon,false,.22)
  end
 end
end

local function district(parent:Folder,nodeId:string,index:number,node:any)
 local x=node.Position.X
 local folder=Instance.new("Folder");folder.Name=nodeId;folder.Parent=parent
 part(folder,"Ground",Vector3.new(Config.Map.DistrictWidth,2,Config.Map.Depth),Vector3.new(x,-1,0),Color3.fromRGB(41,46,57),Enum.Material.Asphalt,true)
 part(folder,"MainRoad",Vector3.new(Config.Map.DistrictWidth,2,Config.Map.RoadWidth),Vector3.new(x,1,0),Color3.fromRGB(22,27,34),Enum.Material.Asphalt,true)
 part(folder,"NorthWalk",Vector3.new(Config.Map.DistrictWidth,1,50),Vector3.new(x,2,58),Color3.fromRGB(63,68,76),Enum.Material.Concrete,true)
 part(folder,"SouthWalk",Vector3.new(Config.Map.DistrictWidth,1,50),Vector3.new(x,2,-58),Color3.fromRGB(63,68,76),Enum.Material.Concrete,true)
 for lane=-100,100,25 do part(folder,"Lane_"..lane,Vector3.new(13,.2,.8),Vector3.new(x+lane,2.1,0),Color3.fromRGB(196,201,207),Enum.Material.SmoothPlastic,false) end
 local buildingColor=Color3.fromRGB(50+index*4,56+index*4,67+index*3)
 for i=1,8 do
  local col=((i-1)%4)-1.5
  local row=i<=4 and 1 or -1
  local bx=x+col*52
  local bz=row*82
  local h=26+((i*index)%4)*8
  building(folder,nodeId,i,bx,bz,h,buildingColor,node.Color,index==3 and i<=4)
 end
 for i=1,4 do
  local side=i%2==0 and 1 or -1
  local z=side*38
  local bx=x+(i-2.5)*50
  breakable(folder,"Cover_"..i,Vector3.new(14,4,3),Vector3.new(bx,3,z+side*9),Color3.fromRGB(111,117,126),30)
 end
 for i=1,6 do
  local px=x+(i-3.5)*34
  local p=part(folder,"LampPole_"..i,Vector3.new(.7,16,.7),Vector3.new(px,8,lampSide(i)),Color3.fromRGB(38,43,50),Enum.Material.Metal,true)
  part(folder,"Lamp_"..i,Vector3.new(3,.5,3),p.Position+Vector3.new(0,8,0),node.Color,Enum.Material.Neon,false,.1)
 end
 if index==1 then
  part(folder,"FountainBase",Vector3.new(32,2,32),Vector3.new(x,3,0),Color3.fromRGB(84,90,101),Enum.Material.Concrete,true)
  part(folder,"FountainCore",Vector3.new(10,7,10),Vector3.new(x,7,0),node.Color,Enum.Material.Neon,false,.2)
 elseif index==2 then
  part(folder,"MetroRoof",Vector3.new(70,2,28),Vector3.new(x,20,0),Color3.fromRGB(31,36,47),Enum.Material.Metal,true)
 elseif index==3 then
  part(folder,"CoreRing",Vector3.new(78,2,78),Vector3.new(x,3,0),node.Color,Enum.Material.Neon,true,.55)
 elseif index==4 then
  for i=-2,2 do part(folder,"MarketCrate_"..i,Vector3.new(8,8,8),Vector3.new(x+i*18,4,-30),Color3.fromRGB(102,77,49),Enum.Material.WoodPlanks,true) end
 elseif index==5 then
  for i=1,5 do part(folder,"ApexPlatform_"..i,Vector3.new(22,2,18),Vector3.new(x+(i-3)*30,10+i*6,30),node.Color,Enum.Material.Metal,true,.18) end
 end
end

function M:Build()
 local old=workspace:FindFirstChild("CollisionBattlestarWorld")
 if old then old:Destroy() end
 world=Instance.new("Folder");world.Name="CollisionBattlestarWorld";world.Parent=workspace
 local map=Instance.new("Folder");map.Name="Map";map.Parent=world
 local spawnFolder=Instance.new("Folder");spawnFolder.Name="Spawns";spawnFolder.Parent=world
 table.clear(spawns)
 part(map,"WorldBase",Vector3.new(Config.Map.Width+80,2,Config.Map.Depth+40),Vector3.new(0,-3,0),Color3.fromRGB(16,21,29),Enum.Material.Slate,true)
 part(map,"NorthBarrier",Vector3.new(Config.Map.Width+80,24,3),Vector3.new(0,10,Config.Map.Depth/2+20),Color3.fromRGB(12,17,24),Enum.Material.Concrete,true)
 part(map,"SouthBarrier",Vector3.new(Config.Map.Width+80,24,3),Vector3.new(0,10,-Config.Map.Depth/2-20),Color3.fromRGB(12,17,24),Enum.Material.Concrete,true)
 for i,nodeId in ipairs(Routes.Order) do district(map,nodeId,i,Routes.Nodes[nodeId]) end
 for _,nodeId in ipairs(Routes.Order) do
  local x=Routes.Nodes[nodeId].Position.X
  for side=-1,1,2 do part(map,"Connector_"..nodeId.."_"..side,Vector3.new(Config.Map.Gap+30,2,Config.Map.RoadWidth),Vector3.new(x+side*(Config.Map.DistrictWidth/2+Config.Map.Gap/2),1,0),Color3.fromRGB(23,28,35),Enum.Material.Asphalt,true) end
 end
 for _,nodeId in ipairs(Routes.Order) do
  local p=part(spawnFolder,"Spawn_"..nodeId,Vector3.new(8,1,8),Routes.Nodes[nodeId].Position+Vector3.new(0,4,28),Routes.Nodes[nodeId].Color,Enum.Material.Neon,false,.55)
  table.insert(spawns,p)
 end
 local npcs=Instance.new("Folder")
 npcs.Name="NPCs"
 npcs.Parent=world
 createTrainingDummy(npcs)
 workspace:SetAttribute("CollisionBattlestarMapReady",true)
 workspace:SetAttribute("CollisionBattlestarWorldVersion",Routes.Version)
 workspace:SetAttribute("CollisionBattlestarWorldPartCount",#workspace:GetDescendants())
 workspace:SetAttribute("CollisionBattlestarReady",true)
end

function M:GetSpawn(id:string):BasePart?
 for _,p in ipairs(spawns) do if p.Name=="Spawn_"..id then return p end end
 return spawns[1]
end

function M:Teleport(player:Player,id:string):boolean
 local node=Routes.Get(id)
 if not node or not player.Character then return false end
 local root=player.Character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return false end
 pcall(function() player:RequestStreamAroundAsync(node.Position,3) end)
 player.Character:PivotTo(CFrame.lookAt(node.Position+Vector3.new(0,5,28),node.Position))
 player:SetAttribute("CurrentMapNode",id)
 return true
end
return M