--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")

local Config=require(ReplicatedStorage.Shared.Config)
local Theme=require(ReplicatedStorage.Shared.HUDTheme)
local Definitions=require(ReplicatedStorage.Shared.CombatDefinitions)

local M={}

local function corner(parent:Instance,radius:number)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,radius)
	c.Parent=parent
	return c
end

local function stroke(parent:Instance,color:Color3,transparency:number,thickness:number)
	local s=Instance.new("UIStroke")
	s.Color=color
	s.Transparency=transparency
	s.Thickness=thickness
	s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	s.Parent=parent
	return s
end

local function frame(name:string,size:UDim2,pos:UDim2,parent:Instance,color:Color3,transparency:number,radius:number)
	local f=Instance.new("Frame")
	f.Name=name
	f.Size=size
	f.Position=pos
	f.BackgroundColor3=color
	f.BackgroundTransparency=transparency
	f.BorderSizePixel=0
	f.Parent=parent
	corner(f,radius)
	return f
end

local function text(name:string,value:string,size:UDim2,pos:UDim2,parent:Instance,textSize:number,color:Color3,font:Enum.Font,align:Enum.TextXAlignment?)
	local l=Instance.new("TextLabel")
	l.Name=name
	l.Text=value
	l.Size=size
	l.Position=pos
	l.BackgroundTransparency=1
	l.Font=font
	l.TextSize=textSize
	l.TextColor3=color
	l.TextXAlignment=align or Enum.TextXAlignment.Left
	l.TextYAlignment=Enum.TextYAlignment.Center
	l.Parent=parent
	return l
end

local function button(name:string,value:string,size:UDim2,pos:UDim2,parent:Instance)
	local b=Instance.new("TextButton")
	b.Name=name
	b.Text=value
	b.Size=size
	b.Position=pos
	b.BackgroundColor3=Config.UI.PanelAlt
	b.BackgroundTransparency=.03
	b.BorderSizePixel=0
	b.AutoButtonColor=false
	b.Font=Theme.FontBold
	b.TextSize=13
	b.TextColor3=Config.UI.Text
	b.Selectable=true
	b.Parent=parent
	corner(b,12)
	stroke(b,Theme.Stroke,.5,1)
	local scale=Instance.new("UIScale")
	scale.Parent=b
	return b
end

local function meter(name:string,size:UDim2,pos:UDim2,parent:Instance,fillColor:Color3,radius:number)
	local back=frame(name,size,pos,parent,Color3.fromRGB(35,40,49),0,radius)
	local fill=frame("Fill",UDim2.fromScale(0,1),UDim2.fromScale(0,0),back,fillColor,0,radius)
	return back,fill
end

function M.Build():ScreenGui
	local old=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CollisionHUD")
	if old then old:Destroy() end

	local gui=Instance.new("ScreenGui")
	gui.Name="CollisionHUD"
	gui.ResetOnSpawn=false
	gui.IgnoreGuiInset=false
	gui.DisplayOrder=25
	gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
	gui:SetAttribute("HUDVersion","3.0")
	gui:SetAttribute("ManagedByFallback",true)

	local scale=Instance.new("UIScale")
	scale.Name="ResponsiveScale"
	scale.Parent=gui

	local status=frame("StatusFrame",UDim2.fromOffset(368,124),UDim2.fromOffset(16,16),gui,Config.UI.Panel,.10,14)
	stroke(status,Theme.Stroke,.58,1)

	local profile=frame("Profile",UDim2.fromOffset(62,62),UDim2.fromOffset(12,14),status,Config.UI.PanelSoft,.02,31)
	text("Initial","?",UDim2.fromScale(1,1),UDim2.fromScale(0,0),profile,24,Config.UI.Accent,Theme.FontBold,Enum.TextXAlignment.Center)

	text("Name","PLAYER",UDim2.fromOffset(245,22),UDim2.fromOffset(82,9),status,17,Config.UI.Text,Theme.FontBold)
	text("Role","BATTLE PILOT",UDim2.fromOffset(245,17),UDim2.fromOffset(82,30),status,10,Config.UI.Muted,Theme.FontSemi)

	local hpBack,hpFill=meter("HealthBackground",UDim2.fromOffset(262,17),UDim2.fromOffset(82,54),status,Config.UI.Danger,6)
	text("HealthText","100 / 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),hpBack,10,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)

	local energyBack,energyFill=meter("EnergyBackground",UDim2.fromOffset(262,10),UDim2.fromOffset(82,76),status,Config.UI.Accent,5)
	text("EnergyText","ENERGY 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),energyBack,8,Config.UI.Text,Theme.FontSemi,Enum.TextXAlignment.Right)

	local ultBack,ultFill=meter("UltBackground",UDim2.fromOffset(342,17),UDim2.fromOffset(12,96),status,Config.UI.Accent2,6)
	stroke(ultBack,Config.UI.Accent2,.30,1)
	text("UltText","AWAKENING 0%",UDim2.fromScale(1,1),UDim2.fromScale(0,0),ultBack,9,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)

	local quick=frame("QuickInfo",UDim2.fromOffset(368,34),UDim2.fromOffset(16,146),gui,Config.UI.Panel,.12,10)
	text("Location","ORIGIN PLAZA",UDim2.fromOffset(175,34),UDim2.fromOffset(11,0),quick,10,Config.UI.Muted,Theme.FontSemi)
	text("Level","LV 1",UDim2.fromOffset(70,34),UDim2.fromOffset(184,0),quick,10,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)
	text("Credits","0 C",UDim2.fromOffset(88,34),UDim2.fromOffset(270,0),quick,10,Config.UI.Accent,Theme.FontBold,Enum.TextXAlignment.Right)

	local utility=frame("UtilityBar",UDim2.fromOffset(190,42),UDim2.new(1,-208,0,16),gui,Config.UI.Panel,.10,12)
	stroke(utility,Theme.Stroke,.58,1)
	local mapButton=button("MapButton","MAP",UDim2.fromOffset(76,34),UDim2.fromOffset(6,4),utility)
	local menuButton=button("MenuButton","≡",UDim2.fromOffset(44,34),UDim2.fromOffset(88,4),utility)
	local pingButton=button("PingButton","PING",UDim2.fromOffset(46,34),UDim2.fromOffset(138,4),utility)

	local toast=frame("Notice",UDim2.fromOffset(360,44),UDim2.new(.5,0,0,20),gui,Config.UI.Panel,.07,12)
	toast.AnchorPoint=Vector2.new(.5,0)
	toast.Visible=false
	text("Text","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),toast,13,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)

	local centerState=frame("CenterState",UDim2.fromOffset(210,42),UDim2.new(.5,0,.18,0),gui,Config.UI.Panel,.16,11)
	centerState.AnchorPoint=Vector2.new(.5,0)
	text("Combo","COMBO 0",UDim2.fromScale(1,.55),UDim2.fromScale(0,0),centerState,14,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)
	text("Mode","FREE BATTLE",UDim2.fromScale(1,.45),UDim2.fromScale(0,.53),centerState,9,Config.UI.Muted,Theme.FontSemi,Enum.TextXAlignment.Center)

	local hotbar=frame("Hotbar",UDim2.fromOffset(450,92),UDim2.new(.5,0,1,-6),gui,Config.UI.Panel,.09,14)
	hotbar.AnchorPoint=Vector2.new(.5,1)
	stroke(hotbar,Theme.Stroke,.58,1)

	local slotNames={"Light","Dash","Block","Special"}
	local slotLabels={"M1","DASH","GUARD","SPECIAL"}
	local slotHints={"LMB","Q","F","R"}
	for i,name in ipairs(slotNames) do
		local x=10+(i-1)*110
		local slot=button(name,slotLabels[i],UDim2.fromOffset(102,72),UDim2.fromOffset(x,10),hotbar)
		slot:SetAttribute("ActionId",name)
		text("Hint",slotHints[i],UDim2.fromOffset(36,14),UDim2.fromOffset(5,5),slot,9,Config.UI.Muted,Theme.FontBold)
		text("Cooldown","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),slot,17,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)
		text("State","READY",UDim2.fromOffset(88,14),UDim2.new(0,7,1,-18),slot,8,Config.UI.Muted,Theme.FontSemi,Enum.TextXAlignment.Center)
	end

	local mobile=frame("MobileActions",UDim2.fromOffset(190,252),UDim2.new(1,-14,.5,28),gui,Color3.new(0,0,0),1,0)
	mobile.AnchorPoint=Vector2.new(1,.5)

	local mobileSpec={
		{Name="MobileM1",Text="M1",X=96,Y=0,Size=72},
		{Name="MobileGuard",Text="GUARD",X=14,Y=64,Size=66},
		{Name="MobileDash",Text="DASH",X=111,Y=78,Size=62},
		{Name="MobileSpecial",Text="SPECIAL",X=40,Y=142,Size=72},
	}
	for _,info in ipairs(mobileSpec) do
		local b=button(info.Name,info.Text,UDim2.fromOffset(info.Size,info.Size),UDim2.fromOffset(info.X,info.Y),mobile)
		b:SetAttribute("TouchAction",info.Name)
		corner(b,info.Size/2)
		text("TouchBadge","",UDim2.fromOffset(20,16),UDim2.new(.5,-10,1,-20),b,8,Config.UI.Muted,Theme.FontBold,Enum.TextXAlignment.Center)
		if UserInputService.TouchEnabled then
			local icon=Instance.new("ImageLabel")
			icon.Name="TouchIcon"
			icon.BackgroundTransparency=1
			icon.Size=UDim2.fromOffset(18,18)
			icon.Position=UDim2.fromOffset(info.Size-23,6)
			icon.Image="rbxasset://textures/ui/Controls/TouchTapIcon.png"
			icon.ImageTransparency=.18
			icon.Parent=b
		end
	end

	local mobileHeader=text("Header","BATTLE CONTROLS",UDim2.fromOffset(190,22),UDim2.fromOffset(0,-26),mobile,9,Config.UI.Muted,Theme.FontBold,Enum.TextXAlignment.Right)

	local controllerHints=frame("ControllerHints",UDim2.fromOffset(450,38),UDim2.new(.5,0,1,-108),gui,Config.UI.Panel,.12,10)
	controllerHints.AnchorPoint=Vector2.new(.5,1)
	text("HintText","R2  M1     B  DASH     L2  GUARD     Y  SPECIAL",UDim2.fromScale(1,1),UDim2.fromScale(0,0),controllerHints,10,Config.UI.Muted,Theme.FontBold,Enum.TextXAlignment.Center)

	local mapPanel=frame("MapPanel",UDim2.fromOffset(420,398),UDim2.new(.5,0,.5,0),gui,Config.UI.Panel,.015,14)
	mapPanel.AnchorPoint=Vector2.new(.5,.5)
	mapPanel.Visible=false
	stroke(mapPanel,Theme.Stroke,.38,1)
	text("Title","BATTLE LINE",UDim2.fromOffset(250,30),UDim2.fromOffset(18,14),mapPanel,19,Config.UI.Text,Theme.FontBold)
	text("Sub","Five connected combat districts",UDim2.fromOffset(270,18),UDim2.fromOffset(18,44),mapPanel,10,Config.UI.Muted,Theme.FontSemi)
	local close=button("Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-56,0,12),mapPanel)
	for i,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
		local node=require(ReplicatedStorage.Shared.MapDefinitions).Nodes[id]
		local b=button(id,node.Name,UDim2.new(1,-36,0,51),UDim2.fromOffset(18,76+(i-1)*59),mapPanel)
		text("Desc",node.Subtitle,UDim2.new(1,-112,0,17),UDim2.fromOffset(12,27),b,9,Config.UI.Muted,Theme.FontSemi)
		local dot=frame("Dot",UDim2.fromOffset(9,9),UDim2.new(1,-24,0,21),b,node.Color,0,8)
		b:SetAttribute("NodeId",id)
	end

	local bindings={
		Light=Definitions.Slots[1],
		Dash=Definitions.Slots[2],
		Block=Definitions.Slots[3],
		Special=Definitions.Slots[4],
	}
	gui:SetAttribute("InputBindingsReady",bindings.Light~=nil and bindings.Dash~=nil and bindings.Block~=nil and bindings.Special~=nil)
	gui:SetAttribute("HUDLayoutReady",true)
	return gui
end

return M
