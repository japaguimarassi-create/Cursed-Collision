--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local UIS=game:GetService("UserInputService");local TweenService=game:GetService("TweenService")
local p=Players.LocalPlayer
local remotes=R:WaitForChild("CollisionRemotes")
local defs=require(R.Shared.GamePassDefinitions)
local gui=Instance.new("ScreenGui");gui.Name="CollisionBattlestarHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Parent=p:WaitForChild("PlayerGui")

local function round(x:GuiObject,r:number)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=x end
local function stroke(x:GuiObject,color:Color3,thickness:number?)local s=Instance.new("UIStroke");s.Color=color;s.Thickness=thickness or 1;s.Transparency=.28;s.Parent=x end
local function textButton(parent:Instance,name:string,label:string,size:UDim2,pos:UDim2,color:Color3):TextButton
	local b=Instance.new("TextButton");b.Name=name;b.Size=size;b.Position=pos;b.BackgroundColor3=color;b.TextColor3=Color3.fromRGB(245,245,255);b.Font=Enum.Font.GothamBold;b.TextSize=13;b.Text=label;b.AutoButtonColor=true;b.Parent=parent;round(b,10);return b
end

local panel=Instance.new("Frame");panel.Size=UIS.TouchEnabled and UDim2.fromScale(.56,.13)or UDim2.fromScale(.44,.17);panel.Position=UIS.TouchEnabled and UDim2.fromScale(.22,.02)or UDim2.fromScale(.025,.03);panel.BackgroundColor3=Color3.fromRGB(18,20,28);panel.BackgroundTransparency=.08;panel.Parent=gui;round(panel,12);stroke(panel,Color3.fromRGB(92,198,255),1)
local title=Instance.new("TextLabel");title.Size=UDim2.fromScale(.70,.28);title.Position=UDim2.fromScale(.04,.05);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBlack;title.TextSize=UIS.TouchEnabled and 15 or 20;title.TextXAlignment=Enum.TextXAlignment.Left;title.TextColor3=Color3.fromRGB(245,245,255);title.Text="COLLISION BATTLESTAR";title.Parent=panel
local state=Instance.new("TextLabel");state.Size=UDim2.fromScale(.96,.22);state.Position=UDim2.fromScale(.04,.37);state.BackgroundTransparency=1;state.Font=Enum.Font.GothamBold;state.TextSize=UIS.TouchEnabled and 9 or 12;state.TextXAlignment=Enum.TextXAlignment.Left;state.TextColor3=Color3.fromRGB(175,185,210);state.Parent=panel
local credits=Instance.new("TextLabel");credits.Size=UDim2.fromScale(.25,.28);credits.Position=UDim2.fromScale(.71,.05);credits.BackgroundTransparency=1;credits.Font=Enum.Font.GothamBold;credits.TextSize=UIS.TouchEnabled and 12 or 15;credits.TextXAlignment=Enum.TextXAlignment.Right;credits.TextColor3=Color3.fromRGB(255,220,100);credits.Parent=panel

local mapBanner=Instance.new("TextLabel");mapBanner.Size=UIS.TouchEnabled and UDim2.fromScale(.44,.055)or UDim2.fromScale(.34,.045);mapBanner.Position=UIS.TouchEnabled and UDim2.fromScale(.28,.155)or UDim2.fromScale(.33,.035);mapBanner.BackgroundColor3=Color3.fromRGB(18,20,28);mapBanner.BackgroundTransparency=.12;mapBanner.Font=Enum.Font.GothamBold;mapBanner.TextSize=UIS.TouchEnabled and 10 or 12;mapBanner.TextColor3=Color3.fromRGB(145,225,255);mapBanner.Text="CITY ONLINE";mapBanner.Parent=gui;round(mapBanner,9);stroke(mapBanner,Color3.fromRGB(92,198,255),1)

local quest=Instance.new("TextLabel");quest.Size=UDim2.fromScale(.34,.065);quest.Position=UIS.TouchEnabled and UDim2.fromScale(.33,.22)or UDim2.fromScale(.33,.09);quest.BackgroundColor3=Color3.fromRGB(18,20,28);quest.BackgroundTransparency=.15;quest.Font=Enum.Font.GothamBold;quest.TextSize=UIS.TouchEnabled and 11 or 14;quest.TextColor3=Color3.fromRGB(235,240,255);quest.Parent=gui;round(quest,10)
local streak=Instance.new("TextLabel");streak.Size=UDim2.fromScale(.34,.055);streak.Position=UIS.TouchEnabled and UDim2.fromScale(.33,.285)or UDim2.fromScale(.33,.16);streak.BackgroundColor3=Color3.fromRGB(18,20,28);streak.BackgroundTransparency=.18;streak.Font=Enum.Font.GothamBlack;streak.TextSize=UIS.TouchEnabled and 10 or 13;streak.TextColor3=Color3.fromRGB(255,220,100);streak.Text="BATTLE STREAK • READY";streak.Parent=gui;round(streak,9)

local alert=Instance.new("TextLabel");alert.AnchorPoint=Vector2.new(.5,.5);alert.Size=UDim2.fromScale(.62,.1);alert.Position=UDim2.fromScale(.5,.22);alert.BackgroundTransparency=1;alert.Font=Enum.Font.GothamBlack;alert.TextScaled=true;alert.TextColor3=Color3.new(1,1,1);alert.TextStrokeTransparency=.25;alert.Visible=false;alert.Parent=gui

local menuButton:TextButton?=nil
local menuPanel:Frame?=nil
local shopPanel:Frame?=nil

local function notify(message:string,duration:number?)
	alert.Text=message;alert.Visible=true;alert.TextTransparency=0
	task.delay(duration or 2.3,function()
		if not alert.Parent then return end
		local tw=TweenService:Create(alert,TweenInfo.new(.3),{TextTransparency=1});tw:Play();tw.Completed:Wait();alert.Visible=false
	end)
end

local function openShop()
	if shopPanel then
		shopPanel.Visible=true
		if menuPanel then menuPanel.Visible=false end
	end
end

if UIS.TouchEnabled then
	menuButton=textButton(gui,"MobileMenu","☰",UDim2.fromOffset(50,44),UDim2.fromScale(.025,.02),Color3.fromRGB(22,25,35))
	menuButton.TextSize=22;stroke(menuButton,Color3.fromRGB(178,92,255),1.2)
	menuPanel=Instance.new("Frame");menuPanel.Size=UDim2.fromScale(.48,.52);menuPanel.Position=UDim2.fromScale(.025,.08);menuPanel.BackgroundColor3=Color3.fromRGB(16,18,25);menuPanel.BackgroundTransparency=.03;menuPanel.Visible=false;menuPanel.Parent=gui;round(menuPanel,14);stroke(menuPanel,Color3.fromRGB(178,92,255),1.2)
	local menuTitle=Instance.new("TextLabel");menuTitle.Size=UDim2.fromScale(.88,.11);menuTitle.Position=UDim2.fromScale(.06,.04);menuTitle.BackgroundTransparency=1;menuTitle.Font=Enum.Font.GothamBlack;menuTitle.TextSize=15;menuTitle.TextXAlignment=Enum.TextXAlignment.Left;menuTitle.TextColor3=Color3.fromRGB(245,245,255);menuTitle.Text="BATTLESTAR MENU";menuTitle.Parent=menuPanel
	local menuList=Instance.new("Frame");menuList.Size=UDim2.fromScale(.88,.79);menuList.Position=UDim2.fromScale(.06,.15);menuList.BackgroundTransparency=1;menuList.Parent=menuPanel
	local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,7);layout.FillDirection=Enum.FillDirection.Vertical;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=menuList
	for order,item in ipairs({{"SHOP","Shop"},{"CHARACTERS","Characters"},{"EMOTES","Emotes"},{"QUESTS","Quests"},{"PROFILE","Profile"},{"SETTINGS","Settings"}})do
		local b=textButton(menuList,item[1],item[1],UDim2.new(1,0,0,42),UDim2.new(),order%3==1 and Color3.fromRGB(27,35,48)or order%3==2 and Color3.fromRGB(35,29,46)or Color3.fromRGB(29,39,34))
		b.LayoutOrder=order
		b.MouseButton1Click:Connect(function()
			if item[2]=="Shop" then openShop() else if menuPanel then menuPanel.Visible=false end;notify(item[1].." MENU") end
		end)
	end
	menuButton.MouseButton1Click:Connect(function()if menuPanel then menuPanel.Visible=not menuPanel.Visible end end)
end

shopPanel=Instance.new("Frame");shopPanel.Size=UIS.TouchEnabled and UDim2.fromScale(.88,.76)or UDim2.fromScale(.70,.78);shopPanel.Position=UIS.TouchEnabled and UDim2.fromScale(.06,.13)or UDim2.fromScale(.15,.11);shopPanel.BackgroundColor3=Color3.fromRGB(15,17,23);shopPanel.BackgroundTransparency=.02;shopPanel.Visible=false;shopPanel.Parent=gui;round(shopPanel,16);stroke(shopPanel,Color3.fromRGB(86,221,160),1.4)
local shopHeader=Instance.new("TextLabel");shopHeader.Size=UDim2.fromScale(.70,.09);shopHeader.Position=UDim2.fromScale(.04,.03);shopHeader.BackgroundTransparency=1;shopHeader.Font=Enum.Font.GothamBlack;shopHeader.TextSize=20;shopHeader.TextXAlignment=Enum.TextXAlignment.Left;shopHeader.TextColor3=Color3.fromRGB(245,245,255);shopHeader.Text="SHOP";shopHeader.Parent=shopPanel
local shopSub=Instance.new("TextLabel");shopSub.Size=UDim2.fromScale(.72,.06);shopSub.Position=UDim2.fromScale(.04,.105);shopSub.BackgroundTransparency=1;shopSub.Font=Enum.Font.GothamBold;shopSub.TextSize=11;shopSub.TextXAlignment=Enum.TextXAlignment.Left;shopSub.TextColor3=Color3.fromRGB(165,175,195);shopSub.Text="COSMETICS • CONVENIENCE • PRIVATE SERVER";shopSub.Parent=shopPanel
local shopClose=textButton(shopPanel,"ShopClose","×",UDim2.fromOffset(46,42),UDim2.fromScale(.91,.025),Color3.fromRGB(95,37,45));shopClose.TextSize=26;shopClose.MouseButton1Click:Connect(function()shopPanel.Visible=false end)
local scroll=Instance.new("ScrollingFrame");scroll.Size=UDim2.fromScale(.92,.79);scroll.Position=UDim2.fromScale(.04,.18);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=4;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=shopPanel
local grid=Instance.new("UIGridLayout");grid.CellSize=UIS.TouchEnabled and UDim2.fromScale(.47,.18)or UDim2.fromScale(.31,.24);grid.CellPadding=UDim2.fromScale(.025,.025);grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.Parent=scroll
local keys={}
for key in defs.Passes do table.insert(keys,key)end
table.sort(keys)
for index,key in ipairs(keys)do
	local definition=defs.Passes[key]
	local card=Instance.new("Frame");card.Name=key;card.BackgroundColor3=Color3.fromRGB(23,26,35);card.BorderSizePixel=0;card.LayoutOrder=index;card.Parent=scroll;round(card,11);stroke(card,definition.Category=="Premium" and Color3.fromRGB(178,92,255)or definition.Category=="PrivateServer" and Color3.fromRGB(255,196,82)or Color3.fromRGB(86,176,255),1)
	local name=Instance.new("TextLabel");name.Size=UDim2.fromScale(.92,.30);name.Position=UDim2.fromScale(.04,.05);name.BackgroundTransparency=1;name.Font=Enum.Font.GothamBlack;name.TextSize=12;name.TextWrapped=true;name.TextColor3=Color3.fromRGB(245,245,255);name.Text=key;name.Parent=card
	local price=Instance.new("TextLabel");price.Size=UDim2.fromScale(.45,.20);price.Position=UDim2.fromScale(.04,.38);price.BackgroundTransparency=1;price.Font=Enum.Font.GothamBold;price.TextSize=11;price.TextXAlignment=Enum.TextXAlignment.Left;price.TextColor3=Color3.fromRGB(125,230,170);price.Text=tostring(definition.TargetPrice).." R$";price.Parent=card
	local buy=textButton(card,"Buy","BUY",UDim2.fromScale(.38,.30),UDim2.fromScale(.58,.62),Color3.fromRGB(42,92,68));buy.TextSize=11
	local function sync()
		if p:GetAttribute("Pass_"..key)==true then buy.Text="OWNED";buy.BackgroundColor3=Color3.fromRGB(54,65,60) else buy.Text="BUY";buy.BackgroundColor3=Color3.fromRGB(42,92,68)end
	end
	buy.MouseButton1Click:Connect(function()
		if p:GetAttribute("Pass_"..key)==true then return end
		remotes.GamePassRequest:FireServer(key)
	end)
	p:GetAttributeChangedSignal("Pass_"..key):Connect(sync);sync()
end

local hud=Instance.new("Frame");hud.Size=UDim2.fromScale(.40,.22);hud.Position=UIS.TouchEnabled and UDim2.fromScale(.025,.74)or UDim2.fromScale(.025,.75);hud.BackgroundColor3=Color3.fromRGB(18,20,28);hud.BackgroundTransparency=.1;hud.Parent=gui;round(hud,12);stroke(hud,Color3.fromRGB(92,198,255),1)
local function bar(y:number,color:Color3)local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(.9,.14);bg.Position=UDim2.fromScale(.05,y);bg.BackgroundColor3=Color3.fromRGB(34,36,48);bg.BorderSizePixel=0;bg.Parent=hud;round(bg,6);local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=color;fill.BorderSizePixel=0;fill.Parent=bg;round(fill,6);local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextSize=12;label.TextColor3=Color3.new(1,1,1);label.Parent=bg;return fill,label end
local hp,hpt=bar(.08,Color3.fromRGB(110,220,120));local mom,momt=bar(.32,Color3.fromRGB(180,105,255));local inst,instt=bar(.56,Color3.fromRGB(255,120,85))

local controls=Instance.new("Frame");controls.Size=UDim2.fromScale(.45,.38);controls.Position=UDim2.fromScale(.53,.59);controls.BackgroundTransparency=1;controls.Visible=UIS.TouchEnabled;controls.Parent=gui
local gridControls=Instance.new("UIGridLayout");gridControls.CellSize=UDim2.fromScale(.29,.21);gridControls.CellPadding=UDim2.fromScale(.04,.05);gridControls.Parent=controls
for _,e in ipairs({{"LIGHT","Light"},{"HEAVY","Heavy"},{"BLOCK","BlockStart"},{"PARRY","Parry"},{"DASH","Dash"},{"SPECIAL","Special"},{"OVERDRIVE","Overdrive"},{"STYLE","StyleToggle"}})do
	local b=textButton(controls,e[1],e[1],UDim2.new(),UDim2.new(),Color3.fromRGB(27,30,42));b.Font=Enum.Font.GothamBlack;b.TextSize=11;round(b,12);stroke(b,e[2]=="Special" and Color3.fromRGB(178,92,255)or Color3.fromRGB(92,198,255),1)
	b.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
		if workspace:GetAttribute("CollisionBattlestarMapReady")~=true then notify("MAP INITIALIZING",1) return end
		remotes.CombatRequest:FireServer(e[2])
	end end)
	if e[2]=="BlockStart"then
		b.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then remotes.CombatRequest:FireServer("BlockEnd")end end)
	end
end

remotes.Feedback.OnClientEvent:Connect(function(k,v)
	if k=="QuestStart"or k=="QuestComplete"or k=="OverdriveStart"or k=="OverdriveCollapse"or k=="OverdriveDenied"or k=="Style"then notify(tostring(v or k))
	elseif k=="ParrySuccess"then notify("PARRY",.7)elseif k=="GuardBreak"then notify("GUARD BREAK",.7)
	elseif k=="PassUnlocked"then notify("UNLOCKED • "..tostring(v),1.5)
	elseif k=="PassRequired"then notify("PASS REQUIRED • "..tostring(typeof(v)=="table"and v.Pass or "PREMIUM"),1.5)
	elseif k=="PassError"then notify(tostring(v),1.5)
	end
end)
remotes.WorldState.OnClientEvent:Connect(function(k,v)
	if k=="Warning"then notify("REALITY BREAK — DESTABILIZATION",7)elseif k=="Begin"then notify("REALITY BREAK — BEGIN",1.5)elseif k=="Escalation"then notify("REALITY BREAK — ESCALATION",2)elseif k=="Climax"then notify(v.Title.." — "..v.Subtitle,4)elseif k=="End"then notify("REALITY BREAK — RESOLVED",2)end
end)

task.spawn(function()
	local announced=false
	while gui.Parent do
		local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local max=h and h.MaxHealth or 100;local health=h and h.Health or 0;local m=p:GetAttribute("Momentum")or 0;local i=p:GetAttribute("Instability")or 0
		hp.Size=UDim2.fromScale(math.clamp(health/max,0,1),1);mom.Size=UDim2.fromScale(math.clamp(m/100,0,1),1);inst.Size=UDim2.fromScale(math.clamp(i/100,0,1),1)
		hpt.Text=("HP %d / %d"):format(math.floor(health),math.floor(max));momt.Text=("MOMENTUM %d"):format(math.floor(m));instt.Text=("INSTABILITY %d"):format(math.floor(i))
		local ready=workspace:GetAttribute("CollisionBattlestarMapReady")==true
		mapBanner.Text=ready and"FRACTURE DISTRICT • ONLINE"or"FRACTURE DISTRICT • LOADING"
		mapBanner.TextColor3=ready and Color3.fromRGB(145,225,255)or Color3.fromRGB(255,205,115)
		if ready and not announced then announced=true;notify("FRACTURE DISTRICT • ONLINE",1.4)end
		state.Text=("FRACTURE DISTRICT • %s • %s"):format(string.upper(tostring(workspace:GetAttribute("CollisionState")or"Stable")),tostring(p:GetAttribute("CombatStyle")or"Blade"))
		local q=p:GetAttribute("QuestProgress")or 0;local qt=p:GetAttribute("QuestTarget")or 6;quest.Text=p:GetAttribute("QuestCompleted")and"FIRST RESPONSE • COMPLETE"or("FIRST RESPONSE • %d / %d"):format(q,qt)
		local best=p:GetAttribute("BattleStreakBest")or 0;if not p:GetAttribute("BattleStreakActive")then streak.Text=("BATTLE STREAK • BEST %d"):format(best)end
		local ls=p:FindFirstChild("leaderstats");local cr=ls and ls:FindFirstChild("Credits");credits.Text=cr and cr:IsA("IntValue")and("%d CR"):format(cr.Value)or"0 CR"
		task.wait(.15)
	end
end)
return {}
