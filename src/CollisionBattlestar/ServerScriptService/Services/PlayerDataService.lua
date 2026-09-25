--!strict
local Players=game:GetService("Players");local DSS=game:GetService("DataStoreService")
local C=require(game.ReplicatedStorage.Shared.Config);local U=require(game.ReplicatedStorage.Shared.Util)
local S={};local profiles:{[Player]:any}={};local store=DSS:GetDataStore(C.Data.StoreName)
local function defaults()return{SchemaVersion=C.SchemaVersion,Coins=0,Level=1,XP=0,BattleStreakBest=0,Inventory={StarterBlade=1},Mastery={Blade=1,Martial=1},Exploration=0,Reputation={FractureDistrict=0},Achievements={},Quest={Id=nil,Progress=0,Target=6,Completed=false},SessionId=nil,SessionTimestamp=nil}end
local function norm(d:any):any
	local b=defaults();if typeof(d)~="table"then return b end
	for k,v in b do if d[k]==nil or typeof(d[k])~=typeof(v)then d[k]=v end end
	if typeof(d.Inventory)~="table"then d.Inventory=b.Inventory end;if typeof(d.Mastery)~="table"then d.Mastery=b.Mastery end;if typeof(d.Reputation)~="table"then d.Reputation=b.Reputation end;if typeof(d.Achievements)~="table"then d.Achievements={}end;if typeof(d.Quest)~="table"then d.Quest=b.Quest end
	d.Level=math.max(1,math.floor(tonumber(d.Level)or 1));d.XP=math.max(0,math.floor(tonumber(d.XP)or 0));d.Exploration=math.max(0,math.floor(tonumber(d.Exploration)or 0));d.BattleStreakBest=math.max(0,math.floor(tonumber(d.BattleStreakBest)or 0));d.Coins=math.max(0,math.floor(tonumber(d.Coins)or 0));d.Quest.Progress=U.Clamp(tonumber(d.Quest.Progress)or 0,0,math.max(1,tonumber(d.Quest.Target)or 6));d.Quest.Target=math.max(1,tonumber(d.Quest.Target)or 6);d.Quest.Completed=d.Quest.Completed==true;d.SchemaVersion=C.SchemaVersion;return d
end
local function key(p:Player)return"Player_"..p.UserId end
local function load(p:Player):(any?,string?)
	for attempt=1,C.Data.MaxRetries do
		local ok,res=pcall(function()return store:UpdateAsync(key(p),function(cur)local d=norm(cur);local ts=tonumber(d.SessionTimestamp)or 0;if d.SessionId and d.SessionId~=game.JobId and os.time()-ts<C.Data.SessionTimeoutSeconds then return nil end;d.SessionId=game.JobId;d.SessionTimestamp=os.time();return d end)end)
		if ok and res then return norm(res),"OK"end;task.wait(math.min(2^(attempt-1),8)+math.random())
	end
	return nil,"LOAD_FAILED"
end
local function save(p:Player):boolean
	local d=profiles[p];if not d then return true end;local snap=norm(table.clone(d));snap.SessionId=game.JobId;snap.SessionTimestamp=os.time()
	for attempt=1,C.Data.MaxRetries do
		local ok=pcall(function()store:UpdateAsync(key(p),function(cur)if cur and cur.SessionId and cur.SessionId~=game.JobId then return cur end;return snap end)end)
		if ok then return true end;task.wait(math.min(2^(attempt-1),8)+math.random())
	end
	return false
end
local function bindAttributes(p:Player,d:any)
	p:SetAttribute("QuestId",d.Quest.Id or "");p:SetAttribute("QuestProgress",d.Quest.Progress);p:SetAttribute("QuestTarget",d.Quest.Target);p:SetAttribute("QuestCompleted",d.Quest.Completed);p:SetAttribute("Exploration",d.Exploration);p:SetAttribute("Level",d.Level);p:SetAttribute("XP",d.XP);p:SetAttribute("BattleStreakBest",d.BattleStreakBest)
	for itemId,count in pairs(d.Inventory)do if typeof(count)=="number"then p:SetAttribute("Inventory_"..itemId,math.max(0,count))end end
end
function S.Init()
	Players.PlayerAdded:Connect(function(p)
		local d,status=load(p)
		if not d then p:Kick(status=="LOCKED" and "Profile is active in another server." or "Profile data could not be loaded safely.");return end
		profiles[p]=d;local ls=Instance.new("Folder");ls.Name="leaderstats";ls.Parent=p;local c=Instance.new("IntValue");c.Name="Credits";c.Value=d.Coins;c.Parent=ls;bindAttributes(p,d)
	end)
	Players.PlayerRemoving:Connect(function(p)save(p);task.wait(.15);S.Release(p);profiles[p]=nil end)
	game:BindToClose(function()for _,p in Players:GetPlayers()do save(p);S.Release(p)end end)
	task.spawn(function()while task.wait(C.Data.AutosaveSeconds)do for _,p in Players:GetPlayers()do save(p)end end end)
end
function S.Release(p:Player)
	pcall(function()store:UpdateAsync(key(p),function(cur)if cur and cur.SessionId==game.JobId then cur.SessionId=nil;cur.SessionTimestamp=nil end;return cur end)end)
end
function S.Get(p:Player):any?return profiles[p]end
function S.AddCoins(p:Player,n:number)local d=profiles[p];if not d then return end;n=math.floor(n);if n<=0 then return end;d.Coins+=n;local ls=p:FindFirstChild("leaderstats");local c=ls and ls:FindFirstChild("Credits");if c and c:IsA("IntValue")then c.Value=d.Coins end end
function S.SetBattleStreakBest(p:Player,wave:number)local d=profiles[p];if not d then return end;wave=math.max(0,math.floor(wave));if wave>d.BattleStreakBest then d.BattleStreakBest=wave;p:SetAttribute("BattleStreakBest",wave)end end
function S.AddXP(p:Player,n:number)local d=profiles[p];if not d then return end;d.XP=math.max(0,d.XP+math.floor(n));while d.XP>=d.Level*100 do d.XP-=d.Level*100;d.Level+=1 end;p:SetAttribute("Level",d.Level);p:SetAttribute("XP",d.XP)end
function S.AddExploration(p:Player,n:number)local d=profiles[p];if not d then return end;d.Exploration=math.max(0,d.Exploration+math.floor(n));p:SetAttribute("Exploration",d.Exploration)end
function S.AddMastery(p:Player,style:string,n:number)local d=profiles[p];if not d or not d.Mastery[style]then return end;d.Mastery[style]+=math.max(0,math.floor(n))end
function S.UnlockAchievement(p:Player,id:string):boolean local d=profiles[p];if not d or d.Achievements[id]then return false end;d.Achievements[id]=true;return true end
function S.StartQuest(p:Player,id:string,target:number)local d=profiles[p];if not d then return end;d.Quest={Id=id,Progress=0,Target=target,Completed=false};p:SetAttribute("QuestId",id);p:SetAttribute("QuestProgress",0);p:SetAttribute("QuestTarget",target);p:SetAttribute("QuestCompleted",false)end
function S.ProgressQuest(p:Player,id:string,n:number):boolean local d=profiles[p];if not d or d.Quest.Id~=id or d.Quest.Completed then return false end;d.Quest.Progress=U.Clamp(d.Quest.Progress+n,0,d.Quest.Target);p:SetAttribute("QuestProgress",d.Quest.Progress);if d.Quest.Progress>=d.Quest.Target then d.Quest.Completed=true;p:SetAttribute("QuestCompleted",true);S.AddCoins(p,50);S.AddXP(p,100);S.AddExploration(p,10);d.Reputation.FractureDistrict+=15;return true end;return false end
return S
