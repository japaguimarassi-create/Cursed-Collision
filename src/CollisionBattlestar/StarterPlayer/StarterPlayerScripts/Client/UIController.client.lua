--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local UIS=game:GetService("UserInputService");local TweenService=game:GetService("TweenService")
local p=Players.LocalPlayer;local remotes=R:WaitForChild("CollisionRemotes")
local gui=Instance.new("ScreenGui");gui.Name="CollisionBattlestarHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Parent=p:WaitForChild("PlayerGui")
local function round(x:GuiObject,r:number)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=x end
local panel=Instance.new("Frame");panel.Size=UDim2.fromScale(.44,.17);panel.Position=UDim2.fromScale(.025,.03);panel.BackgroundColor3=Color3.fromRGB(18,20,28);panel.BackgroundTransparency=.1;panel.Parent=gui;round(panel,12)
local title=Instance.new("TextLabel");title.Size=UDim2.fromScale(.72,.25);title.Position=UDim2.fromScale(.04,.05);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBlack;title.TextSize=20;title.TextXAlignment=Enum.TextXAlignment.Left;title.TextColor3=Color3.fromRGB(245,245,255);title.Text="COLLISION BATTLESTAR";title.Parent=panel
local state=Instance.new("TextLabel");state.Size=UDim2.fromScale(.95,.22);state.Position=UDim2.fromScale(.04,.34);state.BackgroundTransparency=1;state.Font=Enum.Font.GothamBold;state.TextSize=12;state.TextXAlignment=Enum.TextXAlignment.Left;state.TextColor3=Color3.fromRGB(175,185,210);state.Parent=panel
local credits=Instance.new("TextLabel");credits.Size=UDim2.fromScale(.23,.25);credits.Position=UDim2.fromScale(.73,.06);credits.BackgroundTransparency=1;credits.Font=Enum.Font.GothamBold;credits.TextSize=15;credits.TextXAlignment=Enum.TextXAlignment.Right;credits.TextColor3=Color3.fromRGB(255,220,100);credits.Parent=panel
local hud=Instance.new("Frame");hud.Size=UDim2.fromScale(.40,.22);hud.Position=UDim2.fromScale(.025,.75);hud.BackgroundColor3=Color3.fromRGB(18,20,28);hud.BackgroundTransparency=.1;hud.Parent=gui;round(hud,12)
local function bar(y:number,color:Color3)local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(.9,.14);bg.Position=UDim2.fromScale(.05,y);bg.BackgroundColor3=Color3.fromRGB(34,36,48);bg.BorderSizePixel=0;bg.Parent=hud;round(bg,6);local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=color;fill.BorderSizePixel=0;fill.Parent=bg;round(fill,6);local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextSize=12;label.TextColor3=Color3.new(1,1,1);label.Parent=bg;return fill,label end
local hp,hpt=bar(.08,Color3.fromRGB(110,220,120));local mom,momt=bar(.32,Color3.fromRGB(180,105,255));local inst,instt=bar(.56,Color3.fromRGB(255,120,85))
local quest=Instance.new("TextLabel");quest.Size=UDim2.fromScale(.34,.065);quest.Position=UDim2.fromScale(.33,.035);quest.BackgroundColor3=Color3.fromRGB(18,20,28);quest.BackgroundTransparency=.15;quest.Font=Enum.Font.GothamBold;quest.TextSize=14;quest.TextColor3=Color3.fromRGB(235,240,255);quest.Parent=gui;round(quest,10)
local streak=Instance.new("TextLabel");streak.Size=UDim2.fromScale(.34,.055);streak.Position=UDim2.fromScale(.33,.108);streak.BackgroundColor3=Color3.fromRGB(18,20,28);streak.BackgroundTransparency=.18;streak.Font=Enum.Font.GothamBlack;streak.TextSize=13;streak.TextColor3=Color3.fromRGB(255,220,100);streak.Text="BATTLE STREAK • READY";streak.Parent=gui;round(streak,9)
local alert=Instance.new("TextLabel");alert.AnchorPoint=Vector2.new(.5,.5);alert.Size=UDim2.fromScale(.62,.1);alert.Position=UDim2.fromScale(.5,.22);alert.BackgroundTransparency=1;alert.Font=Enum.Font.GothamBlack;alert.TextScaled=true;alert.TextColor3=Color3.new(1,1,1);alert.TextStrokeTransparency=.25;alert.Visible=false;alert.Parent=gui
local controls=Instance.new("Frame");controls.Size=UDim2.fromScale(.45,.38);controls.Position=UDim2.fromScale(.53,.59);controls.BackgroundTransparency=1;controls.Visible=UIS.TouchEnabled;controls.Parent=gui;local grid=Instance.new("UIGridLayout");grid.CellSize=UDim2.fromScale(.29,.21);grid.CellPadding=UDim2.fromScale(.04,.05);grid.Parent=controls
for _,e in ipairs({{"LIGHT","Light"},{"HEAVY","Heavy"},{"BLOCK","BlockStart"},{"PARRY","Parry"},{"DASH","Dash"},{"SPECIAL","Special"},{"OVERDRIVE","Overdrive"},{"STYLE","StyleToggle"}})do
	local b=Instance.new("TextButton");b.BackgroundColor3=Color3.fromRGB(27,30,42);b.TextColor3=Color3.fromRGB(245,245,255);b.Font=Enum.Font.GothamBlack;b.TextSize=11;b.Text=e[1];b.Parent=controls;round(b,10);b.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then remotes.CombatRequest:FireServer(e[2])end end);if e[2]=="BlockStart"then b.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then remotes.CombatRequest:FireServer("BlockEnd")end end)end
end
local function notify(text:string,duration:number?)alert.Text=text;alert.Visible=true;alert.TextTransparency=0;task.delay(duration or 2.3,function()local tw=TweenService:Create(alert,TweenInfo.new(.3),{TextTransparency=1});tw:Play();tw.Completed:Wait();alert.Visible=false end)end
remotes.Feedback.OnClientEvent:Connect(function(k,v)
	if k=="QuestStart"or k=="QuestComplete"or k=="OverdriveStart"or k=="OverdriveCollapse"or k=="OverdriveDenied"or k=="Style"then notify(tostring(v or k))
	elseif k=="ParrySuccess"then notify("PARRY",.7)elseif k=="GuardBreak"then notify("GUARD BREAK",.7)end
end)
remotes.WorldState.OnClientEvent:Connect(function(k,v)
	if k=="Warning"then notify("REALITY BREAK — DESTABILIZATION",7)elseif k=="Begin"then notify("REALITY BREAK — BEGIN",1.5)elseif k=="Escalation"then notify("REALITY BREAK — ESCALATION",2)elseif k=="Climax"then notify(v.Title.." — "..v.Subtitle,4)elseif k=="End"then notify("REALITY BREAK — RESOLVED",2)end
end)
task.spawn(function()while gui.Parent do
	local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local max=h and h.MaxHealth or 100;local health=h and h.Health or 0;local m=p:GetAttribute("Momentum")or 0;local i=p:GetAttribute("Instability")or 0
	hp.Size=UDim2.fromScale(math.clamp(health/max,0,1),1);mom.Size=UDim2.fromScale(math.clamp(m/100,0,1),1);inst.Size=UDim2.fromScale(math.clamp(i/100,0,1),1)
	hpt.Text=("HP %d / %d"):format(math.floor(health),math.floor(max));momt.Text=("MOMENTUM %d"):format(math.floor(m));instt.Text=("INSTABILITY %d"):format(math.floor(i))
	state.Text=("FRACTURE DISTRICT • %s • %s"):format(string.upper(tostring(workspace:GetAttribute("CollisionState")or"Stable")),tostring(p:GetAttribute("CombatStyle")or"Blade"))
	local q=p:GetAttribute("QuestProgress")or 0;local qt=p:GetAttribute("QuestTarget")or 6;quest.Text=p:GetAttribute("QuestCompleted")and"FIRST RESPONSE • COMPLETE"or("FIRST RESPONSE • %d / %d"):format(q,qt)
	local best=p:GetAttribute("BattleStreakBest")or 0;if not p:GetAttribute("BattleStreakActive")then streak.Text=("BATTLE STREAK • BEST %d"):format(best)end
	local ls=p:FindFirstChild("leaderstats");local cr=ls and ls:FindFirstChild("Credits");credits.Text=cr and cr:IsA("IntValue")and("%d CR"):format(cr.Value)or"0 CR"
	task.wait(.15)
end end)
return {}
