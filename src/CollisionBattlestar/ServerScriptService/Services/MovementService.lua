--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local C=require(R.Shared.Config)
local Anti=require(script.Parent.Parent.Security.AntiCheatService)

local S={}
local bound:{[Player]:boolean}={}

local function bind(p:Player)
	if bound[p]then return end
	bound[p]=true
	p:SetAttribute("Sprinting",false)
	p.CharacterAdded:Connect(function(character)
		local humanoid=character:WaitForChild("Humanoid",5)
		if humanoid and humanoid:IsA("Humanoid")then
			humanoid.WalkSpeed=C.Movement.WalkSpeed
		end
	end)
	if p.Character then
		local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed=C.Movement.WalkSpeed end
	end
end

function S.Init()
	local remote=R.CollisionRemotes.CombatRequest
	remote.OnServerEvent:Connect(function(p:Player,action:any)
		if action~="SprintStart"and action~="SprintEnd"then return end
		if not Anti.Allow(p)then return end
		local c=p.Character
		local h=c and c:FindFirstChildOfClass("Humanoid")
		if not h or h.Health<=0 then return end
		if action=="SprintStart"and p:GetAttribute("IsBlocking")~=true then
			h.WalkSpeed=C.Movement.SprintSpeed
			p:SetAttribute("Sprinting",true)
		else
			h.WalkSpeed=C.Movement.WalkSpeed
			p:SetAttribute("Sprinting",false)
		end
	end)
	Players.PlayerAdded:Connect(bind)
	Players.PlayerRemoving:Connect(function(p)bound[p]=nil end)
	for _,p in ipairs(Players:GetPlayers())do bind(p)end
end

return S