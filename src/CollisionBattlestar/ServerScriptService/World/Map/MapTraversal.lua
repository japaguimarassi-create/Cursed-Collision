--!strict
local T=require(script.Parent.MapContext)
local G=require(script.Parent.MapArchitecture)
local Routes=require(game.ReplicatedStorage.Shared.MapRouteDefinitions)
local M={}
function M.Build(parent:Instance)
	G.BuildRoads(parent)
	T.Part(parent,"UndergroundFloor",Vector3.new(1540,1,44),CFrame.new(0,-20,0),Enum.Material.Concrete,Color3.fromRGB(38,41,49),true,true,false)
	T.Part(parent,"UndergroundRoof",Vector3.new(1540,1,44),CFrame.new(0,6,0),Enum.Material.Concrete,Color3.fromRGB(29,32,39),true,true,false)
	for x=-720,720,120 do T.Decor(parent,"TunnelStrip",Vector3.new(6,.4,36),CFrame.new(x,4.5,0),Enum.Material.Neon,Routes.Nodes.Core.Color)end
	T.Part(parent,"SkyRoute",Vector3.new(1600,2,18),CFrame.new(0,58,0),Enum.Material.Metal,Color3.fromRGB(36,41,51),true,true,false)
	for x=-760,760,80 do T.Decor(parent,"SkyStrip",Vector3.new(36,.3,2),CFrame.new(x,59,0),Enum.Material.Neon,Routes.Nodes.Sky.Color)end
	T.SetBossArena(Routes.Nodes.Apex.Position+Vector3.new(0,3,34))
	T.SetEventAnchor(Routes.Nodes.Core.Position+Vector3.new(0,6,0))
end
return M
