--!strict
local CollectionService=game:GetService("CollectionService")
local U=require(game.ReplicatedStorage.Shared.Util)

local M={}
local state:any=nil

local function requireState():any
	if not state then error("MapContext is not initialized") end
	return state
end

function M.Init(data:any)
	state=data
end

function M.Get():any
	return requireState()
end

function M.Folder(name:string):Folder
	local s=requireState()
	local f=Instance.new("Folder")
	f.Name=name
	f.Parent=s.root
	return f
end

function M.Part(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3,collide:boolean?,query:boolean?):Part
	local p=U.Part(parent,name,size,cf,material,color,true)
	p.CanCollide=collide~=false
	p.CanTouch=false
	p.CanQuery=query~=false
	return p
end

function M.Tag(instance:Instance,name:string)
	CollectionService:AddTag(instance,name)
end

function M.Marker(parent:Instance,name:string,pos:Vector3,size:Vector3,regionId:string):BasePart
	local p=M.Part(parent,name,size,CFrame.new(pos),Enum.Material.ForceField,Color3.new(1,1,1),false,false)
	p.Transparency=1
	p:SetAttribute("RegionId",regionId)
	return p
end

function M.Region(id:string,center:Vector3,size:Vector3)
	local s=requireState()
	local p=M.Marker(s.regionVolumes,id,center,size,id)
	p:SetAttribute("CollisionState","Stable")
	p:SetAttribute("StateSource","GlobalFractureDistrict")
end

function M.NeonStrip(parent:Instance,name:string,pos:Vector3,size:Vector3,rotation:number,color:Color3)
	local p=M.Part(parent,name,size,CFrame.new(pos)*CFrame.Angles(0,math.rad(rotation),0),Enum.Material.Neon,color,false,false)
	p.CanTouch=false
	return p
end

function M.DestructibleProp(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3):Part
	local p=M.Part(parent,name,size,CFrame.new(pos),Enum.Material.Metal,color,true,true)
	M.Tag(p,"CombatDestructible")
	p:SetAttribute("RestoreSeconds",6)
	return p
end

function M.CreateSpawn(index:number,pos:Vector3):SpawnLocation
	local s=Instance.new("SpawnLocation")
	s.Name=("CollisionSpawn_%d"):format(index)
	s.Size=Vector3.new(10,1,10)
	s.CFrame=CFrame.new(pos)
	s.Anchored=true
	s.CanCollide=true
	s.CanTouch=false
	s.CanQuery=false
	s.Transparency=1
	s.Material=Enum.Material.Neon
	s.Neutral=true
	s.AllowTeamChangeOnTouch=false
	s.Duration=0
	s.Enabled=true
	s.Parent=workspace
	return s
end

function M.AddBreakPart(part:BasePart)
	table.insert(requireState().breakParts,part)
end

function M.SetBossArena(position:Vector3)
	requireState().bossArena=position
end

function M.SetEventAnchor(position:Vector3)
	requireState().eventAnchor=position
end

function M.SetSpawns(points:{Vector3})
	requireState().spawns=table.clone(points)
end

return M
