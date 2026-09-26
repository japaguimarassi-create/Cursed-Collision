--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("MapTravelRequest")
local feedback=remotes:WaitForChild("MapTravelFeedback")

local S={}
local cooldown:{[Player]:number}={}
local delaySeconds=.8
local combatLock=2

local function travel(player:Player,nodeId:any)
	if typeof(nodeId)~="string" then return end
	local node=Routes.Get(nodeId)
	if not node then return end
	if not workspace:GetAttribute("CollisionBattlestarMapReady") then
		feedback:FireClient(player,"Error","MAP NOT READY")
		return
	end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health<=0 or not root then return end
	if player:GetAttribute("Blocking")==true or player:GetAttribute("DashInvulnerable")==true then return end
	local lastCombat=tonumber(player:GetAttribute("LastCombatAt"))or 0
	if os.clock()-lastCombat<combatLock then
		feedback:FireClient(player,"Error","FINISH COMBAT FIRST")
		return
	end
	if (cooldown[player]or 0)>os.clock() then return end
	cooldown[player]=os.clock()+delaySeconds
	character:PivotTo(CFrame.new(node.Spawn, node.Spawn+Vector3.new(0,0,-1)))
	player:SetAttribute("CurrentMapNode",node.Id)
	feedback:FireClient(player,"Success",node.Name)
end

function S.Init()
	request.OnServerEvent:Connect(travel)
	Players.PlayerRemoving:Connect(function(player)cooldown[player]=nil end)
	for _,player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("CurrentMapNode","Spawn")
	end
end

return S
