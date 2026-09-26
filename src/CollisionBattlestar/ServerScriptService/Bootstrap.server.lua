--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local CollectionService=game:GetService("CollectionService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

Players.CharacterAutoLoads=false

local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared.Config)
local Routes=require(Shared.MapDefinitions)
local Catalog=require(Shared.StoreCatalog)

local remotes=ReplicatedStorage:FindFirstChild("CollisionRemotes")
if not remotes then
  remotes=Instance.new("Folder")
  remotes.Name="CollisionRemotes"
  remotes.Parent=ReplicatedStorage
end

local remoteNames={"CombatRequest","MovementRequest","Feedback","MapTravelRequest","UtilityRequest","UtilityFeedback","GameState"}
for _,name in ipairs(remoteNames) do
  if not remotes:FindFirstChild(name) then
    local event=Instance.new("RemoteEvent")
    event.Name=name
    event.Parent=remotes
  end
end

local feedback=remotes.Feedback
local mapTravel=remotes.MapTravelRequest
local utility=remotes.UtilityRequest

local profileStore=DataStoreService:GetDataStore("CollisionBattlestar_Profile_v3")
local profiles:{[Player]:{Owned:{[string]:boolean},Equipped:string,Redeemed:{[string]:boolean},Loaded:boolean,Saving:boolean}}={}
local requestState:{[Player]:{Window:number,Count:number}}={}
local travelCooldown:{[Player]:number}={}

local function send(player:Player,kind:string,value:any)
  feedback:FireClient(player,kind,value)
end

local function basePart(parent:Instance,name:string,size:Vector3,position:Vector3,color:Color3,material:Enum.Material,collide:boolean,shadow:boolean?):Part
  local p=Instance.new("Part")
  p.Name=name
  p.Size=size
  p.Position=position
  p.Anchored=true
  p.CanCollide=collide
  p.CanTouch=false
  p.CanQuery=collide
  p.Material=material
  p.Color=color
  p.CastShadow=shadow~=false
  p.TopSurface=Enum.SurfaceType.Smooth
  p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=parent
  return p
end

local function accent(parent:Instance,name:string,size:Vector3,position:Vector3,color:Color3):Part
  return basePart(parent,name,size,position,color,Enum.Material.Neon,false,false)
end

local function cover(parent:Instance,name:string,size:Vector3,position:Vector3,color:Color3,hp:number)
  local p=basePart(parent,name,size,position,color,Enum.Material.Concrete,true,true)
  p:SetAttribute("CBSDestructible",true)
  p:SetAttribute("HP",hp)
  p:SetAttribute("MaxHP",hp)
  CollectionService:AddTag(p,"CBS_Destructible")
  return p
end

local function building(parent:Instance,name:string,x:number,z:number,w:number,d:number,h:number,color:Color3,accentColor:Color3)
  basePart(parent,name,Vector3.new(w,h,d),Vector3.new(x,h/2,z),color,Enum.Material.Concrete,true,true)
  basePart(parent,name.."_Roof",Vector3.new(w+3,1.2,d+3),Vector3.new(x,h+.6,z),Color3.fromRGB(22,28,38),Enum.Material.Metal,true,true)
  for side=-1,1,2 do
    for level=1,math.min(3,math.floor(h/18)) do
      for column=1,3 do
        local xx=x+(column-2)*(w/3.4)
        local zz=z+side*(d/2+.08)
        accent(parent,name.."_W_"..side.."_"..level.."_"..column,Vector3.new(4,4,.16),Vector3.new(xx,level*16-5,zz),accentColor)
      end
    end
  end
end

local function district(parent:Folder,node:any,index:number)
  local x=node.Position.X
  local floorColor=Color3.fromRGB(40,47,59)
  basePart(parent,node.Id.."_Ground",Vector3.new(220,2,190),Vector3.new(x,0,0),floorColor,Enum.Material.Asphalt,true,true)
  basePart(parent,node.Id.."_Road",Vector3.new(42,2,190),Vector3.new(x,1,0),Color3.fromRGB(23,28,35),Enum.Material.Asphalt,true,false)
  basePart(parent,node.Id.."_RoadX",Vector3.new(220,2,34),Vector3.new(x,1,0),Color3.fromRGB(23,28,35),Enum.Material.Asphalt,true,false)
  for side=-1,1,2 do
    for slot=-1,1,2 do
      local bx=x+slot*66
      local bz=side*62
      local h=(index==3 and 54 or 38)+index*3
      building(parent,node.Id.."_Building_"..side.."_"..slot,bx,bz,48,42,h,Color3.fromRGB(51+index*3,57+index*3,68+index*2),node.Color)
    end
  end
  for i=-2,2 do
    accent(parent,node.Id.."_Lane_"..i,Vector3.new(.6,.15,13),Vector3.new(x+i*24,2,0),node.Color)
  end
  for i=1,4 do
    local px=x+(i<=2 and -1 or 1)*80
    local pz=(i%2==0 and 74 or -74)
    cover(parent,node.Id.."_Cover_"..i,Vector3.new(12,5,2),Vector3.new(px,3,pz),Color3.fromRGB(101,108,118),22)
  end
  local sign=basePart(parent,node.Id.."_Sign",Vector3.new(70,10,2),Vector3.new(x,10,-92),Color3.fromRGB(16,22,31),Enum.Material.Metal,true,false)
  local gui=Instance.new("SurfaceGui")
  gui.Face=Enum.NormalId.Front
  gui.LightInfluence=0
  gui.Parent=sign
  local label=Instance.new("TextLabel")
  label.Size=UDim2.fromScale(1,1)
  label.BackgroundTransparency=1
  label.Text=node.Name
  label.Font=Enum.Font.GothamBlack
  label.TextScaled=true
  label.TextColor3=node.Color
  label.Parent=gui
end

local function buildMap()
  local old=workspace:FindFirstChild("CollisionBattlestarWorld")
  if old then old:Destroy() end
  local world=Instance.new("Folder")
  world.Name="CollisionBattlestarWorld"
  world.Parent=workspace
  local map=Instance.new("Folder")
  map.Name="Map"
  map.Parent=world
  local spawns=Instance.new("Folder")
  spawns.Name="Spawns"
  spawns.Parent=world

  basePart(map,"WorldFloor",Vector3.new(Config.Map.Width+100,2,330),Vector3.new(0,-2,0),Color3.fromRGB(18,23,30),Enum.Material.Slate,true,true)
  basePart(map,"NorthBarrier",Vector3.new(Config.Map.Width+40,30,4),Vector3.new(0,14,170),Color3.fromRGB(13,18,25),Enum.Material.Concrete,true,false)
  basePart(map,"SouthBarrier",Vector3.new(Config.Map.Width+40,30,4),Vector3.new(0,14,-170),Color3.fromRGB(13,18,25),Enum.Material.Concrete,true,false)
  for i,nodeId in ipairs(Routes.Order) do
    district(map,Routes.Nodes[nodeId],i)
  end
  for x=-390,390,130 do
    basePart(map,"Connector_"..x,Vector3.new(100,2,46),Vector3.new(x,1,0),Color3.fromRGB(24,29,36),Enum.Material.Asphalt,true,false)
    accent(map,"Divider_"..x,Vector3.new(22,.15,.7),Vector3.new(x,2.2,0),Color3.fromRGB(170,178,190))
  end
  local spawn=Instance.new("SpawnLocation")
  spawn.Name="OriginSpawn"
  spawn.Size=Vector3.new(10,1,10)
  spawn.Position=Routes.Nodes.Origin.Position+Vector3.new(0,2,0)
  spawn.Anchored=true
  spawn.CanCollide=true
  spawn.Transparency=1
  spawn.Neutral=true
  spawn.AllowTeamChangeOnTouch=false
  spawn.Parent=spawns
  world:SetAttribute("MapVersion",Routes.Version)
  workspace:SetAttribute("CollisionBattlestarMapReady",true)
  workspace:SetAttribute("CollisionBattlestarReady",true)
end

local function levelForXP(xp:number):number
  local level=1
  local need=Config.Progression.BaseXP
  while xp>=need and level<Config.Progression.MaxLevel do
    xp-=need
    level+=1
    need+=Config.Progression.StepXP
  end
  return level
end

local function defaultProfile()
  return {Owned={},Equipped="",Redeemed={},Loaded=false,Saving=false}
end

local function setupStats(player:Player)
  local old=player:FindFirstChild("leaderstats")
  if old then old:Destroy() end
  local stats=Instance.new("Folder")
  stats.Name="leaderstats"
  stats.Parent=player
  for _,entry in ipairs({{"Credits",0},{"KOs",0},{"Streak",0}}) do
    local v=Instance.new("IntValue")
    v.Name=entry[1]
    v.Value=entry[2]
    v.Parent=stats
  end
end

local function applyProfile(player:Player,data:any)
  local stats=player:FindFirstChild("leaderstats")
  local xp=math.max(0,tonumber(data.XP)or 0)
  local credits=stats and stats:FindFirstChild("Credits")
  local kos=stats and stats:FindFirstChild("KOs")
  if credits and credits:IsA("IntValue") then credits.Value=math.max(0,tonumber(data.Credits)or 0) end
  if kos and kos:IsA("IntValue") then kos.Value=math.max(0,tonumber(data.KOs)or 0) end
  player:SetAttribute("XP",xp)
  player:SetAttribute("Level",levelForXP(xp))
end

local function snapshot(player:Player)
  local stats=player:FindFirstChild("leaderstats")
  local p=profiles[player] or defaultProfile()
  local owned={}
  for id,value in pairs(p.Owned) do owned[id]=value end
  local credits=stats and stats:FindFirstChild("Credits")
  local kos=stats and stats:FindFirstChild("KOs")
  return {
    Credits=credits and credits:IsA("IntValue") and credits.Value or 0,
    KOs=kos and kos:IsA("IntValue") and kos.Value or 0,
    XP=tonumber(player:GetAttribute("XP"))or 0,
    Owned=owned,
    Equipped=p.Equipped,
    Redeemed=p.Redeemed,
  }
end

local function save(player:Player)
  local p=profiles[player]
  if not p or not p.Loaded or p.Saving then return end
  p.Saving=true
  local data=snapshot(player)
  pcall(function() profileStore:UpdateAsync("Player_"..player.UserId,function() return data end) end)
  p.Saving=false
end

local function load(player:Player)
  setupStats(player)
  local p=defaultProfile()
  profiles[player]=p
  local ok,data=pcall(function() return profileStore:GetAsync("Player_"..player.UserId) end)
  if ok and typeof(data)=="table" then
    applyProfile(player,data)
    if typeof(data.Owned)=="table" then p.Owned=data.Owned end
    if typeof(data.Redeemed)=="table" then p.Redeemed=data.Redeemed end
    p.Equipped=typeof(data.Equipped)=="string" and data.Equipped or ""
  else
    applyProfile(player,{})
  end
  p.Loaded=true
  player:SetAttribute("DataReady",true)
  player:SetAttribute("CurrentMapNode","Origin")
  player:SetAttribute("Blocking",false)
  player:SetAttribute("BlockStarted",0)
  player:SetAttribute("Combo",0)
  player:SetAttribute("ComboStarted",0)
  player:SetAttribute("NextLight",0)
  player:SetAttribute("NextDash",0)
  player:SetAttribute("NextSpecial",0)
  player:SetAttribute("LastCombatAt",0)
  player:SetAttribute("HitStunUntil",0)
  player:SetAttribute("DashUntil",0)
  player:SetAttribute("Overdrive",0)
  player:SetAttribute("Energy",Config.Resources.MaxEnergy)
  player:SetAttribute("MaxEnergy",Config.Resources.MaxEnergy)
  player:SetAttribute("EquippedItem",p.Equipped)
end

local function spawnPlayer(player:Player)
  if not player.Parent then return end
  player:LoadCharacter()
end

local function configureCharacter(player:Player,character:Model)
  local humanoid=character:WaitForChild("Humanoid",8)
  local root=character:WaitForChild("HumanoidRootPart",8)
  if humanoid and humanoid:IsA("Humanoid") then
    humanoid.WalkSpeed=Config.Movement.WalkSpeed
    humanoid.UseJumpPower=true
    humanoid.JumpPower=Config.Movement.JumpPower
    humanoid.Died:Connect(function()
      if player.Parent then
        task.delay(2,function() spawnPlayer(player) end)
      end
    end)
  end
  if root and root:IsA("BasePart") then
    root.CFrame=CFrame.new(Routes.Nodes.Origin.Position+Vector3.new(0,5,0))
    root.AssemblyLinearVelocity=Vector3.zero
  end
end

local function addXP(player:Player,amount:number)
  local old=tonumber(player:GetAttribute("Level"))or 1
  local xp=math.max(0,(tonumber(player:GetAttribute("XP"))or 0)+math.max(0,amount))
  local level=levelForXP(xp)
  player:SetAttribute("XP",xp)
  player:SetAttribute("Level",level)
  if level>old then send(player,"LevelUp",level) end
end

local function addCredits(player:Player,amount:number)
  local stats=player:FindFirstChild("leaderstats")
  local credits=stats and stats:FindFirstChild("Credits")
  if credits and credits:IsA("IntValue") then credits.Value=math.max(0,credits.Value+math.floor(amount)) end
end

local function addKO(player:Player)
  local stats=player:FindFirstChild("leaderstats")
  local kos=stats and stats:FindFirstChild("KOs")
  local streak=stats and stats:FindFirstChild("Streak")
  if kos and kos:IsA("IntValue") then kos.Value+=1 end
  if streak and streak:IsA("IntValue") then streak.Value+=1 end
  addCredits(player,Config.Progression.KOReward)
  addXP(player,Config.Progression.KOXP)
  send(player,"KOReward",{Credits=Config.Progression.KOReward})
end

local function charParts(player:Player)
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not character or not humanoid or not root or humanoid.Health<=0 or not root:IsA("BasePart") then return nil,nil,nil end
  return character,humanoid,root
end

local function targetHumanoids(attacker:Player,cf:CFrame,size:Vector3)
  local params=OverlapParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={attacker.Character}
  params.MaxParts=32
  local results={}
  local seen={}
  for _,part in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
    local model=part:FindFirstAncestorOfClass("Model")
    local humanoid=model and model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health>0 and model~=attacker.Character and not seen[humanoid] then
      seen[humanoid]=true
      table.insert(results,humanoid)
    end
  end
  return results
end

local function targetRadius(attacker:Player,position:Vector3,radius:number)
  local params=OverlapParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={attacker.Character}
  params.MaxParts=48
  local results={}
  local seen={}
  for _,part in ipairs(workspace:GetPartBoundsInRadius(position,radius,params)) do
    local model=part:FindFirstAncestorOfClass("Model")
    local humanoid=model and model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health>0 and model~=attacker.Character and not seen[humanoid] then
      seen[humanoid]=true
      table.insert(results,humanoid)
    end
  end
  return results
end

local function damageCover(player:Player,position:Vector3,radius:number,damage:number)
  local params=OverlapParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={player.Character}
  params.MaxParts=18
  for _,item in ipairs(workspace:GetPartBoundsInRadius(position,radius,params)) do
    if item:IsA("BasePart") and CollectionService:HasTag(item,"CBS_Destructible") then
      local hp=math.max(0,(tonumber(item:GetAttribute("HP"))or tonumber(item:GetAttribute("MaxHP"))or 20)-damage)
      item:SetAttribute("HP",hp)
      if hp<=0 and item.CanCollide then
        item.CanCollide=false
        item.CanQuery=false
        item.Transparency=1
        task.delay(Config.Performance.DestructionRestore,function()
          if item.Parent then
            item.CanCollide=true
            item.CanQuery=true
            item.Transparency=0
            item:SetAttribute("HP",item:GetAttribute("MaxHP")or 20)
          end
        end)
      end
    end
  end
end

local function applyHit(attacker:Player,victimHumanoid:Humanoid,damage:number,knockback:number,finisher:boolean)
  local model=victimHumanoid.Parent
  if not model or not model:IsA("Model") then return end
  local victim=Players:GetPlayerFromCharacter(model)
  if victim and (tonumber(victim:GetAttribute("DashUntil"))or 0)>os.clock() then return end
  local victimRoot=model:FindFirstChild("HumanoidRootPart")
  local attackerRoot=attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
  if victim and victimRoot and attackerRoot and victim:GetAttribute("Blocking")==true then
    local direction=(attackerRoot.Position-victimRoot.Position)
    local front=victimRoot.CFrame.LookVector:Dot(direction.Unit)
    if front>=Config.Combat.BlockDot then
      local started=tonumber(victim:GetAttribute("BlockStarted"))or 0
      if os.clock()-started<=Config.Combat.ParryWindow then
        victim:SetAttribute("HitStunUntil",os.clock()+Config.Combat.Stun)
        send(victim,"Parry",{Position=victimRoot.Position})
        send(attacker,"Parried",{Position=attackerRoot.Position})
      else
        send(victim,"Guard",{Position=victimRoot.Position})
        send(attacker,"Guarded",{Position=victimRoot.Position})
      end
      return
    end
  end
  victimHumanoid:TakeDamage(damage)
  if victim then victim:SetAttribute("HitStunUntil",os.clock()+Config.Combat.Stun) end
  if victimRoot and victimRoot:IsA("BasePart") and attackerRoot and attackerRoot:IsA("BasePart") then
    victimRoot.AssemblyLinearVelocity=attackerRoot.CFrame.LookVector*knockback+Vector3.new(0,7,0)
  end
  addCredits(attacker,0)
  addXP(attacker,Config.Progression.HitXP)
  attacker:SetAttribute("Energy",math.min(Config.Resources.MaxEnergy,(tonumber(attacker:GetAttribute("Energy"))or 0)+Config.Resources.HitEnergy))
  attacker:SetAttribute("Overdrive",math.min(100,(tonumber(attacker:GetAttribute("Overdrive"))or 0)+Config.Resources.DamageOverdrive*damage+Config.Resources.HitOverdrive))
  send(attacker,"Hit",{Position=victimRoot and victimRoot.Position or attackerRoot.Position,Damage=damage,Finisher=finisher})
  if victim then send(victim,"HitTaken",{Position=victimRoot and victimRoot.Position or attackerRoot.Position,Damage=damage}) end
  if victimHumanoid.Health<=0 then
    addKO(attacker)
    if victim then
      local stats=victim:FindFirstChild("leaderstats")
      local streak=stats and stats:FindFirstChild("Streak")
      if streak and streak:IsA("IntValue") then streak.Value=0 end
    end
  end
end

local function light(player:Player)
  local character,humanoid,root=charParts(player)
  if not character or not humanoid or not root then return end
  if os.clock()<(tonumber(player:GetAttribute("HitStunUntil"))or 0) then return end
  local t=os.clock()
  if t<(tonumber(player:GetAttribute("NextLight"))or 0) then return end
  local combo=tonumber(player:GetAttribute("Combo"))or 0
  local started=tonumber(player:GetAttribute("ComboStarted"))or 0
  if t-started>Config.Combat.ComboReset then combo=0 end
  combo=(combo%4)+1
  player:SetAttribute("Combo",combo)
  player:SetAttribute("ComboStarted",t)
  player:SetAttribute("NextLight",t+Config.Combat.Light.Cooldown)
  player:SetAttribute("LastCombatAt",t)
  local cf=root.CFrame*CFrame.new(0,0,-Config.Combat.Light.Offset)
  local damage=Config.Combat.Light.Damage[combo]
  damageCover(player,cf.Position,5.5,damage)
  for _,target in ipairs(targetHumanoids(player,cf,Config.Combat.Light.Hitbox)) do
    applyHit(player,target,damage,Config.Combat.Light.Knockback[combo],combo==4)
  end
  send(player,"Swing",{Combo=combo,Position=root.Position})
end

local function dash(player:Player)
  local _,humanoid,root=charParts(player)
  if not humanoid or not root then return end
  local t=os.clock()
  if t<(tonumber(player:GetAttribute("NextDash"))or 0) or t<(tonumber(player:GetAttribute("HitStunUntil"))or 0) then return end
  player:SetAttribute("NextDash",t+Config.Combat.Dash.Cooldown)
  player:SetAttribute("LastCombatAt",t)
  player:SetAttribute("Blocking",false)
  player:SetAttribute("DashUntil",t+Config.Combat.Dash.Duration)
  root.AssemblyLinearVelocity=root.CFrame.LookVector*Config.Combat.Dash.Speed+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
  send(player,"Dash",{Position=root.Position})
end

local function block(player:Player,active:boolean)
  local _,humanoid,root=charParts(player)
  if not humanoid or not root then return end
  if active and os.clock()<(tonumber(player:GetAttribute("HitStunUntil"))or 0) then return end
  player:SetAttribute("Blocking",active)
  player:SetAttribute("BlockStarted",active and os.clock() or 0)
  send(player,"Block",active)
end

local function special(player:Player)
  local _,humanoid,root=charParts(player)
  if not humanoid or not root then return end
  local t=os.clock()
  local energy=tonumber(player:GetAttribute("Energy"))or 0
  if t<(tonumber(player:GetAttribute("NextSpecial"))or 0) or energy<Config.Combat.Special.EnergyCost then return end
  player:SetAttribute("NextSpecial",t+Config.Combat.Special.Cooldown)
  player:SetAttribute("LastCombatAt",t)
  player:SetAttribute("Energy",energy-Config.Combat.Special.EnergyCost)
  local charged=(tonumber(player:GetAttribute("Overdrive"))or 0)>=100
  local damage=Config.Combat.Special.Damage+(charged and Config.Combat.Special.OverdriveBonus or 0)
  damageCover(player,root.Position,Config.Combat.Special.Radius,damage)
  local count=0
  for _,target in ipairs(targetRadius(player,root.Position,Config.Combat.Special.Radius)) do
    applyHit(player,target,damage,Config.Combat.Special.Knockback,charged)
    count+=1
  end
  if charged then player:SetAttribute("Overdrive",0) end
  send(player,"Special",{Position=root.Position,Charged=charged,Hits=count})
end

local function validRequest(player:Player):boolean
  local t=os.clock()
  local state=requestState[player]
  if not state then state={Window=t,Count=0};requestState[player]=state end
  if t-state.Window>=1 then state.Window=t;state.Count=0 end
  state.Count+=1
  return state.Count<=Config.Combat.RequestRate
end

local function travel(player:Player,nodeId:any)
  if typeof(nodeId)~="string" then return end
  local node=Routes.Get(nodeId)
  local _,humanoid,root=charParts(player)
  if not node or not humanoid or not root or not workspace:GetAttribute("CollisionBattlestarMapReady") then return end
  local t=os.clock()
  if (travelCooldown[player]or 0)>t or t-(tonumber(player:GetAttribute("LastCombatAt"))or 0)<1.2 then return end
  if player:GetAttribute("Blocking")==true then return end
  travelCooldown[player]=t+.7
  root.CFrame=CFrame.new(node.Position+Vector3.new(0,5,0))
  root.AssemblyLinearVelocity=Vector3.zero
  player:SetAttribute("CurrentMapNode",node.Id)
  send(player,"Travel",{Name=node.Name,Subtitle=node.Subtitle})
end

local function syncShop(player:Player)
  local p=profiles[player] or defaultProfile()
  local owned={}
  for id,yes in pairs(p.Owned) do if yes then table.insert(owned,id) end end
  table.sort(owned)
  remotes.UtilityFeedback:FireClient(player,"ShopSync",{Owned=owned,Equipped=p.Equipped})
  player:SetAttribute("EquippedItem",p.Equipped)
end

local function buyItem(player:Player,id:any)
  if typeof(id)~="string" then return end
  local item=Catalog.Get(id)
  local p=profiles[player]
  local stats=player:FindFirstChild("leaderstats")
  local credits=stats and stats:FindFirstChild("Credits")
  if not item or not p or not p.Loaded or not credits or not credits:IsA("IntValue") then return end
  if p.Owned[id] then
    remotes.UtilityFeedback:FireClient(player,"Message","ALREADY OWNED")
    return
  end
  if credits.Value<item.Price then
    remotes.UtilityFeedback:FireClient(player,"Message","NEED "..tostring(item.Price-credits.Value).." MORE CREDITS")
    return
  end
  credits.Value-=item.Price
  p.Owned[id]=true
  p.Equipped=id
  save(player)
  syncShop(player)
  remotes.UtilityFeedback:FireClient(player,"Message","UNLOCKED  •  "..item.Name)
end

local codes={BATTLESTAR=250,NOVA=100,BATTLELINE=150}

local function redeem(player:Player,raw:any)
  if typeof(raw)~="string" then return end
  local key=string.upper(raw:gsub("%s+",""))
  local p=profiles[player]
  local amount=codes[key]
  if not p or not p.Loaded or not amount then
    remotes.UtilityFeedback:FireClient(player,"Message","INVALID CODE")
    return
  end
  if p.Redeemed[key] then
    remotes.UtilityFeedback:FireClient(player,"Message","CODE ALREADY USED")
    return
  end
  p.Redeemed[key]=true
  addCredits(player,amount)
  save(player)
  remotes.UtilityFeedback:FireClient(player,"Message","CODE REDEEMED  •  +"..amount.." C")
end

local function equip(player:Player,id:any)
  if typeof(id)~="string" then return end
  local p=profiles[player]
  if not p or not p.Owned[id] then return end
  p.Equipped=id
  save(player)
  syncShop(player)
  local item=Catalog.Get(id)
  remotes.UtilityFeedback:FireClient(player,"Message","EQUIPPED  •  "..(item and item.Name or id))
end

local function emote(player:Player,id:any)
  if typeof(id)~="string" then return end
  local p=profiles[player]
  if not p or not p.Owned[id] then return end
  send(player,"Emote",{Id=id})
end

buildMap()

Players.PlayerAdded:Connect(function(player)
  load(player)
  player.CharacterAdded:Connect(function(character) configureCharacter(player,character) end)
  task.spawn(function()
    task.wait(.15)
    if player.Parent then
      spawnPlayer(player)
    end
  end)
end)

for _,player in ipairs(Players:GetPlayers()) do
  load(player)
  player.CharacterAdded:Connect(function(character) configureCharacter(player,character) end)
  task.spawn(function() spawnPlayer(player) end)
end

Players.PlayerRemoving:Connect(function(player)
  save(player)
  profiles[player]=nil
  requestState[player]=nil
  travelCooldown[player]=nil
end)

task.spawn(function()
  while true do
    task.wait(.25)
    for _,player in ipairs(Players:GetPlayers()) do
      local energy=tonumber(player:GetAttribute("Energy"))or 0
      local maxEnergy=tonumber(player:GetAttribute("MaxEnergy"))or Config.Resources.MaxEnergy
      if energy<maxEnergy then player:SetAttribute("Energy",math.min(maxEnergy,energy+Config.Resources.EnergyRegen*.25)) end
      if (tonumber(player:GetAttribute("ComboStarted"))or 0)+Config.Combat.ComboReset<os.clock() then player:SetAttribute("Combo",0) end
    end
  end
end)

game:BindToClose(function()
  for _,player in ipairs(Players:GetPlayers()) do save(player) end
  task.wait(2)
end)

remotes.CombatRequest.OnServerEvent:Connect(function(player,action,value)
  if typeof(action)~="string" or not validRequest(player) then return end
  if action=="Light" then light(player)
  elseif action=="Dash" then dash(player)
  elseif action=="BlockStart" then block(player,true)
  elseif action=="BlockEnd" then block(player,false)
  elseif action=="Special" then special(player)
  end
end)

remotes.MovementRequest.OnServerEvent:Connect(function(player,action,value)
  if typeof(action)~="string" or action~="Sprint" or not validRequest(player) then return end
  local _,humanoid=charParts(player)
  if humanoid then humanoid.WalkSpeed=value==true and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed end
end)

mapTravel.OnServerEvent:Connect(travel)

utility.OnServerEvent:Connect(function(player,action,value)
  if typeof(action)~="string" or not validRequest(player) then return end
  if action=="ShopState" then syncShop(player)
  elseif action=="BuyItem" then buyItem(player,value)
  elseif action=="EquipItem" then equip(player,value)
  elseif action=="RedeemCode" then redeem(player,value)
  elseif action=="PlayEmote" then emote(player,value)
  elseif action=="Ping" then
    if typeof(value)=="Vector3" then
      local _,humanoid,root=charParts(player)
      if humanoid and root and (value-root.Position).Magnitude<=220 then
        local marker=basePart(workspace,"CBS_Ping",Vector3.new(1.2,1.2,1.2),value+Vector3.new(0,1.2,0),Config.UI.Accent,Enum.Material.Neon,false,false)
        marker.Shape=Enum.PartType.Ball
        Debris:AddItem(marker,3)
        remotes.UtilityFeedback:FireAllClients("Ping",{Position=marker.Position,Owner=player.UserId})
      end
    end
  elseif action=="Respawn" then
    local _,humanoid=charParts(player)
    if not humanoid or humanoid.Health<=0 then spawnPlayer(player) end
  end
end)

remotes.GameState:FireAllClients("Ready",Config.Version)
