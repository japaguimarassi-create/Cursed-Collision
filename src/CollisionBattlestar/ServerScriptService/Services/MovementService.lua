--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local C=require(R.Shared.Config);local Anti=require(script.Parent.Parent.Security.AntiCheatService)
local S={}
function S.Init()
	local remote=R.CollisionRemotes.CombatRequest
	remote.OnServerEvent:Connect(function(p,action)
		if action~="SprintStart"and action~="SprintEnd"then return end
		if not Anti.Allow(p)then return end
		local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");if not h or h.Health<=0 then return end
		if action=="SprintStart"and p:GetAttribute("IsBlocking")~=true then h.WalkSpeed=C.Movement.SprintSpeed;p:SetAttribute("Sprinting",true)
		else h.WalkSpeed=C.Movement.WalkSpeed;p:SetAttribute("Sprinting",false)end
	end)
	Players.PlayerAdded:Connect(function(p)p:SetAttribute("Sprinting",false);p.CharacterAdded:Connect(function(c)local h=c:WaitForChild("Humanoid");h.WalkSpeed=C.Movement.WalkSpeed end)end)
end
return S
