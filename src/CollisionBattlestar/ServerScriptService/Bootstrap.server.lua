--!strict
local R=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")

local remotes=R:FindFirstChild("CollisionRemotes")or Instance.new("Folder")
remotes.Name="CollisionRemotes"
remotes.Parent=R

for _,name in {"CombatRequest","Feedback","WorldState","GamePassRequest","MapTravelRequest","MapTravelFeedback"}do
	if not remotes:FindFirstChild(name)then
		local r=Instance.new("RemoteEvent")
		r.Name=name
		r.Parent=remotes
	end
end

local WB=require(script.Parent.World.WorldBuilder)
local Data=require(script.Parent.Services.PlayerDataService)
local World=require(script.Parent.Services.WorldStateService)
local MapDecoration=require(script.Parent.Services.MapDecorationService)
local Enemy=require(script.Parent.Services.EnemyService)
local Quest=require(script.Parent.Services.QuestService)
local NPC=require(script.Parent.Services.NPCService)
local Combat=require(script.Parent.Services.CombatService)
local Economy=require(script.Parent.Services.EconomyService)
local Movement=require(script.Parent.Services.MovementService)
local Events=require(script.Parent.Services.EventService)
local Achievement=require(script.Parent.Services.AchievementService)
local BattleStreak=require(script.Parent.Services.BattleStreakService)
local WorldPresentation=require(script.Parent.Services.WorldPresentationService)
local GamePass=require(script.Parent.Services.GamePassService)
local MapTravel=require(script.Parent.Services.MapTravelService)

local function safeInit(name:string,callback:()->())
	local ok,err=pcall(callback)
	workspace:SetAttribute("CollisionBattlestarService_"..name,ok and "Ready"or"Failed")
	if not ok then
		warn("[Collision Battlestar] Service failed: "..name.." :: "..tostring(err))
	end
	return ok
end

WB.Init()
safeInit("MapTravel",MapTravel.Init)
safeInit("MapDecoration",MapDecoration.Init)
safeInit("Data",Data.Init)
safeInit("WorldState",World.Init)
safeInit("WorldPresentation",function()WorldPresentation.Init(World)end)
safeInit("GamePass",function()GamePass.Init(remotes.GamePassRequest)end)
safeInit("Enemy",Enemy.Init)
safeInit("Combat",Combat.Init)
safeInit("Economy",function()Economy.Init(Enemy.Defeated)end)
safeInit("Quest",function()Quest.Init(Enemy.Defeated)end)
safeInit("NPC",NPC.Init)
safeInit("Movement",Movement.Init)
safeInit("Events",function()Events.Init(Enemy,WB)end)
safeInit("Achievement",function()Achievement.Init(Enemy.Defeated,Events.Started)end)
safeInit("BattleStreak",function()BattleStreak.Init(Enemy)end)

local function ensureQuest(p:Player)
	task.defer(function()
		if p.Parent and (not p:GetAttribute("QuestId")or p:GetAttribute("QuestId")=="")then
			Quest.Start(p)
		end
	end)
end

Players.PlayerAdded:Connect(ensureQuest)
for _,p in Players:GetPlayers()do ensureQuest(p)end

workspace:SetAttribute("CollisionBattlestarBootstrapReady",true)

task.spawn(function()
	while task.wait(8)do
		local pts=WB.GetSpawnPoints()
		local kinds={"Riftling","Warden","Caster","Hunter"}
		if Enemy.CountAlive()<14 and #Players:GetPlayers()>0 and #pts>0 then
			Enemy.Spawn(kinds[math.random(1,#kinds)],pts[math.random(1,#pts)])
		end
	end
end)

task.spawn(function()
	while task.wait(55)do
		if #Players:GetPlayers()>0 and Enemy.CountAlive()<=1 and not Events.Active then
			Enemy.SpawnBoss(WB.GetBossArena()+Vector3.new(0,5,0))
		end
	end
end)
