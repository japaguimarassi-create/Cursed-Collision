--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local ServerStorage=game:GetService("ServerStorage")

local C=require(ReplicatedStorage.Shared.Config)
local Q=require(ReplicatedStorage.Shared.QAContract)

local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local reportEvent=remotes:FindFirstChild(Q.ReportEvent)
local controlEvent=remotes:FindFirstChild(Q.ControlEvent)

if not reportEvent then
	reportEvent=Instance.new("RemoteEvent")
	reportEvent.Name=Q.ReportEvent
	reportEvent.Parent=remotes
end
if not controlEvent then
	controlEvent=Instance.new("RemoteEvent")
	controlEvent.Name=Q.ControlEvent
	controlEvent.Parent=remotes
end

local ownerId=game.CreatorId
local activeBots:{[Player]:Model}={}
local latestReport:string=""

local function isOwner(player:Player):boolean
	return player.UserId==ownerId
end

local function createDummy(player:Player):Model?
	if not isOwner(player) then return nil end
	local old=workspace:FindFirstChild(Q.DummyName)
	if old then old:Destroy() end
	local model=Instance.new("Model")
	model.Name=Q.DummyName
	model.Parent=workspace
	local root=Instance.new("Part")
	root.Name="HumanoidRootPart"
	root.Size=Vector3.new(2,2,1)
	root.Position=(player.Character and player.Character:GetPivot().Position or Vector3.new(0,5,0))+Vector3.new(0,0,-10)
	root.Anchored=true
	root.CanCollide=true
	root.Color3=Color3.fromRGB(45,50,62)
	root.Parent=model
	model.PrimaryPart=root
	local torso=Instance.new("Part")
	torso.Name="Torso"
	torso.Size=Vector3.new(2.5,3,1.5)
	torso.Position=root.Position+Vector3.new(0,2.3,0)
	torso.Anchored=true
	torso.CanCollide=false
	torso.Color=Color3.fromRGB(79,90,110)
	torso.Parent=model
	local head=Instance.new("Part")
	head.Name="Head"
	head.Shape=Enum.PartType.Ball
	head.Size=Vector3.new(2,2,2)
	head.Position=root.Position+Vector3.new(0,4.9,0)
	head.Anchored=true
	head.CanCollide=false
	head.Color=Color3.fromRGB(130,141,160)
	head.Parent=model
	local humanoid=Instance.new("Humanoid")
	humanoid.Name="Humanoid"
	humanoid.MaxHealth=500
	humanoid.Health=500
	humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent=model
	local highlight=Instance.new("Highlight")
	highlight.Name="QADetector"
	highlight.FillTransparency=.72
	highlight.OutlineColor=C.UI.Accent
	highlight.Parent=model
	model:SetAttribute("QA_Dummy",true)
	activeBots[player]=model
	return model
end

local function cleanup(player:Player)
	local bot=activeBots[player]
	if bot then bot:Destroy() end
	activeBots[player]=nil
	local old=workspace:FindFirstChild(Q.DummyName)
	if old then old:Destroy() end
end

local function sendReportToGitHub(report:any)
	local encoded=HttpService:JSONEncode(report)
	local holder=ServerStorage:FindFirstChild("CollisionQALatest")
	if not holder then
		holder=Instance.new("StringValue")
		holder.Name="CollisionQALatest"
		holder.Parent=ServerStorage
	end
	holder.Value=encoded
	latestReport=encoded

	local ok,secret=pcall(function()
		return HttpService:GetSecret("GITHUB_QA_TOKEN")
	end)
	if not ok or not secret then
		warn("[CollisionQA] GITHUB_QA_TOKEN is not configured; report retained in ServerStorage.CollisionQALatest")
		return false
	end

	local payload=HttpService:JSONEncode({
		event_type="collision-battlestar-qa",
		client_payload={
			report=report,
			repository="japaguimarassi-create/Cursed-Collision",
		},
	})

	local success,response=pcall(function()
		return HttpService:RequestAsync({
			Url="https://api.github.com/repos/japaguimarassi-create/Cursed-Collision/dispatches",
			Method="POST",
			Headers={
				["Accept"]="application/vnd.github+json",
				["Content-Type"]="application/json",
				["Authorization"]=secret:AddPrefix("Bearer "),
				["X-GitHub-Api-Version"]="2026-03-10",
			},
			Body=payload,
		})
	end)
	if not success then
		warn("[CollisionQA] GitHub report failed:",response)
		return false
	end
	if not response.Success then
		warn("[CollisionQA] GitHub report rejected:",response.StatusCode,response.StatusMessage)
		return false
	end
	return true
end

controlEvent.OnServerEvent:Connect(function(player:Player,action:string)
	if not isOwner(player) then return end
	if action=="START" then
		createDummy(player)
	elseif action=="STOP" then
		cleanup(player)
	end
end)

reportEvent.OnServerEvent:Connect(function(player:Player,report:any)
	if not isOwner(player) or typeof(report)~="table" then return end
	report.project="Collision Battlestar"
	report.serverJobId=game.JobId
	report.placeId=game.PlaceId
	report.timestamp=os.time()
	report.serverMapReady=workspace:GetAttribute("CollisionBattlestarMapReady")==true
	report.performance={
		serverPlayers=#Players:GetPlayers(),
		worldParts=#workspace:GetDescendants(),
	}
	task.spawn(function()
		local sent=sendReportToGitHub(report)
		report.githubSent=sent
		latestReport=HttpService:JSONEncode(report)
	end)
end)

Players.PlayerRemoving:Connect(cleanup)

return true
