--!strict
local CollectionService=game:GetService("CollectionService")
local R=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local C=require(R.Shared.Config)
local U=require(R.Shared.Util)
local Data=require(script.Parent.Parent.Services.PlayerDataService)

local S={}
local root:Folder?
local environment:Folder?
local gameplay:Folder?
local landmarks:Folder?
local regionVolumes:Folder?
local spawns:{Vector3}={}
local breakParts:{BasePart}={}
local bossArena=Vector3.new(0,2,-312)
local eventAnchor=Vector3.new(0,6,-286)
local secretFound:{[Player]:boolean}={}

local PALETTE={
	Street=Color3.fromRGB(31,34,42),
	Sidewalk=Color3.fromRGB(94,98,108),
	Concrete=Color3.fromRGB(88,92,102),
	Glass=Color3.fromRGB(61,111,142),
	Metal=Color3.fromRGB(55,62,74),
	DarkMetal=Color3.fromRGB(32,37,48),
	Neon=Color3.fromRGB(92,198,255),
	Purple=Color3.fromRGB(178,92,255),
	Industrial=Color3.fromRGB(112,78,60),
	Park=Color3.fromRGB(56,104,69),
	Canal=Color3.fromRGB(49,104,128),
	Rift=Color3.fromRGB(175,76,255),
	Warning=Color3.fromRGB(255,104,83),
}

local function folder(name:string):Folder
	local f=Instance.new("Folder")
	f.Name=name
	f.Parent=root
	return f
end

local function part(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3,collide:boolean?,query:boolean?):Part
	local p=U.Part(parent,name,size,cf,material,color,true)
	p.CanCollide=collide~=false
	p.CanTouch=false
	p.CanQuery=query~=false
	return p
end

local function tag(p:Instance,name:string)
	CollectionService:AddTag(p,name)
end

local function marker(parent:Instance,name:string,pos:Vector3,size:Vector3,regionId:string):BasePart
	local p=part(parent,name,size,CFrame.new(pos),Enum.Material.ForceField,Color3.new(1,1,1),false,false)
	p.Transparency=1
	p:SetAttribute("RegionId",regionId)
	return p
end

local function region(id:string,center:Vector3,size:Vector3)
	local p=marker(regionVolumes,id,center,size,id)
	p:SetAttribute("CollisionState","Stable")
	p:SetAttribute("StateSource","GlobalFractureDistrict")
end

local function neonStrip(parent:Instance,name:string,pos:Vector3,size:Vector3,rotation:number,color:Color3)
	local p=part(parent,name,size,CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Neon,color,false,false)
	p.CanTouch=false
	return p
end

local function streetSegment(parent:Instance,name:string,pos:Vector3,size:Vector3,rotation:number)
	local road=part(parent,name,size,CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Asphalt,PALETTE.Street,true,true)
	local lineSize=rotation%180==0 and Vector3.new(size.X,.08,1.2) or Vector3.new(1.2,.08,size.Z)
	local line=part(parent,name.."_Center",lineSize,CFrame.new(pos+Vector3.new(0,.54,0))*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Neon,Color3.fromRGB(170,180,195),false,false)
	line.Transparency=.35
	return road
end

local function sidewalk(parent:Instance,name:string,pos:Vector3,size:Vector3)
	return part(parent,name,size,CFrame.new(pos),Enum.Material.Concrete,PALETTE.Sidewalk,true,true)
end

local function streetLight(parent:Instance,pos:Vector3,rotation:number)
	local pole=part(parent,"StreetLight",Vector3.new(.8,12,.8),CFrame.new(pos+Vector3.new(0,6,0)),Enum.Material.Metal,PALETTE.Metal,true,true)
	part(parent,"StreetLightArm",Vector3.new(4,.5,.5),CFrame.new(pos+Vector3.new(rotation*2,11,0)),Enum.Material.Metal,PALETTE.Metal,true,true)
	local lamp=part(parent,"StreetLightGlow",Vector3.new(1.4,.5,1.4),CFrame.new(pos+Vector3.new(rotation*3.3,10.8,0)),Enum.Material.Neon,PALETTE.Neon,false,false)
	lamp.CanTouch=false
end

local function windowStrip(parent:Instance,name:string,pos:Vector3,size:Vector3,vertical:boolean,color:Color3)
	local w=part(parent,name,size,CFrame.new(pos),Enum.Material.Glass,color,false,false)
	w.Transparency=.12
	if vertical then
		w.Size=Vector3.new(.5,size.Y,size.Z)
	else
		w.Size=Vector3.new(size.X,.5,size.Z)
	end
	return w
end

local function simpleBuilding(parent:Instance,name:string,base:Vector3,width:number,depth:number,height:number,color:Color3,accent:Color3,regionId:string)
	local body=part(parent,name,Vector3.new(width,height,depth),CFrame.new(base+Vector3.new(0,height/2,0)),Enum.Material.Concrete,color,true,true)
	body:SetAttribute("RegionId",regionId)
	local roof=part(parent,name.."_Roof",Vector3.new(width+2,1.5,depth+2),CFrame.new(base+Vector3.new(0,height+.75,0)),Enum.Material.Metal,PALETTE.DarkMetal,true,true)
	tag(body,"EnvironmentStatic")
	local strips=math.max(2,math.floor(width/11))
	for i=1,strips do
		local x=(-width/2)+(i*(width/(strips+1)))
		local w=windowStrip(parent,name.."_Glass_"..i,base+Vector3.new(x,height*.56,-depth/2-.28),Vector3.new(2,height*.50,.4),false,accent)
		w.Parent=parent
	end
	local crown=part(parent,name.."_Crown",Vector3.new(math.max(5,width*.55),2,math.max(5,depth*.55)),CFrame.new(base+Vector3.new(0,height+2,0)),Enum.Material.Neon,accent,false,false)
	crown.CanTouch=false
end

local function tower(parent:Instance,name:string,base:Vector3,width:number,depth:number,height:number,accent:Color3,regionId:string)
	local body=part(parent,name,Vector3.new(width,height,depth),CFrame.new(base+Vector3.new(0,height/2,0)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	body:SetAttribute("RegionId",regionId)
	local podiumH=math.min(18,height*.18)
	part(parent,name.."_Podium",Vector3.new(width+10,podiumH,depth+10),CFrame.new(base+Vector3.new(0,podiumH/2,0)),Enum.Material.Concrete,Color3.fromRGB(73,78,90),true,true)
	for y=podiumH+8,height-5,8 do
		local strip=part(parent,name.."_Band_"..tostring(math.floor(y)),Vector3.new(width+.7,.55,depth+.7),CFrame.new(base+Vector3.new(0,y,0)),Enum.Material.Neon,accent,false,false)
		strip.CanTouch=false
	end
	for y=8,height-8,8 do
		local front=part(parent,name.."_FrontWindow_"..tostring(y),Vector3.new(width*.68,.9,.6),CFrame.new(base+Vector3.new(0,y,-depth/2-.7)),Enum.Material.Glass,accent,false,false)
		front.Transparency=.08
		local side=part(parent,name.."_SideWindow_"..tostring(y),Vector3.new(.6,.9,depth*.68),CFrame.new(base+Vector3.new(width/2+.7,y,0)),Enum.Material.Glass,accent,false,false)
		side.Transparency=.10
	end
	local crown=part(parent,name.."_Crown",Vector3.new(width*.65,3,depth*.65),CFrame.new(base+Vector3.new(0,height+2,0)),Enum.Material.Neon,accent,false,false)
	tag(body,"EnvironmentStatic")
	tag(crown,"LandmarkVisual")
end

local function enterableBuilding(parent:Instance,name:string,pos:Vector3,width:number,depth:number,height:number,regionId:string,accent:Color3)
	local wall=4
	local frontZ=-depth/2
	part(parent,name.."_Back",Vector3.new(width,height,wall),CFrame.new(pos+Vector3.new(0,height/2,depth/2)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	part(parent,name.."_Left",Vector3.new(wall,height,depth),CFrame.new(pos+Vector3.new(-width/2,height/2,0)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	part(parent,name.."_Right",Vector3.new(wall,height,depth),CFrame.new(pos+Vector3.new(width/2,height/2,0)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	local frontWidth=(width-12)/2
	part(parent,name.."_FrontL",Vector3.new(frontWidth,height,wall),CFrame.new(pos+Vector3.new(-(width-frontWidth)/2,height/2,frontZ)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	part(parent,name.."_FrontR",Vector3.new(frontWidth,height,wall),CFrame.new(pos+Vector3.new((width-frontWidth)/2,height/2,frontZ)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	for floor=1,math.max(1,math.floor(height/10)) do
		part(parent,name.."_Floor_"..floor,Vector3.new(width-8,.8,depth-8),CFrame.new(pos+Vector3.new(0,floor*10-1,0)),Enum.Material.Concrete,Color3.fromRGB(70,73,82),true,true)
	end
	local frame=part(parent,name.."_DoorFrame",Vector3.new(12,12,1),CFrame.new(pos+Vector3.new(0,6,frontZ-.2)),Enum.Material.Metal,PALETTE.DarkMetal,true,true)
	frame:SetAttribute("RegionId",regionId)
	local sign=part(parent,name.."_Sign",Vector3.new(math.min(width*.45,18),3,.5),CFrame.new(pos+Vector3.new(0,height-4,frontZ-.6)),Enum.Material.Neon,accent,false,false)
	sign.CanTouch=false
	marker(parent,name.."_InteriorVolume",pos+Vector3.new(0,height/2,0),Vector3.new(width-4,height-2,depth-4),regionId)
end

local function tree(parent:Instance,pos:Vector3,scale:number)
	local trunk=part(parent,"TreeTrunk",Vector3.new(scale*.7,scale*2.5,scale*.7),CFrame.new(pos+Vector3.new(0,scale*1.25,0)),Enum.Material.Wood,Color3.fromRGB(87,62,46),true,false)
	trunk.CanQuery=false
	local crown=part(parent,"TreeCrown",Vector3.new(scale*2.5,scale*2.5,scale*2.5),CFrame.new(pos+Vector3.new(0,scale*3,0)),Enum.Material.Grass,Color3.fromRGB(67,127,82),true,false)
	crown.Shape=Enum.PartType.Ball
	crown.CanQuery=false
end

local function bench(parent:Instance,pos:Vector3,rotation:number)
	part(parent,"BenchSeat",Vector3.new(6,.5,1.6),CFrame.new(pos+Vector3.new(0,1,0))*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Wood,Color3.fromRGB(98,68,48),true,false)
	part(parent,"BenchBack",Vector3.new(6,1.8,.45),CFrame.new(pos+Vector3.new(0,2,0))*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Wood,Color3.fromRGB(98,68,48),true,false)
end

local function destructibleProp(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3)
	local p=part(parent,name,size,CFrame.new(pos),Enum.Material.Metal,color,true,true)
	tag(p,"CombatDestructible")
	p:SetAttribute("RestoreSeconds",6)
	return p
end


local function roofLadder(parent:Instance,name:string,pos:Vector3,height:number)
	local ladder=Instance.new("TrussPart");ladder.Name=name;ladder.Size=Vector3.new(2,height,2);ladder.CFrame=CFrame.new(pos+Vector3.new(0,height/2,0));ladder.Material=Enum.Material.Metal;ladder.Color=PALETTE.Metal;ladder.Anchored=true;ladder.Parent=parent
	return ladder
end

local function stair(parent:Instance,name:string,start:Vector3,steps:number,width:number,height:number,forward:Vector3)
	local dir=forward.Magnitude>.1 and forward.Unit or Vector3.new(0,0,1)
	for i=1,steps do
		local pos=start+dir*((i-1)*2.2)+Vector3.new(0,(i-1)*height,0)
		part(parent,name.."_"..i,Vector3.new(width,height*i,3),CFrame.new(pos+Vector3.new(0,height*i/2,0)),Enum.Material.Concrete,PALETTE.Sidewalk,true,true)
	end
end

local function skybridge(parent:Instance,name:string,pos:Vector3,length:number,rotation:number)
	local cf=CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0)
	part(parent,name.."_Deck",Vector3.new(length,2,14),cf,Enum.Material.Metal,PALETTE.DarkMetal,true,true)
	part(parent,name.."_RailA",Vector3.new(length,3,.6),cf*CFrame.new(0,2.2,-6),Enum.Material.Glass,PALETTE.Neon,true,false)
	part(parent,name.."_RailB",Vector3.new(length,3,.6),cf*CFrame.new(0,2.2,6),Enum.Material.Glass,PALETTE.Neon,true,false)
	for x=-length/2+12,length/2-12,24 do
		part(parent,name.."_Beam_"..tostring(x),Vector3.new(.8,8,16),cf*CFrame.new(x,-4,0),Enum.Material.Metal,PALETTE.Metal,true,true)
	end
end

local function canal(parent:Instance)
	local water=part(parent,"CanalWater",Vector3.new(250,.6,30),CFrame.new(250,.2,300),Enum.Material.Glass,PALETTE.Canal,false,false)
	water.Transparency=.28
	local glow=neonStrip(parent,"CanalGlow",Vector3.new(250,.5,300),Vector3.new(230,.2,2),0,PALETTE.Neon);CollectionService:AddTag(glow,"CollisionResponsive")
	glow.Transparency=.2
	for x=130,370,20 do
		part(parent,"CanalWall",Vector3.new(1,4,34),CFrame.new(x,1.5,282),Enum.Material.Concrete,PALETTE.Sidewalk,true,true)
		part(parent,"CanalWall",Vector3.new(1,4,34),CFrame.new(x,1.5,318),Enum.Material.Concrete,PALETTE.Sidewalk,true,true)
	end
end

local function metro(parent:Instance)
	local center=Vector3.new(-120,-14,-70)
	part(parent,"MetroFloor",Vector3.new(90,1,56),CFrame.new(center),Enum.Material.Concrete,Color3.fromRGB(51,54,63),true,true)
	part(parent,"MetroBackWall",Vector3.new(90,22,2),CFrame.new(center+Vector3.new(0,11,27)),Enum.Material.Concrete,PALETTE.DarkMetal,true,true)
	part(parent,"MetroLeftWall",Vector3.new(2,22,56),CFrame.new(center+Vector3.new(-44,11,0)),Enum.Material.Concrete,PALETTE.DarkMetal,true,true)
	part(parent,"MetroRightWall",Vector3.new(2,22,56),CFrame.new(center+Vector3.new(44,11,0)),Enum.Material.Concrete,PALETTE.DarkMetal,true,true)
	part(parent,"MetroTrack",Vector3.new(74,.35,4),CFrame.new(center+Vector3.new(0,.6,0)),Enum.Material.Metal,PALETTE.Metal,true,true)
	for x=-30,30,12 do
		neonStrip(parent,"MetroLine",center+Vector3.new(x,8,-26),Vector3.new(7,.25,.4),0,PALETTE.Neon)
	end
	stair(parent,"MetroStairs",Vector3.new(-120,-2,-100),8,14,1.5,Vector3.new(0,0,1))
end

local function centralPlaza(parent:Instance)
	part(parent,"NexusPlaza",Vector3.new(130,1,100),CFrame.new(0,.5,-20),Enum.Material.Slate,Color3.fromRGB(54,59,70),true,true)
	local ring=part(parent,"NexusRing",Vector3.new(70,.6,70),CFrame.new(0,1,-20),Enum.Material.Neon,PALETTE.Purple,false,false)
	ring.Shape=Enum.PartType.Cylinder
	ring.Transparency=.65
	local core=part(parent,"NexusCore",Vector3.new(14,14,14),CFrame.new(0,8,-20),Enum.Material.Neon,PALETTE.Neon,false,false)
	core.Shape=Enum.PartType.Ball
	table.insert(breakParts,core);CollectionService:AddTag(core,"CollisionResponsive")
	for angle=0,315,45 do
		local rad=math.rad(angle)
		local pos=Vector3.new(math.cos(rad)*46,2, -20+math.sin(rad)*34)
		destructibleProp(parent,"NexusCover",pos,Vector3.new(6,4,3),PALETTE.Metal)
	end
end

local function park(parent:Instance)
	part(parent,"ShatterPark",Vector3.new(190,1,150),CFrame.new(-250,.5,-275),Enum.Material.Grass,PALETTE.Park,true,true)
	for _,pos in ipairs({
		Vector3.new(-315,0,-320),Vector3.new(-270,0,-310),Vector3.new(-220,0,-325),
		Vector3.new(-300,0,-250),Vector3.new(-250,0,-230),Vector3.new(-190,0,-260),
		Vector3.new(-315,0,-220),Vector3.new(-210,0,-300),
	}) do tree(parent,pos,3.5)
	end
	for _,pos in ipairs({Vector3.new(-300,0,-275),Vector3.new(-225,0,-285),Vector3.new(-270,0,-245)})do bench(parent,pos,90)end
	local fountain=part(parent,"ParkFountain",Vector3.new(26,2,26),CFrame.new(-250,2,-275),Enum.Material.Slate,Color3.fromRGB(72,78,88),true,true)
	local water=part(parent,"ParkWater",Vector3.new(20,.4,20),CFrame.new(-250,3,-275),Enum.Material.Glass,PALETTE.Canal,false,false);water.Transparency=.25;water.Shape=Enum.PartType.Cylinder
end

local function riftZone(parent:Instance)
	part(parent,"RiftCraterFloor",Vector3.new(210,1,150),CFrame.new(0,0,-385),Enum.Material.Basalt,Color3.fromRGB(41,38,52),true,true)
	for ringIndex=1,3 do
		local radius=24+ringIndex*22
		for angle=0,330,30 do
			local rad=math.rad(angle)
			local pos=Vector3.new(math.cos(rad)*radius,1+ringIndex*.4,-385+math.sin(rad)*(radius*.65))
			local rock=part(parent,"RiftRock",Vector3.new(7+ringIndex*2,4+ringIndex*2,7+ringIndex*2),CFrame.new(pos)*CFrame.Angles(math.rad(angle),rad,math.rad(angle*.5)),Enum.Material.Basalt,ringIndex==3 and Color3.fromRGB(63,49,74)or Color3.fromRGB(57,54,65),true,true)
			tag(rock,"RiftProp")
		end
	end
	local core=part(parent,"RiftCore",Vector3.new(16,4,16),CFrame.new(0,3,-385),Enum.Material.Neon,PALETTE.Rift,false,false);core.Shape=Enum.PartType.Cylinder;core.Transparency=.15;CollectionService:AddTag(core,"CollisionResponsive")
	table.insert(breakParts,core)
	for angle=0,315,45 do
		local rad=math.rad(angle)
		neonStrip(parent,"RiftFissure",Vector3.new(math.cos(rad)*42,1.2,-385+math.sin(rad)*29),Vector3.new(38,.25,1),angle,PALETTE.Rift)
	end
end

local function industrial(parent:Instance)
	for _,d in ipairs({
		{Vector3.new(265,0,-190),42,36,28},
		{Vector3.new(350,0,-155),54,40,34},
		{Vector3.new(275,0,-85),36,48,26},
		{Vector3.new(370,0,-70),46,42,30},
		{Vector3.new(300,0,55),50,38,40},
		{Vector3.new(390,0,100),42,48,34},
	}) do
		enterableBuilding(parent,"IndustrialUnit",d[1],d[2],d[3],d[4],"IndustrialVerge",PALETTE.Warning)
	end
	for x=190,430,24 do
		local stack=part(parent,"Pipe",Vector3.new(5,5,34),CFrame.new(x,5,15),Enum.Material.Metal,PALETTE.Industrial,true,true)
		stack.Shape=Enum.PartType.Cylinder
	end
	for x=210,420,42 do
		destructibleProp(parent,"Crate",Vector3.new(x,2,180),Vector3.new(5,4,5),PALETTE.Industrial)
	end
end

local function market(parent:Instance)
	enterableBuilding(parent,"CanalMarket",Vector3.new(205,0,205),82,56,18,"CanalMarket",PALETTE.Neon)
	for x=170,240,16 do
		for z=180,230,16 do
			local canopy=part(parent,"MarketCanopy",Vector3.new(12,5,10),CFrame.new(x,5,z),Enum.Material.Fabric,Color3.fromRGB(92,66,122),true,false)
			canopy.CanCollide=false
		end
	end
end

local function highrise(parent:Instance)
	tower(parent,"AsterTower",Vector3.new(-345,0,-130),46,46,102,PALETTE.Neon,"NeonHeights")
	tower(parent,"VantaTower",Vector3.new(-275,0,-130),38,42,74,PALETTE.Purple,"NeonHeights")
	simpleBuilding(parent,"ArcadeBlock",Vector3.new(-355,0,-35),48,52,42,Color3.fromRGB(70,75,88),PALETTE.Neon,"NeonHeights")
	simpleBuilding(parent,"GalleryBlock",Vector3.new(-275,0,-25),44,48,54,Color3.fromRGB(78,73,88),PALETTE.Purple,"NeonHeights")
end

local function northCampus(parent:Instance)
	enterableBuilding(parent,"ArchiveHall",Vector3.new(150,0,-300),76,52,26,"ArchiveQuarter",PALETTE.Neon)
	tower(parent,"ObservationSpire",Vector3.new(255,0,-315),34,34,88,PALETTE.Neon,"ArchiveQuarter")
	part(parent,"ArchiveTerrace",Vector3.new(120,1,76),CFrame.new(150,1,-230),Enum.Material.Grass,Color3.fromRGB(55,86,72),true,true)
	for _,pos in ipairs({Vector3.new(115,0,-245),Vector3.new(155,0,-245),Vector3.new(195,0,-245)})do tree(parent,pos,3)end
end

local function skyNetwork(parent:Instance)
	skybridge(parent,"SkybridgeWest",Vector3.new(-180,36,-20),210,0)
	skybridge(parent,"SkybridgeNorth",Vector3.new(0,36,-160),250,90)
	skybridge(parent,"SkybridgeSouth",Vector3.new(30,30,145),220,90)
	stair(parent,"SkybridgeAccessA",Vector3.new(-230,1,-15),18,12,2,Vector3.new(0,0,1))
	stair(parent,"SkybridgeAccessB",Vector3.new(92,1,-170),18,12,2,Vector3.new(1,0,0))
end

local function roads(parent:Instance)
	streetSegment(parent,"BoulevardX",Vector3.new(0,0,0),Vector3.new(860,1,34),0)
	streetSegment(parent,"BoulevardZ",Vector3.new(0,0,0),Vector3.new(34,1,860),90)
	streetSegment(parent,"NorthRing",Vector3.new(0,0,-220),Vector3.new(760,1,24),0)
	streetSegment(parent,"SouthRing",Vector3.new(0,0,220),Vector3.new(760,1,24),0)
	streetSegment(parent,"WestRing",Vector3.new(-220,0,0),Vector3.new(24,1,760),90)
	streetSegment(parent,"EastRing",Vector3.new(220,0,0),Vector3.new(24,1,760),90)
	for x=-390,390,52 do streetLight(parent,Vector3.new(x,0,22),1);streetLight(parent,Vector3.new(x,0,-22),-1)end
	for z=-390,390,52 do streetLight(parent,Vector3.new(22,0,z),1);streetLight(parent,Vector3.new(-22,0,z),-1)end
	for _,pos in ipairs({
		Vector3.new(-60,1,-55),Vector3.new(60,1,-55),Vector3.new(-60,1,55),Vector3.new(60,1,55),
		Vector3.new(-255,1,150),Vector3.new(-255,1,380),Vector3.new(120,1,250),Vector3.new(370,1,250)
	})do sidewalk(parent,"IntersectionWalk",pos,Vector3.new(24,1,24))end
end

local function ground(parent:Instance)
	local holeCenter=Vector3.new(-120,-1,-70)
	local holeW=110
	local holeD=70
	local minX=-480
	local maxX=480
	local minZ=-480
	local maxZ=480
	local leftEdge=holeCenter.X-holeW/2
	local rightEdge=holeCenter.X+holeW/2
	local bottomEdge=holeCenter.Z-holeD/2
	local topEdge=holeCenter.Z+holeD/2
	local leftW=leftEdge-minX
	local rightW=maxX-rightEdge
	local topD=maxZ-topEdge
	local bottomD=bottomEdge-minZ
	part(parent,"GroundWest",Vector3.new(leftW,2,960),CFrame.new(minX+leftW/2,-1,0),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
	part(parent,"GroundEast",Vector3.new(rightW,2,960),CFrame.new(rightEdge+rightW/2,-1,0),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
	part(parent,"GroundNorth",Vector3.new(holeW,2,topD),CFrame.new(holeCenter.X,-1,topEdge+topD/2),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
	part(parent,"GroundSouth",Vector3.new(holeW,2,bottomD),CFrame.new(holeCenter.X,-1,minZ+bottomD/2),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
end

function S.Init()
	if root then return end
	root=Instance.new("Folder");root.Name="CollisionBattlestarWorld";root.Parent=workspace
	environment=folder("Environment")
	gameplay=folder("Gameplay")
	landmarks=folder("Landmarks")
	regionVolumes=folder("RegionVolumes")

	ground(environment)
	roads(environment)
	centralPlaza(landmarks)
	highrise(environment)
	park(environment)
	roofLadder(environment,"AsterRoofLadder",Vector3.new(-345,0,-94),102)
	roofLadder(environment,"VantaRoofLadder",Vector3.new(-275,0,-94),74)
	roofLadder(environment,"ObservationRoofLadder",Vector3.new(255,0,-299),88)
	industrial(environment)
	market(environment)
	northCampus(environment)
	canal(environment)
	metro(gameplay)
	riftZone(gameplay)
	skyNetwork(gameplay)

	for _,data in ipairs({
		{"NexusPlaza",Vector3.new(0,6,-20),Vector3.new(170,24,140)},
		{"NeonHeights",Vector3.new(-310,20,-90),Vector3.new(190,100,210)},
		{"IndustrialVerge",Vector3.new(320,20,-60),Vector3.new(260,80,420)},
		{"ShatterPark",Vector3.new(-250,10,-275),Vector3.new(210,30,170)},
		{"CanalMarket",Vector3.new(205,10,245),Vector3.new(180,30,150)},
		{"ArchiveQuarter",Vector3.new(185,30,-285),Vector3.new(230,80,180)},
		{"OldMetro",Vector3.new(-120,-5,-70),Vector3.new(120,40,100)},
		{"RiftCrater",Vector3.new(0,10,-385),Vector3.new(240,50,190)},
	})do
		region(data[1],data[2],data[3])
	end

	local anchor=part(gameplay,"RealityBreakCenter",Vector3.new(4,4,4),CFrame.new(eventAnchor),Enum.Material.Neon,PALETTE.Rift,false,false)
	anchor.Transparency=.08
	anchor:SetAttribute("EventAnchor",true)
	table.insert(breakParts,anchor)

	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText="Trigger Resonance"
	prompt.ObjectText="Reality Break"
	prompt.HoldDuration=1.2
	prompt.MaxActivationDistance=12
	prompt.Parent=anchor
	prompt.Triggered:Connect(function()
		require(game.ServerScriptService.Services.EventService).StartRealityBreak("ManualAnchor")
	end)

	local secret=part(gameplay,"HiddenTerminal",Vector3.new(5,4,2),CFrame.new(-354,3,-328),Enum.Material.Neon,PALETTE.Purple,false,false)
	secret.Transparency=.12
	local secretPrompt=Instance.new("ProximityPrompt")
	secretPrompt.ActionText="Decode"
	secretPrompt.ObjectText="Anomalous Terminal"
	secretPrompt.HoldDuration=1
	secretPrompt.MaxActivationDistance=10
	secretPrompt.Parent=secret
	secretPrompt.Triggered:Connect(function(player)
		if secretFound[player] then return end
		secretFound[player]=true
		player:SetAttribute("SecretTerminalFound",true)
		Data.AddCoins(player,40)
		Data.AddExploration(player,40)
		game.ReplicatedStorage.CollisionRemotes.Feedback:FireClient(player,"SecretFound","ANOMALOUS TERMINAL • +40 CR")
	end)

	bossArena=Vector3.new(0,2,-312)
	local arena=part(landmarks,"BossArena",Vector3.new(160,2,110),CFrame.new(bossArena),Enum.Material.Slate,Color3.fromRGB(44,47,57),true,true)
	arena:SetAttribute("BossArena",true)
	for _,pos in ipairs({
		Vector3.new(-55,2,-345),Vector3.new(55,2,-345),Vector3.new(-55,2,-280),Vector3.new(55,2,-280)
	})do destructibleProp(gameplay,"ArenaCover",pos,Vector3.new(8,5,3),PALETTE.Metal)end

	spawns={
		Vector3.new(-68,4,60),Vector3.new(68,4,60),Vector3.new(-68,4,-60),Vector3.new(68,4,-60),
		Vector3.new(-190,4,40),Vector3.new(190,4,40),Vector3.new(-190,4,-180),Vector3.new(190,4,-180),
		Vector3.new(-335,4,120),Vector3.new(340,4,150),Vector3.new(-350,4,-10),Vector3.new(350,4,-20),
		Vector3.new(-240,4,285),Vector3.new(235,4,285),Vector3.new(90,4,-280),Vector3.new(-100,4,-330)
	}

	workspace:SetAttribute("CollisionBattlestarMap","FractureDistrict_v2")
	workspace:SetAttribute("MapBounds",480)
	workspace:SetAttribute("BossArenaPosition",bossArena)

	Lighting.EnvironmentDiffuseScale=.65
	Lighting.EnvironmentSpecularScale=.85
	Lighting.ClockTime=17.5
	Lighting.Brightness=2.2
	Lighting.GlobalShadows=true
end

function S.GetSpawnPoints():{Vector3}
	return spawns
end

function S.GetBossArena():Vector3
	return bossArena
end

function S.GetEventAnchor():Vector3
	return eventAnchor
end

function S.AnimateRealityBreak(active:boolean)
	for _,p in ipairs(breakParts)do
		if p.Parent then
			p.Material=active and Enum.Material.Neon or Enum.Material.Concrete
			p.Color=active and PALETTE.Rift or Color3.fromRGB(105,110,115)
		end
	end
end

return S
