--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)
local U=require(ReplicatedStorage.Shared.Util)
local PlayerService=require(script.Parent.PlayerService)
local DestructionService=require(script.Parent.DestructionService)
local S={}
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("CombatRequest")
local feedback=remotes:WaitForChild("Feedback")
local state:{[Player]:{WindowStart:number,Count:number}}={}

local function now():number return os.clock() end

local function getCharacter(player:Player):(Model?,Humanoid?,BasePart?)
	local character=player.Character
	local humanoid=U.Humanoid(character)
	local root=U.Root(character)
	if not character or not humanoid or not root or humanoid.Health<=0 then return nil,nil,nil end
	return character,humanoid,root
end

local function isStunned(player:Player):boolean
	return now()<(tonumber(player:GetAttribute("HitStunUntil"))or 0)
end

local function markCombat(player:Player)
	player:SetAttribute("LastCombatAt",now())
end

local function addOverdrive(player:Player,amount:number)
	player:SetAttribute("Overdrive",math.clamp((tonumber(player:GetAttribute("Overdrive"))or 0)+amount,0,100))
end

local function targetsBox(attacker:Player,cframe:CFrame,size:Vector3):{Humanoid}
	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={attacker.Character}
	params.MaxParts=48
	local found={}
	local seen={}
	for _,part in ipairs(workspace:GetPartBoundsInBox(cframe,size,params)) do
		local model=U.Model(part)
		local humanoid=model and U.Humanoid(model)
		if model and humanoid and humanoid.Health>0 and model~=attacker.Character and not seen[humanoid] then
			seen[humanoid]=true
			table.insert(found,humanoid)
		end
	end
	return found
end

local function targetsRadius(attacker:Player,position:Vector3,radius:number):{Humanoid}
	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={attacker.Character}
	params.MaxParts=64
	local found={}
	local seen={}
	for _,part in ipairs(workspace:GetPartBoundsInRadius(position,radius,params)) do
		local model=U.Model(part)
		local humanoid=model and U.Humanoid(model)
		if model and humanoid and humanoid.Health>0 and model~=attacker.Character and not seen[humanoid] then
			seen[humanoid]=true
			table.insert(found,humanoid)
		end
	end
	return found
end

local function hit(attacker:Player,humanoid:Humanoid,damage:number,knockback:number,finisher:boolean?)
	local model=humanoid.Parent
	if not model or not model:IsA("Model") then return end
	local victim=Players:GetPlayerFromCharacter(model)
	if victim and victim:GetAttribute("DashInvulnerable")==true then
		feedback:FireClient(attacker,"Evade",{Position=U.Root(model) and U.Root(model).Position or Vector3.zero})
		return
	end
	if victim and victim:GetAttribute("Blocking")==true then
		local victimRoot=U.Root(model)
		local attackerRoot=U.Root(attacker.Character)
		local direction=attackerRoot and victimRoot and U.SafeUnit(attackerRoot.Position-victimRoot.Position,Vector3.new(0,0,-1)) or Vector3.new(0,0,-1)
		local front=victimRoot and victimRoot.CFrame.LookVector:Dot(direction) or -1
		local started=tonumber(victim:GetAttribute("BlockStarted"))or 0
		if front>=Config.Combat.FrontBlockDot then
			if now()-started<=Config.Combat.ParryWindow then
				feedback:FireClient(attacker,"Parry")
				feedback:FireClient(victim,"Parry")
				if attackerRoot then attackerRoot.AssemblyLinearVelocity=-attackerRoot.CFrame.LookVector*42+Vector3.new(0,20,0) end
				return
			end
			damage*=Config.Combat.BlockMultiplier
			feedback:FireClient(victim,"Guard",{Position=victimRoot and victimRoot.Position or Vector3.zero})
		else
			feedback:FireClient(victim,"GuardBreak",{Position=victimRoot and victimRoot.Position or Vector3.zero})
		end
	end
	local root=U.Root(model)
	local attackerRoot=U.Root(attacker.Character)
	if root and attackerRoot then
		local direction=U.SafeUnit(root.Position-attackerRoot.Position,attackerRoot.CFrame.LookVector)
		root.AssemblyLinearVelocity=direction*knockback+Vector3.new(0,knockback*.18,0)
	end
	feedback:FireClient(attacker,"Hit",{Position=root and root.Position or Vector3.zero,Damage=damage,Finisher=finisher==true})
	if victim then feedback:FireClient(victim,"HitTaken",{Position=root and root.Position or Vector3.zero,Damage=damage,Finisher=finisher==true}) end
	humanoid:TakeDamage(damage)
	if victim then victim:SetAttribute("HitStunUntil",now()+Config.Combat.Stun) end
	addOverdrive(attacker,math.clamp(damage*.45,2,15))
	PlayerService.AddXP(attacker,1)
	if humanoid.Health<=0 then
		PlayerService.AddKO(attacker)
		if victim then PlayerService.ResetStreak(victim) end
	end
end

local function light(player:Player)
	local character,_,root=getCharacter(player)
	if not character or not root or isStunned(player) then return end
	local t=now()
	if t<(tonumber(player:GetAttribute("NextLight"))or 0) then return end
	local combo=tonumber(player:GetAttribute("Combo"))or 0
	local started=tonumber(player:GetAttribute("ComboStarted"))or 0
	if t-started>Config.Combat.ComboReset then combo=0 end
	combo=math.clamp(combo+1,1,4)
	player:SetAttribute("Combo",combo)
	player:SetAttribute("ComboStarted",t)
	player:SetAttribute("NextLight",t+Config.Combat.Actions.Light.Cooldown)
	markCombat(player)
	local action=Config.Combat.Actions.Light
	local offset=action.Offset+(combo==4 and 1 or 0)
	local cframe=root.CFrame*CFrame.new(0,0,-offset)
	local knockback=combo==4 and action.Knockback*2.2 or action.Knockback
	local damage=Config.Combat.ComboDamage[combo]
	DestructionService.TryDamage(player,cframe.Position,math.max(4.5,action.Size.Z*.52),damage)
	for _,humanoid in ipairs(targetsBox(player,cframe,action.Size)) do hit(player,humanoid,damage,knockback,combo==4) end
	feedback:FireClient(player,"Swing",{Combo=combo,Position=root.Position})
end

local function special(player:Player)
	local character,_,root=getCharacter(player)
	if not character or not root or isStunned(player) then return end
	local t=now()
	if t<(tonumber(player:GetAttribute("NextSpecial"))or 0) then return end
	player:SetAttribute("NextSpecial",t+Config.Combat.Actions.Special.Cooldown)
	markCombat(player)
	local overdrive=tonumber(player:GetAttribute("Overdrive"))or 0
	local charged=overdrive>=100
	local damage=Config.Combat.Actions.Special.Damage+(charged and Config.Combat.Actions.Special.OverdriveBonus or 0)
	DestructionService.TryDamage(player,root.Position,Config.Combat.Actions.Special.Radius,damage)
	local hitCount=0
	for _,humanoid in ipairs(targetsRadius(player,root.Position,Config.Combat.Actions.Special.Radius)) do
		hit(player,humanoid,damage,Config.Combat.Actions.Special.Knockback,charged)
		hitCount+=1
	end
	if charged then player:SetAttribute("Overdrive",0) end
	feedback:FireClient(player,"Special",{Position=root.Position,Charged=charged,Hits=hitCount})
end

local function dash(player:Player)
	local _,humanoid,root=getCharacter(player)
	if not humanoid or not root or isStunned(player) then return end
	local t=now()
	if t<(tonumber(player:GetAttribute("NextDash"))or 0) then return end
	player:SetAttribute("NextDash",t+Config.Combat.Dash.Cooldown)
	markCombat(player)
	player:SetAttribute("DashInvulnerable",true)
	player:SetAttribute("Blocking",false)
	root.AssemblyLinearVelocity=root.CFrame.LookVector*Config.Combat.Dash.Speed+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
	feedback:FireClient(player,"Dash",{Position=root.Position})
	task.delay(Config.Combat.Dash.Duration,function()
		if player.Parent then player:SetAttribute("DashInvulnerable",false) end
	end)
end

local function setBlock(player:Player,active:boolean)
	if not getCharacter(player) then return end
	if active and isStunned(player) then return end
	player:SetAttribute("Blocking",active)
	player:SetAttribute("BlockStarted",active and now() or 0)
	if active then markCombat(player) end
	feedback:FireClient(player,"Block",active)
end

function S.Init()
	request.OnServerEvent:Connect(function(player,action,value)
		local entry=state[player]
		local t=now()
		if not entry then entry={WindowStart=t,Count=0};state[player]=entry end
		if t-entry.WindowStart>=1 then entry.WindowStart=t;entry.Count=0 end
		entry.Count+=1
		if entry.Count>Config.Combat.RequestRate then return end
		if typeof(action)~="string" then return end
		if action=="Light" then light(player)
		elseif action=="Dash" then dash(player)
		elseif action=="BlockStart" then setBlock(player,true)
		elseif action=="BlockEnd" then setBlock(player,false)
		elseif action=="Special" then special(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player) state[player]=nil end)
end
return S
