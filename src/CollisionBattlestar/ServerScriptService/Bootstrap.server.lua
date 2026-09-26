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
for _,name in ipairs({"CombatRequest","MovementRequest","Feedback","MapTravelRequest","MapTravelFeedback"}) do
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

WorldBuilder.Init()
PlayerService.Init()
CombatService.Init()
MovementService.Init()
MapTravelService.Init()

workspace:SetAttribute("CollisionBattlestarReady",true)
workspace:SetAttribute("CollisionBattlestarBuild",BuildInfo.BuildTag)
workspace:SetAttribute("CollisionBattlestarMap",BuildInfo.Map)
workspace:SetAttribute("CollisionBattlestarVersion",BuildInfo.Version)

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
Players.PlayerAdded:Connect(bindPlayer)
for _,player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
