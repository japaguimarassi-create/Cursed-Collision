--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local BuildInfo=require(ReplicatedStorage.Shared.BuildInfo)
local Config=require(ReplicatedStorage.Shared.Config)

local remotes=ReplicatedStorage:FindFirstChild("CollisionRemotes")
if not remotes then
	remotes=Instance.new("Folder")
	remotes.Name="CollisionRemotes"
	remotes.Parent=ReplicatedStorage
end
for _,name in ipairs({"CombatRequest","MovementRequest","Feedback","MapTravelRequest","MapTravelFeedback","BootRequest","BootFeedback"}) do
	if not remotes:FindFirstChild(name) then
		local event=Instance.new("RemoteEvent")
		event.Name=name
		event.Parent=remotes
	end
end

local WorldBuilder=require(script.Parent.World.WorldBuilder)
local PlayerService=require(script.Parent.Services.PlayerService)
local CombatService=require(script.Parent.Services.CombatService)
local MovementService=require(script.Parent.Services.MovementService)
local MapTravelService=require(script.Parent.Services.MapTravelService)

local bootFeedback=remotes:WaitForChild("BootFeedback")
local bootRequest=remotes:WaitForChild("BootRequest")
local stages:{[string]:boolean}={}
local bootEpoch=0
local busy=false

local function stage(name:string,callback:()->boolean?):boolean
	workspace:SetAttribute("CollisionBattlestarBootStage",name)
	local ok,result=pcall(callback)
	if not ok then
		workspace:SetAttribute("CollisionBattlestarBootError",name..": "..tostring(result))
		return false
	end
	if result==false then
		workspace:SetAttribute("CollisionBattlestarBootError",name..": verification failed")
		return false
	end
	stages[name]=true
	workspace:SetAttribute("CollisionBattlestarBootError","")
	return true
end

local function verifyRuntime():boolean
	local world=workspace:FindFirstChild("CollisionBattlestarWorld")
	local map=world and world:FindFirstChild("Map")
	local spawns=world and world:FindFirstChild("Spawns")
	if not world or not world:IsA("Folder") or not map or not spawns then return false end
	if workspace:GetAttribute("CollisionBattlestarMapReady")~=true then return false end
	if world:GetAttribute("MapLoaded")~=true then return false end
	local spawnCount=0
	for _,item in ipairs(spawns:GetChildren()) do
		if item:IsA("SpawnLocation") then spawnCount+=1 end
	end
	return spawnCount>=5
end

local function configureCharacter(player:Player,character:Model)
	task.defer(function()
		local humanoid=character:WaitForChild("Humanoid",8)
		local root=character:WaitForChild("HumanoidRootPart",8)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.WalkSpeed=Config.Movement.WalkSpeed
			humanoid.UseJumpPower=true
			humanoid.JumpPower=Config.Movement.JumpPower
		end
		if root and root:IsA("BasePart") then root.AssemblyLinearVelocity=Vector3.zero end
	end)
end

local function bindPlayer(player:Player)
	player.CharacterAdded:Connect(function(character) configureCharacter(player,character) end)
	if player.Character then configureCharacter(player,player.Character) end
end

local function ensure()
	if busy then return end
	busy=true
	bootEpoch+=1
	local epoch=bootEpoch
	workspace:SetAttribute("CollisionBattlestarReady",false)
	workspace:SetAttribute("CollisionBattlestarBootEpoch",epoch)
	workspace:SetAttribute("CollisionBattlestarBootStage","starting")
	workspace:SetAttribute("CollisionBattlestarBootError","")

	if not stages.World then
		stage("World",function() return WorldBuilder.Init() end)
	elseif not WorldBuilder.Verify() then
		stages.World=false
		stage("WorldRepair",function() return WorldBuilder.Rebuild() end)
	end

	if not stages.PlayerService then stage("PlayerService",function() PlayerService.Init() return true end) end
	if not stages.CombatService then stage("CombatService",function() CombatService.Init() return true end) end
	if not stages.MovementService then stage("MovementService",function() MovementService.Init() return true end) end
	if not stages.MapTravelService then stage("MapTravelService",function() MapTravelService.Init() return true end) end

	local verified=verifyRuntime()
	if not verified then
		stages.World=false
		verified=stage("WorldRepair",function() return WorldBuilder.Rebuild() end) and verifyRuntime()
	end

	if verified then
		workspace:SetAttribute("CollisionBattlestarBuild",BuildInfo.BuildTag)
		workspace:SetAttribute("CollisionBattlestarMap",BuildInfo.Map)
		workspace:SetAttribute("CollisionBattlestarVersion",BuildInfo.Version)
		workspace:SetAttribute("CollisionBattlestarReady",true)
		workspace:SetAttribute("CollisionBattlestarBootStage","ready")
		workspace:SetAttribute("CollisionBattlestarBootError","")
		bootFeedback:FireAllClients("Ready",epoch)
	else
		workspace:SetAttribute("CollisionBattlestarReady",false)
		workspace:SetAttribute("CollisionBattlestarBootStage","repairing")
		bootFeedback:FireAllClients("Retry",workspace:GetAttribute("CollisionBattlestarBootError") or "runtime verification failed")
	end
	busy=false
end

bootRequest.OnServerEvent:Connect(function(player:Player)
	bootFeedback:FireClient(player,"Checking",workspace:GetAttribute("CollisionBattlestarBootStage") or "starting")
	ensure()
end)

Players.PlayerAdded:Connect(bindPlayer)
for _,player in ipairs(Players:GetPlayers()) do bindPlayer(player) end

task.spawn(function()
	for attempt=1,8 do
		ensure()
		if workspace:GetAttribute("CollisionBattlestarReady")==true then break end
		task.wait(math.min(2+attempt*.5,6))
	end
	while true do
		task.wait(5)
		if workspace:GetAttribute("CollisionBattlestarReady")~=true or not verifyRuntime() then
			ensure()
		end
	end
end)
