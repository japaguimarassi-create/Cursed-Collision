--!strict
local Lighting=game:GetService("Lighting")
local R=game:GetService("ReplicatedStorage")
local C=require(R.Shared.Config)
local BuildInfo=require(R.Shared.BuildInfo)
local Routes=require(R.Shared.MapRouteDefinitions)
local T=require(script.Parent.World.Map.MapContext)

local S={}
local root:Folder?
local bossArena=Routes.Nodes.Apex.Position+Vector3.new(0,3,34)
local eventAnchor=Routes.Nodes.Core.Position+Vector3.new(0,6,0)

local function cleanup()
	local old=workspace:FindFirstChild("CollisionBattlestarWorld")
	if old then old:Destroy()end
	for _,item in ipairs(workspace:GetChildren())do
		if item:IsA("SpawnLocation")and item.Name:sub(1,15)=="CollisionSpawn_"then item:Destroy()end
	end
end

local function spawnPoint(index:number,pos:Vector3):SpawnLocation
	local s=Instance.new("SpawnLocation")
	s.Name=("CollisionSpawn_%d"):format(index)
	s.Size=Vector3.new(10,1,10)
	s.CFrame=CFrame.new(pos)
	s.Anchored=true
	s.CanCollide=true
	s.CanTouch=false
	s.CanQuery=false
	s.Transparency=1
	s.Neutral=true
	s.Duration=0
	s.Parent=workspace
	return s
end

function S.Init()
	if root then return end
	cleanup()
	root=Instance.new("Folder")
	root.Name="CollisionBattlestarWorld"
	root.Parent=workspace

	local environment=Instance.new("Folder")
	environment.Name="Environment"
	environment.Parent=root

	local gameplay=Instance.new("Folder")
	gameplay.Name="Gameplay"
	gameplay.Parent=root

	local landmarks=Instance.new("Folder")
	landmarks.Name="Landmarks"
	landmarks.Parent=root

	local route=Instance.new("Folder")
	route.Name="BattleRoute"
	route.Parent=root

	local regionVolumes=Instance.new("Folder")
	regionVolumes.Name="RegionVolumes"
	regionVolumes.Parent=root

	T.Init({
		root=root,
		environment=environment,
		gameplay=gameplay,
		landmarks=landmarks,
		route=route,
		regionVolumes=regionVolumes,
		spawns={},
		breakParts={},
		bossArena=bossArena,
		eventAnchor=eventAnchor,
		Config=C
	})

	local Zones=require(script.Parent.World.Map.MapZones)
	local Traversal=require(script.Parent.World.Map.MapTraversal)

	workspace:SetAttribute("CollisionBattlestarMapReady",false)
	workspace:SetAttribute("CollisionBattlestarMapError","")
	workspace:SetAttribute("CollisionBattlestarBuild",BuildInfo.BuildTag)
	workspace:SetAttribute("CollisionBattlestarBuildVersion",BuildInfo.Version)
	workspace:SetAttribute("CollisionBattlestarPlaceVersion",game.PlaceVersion)
	workspace:SetAttribute("CollisionBattlestarMapVersion",Routes.Version)

	local ok,err=pcall(function()
		Zones.Build(environment)
		Traversal.Build(route)
	end)

	if not ok then
		workspace:SetAttribute("CollisionBattlestarMapError",tostring(err))
		error(err)
	end

	for index,id in ipairs(Routes.Order)do
		spawnPoint(index,Routes.Nodes[id].Spawn)
	end

	bossArena=T.Get().bossArena
	eventAnchor=T.Get().eventAnchor

	Lighting.ClockTime=17.5
	Lighting.Brightness=2.2
	Lighting.EnvironmentDiffuseScale=.65
	Lighting.EnvironmentSpecularScale=.85
	Lighting.GlobalShadows=true

	workspace:SetAttribute("CollisionBattlestarMap","BattleLine_v1")
	workspace:SetAttribute("MapBounds",850)
	workspace:SetAttribute("BattleRouteNodes",#Routes.Order)
	workspace:SetAttribute("BossArenaPosition",bossArena)
	workspace:SetAttribute("CollisionBattlestarMapReady",true)
	workspace:SetAttribute("CollisionBattlestarMapError","")
end

function S.GetSpawnPoints():{Vector3}
	return T.Get().spawns
end

function S.GetBossArena():Vector3
	return T.Get().bossArena
end

function S.GetEventAnchor():Vector3
	return T.Get().eventAnchor
end

function S.AnimateRealityBreak(active:boolean)
	for _,p in ipairs(T.Get().breakParts or {})do
		if p.Parent then
			p.Material=active and Enum.Material.Neon or Enum.Material.Concrete
			p.Color=active and Color3.fromRGB(197,92,255) or Color3.fromRGB(105,110,115)
		end
	end
end

return S
