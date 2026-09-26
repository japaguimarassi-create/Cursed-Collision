--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local Data=require(script.Parent.PlayerDataService)

local Service={}
local enemyService
local sessions:{[Player]:any}={}
local arenaCenter:Vector3?
local offsets={Vector3.new(-28,0,-18),Vector3.new(0,0,-24),Vector3.new(28,0,-18),Vector3.new(-28,0,18),Vector3.new(0,0,24),Vector3.new(28,0,18)}
local firstWaves={
	[1]={"Riftling","Riftling","Warden"},
	[2]={"Riftling","Warden","Hunter","Riftling"},
	[3]={"Warden","Hunter","Caster","Riftling"},
	[4]={"Hunter","Hunter","Caster","Warden","Riftling"},
	[5]={"Caster","Hunter","Warden","Hunter","Riftling","Caster"},
}
local function notify(p:Player,k:string,v:any?)R.CollisionRemotes.Feedback:FireClient(p,k,v)end
local function makeWave(wave:number):{string}
	if firstWaves[wave]then return table.clone(firstWaves[wave])end
	local pool={"Riftling","Warden","Caster","Hunter"};local count=math.min(10,3+math.floor(wave/2));local result={}
	for i=1,count do
		local kind=pool[((i+wave-1)%#pool)+1]
		if wave%10==0 and i==count then kind="Boss"elseif wave%5==0 and i==count then kind="MiniBoss"end
		table.insert(result,kind)
	end
	return result
end
local function spawnEnemy(kind:string,pos:Vector3,ownerUserId:number?):Model?
	if kind=="Boss" then
		return enemyService.SpawnBoss(pos,ownerUserId)
	elseif kind=="MiniBoss" then
		return enemyService.SpawnMiniBoss(pos,ownerUserId)
	end
	return enemyService.Spawn(kind,pos,ownerUserId)
end
local function getArenaCenter():Vector3
	if arenaCenter then return arenaCenter end
	local folder=workspace:FindFirstChild("BattleStreakArena")
	local floor=folder and folder:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart")then
		arenaCenter=floor.Position
		return arenaCenter
	end
	local fallback=Vector3.new(720,4,34)
	arenaCenter=fallback
	return fallback
end
local function spawnWave(p:Player)
	local s=sessions[p];if not s then return end
	local center=getArenaCenter()
	s.Kinds=makeWave(s.Wave);s.Alive=0
	for i,kind in ipairs(s.Kinds)do
		local m=spawnEnemy(kind,center+offsets[((i-1)%#offsets)+1]+Vector3.new(0,3,0),p.UserId)
		if m then s.Spawned[m]=true;s.Alive+=1;m:SetAttribute("BattleStreakWave",s.Wave)end
	end
	notify(p,"BattleStreakWave",{Wave=s.Wave,Best=(Data.Get(p)and Data.Get(p).BattleStreakBest)or 0})
	if s.Alive<=0 then
		task.defer(function()
			local current=sessions[p]
			if current==s then
				s.Wave+=1
				spawnWave(p)
			end
		end)
	end
end
local function stop(p:Player,reason:string)
	local s=sessions[p];if not s then return end
	Data.SetBattleStreakBest(p,s.Wave-1)
	for m in pairs(s.Spawned)do if m and m.Parent then m:Destroy()end end
	sessions[p]=nil;p:SetAttribute("BattleStreakActive",false);notify(p,"BattleStreakEnd",reason)
end
function Service.Init(enemy)
	enemyService=enemy
	local folder=workspace:FindFirstChild("BattleStreakArena");local start=folder and folder:FindFirstChild("StartPoint")
	if start and start:IsA("BasePart")then
		local prompt=Instance.new("ProximityPrompt")
		prompt.ActionText="Start Streak";prompt.ObjectText="BATTLE STREAK";prompt.HoldDuration=.6;prompt.MaxActivationDistance=12;prompt.Parent=start
		prompt.Triggered:Connect(function(p)
			if sessions[p]then return end
			local character=p.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health<=0 then return end
			sessions[p]={Wave=1,Alive=0,Spawned={}}
			p:SetAttribute("BattleStreakActive",true)
			notify(p,"BattleStreakStart","BATTLE STREAK • WAVE 1")
			spawnWave(p)
			humanoid.Died:Once(function()stop(p,"BATTLE STREAK FAILED")end)
		end)
	end
	enemy.Defeated.Event:Connect(function(model,killerUserId,kind,reward)
		local p=Players:GetPlayerByUserId(killerUserId);local s=p and sessions[p]
		if not s or not s.Spawned[model]then return end
		s.Spawned[model]=nil;s.Alive-=1
		if s.Alive>0 then return end
		Data.AddXP(p,40+s.Wave*18);Data.AddCoins(p,math.max(1,math.floor((reward or 0)*(.8+s.Wave*.08))));Data.SetBattleStreakBest(p,s.Wave);notify(p,"BattleStreakClear",("WAVE %d CLEARED"):format(s.Wave))
		s.Wave+=1;task.delay(2,function()if sessions[p]~=s then return end;spawnWave(p)end)
	end)
	Players.PlayerRemoving:Connect(function(p)stop(p,"Player left.")end)
end
return Service
