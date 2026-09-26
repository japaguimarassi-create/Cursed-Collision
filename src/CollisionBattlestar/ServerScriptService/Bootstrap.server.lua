--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")

local remotes=ReplicatedStorage:FindFirstChild("CollisionRemotes")
if not remotes then
	remotes=Instance.new("Folder")
	remotes.Name="CollisionRemotes"
	remotes.Parent=ReplicatedStorage
end

for _,name in ipairs({"CombatRequest","Feedback","MapTravelRequest","MapTravelFeedback"}) do
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
workspace:SetAttribute("CollisionBattlestarBuild","clean-core-2026-09-26")
workspace:SetAttribute("CollisionBattlestarMap","BattleLine_Clean_v1")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			local humanoid=character:WaitForChild("Humanoid",8)
			if humanoid then
				humanoid.WalkSpeed=16
			end
		end)
	end)
end)
