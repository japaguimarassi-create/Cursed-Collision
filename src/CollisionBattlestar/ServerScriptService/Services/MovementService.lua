--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.Shared.Config)
local S={}
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("MovementRequest")

local function apply(player:Player,sprinting:boolean)
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health>0 then
		if (tonumber(player:GetAttribute("HitStunUntil"))or 0)>os.clock() then
			humanoid.WalkSpeed=10
		else
			humanoid.WalkSpeed=sprinting and Config.Movement.SprintSpeed or Config.Movement.WalkSpeed
		end
		humanoid.UseJumpPower=true
		humanoid.JumpPower=Config.Movement.JumpPower
	end
end

function S.Init()
	local function bind(player:Player)
		player.CharacterAdded:Connect(function(character)
			local humanoid=character:WaitForChild("Humanoid",8)
			if humanoid and humanoid:IsA("Humanoid") then apply(player,false) end
		end)
	end
	Players.PlayerAdded:Connect(bind)
	for _,player in ipairs(Players:GetPlayers()) do bind(player) end
	request.OnServerEvent:Connect(function(player,action,value)
		if action=="Sprint" then apply(player,value==true) end
	end)
end
return S
