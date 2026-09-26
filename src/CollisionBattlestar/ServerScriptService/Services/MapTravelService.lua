--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("MapTravelRequest")
local feedback=remotes:WaitForChild("MapTravelFeedback")
local S={}
local cooldown:{[Player]:number}={}
local delaySeconds=.65
local combatLock=1.4

local function travel(player:Player,nodeId:any)
	if typeof(nodeId)~="string" then return end
	local node=Routes.Get(nodeId)
	if not node or not workspace:GetAttribute("CollisionBattlestarMapReady") then return end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health<=0 or not root or not root:IsA("BasePart") then return end
	if player:GetAttribute("Blocking")==true or player:GetAttribute("DashInvulnerable")==true then return end
	if os.clock()-(tonumber(player:GetAttribute("LastCombatAt"))or 0)<combatLock then
		feedback:FireClient(player,"Error","Finish combat first")
		return
	end
	if (cooldown[player]or 0)>os.clock() then return end
	cooldown[player]=os.clock()+delaySeconds
	character:PivotTo(CFrame.new(node.Spawn,node.Spawn+Vector3.new(1,0,0)))
	root.AssemblyLinearVelocity=Vector3.zero
	player:SetAttribute("CurrentMapNode",node.Id)
	feedback:FireClient(player,"Success",{Name=node.Name,Subtitle=node.Subtitle,Node=node.Id})
end

function S.Init()
	request.OnServerEvent:Connect(travel)
	Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil end)
	for _,player in ipairs(Players:GetPlayers()) do player:SetAttribute("CurrentMapNode","Origin") end
end
return S
