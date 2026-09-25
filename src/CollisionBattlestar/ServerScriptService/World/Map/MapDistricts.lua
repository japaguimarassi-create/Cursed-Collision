--!strict
local T=require(script.Parent.MapContext)
local G=require(script.Parent.MapArchitecture)
local s=T.Get()
local C=s.Config
local P=s.PALETTE

local function centralPlaza(parent:Instance)
	T.Part(parent,"NexusPlaza",Vector3.new(130,1,100),CFrame.new(0,.5,-20),Enum.Material.Slate,Color3.fromRGB(54,59,70),true,true)
	local ring=T.Part(parent,"NexusRing",Vector3.new(70,.6,70),CFrame.new(0,1,-20),Enum.Material.Neon,P.Purple,false,false)
	ring.Shape=Enum.PartType.Cylinder
	ring.Transparency=.65
	local core=T.Part(parent,"NexusCore",Vector3.new(14,14,14),CFrame.new(0,8,-20),Enum.Material.Neon,P.Neon,false,false)
	core.Shape=Enum.PartType.Ball
	T.AddBreakPart(core)
	T.Tag(core,"CollisionResponsive")
	for angle=0,315,45 do
		local rad=math.rad(angle)
		T.DestructibleProp(parent,"NexusCover",Vector3.new(math.cos(rad)*46,2,-20+math.sin(rad)*34),Vector3.new(6,4,3),P.Metal)
	end
end

local function park(parent:Instance)
	T.Part(parent,"ShatterPark",Vector3.new(190,1,150),CFrame.new(-250,.5,-275),Enum.Material.Grass,P.Park,true,true)
	for _,pos in ipairs({
		Vector3.new(-315,0,-320),Vector3.new(-270,0,-310),Vector3.new(-220,0,-325),
		Vector3.new(-300,0,-250),Vector3.new(-250,0,-230),Vector3.new(-190,0,-260),
		Vector3.new(-315,0,-220),Vector3.new(-210,0,-300),
	}) do G.tree(parent,pos,3.5) end
	for _,pos in ipairs({Vector3.new(-300,0,-275),Vector3.new(-225,0,-285),Vector3.new(-270,0,-245)})do G.bench(parent,pos,90)end
	local fountain=T.Part(parent,"ParkFountain",Vector3.new(26,2,26),CFrame.new(-250,2,-275),Enum.Material.Slate,Color3.fromRGB(72,78,88),true,true)
	local water=T.Part(parent,"ParkWater",Vector3.new(20,.4,20),CFrame.new(-250,3,-275),Enum.Material.Glass,P.Canal,false,false)
	water.Transparency=.25
	water.Shape=Enum.PartType.Cylinder
end

local function riftZone(parent:Instance)
	T.Part(parent,"RiftCraterFloor",Vector3.new(210,1,150),CFrame.new(0,0,-385),Enum.Material.Basalt,Color3.fromRGB(41,38,52),true,true)
	for ringIndex=1,3 do
		local radius=24+ringIndex*22
		for angle=0,330,30 do
			local rad=math.rad(angle)
			local pos=Vector3.new(math.cos(rad)*radius,1+ringIndex*.4,-385+math.sin(rad)*(radius*.65))
			local rock=T.Part(parent,"RiftRock",Vector3.new(7+ringIndex*2,4+ringIndex*2,7+ringIndex*2),CFrame.new(pos)*CFrame.Angles(math.rad(angle),rad,math.rad(angle*.5)),Enum.Material.Basalt,ringIndex==3 and Color3.fromRGB(63,49,74)or Color3.fromRGB(57,54,65),true,true)
			T.Tag(rock,"RiftProp")
		end
	end
	local core=T.Part(parent,"RiftCore",Vector3.new(16,4,16),CFrame.new(0,3,-385),Enum.Material.Neon,P.Rift,false,false)
	core.Shape=Enum.PartType.Cylinder
	core.Transparency=.15
	T.Tag(core,"CollisionResponsive")
	T.AddBreakPart(core)
	for angle=0,315,45 do
		local rad=math.rad(angle)
		T.NeonStrip(parent,"RiftFissure",Vector3.new(math.cos(rad)*42,1.2,-385+math.sin(rad)*29),Vector3.new(38,.25,1),angle,P.Rift)
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
		G.enterableBuilding(parent,"IndustrialUnit",d[1],d[2],d[3],d[4],"IndustrialVerge",P.Warning)
	end
	for x=190,430,24 do
		local stack=T.Part(parent,"Pipe",Vector3.new(5,5,34),CFrame.new(x,5,15),Enum.Material.Metal,P.Industrial,true,true)
		stack.Shape=Enum.PartType.Cylinder
	end
	for x=210,420,42 do
		T.DestructibleProp(parent,"Crate",Vector3.new(x,2,180),Vector3.new(5,4,5),P.Industrial)
	end
end

local function market(parent:Instance)
	G.enterableBuilding(parent,"CanalMarket",Vector3.new(205,0,205),82,56,18,"CanalMarket",P.Neon)
	for x=170,240,16 do
		for z=180,230,16 do
			local canopy=T.Part(parent,"MarketCanopy",Vector3.new(12,5,10),CFrame.new(x,5,z),Enum.Material.Fabric,Color3.fromRGB(92,66,122),true,false)
			canopy.CanCollide=false
		end
	end
end

local function highrise(parent:Instance)
	G.tower(parent,"AsterTower",Vector3.new(-345,0,-130),46,46,102,P.Neon,"NeonHeights")
	G.tower(parent,"VantaTower",Vector3.new(-275,0,-130),38,42,74,P.Purple,"NeonHeights")
	G.simpleBuilding(parent,"ArcadeBlock",Vector3.new(-355,0,-35),48,52,42,Color3.fromRGB(70,75,88),P.Neon,"NeonHeights")
	G.simpleBuilding(parent,"GalleryBlock",Vector3.new(-275,0,-25),44,48,54,Color3.fromRGB(78,73,88),P.Purple,"NeonHeights")
end

local function northCampus(parent:Instance)
	G.enterableBuilding(parent,"ArchiveHall",Vector3.new(150,0,-300),76,52,26,"ArchiveQuarter",P.Neon)
	G.tower(parent,"ObservationSpire",Vector3.new(255,0,-315),34,34,88,P.Neon,"ArchiveQuarter")
	T.Part(parent,"ArchiveTerrace",Vector3.new(120,1,76),CFrame.new(150,1,-230),Enum.Material.Grass,Color3.fromRGB(55,86,72),true,true)
	for _,pos in ipairs({Vector3.new(115,0,-245),Vector3.new(155,0,-245),Vector3.new(195,0,-245)})do G.tree(parent,pos,3)end
end

local function skyNetwork(parent:Instance)
	G.skybridge(parent,"SkybridgeWest",Vector3.new(-180,36,-20),210,0)
	G.skybridge(parent,"SkybridgeNorth",Vector3.new(0,36,-160),250,90)
	G.skybridge(parent,"SkybridgeSouth",Vector3.new(30,30,145),220,90)
	G.stair(parent,"SkybridgeAccessA",Vector3.new(-230,1,-15),18,12,2,Vector3.new(0,0,1))
	G.stair(parent,"SkybridgeAccessB",Vector3.new(92,1,-170),18,12,2,Vector3.new(1,0,0))
end

local function roads(parent:Instance)
	G.streetSegment(parent,"BoulevardX",Vector3.new(0,0,0),Vector3.new(860,1,34),0)
	G.streetSegment(parent,"BoulevardZ",Vector3.new(0,0,0),Vector3.new(34,1,860),90)
	G.streetSegment(parent,"NorthRing",Vector3.new(0,0,-220),Vector3.new(760,1,24),0)
	G.streetSegment(parent,"SouthRing",Vector3.new(0,0,220),Vector3.new(760,1,24),0)
	G.streetSegment(parent,"WestRing",Vector3.new(-220,0,0),Vector3.new(24,1,760),90)
	G.streetSegment(parent,"EastRing",Vector3.new(220,0,0),Vector3.new(24,1,760),90)
	for x=-390,390,52 do
		G.streetLight(parent,Vector3.new(x,0,22),1)
		G.streetLight(parent,Vector3.new(x,0,-22),-1)
	end
	for z=-390,390,52 do
		G.streetLight(parent,Vector3.new(22,0,z),1)
		G.streetLight(parent,Vector3.new(-22,0,z),-1)
	end
	for _,pos in ipairs({
		Vector3.new(-60,1,-55),Vector3.new(60,1,-55),Vector3.new(-60,1,55),Vector3.new(60,1,55),
		Vector3.new(-255,1,150),Vector3.new(-255,1,380),Vector3.new(120,1,250),Vector3.new(370,1,250)
	})do
		G.sidewalk(parent,"IntersectionWalk",pos,Vector3.new(24,1,24))
	end
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
	T.Part(parent,"GroundWest",Vector3.new(leftW,2,960),CFrame.new(minX+leftW/2,-1,0),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
	T.Part(parent,"GroundEast",Vector3.new(rightW,2,960),CFrame.new(rightEdge+rightW/2,-1,0),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
	T.Part(parent,"GroundNorth",Vector3.new(holeW,2,topD),CFrame.new(holeCenter.X,-1,topEdge+topD/2),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
	T.Part(parent,"GroundSouth",Vector3.new(holeW,2,bottomD),CFrame.new(holeCenter.X,-1,minZ+bottomD/2),Enum.Material.Concrete,Color3.fromRGB(69,74,83),true,true)
end

local function canal(parent:Instance)
	local water=T.Part(parent,"CanalWater",Vector3.new(250,.6,30),CFrame.new(250,.2,300),Enum.Material.Glass,P.Canal,false,false)
	water.Transparency=.28
	local glow=T.NeonStrip(parent,"CanalGlow",Vector3.new(250,.5,300),Vector3.new(230,.2,2),0,P.Neon)
	T.Tag(glow,"CollisionResponsive")
	glow.Transparency=.2
	for x=130,370,20 do
		T.Part(parent,"CanalWall",Vector3.new(1,4,34),CFrame.new(x,1.5,282),Enum.Material.Concrete,P.Sidewalk,true,true)
		T.Part(parent,"CanalWall",Vector3.new(1,4,34),CFrame.new(x,1.5,318),Enum.Material.Concrete,P.Sidewalk,true,true)
	end
end

local function metro(parent:Instance)
	local center=Vector3.new(-120,-14,-70)
	T.Part(parent,"MetroFloor",Vector3.new(90,1,56),CFrame.new(center),Enum.Material.Concrete,Color3.fromRGB(51,54,63),true,true)
	T.Part(parent,"MetroBackWall",Vector3.new(90,22,2),CFrame.new(center+Vector3.new(0,11,27)),Enum.Material.Concrete,P.DarkMetal,true,true)
	T.Part(parent,"MetroLeftWall",Vector3.new(2,22,56),CFrame.new(center+Vector3.new(-44,11,0)),Enum.Material.Concrete,P.DarkMetal,true,true)
	T.Part(parent,"MetroRightWall",Vector3.new(2,22,56),CFrame.new(center+Vector3.new(44,11,0)),Enum.Material.Concrete,P.DarkMetal,true,true)
	T.Part(parent,"MetroTrack",Vector3.new(74,.35,4),CFrame.new(center+Vector3.new(0,.6,0)),Enum.Material.Metal,P.Metal,true,true)
	for x=-30,30,12 do
		T.NeonStrip(parent,"MetroLine",center+Vector3.new(x,8,-26),Vector3.new(7,.25,.4),0,P.Neon)
	end
	G.stair(parent,"MetroStairs",Vector3.new(-120,-2,-100),8,14,1.5,Vector3.new(0,0,1))
end

function M.Build()
	ground(s.environment)
	roads(s.environment)
	centralPlaza(s.landmarks)
	highrise(s.environment)
	park(s.environment)
	G.roofLadder(s.environment,"AsterRoofLadder",Vector3.new(-345,0,-94),102)
	G.roofLadder(s.environment,"VantaRoofLadder",Vector3.new(-275,0,-94),74)
	G.roofLadder(s.environment,"ObservationRoofLadder",Vector3.new(255,0,-299),88)
	industrial(s.environment)
	market(s.environment)
	northCampus(s.environment)
	canal(s.environment)
	metro(s.gameplay)
	riftZone(s.gameplay)
	skyNetwork(s.gameplay)
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
		T.Region(data[1],data[2],data[3])
	end
end

return M
