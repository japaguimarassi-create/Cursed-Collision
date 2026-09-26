--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local CollectionService=game:GetService("CollectionService")
local Config=require(ReplicatedStorage.Shared.Config)
local Fighters=require(ReplicatedStorage.Shared.CharacterDefinitions)

type State={
 bucketStart:number,
 bucketCount:number,
 combo:number,
 comboExpire:number,
 nextLight:number,
 nextDash:number,
 nextSpecial:number,
 nextDomain:number,
 blockStarted:number,
 blocking:boolean,
 stunUntil:number,
 dashUntil:number,
 awakening:boolean,
 awakeningUntil:number,
 overdrive:number,
 perfectReady:boolean,
 clashId:number?,
 clashScore:number
}
type DomainState={id:number,owner:Player,part:BasePart,expires:number}

local M={}
local states:{[Player]:State}={}
local domains:{[number]:DomainState}={}
local nextDomainId=0
local FX:UnreliableRemoteEvent?
local Feedback:RemoteEvent?
local DataService

local function now():number return os.clock() end

local function state(player:Player):State
 local s=states[player]
 if s then return s end
 s={bucketStart=now(),bucketCount=0,combo=0,comboExpire=0,nextLight=0,nextDash=0,nextSpecial=0,nextDomain=0,blockStarted=0,blocking=false,stunUntil=0,dashUntil=0,awakening=false,awakeningUntil=0,overdrive=0,perfectReady=false,clashId=nil,clashScore=0}
 states[player]=s
 return s
end

local function mirror(player:Player,s:State)
 player:SetAttribute("Combo",s.combo)
 player:SetAttribute("Blocking",s.blocking)
 player:SetAttribute("Energy",math.max(0,tonumber(player:GetAttribute("Energy")) or Config.Resources.MaxEnergy))
 player:SetAttribute("Overdrive",s.overdrive)
 player:SetAttribute("AwakeningActive",s.awakening)
 player:SetAttribute("AwakeningUntil",s.awakeningUntil)
 player:SetAttribute("NextLight",s.nextLight)
 player:SetAttribute("NextDash",s.nextDash)
 player:SetAttribute("NextSpecial",s.nextSpecial)
 player:SetAttribute("NextDomain",s.nextDomain)
 player:SetAttribute("DomainClash",s.clashId or 0)
 player:SetAttribute("ClashScore",s.clashScore)
end

local function characterParts(player:Player):(Model?,Humanoid?,BasePart?)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not character or not humanoid or not root or not root:IsA("BasePart") or humanoid.Health<=0 then return nil,nil,nil end
 return character,humanoid,root
end

local function send(player:Player,kind:string,payload:any)
 if Feedback then Feedback:FireClient(player,kind,payload) end
end

local function fx(kind:string,position:Vector3,extra:any?)
 if FX then FX:FireAllClients(kind,position,extra) end
end

local function consumeRequest(s:State):boolean
 local t=now()
 if t-s.bucketStart>=1 then s.bucketStart=t;s.bucketCount=0 end
 s.bucketCount+=1
 return s.bucketCount<=Config.Combat.RequestRate+Config.Combat.RequestBurst
end

local function fighterFor(player:Player)
 return Fighters.Get(tostring(player:GetAttribute("EquippedCharacter") or "Yuji")) or Fighters.Get("Yuji") :: any
end

local function getHumanoids(player:Player,cf:CFrame,size:Vector3):{Humanoid}
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character}
 params.MaxParts=64
 local out:{Humanoid}={}
 local seen:{[Humanoid]:boolean}={}
 for _,part in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
  local model=part:FindFirstAncestorOfClass("Model")
  local humanoid=model and model:FindFirstChildOfClass("Humanoid")
  if humanoid and humanoid.Health>0 and not seen[humanoid] then
   local victimPlayer=Players:GetPlayerFromCharacter(model)
   if victimPlayer~=player then
    seen[humanoid]=true;table.insert(out,humanoid)
   end
  end
 end
 return out
end

local function getHumanoidsRadius(player:Player,position:Vector3,radius:number):{Humanoid}
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character}
 params.MaxParts=64
 local out:{Humanoid}={}
 local seen:{[Humanoid]:boolean}={}
 for _,part in ipairs(workspace:GetPartBoundsInRadius(position,radius,params)) do
  local model=part:FindFirstAncestorOfClass("Model")
  local humanoid=model and model:FindFirstChildOfClass("Humanoid")
  if humanoid and humanoid.Health>0 and not seen[humanoid] then
   local victimPlayer=Players:GetPlayerFromCharacter(model)
   if victimPlayer~=player then seen[humanoid]=true;table.insert(out,humanoid) end
  end
 end
 return out
end

local function damageDestructibles(position:Vector3,radius:number,damage:number)
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace:FindFirstChild("CollisionBattlestarWorld")}
 params.MaxParts=64
 for _,item in ipairs(workspace:GetPartBoundsInRadius(position,radius,params)) do
  if item:IsA("BasePart") and CollectionService:HasTag(item,"CBS_Destructible") then
   local hp=math.max(0,(tonumber(item:GetAttribute("HP")) or tonumber(item:GetAttribute("MaxHP")) or 40)-damage)
   item:SetAttribute("HP",hp)
   if hp<=0 and item.Transparency<1 then
    item.CanCollide=false;item.CanQuery=false;item.Transparency=1
    task.delay(Config.Performance.DestructionRestore,function()
     if item.Parent then item.Transparency=0;item.CanCollide=true;item.CanQuery=true;item:SetAttribute("HP",item:GetAttribute("MaxHP") or 40) end
    end)
   end
  end
 end
end

local function applyStun(victim:Player,duration:number)
 local s=state(victim)
 s.stunUntil=math.max(s.stunUntil,now()+duration)
 s.blocking=false
 mirror(victim,s)
end

local function addOverdrive(player:Player,amount:number)
 local s=state(player)
 s.overdrive=math.clamp(s.overdrive+amount,0,100)
 mirror(player,s)
end

local function registerCombatHit(attacker:Player,victim:Player?,damage:number)
 addOverdrive(attacker,6)
 local energy=tonumber(attacker:GetAttribute("Energy")) or 0
 attacker:SetAttribute("Energy",math.min(Config.Resources.MaxEnergy,energy+Config.Resources.HitEnergy))
 if victim then
  addOverdrive(victim,math.clamp(damage*Config.Resources.DamageAwakening,0,25))
 end
 if victim then
  local vs=state(victim)
  if vs.clashId and vs.clashId==state(attacker).clashId then state(attacker).clashScore+=1 end
 end
 DataService:AddXP(attacker,Config.Progression.HitXP)
end

local function applyHit(attacker:Player,victimHumanoid:Humanoid,damage:number,knockback:number,guardBreak:boolean,finisher:boolean):boolean
 local victimModel=victimHumanoid.Parent
 if not victimModel or not victimModel:IsA("Model") then return false end
 local victim=Players:GetPlayerFromCharacter(victimModel)
 local _,_,attackerRoot=characterParts(attacker)
 local victimRoot=victimModel:FindFirstChild("HumanoidRootPart")
 if not attackerRoot or not victimRoot or not victimRoot:IsA("BasePart") then return false end
 if victim and state(victim).dashUntil>now() then return false end
 if victim and state(victim).blocking and not guardBreak then
  local direction=attackerRoot.Position-victimRoot.Position
  if direction.Magnitude>0 and victimRoot.CFrame.LookVector:Dot(direction.Unit)>=Config.Combat.BlockDot then
   local vs=state(victim)
   if now()-vs.blockStarted<=Config.Combat.ParryWindow then
    local as=state(attacker)
    applyStun(attacker,Config.Combat.Stun+.12)
    vs.perfectReady=true
    send(victim,"Parry",{Position=victimRoot.Position})
    send(attacker,"Parried",{Position=attackerRoot.Position})
    fx("Parry",victimRoot.Position,nil)
   else
    send(victim,"Guard",{Position=victimRoot.Position})
    send(attacker,"Guarded",{Position=victimRoot.Position})
    fx("Guard",victimRoot.Position,nil)
   end
   return false
  end
 end
 local before=victimHumanoid.Health
 victimHumanoid:TakeDamage(damage)
 local after=victimHumanoid.Health
 if victim then
  applyStun(victim,Config.Combat.Stun)
  registerCombatHit(attacker,victim,damage)
  send(victim,"HitTaken",{Position=victimRoot.Position,Damage=damage})
 end
 if attackerRoot then
  local vertical=finisher and 18 or 7
  local variant=tostring(attacker:GetAttribute("LastM1Variant") or "Neutral")
  if finisher and variant=="Uppercut" then vertical=58 elseif finisher and variant=="Downslam" then vertical=-54 end
  victimRoot.AssemblyLinearVelocity=attackerRoot.CFrame.LookVector*knockback+Vector3.new(0,vertical,0)
  if finisher and victim then
   local stateHumanoid=victimHumanoid
   stateHumanoid.PlatformStand=true
   task.delay(.42,function() if stateHumanoid.Parent and stateHumanoid.Health>0 then stateHumanoid.PlatformStand=false end end)
  end
 end
 send(attacker,"Hit",{Position=victimRoot.Position,Damage=damage,Finisher=finisher})
 fx("Hit",victimRoot.Position,{damage=damage,finisher=finisher})
 damageDestructibles(victimRoot.Position,finisher and 8 or 5,damage)
 if before>0 and after<=0 and victim then
  DataService:AddKO(attacker)
  victim:SetAttribute("KOs",victim:GetAttribute("KOs") or 0)
  victim:SetAttribute("Streak",0)
  send(attacker,"KOReward",{Credits=Config.Progression.KOReward})
 end
 return true
end

local function hitList(attacker:Player,humanoids:{Humanoid},damage:number,knockback:number,guardBreak:boolean,finisher:boolean)
 for _,humanoid in ipairs(humanoids) do
  local as=state(attacker)
  local multiplier=as.awakening and Config.Combat.Awakening.DamageMultiplier or 1
  if applyHit(attacker,humanoid,damage*multiplier,knockback,guardBreak,finisher) then
   if finisher then as.combo=0 else as.comboExpire=now()+Config.Combat.ComboReset end
  end
 end
end

local function light(player:Player)
 local s=state(player)
 local t=now()
 if t<s.nextLight or t<s.stunUntil or s.blocking then return end
 local _,_,root=characterParts(player);if not root then return end
 if t>s.comboExpire then s.combo=0 end
 s.combo=math.min(4,s.combo+1)
 s.comboExpire=t+Config.Combat.ComboReset
 s.nextLight=t+Config.Combat.Light.Cooldown
 local index=s.combo
 local damage=Config.Combat.Light.Damage[index]
 local finisher=index==4
 local variant="Neutral"
 local vertical=root.AssemblyLinearVelocity.Y
 if finisher and vertical>5 then variant="Uppercut" elseif finisher and vertical<-5 then variant="Downslam" end
 if s.perfectReady then damage*=1.45;s.perfectReady=false end
 local cf=root.CFrame*CFrame.new(0,0,-Config.Combat.Light.Offset)
 local knock=Config.Combat.Light.Knockback[index]
 if variant=="Uppercut" then knock=knock+10 elseif variant=="Downslam" then knock=math.max(10,knock-6) end
 hitList(player,getHumanoids(player,cf,Config.Combat.Light.Hitbox),damage,knock,false,finisher)
 player:SetAttribute("LastM1Variant",variant)
 send(player,"Swing",{Position=cf.Position,Combo=index,Variant=variant})
 fx("Swing",cf.Position,{combo=index,color=fighterFor(player).Color})
 mirror(player,s)
end

local function dash(player:Player)
 local s=state(player)
 local t=now()
 if t<s.nextDash or t<s.stunUntil or s.blocking then return end
 local _,_,root=characterParts(player);if not root then return end
 local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 local move=(humanoid and humanoid.MoveDirection) or Vector3.zero
 local direction=move.Magnitude>.1 and move.Unit or root.CFrame.LookVector
 local forward=root.CFrame.LookVector
 local dot=direction:Dot(forward)
 local speed=dot<-.25 and Config.Combat.Dash.BackSpeed or math.abs(dot)<.35 and Config.Combat.Dash.SideSpeed or Config.Combat.Dash.Speed
 s.nextDash=t+Config.Combat.Dash.Cooldown
 s.dashUntil=t+Config.Combat.Dash.Duration
 root.AssemblyLinearVelocity=direction*speed+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
 send(player,"Dash",{Position=root.Position})
 fx("Dash",root.Position,{color=fighterFor(player).Color})
 mirror(player,s)
end

local function special(player:Player)
 local s=state(player)
 local t=now()
 if t<s.nextSpecial or t<s.stunUntil or s.blocking then return end
 local _,_,root=characterParts(player);if not root then return end
 local fighter=fighterFor(player)
 local energy=tonumber(player:GetAttribute("Energy")) or Config.Resources.MaxEnergy
 if energy<Config.Combat.Special.EnergyCost then send(player,"Message","NOT ENOUGH CE");return end
 local charged=s.overdrive>=100
 local damage=fighter.Damage*(charged and Config.Combat.Awakening.SpecialMultiplier or 1)*(s.awakening and Config.Combat.Awakening.SpecialMultiplier or 1)
 if s.perfectReady then damage*=1.65;s.perfectReady=false end
 player:SetAttribute("Energy",energy-Config.Combat.Special.EnergyCost)
 s.nextSpecial=t+Config.Combat.Special.Cooldown
 if charged then s.overdrive=0 end
 local range=fighter.Radius
 local hits:{Humanoid}={}
 if fighter.SpecialType=="Line" then
  hits=getHumanoids(player,root.CFrame*CFrame.new(0,0,-range*.9),Vector3.new(7,6,range*1.8))
 elseif fighter.SpecialType=="Cone" then
  for _,h in ipairs(getHumanoidsRadius(player,root.Position,range)) do
   local r=h.Parent and h.Parent:FindFirstChild("HumanoidRootPart")
   if r and r:IsA("BasePart") and root.CFrame.LookVector:Dot((r.Position-root.Position).Unit)>.15 then table.insert(hits,h) end
  end
 elseif fighter.SpecialType=="Pull" then
  hits=getHumanoidsRadius(player,root.Position,range)
  for _,h in ipairs(hits) do
   local r=h.Parent and h.Parent:FindFirstChild("HumanoidRootPart")
   if r and r:IsA("BasePart") then r.AssemblyLinearVelocity=(root.Position-r.Position).Unit*42+Vector3.new(0,10,0) end
  end
 elseif fighter.SpecialType=="DashStrike" then
  root.AssemblyLinearVelocity=root.CFrame.LookVector*90+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
  task.wait(.08)
  if root.Parent then hits=getHumanoids(player,root.CFrame*CFrame.new(0,0,-5),Vector3.new(8,7,13)) end
 elseif fighter.SpecialType=="Blink" then
  local nearest:BasePart?
  local best=range+1
  for _,h in ipairs(getHumanoidsRadius(player,root.Position,range)) do
   local r=h.Parent and h.Parent:FindFirstChild("HumanoidRootPart")
   if r and r:IsA("BasePart") then local d=(r.Position-root.Position).Magnitude;if d<best then best=d;nearest=r end end
  end
  if nearest then root.CFrame=CFrame.lookAt(nearest.Position-nearest.CFrame.LookVector*4,nearest.Position);hits=getHumanoids(player,root.CFrame*CFrame.new(0,0,-4),Vector3.new(8,7,10)) end
 elseif fighter.SpecialType=="Heal" then
  local _,humanoid=characterParts(player)
  if humanoid then humanoid.Health=math.min(humanoid.MaxHealth,humanoid.Health+24) end
  hits=getHumanoidsRadius(player,root.Position,range)
 else
  hits=getHumanoidsRadius(player,root.Position,range)
 end
 if fighter.SpecialType=="GuardBreak" then
  hitList(player,hits,damage, fighter.Knockback,true,charged)
 else
  hitList(player,hits,damage, fighter.Knockback,false,charged)
 end
 send(player,"Special",{Position=root.Position,Charged=charged,Name=fighter.Special,Color=fighter.Color})
 fx("Special",root.Position,{color=fighter.Color,charged=charged})
 mirror(player,s)
end

local function awaken(player:Player)
 local s=state(player)
 local t=now()
 if s.awakening or s.stunUntil>t or s.overdrive<Config.Combat.Awakening.Required then return end
 if s.clashId then return end
 s.awakening=true
 s.awakeningUntil=t+Config.Combat.Awakening.Duration
 s.overdrive=0
 local _,humanoid=characterParts(player)
 if humanoid then humanoid.Health=math.min(humanoid.MaxHealth,humanoid.Health+12) end
 send(player,"Awaken",{Name=fighterFor(player).Awakening})
 fx("Awaken",(player.Character and player.Character:GetPivot().Position) or Vector3.zero,{color=fighterFor(player).Color})
 mirror(player,s)
end

local function destroyDomain(id:number)
 local d=domains[id]
 if not d then return end
 if d.part.Parent then d.part:Destroy() end
 domains[id]=nil
 if d.owner.Parent then
  local s=state(d.owner);if s.clashId==id then s.clashId=nil;s.clashScore=0;s.clashMoveNext=0;mirror(d.owner,s) end
 end
end

local function endClash(clashId:number,p1:Player,p2:Player,d1:number,d2:number)
 local s1=state(p1)
 local s2=state(p2)
 local score1=s1.clashScore
 local score2=s2.clashScore
 s1.clashId=nil;s2.clashId=nil;s1.clashScore=0;s2.clashScore=0;s1.clashMoveNext=0;s2.clashMoveNext=0
 mirror(p1,s1);mirror(p2,s2)
 local winner:Player?
 if score1>score2 then winner=p1 elseif score2>score1 then winner=p2 end
 if not winner then
  destroyDomain(d1);destroyDomain(d2)
  send(p1,"Message","DOMAIN CLASH  •  DRAW")
  send(p2,"Message","DOMAIN CLASH  •  DRAW")
  return
 end
 local loser=winner==p1 and p2 or p1
 local winnerDomain=winner==p1 and d1 or d2
 local loserDomain=winner==p1 and d2 or d1
 destroyDomain(loserDomain)
 local wd=domains[winnerDomain]
 if wd then wd.expires=now()+Config.Combat.Domain.Duration end
 send(winner,"Message","DOMAIN CLASH  •  DOMAIN PREVAILS")
 send(loser,"Message","DOMAIN CLASH  •  DOMAIN LOST")
end

local function clashMove(player:Player,index:number)
 local s=state(player)
 local t=now()
 if not s.clashId or t<s.clashMoveNext then return end
 if index<1 or index>4 then return end
 s.clashMoveNext=t+Config.Combat.Domain.ClashWindow/4
 s.clashScore+=1
 player:SetAttribute("LastClashMove",index)
 mirror(player,s)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if root and root:IsA("BasePart") then
  send(player,"ClashMove",{Index=index,Score=s.clashScore,Position=root.Position})
  fx("Clash",root.Position,{index=index,score=s.clashScore,color=fighterFor(player).Color})
 end
end

local function createDomain(player:Player)
 local fighter=fighterFor(player)
 if fighter.Domain=="No Domain" then send(player,"Message","THIS FIGHTER HAS NO DOMAIN");return end
 local _,_,root=characterParts(player);if not root then return end
 nextDomainId+=1
 local id=nextDomainId
 local sphere=Instance.new("Part")
 sphere.Name="Domain_"..id
 sphere.Shape=Enum.PartType.Ball
 sphere.Size=Vector3.new(Config.Combat.Domain.Radius*2,Config.Combat.Domain.Radius*2,Config.Combat.Domain.Radius*2)
 sphere.Position=root.Position
 sphere.Anchored=true;sphere.CanCollide=false;sphere.CanTouch=false;sphere.CanQuery=false;sphere.Material=Enum.Material.ForceField;sphere.Transparency=.86;sphere.Color=fighter.Color
 sphere.Parent=workspace
 domains[id]={id=id,owner=player,part=sphere,expires=now()+Config.Combat.Domain.Duration}
 local s=state(player);s.nextDomain=now()+Config.Combat.Domain.Cooldown;s.clashId=id;s.clashScore=0
 player:SetAttribute("Energy",0)
 mirror(player,s)
 fx("Domain",root.Position,{color=fighter.Color})
 send(player,"Domain",{Name=fighter.Domain})
 for other,ds in pairs(domains) do
  if other~=id and ds.owner~=player and ds.part.Parent and now()-ds.expires+Config.Combat.Domain.Duration<=Config.Combat.Domain.ClashWindow then
   local distance=(ds.part.Position-sphere.Position).Magnitude
   if distance<=Config.Combat.Domain.Radius*1.8 then
    state(ds.owner).clashId=id;state(ds.owner).clashScore=0;state(ds.owner).clashMoveNext=0;state(player).clashId=id
    mirror(ds.owner,state(ds.owner));mirror(player,state(player))
    task.delay(Config.Combat.Domain.ClashDuration,function()
     if domains[id] or domains[other] then endClash(id,player,ds.owner,id,other) end
    end)
    return
   end
  end
 end
 task.spawn(function()
  while domains[id] and sphere.Parent and now()<domains[id].expires do
   task.wait(1)
   local d=domains[id]
   if not d or not sphere.Parent then break end
   for _,h in ipairs(getHumanoidsRadius(player,sphere.Position,Config.Combat.Domain.Radius-2)) do
    applyHit(player,h,6,10,false,false)
   end
  end
  if domains[id] then destroyDomain(id) end
 end)
end

function M:Handle(player:Player,action:string)
 if player:GetAttribute("DataReady")~=true then return end
 local s=state(player)
 if not consumeRequest(s) then return end
 if action=="Light" then light(player)
 elseif action=="Dash" then dash(player)
 elseif action=="Special" then special(player)
 elseif action=="BlockStart" then
  if now()>=s.stunUntil and not s.clashId then
   s.blocking=true;s.blockStarted=now()
   local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.WalkSpeed=Config.Movement.BlockWalkSpeed end
   mirror(player,s)
  end
 elseif action=="BlockEnd" then
  s.blocking=false
  local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then humanoid.WalkSpeed=Config.Movement.WalkSpeed end
  mirror(player,s)
 elseif action=="Clash1" then clashMove(player,1)
 elseif action=="Clash2" then clashMove(player,2)
 elseif action=="Clash3" then clashMove(player,3)
 elseif action=="Clash4" then clashMove(player,4)
 elseif action=="Awaken" then awaken(player)
 elseif action=="Domain" then
  if now()>=s.nextDomain and not s.awakening and not s.clashId and (tonumber(player:GetAttribute("Energy")) or 0)>=Config.Combat.Domain.Cost then createDomain(player) end
 end
end

function M:Movement(player:Player,sprint:boolean)
 if typeof(sprint)~="boolean" or player:GetAttribute("DataReady")~=true then return end
 local s=state(player)
 if s.stunUntil>now() then return end
 local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.WalkSpeed=sprint and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed end
end

function M:Init(dataService,feedback:RemoteEvent,fxRemote:UnreliableRemoteEvent)
 DataService=dataService;Feedback=feedback;FX=fxRemote
 Players.PlayerAdded:Connect(function(player)
  local s=state(player)
  player.CharacterAdded:Connect(function()
   task.wait(.15)
   local _,humanoid=characterParts(player)
   if humanoid then humanoid.WalkSpeed=Config.Movement.WalkSpeed;humanoid.JumpPower=Config.Movement.JumpPower end
   s.blocking=false;s.stunUntil=0;s.dashUntil=0;s.combo=0;s.awakening=false;s.awakeningUntil=0;s.overdrive=0;s.perfectReady=false;s.clashId=nil;s.clashScore=0
   player:SetAttribute("Energy",Config.Resources.MaxEnergy);mirror(player,s)
  end)
  player:SetAttribute("MaxEnergy",Config.Resources.MaxEnergy)
  player:SetAttribute("Energy",Config.Resources.MaxEnergy)
  s.clashMoveNext=0
  mirror(player,s)
 end)
 Players.PlayerRemoving:Connect(function(player)
  local s=state(player)
  if s.clashId then
   local id=s.clashId
   if domains[id] then destroyDomain(id) end
  end
  states[player]=nil
 end)
 for _,player in ipairs(Players:GetPlayers()) do
  state(player)
 end
 task.spawn(function()
  while game.Parent do
   task.wait(.1)
   local t=now()
   for player,s in pairs(states) do
    if player.Parent then
     if s.awakening and t>=s.awakeningUntil then s.awakening=false;send(player,"Message","AWAKENING ENDED");mirror(player,s) end
     if s.stunUntil<t and player.Character then
      local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
      if humanoid and humanoid.WalkSpeed==0 then humanoid.WalkSpeed=Config.Movement.WalkSpeed;humanoid.JumpPower=Config.Movement.JumpPower end
     elseif s.stunUntil>=t and player.Character then
      local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
      if humanoid then humanoid.WalkSpeed=0;humanoid.JumpPower=0 end
     end
     local energy=tonumber(player:GetAttribute("Energy")) or Config.Resources.MaxEnergy
     if energy<Config.Resources.MaxEnergy and not s.blocking then player:SetAttribute("Energy",math.min(Config.Resources.MaxEnergy,energy+Config.Resources.EnergyRegen*.1)) end
     if s.combo>0 and t>s.comboExpire then s.combo=0;mirror(player,s) end
    end
   end
   for id,d in pairs(domains) do if t>=d.expires then destroyDomain(id) end end
  end
 end)
end
return M