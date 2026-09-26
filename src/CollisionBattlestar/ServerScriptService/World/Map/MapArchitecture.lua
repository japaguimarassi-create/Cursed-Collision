--!strict
local T=require(script.Parent.MapContext)
local Routes=require(game.ReplicatedStorage.Shared.MapRouteDefinitions)
local M={}
local function road(parent:Instance,name:string,pos:Vector3,size:Vector3,rotation:number)
	local cf=CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0)
	T.Part(parent,name,size,cf,Enum.Material.Asphalt,Color3.fromRGB(29,32,39),true,true,false)
	local lineSize=rotation%180==0 and Vector3.new(size.X,.08,1.1)or Vector3.new(1.1,.08,size.Z)
	T.Decor(parent,name.."_Line",lineSize,cf*CFrame.new(0,.54,0),Enum.Material.Neon,Color3.fromRGB(145,151,166)).Transparency=.38
end
local function sidewalk(parent:Instance,name:string,pos:Vector3,size:Vector3)T.Part(parent,name,size,CFrame.new(pos),Enum.Material.Concrete,Color3.fromRGB(92,96,106),true,true,false)end
local function lamp(parent:Instance,pos:Vector3,color:Color3)
	T.Part(parent,"LampPole",Vector3.new(.7,11,.7),CFrame.new(pos+Vector3.new(0,5.5,0)),Enum.Material.Metal,Color3.fromRGB(47,52,61),true,true,false)
	T.Part(parent,"LampArm",Vector3.new(4,.45,.45),CFrame.new(pos+Vector3.new(2,10,0)),Enum.Material.Metal,Color3.fromRGB(47,52,61),true,true,false)
	T.Decor(parent,"LampGlow",Vector3.new(1.3,.45,1.3),CFrame.new(pos+Vector3.new(3.4,9.7,0)),Enum.Material.Neon,color)
end
local function building(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3,accent:Color3,regionId:string)
	local body=T.Part(parent,name,size,CFrame.new(pos+Vector3.new(0,size.Y/2,0)),Enum.Material.Concrete,color,true,true,false)
	body:SetAttribute("RegionId",regionId);T.Tag(body,"EnvironmentStatic")
	local roof=T.Decor(parent,name.."_Roof",Vector3.new(size.X+2,1.4,size.Z+2),CFrame.new(pos+Vector3.new(0,size.Y+.7,0)),Enum.Material.Metal,Color3.fromRGB(40,44,53));T.Tag(roof,"LandmarkVisual")
	for floor=1,math.max(1,math.floor(size.Y/12))do T.Decor(parent,name.."_WindowBand_"..floor,Vector3.new(size.X*.72,.8,.45),CFrame.new(pos.X,pos.Y+floor*10,pos.Z-size.Z/2-.4),Enum.Material.Glass,accent)end
end
local function tower(parent:Instance,name:string,pos:Vector3,width:number,depth:number,height:number,accent:Color3,regionId:string)
	building(parent,name,pos,Vector3.new(width,height,depth),Color3.fromRGB(72,77,88),accent,regionId)
	for y=16,height-6,10 do T.Decor(parent,name.."_Band_"..y,Vector3.new(width+1,.5,depth+1),CFrame.new(pos+Vector3.new(0,y,0)),Enum.Material.Neon,accent)end
end
local function warehouse(parent:Instance,name:string,pos:Vector3,width:number,depth:number,height:number,accent:Color3,regionId:string)
	local body=T.Part(parent,name,Vector3.new(width,height,depth),CFrame.new(pos+Vector3.new(0,height/2,0)),Enum.Material.Metal,Color3.fromRGB(69,72,80),true,true,false)
	body:SetAttribute("RegionId",regionId);T.Tag(body,"EnvironmentStatic")
	for x=-width/2+8,width/2-7,16 do T.Decor(parent,name.."_Panel_"..x,Vector3.new(2,height*.7,.5),CFrame.new(pos+Vector3.new(x,height*.56,-depth/2-.5)),Enum.Material.Neon,accent)end
	T.Destructible(parent,name.."_Door",pos+Vector3.new(0,height*.31,-depth/2-.5),Vector3.new(math.min(18,width*.42),height*.62,.6),Color3.fromRGB(34,38,46))
end
local function canopy(parent:Instance,name:string,pos:Vector3,color:Color3)
	T.Part(parent,name.."_Top",Vector3.new(22,1.2,18),CFrame.new(pos+Vector3.new(0,8,0)),Enum.Material.Metal,color,true,true,false)
	for _,x in ipairs({-9,9})do for _,z in ipairs({-7,7})do T.Part(parent,name.."_Post",Vector3.new(.7,8,.7),CFrame.new(pos+Vector3.new(x,4,z)),Enum.Material.Metal,Color3.fromRGB(44,49,58),true,true,false)end end
end
local function cover(parent:Instance,pos:Vector3,color:Color3)T.Destructible(parent,"Cover",pos+Vector3.new(0,2,0),Vector3.new(7,4,3),color)end
function M.BuildRoads(parent:Instance)
	road(parent,"MainSpine",Vector3.new(0,0,0),Vector3.new(1700,1,40),0)
	road(parent,"SouthCombatLane",Vector3.new(0,0,105),Vector3.new(1700,1,22),0)
	road(parent,"NorthCombatLane",Vector3.new(0,0,-105),Vector3.new(1700,1,22),0)
	for x=-720,720,120 do road(parent,"CrossStreet",Vector3.new(x,0,0),Vector3.new(18,1,240),90)end
	for x=-720,720,80 do sidewalk(parent,"SidewalkA",Vector3.new(x,0,25),Vector3.new(58,1,14));sidewalk(parent,"SidewalkB",Vector3.new(x,0,-25),Vector3.new(58,1,14));lamp(parent,Vector3.new(x,0,31),Color3.fromRGB(92,198,255))end
end
function M.BuildZoneShell(parent:Instance,node:any)
	local p=node.Position
	T.Part(parent,node.Id.."_Floor",Vector3.new(220,2,210),CFrame.new(p.X,-1,p.Z),Enum.Material.Concrete,Color3.fromRGB(63,67,77),true,true,false)
	T.Decor(parent,node.Id.."_Ring",Vector3.new(130,.4,130),CFrame.new(p.X,.2,p.Z),Enum.Material.Neon,node.Color)
	local center=T.Part(parent,node.Id.."_CombatFloor",Vector3.new(140,.8,110),CFrame.new(p.X,.75,p.Z),Enum.Material.Slate,Color3.fromRGB(48,52,62),true,true,false);center:SetAttribute("RegionId",node.Id)
	for angle=0,315,45 do local a=math.rad(angle);cover(parent,p+Vector3.new(math.cos(a)*78,2,math.sin(a)*66),node.Color)end
end
function M.BuildLandmark(parent:Instance,id:string)
	local node=Routes.Nodes[id];local p=node.Position
	if id=="Origin" then tower(parent,"OriginGate",p+Vector3.new(-72,0,-70),26,26,44,node.Color,id);canopy(parent,"OriginTraining",p+Vector3.new(55,0,52),node.Color)
	elseif id=="Neon" then tower(parent,"NeonTower",p+Vector3.new(74,0,-62),34,34,76,node.Color,id);building(parent,"NeonArcade",p+Vector3.new(-62,0,60),Vector3.new(50,26,42),Color3.fromRGB(69,65,82),node.Color,id)
	elseif id=="Iron" then warehouse(parent,"IronWarehouse",p+Vector3.new(-62,0,-58),72,48,28,node.Color,id);for x=-48,48,24 do canopy(parent,"Market",p+Vector3.new(x,0,56),node.Color)end
	elseif id=="Core" then tower(parent,"CoreSpire",p+Vector3.new(0,0,-68),42,42,98,node.Color,id);local core=T.Decor(parent,"CollisionPillar",Vector3.new(18,24,18),CFrame.new(p+Vector3.new(0,12,0)),Enum.Material.Neon,node.Color);core.Shape=Enum.PartType.Ball;T.Tag(core,"CollisionResponsive")
	elseif id=="Sky" then tower(parent,"SkyTower",p+Vector3.new(65,0,65),30,30,90,node.Color,id);T.Part(parent,"SkyDeck",Vector3.new(150,2,18),CFrame.new(p+Vector3.new(0,42,0)),Enum.Material.Metal,Color3.fromRGB(36,41,51),true,true,false);T.Decor(parent,"SkyRail",Vector3.new(150,2.4,.5),CFrame.new(p+Vector3.new(0,44,-8)),Enum.Material.Glass,node.Color)
	elseif id=="Rift" then warehouse(parent,"RiftFactory",p+Vector3.new(-58,0,55),76,52,30,node.Color,id);local crater=T.Decor(parent,"RiftCore",Vector3.new(32,4,32),CFrame.new(p+Vector3.new(15,2,-34)),Enum.Material.Neon,node.Color);crater.Shape=Enum.PartType.Cylinder;T.Tag(crater,"CollisionResponsive")
	else warehouse(parent,"ApexArena",p+Vector3.new(0,0,-66),94,58,20,node.Color,id);local ring=T.Decor(parent,"ApexRing",Vector3.new(90,.6,90),CFrame.new(p+Vector3.new(0,2,34)),Enum.Material.Neon,node.Color);ring.Shape=Enum.PartType.Cylinder;T.Tag(ring,"BattleStreakArenaVisual")
	end
end
return M
