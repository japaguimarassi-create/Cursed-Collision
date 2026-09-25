--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local C=require(R.Shared.Config);local D=require(R.Shared.CombatDefinitions);local U=require(R.Shared.Util);local Anti=require(script.Parent.Parent.Security.AntiCheatService)
local S={};local states:{[Player]:any}={}
local function state(p:Player)local s=states[p];if s then return s end;s={Busy=0,LastLight=0,Combo=0,LastDash=0,LastSpecial=0,LastOverdrive=0,IsBlocking=false,ParryUntil=0,Momentum=0,Instability=0,Overdrive=false,Style="Blade"};states[p]=s;return s end
local function sync(p:Player,s:any)p:SetAttribute("Momentum",math.floor(s.Momentum));p:SetAttribute("Instability",math.floor(s.Instability));p:SetAttribute("Overdrive",s.Overdrive);p:SetAttribute("IsBlocking",s.IsBlocking);p:SetAttribute("ParryUntil",s.ParryUntil);p:SetAttribute("CombatStyle",s.Style)end
local function fb(p:Player,k:string,v:any?)R.CollisionRemotes.Feedback:FireClient(p,k,v)end
local function performHit(p:Player,s:any,name:string,d:any,scale:number?)
	local root=U.Root(p.Character);local hum=U.Hum(p.Character);if not root or not hum or hum.Health<=0 then return end
	local style=C.Styles[s.Style];local range=d.Range*style.Range;local cf=root.CFrame*CFrame.new(0,0,-(range*.5+1.5));local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={p.Character}
	local seen:{[Model]=boolean}={}
	for _,part in workspace:GetPartBoundsInBox(cf,Vector3.new(d.Width*style.Range,d.Height,range),params)do local model=U.Model(part);if model and not seen[model]then seen[model]=true;local targetHum=U.Hum(model);local targetRoot=U.Root(model);local targetPlayer=Players:GetPlayerFromCharacter(model);local enemy=model:GetAttribute("Archetype")~=nil
		if targetHum and targetRoot and targetHum.Health>0 and ((enemy and not targetPlayer)or(targetPlayer and targetPlayer~=p))then
			local targetState=targetPlayer and states[targetPlayer]
			if targetState and targetState.ParryUntil>=os.clock()then s.Busy=os.clock()+.6;s.Momentum=U.Clamp(s.Momentum-18,0,100);fb(p,"Parried");fb(targetPlayer,"ParrySuccess");continue end
			local styleScale=(name=="Light"and style.Light)or(name=="Heavy"and style.Heavy)or style.Special;local damage=d.Damage*styleScale*(scale or 1);if s.Overdrive then damage*=C.Combat.Actions.Overdrive.Power end
			local blocked=targetPlayer and targetPlayer:GetAttribute("IsBlocking")==true
			if blocked and not d.GuardBreak then damage*=C.Combat.BlockMultiplier elseif blocked and d.GuardBreak and targetState then targetState.IsBlocking=false;targetState.ParryUntil=0;sync(targetPlayer,targetState);fb(targetPlayer,"GuardBreak")end
			targetHum:TakeDamage(damage);model:SetAttribute("LastHitUserId",p.UserId);local push=targetRoot.Position-root.Position;if push.Magnitude>.1 then targetRoot.AssemblyLinearVelocity=push.Unit*d.Knockback+Vector3.new(0,8,0)end
			s.Momentum=U.Clamp(s.Momentum+d.MomentumGain,0,100);if s.Overdrive then s.Instability=U.Clamp(s.Instability+C.Combat.Actions.Overdrive.InstabilityPerAction,0,100)end
			fb(p,"Hit",{Position=targetRoot.Position,Action=name,Damage=math.floor(damage)});if targetPlayer then fb(targetPlayer,"HitTaken",{Position=targetRoot.Position,Damage=math.floor(damage)})end
		end
	end end
	if s.Overdrive and s.Instability>=100 then s.Overdrive=false;s.Busy=os.clock()+.8;s.Momentum=U.Clamp(s.Momentum-25,0,100);fb(p,"OverdriveCollapse")end;sync(p,s)
end
local function request(p:Player,action:string)
	if not Anti.Allow(p)or not Anti.Validate(action)then return end;local s=state(p);local now=os.clock();local h=U.Hum(p.Character);local root=U.Root(p.Character);if not h or not root or h.Health<=0 then return end
	if action=="BlockStart"then s.IsBlocking=true;s.ParryUntil=now+C.Combat.ParryWindow;sync(p,s);fb(p,"BlockStart");return end
	if action=="BlockEnd"then s.IsBlocking=false;s.ParryUntil=0;sync(p,s);return end
	if action=="StyleToggle"then s.Style=s.Style=="Blade"and"Martial"or"Blade";sync(p,s);fb(p,"Style",s.Style);return end
	if now<s.Busy or s.IsBlocking then return end
	if action=="Parry"then s.ParryUntil=now+C.Combat.ParryWindow;s.Busy=now+.32;s.Momentum=U.Clamp(s.Momentum+3,0,100);sync(p,s);fb(p,"Parry");return end
	if action=="Dash"then if now-s.LastDash<C.Combat.Actions.Dash.Cooldown then return end;s.LastDash=now;s.Busy=now+C.Combat.Actions.Dash.Duration;local dir=h.MoveDirection;if dir.Magnitude<.1 then dir=root.CFrame.LookVector end;root.AssemblyLinearVelocity=dir.Unit*(C.Combat.Actions.Dash.Distance/C.Combat.Actions.Dash.Duration);s.Momentum=U.Clamp(s.Momentum+C.Combat.Actions.Dash.MomentumGain,0,100);sync(p,s);fb(p,"Dash");return end
	if action=="Overdrive"then if s.Overdrive or now-s.LastOverdrive<C.Combat.Actions.Overdrive.Cooldown then return end;if s.Momentum<C.Combat.Actions.Overdrive.MinimumMomentum then fb(p,"OverdriveDenied","Momentum too low");return end;s.LastOverdrive=now;s.Overdrive=true;s.Instability=0;sync(p,s);fb(p,"OverdriveStart");return end
	local d=C.Combat.Actions[action];if not d then return end
	if action=="Light"then if now-s.LastLight>.85 then s.Combo=0 end;s.Combo=math.clamp(s.Combo+1,1,4);s.LastLight=now;s.Busy=now+d.Startup+d.Recovery;local mult=D.LightChain[s.Combo];task.delay(d.Startup,function()if states[p]==s then performHit(p,s,action,d,mult)end end);fb(p,"Swing",{Combo=s.Combo})
	elseif action=="Heavy"then s.Combo=0;s.Busy=now+d.Startup+d.Recovery;task.delay(d.Startup,function()if states[p]==s then performHit(p,s,action,d)end end);fb(p,"Swing",{Combo=0})
	elseif action=="Special"then if now-s.LastSpecial<d.Cooldown then return end;s.LastSpecial=now;s.Busy=now+d.Startup+d.Recovery;task.delay(d.Startup,function()if states[p]==s then performHit(p,s,action,d)end end);fb(p,"Special")end
	sync(p,s)
end
function S.Init()
	Anti.Init();R.CollisionRemotes.CombatRequest.OnServerEvent:Connect(request);Players.PlayerRemoving:Connect(function(p)states[p]=nil end)
	Players.PlayerAdded:Connect(function(p)local s=state(p);sync(p,s);p.CharacterAdded:Connect(function(c)local h=c:WaitForChild("Humanoid");s.Busy=0;s.LastLight=0;s.Combo=0;s.LastDash=0;s.LastSpecial=0;s.LastOverdrive=0;s.IsBlocking=false;s.ParryUntil=0;s.Momentum=0;s.Instability=0;s.Overdrive=false;sync(p,s);h.WalkSpeed=C.Combat.BaseWalkSpeed end);task.spawn(function()while p.Parent do task.wait(.25);local x=states[p];if not x then break end;if x.Overdrive then x.Instability=U.Clamp(x.Instability-C.Combat.Actions.Overdrive.InstabilityDrain*.25,0,100);if x.Instability<=0 then x.Overdrive=false end else x.Momentum=U.Clamp(x.Momentum-.8,0,100)end;sync(p,x)end end)end)
end
return S
