--!strict
local Lighting=game:GetService("Lighting")
local CollectionService=game:GetService("CollectionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local U=require(ReplicatedStorage.Shared.Util)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Config=require(ReplicatedStorage.Shared.Config)
local AssetLoader=require(script.Parent.MapAssetLoader)

local S={}
local root:Folder?
local rng=Random.new(9262026)

local function part(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3,collide:boolean?,transparency:number?):Part
	local p=U.Part(parent,name,size,cf,material,color,true)
	p.CanCollide=collide~=false
	p.CanTouch=false
	p.CanQuery=collide~=false
	p.Transparency=transparency or 0
	return p
end

local function box(parent:Instance,name:string,size:Vector3,pos:Vector3,material:Enum.Material,color:Color3,collide:boolean?)
	return part(parent,name,size,CFrame.new(pos),material,color,collide)
end

local function neon(parent:Instance,name:string,size:Vector3,pos:Vector3,color:Color3)
	return part(parent,name,size,CFrame.new(pos),Enum.Material.Neon,color,false,.04)
end

local function destructible(parent:Instance,name:string,size:Vector3,pos:Vector3,color:Color3,hp:number)
	local p=box(parent,name,size,pos,Enum.Material.Concrete,color,true)
	p:SetAttribute("DestructibleMaxHP",hp)
	p:SetAttribute("DestructibleHP",hp)
	p:SetAttribute("DestructibleOriginalSize",size)
	CollectionService:AddTag(p,"CBS_Destructible")
	return p
end

local function sidewalk(parent:Instance,name:string,size:Vector3,pos:Vector3)
	box(parent,name,size,pos,Enum.Material.Concrete,Color3.fromRGB(83,88,97),true)
end

local function road(parent:Instance,name:string,size:Vector3,pos:Vector3)
	box(parent,name,size,pos,Enum.Material.Asphalt,Color3.fromRGB(25,28,34),true)
end

local function lane(parent:Instance,name:string,size:Vector3,pos:Vector3)
	box(parent,name,size,pos,Enum.Material.SmoothPlastic,Color3.fromRGB(218,223,229),false)
end

local function lamp(parent:Instance,pos:Vector3,index:number,color:Color3?)
	box(parent,"LampPole_"..index,Vector3.new(.9,12,.9),pos+Vector3.new(0,6,0),Enum.Material.Metal,Color3.fromRGB(55,59,68),true)
	neon(parent,"LampHead_"..index,Vector3.new(2.6,.34,2.6),pos+Vector3.new(0,12,0),color or Color3.fromRGB(223,235,255))
end

local function tree(parent:Instance,pos:Vector3,index:number)
	box(parent,"TreeTrunk_"..index,Vector3.new(1.7,7,1.7),pos+Vector3.new(0,3.5,0),Enum.Material.Wood,Color3.fromRGB(91,60,42),true)
	local crown=box(parent,"TreeCrown_"..index,Vector3.new(10,9,10),pos+Vector3.new(0,9,0),Enum.Material.Grass,Color3.fromRGB(34,112,72),false)
	crown.Shape=Enum.PartType.Ball
end

local function sign(parent:Instance,name:string,pos:Vector3,textValue:string,color:Color3)
	box(parent,name.."_Post",Vector3.new(.45,5,.45),pos+Vector3.new(0,2.5,0),Enum.Material.Metal,Color3.fromRGB(55,59,67),true)
	local board=box(parent,name.."_Board",Vector3.new(10,3,.4),pos+Vector3.new(0,5.4,0),Enum.Material.SmoothPlastic,Color3.fromRGB(22,27,35),true)
	local surface=Instance.new("SurfaceGui")
	surface.Face=Enum.NormalId.Front
	surface.LightInfluence=0
	surface.Parent=board
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Font=Enum.Font.GothamBold
	label.Text=textValue
	label.TextSize=12
	label.TextColor3=color
	label.TextScaled=true
	label.Parent=surface
end

local function window(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3)
	neon(parent,name,size,pos,color)
end

local function building(parent:Instance,name:string,pos:Vector3,size:Vector3,accent:Color3,style:number,breakable:boolean)
	box(parent,name,size,Vector3.new(pos.X,pos.Y+size.Y/2,pos.Z),Enum.Material.Concrete,Color3.fromRGB(49+style*4,54+style*4,63+style*3),true)
	box(parent,name.."_Roof",Vector3.new(size.X+2,1.2,size.Z+2),Vector3.new(pos.X,pos.Y+size.Y+.6,pos.Z),Enum.Material.Metal,Color3.fromRGB(28,32,39),true)
	for floor=1,math.max(2,math.floor(size.Y/12)),2 do
		local y=pos.Y+6+(floor-1)*11
		local cols=3
		for col=1,cols do
			local x=pos.X-size.X/2+6+(col-1)*(size.X-12)/math.max(1,cols-1)
			local wcol=rng:NextNumber()<.48 and accent or Color3.fromRGB(61,78,92)
			window(parent,name.."_F_"..floor.."_"..col,Vector3.new(4.3,3,.16),Vector3.new(x,y,pos.Z-size.Z/2-.16),wcol)
			if floor%2==0 then
				window(parent,name.."_B_"..floor.."_"..col,Vector3.new(4.3,3,.16),Vector3.new(x,y,pos.Z+size.Z/2+.16),wcol)
			end
		end
	end
	if breakable then
		destructible(parent,name.."_Barrier",Vector3.new(math.min(size.X*.55,18),5,1.2),Vector3.new(pos.X,pos.Y+3,-size.Z/2-1.2),Color3.fromRGB(107,112,120),28)
	end
end

local function storefront(parent:Instance,name:string,pos:Vector3,accent:Color3,labelText:string)
	box(parent,name.."_Shell",Vector3.new(38,18,28),Vector3.new(pos.X,9,pos.Z),Enum.Material.Concrete,Color3.fromRGB(70,74,83),true)
	local signPart=box(parent,name.."_Sign",Vector3.new(28,3,.4),Vector3.new(pos.X,14,pos.Z-14.3),Enum.Material.SmoothPlastic,Color3.fromRGB(22,26,34),true)
	local gui=Instance.new("SurfaceGui")
	gui.Face=Enum.NormalId.Front
	gui.LightInfluence=0
	gui.Parent=signPart
	local label=Instance.new("TextLabel")
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Font=Enum.Font.GothamBlack
	label.Text=labelText
	label.TextColor3=accent
	label.TextScaled=true
	label.Parent=gui
	neon(parent,name.."_Door",Vector3.new(6,10,.22),Vector3.new(pos.X,5.5,pos.Z-14.5),Color3.fromRGB(54,88,108))
	for x=-10,10,20 do
		neon(parent,name.."_Window_"..x,Vector3.new(7,5,.18),Vector3.new(pos.X+x,8.5,pos.Z-14.55),accent)
	end
	destructible(parent,name.."_FrontBarrier",Vector3.new(26,2,1),Vector3.new(pos.X,1.3,pos.Z-15.2),Color3.fromRGB(92,96,104),20)
end

local function streetCluster(parent:Instance,baseX:number,index:number,node:any)
	local accent=node.Color
	for z=-112,112,224 do
		sidewalk(parent,"Sidewalk_"..index.."_"..z,Vector3.new(230,1.5,18),Vector3.new(baseX,1.1,z))
	end
	for x=-86,86,86 do
		road(parent,"CrossRoad_"..index.."_"..x,Vector3.new(38,1.1,230),Vector3.new(baseX+x,0,0))
	end
	for x=-95,95,95 do
		lamp(parent,Vector3.new(baseX+x,0,22),index*20+math.abs(x))
		lamp(parent,Vector3.new(baseX+x,0,-22),index*30+math.abs(x))
	end
	tree(parent,Vector3.new(baseX-82,0,102),index*100+1)
	tree(parent,Vector3.new(baseX+82,0,102),index*100+2)
	tree(parent,Vector3.new(baseX-82,0,-102),index*100+3)
	tree(parent,Vector3.new(baseX+82,0,-102),index*100+4)
	sign(parent,"StreetSign_"..index,Vector3.new(baseX-102,0,-8),node.Name,accent)
end

local function station(parent:Instance,baseX:number,node:any)
	local accent=node.Color
	box(parent,"MetroStation",Vector3.new(105,10,62),Vector3.new(baseX,5,-92),Enum.Material.Concrete,Color3.fromRGB(42,48,58),true)
	box(parent,"MetroCanopy",Vector3.new(96,1.5,48),Vector3.new(baseX,11,-92),Enum.Material.Glass,Color3.fromRGB(73,96,112),false,.32)
	for x=-38,38,19 do neon(parent,"MetroLight_"..x,Vector3.new(4,.3,2),Vector3.new(baseX+x,9,-60),accent) end
	for i=-2,2 do
		lane(parent,"PlatformEdge_"..i,Vector3.new(18,.12,2),Vector3.new(baseX+i*20,.8,-122))
	end
	for i=1,10 do
		destructible(parent,"MetroBarrier_"..i,Vector3.new(8,4,1),Vector3.new(baseX-45+(i-1)*10,2,-125),Color3.fromRGB(109,115,124),18)
	end
	sign(parent,"MetroSign",Vector3.new(baseX,0,-58),"METRO ROW",accent)
end

local function towers(parent:Instance,baseX:number,node:any)
	local accent=node.Color
	local left=Vector3.new(baseX-44,0,82)
	local right=Vector3.new(baseX+44,0,82)
	building(parent,"CoreTowerA",left,Vector3.new(58,122,54),accent,4,true)
	building(parent,"CoreTowerB",right,Vector3.new(58,122,54),Color3.fromRGB(115,213,255),5,true)
	box(parent,"CoreSkyBridge",Vector3.new(36,8,54),Vector3.new(baseX,84,82),Enum.Material.Metal,Color3.fromRGB(35,40,48),true)
	for i=1,6 do
		window(parent,"BridgeWindow_"..i,Vector3.new(5,4,.2),Vector3.new(baseX-12+(i-1)*5,84,54),accent)
	end
	for z=-5,45,10 do
		local ladderA=Instance.new("TrussPart")
		ladderA.Name="TowerLadderA_"..z
		ladderA.Size=Vector3.new(3,10,2)
		ladderA.CFrame=CFrame.new(baseX-14,5+z,55)
		ladderA.Anchored=true
		ladderA.Color=Color3.fromRGB(72,77,85)
		ladderA.Parent=parent
		local ladderB=ladderA:Clone()
		ladderB.Name="TowerLadderB_"..z
		ladderB.CFrame=CFrame.new(baseX+14,5+z,55)
		ladderB.Parent=parent
	end
end

local function market(parent:Instance,baseX:number,node:any)
	local accent=node.Color
	for row=-1,1,2 do
		for col=-2,2,2 do
			local pos=Vector3.new(baseX+col*22,0,row*34-5)
			box(parent,"MarketStall_"..row.."_"..col,Vector3.new(18,7,14),Vector3.new(pos.X,3.5,pos.Z),Enum.Material.Wood,Color3.fromRGB(88,63,44),true)
			box(parent,"MarketRoof_"..row.."_"..col,Vector3.new(20,1,16),Vector3.new(pos.X,8,pos.Z),Enum.Material.Metal,Color3.fromRGB(41,45,53),true)
			neon(parent,"MarketSign_"..row.."_"..col,Vector3.new(10,1.2,.3),Vector3.new(pos.X,7.2,pos.Z-7.2),accent)
		end
	end
	for i=1,8 do
		destructible(parent,"MarketCrate_"..i,Vector3.new(7,7,7),Vector3.new(baseX+rng:NextInteger(-62,62),3.5,rng:NextInteger(-115,115)),Color3.fromRGB(117,84,52),16)
	end
end

local function apex(parent:Instance,baseX:number,node:any)
	local accent=node.Color
	box(parent,"ApexDeck",Vector3.new(170,2,130),Vector3.new(baseX,6,0),Enum.Material.Metal,Color3.fromRGB(39,44,52),true)
	for x=-65,65,32.5 do
		neon(parent,"ApexRail_"..x,Vector3.new(20,.5,.5),Vector3.new(baseX+x,8,-58),accent)
		neon(parent,"ApexRailBack_"..x,Vector3.new(20,.5,.5),Vector3.new(baseX+x,8,58),accent)
	end
	for i=1,6 do
		local truss=Instance.new("TrussPart")
		truss.Name="ApexAccess_"..i
		truss.Size=Vector3.new(3,30,2)
		truss.CFrame=CFrame.new(baseX-78+(i-1)*31,21,60)
		truss.Anchored=true
		truss.Color=Color3.fromRGB(63,68,76)
		truss.Parent=parent
	end
	for i=1,10 do
		destructible(parent,"ApexCover_"..i,Vector3.new(8,6,3),Vector3.new(baseX+rng:NextInteger(-70,70),9,rng:NextInteger(-48,48)),Color3.fromRGB(83,87,96),22)
	end
	sign(parent,"ApexSign",Vector3.new(baseX,0,0),"APEX YARD",accent)
end

local function origin(parent:Instance,baseX:number,node:any)
	local accent=node.Color
	box(parent,"OriginCourt",Vector3.new(170,1,135),Vector3.new(baseX,.5,0),Enum.Material.Slate,Color3.fromRGB(43,48,57),true)
	for angle=0,315,45 do
		local rad=math.rad(angle)
		local pos=Vector3.new(baseX+math.cos(rad)*52,1.2,math.sin(rad)*42)
		neon(parent,"OriginBeacon_"..angle,Vector3.new(3,.3,3),pos,accent)
	end
	for i=1,6 do
		destructible(parent,"OriginBarrier_"..i,Vector3.new(14,5,1),Vector3.new(baseX-58+i*20,3,-54),Color3.fromRGB(98,103,112),18)
	end
	sign(parent,"OriginSign",Vector3.new(baseX,0,52),"ORIGIN PLAZA",accent)
end

local function district(parent:Instance,node:any,index:number)
	local x=node.Position.X
	streetCluster(parent,x,index,node)
	if node.Id=="Origin" then
		origin(parent,x,node)
	elseif node.Id=="Metro" then
		station(parent,x,node)
		storefront(parent,"MetroCafe",Vector3.new(x-52,0,92),Color3.fromRGB(244,168,89),"NOVA CAFE")
		storefront(parent,"MetroStore",Vector3.new(x+52,0,92),node.Color,"ROW MART")
	elseif node.Id=="Core" then
		towers(parent,x,node)
		storefront(parent,"CoreArcade",Vector3.new(x-62,0,-100),node.Color,"VECTOR")
		storefront(parent,"CoreDiner",Vector3.new(x+62,0,-100),Color3.fromRGB(244,168,89),"NIGHT BITES")
	elseif node.Id=="Iron" then
		market(parent,x,node)
		storefront(parent,"IronWorkshop",Vector3.new(x-58,0,98),node.Color,"FORGE WORKS")
		storefront(parent,"IronDepot",Vector3.new(x+58,0,98),node.Color,"IRON DEPOT")
	else
		apex(parent,x,node)
		storefront(parent,"ApexGarage",Vector3.new(x-58,0,-96),node.Color,"APEX GARAGE")
		storefront(parent,"ApexClub",Vector3.new(x+58,0,-96),Color3.fromRGB(180,112,255),"RIFT CLUB")
	end

	for side=-1,1,2 do
		for slot=-1,1,2 do
			local px=x+slot*70
			local pz=side*145
			local height=rng:NextInteger(30,68)
			local accent=node.Color
			building(parent,node.Id.."_Building_"..side.."_"..slot,Vector3.new(px,0,pz),Vector3.new(rng:NextInteger(36,54),height,rng:NextInteger(30,46)),accent,index,false)
		end
	end
end

local function roads(parent:Instance)
	road(parent,"MainArterial",Vector3.new(Config.Map.Width,1.2,64),Vector3.new(0,0,0))
	road(parent,"NorthArterial",Vector3.new(Config.Map.Width,1.2,44),Vector3.new(0,0,185))
	road(parent,"SouthArterial",Vector3.new(Config.Map.Width,1.2,44),Vector3.new(0,0,-185))
	for x=-520,520,130 do
		task.wait()
		for z=-28,28,56 do
			sidewalk(parent,"MainSidewalk_"..x.."_"..z,Vector3.new(112,1.4,10),Vector3.new(x,1.15,z+math.sign(z)*38))
		end
		lane(parent,"LaneMark_"..x,Vector3.new(22,.12,1.2),Vector3.new(x,1,0))
		if x<520 then
			lane(parent,"CenterMark_"..x,Vector3.new(22,.12,1.2),Vector3.new(x+10,1,0))
		end
	end
	for i,x in ipairs({-390,-260,-130,0,130,260,390}) do
		for laneIndex=-2,2 do
			lane(parent,"Crosswalk_"..i.."_"..laneIndex,Vector3.new(3,.12,28),Vector3.new(x+laneIndex*5,1,0))
		end
	end
end

local function lighting()
	local bloom=Lighting:FindFirstChild("CSBBloom")
	if bloom then bloom:Destroy() end
	Lighting.ClockTime=18.35
	Lighting.Brightness=2.0
	Lighting.GlobalShadows=true
	Lighting.EnvironmentDiffuseScale=.72
	Lighting.EnvironmentSpecularScale=.58
	Lighting.Ambient=Color3.fromRGB(52,58,73)
	Lighting.OutdoorAmbient=Color3.fromRGB(66,72,88)
	local atmosphere=Lighting:FindFirstChild("CBSAtmosphere")
	if not atmosphere then
		atmosphere=Instance.new("Atmosphere")
		atmosphere.Name="CBSAtmosphere"
		atmosphere.Parent=Lighting
	end
	atmosphere.Density=.14
	atmosphere.Offset=.08
	atmosphere.Color=Color3.fromRGB(122,139,170)
	atmosphere.Decay=Color3.fromRGB(46,56,76)
	atmosphere.Glare=.05
	atmosphere.Haze=.35
	local bloom=Lighting:FindFirstChild("CSBBloom")
	if not bloom then
		bloom=Instance.new("BloomEffect")
		bloom.Name="CSBBloom"
		bloom.Parent=Lighting
	end
	local color=Lighting:FindFirstChild("CBSColor")
	if not color then
		color=Instance.new("ColorCorrectionEffect")
		color.Name="CBSColor"
		color.Parent=Lighting
	end
	color.Brightness=-.02
	color.Contrast=.10
	color.Saturation=-.04
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
	local geometry=Instance.new("Folder")
	geometry.Name="Architecture"
	geometry.Parent=map

	box(map,"WorldGround",Vector3.new(Config.Map.Width,2,Config.Map.Depth),Vector3.new(0,-2,0),Enum.Material.Grass,Color3.fromRGB(40,44,46),true)
	roads(geometry)
	task.wait()

	for index,id in ipairs(Routes.Order) do
		local node=Routes.Nodes[id]
		if not node then error("Missing route node: "..id) end
		district(geometry,node,index)
		task.wait()
	end

	for index,id in ipairs(Routes.Order) do
		local node=Routes.Nodes[id]
		local spawn=Instance.new("SpawnLocation")
		spawn.Name="BattleSpawn_"..index
		spawn.Size=Vector3.new(9,1,9)
		spawn.CFrame=CFrame.new(node.Spawn,node.Spawn+Vector3.new(1,0,0))
		spawn.Anchored=true
		spawn.Neutral=true
		spawn.Duration=0
		spawn.Transparency=1
		spawn.CanCollide=true
		spawn.CanTouch=false
		spawn.CanQuery=false
		spawn.Parent=spawns
	end

	sign(map,"CityNorthSign",Vector3.new(0,0,342),"BATTLE LINE",Color3.fromRGB(94,205,255))
	newRoot:SetAttribute("MapVersion",Routes.Version)
	newRoot:SetAttribute("MapLoaded",true)
	newRoot:SetAttribute("DestructionSystem","CBS_v1")
	lighting()
	return newRoot
end

local function verify(newRoot:Folder):boolean
	local map=newRoot:FindFirstChild("Map")
	local spawns=newRoot:FindFirstChild("Spawns")
	if not map or not spawns then return false end
	local count=0
	for _,id in ipairs(Routes.Order) do
		if map:FindFirstChild("Architecture") and map.Architecture:FindFirstChild(id.."_Building_-1_-1") or false then end
		if map:FindFirstChild("Architecture") then
			local found=false
			for _,d in ipairs(map.Architecture:GetChildren()) do
				if string.sub(d.Name,1,#id)==id then found=true break end
			end
			if found then count+=1 end
		end
	end
	local spawnCount=0
	for _,item in ipairs(spawns:GetChildren()) do if item:IsA("SpawnLocation") then spawnCount+=1 end end
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
	return true
end

function S.Verify():boolean
	return root~=nil and root.Parent==workspace and verify(root)
end

function S.GetRoot():Folder? return root end
return S
