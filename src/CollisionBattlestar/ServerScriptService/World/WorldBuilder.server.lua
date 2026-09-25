--!strict
local CollectionService=game:GetService("CollectionService");local R=game:GetService("ReplicatedStorage");local C=require(R.Shared.Config);local U=require(R.Shared.Util)
local S={};local world:Folder?;local spawns:{Vector3}={};local breakParts:{BasePart}={};local bossArena=Vector3.new(0,5,-110)
local function building(parent:Instance,pos:Vector3,size:Vector3,color:Color3,name:string)
	local body=U.Part(parent,name,size,CFrame.new(pos+Vector3.new(0,size.Y*.5,0)),Enum.Material.Concrete,color,true);CollectionService:AddTag(body,"SelectiveDestruction")
	local count=math.max(2,math.floor(size.X/9));for i=1,count do local x=-size.X*.5+i*(size.X/(count+1));local w=U.Part(parent,name.."_Window"..i,Vector3.new(2.2,3,.4),CFrame.new(pos+Vector3.new(x,size.Y*.62,-size.Z*.5-.25)),Enum.Material.Glass,Color3.fromRGB(55,80,110),true);w.CanCollide=false end
end
function S.Init()
	if world then return end;world=Instance.new("Folder");world.Name="CBSWorld";world.Parent=workspace
	local env=Instance.new("Folder");env.Name="Environment";env.Parent=world;local landmarks=Instance.new("Folder");landmarks.Name="Landmarks";landmarks.Parent=world
	U.Part(env,"Ground",Vector3.new(500,2,500),CFrame.new(0,-1,0),Enum.Material.Concrete,Color3.fromRGB(70,75,82),true)
	U.Part(env,"MainRoad",Vector3.new(500,1,34),CFrame.new(0,.1,0),Enum.Material.Asphalt,Color3.fromRGB(35,37,44),true);U.Part(env,"WestRoad",Vector3.new(28,1,500),CFrame.new(-95,.15,0),Enum.Material.Asphalt,Color3.fromRGB(35,37,44),true);U.Part(env,"EastRoad",Vector3.new(28,1,500),CFrame.new(95,.15,0),Enum.Material.Asphalt,Color3.fromRGB(35,37,44),true)
	for _,d in {{Vector3.new(-140,0,-120),Vector3.new(62,58,55),Color3.fromRGB(80,86,95),"BlockA"},{Vector3.new(-35,0,-155),Vector3.new(72,82,52),Color3.fromRGB(91,83,94),"BlockB"},{Vector3.new(65,0,-125),Vector3.new(70,46,58),Color3.fromRGB(76,90,103),"BlockC"},{Vector3.new(150,0,-55),Vector3.new(55,96,62),Color3.fromRGB(95,92,86),"BlockD"},{Vector3.new(-160,0,80),Vector3.new(62,66,54),Color3.fromRGB(85,90,100),"BlockE"},{Vector3.new(140,0,105),Vector3.new(78,55,68),Color3.fromRGB(89,84,78),"BlockF"}}do building(env,d[1],d[2],d[3],d[4])end
	U.Part(landmarks,"CollapsedMetro",Vector3.new(90,12,32),CFrame.new(0,6,-72),Enum.Material.Metal,Color3.fromRGB(50,55,65),true)
	local secret=U.Part(landmarks,"SecretDoor",Vector3.new(8,12,2),CFrame.new(0,6,-38),Enum.Material.Neon,Color3.fromRGB(85,255,195),true);CollectionService:AddTag(secret,"Interactable");local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Inspect";prompt.ObjectText="Unknown Door";prompt.HoldDuration=.4;prompt.MaxActivationDistance=9;prompt.Parent=secret
	local tower=U.Part(landmarks,"BrokenTower",Vector3.new(28,112,28),CFrame.new(115,56,15),Enum.Material.Concrete,Color3.fromRGB(64,68,75),true);local top=U.Part(landmarks,"TowerTop",Vector3.new(40,4,40),CFrame.new(115,114,15),Enum.Material.Neon,Color3.fromRGB(100,180,255),true);top.CanCollide=false;table.insert(breakParts,top)
	local center=U.Part(landmarks,"RealityBreakCenter",Vector3.new(3,3,3),CFrame.new(C.Region.EventAnchor),Enum.Material.Neon,Color3.fromRGB(175,85,255),true);center.CanCollide=false;center.Parent=workspace;table.insert(breakParts,center)
	local rb=Instance.new("ProximityPrompt");rb.ActionText="Trigger Resonance";rb.ObjectText="Reality Break";rb.HoldDuration=1.2;rb.MaxActivationDistance=12;rb.Parent=center;rb.Triggered:Connect(function()require(game.ServerScriptService.Services.EventService).StartRealityBreak("ManualAnchor")end)
	spawns={Vector3.new(-70,4,55),Vector3.new(70,4,55),Vector3.new(-70,4,-30),Vector3.new(70,4,-30),Vector3.new(-150,4,10),Vector3.new(150,4,10),Vector3.new(-145,4,-165),Vector3.new(145,4,-165)}
	local arena=U.Part(landmarks,"BossArena",Vector3.new(150,2,100),CFrame.new(bossArena),Enum.Material.Slate,Color3.fromRGB(43,45,52),true);arena.Transparency=.2
	local spawn=Instance.new("SpawnLocation");spawn.Name="CollisionSpawn";spawn.Size=Vector3.new(8,1,8);spawn.Position=C.Region.Spawn;spawn.Anchored=true;spawn.Neutral=true;spawn.Parent=world
end
function S.GetSpawnPoints():{Vector3}return spawns end
function S.GetBossArena():Vector3 return bossArena end
function S.AnimateRealityBreak(active:boolean)for _,p in breakParts do if p.Parent then p.Material=active and Enum.Material.Neon or Enum.Material.Concrete;p.Color=active and Color3.fromRGB(175,85,255)or Color3.fromRGB(105,110,115)end end end
return S
