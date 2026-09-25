--!strict
local R=game:GetService("ReplicatedStorage")
local remotes=R:FindFirstChild("CollisionRemotes")or Instance.new("Folder");remotes.Name="CollisionRemotes";remotes.Parent=R
for _,name in {"CombatRequest","Feedback","WorldState"}do if not remotes:FindFirstChild(name)then local r=Instance.new("RemoteEvent");r.Name=name;r.Parent=remotes end end
local Players=game:GetService("Players")
local WB=require(script.Parent.World.WorldBuilder);local Data=require(script.Parent.Services.PlayerDataService);local World=require(script.Parent.Services.WorldStateService);local Enemy=require(script.Parent.Services.EnemyService);local Quest=require(script.Parent.Services.QuestService);local NPC=require(script.Parent.Services.NPCService);local Combat=require(script.Parent.Services.CombatService);local Economy=require(script.Parent.Services.EconomyService);local Events=require(script.Parent.Services.EventService)
WB.Init();Data.Init();World.Init();Enemy.Init();Combat.Init();Economy.Init(Enemy.Defeated);Quest.Init(Enemy.Defeated);NPC.Init();Events.Init(Enemy,WB)
Players.PlayerAdded:Connect(function(p)task.defer(function)if not p:GetAttribute("QuestId")or p:GetAttribute("QuestId")==""then Quest.Start(p)end end)end)
task.spawn(function()while task.wait(8)do local pts=WB.GetSpawnPoints();local kinds={"Riftling","Warden","Caster","Hunter"};if Enemy.CountAlive()<14 and #Players:GetPlayers()>0 and #pts>0 then Enemy.Spawn(kinds[math.random(1,#kinds)],pts[math.random(1,#pts)])end end end)
task.spawn(function()while task.wait(55)do if #Players:GetPlayers()>0 and Enemy.CountAlive()<=1 and not Events.Active then Enemy.SpawnBoss(WB.GetBossArena()+Vector3.new(0,5,0))end end end)
