--!strict
local Players=game:GetService("Players");local UIS=game:GetService("UserInputService")
local p=Players.LocalPlayer;local gui=Instance.new("ScreenGui");gui.Name="CollisionMenu";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Parent=p:WaitForChild("PlayerGui")
local open=false
local panel=Instance.new("Frame");panel.Size=UDim2.fromScale(.62,.68);panel.Position=UDim2.fromScale(.19,.16);panel.BackgroundColor3=Color3.fromRGB(14,16,24);panel.BackgroundTransparency=.04;panel.Visible=false;panel.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,16);corner.Parent=panel
local title=Instance.new("TextLabel");title.Size=UDim2.fromScale(.9,.1);title.Position=UDim2.fromScale(.05,.03);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBlack;title.TextScaled=true;title.TextColor3=Color3.fromRGB(245,245,255);title.Text="COLLISION MENU";title.Parent=panel
local body=Instance.new("TextLabel");body.Size=UDim2.fromScale(.9,.68);body.Position=UDim2.fromScale(.05,.16);body.BackgroundTransparency=1;body.Font=Enum.Font.GothamMedium;body.TextSize=18;body.TextWrapped=true;body.TextXAlignment=Enum.TextXAlignment.Left;body.TextYAlignment=Enum.TextYAlignment.Top;body.TextColor3=Color3.fromRGB(220,225,240);body.Parent=panel
local close=Instance.new("TextButton");close.Size=UDim2.fromScale(.24,.1);close.Position=UDim2.fromScale(.38,.86);close.BackgroundColor3=Color3.fromRGB(32,36,50);close.TextColor3=Color3.new(1,1,1);close.Font=Enum.Font.GothamBold;close.Text="CLOSE";close.Parent=panel;local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,10);cc.Parent=close
local function refresh()
	local ls=p:FindFirstChild("leaderstats");local cr=ls and ls:FindFirstChild("Credits");local credits=cr and cr:IsA("IntValue")and cr.Value or 0
	local level=p:GetAttribute("Level")or 1;local xp=p:GetAttribute("XP")or 0;local exploration=p:GetAttribute("Exploration")or 0
	local q=p:GetAttribute("QuestProgress")or 0;local qt=p:GetAttribute("QuestTarget")or 6;local style=p:GetAttribute("CombatStyle")or"Blade";local state=workspace:GetAttribute("CollisionState")or"Stable"
	body.Text=("LOADOUT\n• Starter Blade\n• Combat Style: %s\n\nPROGRESSION\n• Level %d\n• XP %d\n• Exploration %d\n• Credits %d\n\nMISSION\n• First Response: %d / %d\n\nWORLD\n• Fracture District: %s\n• Threat: %d\n• Energy: %d"):format(style,level,xp,exploration,credits,q,qt,state,workspace:GetAttribute("CollisionThreat")or 0,workspace:GetAttribute("CollisionEnergy")or 0)
end
local function toggle()open=not open;panel.Visible=open;if open then refresh()end end
close.Activated:Connect(toggle)
UIS.InputBegan:Connect(function(input,gp)if gp then return end;if input.KeyCode==Enum.KeyCode.Tab then toggle()end end)
if UIS.TouchEnabled then local b=Instance.new("TextButton");b.Size=UDim2.fromOffset(96,46);b.Position=UDim2.new(1,-112,0,18);b.BackgroundColor3=Color3.fromRGB(27,30,42);b.TextColor3=Color3.new(1,1,1);b.Font=Enum.Font.GothamBlack;b.TextSize=12;b.Text="MENU";b.Parent=gui;local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,10);bc.Parent=b;b.Activated:Connect(toggle)end
task.spawn(function()while gui.Parent do if open then refresh()end;task.wait(.25)end end)
