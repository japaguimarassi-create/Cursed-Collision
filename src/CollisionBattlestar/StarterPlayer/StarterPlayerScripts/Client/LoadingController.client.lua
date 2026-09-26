--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

local function make(className:string,parent:Instance,name:string):Instance
	local object=Instance.new(className)
	object.Name=name
	object.Parent=parent
	return object
end

local setPlatform:(()->())=function() end

local boot=make("ScreenGui",playerGui,"CollisionBootScreen") :: ScreenGui
boot.ResetOnSpawn=false
boot.IgnoreGuiInset=false
boot.DisplayOrder=10000
boot.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local background=make("Frame",boot,"Background") :: Frame
background.Size=UDim2.fromScale(1,1)
background.BackgroundColor3=Color3.fromRGB(5,8,13)
background.BorderSizePixel=0

local card=make("Frame",background,"Card") :: Frame
card.AnchorPoint=Vector2.new(.5,.5)
card.Position=UDim2.fromScale(.5,.5)
card.Size=UDim2.fromOffset(470,215)
card.BackgroundColor3=Color3.fromRGB(14,18,25)
card.BorderSizePixel=0

local cardCorner=make("UICorner",card,"Corner") :: UICorner
cardCorner.CornerRadius=UDim.new(0,20)
local cardStroke=make("UIStroke",card,"Stroke") :: UIStroke
cardStroke.Color=Color3.fromRGB(74,89,112)
cardStroke.Transparency=.32
cardStroke.Thickness=1

local title=make("TextLabel",card,"Title") :: TextLabel
title.BackgroundTransparency=1
title.Size=UDim2.new(1,-40,0,40)
title.Position=UDim2.fromOffset(20,22)
title.Font=Enum.Font.GothamBlack
title.Text="COLLISION BATTLESTAR"
title.TextColor3=Color3.fromRGB(244,247,252)
title.TextSize=25
title.TextXAlignment=Enum.TextXAlignment.Center

local stage=make("TextLabel",card,"Stage") :: TextLabel
stage.BackgroundTransparency=1
stage.Size=UDim2.new(1,-40,0,24)
stage.Position=UDim2.fromOffset(20,64)
stage.Font=Enum.Font.GothamBold
stage.Text="STARTING"
stage.TextColor3=Color3.fromRGB(94,205,255)
stage.TextSize=13
stage.TextXAlignment=Enum.TextXAlignment.Center

local status=make("TextLabel",card,"Status") :: TextLabel
status.BackgroundTransparency=1
status.Size=UDim2.new(1,-54,0,42)
status.Position=UDim2.fromOffset(27,93)
status.Font=Enum.Font.Gotham
status.Text="Preparando o jogo..."
status.TextColor3=Color3.fromRGB(165,177,194)
status.TextSize=13
status.TextWrapped=true
status.TextXAlignment=Enum.TextXAlignment.Center

local barBack=make("Frame",card,"BarBack") :: Frame
barBack.Size=UDim2.new(1,-54,0,9)
barBack.Position=UDim2.fromOffset(27,145)
barBack.BackgroundColor3=Color3.fromRGB(35,42,53)
barBack.BorderSizePixel=0
local bb=make("UICorner",barBack,"Corner") :: UICorner
bb.CornerRadius=UDim.new(0,5)

local bar=make("Frame",barBack,"Bar") :: Frame
bar.Size=UDim2.fromScale(0,1)
bar.BackgroundColor3=Color3.fromRGB(94,205,255)
bar.BorderSizePixel=0
local bc=make("UICorner",bar,"Corner") :: UICorner
bc.CornerRadius=UDim.new(0,5)

local checksLabel=make("TextLabel",card,"Checks") :: TextLabel
checksLabel.BackgroundTransparency=1
checksLabel.Size=UDim2.new(1,-54,0,20)
checksLabel.Position=UDim2.fromOffset(27,164)
checksLabel.Font=Enum.Font.GothamMedium
checksLabel.Text="0 / 5"
checksLabel.TextColor3=Color3.fromRGB(114,125,142)
checksLabel.TextSize=10
checksLabel.TextXAlignment=Enum.TextXAlignment.Center

local function setBoot(done:number,total:number)
	bar.Size=UDim2.new(math.clamp(done/math.max(1,total),0,1),0,1,0)
	checksLabel.Text=("%d / %d"):format(done,total)
end

local function safeRemote():Folder?
	local folder=ReplicatedStorage:FindFirstChild("CollisionRemotes")
	if folder and folder:IsA("Folder") then return folder end
	local waited=ReplicatedStorage:WaitForChild("CollisionRemotes",10)
	return waited and waited:IsA("Folder") and waited or nil
end

local remotes=safeRemote()
local bootRequest=remotes and remotes:FindFirstChild("BootRequest")
local bootFeedback=remotes and remotes:FindFirstChild("BootFeedback")

local function makeRound(parent:Instance,size:number,pos:UDim2,textValue:string,name:string):TextButton
	local b=make("TextButton",parent,name) :: TextButton
	b.Size=UDim2.fromOffset(size,size)
	b.Position=pos
	b.BackgroundColor3=Color3.fromRGB(22,28,38)
	b.BackgroundTransparency=.02
	b.BorderSizePixel=0
	b.AutoButtonColor=false
	b.Text=textValue
	b.Font=Enum.Font.GothamBlack
	b.TextSize=13
	b.TextColor3=Color3.fromRGB(244,247,252)
	local c=make("UICorner",b,"Corner") :: UICorner
	c.CornerRadius=UDim.new(1,0)
	local s=make("UIStroke",b,"Stroke") :: UIStroke
	s.Color=Color3.fromRGB(82,98,124)
	s.Transparency=.42
	s.Thickness=1
	return b
end

local function createHUD():ScreenGui?
	local existing=playerGui:FindFirstChild("CollisionHUD")
	if existing and existing:IsA("ScreenGui") then existing:Destroy() end

	local gui=make("ScreenGui",playerGui,"CollisionHUD") :: ScreenGui
	gui.ResetOnSpawn=false
	gui.IgnoreGuiInset=false
	gui.DisplayOrder=25
	gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
	gui:SetAttribute("HUDVersion","4.0")
	gui:SetAttribute("HUDLayoutReady",true)

	local scale=make("UIScale",gui,"ResponsiveScale") :: UIScale
	local function resize()
		local camera=workspace.CurrentCamera
		local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
		scale.Scale=math.clamp(math.min(viewport.X/1200,viewport.Y/720),.68,1.05)
	end
	resize()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end

	local statusFrame=make("Frame",gui,"StatusFrame") :: Frame
	statusFrame.Size=UDim2.fromOffset(355,114)
	statusFrame.Position=UDim2.fromOffset(16,16)
	statusFrame.BackgroundColor3=Color3.fromRGB(14,18,25)
	statusFrame.BackgroundTransparency=.08
	statusFrame.BorderSizePixel=0
	local sc=make("UICorner",statusFrame,"Corner") :: UICorner
	sc.CornerRadius=UDim.new(0,14)
	local ss=make("UIStroke",statusFrame,"Stroke") :: UIStroke
	ss.Color=Color3.fromRGB(74,89,112)
	ss.Transparency=.48
	ss.Thickness=1

	local profile=make("Frame",statusFrame,"Profile") :: Frame
	profile.Size=UDim2.fromOffset(56,56)
	profile.Position=UDim2.fromOffset(11,10)
	profile.BackgroundColor3=Color3.fromRGB(28,35,47)
	profile.BorderSizePixel=0
	local pc=make("UICorner",profile,"Corner") :: UICorner
	pc.CornerRadius=UDim.new(1,0)
	local initial=make("TextLabel",profile,"Initial") :: TextLabel
	initial.Size=UDim2.fromScale(1,1)
	initial.BackgroundTransparency=1
	initial.Font=Enum.Font.GothamBlack
	initial.Text=string.sub(player.DisplayName,1,1):upper()
	initial.TextColor3=Color3.fromRGB(94,205,255)
	initial.TextSize=24

	local nameLabel=make("TextLabel",statusFrame,"Name") :: TextLabel
	nameLabel.Size=UDim2.fromOffset(260,22)
	nameLabel.Position=UDim2.fromOffset(77,8)
	nameLabel.BackgroundTransparency=1
	nameLabel.Font=Enum.Font.GothamBold
	nameLabel.Text=player.DisplayName
	nameLabel.TextColor3=Color3.fromRGB(244,247,252)
	nameLabel.TextSize=16

	local role=make("TextLabel",statusFrame,"Role") :: TextLabel
	role.Size=UDim2.fromOffset(260,16)
	role.Position=UDim2.fromOffset(77,28)
	role.BackgroundTransparency=1
	role.Font=Enum.Font.GothamSemibold
	role.Text="BATTLE PILOT"
	role.TextColor3=Color3.fromRGB(142,153,170)
	role.TextSize=9

	local healthBack=make("Frame",statusFrame,"HealthBackground") :: Frame
	healthBack.Size=UDim2.fromOffset(262,14)
	healthBack.Position=UDim2.fromOffset(77,51)
	healthBack.BackgroundColor3=Color3.fromRGB(42,48,59)
	healthBack.BorderSizePixel=0
	local hbc=make("UICorner",healthBack,"Corner") :: UICorner
	hbc.CornerRadius=UDim.new(0,5)
	local healthFill=make("Frame",healthBack,"Fill") :: Frame
	healthFill.Size=UDim2.fromScale(1,1)
	healthFill.BackgroundColor3=Color3.fromRGB(255,96,102)
	healthFill.BorderSizePixel=0
	local hfc=make("UICorner",healthFill,"Corner") :: UICorner
	hfc.CornerRadius=UDim.new(0,5)
	local healthText=make("TextLabel",healthBack,"HealthText") :: TextLabel
	healthText.Size=UDim2.fromScale(1,1)
	healthText.BackgroundTransparency=1
	healthText.Font=Enum.Font.GothamBold
	healthText.Text="100 / 100"
	healthText.TextColor3=Color3.fromRGB(255,255,255)
	healthText.TextSize=9

	local energyBack=make("Frame",statusFrame,"EnergyBackground") :: Frame
	energyBack.Size=UDim2.fromOffset(262,9)
	energyBack.Position=UDim2.fromOffset(77,69)
	energyBack.BackgroundColor3=Color3.fromRGB(42,48,59)
	energyBack.BorderSizePixel=0
	local ebc=make("UICorner",energyBack,"Corner") :: UICorner
	ebc.CornerRadius=UDim.new(0,4)
	local energyFill=make("Frame",energyBack,"Fill") :: Frame
	energyFill.Size=UDim2.fromScale(1,1)
	energyFill.BackgroundColor3=Color3.fromRGB(84,184,255)
	energyFill.BorderSizePixel=0
	local efc=make("UICorner",energyFill,"Corner") :: UICorner
	efc.CornerRadius=UDim.new(0,4)
	local energyText=make("TextLabel",energyBack,"EnergyText") :: TextLabel
	energyText.Size=UDim2.fromScale(1,1)
	energyText.BackgroundTransparency=1
	energyText.Font=Enum.Font.GothamBold
	energyText.Text="ENERGY 100"
	energyText.TextColor3=Color3.fromRGB(235,244,255)
	energyText.TextSize=7
	energyText.TextXAlignment=Enum.TextXAlignment.Right

	local ultBack=make("Frame",statusFrame,"UltBackground") :: Frame
	ultBack.Size=UDim2.fromOffset(333,17)
	ultBack.Position=UDim2.fromOffset(11,90)
	ultBack.BackgroundColor3=Color3.fromRGB(35,38,53)
	ultBack.BorderSizePixel=0
	local ubc=make("UICorner",ultBack,"Corner") :: UICorner
	ubc.CornerRadius=UDim.new(0,6)
	local ultFill=make("Frame",ultBack,"Fill") :: Frame
	ultFill.Size=UDim2.fromScale(0,1)
	ultFill.BackgroundColor3=Color3.fromRGB(176,112,255)
	ultFill.BorderSizePixel=0
	local ufc=make("UICorner",ultFill,"Corner") :: UICorner
	ufc.CornerRadius=UDim.new(0,6)
	local ultText=make("TextLabel",ultBack,"UltText") :: TextLabel
	ultText.Size=UDim2.fromScale(1,1)
	ultText.BackgroundTransparency=1
	ultText.Font=Enum.Font.GothamBold
	ultText.Text="AWAKENING 0%"
	ultText.TextColor3=Color3.fromRGB(247,242,255)
	ultText.TextSize=9

	local quick=make("Frame",gui,"QuickInfo") :: Frame
	quick.Size=UDim2.fromOffset(355,31)
	quick.Position=UDim2.fromOffset(16,136)
	quick.BackgroundColor3=Color3.fromRGB(14,18,25)
	quick.BackgroundTransparency=.14
	quick.BorderSizePixel=0
	local qc=make("UICorner",quick,"Corner") :: UICorner
	qc.CornerRadius=UDim.new(0,9)
	local location=make("TextLabel",quick,"Location") :: TextLabel
	location.Size=UDim2.fromOffset(176,31)
	location.Position=UDim2.fromOffset(10,0)
	location.BackgroundTransparency=1
	location.Font=Enum.Font.GothamSemibold
	location.Text="ORIGIN PLAZA"
	location.TextColor3=Color3.fromRGB(148,160,177)
	location.TextSize=9

	local level=make("TextLabel",quick,"Level") :: TextLabel
	level.Size=UDim2.fromOffset(68,31)
	level.Position=UDim2.fromOffset(185,0)
	level.BackgroundTransparency=1
	level.Font=Enum.Font.GothamBold
	level.Text="LV 1"
	level.TextColor3=Color3.fromRGB(244,247,252)
	level.TextSize=9
	level.TextXAlignment=Enum.TextXAlignment.Right

	local credits=make("TextLabel",quick,"Credits") :: TextLabel
	credits.Size=UDim2.fromOffset(88,31)
	credits.Position=UDim2.fromOffset(264,0)
	credits.BackgroundTransparency=1
	credits.Font=Enum.Font.GothamBold
	credits.Text="0 C"
	credits.TextColor3=Color3.fromRGB(94,205,255)
	credits.TextSize=9
	credits.TextXAlignment=Enum.TextXAlignment.Right

	local utility=make("Frame",gui,"UtilityBar") :: Frame
	utility.Size=UDim2.fromOffset(190,40)
	utility.Position=UDim2.new(1,-206,0,16)
	utility.BackgroundColor3=Color3.fromRGB(14,18,25)
	utility.BackgroundTransparency=.10
	utility.BorderSizePixel=0
	local uc=make("UICorner",utility,"Corner") :: UICorner
	uc.CornerRadius=UDim.new(0,11)

	local mapButton=make("TextButton",utility,"MapButton") :: TextButton
	mapButton.Size=UDim2.fromOffset(70,32)
	mapButton.Position=UDim2.fromOffset(5,4)
	mapButton.BackgroundColor3=Color3.fromRGB(26,34,45)
	mapButton.BorderSizePixel=0
	mapButton.Text="MAP"
	mapButton.Font=Enum.Font.GothamBold
	mapButton.TextSize=10
	mapButton.TextColor3=Color3.fromRGB(244,247,252)
	local mbc=make("UICorner",mapButton,"Corner") :: UICorner
	mbc.CornerRadius=UDim.new(0,9)

	local menuButton=make("TextButton",utility,"MenuButton") :: TextButton
	menuButton.Size=UDim2.fromOffset(42,32)
	menuButton.Position=UDim2.fromOffset(80,4)
	menuButton.BackgroundColor3=Color3.fromRGB(26,34,45)
	menuButton.BorderSizePixel=0
	menuButton.Text="≡"
	menuButton.Font=Enum.Font.GothamBlack
	menuButton.TextSize=16
	menuButton.TextColor3=Color3.fromRGB(244,247,252)
	local menuc=make("UICorner",menuButton,"Corner") :: UICorner
	menuc.CornerRadius=UDim.new(0,9)

	local pingButton=make("TextButton",utility,"PingButton") :: TextButton
	pingButton.Size=UDim2.fromOffset(58,32)
	pingButton.Position=UDim2.fromOffset(126,4)
	pingButton.BackgroundColor3=Color3.fromRGB(26,34,45)
	pingButton.BorderSizePixel=0
	pingButton.Text="PING"
	pingButton.Font=Enum.Font.GothamBold
	pingButton.TextSize=9
	pingButton.TextColor3=Color3.fromRGB(244,247,252)
	local pingc=make("UICorner",pingButton,"Corner") :: UICorner
	pingc.CornerRadius=UDim.new(0,9)

	local hotbar=make("Frame",gui,"Hotbar") :: Frame
	hotbar.AnchorPoint=Vector2.new(.5,1)
	hotbar.Position=UDim2.new(.5,0,1,-8)
	hotbar.Size=UDim2.fromOffset(448,84)
	hotbar.BackgroundColor3=Color3.fromRGB(14,18,25)
	hotbar.BackgroundTransparency=.08
	hotbar.BorderSizePixel=0
	local hc=make("UICorner",hotbar,"Corner") :: UICorner
	hc.CornerRadius=UDim.new(0,13)
	local hs=make("UIStroke",hotbar,"Stroke") :: UIStroke
	hs.Color=Color3.fromRGB(74,89,112)
	hs.Transparency=.48
	hs.Thickness=1

	for i,data in ipairs({
		{"Light","M1","LMB"},
		{"Dash","DASH","Q"},
		{"Block","GUARD","F"},
		{"Special","SPECIAL","R"},
	}) do
		local slot=make("TextButton",hotbar,data[1]) :: TextButton
		slot.Size=UDim2.fromOffset(101,66)
		slot.Position=UDim2.fromOffset(9+(i-1)*110,9)
		slot.BackgroundColor3=Color3.fromRGB(24,30,40)
		slot.BorderSizePixel=0
		slot.AutoButtonColor=false
		slot.Text=data[2]
		slot.Font=Enum.Font.GothamBlack
		slot.TextSize=13
		slot.TextColor3=Color3.fromRGB(244,247,252)
		local s=make("UICorner",slot,"Corner") :: UICorner
		s.CornerRadius=UDim.new(0,11)
		local hint=make("TextLabel",slot,"Hint") :: TextLabel
		hint.Size=UDim2.fromOffset(35,14)
		hint.Position=UDim2.fromOffset(5,4)
		hint.BackgroundTransparency=1
		hint.Font=Enum.Font.GothamBold
		hint.Text=data[3]
		hint.TextColor3=Color3.fromRGB(137,150,168)
		hint.TextSize=8
		local cooldown=make("TextLabel",slot,"Cooldown") :: TextLabel
		cooldown.Size=UDim2.fromScale(1,1)
		cooldown.BackgroundTransparency=1
		cooldown.Font=Enum.Font.GothamBlack
		cooldown.Text=""
		cooldown.TextColor3=Color3.fromRGB(255,255,255)
		cooldown.TextSize=17
		local state=make("TextLabel",slot,"State") :: TextLabel
		state.Size=UDim2.new(1,-10,0,14)
		state.Position=UDim2.fromOffset(5,49)
		state.BackgroundTransparency=1
		state.Font=Enum.Font.GothamSemibold
		state.Text="READY"
		state.TextColor3=Color3.fromRGB(136,149,166)
		state.TextSize=7
		state.TextXAlignment=Enum.TextXAlignment.Center
	end

	local mobile=make("Frame",gui,"MobileActions") :: Frame
	mobile.Size=UDim2.fromOffset(190,250)
	mobile.Position=UDim2.new(1,-10,.5,25)
	mobile.AnchorPoint=Vector2.new(1,.5)
	mobile.BackgroundTransparency=1

	local m1=makeRound(mobile,72,UDim2.fromOffset(101,0),"M1","MobileM1")
	local guard=makeRound(mobile,66,UDim2.fromOffset(10,68),"GUARD","MobileGuard")
	local dash=makeRound(mobile,62,UDim2.fromOffset(112,82),"DASH","MobileDash")
	local special=makeRound(mobile,76,UDim2.fromOffset(42,150),"SPECIAL","MobileSpecial")
	m1:SetAttribute("TouchAction","Light")
	guard:SetAttribute("TouchAction","Block")
	dash:SetAttribute("TouchAction","Dash")
	special:SetAttribute("TouchAction","Special")

	local hints=make("Frame",gui,"ControllerHints") :: Frame
	hints.AnchorPoint=Vector2.new(.5,1)
	hints.Position=UDim2.new(.5,0,1,-100)
	hints.Size=UDim2.fromOffset(448,32)
	hints.BackgroundColor3=Color3.fromRGB(14,18,25)
	hints.BackgroundTransparency=.10
	hints.BorderSizePixel=0
	local hic=make("UICorner",hints,"Corner") :: UICorner
	hic.CornerRadius=UDim.new(0,9)
	local hintText=make("TextLabel",hints,"HintText") :: TextLabel
	hintText.Size=UDim2.fromScale(1,1)
	hintText.BackgroundTransparency=1
	hintText.Font=Enum.Font.GothamBold
	hintText.Text="R2  M1    •    B  DASH    •    L2  GUARD    •    Y  SPECIAL"
	hintText.TextColor3=Color3.fromRGB(141,153,171)
	hintText.TextSize=9

	local mapPanel=make("Frame",gui,"MapPanel") :: Frame
	mapPanel.AnchorPoint=Vector2.new(.5,.5)
	mapPanel.Position=UDim2.fromScale(.5,.5)
	mapPanel.Size=UDim2.fromOffset(420,390)
	mapPanel.BackgroundColor3=Color3.fromRGB(14,18,25)
	mapPanel.BorderSizePixel=0
	mapPanel.Visible=false
	local mpc=make("UICorner",mapPanel,"Corner") :: UICorner
	mpc.CornerRadius=UDim.new(0,14)

	local mapTitle=make("TextLabel",mapPanel,"Title") :: TextLabel
	mapTitle.Size=UDim2.fromOffset(260,30)
	mapTitle.Position=UDim2.fromOffset(18,14)
	mapTitle.BackgroundTransparency=1
	mapTitle.Font=Enum.Font.GothamBlack
	mapTitle.Text="BATTLE LINE"
	mapTitle.TextColor3=Color3.fromRGB(244,247,252)
	mapTitle.TextSize=19

	local close=make("TextButton",mapPanel,"Close") :: TextButton
	close.Size=UDim2.fromOffset(38,34)
	close.Position=UDim2.new(1,-52,0,12)
	close.BackgroundColor3=Color3.fromRGB(30,37,49)
	close.BorderSizePixel=0
	close.Text="×"
	close.TextColor3=Color3.fromRGB(244,247,252)
	close.Font=Enum.Font.GothamBlack
	close.TextSize=20
	local cc=make("UICorner",close,"Corner") :: UICorner
	cc.CornerRadius=UDim.new(0,9)

	local routeNames={{"Origin","ORIGIN PLAZA"},{"Metro","METRO ROW"},{"Core","BATTLE CORE"},{"Iron","IRON MARKET"},{"Apex","APEX YARD"}}
	for i,item in ipairs(routeNames) do
		local b=make("TextButton",mapPanel,item[1]) :: TextButton
		b.Size=UDim2.new(1,-36,0,52)
		b.Position=UDim2.fromOffset(18,65+(i-1)*58)
		b.BackgroundColor3=Color3.fromRGB(24,30,40)
		b.BorderSizePixel=0
		b.Text=item[2]
		b.Font=Enum.Font.GothamBold
		b.TextSize=11
		b.TextColor3=Color3.fromRGB(244,247,252)
		local c=make("UICorner",b,"Corner") :: UICorner
		c.CornerRadius=UDim.new(0,9)
	end

	local notice=make("Frame",gui,"Notice") :: Frame
	notice.AnchorPoint=Vector2.new(.5,0)
	notice.Position=UDim2.new(.5,0,0,20)
	notice.Size=UDim2.fromOffset(350,42)
	notice.BackgroundColor3=Color3.fromRGB(14,18,25)
	notice.BackgroundTransparency=.08
	notice.BorderSizePixel=0
	notice.Visible=false
	local nc=make("UICorner",notice,"Corner") :: UICorner
	nc.CornerRadius=UDim.new(0,11)
	local nt=make("TextLabel",notice,"Text") :: TextLabel
	nt.Size=UDim2.fromScale(1,1)
	nt.BackgroundTransparency=1
	nt.Font=Enum.Font.GothamBold
	nt.TextColor3=Color3.fromRGB(244,247,252)
	nt.TextSize=12

	local function noticeMessage(message:string,duration:number)
		nt.Text=message
		notice.Visible=true
		task.delay(duration,function() if nt.Parent and nt.Text==message then notice.Visible=false end end)
	end

	local function send(action:string)
		local event=remotes and remotes:FindFirstChild("CombatRequest")
		if event and event:IsA("RemoteEvent") then event:FireServer(action) end
	end
	local blockHeld=false

	hotbar.Light.Activated:Connect(function() send("Light") end)
	hotbar.Dash.Activated:Connect(function() send("Dash") end)
	hotbar.Special.Activated:Connect(function() send("Special") end)
	hotbar.Block.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonL2 then
			if not blockHeld then blockHeld=true;send("BlockStart") end
		end
	end)
	hotbar.Block.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonL2 then
			blockHeld=false
			send("BlockEnd")
		end
	end)

	for _,b in ipairs({m1,dash,special}) do
		b.Activated:Connect(function()
			local action=b:GetAttribute("TouchAction")
			if action and typeof(action)=="string" then send(action) end
		end)
	end
	guard.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
			if not blockHeld then blockHeld=true;send("BlockStart") end
		end
	end)
	guard.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
			blockHeld=false
			send("BlockEnd")
		end
	end)

	mapButton.Activated:Connect(function() mapPanel.Visible=not mapPanel.Visible end)
	menuButton.Activated:Connect(function() mapPanel.Visible=false;noticeMessage("MENU",.7) end)
	pingButton.Activated:Connect(function() noticeMessage("PING",.7) end)
	close.Activated:Connect(function() mapPanel.Visible=false end)
	for _,item in ipairs(routeNames) do
		local button=mapPanel:FindFirstChild(item[1])
		if button and button:IsA("TextButton") then
			button.Activated:Connect(function()
				local event=remotes and remotes:FindFirstChild("MapTravelRequest")
				if event and event:IsA("RemoteEvent") then event:FireServer(item[1]) end
				mapPanel.Visible=false
			end)
		end
	end

	UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 then send("Light")
		elseif input.KeyCode==Enum.KeyCode.Q then send("Dash")
		elseif input.KeyCode==Enum.KeyCode.F then
			blockHeld=true
			send("BlockStart")
		elseif input.KeyCode==Enum.KeyCode.R then send("Special")
		elseif input.KeyCode==Enum.KeyCode.M then mapPanel.Visible=not mapPanel.Visible
		end
	end)
	UserInputService.InputEnded:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode==Enum.KeyCode.F then
			blockHeld=false
			send("BlockEnd")
		end
	end)

	local function updateHealth()
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
		healthFill.Size=UDim2.new(ratio,0,1,0)
		healthText.Text=("%d / %d"):format(math.floor(humanoid.Health),math.floor(humanoid.MaxHealth))
	end
	local function updateState()
		local energy=math.clamp(tonumber(player:GetAttribute("Energy")) or 100,0,math.max(1,tonumber(player:GetAttribute("MaxEnergy")) or 100))
		local maxEnergy=math.max(1,tonumber(player:GetAttribute("MaxEnergy")) or 100)
		energyFill.Size=UDim2.new(energy/maxEnergy,0,1,0)
		energyText.Text=("ENERGY %d"):format(math.floor(energy))
		local over=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
		ultFill.Size=UDim2.new(over/100,0,1,0)
		ultText.Text=over>=100 and "AWAKENING READY  •  G" or ("AWAKENING %d%%"):format(math.floor(over))
		quick.Level.Text=("LV %d"):format(tonumber(player:GetAttribute("Level")) or 1)
		local stats=player:FindFirstChild("leaderstats")
		local credit=stats and stats:FindFirstChild("Credits")
		quick.Credits.Text=("%d C"):format(credit and credit:IsA("IntValue") and credit.Value or 0)
		local routes=require(ReplicatedStorage.Shared.MapDefinitions)
		local node=routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
		quick.Location.Text=node and node.Name or "ORIGIN PLAZA"
	end

	player.CharacterAdded:Connect(function(c)
		local h=c:WaitForChild("Humanoid",8)
		if h and h:IsA("Humanoid") then h.HealthChanged:Connect(updateHealth) end
		updateHealth()
	end)

	for _,name in ipairs({"Energy","MaxEnergy","Overdrive","Level","CurrentMapNode"}) do
		player:GetAttributeChangedSignal(name):Connect(updateState)
	end
	local stats=player:WaitForChild("leaderstats",20)
	if stats then
		local credit=stats:FindFirstChild("Credits")
		if credit and credit:IsA("IntValue") then credit:GetPropertyChangedSignal("Value"):Connect(updateState) end
	end

	setPlatform=function()
		local preferred=UserInputService.PreferredInput
		local touch=preferred==Enum.PreferredInput.Touch
		local gamepad=preferred==Enum.PreferredInput.Gamepad or preferred==Enum.PreferredInput.MicroGamepad
		hotbar.Visible=not touch
		mobile.Visible=touch
		hints.Visible=gamepad
		if gamepad then
			GuiService.GuiNavigationEnabled=true
			local first=hotbar:FindFirstChild("Light")
			if first and first:IsA("GuiButton") then GuiService.SelectedObject=first end
		else
			GuiService.GuiNavigationEnabled=false
		end
	end
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(setPlatform)
	setPlatform()
	updateHealth()
	updateState()
	gui:SetAttribute("HUDRuntimeReady",true)
	player:SetAttribute("HUDRuntimeReady",true)
	return gui
end

local function hudReady():boolean
	local gui=playerGui:FindFirstChild("CollisionHUD")
	if not gui or not gui:IsA("ScreenGui") then return false end
	if gui:GetAttribute("HUDLayoutReady")~=true or gui:GetAttribute("HUDRuntimeReady")~=true then return false end
	local statusFrame=gui:FindFirstChild("StatusFrame")
	local hotbar=gui:FindFirstChild("Hotbar")
	local mobile=gui:FindFirstChild("MobileActions")
	return statusFrame~=nil and hotbar~=nil and mobile~=nil
end

local function mapReady():boolean
	local world=workspace:FindFirstChild("CollisionBattlestarWorld")
	local map=world and world:FindFirstChild("Map")
	local spawns=world and world:FindFirstChild("Spawns")
	if not world or not map or not spawns then return false end
	if workspace:GetAttribute("CollisionBattlestarMapReady")~=true then return false end
	local required={"Origin_Plaza","Metro_Plaza","Core_Plaza","Iron_Plaza","Apex_Plaza"}
	local count=0
	for _,name in ipairs(required) do if map:FindFirstChild(name) then count+=1 end end
	local spawnCount=0
	for _,item in ipairs(spawns:GetChildren()) do if item:IsA("SpawnLocation") then spawnCount+=1 end end
	return count==5 and spawnCount>=5
end

local function coreReady():boolean
	return ReplicatedStorage:FindFirstChild("Shared")~=nil and remotes~=nil
end

local function playerReady():boolean
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	return humanoid~=nil and root~=nil and humanoid.Health>0
end

local function requestRecovery()
	if bootRequest and bootRequest:IsA("RemoteEvent") then
		pcall(function() bootRequest:FireServer("Recovery") end)
	end
end

local okHUD,hudResult=pcall(createHUD)
if not okHUD or not hudResult then
	stage.Text="HUD RECOVERY"
	status.Text="Reconstrução local do HUD..."
end

if bootFeedback and bootFeedback:IsA("RemoteEvent") then
	bootFeedback.OnClientEvent:Connect(function(kind:string,value:any)
		if kind=="Retry" then
			stage.Text="SERVER RECOVERY"
			status.Text=tostring(value or "Servidor recuperando...")
		elseif kind=="Ready" then
			stage.Text="VERIFYING"
			status.Text="Servidor pronto; validando cliente..."
		end
	end)
end

task.defer(requestRecovery)

local start=os.clock()
local lastRecovery=0
local recoveryAttempts=0
local ready=false

while boot.Parent and not ready do
	if not hudReady() then
		local success=hudResult~=nil
		if not success or os.clock()-lastRecovery>.5 then
			lastRecovery=os.clock()
			local rebuilt=pcall(createHUD)
			recoveryAttempts+=1
			if recoveryAttempts>12 then
				status.Text="HUD recuperado/recriando..."
			else
				status.Text="Reconstruindo interface..."
			end
			if rebuilt then hudResult=playerGui:FindFirstChild("CollisionHUD") end
		end
	end

	local checks={
		coreReady(),
		workspace:GetAttribute("CollisionBattlestarReady")==true,
		mapReady(),
		hudReady(),
		playerReady(),
	}
	local done=0
	for _,value in ipairs(checks) do if value then done+=1 end end
	setBoot(done,5)

	if not checks[1] then
		stage.Text="CORE"
		status.Text="Aguardando o núcleo do servidor..."
	elseif not checks[2] then
		stage.Text="WORLD"
		status.Text="Servidor verificando o mapa..."
		if os.clock()-lastRecovery>2 then lastRecovery=os.clock();requestRecovery() end
	elseif not checks[3] then
		stage.Text="MAP"
		status.Text="Verificando os cinco distritos..."
		if os.clock()-lastRecovery>2 then lastRecovery=os.clock();requestRecovery() end
	elseif not checks[4] then
		stage.Text="HUD"
		status.Text="Verificando a interface..."
	elseif not checks[5] then
		stage.Text="PLAYER"
		status.Text="Preparando o personagem..."
	else
		stage.Text="READY"
		status.Text="Todos os sistemas carregados."
		ready=true
		break
	end

	if os.clock()-start>18 then
		stage.Text="RECOVERY"
		status.Text="Recuperação automática..."
		if os.clock()-lastRecovery>1 then
			lastRecovery=os.clock()
			requestRecovery()
		end
	end
	task.wait(.15)
end

if ready then
	task.wait(.15)
	local fade=TweenService:Create(background,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1})
	fade:Play()
	task.wait(.22)
	if boot.Parent then boot:Destroy() end
end
