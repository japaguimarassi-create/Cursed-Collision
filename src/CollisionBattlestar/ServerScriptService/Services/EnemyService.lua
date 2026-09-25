--!strict
local Players=game:GetService("Players");local CollectionService=game:GetService("CollectionService");local C=require(game.ReplicatedStorage.Shared.Config);local U=require(game.ReplicatedStorage.Shared.Util)
local S={};S.Defeated=Instance.new("BindableEvent");local folder:Folder?;local active:{[Model]=boolean}={};local attackAt:{[Model]=number}={}
local function make(kind:string,pos:Vector3,boss:boolean):Model
	local d=C.Enemies[kind];local m=Instance.new("Model");m.Name=kind;m:SetAttribute("Archetype",kind);m:SetAttribute("LastHitUserId",0);m:SetAttribute("IsBoss",boss);m:SetAttribute("Phase",1)
	local root=U.Part(m,"HumanoidRootPart",Vector3.new(2.5,3,2.5),CFrame.new(pos),Enum.Material.Metal,d.Color,false);root.Transparency=1;root.CanCollide=false
	local core=U.Part(m,"Core",boss and Vector3.new(7,8,7)or Vector3.new(3.5,4,3.5),CFrame.new(pos+Vector3.new(0,2,0)),Enum.Material.Neon,d.Color,false)
	local head=U.Part(m,"Head",Vector3.new(2.2,2.2,2.2),CFrame.new(pos+Vector3.new(0,5,0)),Enum.Material.Neon,Color3.new(1,1,1),false);head.Shape=Enum.PartType.Ball;head.CanCollide=false
	local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=core;w.Parent=root;local w2=Instance.new("WeldConstraint");w2.Part0=core;w2.Part1=head;w2.Parent=core
	local h=Instance.new("Humanoid");h.MaxHealth=d.Health;h.Health=d.Health;h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.Parent=m
	U.Nameplate(core,kind,d.Color);m.PrimaryPart=root;CollectionService:AddTag(m,"CBSEnemy");m.Parent=folder;active[m]=true
	h.Died:Connect(function()if not active[m]then return end;active[m]=nil;S.Defeated:Fire(m,tonumber(m:GetAttribute("LastHitUserId"))or 0,kind,d.Reward);task.delay(2.5,function()if m.Parent then m:Destroy()end end)end)
	return m
end
function S.Init()
	folder=workspace:FindFirstChild("CBSEnemies")or Instance.new("Folder");folder.Name="CBSEnemies";folder.Parent=workspace
	task.spawn(function()while task.wait(.25)do for m in pairs(active)do
		local h=m:FindFirstChildOfClass("Humanoid");local root=m.PrimaryPart;local kind=m:GetAttribute("Archetype");local d=kind and C.Enemies[kind]
		if not m.Parent or not h or not root or not d then active[m]=nil;continue end;if h.Health<=0 then continue end
		local player=U.NearestPlayer(Players:GetPlayers(),root.Position,80)
		if player and player.Character then local tr=U.Root(player.Character);local th=U.Hum(player.Character);if tr and th and th.Health>0 then
			local delta=tr.Position-root.Position;local flat=Vector3.new(delta.X,0,delta.Z);local phase=(m:GetAttribute("IsBoss")and h.Health/h.MaxHealth<=.5)and 2 or 1;m:SetAttribute("Phase",phase);local speed=d.Speed*(phase==2 and 1.2 or 1)
			if flat.Magnitude>d.Range then if flat.Magnitude>.1 then m:PivotTo(CFrame.lookAt(root.Position+flat.Unit*math.min(speed*.25,flat.Magnitude),Vector3.new(tr.Position.X,root.Position.Y,tr.Position.Z)))end
			else local now=os.clock();if now-(attackAt[m]or 0)>=d.Cooldown then attackAt[m]=now;local parry=player:GetAttribute("ParryUntil")or 0;if now<=parry then player:SetAttribute("Momentum",U.Clamp((player:GetAttribute("Momentum")or 0)+10,0,100));game.ReplicatedStorage.CollisionRemotes.Feedback:FireClient(player,"ParrySuccess")else local block=player:GetAttribute("IsBlocking")==true;th:TakeDamage(d.Damage*(block and C.Combat.BlockMultiplier or 1)*(phase==2 and 1.15 or 1))end end end
		end end
	end end end)
end
function S.Spawn(kind:string,pos:Vector3):Model?if not folder or not C.Enemies[kind]then return nil end;return make(kind,pos,false)end
function S.SpawnMiniBoss(pos:Vector3):Model?if not folder then return nil end;return make("MiniBoss",pos,true)end
function S.SpawnBoss(pos:Vector3):Model?if not folder then return nil end;return make("Boss",pos,true)end
function S.CountAlive():number local n=0;for _ in pairs(active)do n+=1 end;return n end
return S
