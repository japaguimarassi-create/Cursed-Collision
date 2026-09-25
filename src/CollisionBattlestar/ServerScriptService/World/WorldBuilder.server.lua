--!strict
local Lighting=game:GetService("Lighting")
local R=game:GetService("ReplicatedStorage")
local C=require(R.Shared.Config)
local BuildInfo=require(R.Shared.BuildInfo)
local T=require(script.Parent.World.Map.MapContext)

local S={}
local root:Folder?
local breakParts:{BasePart}={}
local spawns:{Vector3}={}
local bossArena=Vector3.new(0,2,-312)
local eventAnchor=Vector3.new(0,6,-286)
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

function S.Init()
	if root then return end
	root=Instance.new("Folder")
	root.Name="CollisionBattlestarWorld"
	root.Parent=workspace
	local environment=Instance.new("Folder");environment.Name="Environment";environment.Parent=root
	local gameplay=Instance.new("Folder");gameplay.Name="Gameplay";gameplay.Parent=root
	local landmarks=Instance.new("Folder");landmarks.Name="Landmarks";landmarks.Parent=root
	local regionVolumes=Instance.new("Folder");regionVolumes.Name="RegionVolumes";regionVolumes.Parent=root

	T.Init({
		root=root,
		environment=environment,
		gameplay=gameplay,
		landmarks=landmarks,
		regionVolumes=regionVolumes,
		breakParts=breakParts,
		spawns=spawns,
		bossArena=bossArena,
		eventAnchor=eventAnchor,
		PALETTE=PALETTE,
		Config=C,
	})

	local Districts=require(script.Parent.World.Map.MapDistricts)
	local Gameplay=require(script.Parent.World.Map.MapGameplay)

	workspace:SetAttribute("CollisionBattlestarMapReady",false)
	workspace:SetAttribute("CollisionBattlestarMapError","")
	workspace:SetAttribute("CollisionBattlestarBuild",BuildInfo.BuildTag)
	workspace:SetAttribute("CollisionBattlestarBuildVersion",BuildInfo.Version)
	workspace:SetAttribute("CollisionBattlestarPlaceVersion",game.PlaceVersion)

	for index,offset in ipairs({
		Vector3.new(0,0,0),Vector3.new(20,0,0),Vector3.new(-20,0,0),
		Vector3.new(0,0,20),Vector3.new(0,0,-20),Vector3.new(20,0,20),
		Vector3.new(-20,0,20),Vector3.new(20,0,-20),Vector3.new(-20,0,-20),
	})do
		T.CreateSpawn(index,C.Region.Spawn+offset-Vector3.new(0,4.5,0))
	end

	local ok,err=pcall(function()
		Districts.Build()
		Gameplay.Build()
	end)
	if not ok then
		workspace:SetAttribute("CollisionBattlestarMapError",tostring(err))
		workspace:SetAttribute("CollisionBattlestarMapReady",false)
		error(err)
	end

	bossArena=T.Get().bossArena
	eventAnchor=T.Get().eventAnchor
	spawns=T.Get().spawns

	Lighting.EnvironmentDiffuseScale=.65
	Lighting.EnvironmentSpecularScale=.85
	Lighting.ClockTime=17.5
	Lighting.Brightness=2.2
	Lighting.GlobalShadows=true

	workspace:SetAttribute("CollisionBattlestarMap","FractureDistrict_v3")
	workspace:SetAttribute("MapBounds",480)
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
	for _,p in ipairs(T.Get().breakParts)do
		if p.Parent then
			p.Material=active and Enum.Material.Neon or Enum.Material.Concrete
			p.Color=active and PALETTE.Rift or Color3.fromRGB(105,110,115)
		end
	end
end

return S
