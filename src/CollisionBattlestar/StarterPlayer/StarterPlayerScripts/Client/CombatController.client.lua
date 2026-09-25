--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")

local player=Players.LocalPlayer
local remote=R:WaitForChild("CollisionRemotes"):WaitForChild("CombatRequest")

local function request(action:string)
	remote:FireServer(action)
end

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then request("Light");return end
	if input.UserInputType==Enum.UserInputType.MouseButton2 then request("BlockStart");return end
	if input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonX then request("Heavy")
	elseif input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.ButtonB then request("Dash")
	elseif input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonY then request("Special")
	elseif input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonA then request("Overdrive")
	elseif input.KeyCode==Enum.KeyCode.T or input.KeyCode==Enum.KeyCode.DPadUp then request("StyleToggle")
	elseif input.KeyCode==Enum.KeyCode.Space then request("Parry")
	elseif input.KeyCode==Enum.KeyCode.ButtonR2 then request("Light")
	elseif input.KeyCode==Enum.KeyCode.ButtonL2 then request("BlockStart")end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.ButtonL2 then
		request("BlockEnd")
	end
end)

return {}
