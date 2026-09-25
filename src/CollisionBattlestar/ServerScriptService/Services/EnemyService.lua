--!strict
local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")
local C=require(game.ReplicatedStorage.Shared.Config)
local U=require(game.ReplicatedStorage.Shared.Util)
local Animation=require(script.Parent.AnimationService)
local Destruction=require(script.Parent.DestructionService)

local S={}
S.Defeated=Instance.new("BindableEvent")
local folder:Folder?
local active:{[Model]=boolean}={}
local attackAt:{[Model]=number}={}

local function limb(parent:Model,name:string,size:Vector3,pos:Vector3,color:Color3):Part
	local p=U.Part(parent,name,size,CFrame.new(pos),Enum.Material.Neon,color,false)
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=true
	p.Massless=true
	return p
end

local function joint(parent:Instance,name:string,a:BasePart,b:BasePart,c0:CFrame,c1:CFrame)
	local motor=Instance.new("Motor6D")
	motor.Name=name
	motor.Part0=a
	motor.Part1=b
	motor.C0=c0
	motor.C1=c1
	motor.Parent=parent
end

local function buildRig(model:Model,pos:Vector3,color:Color3,boss:boolean):(BasePart,BasePart)
	local scale=boss and 1.45 or 1
	local root=U.Part(model,"HumanoidRootPart",Vector3.new(2.5,2.5,2.5),CFrame.new(pos),Enum.Material.Metal,false)
	root.Transparency=1
	root.CanCollide=false
	root.CanTouch=false
	root.CanQuery=true
	root.Massless=false

	local torso=limb(model,"Torso",Vector3.new(3.4*scale,4*scale,2.4*scale),pos+Vector3.new(0,2*scale,0),Color3.fromRGB(49,55,66))
	local head=limb(model,"Head",Vector3.new(2.2*scale,2.2*scale,2.2*scale),pos+Vector3.new(0,5*scale,0),Color3.new(1,1,1))
	head.Shape=Enum.PartType.Ball

	local rightArm=limb(model,"Right Arm",Vector3.new(1.15*scale,4*scale,1.15*scale),pos+Vector3.new(2.15*scale,2*scale,0),color)
	local leftArm=limb(model,"Left Arm",Vector3.new(1.15*scale,4*scale,1.15*scale),pos+Vector3.new(-2.15*scale,2*scale,0),color)
	local rightLeg=limb(model,"Right Leg",Vector3.new(1.3*scale,4*scale,1.3*scale),pos+Vector3.new(.9*scale,-2*scale,0),Color3.fromRGB(45,49,58))
	local leftLeg=limb(model,"Left Leg",Vector3.new(1.3*scale,4*scale,1.3*scale),pos+Vector3.new(-.9*scale,-2*scale,0),Color3.fromRGB(45,49,58))

	joint(root,"RootJoint",root,torso,CFrame.new(0,2*scale,0),CFrame.identity)
	joint(torso,"Neck",torso,head,CFrame.new(0,2.2*scale,0),CFrame.new(0,-1.1*scale,0))
	joint(torso,"Right Shoulder",torso,rightArm,CFrame.new(1.7*scale,1.4*scale,0),CFrame.new(0,1.7*scale,0))
	joint(torso,"Left Shoulder",torso,leftArm,CFrame.new(-1.7*scale,1.4*scale,0),CFrame.new(0,1.7*scale,0))
	joint(torso,"Right Hip",torso,rightLeg,CFrame.new(.85*scale,-2*scale,0),CFrame.new(0,2*scale,0))
	joint(torso,"Left Hip",torso,leftLeg,CFrame.new(-.85*scale,-2*scale,0),CFrame.new(0,2*scale,0))

	local core=U.Part(model,"Core",boss and Vector3.new(3.8,4.2,3.8)or Vector3.new(2.3,2.8,2.3),CFrame.new(pos+Vector3.new(0,2*scale,0)),Enum.Material.Neon,color,false)
	core.Shape=Enum.PartType.Ball
	core.CanCollide=false
	core.CanTouch=false
	core.CanQuery=true
	local coreWeld=Instance.new("WeldConstraint")
	coreWeld.Part0=torso
	coreWeld.Part1=core
	coreWeld.Parent=torso
	return root,core
end

local function make(kind:string,pos:Vector3,boss:boolean,ownerUserId:number?):Model
	local d=C.Enemies[kind]
	local m=Instance.new("Model")
	m.Name=kind
	m:SetAttribute("Archetype",kind)
	m:SetAttribute("LastHitUserId",0)
	m:SetAttribute("IsBoss",boss)
	m:SetAttribute("Phase",1)
	m:SetAttribute("BattleStreakOwnerUserId",ownerUserId or 0)

	local root,core=buildRig(m,pos,d.Color,boss)
	local h=Instance.new("Humanoid")
	h.MaxHealth=d.Health
	h.Health=d.Health
	h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	h.Parent=m
	U.Nameplate(core,kind,d.Color)
	m.PrimaryPart=root
	CollectionService:AddTag(m,"CBSEnemy")
	m.Parent=folder
	root:SetNetworkOwner(nil)
	active[m]=true
	Animation.Register(m)

	h.Died:Connect(function()
		if not active[m]then return end
		active[m]=nil
		Animation.StopActions(m)
		S.Defeated:Fire(m,tonumber(m:GetAttribute("LastHitUserId"))or 0,kind,d.Reward)
		task.delay(2.5,function()
			if m.Parent then m:Destroy()end
		end)
	end)
	return m
end

function S.Init()
	folder=workspace:FindFirstChild("CBSEnemies")or Instance.new("Folder")
	folder.Name="CBSEnemies"
	folder.Parent=workspace
	task.spawn(function()
		while task.wait(.25)do
			for m in pairs(active)do
				local h=m:FindFirstChildOfClass("Humanoid")
				local root=m.PrimaryPart
				local kind=m:GetAttribute("Archetype")
				local d=kind and C.Enemies[kind]
				if not m.Parent or not h or not root or not d then
					active[m]=nil
					attackAt[m]=nil
					continue
				end
				if h.Health<=0 then continue end

				local targetPlayers={}
				local owner=tonumber(m:GetAttribute("BattleStreakOwnerUserId"))or 0
				for _,candidate in ipairs(Players:GetPlayers())do
					if owner==0 or candidate.UserId==owner then
						table.insert(targetPlayers,candidate)
					end
				end

				local player=U.Nearest(targetPlayers,root.Position,80)
				if not player or not player.Character then continue end
				local targetRoot=U.Root(player.Character)
				local targetHum=U.Hum(player.Character)
				if not targetRoot or not targetHum or targetHum.Health<=0 then continue end

				local delta=targetRoot.Position-root.Position
				local flat=Vector3.new(delta.X,0,delta.Z)
				local phase=(m:GetAttribute("IsBoss")and h.Health/h.MaxHealth<=.5)and 2 or 1
				m:SetAttribute("Phase",phase)
				local speed=d.Speed*(phase==2 and 1.2 or 1)

				if flat.Magnitude>d.Range then
					if flat.Magnitude>.1 then
						m:PivotTo(CFrame.lookAt(
							root.Position+flat.Unit*math.min(speed*.25,flat.Magnitude),
							Vector3.new(targetRoot.Position.X,root.Position.Y,targetRoot.Position.Z)
						))
					end
					continue
				end

				local now=os.clock()
				if now-(attackAt[m]or 0)<d.Cooldown then continue end
				attackAt[m]=now
				Animation.Play(m,m:GetAttribute("IsBoss")and"BossAttack"or"BotAttack",.04,phase==2 and 1.12 or 1)
				if d.Range<=10 then
					local attackCF=root.CFrame*CFrame.new(0,2,-d.Range*.5)
					local breakSize=Vector3.new(d.Range*1.25,5,d.Range)
					local broken=Destruction.BreakInBox(attackCF,breakSize,phase==2 and 2 or 1)
					if broken>0 then
						game.ReplicatedStorage.CollisionRemotes.Feedback:FireClient(player,"BreakFX",{
							Position=attackCF.Position,
							Size=breakSize,
							Strength=phase==2 and 2 or 1,
						})
					end
				end

				local parry=tonumber(player:GetAttribute("ParryUntil"))or 0
				local wave=tonumber(m:GetAttribute("BattleStreakWave"))or 0
				local damageScale=tonumber(m:GetAttribute("BattleStreakDamageScale"))or (1+math.min(.55,wave*.04))
				if now<=parry then
					player:SetAttribute("Momentum",U.Clamp((player:GetAttribute("Momentum")or 0)+10,0,C.Combat.MomentumMax))
					game.ReplicatedStorage.CollisionRemotes.Feedback:FireClient(player,"ParrySuccess")
				else
					local block=player:GetAttribute("IsBlocking")==true
					targetHum:TakeDamage(d.Damage*damageScale*(block and C.Combat.BlockMultiplier or 1)*(phase==2 and 1.15 or 1))
				end
			end
		end
	end)
end

function S.Spawn(kind:string,pos:Vector3,ownerUserId:number?):Model?
	if not folder or not C.Enemies[kind]then return nil end
	return make(kind,pos,false,ownerUserId)
end

function S.SpawnMiniBoss(pos:Vector3,ownerUserId:number?):Model?
	if not folder then return nil end
	return make("MiniBoss",pos,true,ownerUserId)
end

function S.SpawnBoss(pos:Vector3,ownerUserId:number?):Model?
	if not folder then return nil end
	return make("Boss",pos,true,ownerUserId)
end

function S.CountAlive():number
	local n=0
	for _ in pairs(active)do n+=1 end
	return n
end

return S
