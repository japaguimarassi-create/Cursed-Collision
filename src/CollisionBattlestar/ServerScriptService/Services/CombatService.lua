--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local C=require(R.Shared.Config)
local D=require(R.Shared.CombatDefinitions)
local U=require(R.Shared.Util)
local Anti=require(script.Parent.Parent.Security.AntiCheatService)
local Destruction=require(script.Parent.DestructionService)
local Hitbox=require(script.Parent.HitboxService)
local Hybrid=require(R.Shared.HybridCombatRules)

local S={}
local states:{[Player]:any}={}

local function state(p:Player)
	local s=states[p]
	if s then return s end
	s={Busy=0,LastLight=0,Combo=0,LastDash=0,LastSpecial=0,LastOverdrive=0,IsBlocking=false,ParryUntil=0,Momentum=0,Instability=0,Overdrive=false,Style="Blade"}
	states[p]=s
	return s
end

local function sync(p:Player,s:any)
	p:SetAttribute("Momentum",math.floor(s.Momentum))
	p:SetAttribute("Instability",math.floor(s.Instability))
	p:SetAttribute("Overdrive",s.Overdrive)
	p:SetAttribute("IsBlocking",s.IsBlocking)
	p:SetAttribute("ParryUntil",s.ParryUntil)
	p:SetAttribute("CombatStyle",s.Style)
end

local function fb(p:Player,k:string,v:any?)
	R.CollisionRemotes.Feedback:FireClient(p,k,v)
end

local function performHit(p:Player,s:any,name:string,d:any,scale:number?)
	local character=p.Character
	local root=U.Root(character)
	local hum=U.Hum(character)
	if not root or not hum or hum.Health<=0 then return end
	local style=C.Styles[s.Style]
	if not style then return end
	local range=d.Range*style.Range
	local size=Vector3.new(d.Width*style.Range,d.Height,range)
	local cf=root.CFrame*CFrame.new(0,0,-(range*.5+1.5))
	local targets=Hitbox.Query(character,cf,size,{MaxTargets=12,LineOfSight=true})

	for _,target in ipairs(targets)do
		local model=target.Model
		local targetHum=target.Humanoid
		local targetRoot=target.Root
		local targetPlayer=target.Player
		local ownerUserId=tonumber(model:GetAttribute("BattleStreakOwnerUserId"))or 0
		if ownerUserId>0 and p.UserId~=ownerUserId then continue end

		local targetState=targetPlayer and states[targetPlayer]
		if targetState and targetState.ParryUntil>=os.clock()then
			s.Busy=os.clock()+.6
			s.Momentum=U.Clamp(s.Momentum-18,0,C.Combat.MomentumMax)
			fb(p,"Parried")
			fb(targetPlayer,"ParrySuccess")
			continue
		end

		local styleScale=(name=="Light"and style.Light)or(name=="Heavy"and style.Heavy)or style.Special
		local damage=d.Damage*styleScale*(scale or 1)
		if s.Overdrive then damage*=C.Combat.Actions.Overdrive.Power end

		local blocked=targetPlayer and targetPlayer:GetAttribute("IsBlocking")==true
		if blocked and not d.GuardBreak then
			damage*=C.Combat.BlockMultiplier
		elseif blocked and d.GuardBreak and targetState then
			targetState.IsBlocking=false
			targetState.ParryUntil=0
			sync(targetPlayer,targetState)
			fb(targetPlayer,"GuardBreak")
		end

		targetHum:TakeDamage(damage)
		model:SetAttribute("LastHitUserId",p.UserId)

		local push=targetRoot.Position-root.Position
		if push.Magnitude>.1 then
			local vertical=8
			if Hybrid.IsAirborne(hum)then
				vertical=s.Combo>=4 and -34 or 20
			end
			targetRoot.AssemblyLinearVelocity=push.Unit*d.Knockback+Vector3.new(0,vertical,0)
			if Hybrid.Features.WallImpact and Hybrid.IsNearWall(targetRoot.Position,push.Unit,5,model)then
				targetHum:TakeDamage(math.max(2,d.Damage*.18))
				Destruction.BreakInBox(targetRoot.CFrame,Vector3.new(10,10,10),1)
				fb(p,"WallImpact",{Position=targetRoot.Position,Action=name})
			end
		end

		s.Momentum=U.Clamp(s.Momentum+d.MomentumGain,0,C.Combat.MomentumMax)
		if s.Overdrive then
			s.Instability=U.Clamp(s.Instability+C.Combat.Actions.Overdrive.InstabilityPerAction,0,C.Combat.InstabilityMax)
		end

		local payload={Position=targetRoot.Position,Action=name,Damage=math.floor(damage)}
		fb(p,"Hit",payload)
		if targetPlayer then fb(targetPlayer,"HitTaken",payload)end
	end

	if name=="Heavy"or name=="Special"then
		local strength=name=="Special"and 2 or 1
		local broken=Destruction.BreakInBox(cf,size,strength)
		if broken>0 then
			fb(p,"BreakFX",{Position=cf.Position,Size=size,Strength=strength})
		end
	end

	if s.Overdrive and s.Instability>=C.Combat.InstabilityMax then
		s.Overdrive=false
		s.Busy=os.clock()+.8
		s.Momentum=U.Clamp(s.Momentum-25,0,C.Combat.MomentumMax)
		fb(p,"OverdriveCollapse")
	end
	sync(p,s)
end

local function request(p:Player,action:string)
	if not Anti.Allow(p)or not Anti.Validate(action)then return end
	local s=state(p)
	local now=os.clock()
	local previousAction=s.LastAction
	if action~="SprintStart"and action~="SprintEnd"then
		p:SetAttribute("LastCombatAt",now)
	end
	local hum=U.Hum(p.Character)
	local root=U.Root(p.Character)
	if not hum or not root or hum.Health<=0 then return end

	if action=="BlockStart"then
		s.LastAction=action
		s.IsBlocking=true
		s.ParryUntil=now+C.Combat.ParryWindow
		sync(p,s)
		fb(p,"BlockStart")
		return
	end

	if action=="BlockEnd"then
		s.LastAction=action
		s.IsBlocking=false
		s.ParryUntil=0
		sync(p,s)
		fb(p,"BlockEnd")
		return
	end

	if action=="StyleToggle"then
		s.LastAction=action
		s.Style=s.Style=="Blade"and"Martial"or"Blade"
		sync(p,s)
		fb(p,"Style",s.Style)
		return
	end

	if action=="SprintStart"or action=="SprintEnd"then return end
	if now<s.Busy or s.IsBlocking then return end

	if action=="Parry"then
		s.LastAction=action
		s.ParryUntil=now+C.Combat.ParryWindow
		s.Busy=now+.32
		s.Momentum=U.Clamp(s.Momentum+3,0,C.Combat.MomentumMax)
		sync(p,s)
		fb(p,"Parry")
		return
	end

	if action=="Dash"then
		if now-s.LastDash<C.Combat.Actions.Dash.Cooldown then return end
		s.LastAction=action
		s.LastDash=now
		s.Busy=now+C.Combat.Actions.Dash.Duration
		local dir=hum.MoveDirection
		if dir.Magnitude<.1 then dir=root.CFrame.LookVector end
		root.AssemblyLinearVelocity=dir.Unit*(C.Combat.Actions.Dash.Distance/C.Combat.Actions.Dash.Duration)
		s.Momentum=U.Clamp(s.Momentum+C.Combat.Actions.Dash.MomentumGain,0,C.Combat.MomentumMax)
		sync(p,s)
		fb(p,"Dash")
		return
	end

	if action=="Overdrive"then
		s.LastAction=action
		if s.Overdrive or now-s.LastOverdrive<C.Combat.Actions.Overdrive.Cooldown then return end
		if s.Momentum<C.Combat.Actions.Overdrive.MinimumMomentum then
			fb(p,"OverdriveDenied","Momentum too low")
			return
		end
		s.LastOverdrive=now
		s.Overdrive=true
		s.Instability=0
		sync(p,s)
		fb(p,"OverdriveStart")
		return
	end

	local d=C.Combat.Actions[action]
	if not d then return end

	if action=="Light"then
		if now-s.LastLight>Hybrid.ComboReset then s.Combo=0 end
		if previousAction=="Dash"then s.Busy=math.min(s.Busy,now+d.Startup*.55)end
		s.Combo=math.clamp(s.Combo+1,1,4)
		s.LastLight=now
		s.Busy=now+d.Startup+d.Recovery
		local combo=s.Combo
		local mult=D.LightChain[combo]or 1
		fb(p,"Swing",{Combo=combo,Action="Light"})
		task.delay(d.Startup,function()
			if states[p]==s then performHit(p,s,action,d,mult)end
		end)
	elseif action=="Heavy"then
		s.LastAction=action
		s.Combo=0
		s.Busy=now+d.Startup+d.Recovery
		fb(p,"Swing",{Combo=0,Action="Heavy"})
		task.delay(d.Startup,function()
			if states[p]==s then performHit(p,s,action,d)end
		end)
	elseif action=="Special"then
		s.LastAction=action
		if now-s.LastSpecial<d.Cooldown then return end
		s.LastSpecial=now
		s.Busy=now+d.Startup+d.Recovery
		fb(p,"Swing",{Combo=0,Action="Special"})
		task.delay(d.Startup,function()
			if states[p]==s then performHit(p,s,action,d)end
		end)
	end

	sync(p,s)
end

function S.Init()
	Anti.Init()
	R.CollisionRemotes.CombatRequest.OnServerEvent:Connect(request)
	Players.PlayerRemoving:Connect(function(p)states[p]=nil end)
	Players.PlayerAdded:Connect(function(p)
		local s=state(p)
		sync(p,s)
		p.CharacterAdded:Connect(function(c)
			local h=c:WaitForChild("Humanoid")
			s.Busy=0;s.LastLight=0;s.Combo=0;s.LastDash=0;s.LastSpecial=0;s.LastOverdrive=0
			s.IsBlocking=false;s.ParryUntil=0;s.Momentum=0;s.Instability=0;s.Overdrive=false
			sync(p,s)
			h.WalkSpeed=C.Combat.BaseWalkSpeed
		end)
		task.spawn(function()
			while p.Parent do
				task.wait(.25)
				local current=states[p]
				if not current then break end
				if current.Overdrive then
					current.Instability=U.Clamp(current.Instability-C.Combat.Actions.Overdrive.InstabilityDrain*.25,0,C.Combat.InstabilityMax)
					if current.Instability<=0 then current.Overdrive=false end
				else
					current.Momentum=U.Clamp(current.Momentum-.8,0,C.Combat.MomentumMax)
				end
				sync(p,current)
			end
		end)
	end)
end

return S
