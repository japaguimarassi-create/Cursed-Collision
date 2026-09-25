--!strict
local UIS=game:GetService("UserInputService");local R=game:GetService("ReplicatedStorage");local remote=R:WaitForChild("CollisionRemotes"):WaitForChild("CombatRequest");local Players=game:GetService("Players")
local function makeTouchSprint() if not UIS.TouchEnabled then return end local gui=Instance.new("ScreenGui");gui.Name="CollisionSprint";gui.ResetOnSpawn=false;gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui");local b=Instance.new("TextButton");b.Size=UDim2.fromOffset(105,50);b.Position=UDim2.new(1,-125,1,-270);b.BackgroundColor3=Color3.fromRGB(27,30,42);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBlack;b.TextSize=13;b.Text="SPRINT";local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=b;b.Parent=gui;b.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then remote:FireServer("SprintStart")end end);b.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch then remote:FireServer("SprintEnd")end end) end;makeTouchSprint()
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift or input.KeyCode==Enum.KeyCode.ButtonL3 then remote:FireServer("SprintStart")end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift or input.KeyCode==Enum.KeyCode.ButtonL3 then remote:FireServer("SprintEnd")end
end)
return {}
