--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Fighters=require(ReplicatedStorage.Shared.CharacterDefinitions)

local M={}
local player=Players.LocalPlayer

local function corner(parent:Instance,r:number)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r)
 c.Parent=parent
end

local function stroke(parent:Instance,color:Color3,transparency:number,thickness:number?)
 local s=Instance.new("UIStroke")
 s.Color=color
 s.Transparency=transparency
 s.Thickness=thickness or 1
 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 s.Parent=parent
end

local function frame(parent:Instance,name:string,size:UDim2,pos:UDim2,color:Color3,transparency:number,r:number):Frame
 local f=Instance.new("Frame")
 f.Name=name
 f.Size=size
 f.Position=pos
 f.BackgroundColor3=color
 f.BackgroundTransparency=transparency
 f.BorderSizePixel=0
 f.Parent=parent
 if r>0 then corner(f,r) end
 return f
end

local function text(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2,font:Enum.Font,textSize:number,color:Color3,align:Enum.TextXAlignment,wrap:boolean?):TextLabel
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
 t.TextWrapped=wrap or false
 t.Parent=parent
 return t
end

local function button(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2):TextButton
 local b=Instance.new("TextButton")
 b.Name=name
 b.Text=value
 b.Size=size
 b.Position=pos
 b.BackgroundColor3=C.UI.PanelSoft
 b.BackgroundTransparency=.04
 b.BorderSizePixel=0
 b.AutoButtonColor=false
 b.Font=Enum.Font.GothamBold
 b.TextSize=10
 b.TextColor3=C.UI.Text
 b.Selectable=true
 b.Parent=parent
 corner(b,12)
 stroke(b,C.UI.Muted,.78,1)
 return b
end

local function pill(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2):TextButton
 local b=button(parent,name,value,size,pos)
 corner(b,18)
 b.TextSize=9
 return b
end

local function meter(parent:Instance,name:string,size:UDim2,pos:UDim2,color:Color3):Frame
 local back=frame(parent,name,size,pos,C.UI.PanelAlt,.02,7)
 local fill=frame(back,"Fill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),color,0,7)
 return back
end

local function icon(parent:Instance,value:string,pos:UDim2,size:number):TextLabel
 return text(parent,"Icon",value,UDim2.fromOffset(size,size),pos,Enum.Font.GothamBlack,math.max(12,math.floor(size*.48)),C.UI.Text,Enum.TextXAlignment.Center)
end

function M.Build():ScreenGui
 local pg=player:WaitForChild("PlayerGui")
 local old=pg:FindFirstChild("CollisionHUD")
 if old then old:Destroy() end

 local gui=Instance.new("ScreenGui")
 gui.Name="CollisionHUD"
 gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=false
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
 gui.DisplayOrder=20
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui:SetAttribute("HUDVersion","5.0")
 gui:SetAttribute("HUDRuntimeReady",true)

 local scale=Instance.new("UIScale")
 scale.Name="Scale"
 scale.Parent=gui

 local function resize()
  local cam=workspace.CurrentCamera
  local v=cam and cam.ViewportSize or Vector2.new(1280,720)
  scale.Scale=math.clamp(math.min(v.X/1280,v.Y/720),.70,1)
 end

 resize()
 if workspace.CurrentCamera then
  workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
 end

 local topLeft=frame(gui,"PlayerCard",UDim2.fromOffset(330,86),UDim2.fromOffset(14,12),C.UI.Panel,.04,16)
 stroke(topLeft,C.UI.Muted,.76)
 local avatar=frame(topLeft,"Avatar",UDim2.fromOffset(54,54),UDim2.fromOffset(10,10),C.UI.PanelAlt,0,27)
 local avatarImage=Instance.new("ImageLabel")
 avatarImage.Name="AvatarImage"
 avatarImage.Size=UDim2.fromScale(1,1)
 avatarImage.BackgroundTransparency=1
 avatarImage.Parent=avatar
 corner(avatarImage,27)
 task.spawn(function()
  local ok,url=pcall(function()
   return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
  end)
  if ok and avatarImage.Parent then avatarImage.Image=url end
 end)

 text(topLeft,"Name",player.DisplayName,UDim2.fromOffset(240,22),UDim2.fromOffset(76,7),Enum.Font.GothamBlack,15,C.UI.Text,Enum.TextXAlignment.Left)
 text(topLeft,"Meta","LEVEL 1  •  RIVAL",UDim2.fromOffset(240,16),UDim2.fromOffset(76,28),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Left)
 local hp=meter(topLeft,"Health",UDim2.fromOffset(232,10),UDim2.fromOffset(76,49),C.UI.Danger)
 local hv=text(hp,"Value","100",UDim2.fromScale(1,1),"",Enum.Font.GothamBlack,7,C.UI.Text,Enum.TextXAlignment.Right)
 hv.Position=UDim2.fromOffset(-6,0)
 local xp=meter(topLeft,"Energy",UDim2.fromOffset(154,7),UDim2.fromOffset(76,64),C.UI.Accent)
 local ev=text(xp,"Value","CE 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBlack,6,C.UI.Text,Enum.TextXAlignment.Right)
 local level=text(topLeft,"Credits","0 C",UDim2.fromOffset(68,16),UDim2.fromOffset(240,58),Enum.Font.GothamBlack,8,C.UI.Gold,Enum.TextXAlignment.Right)
 level:SetAttribute("Role","Credits")

 local topCenter=frame(gui,"Objective",UDim2.fromOffset(360,58),UDim2.new(.5,-180,0,12),C.UI.Panel,.09,16)
 stroke(topCenter,C.UI.Muted,.84)
 text(topCenter,"Mode","OPEN BATTLE",UDim2.fromScale(1,.42),UDim2.fromScale(0,0),Enum.Font.GothamBlack,15,C.UI.Text,Enum.TextXAlignment.Center)
 text(topCenter,"Location","BATTLE LINE  •  ORIGIN",UDim2.fromScale(1,.30),UDim2.fromScale(0,.42),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Center)
 text(topCenter,"Status","LIVE COMBAT  •  SERVER VERIFIED",UDim2.fromScale(1,.24),UDim2.fromScale(0,.70),Enum.Font.GothamBold,6,C.UI.Success,Enum.TextXAlignment.Center)

 local topRight=frame(gui,"TopRight",UDim2.fromOffset(270,58),UDim2.new(1,-284,0,12),C.UI.Panel,.05,16)
 stroke(topRight,C.UI.Muted,.80)
 pill(topRight,"ScoreButton","KOs 0",UDim2.fromOffset(78,36),UDim2.fromOffset(8,11))
 pill(topRight,"MarketButton","MARKET",UDim2.fromOffset(78,36),UDim2.fromOffset(94,11))
 pill(topRight,"MenuButton","MENU",UDim2.fromOffset(78,36),UDim2.fromOffset(180,11))

 local signal=frame(gui,"Signal",UDim2.fromOffset(138,24),UDim2.new(1,-152,0,78),C.UI.Panel,.16,8)
 text(signal,"Ping","PING 0",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,7,C.UI.Muted,Enum.TextXAlignment.Right)

 local mission=frame(gui,"MissionChip",UDim2.fromOffset(300,50),UDim2.fromOffset(14,108),C.UI.Panel,.12,14)
 stroke(mission,C.UI.Muted,.84)
 text(mission,"Title","CURRENT MISSION",UDim2.fromOffset(190,16),UDim2.fromOffset(12,7),Enum.Font.GothamBlack,8,C.UI.Muted,Enum.TextXAlignment.Left)
 text(mission,"Value","GET 3 KOs  •  0/3",UDim2.fromOffset(260,20),UDim2.fromOffset(12,23),Enum.Font.GothamBlack,10,C.UI.Text,Enum.TextXAlignment.Left)
 local missionButton=pill(mission,"OpenMission","VIEW",UDim2.fromOffset(55,28),UDim2.new(1,-65,.5,-14))
 missionButton.TextSize=7

 local feed=frame(gui,"CombatFeed",UDim2.fromOffset(260,128),UDim2.new(1,-274,0,108),Color3.new(),1,0)
 feed.ClipsDescendants=true
 text(feed,"Header","COMBAT FEED",UDim2.fromOffset(120,16),UDim2.fromOffset(0,0),Enum.Font.GothamBlack,7,C.UI.Muted,Enum.TextXAlignment.Left)

 local actionBar=frame(gui,"ActionBar",UDim2.fromOffset(566,98),UDim2.new(.5,-283,1,-12),C.UI.Panel,.05,18)
 stroke(actionBar,C.UI.Muted,.82)
 local actions={
  {"Light","M1","ATTACK"},
  {"Dash","Q","MOVE"},
  {"Block","F","GUARD"},
  {"Special","R","SPECIAL"},
 }
 for i,a in ipairs(actions) do
  local x=8+(i-1)*139
  local b=button(actionBar,a[1],a[2],UDim2.fromOffset(128,78),UDim2.fromOffset(x,10))
  b.TextSize=17
  text(b,"Name",a[3],UDim2.fromOffset(92,14),UDim2.fromOffset(10,48),Enum.Font.GothamBlack,7,C.UI.Muted,Enum.TextXAlignment.Left)
  text(b,"Cooldown","",UDim2.fromOffset(55,18),UDim2.new(1,-63,0,8),Enum.Font.GothamBlack,10,C.UI.Text,Enum.TextXAlignment.Right)
 end
 text(actionBar,"Hint","G AWAKEN   •   T DOMAIN",UDim2.fromOffset(240,14),UDim2.new(.5,-120,0,-17),Enum.Font.GothamBlack,7,C.UI.Muted,Enum.TextXAlignment.Center)

 local power=frame(gui,"PowerActions",UDim2.fromOffset(206,82),UDim2.new(.5,298,1,-16),Color3.new(),1,0)
 local awaken=pill(power,"Awaken","AWAKEN 0%",UDim2.fromOffset(96,34),UDim2.fromOffset(0,6))
 awaken.TextSize=7
 local domain=pill(power,"Domain","DOMAIN",UDim2.fromOffset(96,34),UDim2.fromOffset(105,6))
 domain.TextSize=7

 local mobile=frame(gui,"MobileActions",UDim2.fromOffset(250,350),UDim2.new(1,-10,.58,0),Color3.new(),1,0)
 mobile.AnchorPoint=Vector2.new(1,.5)
 mobile.Visible=false
 text(mobile,"Label","BATTLE",UDim2.fromOffset(250,18),UDim2.fromOffset(0,-24),Enum.Font.GothamBlack,8,C.UI.Muted,Enum.TextXAlignment.Right)
 local mm1=button(mobile,"MobileM1","M1",UDim2.fromOffset(96,96),UDim2.new(1,-100,1,-98))
 corner(mm1,48)
 mm1.TextSize=18
 text(mm1,"Sub","ATTACK",UDim2.fromScale(1,.20),UDim2.fromScale(0,.67),Enum.Font.GothamBlack,6,C.UI.Muted,Enum.TextXAlignment.Center)
 local md=button(mobile,"MobileDash","DASH",UDim2.fromOffset(66,66),UDim2.new(1,-184,1,-176))
 corner(md,33);md.TextSize=8
 local mg=button(mobile,"MobileGuard","GUARD",UDim2.fromOffset(70,70),UDim2.new(1,-105,1,-190))
 corner(mg,35);mg.TextSize=8
 local ms=button(mobile,"MobileSpecial","SPECIAL",UDim2.fromOffset(72,72),UDim2.new(1,-182,1,-96))
 corner(ms,36);ms.TextSize=7
 local ma=button(mobile,"MobileAwaken","AWAKEN",UDim2.fromOffset(70,70),UDim2.new(1,-246,1,-174))
 corner(ma,35);ma.TextSize=7
 local mt=button(mobile,"MobileDomain","DOMAIN",UDim2.fromOffset(70,70),UDim2.new(1,-255,1,-95))
 corner(mt,35);mt.TextSize=7

 local dock=frame(gui,"QuickDock",UDim2.fromOffset(310,40),UDim2.fromOffset(14,-2),Color3.new(),1,0)
 local dockNames={{"FightersButton","FIGHTERS"},{"MapButton","MAP"},{"MissionsButton","MISSIONS"},{"ProfileButton","PROFILE"}}
 for i,item in ipairs(dockNames) do
  local b=pill(dock,item[1],item[2],UDim2.fromOffset(70,34),UDim2.fromOffset((i-1)*77,0))
  b.TextSize=7
 end

 local function modal(name:string,size:UDim2,anchor:Vector2):Frame
  local p=frame(gui,name,size,UDim2.fromScale(.5,.5),C.UI.Panel,.015,18)
  p.AnchorPoint=anchor
  p.Visible=false
  p.ZIndex=50
  stroke(p,C.UI.Muted,.68)
  return p
 end

 local menu=modal("QuickMenu",UDim2.fromOffset(420,360),Vector2.new(.5,.5))
 text(menu,"Title","CONTROL CENTER",UDim2.fromOffset(280,30),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 text(menu,"Sub","Player, loadout and world controls",UDim2.fromOffset(340,20),UDim2.fromOffset(22,46),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(menu,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 local menuItems={{"M_Fighters","FIGHTERS"},{"M_Map","MAP"},{"M_Missions","MISSIONS"},{"M_Profile","PROFILE"},{"M_Market","MARKET"},{"M_Scoreboard","PLAYERS"},{"M_Settings","SETTINGS"}}
 for i,item in ipairs(menuItems) do
  local col=(i-1)%2
  local row=math.floor((i-1)/2)
  local b=pill(menu,item[1],item[2],UDim2.fromOffset(178,48),UDim2.fromOffset(22+col*190,76+row*56))
  b.TextSize=8
 end

 local map=modal("MapPanel",UDim2.fromOffset(560,480),Vector2.new(.5,.5))
 text(map,"Title","BATTLE LINE",UDim2.fromOffset(320,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
 text(map,"Sub","Open connected city — move between districts",UDim2.fromOffset(420,20),UDim2.fromOffset(22,46),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(map,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 for i,id in ipairs(Routes.Order) do
  local n=Routes.Nodes[id]
  local b=button(map,id,n.Name,UDim2.new(1,-44,0,62),UDim2.fromOffset(22,76+(i-1)*70))
  text(b,"Subtitle",n.Subtitle,UDim2.new(1,-78,0,16),UDim2.fromOffset(12,34),Enum.Font.Gotham,7,C.UI.Muted,Enum.TextXAlignment.Left)
  text(b,"Action",">",UDim2.fromOffset(24,26),UDim2.new(1,-34,.5,-13),Enum.Font.GothamBlack,16,n.Color,Enum.TextXAlignment.Center)
 end

 local fighters=modal("FighterPanel",UDim2.fromOffset(760,520),Vector2.new(.5,.5))
 text(fighters,"Title","FIGHTER SELECT",UDim2.fromOffset(360,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
 text(fighters,"Sub","Choose a moveset — combat HUD updates automatically",UDim2.fromOffset(480,20),UDim2.fromOffset(22,46),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(fighters,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 local fc=Instance.new("ScrollingFrame")
 fc.Name="Content";fc.Size=UDim2.new(1,-44,1,-88);fc.Position=UDim2.fromOffset(22,76);fc.BackgroundTransparency=1;fc.BorderSizePixel=0;fc.ScrollBarThickness=4;fc.ScrollBarImageTransparency=.4;fc.AutomaticCanvasSize=Enum.AutomaticSize.Y;fc.CanvasSize=UDim2.new();fc.Parent=fighters
 local grid=Instance.new("UIGridLayout");grid.CellSize=UDim2.fromOffset(230,82);grid.CellPadding=UDim2.fromOffset(10,10);grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.Parent=fc
 for i,id in ipairs(Fighters.Order) do
  local f=Fighters.Get(id)
  local b=button(fc,id,f.DisplayName,UDim2.fromOffset(230,82),UDim2.fromOffset(0,0));b.LayoutOrder=i
  text(b,"Special",f.Special,UDim2.new(1,-20,0,17),UDim2.fromOffset(10,28),Enum.Font.GothamBlack,8,C.UI.Accent,Enum.TextXAlignment.Left)
  text(b,"Domain",f.Domain,UDim2.new(1,-20,0,15),UDim2.fromOffset(10,50),Enum.Font.Gotham,7,C.UI.Muted,Enum.TextXAlignment.Left)
 end

 local missions=modal("QuestPanel",UDim2.fromOffset(570,390),Vector2.new(.5,.5))
 text(missions,"Title","MISSIONS",UDim2.fromOffset(300,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 text(missions,"Sub","Complete objectives while you fight",UDim2.fromOffset(350,18),UDim2.fromOffset(22,45),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(missions,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 for i,item in ipairs({{"Daily","DAILY","3 KOs"},{"Weekly","WEEKLY","25 KOs"},{"Lifetime","LIFETIME","100 KOs"}}) do
  local row=frame(missions,item[1],UDim2.new(1,-44,0,72),UDim2.fromOffset(22,72+(i-1)*82),C.UI.PanelSoft,.02,12)
  text(row,"Name",item[2],UDim2.fromOffset(180,20),UDim2.fromOffset(12,8),Enum.Font.GothamBlack,10,C.UI.Text,Enum.TextXAlignment.Left)
  text(row,"Progress",item[3],UDim2.fromOffset(180,18),UDim2.fromOffset(12,36),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
  button(row,"Claim","CLAIM",UDim2.fromOffset(84,32),UDim2.new(1,-96,.5,-16))
 end

 local profile=modal("ProfilePanel",UDim2.fromOffset(560,390),Vector2.new(.5,.5))
 text(profile,"Title","PLAYER PROFILE",UDim2.fromOffset(300,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 button(profile,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 local stats=frame(profile,"StatsCard",UDim2.new(1,-44,0,180),UDim2.fromOffset(22,70),C.UI.PanelSoft,.01,14)
 text(stats,"Stats","LEVEL 1\n0 KOs\n0 CREDITS\n0 STREAK",UDim2.new(1,-24,1,-24),UDim2.fromOffset(12,12),Enum.Font.GothamBlack,18,C.UI.Text,Enum.TextXAlignment.Left)
 text(profile,"Build","COLLISION BATTLESTAR  •  LIVE BUILD",UDim2.fromOffset(450,18),UDim2.fromOffset(22,280),Enum.Font.Gotham,7,C.UI.Muted,Enum.TextXAlignment.Left)

 local market=modal("ShopPanel",UDim2.fromOffset(780,500),Vector2.new(.5,.5))
 text(market,"Title","BATTLE MARKET",UDim2.fromOffset(340,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
 text(market,"Sub","Skins, titles and profile cosmetics",UDim2.fromOffset(350,20),UDim2.fromOffset(22,46),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(market,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 text(market,"Credits","0 C",UDim2.fromOffset(120,26),UDim2.new(1,-155,0,18),Enum.Font.GothamBlack,13,C.UI.Gold,Enum.TextXAlignment.Right)
 local tabs=frame(market,"Tabs",UDim2.fromOffset(420,36),UDim2.fromOffset(22,74),Color3.new(),1,0)
 for i,t in ipairs({"Featured","Robux"}) do
  local b=pill(tabs,"Tab"..t,t:upper(),UDim2.fromOffset(186,32),UDim2.fromOffset((i-1)*196,2))
  b.TextSize=8
 end
 local content=Instance.new("ScrollingFrame")
 content.Name="Content";content.Size=UDim2.new(1,-44,1,-124);content.Position=UDim2.fromOffset(22,116);content.BackgroundTransparency=1;content.BorderSizePixel=0;content.ScrollBarThickness=4;content.ScrollBarImageTransparency=.4;content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.CanvasSize=UDim2.new();content.Parent=market

 local scoreboard=modal("ScoreboardPanel",UDim2.fromOffset(620,520),Vector2.new(.5,.5))
 text(scoreboard,"Title","PLAYERS",UDim2.fromOffset(260,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 text(scoreboard,"Sub","Current players in this server",UDim2.fromOffset(300,18),UDim2.fromOffset(22,45),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(scoreboard,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 local players=Instance.new("ScrollingFrame")
 players.Name="Content";players.Size=UDim2.new(1,-44,1,-78);players.Position=UDim2.fromOffset(22,70);players.BackgroundTransparency=1;players.BorderSizePixel=0;players.ScrollBarThickness=4;players.AutomaticCanvasSize=Enum.AutomaticSize.Y;players.CanvasSize=UDim2.new();players.Parent=scoreboard
 local list=Instance.new("UIListLayout");list.Padding=UDim.new(0,8);list.SortOrder=Enum.SortOrder.LayoutOrder;list.Parent=players

 local settings=modal("SettingsPanel",UDim2.fromOffset(520,360),Vector2.new(.5,.5))
 text(settings,"Title","SETTINGS",UDim2.fromOffset(260,32),UDim2.fromOffset(22,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 text(settings,"Sub","Gameplay presentation",UDim2.fromOffset(280,18),UDim2.fromOffset(22,45),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
 button(settings,"Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-52,0,14))
 for i,name in ipairs({"CAMERA FOV","SCREEN FX","DAMAGE TEXT","COMBAT FEEDBACK"}) do
  local y=76+(i-1)*58
  text(settings,"Setting"..i,name,UDim2.fromOffset(220,20),UDim2.fromOffset(22,y),Enum.Font.GothamBlack,9,C.UI.Text,Enum.TextXAlignment.Left)
  pill(settings,"Toggle"..i,"ON",UDim2.fromOffset(80,32),UDim2.new(1,-102,0,y-4))
 end

 local clash=frame(gui,"ClashPanel",UDim2.fromOffset(570,132),UDim2.new(.5,-285,0,84),C.UI.Panel,.035,18)
 clash.Visible=false
 clash.ZIndex=120
 stroke(clash,C.UI.Accent2,.52)
 text(clash,"Title","DOMAIN CLASH",UDim2.fromOffset(200,24),UDim2.fromOffset(16,9),Enum.Font.GothamBlack,15,C.UI.Text,Enum.TextXAlignment.Left)
 text(clash,"Score","0  •  0",UDim2.fromOffset(150,22),UDim2.new(1,-166,0,10),Enum.Font.GothamBlack,12,C.UI.Accent2,Enum.TextXAlignment.Right)
 text(clash,"Hint","FOUR-CHOICE CLASH",UDim2.fromOffset(220,15),UDim2.fromOffset(16,34),Enum.Font.GothamBold,7,C.UI.Muted,Enum.TextXAlignment.Left)
 for i,name in ipairs({"STRIKE","COUNTER","BREAK","FINISH"}) do
  local b=pill(clash,"Clash"..i,name,UDim2.fromOffset(126,48),UDim2.fromOffset(10+(i-1)*137,62))
  b.TextSize=7
  b.ZIndex=122
 end

 local notice=frame(gui,"Notice",UDim2.fromOffset(430,46),UDim2.new(.5,-215,0,75),C.UI.Panel,.04,14)
 notice.Visible=false
 notice.ZIndex=140
 stroke(notice,C.UI.Muted,.68)
 text(notice,"Text","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBlack,10,C.UI.Text,Enum.TextXAlignment.Center)

 local loading=frame(gui,"LoadingScreen",UDim2.fromScale(1,1),UDim2.fromScale(0,0),C.UI.Panel,.01,0)
 loading.ZIndex=200
 loading.Active=true
 text(loading,"Title","COLLISION BATTLESTAR",UDim2.fromScale(.90,.10),UDim2.fromScale(.05,.22),Enum.Font.GothamBlack,31,C.UI.Text,Enum.TextXAlignment.Center)
 text(loading,"Subtitle","ENTER THE BATTLE LINE",UDim2.fromScale(.90,.05),UDim2.fromScale(.05,.32),Enum.Font.GothamBold,10,C.UI.Muted,Enum.TextXAlignment.Center)
 text(loading,"Status","INITIALIZING",UDim2.fromScale(.90,.06),UDim2.fromScale(.05,.39),Enum.Font.GothamBlack,14,C.UI.Accent,Enum.TextXAlignment.Center)
 text(loading,"Detail","Verifying world and combat systems…",UDim2.fromScale(.90,.05),UDim2.fromScale(.05,.46),Enum.Font.Gotham,9,C.UI.Muted,Enum.TextXAlignment.Center)
 local track=frame(loading,"ProgressTrack",UDim2.fromScale(.58,.012),UDim2.fromScale(.21,.54),C.UI.PanelAlt,0,6)
 frame(track,"Fill",UDim2.fromScale(.01,1),UDim2.fromScale(0,0),C.UI.Accent,0,6)
 local cards=frame(loading,"Agents",UDim2.fromScale(.66,.16),UDim2.fromScale(.17,.60),Color3.new(),1,0)
 for i,name in ipairs({"WORLD","COMBAT","PLAYER","UI"}) do
  local card=frame(cards,"Agent_"..name,UDim2.fromScale(.235,.86),UDim2.fromScale((i-1)*.25,0),C.UI.PanelSoft,.03,10)
  frame(card,"Dot",UDim2.fromOffset(8,8),UDim2.fromOffset(10,10),C.UI.Muted,0,4)
  text(card,"Name",name,UDim2.new(1,-26,0,18),UDim2.fromOffset(23,4),Enum.Font.GothamBlack,8,C.UI.Text,Enum.TextXAlignment.Left)
  text(card,"State","WAIT",UDim2.new(1,-16,0,18),UDim2.fromOffset(8,28),Enum.Font.GothamBold,7,C.UI.Muted,Enum.TextXAlignment.Center)
 end
 text(loading,"Footer","SAFE AREA  •  TOUCH / KEYBOARD / GAMEPAD",UDim2.fromScale(.88,.04),UDim2.fromScale(.06,.89),Enum.Font.Gotham,7,C.UI.Muted,Enum.TextXAlignment.Center)
 gui:SetAttribute("LoadingScreenReady",true)
 return gui
end

return M
