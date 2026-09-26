--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local Routes=require(R.Shared.MapRouteDefinitions)

local S={}
local cooldown:{[Player]:number}={}
local COOLDOWN=.9
local COMBAT_LOCK=2.5

local function feedback(player:Player,kind:string,value:any?)
	local remotes=R:FindFirstChild("CollisionRemotes")
	local event=remotes and remotes:FindFirstChild("MapTravelFeedback")
	if event and event:IsA("RemoteEvent")then event:FireClient(player,kind,value)end
end

local function canTravel(player:Player):boolean
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health<=0 then return false end
	local now=os.clock()
	if (cooldown[player]or 0)>now then return false end
	if player:GetAttribute("MapTraveling")==true then return false end
	if player:GetAttribute("Blocking")==true or player:GetAttribute("CombatStunned")==true or player:GetAttribute("Ragdolled")==true then return false end
	local lastCombat=tonumber(player:GetAttribute("LastCombatAt"))or 0
	if lastCombat>0 and now-lastCombat<COMBAT_LOCK then return false end
	return true
end

function S.Teleport(player:Player,nodeId:any):boolean
	if typeof(nodeId)~="string"or not Routes.Get(nodeId)or not Routes.IsUnlocked(player,nodeId)then return false end
	if not workspace:GetAttribute("CollisionBattlestarMapReady")then feedback(player,"MapUnavailable","MAP IS STILL LOADING");return false end
	if not canTravel(player)then feedback(player,"MapLocked","TRAVEL LOCKED • FINISH COMBAT");return false end

	local node=Routes.Get(nodeId)
	if not node then return false end

	cooldown[player]=os.clock()+COOLDOWN
	player:SetAttribute("MapTraveling",true)

	pcall(function()
		player:RequestStreamAroundAsync(node.Spawn)
	end)

	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if character and humanoid and humanoid.Health>0 then
		character:PivotTo(CFrame.new(node.Spawn,node.Spawn+Vector3.new(0,0,-1)))
		humanoid:Move(Vector3.zero,false)
	end

	player:SetAttribute("CurrentMapNode",node.Id)
	task.delay(.18,function()
		if player.Parent then player:SetAttribute("MapTraveling",false)end
	end)
	feedback(player,"MapTravelSuccess",{Id=node.Id,Name=node.Name})
	return true
end

function S.Init()
	local remotes=R:WaitForChild("CollisionRemotes")
	local request=remotes:FindFirstChild("MapTravelRequest")
	if not request or not request:IsA("RemoteEvent")then return end
	request.OnServerEvent:Connect(function(player,nodeId)S.Teleport(player,nodeId)end)
	Players.PlayerRemoving:Connect(function(player)cooldown[player]=nil end)
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("CurrentMapNode","Origin")
		player:SetAttribute("MapTraveling",false)
	end)
	for _,player in ipairs(Players:GetPlayers())do
		player:SetAttribute("CurrentMapNode","Origin")
		player:SetAttribute("MapTraveling",false)
	end
end

return S
