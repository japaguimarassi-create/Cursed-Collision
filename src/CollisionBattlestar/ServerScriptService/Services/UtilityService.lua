--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local Debris=game:GetService("Debris")
local Store=DataStoreService:GetDataStore("CollisionBattlestar_Store_v1")
local Catalog=require(ReplicatedStorage.Shared.StoreCatalog)

local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("UtilityRequest")
local feedback=remotes:WaitForChild("UtilityFeedback")

local S={}
local cooldown:{[Player]:number}={}
local profile:{[Player]:{Owned:{[string]:boolean},EquippedEmote:string,EquippedSkin:string,EquippedTitle:string,Redeemed:{[string]:boolean},Loaded:boolean,Saving:boolean}}={}

local CODE_REWARDS:{[string]:number}={
	BATTLESTAR=250,
	BATTLELINE=150,
	NOVA=100,
}

local function defaultProfile()
	return {Owned={},EquippedEmote="",EquippedSkin="",EquippedTitle="",Redeemed={},Loaded=false,Saving=false}
end

local function sync(player:Player)
	local data=profile[player]
	if not data then return end
	local owned={}
	for id,has in pairs(data.Owned) do
		if has then table.insert(owned,id) end
	end
	table.sort(owned)
	feedback:FireClient(player,"ShopSync",{
		Owned=owned,
		EquippedEmote=data.EquippedEmote,
		EquippedSkin=data.EquippedSkin,
		EquippedTitle=data.EquippedTitle,
		Loaded=data.Loaded,
	})
	player:SetAttribute("EquippedEmote",data.EquippedEmote)
	player:SetAttribute("EquippedSkin",data.EquippedSkin)
	player:SetAttribute("EquippedTitle",data.EquippedTitle)
end

local function load(player:Player)
	if profile[player] then return end
	local data=defaultProfile()
	profile[player]=data
	local ok,saved=pcall(function() return Store:GetAsync("Player_"..player.UserId) end)
	if ok and typeof(saved)=="table" then
		if typeof(saved.Owned)=="table" then data.Owned=saved.Owned end
		data.EquippedEmote=typeof(saved.EquippedEmote)=="string" and saved.EquippedEmote or ""
		data.EquippedSkin=typeof(saved.EquippedSkin)=="string" and saved.EquippedSkin or ""
		data.EquippedTitle=typeof(saved.EquippedTitle)=="string" and saved.EquippedTitle or ""
		if typeof(saved.Redeemed)=="table" then data.Redeemed=saved.Redeemed end
	end
	data.Loaded=true
	sync(player)
end

local function save(player:Player)
	local data=profile[player]
	if not data or not data.Loaded or data.Saving then return end
	data.Saving=true
	local snapshot={
		Owned=data.Owned,
		EquippedEmote=data.EquippedEmote,
		EquippedSkin=data.EquippedSkin,
		EquippedTitle=data.EquippedTitle,
		Redeemed=data.Redeemed,
	}
	pcall(function()
		Store:UpdateAsync("Player_"..player.UserId,function() return snapshot end)
	end)
	data.Saving=false
end

local function buy(player:Player,id:any)
	if typeof(id)~="string" then return end
	local item=Catalog.Get(id)
	local data=profile[player]
	if not item or not data or not data.Loaded then return end
	if data.Owned[id] then
		feedback:FireClient(player,"ShopMessage","ALREADY OWNED")
		return
	end
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	if not credits or not credits:IsA("IntValue") then return end
	if credits.Value<item.Price then
		feedback:FireClient(player,"ShopMessage","NEED "..tostring(item.Price-credits.Value).." MORE CREDITS")
		return
	end
	credits.Value-=item.Price
	data.Owned[id]=true
	if item.Kind=="Emote" then data.EquippedEmote=id end
	if item.Kind=="Skin" then data.EquippedSkin=id end
	if item.Kind=="Title" then data.EquippedTitle=id end
	save(player)
	sync(player)
	feedback:FireClient(player,"ShopMessage","UNLOCKED  •  "..item.Name)
end

local function equip(player:Player,id:any)
	if typeof(id)~="string" then return end
	local item=Catalog.Get(id)
	local data=profile[player]
	if not item or not data or not data.Owned[id] then return end
	if item.Kind=="Emote" then data.EquippedEmote=id
	elseif item.Kind=="Skin" then data.EquippedSkin=id
	elseif item.Kind=="Title" then data.EquippedTitle=id end
	save(player)
	sync(player)
	feedback:FireClient(player,"ShopMessage","EQUIPPED  •  "..item.Name)
end

local function redeem(player:Player,code:any)
	if typeof(code)~="string" then return end
	local key=string.upper((code:gsub("%s+","")))
	local reward=CODE_REWARDS[key]
	local data=profile[player]
	if not reward or not data or not data.Loaded then
		feedback:FireClient(player,"ShopMessage","INVALID CODE")
		return
	end
	if data.Redeemed[key] then
		feedback:FireClient(player,"ShopMessage","CODE ALREADY USED")
		return
	end
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	if not credits or not credits:IsA("IntValue") then return end
	data.Redeemed[key]=true
	credits.Value+=reward
	save(player)
	feedback:FireClient(player,"ShopMessage","CODE REDEEMED  •  +"..tostring(reward).." C")
end

local function validPlayer(player:Player):boolean
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	return humanoid~=nil and humanoid.Health>0
end

local function respawn(player:Player)
	if not validPlayer(player) then return end
	if (cooldown[player] or 0)>os.clock() then return end
	cooldown[player]=os.clock()+2
	player:LoadCharacter()
	feedback:FireClient(player,"Respawned")
end

local function ping(player:Player,position:any)
	if typeof(position)~="Vector3" or not validPlayer(player) then return end
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root or (position-root.Position).Magnitude>220 then return end
	if (cooldown[player] or 0)>os.clock()-.45 then return end
	cooldown[player]=os.clock()+.45

	local folder=workspace:FindFirstChild("CollisionBattlestarPings")
	if not folder then
		folder=Instance.new("Folder")
		folder.Name="CollisionBattlestarPings"
		folder.Parent=workspace
	end

	local marker=Instance.new("Part")
	marker.Name="Ping"
	marker.Shape=Enum.PartType.Ball
	marker.Size=Vector3.new(1.6,1.6,1.6)
	marker.Anchored=true
	marker.CanCollide=false
	marker.CanTouch=false
	marker.CanQuery=false
	marker.Material=Enum.Material.Neon
	marker.Color=Color3.fromRGB(94,205,255)
	marker.Position=position+Vector3.new(0,1.2,0)
	marker.Parent=folder

	local billboard=Instance.new("BillboardGui")
	billboard.Name="PingLabel"
	billboard.Size=UDim2.fromOffset(110,28)
	billboard.StudsOffset=Vector3.new(0,2.2,0)
	billboard.AlwaysOnTop=true
	billboard.MaxDistance=220
	billboard.Parent=marker
	local text=Instance.new("TextLabel")
	text.Size=UDim2.fromScale(1,1)
	text.BackgroundTransparency=1
	text.Font=Enum.Font.GothamBold
	text.Text="PING  •  "..player.DisplayName
	text.TextSize=10
	text.TextColor3=Color3.fromRGB(244,247,252)
	text.TextStrokeTransparency=.5
	text.Parent=billboard

	Debris:AddItem(marker,4)
	feedback:FireAllClients("Ping",{Position=marker.Position,Owner=player.UserId})
end

function S.Init()
	Players.PlayerAdded:Connect(load)
	for _,player in ipairs(Players:GetPlayers()) do load(player) end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profile[player]=nil
		cooldown[player]=nil
	end)
	game:BindToClose(function()
		for _,player in ipairs(Players:GetPlayers()) do save(player) end
		task.wait(2)
	end)

	request.OnServerEvent:Connect(function(player,action,value)
		if typeof(action)~="string" then return end
		if action=="Respawn" then
			respawn(player)
		elseif action=="Ping" then
			ping(player,value)
		elseif action=="BuyItem" then
			buy(player,value)
		elseif action=="EquipItem" then
			equip(player,value)
		elseif action=="RedeemCode" then
			redeem(player,value)
		elseif action=="ShopState" then
			load(player)
			sync(player)
		elseif action=="CloseMenu" then
			feedback:FireClient(player,"MenuClosed")
		end
	end)
end

return S
