--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
local C=require(script.Parent.Parent.Config)
local M={}

local function corner(parent:Instance,r:number)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,r)
	c.Parent=parent
end

local function stroke(parent:Instance,color:Color3,alpha:number)
	local s=Instance.new("UIStroke")
	s.Color=color
	s.Transparency=alpha
	s.Thickness=1
	s.Parent=parent
end

local function frame(parent:Instance,name:string,size:UDim2,pos:UDim2,color:Color3,alpha:number,r:number):Frame
	local f=Instance.new("Frame")
	f.Name=name
	f.Size=size
	f.Position=pos
	f.BackgroundColor3=color
	f.BackgroundTransparency=alpha
	f.BorderSizePixel=0
	f.Parent=parent
	if r>0 then corner(f,r) end
	return f
end

local function text(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2,font:Enum.Font,textSize:number,color:Color3,align:Enum.TextXAlignment):TextLabel
	local t=Instance.new("TextLabel")
	t.Name=name
	t.Text=value
	t.Size=size
	t.Position=pos
	t.BackgroundTransparency=1
	t.Font=font
	t.TextSize=textSize
	t.TextColor3=color
	t.TextXAlignment=align
	t.TextYAlignment=Enum.TextYAlignment.Center
	t.Parent=parent
	return t
end

local function button(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2):TextButton
	local b=Instance.new("TextButton")
	b.Name=name
	b.Text=value
	b.Size=size
	b.Position=pos
	b.BackgroundColor3=C.UI.PanelAlt
	b.BackgroundTransparency=.03
	b.BorderSizePixel=0
	b.AutoButtonColor=false
	b.Font=Enum.Font.GothamBold
	b.TextSize=11
	b.TextColor3=C.UI.Text
	b.Selectable=true
	b.Parent=parent
	corner(b,10)
	stroke(b,C.UI.Muted,.72)
	return b
end

local function meter(parent:Instance,name:string,width:number,height:number,color:Color3):Frame
	local back=frame(parent,name,UDim2.fromOffset(width,height),UDim2.fromOffset(0,0),Color3.fromRGB(37,44,56),0,6)
	local fill=frame(back,"Fill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),color,0,6)
	return back
end

function M.Build():ScreenGui
	local existing=player:WaitForChild("PlayerGui"):FindFirstChild("CollisionHUD")
	if existing then existing:Destroy() end

	local gui=Instance.new("ScreenGui")
	gui.Name="CollisionHUD"
	gui.ResetOnSpawn=false
	gui.IgnoreGuiInset=false
	gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
	gui.Enabled=true
	gui.DisplayOrder=20
	gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("HUDVersion","3.0")
	gui:SetAttribute("HUDLayoutReady",true)

	local scale=Instance.new("UIScale")
	scale.Name="Scale"
	scale.Parent=gui
	local function resize()
		local cam=workspace.CurrentCamera
		local v=cam and cam.ViewportSize or Vector2.new(1280,720)
		scale.Scale=math.clamp(math.min(v.X/1280,v.Y/720),.72,1)
	end
	resize()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end

	local topLeft=frame(gui,"PlayerPanel",UDim2.fromOffset(360,116),UDim2.fromOffset(16,16),C.UI.Panel,.08,14)
	stroke(topLeft,C.UI.Muted,.66)
	local avatar=frame(topLeft,"Avatar",UDim2.fromOffset(62,62),UDim2.fromOffset(11,11),C.UI.PanelSoft,0,31)
	local avatarImage=Instance.new("ImageLabel")
	avatarImage.Name="AvatarImage"
	avatarImage.Size=UDim2.fromScale(1,1)
	avatarImage.BackgroundTransparency=1
	avatarImage.Parent=avatar
	corner(avatarImage,31)
	task.spawn(function()
		local ok,url=pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
		end)
		if ok and avatarImage.Parent then avatarImage.Image=url end
	end)

	text(topLeft,"Name",player.DisplayName,18,UDim2.fromOffset(84,10),Enum.Font.GothamBlack,18,C.UI.Text,Enum.TextXAlignment.Left)
	text(topLeft,"Title","RIVAL • BATTLE PILOT",10,UDim2.fromOffset(84,31),Enum.Font.GothamBold,9,C.UI.Muted,Enum.TextXAlignment.Left)
	local hp=meter(topLeft,"Health",258,16,C.UI.Danger)
	hp.Position=UDim2.fromOffset(84,52)
	text(hp,"Value","100 / 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,9,C.UI.Text,Enum.TextXAlignment.Center)
	local energy=meter(topLeft,"Energy",258,9,C.UI.Accent)
	energy.Position=UDim2.fromOffset(84,73)
	text(energy,"Value","CE 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,7,C.UI.Text,Enum.TextXAlignment.Right)
	local awakening=meter(topLeft,"Awakening",334,15,C.UI.Accent2)
	awakening.Position=UDim2.fromOffset(11,94)
	text(awakening,"Value","AWAKENING 0%",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,8,C.UI.Text,Enum.TextXAlignment.Center)

	local topRight=frame(gui,"Utility",UDim2.fromOffset(280,40),UDim2.new(1,-296,0,16),C.UI.Panel,.08,11)
	stroke(topRight,C.UI.Muted,.72)
	for i,item in ipairs({{"ShopButton","SHOP"},{"MapButton","MAP"},{"PingButton","PING"},{"MenuButton","☰"}}) do
		local b=button(topRight,item[1],item[2],UDim2.fromOffset(i==4 and 42 or 72,32),UDim2.fromOffset(5+(i-1)*((i==4) and 47 or 74),4))
		b.TextSize=i==4 and 17 or 9
	end

	local center=frame(gui,"CombatState",UDim2.fromOffset(220,48),UDim2.new(.5,-110,0,18),C.UI.Panel,.22,12)
	text(center,"Combo","COMBO 0",UDim2.fromScale(1,.56),UDim2.fromScale(0,0),Enum.Font.GothamBlack,14,C.UI.Text,Enum.TextXAlignment.Center)
	text(center,"Mode","FREE BATTLE",UDim2.fromScale(1,.44),UDim2.fromScale(0,.54),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Center)

	local location=frame(gui,"Location",UDim2.fromOffset(360,30),UDim2.fromOffset(16,140),C.UI.Panel,.18,9)
	text(location,"Text","ORIGIN PLAZA  •  LV 1",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,9,C.UI.Text,Enum.TextXAlignment.Left).Position=UDim2.fromOffset(10,0)

	local hotbar=frame(gui,"Hotbar",UDim2.fromOffset(470,90),UDim2.new(.5,-235,1,-10),C.UI.Panel,.08,13)
	hotbar.AnchorPoint=Vector2.new(.5,1)
	stroke(hotbar,C.UI.Muted,.68)
	local slots={{"Light","M1","LMB"},{"Dash","DASH","Q"},{"Block","GUARD","F"},{"Special","SPECIAL","R"}}
	for i,s in ipairs(slots) do
		local b=button(hotbar,s[1],s[2],UDim2.fromOffset(106,70),UDim2.fromOffset(9+(i-1)*114,10))
		local hint=text(b,"Hint",s[3],UDim2.fromOffset(35,14),UDim2.fromOffset(5,4),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Left)
		text(b,"Cooldown","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBlack,18,C.UI.Text,Enum.TextXAlignment.Center)
		text(b,"State","READY",UDim2.new(1,-10,0,14),UDim2.fromOffset(5,52),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Center)
	end

	local mobile=frame(gui,"MobileActions",UDim2.fromOffset(190,258),UDim2.new(1,-10,.5,42),Color3.new(0,0,0),1,0)
	mobile.AnchorPoint=Vector2.new(1,.5)
	text(mobile,"Label","BATTLE",UDim2.fromOffset(190,22),UDim2.fromOffset(0,-25),Enum.Font.GothamBlack,9,C.UI.Muted,Enum.TextXAlignment.Right)
	for _,s in ipairs({{"MobileM1","M1",72,94,0},{"MobileGuard","GUARD",66,8,74},{"MobileDash","DASH",62,108,86},{"MobileSpecial","SPECIAL",76,33,158}}) do
		local b=button(mobile,s[1],s[2],UDim2.fromOffset(s[3],s[3]),UDim2.fromOffset(s[4],s[5]))
		corner(b,s[3]/2)
		b.TextSize=s[3]>70 and 10 or 9
	end

	local map=frame(gui,"MapPanel",UDim2.fromOffset(430,400),UDim2.fromScale(.5,.5),C.UI.Panel,.02,15)
	map.AnchorPoint=Vector2.new(.5,.5)
	map.Visible=false
	stroke(map,C.UI.Muted,.5)
	text(map,"Title","BATTLE LINE",UDim2.fromOffset(250,30),UDim2.fromOffset(18,14),Enum.Font.GothamBlack,20,C.UI.Text,Enum.TextXAlignment.Left)
	text(map,"Subtitle","Five connected combat districts",UDim2.fromOffset(300,20),UDim2.fromOffset(18,43),Enum.Font.Gotham,9,C.UI.Muted,Enum.TextXAlignment.Left)
	local close=button(map,"Close","×",UDim2.fromOffset(40,34),UDim2.new(1,-55,0,12))
	for i,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
		local node=require(ReplicatedStorage.Shared.MapDefinitions).Nodes[id]
		local b=button(map,id,node.Name,UDim2.new(1,-36,0,49),UDim2.fromOffset(18,76+(i-1)*60))
		local sub=text(b,"Sub",node.Subtitle,UDim2.new(1,-15,0,17),UDim2.fromOffset(10,27),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
		b:SetAttribute("NodeId",id)
	end
	close:SetAttribute("CloseMap",true)

	local shop=frame(gui,"ShopPanel",UDim2.fromScale(.86,.76),UDim2.fromScale(.5,.52),C.UI.Panel,.01,18)
	shop.AnchorPoint=Vector2.new(.5,.5)
	shop.Visible=false
	shop.ZIndex=50
	stroke(shop,C.UI.Muted,.48)
	text(shop,"Title","BATTLE MARKET",UDim2.fromOffset(360,34),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
	text(shop,"Sub","Featured gear, emotes and credits",UDim2.fromOffset(400,20),UDim2.fromOffset(22,45),Enum.Font.Gotham,10,C.UI.Muted,Enum.TextXAlignment.Left)
	local shopClose=button(shop,"Close","×",UDim2.fromOffset(42,38),UDim2.new(1,-57,0,12)); shopClose.ZIndex=53
	local tabs=frame(shop,"Tabs",UDim2.fromOffset(510,40),UDim2.fromOffset(22,74),Color3.new(),1,0)
	for i,t in ipairs({"Featured","Emotes","Robux"}) do
		local b=button(tabs,"Tab"..t,t,UDim2.fromOffset(158,36),UDim2.fromOffset((i-1)*170,2)); b.ZIndex=53
	end
	local credit=text(shop,"Credits","0 C",UDim2.fromOffset(130,30),UDim2.new(1,-170,0,18),Enum.Font.GothamBlack,14,C.UI.Accent,Enum.TextXAlignment.Right)
	local content=frame(shop,"Content",UDim2.new(1,-44,1,-128),UDim2.fromOffset(22,120),Color3.new(),1,0); content.ZIndex=52
	local code=frame(shop,"Code",UDim2.fromOffset(270,38),UDim2.new(1,-294,0,74),C.UI.PanelSoft,0,9); code.ZIndex=53
	local input=Instance.new("TextBox"); input.Name="Input"; input.Size=UDim2.new(1,-82,1,0); input.Position=UDim2.fromOffset(8,0); input.BackgroundTransparency=1; input.PlaceholderText="CODE"; input.TextColor3=C.UI.Text; input.Font=Enum.Font.GothamBold; input.TextSize=10; input.Parent=code
	local redeem=button(code,"Redeem","OK",UDim2.fromOffset(60,30),UDim2.new(1,-66,.5,-15)); redeem.ZIndex=54
	redeem:SetAttribute("CodeBox",true)

	local quests=frame(gui,"QuestPanel",UDim2.fromOffset(520,340),UDim2.fromScale(.5,.5),C.UI.Panel,.02,15); quests.AnchorPoint=Vector2.new(.5,.5); quests.Visible=false
	text(quests,"Title","MISSIONS",UDim2.fromOffset(260,32),UDim2.fromOffset(20,18),Enum.Font.GothamBlack,21,C.UI.Text,Enum.TextXAlignment.Left)
	text(quests,"Daily","DAILY  •  Score 3 KOs",UDim2.fromOffset(480,52),UDim2.fromOffset(20,70),Enum.Font.GothamBold,16,C.UI.Text,Enum.TextXAlignment.Left)
	text(quests,"Weekly","WEEKLY  •  Score 25 KOs",UDim2.fromOffset(480,52),UDim2.fromOffset(20,130),Enum.Font.GothamBold,16,C.UI.Text,Enum.TextXAlignment.Left)
	text(quests,"Reward","REWARD  •  Credits",UDim2.fromOffset(480,36),UDim2.fromOffset(20,195),Enum.Font.Gotham,11,C.UI.Muted,Enum.TextXAlignment.Left)
	local qclose=button(quests,"Close","×",UDim2.fromOffset(42,38),UDim2.new(1,-58,0,12))

	local profilePanel=frame(gui,"ProfilePanel",UDim2.fromOffset(520,340),UDim2.fromScale(.5,.5),C.UI.Panel,.02,15); profilePanel.AnchorPoint=Vector2.new(.5,.5); profilePanel.Visible=false
	text(profilePanel,"Title","PROFILE",UDim2.fromOffset(300,32),UDim2.fromOffset(20,18),Enum.Font.GothamBlack,21,C.UI.Text,Enum.TextXAlignment.Left)
	text(profilePanel,"Stats","LV 1\n0 KOs\n0 Credits",UDim2.fromOffset(480,160),UDim2.fromOffset(20,74),Enum.Font.GothamBold,18,C.UI.Text,Enum.TextXAlignment.Left)
	local pclose=button(profilePanel,"Close","×",UDim2.fromOffset(42,38),UDim2.new(1,-58,0,12))

	gui:SetAttribute("HUDRuntimeReady",true)
	return gui
end

return M
