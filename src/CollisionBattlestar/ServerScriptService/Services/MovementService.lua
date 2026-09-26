--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)

local S={}
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("CombatRequest")

local function apply(player:Player,sprinting:boolean)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health>0 then
		humanoid.WalkSpeed=sprinting and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed
	end
end

function S.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				apply(player,false)
			end)
		end)
	end)
	request.OnServerEvent:Connect(function(player,action,value)
		if action=="Sprint" then apply(player,value==true) end
	end)
end

return S
