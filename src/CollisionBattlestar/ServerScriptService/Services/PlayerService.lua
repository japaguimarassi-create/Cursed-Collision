--!strict
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Store=DataStoreService:GetDataStore("CollisionBattlestar_Player_v2")
local S={}
local loaded:{[Player]:boolean}={}
local saving:{[Player]:boolean}={}

local function levelForXP(xp:number):number
	local level=1
	local required=350
	local remaining=xp
	while remaining>=required and level<200 do
		remaining-=required
		level+=1
		required+=175
	end
	return level
end

local function applyData(player:Player,data:any)
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	local kos=stats and stats:FindFirstChild("KOs")
	local streak=stats and stats:FindFirstChild("Streak")
	if credits and credits:IsA("IntValue") then credits.Value=math.max(0,tonumber(data.Credits)or 0) end
	if kos and kos:IsA("IntValue") then kos.Value=math.max(0,tonumber(data.KOs)or 0) end
	if streak and streak:IsA("IntValue") then streak.Value=0 end
	local xp=math.max(0,tonumber(data.XP)or 0)
	player:SetAttribute("XP",xp)
	player:SetAttribute("Level",levelForXP(xp))
end

local function snapshot(player:Player):{[string]:any}
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	local kos=stats and stats:FindFirstChild("KOs")
	return {
		Credits=credits and credits:IsA("IntValue") and credits.Value or 0,
		KOs=kos and kos:IsA("IntValue") and kos.Value or 0,
		XP=tonumber(player:GetAttribute("XP"))or 0,
	}
end

local function save(player:Player)
	if not loaded[player] or saving[player] then return end
	saving[player]=true
	local key="Player_"..player.UserId
	local data=snapshot(player)
	pcall(function()
		Store:UpdateAsync(key,function() return data end)
	end)
	saving[player]=nil
end

local function setup(player:Player)
	if player:GetAttribute("CBSInitialized") then return end
	player:SetAttribute("CBSInitialized",true)
	for name,value in pairs({
		Blocking=false,BlockStarted=0,LastCombatAt=0,CurrentMapNode="Origin",
		Combo=0,ComboStarted=0,NextLight=0,NextDash=0,NextSpecial=0,
		DashInvulnerable=false,HitStunUntil=0,Overdrive=0,XP=0,Level=1,DataReady=false,
	}) do player:SetAttribute(name,value) end

	local old=player:FindFirstChild("leaderstats")
	if old then old:Destroy() end
	local leaderstats=Instance.new("Folder")
	leaderstats.Name="leaderstats"
	leaderstats.Parent=player
	for _,definition in ipairs({{"Credits",0},{"KOs",0},{"Streak",0}}) do
		local value=Instance.new("IntValue")
		value.Name=definition[1]
		value.Value=definition[2]
		value.Parent=leaderstats
	end

	task.spawn(function()
		local ok,data=pcall(function() return Store:GetAsync("Player_"..player.UserId) end)
		if player.Parent then
			applyData(player,ok and typeof(data)=="table" and data or {})
			loaded[player]=true
			player:SetAttribute("DataReady",true)
		end
	end)
end

function S.Init()
	Players.PlayerAdded:Connect(setup)
	for _,player in ipairs(Players:GetPlayers()) do setup(player) end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		loaded[player]=nil
		saving[player]=nil
	end)
	game:BindToClose(function()
		for _,player in ipairs(Players:GetPlayers()) do save(player) end
		task.wait(2)
	end)
end

function S.AddXP(player:Player,amount:number)
	local xp=math.max(0,(tonumber(player:GetAttribute("XP"))or 0)+math.max(0,amount))
	local oldLevel=tonumber(player:GetAttribute("Level"))or 1
	local newLevel=levelForXP(xp)
	player:SetAttribute("XP",xp)
	player:SetAttribute("Level",newLevel)
	if newLevel>oldLevel then
		local event=ReplicatedStorage.CollisionRemotes:FindFirstChild("Feedback")
		if event and event:IsA("RemoteEvent") then event:FireClient(player,"LevelUp",newLevel) end
	end
end

function S.AddCredits(player:Player,amount:number)
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	if credits and credits:IsA("IntValue") then credits.Value=math.max(0,credits.Value+math.floor(amount)) end
end

function S.AddKO(player:Player)
	local stats=player:FindFirstChild("leaderstats")
	local kos=stats and stats:FindFirstChild("KOs")
	local streak=stats and stats:FindFirstChild("Streak")
	if kos and kos:IsA("IntValue") then kos.Value+=1 end
	if streak and streak:IsA("IntValue") then streak.Value+=1 end
	S.AddCredits(player,5)
	S.AddXP(player,40)
	local event=ReplicatedStorage.CollisionRemotes:FindFirstChild("Feedback")
	if event and event:IsA("RemoteEvent") then event:FireClient(player,"KOReward",{Credits=5}) end
end

function S.ResetStreak(player:Player)
	local stats=player:FindFirstChild("leaderstats")
	local streak=stats and stats:FindFirstChild("Streak")
	if streak and streak:IsA("IntValue") then streak.Value=0 end
end
return S
