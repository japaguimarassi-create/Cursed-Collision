--!strict
local UIS=game:GetService("UserInputService");local R=game:GetService("ReplicatedStorage");local remote=R:WaitForChild("CollisionRemotes"):WaitForChild("CombatRequest")
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift or input.KeyCode==Enum.KeyCode.ButtonL3 then remote:FireServer("SprintStart")end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift or input.KeyCode==Enum.KeyCode.ButtonL3 then remote:FireServer("SprintEnd")end
end)
return {}
