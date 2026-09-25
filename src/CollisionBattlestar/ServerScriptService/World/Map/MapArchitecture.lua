--!strict
local T=require(script.Parent.MapContext)
local s=T.Get()
local PALETTE=s.PALETTE

local function streetSegment(parent:Instance,name:string,pos:Vector3,size:Vector3,rotation:number)
	local road=T.Part(parent,name,size,CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Asphalt,PALETTE.Street,true,true)
	local lineSize=rotation%180==0 and Vector3.new(size.X,.08,1.2) or Vector3.new(1.2,.08,size.Z)
	local line=T.Part(parent,name.."_Center",lineSize,CFrame.new(pos+Vector3.new(0,.54,0))*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Neon,Color3.fromRGB(170,180,195),false,false)
	line.Transparency=.35
	return road
end

local function sidewalk(parent:Instance,name:string,pos:Vector3,size:Vector3)
	return T.Part(parent,name,size,CFrame.new(pos),Enum.Material.Concrete,PALETTE.Sidewalk,true,true)
end

local function streetLight(parent:Instance,pos:Vector3,rotation:number)
	T.Part(parent,"StreetLight",Vector3.new(.8,12,.8),CFrame.new(pos+Vector3.new(0,6,0)),Enum.Material.Metal,PALETTE.Metal,true,true)
	T.Part(parent,"StreetLightArm",Vector3.new(4,.5,.5),CFrame.new(pos+Vector3.new(rotation*2,11,0)),Enum.Material.Metal,PALETTE.Metal,true,true)
	local lamp=T.Part(parent,"StreetLightGlow",Vector3.new(1.4,.5,1.4),CFrame.new(pos+Vector3.new(rotation*3.3,10.8,0)),Enum.Material.Neon,PALETTE.Neon,false,false)
	lamp.CanTouch=false
end

local function windowStrip(parent:Instance,name:string,pos:Vector3,size:Vector3,vertical:boolean,color:Color3)
	local w=T.Part(parent,name,size,CFrame.new(pos),Enum.Material.Glass,color,false,false)
	w.Transparency=.12
	if vertical then
		w.Size=Vector3.new(.5,size.Y,size.Z)
	else
		w.Size=Vector3.new(size.X,.5,size.Z)
	end
	return w
end

local function simpleBuilding(parent:Instance,name:string,base:Vector3,width:number,depth:number,height:number,color:Color3,accent:Color3,regionId:string)
	local body=T.Part(parent,name,Vector3.new(width,height,depth),CFrame.new(base+Vector3.new(0,height/2,0)),Enum.Material.Concrete,color,true,true)
	body:SetAttribute("RegionId",regionId)
	T.Part(parent,name.."_Roof",Vector3.new(width+2,1.5,depth+2),CFrame.new(base+Vector3.new(0,height+.75,0)),Enum.Material.Metal,PALETTE.DarkMetal,true,true)
	T.Tag(body,"EnvironmentStatic")
	local strips=math.max(2,math.floor(width/11))
	for i=1,strips do
		local x=(-width/2)+(i*(width/(strips+1)))
		windowStrip(parent,name.."_Glass_"..i,base+Vector3.new(x,height*.56,-depth/2-.28),Vector3.new(2,height*.50,.4),false,accent)
	end
	local crown=T.Part(parent,name.."_Crown",Vector3.new(math.max(5,width*.55),2,math.max(5,depth*.55)),CFrame.new(base+Vector3.new(0,height+2,0)),Enum.Material.Neon,accent,false,false)
	crown.CanTouch=false
end

local function tower(parent:Instance,name:string,base:Vector3,width:number,depth:number,height:number,accent:Color3,regionId:string)
	local body=T.Part(parent,name,Vector3.new(width,height,depth),CFrame.new(base+Vector3.new(0,height/2,0)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	body:SetAttribute("RegionId",regionId)
	local podiumH=math.min(18,height*.18)
	T.Part(parent,name.."_Podium",Vector3.new(width+10,podiumH,depth+10),CFrame.new(base+Vector3.new(0,podiumH/2,0)),Enum.Material.Concrete,Color3.fromRGB(73,78,90),true,true)
	for y=podiumH+8,height-5,8 do
		T.Part(parent,name.."_Band_"..tostring(math.floor(y)),Vector3.new(width+.7,.55,depth+.7),CFrame.new(base+Vector3.new(0,y,0)),Enum.Material.Neon,accent,false,false)
	end
	for y=8,height-8,8 do
		local front=T.Part(parent,name.."_FrontWindow_"..tostring(y),Vector3.new(width*.68,.9,.6),CFrame.new(base+Vector3.new(0,y,-depth/2-.7)),Enum.Material.Glass,accent,false,false)
		front.Transparency=.08
		local side=T.Part(parent,name.."_SideWindow_"..tostring(y),Vector3.new(.6,.9,depth*.68),CFrame.new(base+Vector3.new(width/2+.7,y,0)),Enum.Material.Glass,accent,false,false)
		side.Transparency=.10
	end
	local crown=T.Part(parent,name.."_Crown",Vector3.new(width*.65,3,depth*.65),CFrame.new(base+Vector3.new(0,height+2,0)),Enum.Material.Neon,accent,false,false)
	T.Tag(body,"EnvironmentStatic")
	T.Tag(crown,"LandmarkVisual")
end

local function enterableBuilding(parent:Instance,name:string,pos:Vector3,width:number,depth:number,height:number,regionId:string,accent:Color3)
	local wall=4
	local frontZ=-depth/2
	T.Part(parent,name.."_Back",Vector3.new(width,height,wall),CFrame.new(pos+Vector3.new(0,height/2,depth/2)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	T.Part(parent,name.."_Left",Vector3.new(wall,height,depth),CFrame.new(pos+Vector3.new(-width/2,height/2,0)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	T.Part(parent,name.."_Right",Vector3.new(wall,height,depth),CFrame.new(pos+Vector3.new(width/2,height/2,0)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	local frontWidth=(width-12)/2
	T.Part(parent,name.."_FrontL",Vector3.new(frontWidth,height,wall),CFrame.new(pos+Vector3.new(-(width-frontWidth)/2,height/2,frontZ)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	T.Part(parent,name.."_FrontR",Vector3.new(frontWidth,height,wall),CFrame.new(pos+Vector3.new((width-frontWidth)/2,height/2,frontZ)),Enum.Material.Concrete,PALETTE.Concrete,true,true)
	for floor=1,math.max(1,math.floor(height/10)) do
		T.Part(parent,name.."_Floor_"..floor,Vector3.new(width-8,.8,depth-8),CFrame.new(pos+Vector3.new(0,floor*10-1,0)),Enum.Material.Concrete,Color3.fromRGB(70,73,82),true,true)
	end
	local frame=T.Part(parent,name.."_DoorFrame",Vector3.new(12,12,1),CFrame.new(pos+Vector3.new(0,6,frontZ-.2)),Enum.Material.Metal,PALETTE.DarkMetal,true,true)
	frame:SetAttribute("RegionId",regionId)
	T.Part(parent,name.."_Sign",Vector3.new(math.min(width*.45,18),3,.5),CFrame.new(pos+Vector3.new(0,height-4,frontZ-.6)),Enum.Material.Neon,accent,false,false)
	T.Marker(parent,name.."_InteriorVolume",pos+Vector3.new(0,height/2,0),Vector3.new(width-4,height-2,depth-4),regionId)
end

local function tree(parent:Instance,pos:Vector3,scale:number)
	local trunk=T.Part(parent,"TreeTrunk",Vector3.new(scale*.7,scale*2.5,scale*.7),CFrame.new(pos+Vector3.new(0,scale*1.25,0)),Enum.Material.Wood,Color3.fromRGB(87,62,46),true,false)
	trunk.CanQuery=false
	local crown=T.Part(parent,"TreeCrown",Vector3.new(scale*2.5,scale*2.5,scale*2.5),CFrame.new(pos+Vector3.new(0,scale*3,0)),Enum.Material.Grass,Color3.fromRGB(67,127,82),true,false)
	crown.Shape=Enum.PartType.Ball
	crown.CanQuery=false
end

local function bench(parent:Instance,pos:Vector3,rotation:number)
	T.Part(parent,"BenchSeat",Vector3.new(6,.5,1.6),CFrame.new(pos+Vector3.new(0,1,0))*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Wood,Color3.fromRGB(98,68,48),true,false)
	T.Part(parent,"BenchBack",Vector3.new(6,1.8,.45),CFrame.new(pos+Vector3.new(0,2,0))*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Wood,Color3.fromRGB(98,68,48),true,false)
end

local function roofLadder(parent:Instance,name:string,pos:Vector3,height:number)
	local ladder=Instance.new("TrussPart")
	ladder.Name=name
	ladder.Size=Vector3.new(2,height,2)
	ladder.CFrame=CFrame.new(pos+Vector3.new(0,height/2,0))
	ladder.Material=Enum.Material.Metal
	ladder.Color=PALETTE.Metal
	ladder.Anchored=true
	ladder.Parent=parent
	return ladder
end

local function stair(parent:Instance,name:string,start:Vector3,steps:number,width:number,height:number,forward:Vector3)
	local dir=forward.Magnitude>.1 and forward.Unit or Vector3.new(0,0,1)
	for i=1,steps do
		local pos=start+dir*((i-1)*2.2)+Vector3.new(0,(i-1)*height,0)
		T.Part(parent,name.."_"..i,Vector3.new(width,height*i,3),CFrame.new(pos+Vector3.new(0,height*i/2,0)),Enum.Material.Concrete,PALETTE.Sidewalk,true,true)
	end
end

local function skybridge(parent:Instance,name:string,pos:Vector3,length:number,rotation:number)
	local cf=CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0)
	T.Part(parent,name.."_Deck",Vector3.new(length,2,14),cf,Enum.Material.Metal,PALETTE.DarkMetal,true,true)
	T.Part(parent,name.."_RailA",Vector3.new(length,3,.6),cf*CFrame.new(0,2.2,-6),Enum.Material.Glass,PALETTE.Neon,true,false)
	T.Part(parent,name.."_RailB",Vector3.new(length,3,.6),cf*CFrame.new(0,2.2,6),Enum.Material.Glass,PALETTE.Neon,true,false)
	for x=-length/2+12,length/2-12,24 do
		T.Part(parent,name.."_Beam_"..tostring(x),Vector3.new(.8,8,16),cf*CFrame.new(x,-4,0),Enum.Material.Metal,PALETTE.Metal,true,true)
	end
end

return {
	streetSegment=streetSegment,
	sidewalk=sidewalk,
	streetLight=streetLight,
	windowStrip=windowStrip,
	simpleBuilding=simpleBuilding,
	tower=tower,
	enterableBuilding=enterableBuilding,
	tree=tree,
	bench=bench,
	roofLadder=roofLadder,
	stair=stair,
	skybridge=skybridge,
}
