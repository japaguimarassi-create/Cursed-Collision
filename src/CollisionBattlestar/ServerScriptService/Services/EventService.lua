--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local TweenService=game:GetService("TweenService")
local C=require(R.Shared.Config);local World=require(script.Parent.WorldStateService)
local S={Active=false,Last=-math.huge,KillChain=0};local enemies;local builder
local function send(kind:string,payload:any?)R.CollisionRemotes.WorldState:FireAllClients(kind,payload)end
function S.Init(enemyModule,builderModule)
	enemies=enemyModule;builder=builderModule
	enemies.Defeated.Event:Connect(function(_,_,kind:string)
		S.KillChain+=1;World.AddThreat(kind=="Boss"and 18 or 3);World.AddEnergy(kind=="Boss"and 12 or 2)
		if S.KillChain>=C.Events.ChainKillThreshold and not S.Active then S.KillChain=0;task.delay(3,function()S.StartRealityBreak("CollisionChain")end)end
	end)
	task.delay(C.Events.FirstRealityBreakDelay,function()if #Players:GetPlayers()>0 then S.StartRealityBreak("FirstBreak")end end)
	task.spawn(function()while task.wait(30)do if #Players:GetPlayers()>0 and not S.Active and os.clock()-S.Last>=C.Events.RealityBreakCooldown then local w=World.GetSnapshot();local pressure=w.Threat+w.Energy+w.Activity;if pressure>150 and math.random(1,100)<=45 then S.StartRealityBreak("Pressure")elseif math.random(1,100)<=8 then S.StartRealityBreak("Rare")end end end end)
end
function S.StartRealityBreak(reason:string):boolean
	if S.Active or os.clock()-S.Last<C.Events.RealityBreakCooldown then return false end
	S.Active=true;S.Last=os.clock();World.RegisterEvent("RealityBreak:"..reason);send("Warning",{Duration=7,Reason=reason})
	local atmosphere=game.Lighting:FindFirstChildOfClass("Atmosphere")or Instance.new("Atmosphere");atmosphere.Parent=game.Lighting;local d,h=atmosphere.Density,atmosphere.Haze
	TweenService:Create(atmosphere,TweenInfo.new(4),{Density=.55,Haze=2.8}):Play()
	task.wait(7);send("Begin",{Reason=reason});local anchor=workspace:FindFirstChild("RealityBreakCenter");local pos=anchor and anchor:IsA("BasePart")and anchor.Position or C.Region.EventAnchor
	for i=1,8 do enemies.Spawn(i%3==0 and"Caster"or"Hunter",pos+Vector3.new(math.random(-55,55),3,math.random(-55,55)))end
	builder.AnimateRealityBreak(true);World.AddThreat(20);World.AddEnergy(25);send("Escalation",{Duration=18});task.wait(18)
	enemies.SpawnMiniBoss(pos+Vector3.new(0,5,0));send("Climax",{Title="RIFT WARDEN",Subtitle="An apex collision threat has emerged."});task.wait(22)
	builder.AnimateRealityBreak(false);TweenService:Create(atmosphere,TweenInfo.new(7),{Density=d,Haze=h}):Play();send("End",{Reason=reason});S.Active=false;World.RegisterEvent("RealityBreakResolved");return true
end
return S
