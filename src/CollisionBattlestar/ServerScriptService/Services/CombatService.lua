--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Config=require(ReplicatedStorage.Shared.Config)
local U=require(ReplicatedStorage.Shared.Util)

local S={}
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("CombatRequest")
local feedback=remotes:WaitForChild("Feedback")
local state={}

local function now():number return os.clock() end

local function getCharacter(player:Player):(Model?,Humanoid?,BasePart?)
	local character=player.Character
	local humanoid=U.Humanoid(character)
	local root=U.Root(character)
	if not character or not humanoid or not root or humanoid.Health<=0 then return nil,nil,nil end
	return character,humanoid,root
end

local function markCombat(player:Player)
	player:SetAttribute("LastCombatAt",now())
end

local function targetHumanoids(attacker:Player,cframe:CFrame,size:Vector3):{Humanoid}
	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={attacker.Character}
	params.MaxParts=40
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

local function hit(attacker:Player,humanoid:Humanoid,damage:number,knockback:number)
	local victim=Players:GetPlayerFromCharacter(humanoid.Parent)
	if victim and victim:GetAttribute("Blocking")==true then
		local started=tonumber(victim:GetAttribute("BlockStarted"))or 0
		if now()-started<=Config.Combat.ParryWindow then
			feedback:FireClient(attacker,"Parry")
			feedback:FireClient(victim,"Parry")
			local _,_,root=getCharacter(attacker)
			if root then root.AssemblyLinearVelocity=-root.CFrame.LookVector*42+Vector3.new(0,18,0) end
			return
		end
		damage*=Config.Combat.BlockMultiplier
	end

	local root=U.Root(humanoid.Parent)
	if root then
		local attackerRoot=U.Root(attacker.Character)
		local direction=attackerRoot and (root.Position-attackerRoot.Position).Unit or Vector3.new(0,0,-1)
		root.AssemblyLinearVelocity=direction*knockback+Vector3.new(0,knockback*.22,0)
	end
	humanoid:TakeDamage(damage)
	feedback:FireClient(attacker,"Hit",{Position=root and root.Position or Vector3.zero,Damage=damage})
	feedback:FireClient(Players:GetPlayerFromCharacter(humanoid.Parent) or attacker,"HitTaken",{Position=root and root.Position or Vector3.zero,Damage=damage})
	if humanoid.Health<=0 then
		local playerService=require(script.Parent.PlayerService)
		playerService.AddKO(attacker)
		if victim then playerService.ResetStreak(victim) end
	end
end

local function light(player:Player)
	local character,_,root=getCharacter(player)
	if not character or not root then return end
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
	local knockback=combo==4 and action.Knockback*1.8 or action.Knockback
	for _,humanoid in ipairs(targetHumanoids(player,cframe,action.Size)) do
		hit(player,humanoid,action.Damage,knockback)
	end
	feedback:FireClient(player,"Swing",{Combo=combo})
end

local function special(player:Player)
	local _,_,root=getCharacter(player)
	if not root then return end
	local t=now()
	if t<(tonumber(player:GetAttribute("NextSpecial"))or 0) then return end
	player:SetAttribute("NextSpecial",t+Config.Combat.Actions.Special.Cooldown)
	markCombat(player)
	for _,humanoid in ipairs(targetHumanoids(player,root.CFrame,Vector3.new(Config.Combat.Actions.Special.Radius*2,10,Config.Combat.Actions.Special.Radius*2))) do
		hit(player,humanoid,Config.Combat.Actions.Special.Damage,Config.Combat.Actions.Special.Knockback)
	end
	feedback:FireClient(player,"Special")
end

local function dash(player:Player)
	local _,humanoid,root=getCharacter(player)
	if not humanoid or not root then return end
	local t=now()
	if t<(tonumber(player:GetAttribute("NextDash"))or 0) then return end
	player:SetAttribute("NextDash",t+Config.Combat.Dash.Cooldown)
	markCombat(player)
	player:SetAttribute("DashInvulnerable",true)
	root.AssemblyLinearVelocity=root.CFrame.LookVector*Config.Combat.Dash.Speed+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
	feedback:FireClient(player,"Dash")
	task.delay(Config.Combat.Dash.Duration,function()
		if player.Parent then player:SetAttribute("DashInvulnerable",false) end
	end)
end

local function setBlock(player:Player,active:boolean)
	if not getCharacter(player) then return end
	player:SetAttribute("Blocking",active)
	player:SetAttribute("BlockStarted",active and now() or 0)
	if active then markCombat(player) end
	feedback:FireClient(player,"Block",active)
end

function S.Init()
	request.OnServerEvent:Connect(function(player,action)
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
	Players.PlayerRemoving:Connect(function(player)state[player]=nil end)
end

return S
