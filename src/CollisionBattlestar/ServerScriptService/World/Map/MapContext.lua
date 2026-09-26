--!strict
local CollectionService=game:GetService("CollectionService")
local U=require(game.ReplicatedStorage.Shared.Util)
local M={}
local state:any=nil
function M.Init(data:any)state=data end
function M.Get():any if not state then error("MapContext is not initialized")end;return state end
function M.Part(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3,collide:boolean?,query:boolean?,touch:boolean?):Part local p=U.Part(parent,name,size,cf,material,color,true);p.CanCollide=collide~=false;p.CanQuery=query~=false;p.CanTouch=touch==true;return p end
function M.Decor(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3):Part local p=M.Part(parent,name,size,cf,material,color,false,false,false);p.CastShadow=false;return p end
function M.Tag(instance:Instance,tag:string)CollectionService:AddTag(instance,tag)end
function M.Destructible(parent:Instance,name:string,pos:Vector3,size:Vector3,color:Color3):Part local p=M.Part(parent,name,size,CFrame.new(pos),Enum.Material.Concrete,color,true,true,false);M.Tag(p,"CombatDestructible");p:SetAttribute("RestoreSeconds",6);return p end
return M
