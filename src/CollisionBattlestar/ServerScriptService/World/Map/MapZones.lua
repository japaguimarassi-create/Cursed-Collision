--!strict
local T=require(script.Parent.MapContext)
local G=require(script.Parent.MapArchitecture)
local Routes=require(game.ReplicatedStorage.Shared.MapRouteDefinitions)
local M={}
function M.Build(parent:Instance)
	for _,id in ipairs(Routes.Order)do
		local node=Routes.Nodes[id]
		G.BuildZoneShell(parent,node)
		G.BuildLandmark(parent,id)
		for _,offset in ipairs({Vector3.new(-82,0,88),Vector3.new(82,0,88),Vector3.new(-82,0,-88),Vector3.new(82,0,-88)})do
			local height=18+((#id*3)%17)
			local b=T.Part(parent,node.Id.."_Block",Vector3.new(42,height,34),CFrame.new(node.Position+offset+Vector3.new(0,height/2,0)),Enum.Material.Brick,Color3.fromRGB(73,77,88),true,true,false)
			b:SetAttribute("RegionId",node.Id)
			T.Tag(b,"EnvironmentStatic")
		end
	end
	local spawns={}
	for _,id in ipairs(Routes.Order)do table.insert(spawns,Routes.Nodes[id].Spawn)end
	T.Get().spawns=spawns
end
return M
