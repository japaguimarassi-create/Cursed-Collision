--!strict
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)

type Profile={Credits:number,KOs:number,XP:number,Level:number,Owned:{[string]:boolean},EquippedCharacter:string,EquippedTitle:string,EquippedItem:string,DailyKOs:number,WeeklyKOs:number,LifetimeKOs:number,DailyKey:string,WeeklyKey:string,Codes:{[string]:boolean}}

local M={}
local store=DataStoreService:GetDataStore("CollisionBattlestar_Profile_v4")
local cache:{[Player]:Profile}={}
local busy:{[Player]:boolean}={}

local function key(player:Player):string
 return "User_"..tostring(player.UserId)
end

local function levelForXP(xp:number):number
 local level=1
 local need=Config.Progression.BaseXP
 local remaining=math.max(0,xp)
 while remaining>=need and level<Config.Progression.MaxLevel do
  remaining-=need
  level+=1
  need+=Config.Progression.StepXP
 end
 return level
end

local function dateKey(days:number):string
 local t=os.date("!*t",os.time()+days*86400)
 return string.format("%04d-%02d-%02d",t.year,t.month,t.day)
end

local function weekKey():string
 local weekday=tonumber(os.date("!%w")) or 0
 return dateKey(-weekday)
end

local function fresh():Profile
 return {Credits=0,KOs=0,XP=0,Level=1,Owned={},EquippedCharacter="Yuji",EquippedTitle="RIVAL",EquippedItem="",DailyKOs=0,WeeklyKOs=0,LifetimeKOs=0,DailyKey=dateKey(0),WeeklyKey=weekKey(),Codes={}}
end

local function normalize(data:any):Profile
 local p=fresh()
 if typeof(data)~="table" then return p end
 p.Credits=math.max(0,math.floor(tonumber(data.Credits) or 0))
 p.KOs=math.max(0,math.floor(tonumber(data.KOs) or 0))
 p.XP=math.max(0,tonumber(data.XP) or 0)
 p.Level=levelForXP(p.XP)
 if typeof(data.Owned)=="table" then
  for id,value in pairs(data.Owned) do if typeof(id)=="string" and value==true then p.Owned[id]=true end end
 end
 if typeof(data.EquippedCharacter)=="string" then p.EquippedCharacter=data.EquippedCharacter end
 if typeof(data.EquippedTitle)=="string" then p.EquippedTitle=data.EquippedTitle end
 if typeof(data.EquippedItem)=="string" then p.EquippedItem=data.EquippedItem end
 p.DailyKOs=math.max(0,math.floor(tonumber(data.DailyKOs) or 0))
 p.WeeklyKOs=math.max(0,math.floor(tonumber(data.WeeklyKOs) or 0))
 p.LifetimeKOs=math.max(p.KOs,math.floor(tonumber(data.LifetimeKOs) or 0))
 p.DailyKey=typeof(data.DailyKey)=="string" and data.DailyKey or p.DailyKey
 p.WeeklyKey=typeof(data.WeeklyKey)=="string" and data.WeeklyKey or p.WeeklyKey
 if typeof(data.Codes)=="table" then
  for id,value in pairs(data.Codes) do if typeof(id)=="string" and value==true then p.Codes[id]=true end end
 end
 return p
end

local function refreshWindows(p:Profile)
 local today=dateKey(0)
 local week=weekKey()
 if p.DailyKey~=today then p.DailyKey=today;p.DailyKOs=0 end
 if p.WeeklyKey~=week then p.WeeklyKey=week;p.WeeklyKOs=0 end
end

local function mirror(player:Player,p:Profile)
 refreshWindows(p)
 player:SetAttribute("DataReady",true)
 player:SetAttribute("Credits",p.Credits)
 player:SetAttribute("KOs",p.KOs)
 player:SetAttribute("XP",p.XP)
 player:SetAttribute("Level",p.Level)
 player:SetAttribute("EquippedCharacter",p.EquippedCharacter)
 player:SetAttribute("EquippedTitle",p.EquippedTitle)
 player:SetAttribute("EquippedItem",p.EquippedItem)
 player:SetAttribute("DailyKOs",p.DailyKOs)
 player:SetAttribute("WeeklyKOs",p.WeeklyKOs)
 player:SetAttribute("LifetimeKOs",p.LifetimeKOs)
 if player:GetAttribute("Streak")==nil then player:SetAttribute("Streak",0) end
end

function M:Get(player:Player):Profile?
 return cache[player]
end

function M:Load(player:Player):boolean
 local loaded:any=nil
 for attempt=1,3 do
  local ok,result=pcall(function() return store:GetAsync(key(player)) end)
  if ok then loaded=result;break end
  task.wait(math.min(6,2^(attempt-1)))
 end
 cache[player]=normalize(loaded)
 mirror(player,cache[player])
 return true
end

function M:Save(player:Player):boolean
 local p=cache[player]
 if not p or busy[player] then return false end
 busy[player]=true
 refreshWindows(p)
 local payload={Credits=p.Credits,KOs=p.KOs,XP=p.XP,Level=p.Level,Owned=p.Owned,EquippedCharacter=p.EquippedCharacter,EquippedTitle=p.EquippedTitle,EquippedItem=p.EquippedItem,DailyKOs=p.DailyKOs,WeeklyKOs=p.WeeklyKOs,LifetimeKOs=p.LifetimeKOs,DailyKey=p.DailyKey,WeeklyKey=p.WeeklyKey,Codes=p.Codes}
 local success=false
 for attempt=1,3 do
  local ok=pcall(function() store:UpdateAsync(key(player),function() return payload end) end)
  if ok then success=true;break end
  task.wait(math.min(8,2^(attempt-1)))
 end
 busy[player]=nil
 return success
end

function M:AddCredits(player:Player,amount:number)
 local p=cache[player]
 if not p then return end
 p.Credits=math.max(0,p.Credits+math.floor(amount))
 mirror(player,p)
end

function M:AddXP(player:Player,amount:number):boolean
 local p=cache[player]
 if not p then return false end
 local old=p.Level
 p.XP=math.max(0,p.XP+math.max(0,amount))
 p.Level=levelForXP(p.XP)
 mirror(player,p)
 return p.Level>old
end

function M:AddKO(player:Player):number
 local p=cache[player]
 if not p then return 0 end
 refreshWindows(p)
 p.KOs+=1
 p.LifetimeKOs+=1
 p.DailyKOs+=1
 p.WeeklyKOs+=1
 p.Credits+=Config.Progression.KOReward
 p.XP+=Config.Progression.KOXP
 p.Level=levelForXP(p.XP)
 player:SetAttribute("Streak",(tonumber(player:GetAttribute("Streak")) or 0)+1)
 mirror(player,p)
 return Config.Progression.KOReward
end

function M:ResetStreak(player:Player)
 if player.Parent then player:SetAttribute("Streak",0) end
end

function M:Buy(player:Player,itemId:string,price:number):boolean
 local p=cache[player]
 if not p or p.Owned[itemId] or p.Credits<price then return false end
 p.Credits-=price
 p.Owned[itemId]=true
 mirror(player,p)
 return true
end

function M:SetCharacter(player:Player,id:string)
 local p=cache[player]
 if not p then return end
 p.EquippedCharacter=id
 mirror(player,p)
end

function M:SetTitle(player:Player,title:string)
 local p=cache[player]
 if not p then return end
 p.EquippedTitle=title
 mirror(player,p)
end
function M:SetItem(player:Player,itemId:string)
 local p=cache[player]
 if not p then return end
 p.EquippedItem=itemId
 mirror(player,p)
end

function M:UseCode(player:Player,code:string,reward:number):boolean
 local p=cache[player]
 if not p then return false end
 if code=="" or p.Codes[code] then return false end
 p.Codes[code]=true
 p.Credits+=reward
 mirror(player,p)
 return true
end

function M:ClaimMission(player:Player,kind:string):number
 local p=cache[player]
 if not p then return 0 end
 refreshWindows(p)
 local reward=0
 local keyName=""
 if kind=="Daily" and p.DailyKOs>=Config.Missions.Daily.Goal then reward=Config.Missions.Daily.Reward;keyName="MISSION_DAILY_"..p.DailyKey
 elseif kind=="Weekly" and p.WeeklyKOs>=Config.Missions.Weekly.Goal then reward=Config.Missions.Weekly.Reward;keyName="MISSION_WEEKLY_"..p.WeeklyKey
 elseif kind=="Lifetime" and p.LifetimeKOs>=Config.Missions.Lifetime.Goal then reward=Config.Missions.Lifetime.Reward;keyName="MISSION_LIFETIME" end
 if reward<=0 or p.Codes[keyName] then return 0 end
 p.Codes[keyName]=true
 p.Credits+=reward
 mirror(player,p)
 return reward
end

function M:Init()
 Players.PlayerAdded:Connect(function(player)
  task.spawn(function() self:Load(player) end)
 end)
 Players.PlayerRemoving:Connect(function(player)
  self:Save(player)
  cache[player]=nil
  busy[player]=nil
 end)
 for _,player in ipairs(Players:GetPlayers()) do task.spawn(function() self:Load(player) end) end
 task.spawn(function()
  while game.Parent do
   task.wait(180)
   for player in pairs(cache) do if player.Parent then task.spawn(function() self:Save(player) end) end end
  end
 end)
 game:BindToClose(function()
  for player in pairs(cache) do self:Save(player) end
 end)
end
return M