--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")

local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("UtilityRequest")
local feedback=remotes:WaitForChild("UtilityFeedback")

local S={}
local cooldown:{[Player]:number}={}

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
	request.OnServerEvent:Connect(function(player,action,value)
		if typeof(action)~="string" then return end
		if action=="Respawn" then
			respawn(player)
		elseif action=="Ping" then
			ping(player,value)
		elseif action=="CloseMenu" then
			feedback:FireClient(player,"MenuClosed")
		end
	end)
	Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil end)
end

return S
