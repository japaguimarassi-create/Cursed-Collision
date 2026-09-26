--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local C=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Fighters=require(ReplicatedStorage.Shared.CharacterDefinitions)
local Catalog=require(ReplicatedStorage.Shared.StoreCatalog)

local M={}
local player=Players.LocalPlayer

local function round(parent:Instance,r:number)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r)
 c.Parent=parent
end

local function outline(parent:Instance,color:Color3,transparency:number)
 local s=Instance.new("UIStroke")
 s.Color=color;s.Transparency=transparency;s.Thickness=1
 s.Parent=parent
end

local function frame(parent:Instance,name:string,size:UDim2,pos:UDim2,color:Color3,transparency:number,r:number):Frame
 local f=Instance.new("Frame")
 f.Name=name;f.Size=size;f.Position=pos;f.BackgroundColor3=color;f.BackgroundTransparency=transparency;f.BorderSizePixel=0;f.Parent=parent
 if r>0 then round(f,r) end
 return f
end

local function label(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2,font:Enum.Font,textSize:number,color:Color3,align:Enum.TextXAlignment):TextLabel
 local t=Instance.new("TextLabel")
 t.Name=name;t.Text=value;t.Size=size;t.Position=pos;t.BackgroundTransparency=1;t.Font=font;t.TextSize=textSize;t.TextColor3=color;t.TextXAlignment=align;t.TextYAlignment=Enum.TextYAlignment.Center;t.Parent=parent
 return t
end

local function button(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2):TextButton
 local b=Instance.new("TextButton")
 b.Name=name;b.Text=value;b.Size=size;b.Position=pos;b.BackgroundColor3=C.UI.PanelAlt;b.BackgroundTransparency=.03;b.BorderSizePixel=0;b.AutoButtonColor=false;b.Font=Enum.Font.GothamBold;b.TextSize=10;b.TextColor3=C.UI.Text;b.Selectable=true;b.Parent=parent
 round(b,10);outline(b,C.UI.Muted,.76)
 return b
end

local function meter(parent:Instance,name:string,width:number,height:number,color:Color3):Frame
 local back=frame(parent,name,UDim2.fromOffset(width,height),UDim2.fromOffset(0,0),C.UI.PanelAlt,0,6)
 local fill=frame(back,"Fill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),color,0,6)
 return back
end

function M.Build():ScreenGui
 local pg=player:WaitForChild("PlayerGui")
 local old=pg:FindFirstChild("CollisionHUD")
 if old then old:Destroy() end

 local gui=Instance.new("ScreenGui")
 gui.Name="CollisionHUD";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
 gui.Enabled=true;gui.DisplayOrder=20;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui:SetAttribute("HUDVersion","4.0");gui:SetAttribute("HUDRuntimeReady",true)

 local scale=Instance.new("UIScale");scale.Name="Scale";scale.Parent=gui
 local function resize()
  local cam=workspace.CurrentCamera
  local v=cam and cam.ViewportSize or Vector2.new(1280,720)
  scale.Scale=math.clamp(math.min(v.X/1280,v.Y/720),.70,1)
 end
 resize()
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end

 local playerPanel=frame(gui,"PlayerPanel",UDim2.fromOffset(372,120),UDim2.fromOffset(14,14),C.UI.Panel,.05,15)
 outline(playerPanel,C.UI.Muted,.70)
 local avatar=frame(playerPanel,"Avatar",UDim2.fromOffset(58,58),UDim2.fromOffset(10,10),C.UI.PanelSoft,0,29)
 local avatarImage=Instance.new("ImageLabel");avatarImage.Name="AvatarImage";avatarImage.Size=UDim2.fromScale(1,1);avatarImage.BackgroundTransparency=1;avatarImage.Parent=avatar;round(avatarImage,29)
 task.spawn(function()
  local ok,url=pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
  if ok and avatarImage.Parent then avatarImage.Image=url end
 end)
 label(playerPanel,"Name",player.DisplayName,UDim2.fromOffset(285,24),UDim2.fromOffset(78,8),Enum.Font.GothamBlack,17,C.UI.Text,Enum.TextXAlignment.Left)
 label(playerPanel,"Character","YUJI  •  RIVAL",UDim2.fromOffset(285,18),UDim2.fromOffset(78,30),Enum.Font.GothamBold,9,C.UI.Muted,Enum.TextXAlignment.Left)
 local hp=meter(playerPanel,"Health",278,16,C.UI.Danger);hp.Position=UDim2.fromOffset(78,52)
 label(hp,"Value","100 / 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,9,C.UI.Text,Enum.TextXAlignment.Center)
 local energy=meter(playerPanel,"Energy",278,9,C.UI.Accent);energy.Position=UDim2.fromOffset(78,73)
 label(energy,"Value","CE 100",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBold,7,C.UI.Text,Enum.TextXAlignment.Right)
 local over=meter(playerPanel,"Awakening",348,14,C.UI.Accent2);over.Position=UDim2.fromOffset(10,98)
 label(over,"Value","AWAKENING 0%",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBlack,8,C.UI.Text,Enum.TextXAlignment.Center)

 local utility=frame(gui,"Utility",UDim2.fromOffset(350,42),UDim2.new(1,-364,0,14),C.UI.Panel,.05,12)
 outline(utility,C.UI.Muted,.72)
 local utilityNames={{"ShopButton","MARKET"},{"MapButton","MAP"},{"FighterButton","FIGHTERS"},{"MenuButton","MENU"}}
 for i,item in ipairs(utilityNames) do
  local b=button(utility,item[1],item[2],UDim2.fromOffset(80,34),UDim2.fromOffset(5+(i-1)*86,4))
  b.TextSize=8
 end

 local badge=frame(gui,"CombatBadge",UDim2.fromOffset(250,50),UDim2.new(.5,-125,0,16),C.UI.Panel,.18,12)
 label(badge,"Combo","COMBO 0",UDim2.fromScale(1,.58),UDim2.fromScale(0,0),Enum.Font.GothamBlack,14,C.UI.Text,Enum.TextXAlignment.Center)
 label(badge,"State","FREE BATTLE  •  SERVER VERIFIED",UDim2.fromScale(1,.42),UDim2.fromScale(0,.55),Enum.Font.GothamBold,7,C.UI.Muted,Enum.TextXAlignment.Center)

 local location=frame(gui,"Location",UDim2.fromOffset(390,30),UDim2.fromOffset(14,142),C.UI.Panel,.14,9)
 label(location,"Text","ORIGIN PLAZA  •  LV 1",UDim2.fromScale(1,1),UDim2.fromOffset(10,0),Enum.Font.GothamBold,9,C.UI.Text,Enum.TextXAlignment.Left)

 local hotbar=frame(gui,"Hotbar",UDim2.fromOffset(510,96),UDim2.new(.5,-255,1,-8),C.UI.Panel,.04,14)
 hotbar.AnchorPoint=Vector2.new(.5,1);hotbar.Visible=not UserInputService.TouchEnabled;outline(hotbar,C.UI.Muted,.70)
 local slots={{"Light","M1","LMB"},{"Dash","DASH","Q"},{"Block","GUARD","F"},{"Special","SPECIAL","R"}}
 for i,s in ipairs(slots) do
  local b=button(hotbar,s[1],s[2],UDim2.fromOffset(112,72),UDim2.fromOffset(9+(i-1)*124,10))
  label(b,"Hint",s[3],UDim2.fromOffset(35,14),UDim2.fromOffset(7,5),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Left)
  label(b,"Cooldown","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBlack,18,C.UI.Text,Enum.TextXAlignment.Center)
  label(b,"State","READY",UDim2.new(1,-10,0,14),UDim2.fromOffset(5,54),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Center)
 end
 label(hotbar,"SystemHint","G  AWAKEN   •   T  DOMAIN",UDim2.fromOffset(470,15),UDim2.fromOffset(20,-17),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Center)

 local mobile=frame(gui,"MobileActions",UDim2.fromOffset(210,330),UDim2.new(1,-8,.55,0),Color3.new(),1,0)
 mobile.AnchorPoint=Vector2.new(1,.5)
 label(mobile,"Label","BATTLE",UDim2.fromOffset(210,20),UDim2.fromOffset(0,-24),Enum.Font.GothamBlack,9,C.UI.Muted,Enum.TextXAlignment.Right)
 for _,s in ipairs({{"MobileM1","M1",78,112,0},{"MobileGuard","GUARD",68,8,76},{"MobileDash","DASH",68,123,86},{"MobileSpecial","SPECIAL",76,52,164},{"MobileAwaken","AWAKEN",72,12,244},{"MobileDomain","DOMAIN",72,132,235}}) do
  local b=button(mobile,s[1],s[2],UDim2.fromOffset(s[3],s[3]),UDim2.fromOffset(s[4],s[5]));round(b,s[3]/2);b.TextSize=9
 end
 mobile.Visible=false

 local function modal(name:string,size:UDim2):Frame
  local p=frame(gui,name,size,UDim2.fromScale(.5,.5),C.UI.Panel,.01,16);p.AnchorPoint=Vector2.new(.5,.5);p.Visible=false;p.ZIndex=50;outline(p,C.UI.Muted,.55);return p
 end

 local map=modal("MapPanel",UDim2.fromOffset(480,440))
 label(map,"Title","BATTLE LINE",UDim2.fromOffset(300,34),UDim2.fromOffset(20,14),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
 label(map,"Subtitle","Connected city districts • no queue teleport",UDim2.fromOffset(390,20),UDim2.fromOffset(20,44),Enum.Font.Gotham,9,C.UI.Muted,Enum.TextXAlignment.Left)
 button(map,"Close","×",UDim2.fromOffset(40,36),UDim2.new(1,-56,0,11))
 for i,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
  local node=Routes.Nodes[id]
  local b=button(map,id,node.Name,UDim2.new(1,-40,0,55),UDim2.fromOffset(20,76+(i-1)*66))
  label(b,"Sub",node.Subtitle,UDim2.new(1,-18,0,18),UDim2.fromOffset(10,31),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
  b:SetAttribute("NodeId",id)
 end

 local shop=modal("ShopPanel",UDim2.fromScale(.90,.80))
 label(shop,"Title","BATTLE MARKET",UDim2.fromOffset(360,34),UDim2.fromOffset(20,14),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
 label(shop,"Sub","Cosmetics, emotes and credit packs",UDim2.fromOffset(390,20),UDim2.fromOffset(20,44),Enum.Font.Gotham,9,C.UI.Muted,Enum.TextXAlignment.Left)
 button(shop,"Close","×",UDim2.fromOffset(40,36),UDim2.new(1,-56,0,11))
 label(shop,"Credits","0 C",UDim2.fromOffset(150,28),UDim2.new(1,-176,0,18),Enum.Font.GothamBlack,14,C.UI.Accent,Enum.TextXAlignment.Right)
 local tabs=frame(shop,"Tabs",UDim2.fromOffset(510,40),UDim2.fromOffset(20,74),Color3.new(),1,0)
 for i,t in ipairs({"Featured","Emotes","Robux"}) do local b=button(tabs,"Tab"..t,t,UDim2.fromOffset(158,36),UDim2.fromOffset((i-1)*170,2));b.ZIndex=54 end
 local code=frame(shop,"Code",UDim2.fromOffset(270,38),UDim2.new(1,-290,0,74),C.UI.PanelSoft,0,9);code.ZIndex=54
 local input=Instance.new("TextBox");input.Name="Input";input.Size=UDim2.new(1,-78,1,0);input.Position=UDim2.fromOffset(8,0);input.BackgroundTransparency=1;input.PlaceholderText="REDEEM CODE";input.TextColor3=C.UI.Text;input.Font=Enum.Font.GothamBold;input.TextSize=10;input.Parent=code
 local redeem=button(code,"Redeem","OK",UDim2.fromOffset(58,30),UDim2.new(1,-64,.5,-15));redeem.ZIndex=55
 local content=Instance.new("ScrollingFrame")
 content.Name="Content";content.Size=UDim2.new(1,-40,1,-128);content.Position=UDim2.fromOffset(20,120);content.BackgroundTransparency=1;content.BorderSizePixel=0;content.ScrollBarThickness=4;content.ScrollBarImageTransparency=.35;content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.CanvasSize=UDim2.new(0,0,0,0);content.ZIndex=53;content.Parent=shop

 local fighters=modal("FighterPanel",UDim2.fromScale(.92,.82))
 label(fighters,"Title","FIGHTER SELECT",UDim2.fromOffset(360,34),UDim2.fromOffset(20,14),Enum.Font.GothamBlack,23,C.UI.Text,Enum.TextXAlignment.Left)
 label(fighters,"Sub","24 fighters • data-driven combat profiles",UDim2.fromOffset(390,20),UDim2.fromOffset(20,44),Enum.Font.Gotham,9,C.UI.Muted,Enum.TextXAlignment.Left)
 button(fighters,"Close","×",UDim2.fromOffset(40,36),UDim2.new(1,-56,0,11))
 local fighterContent=Instance.new("ScrollingFrame")
 fighterContent.Name="Content";fighterContent.Size=UDim2.new(1,-40,1,-82);fighterContent.Position=UDim2.fromOffset(20,72);fighterContent.BackgroundTransparency=1;fighterContent.BorderSizePixel=0;fighterContent.ScrollBarThickness=4;fighterContent.ScrollBarImageTransparency=.35;fighterContent.AutomaticCanvasSize=Enum.AutomaticSize.Y;fighterContent.CanvasSize=UDim2.new(0,0,0,0);fighterContent.ZIndex=53;fighterContent.Parent=fighters
 local grid=Instance.new("UIGridLayout");grid.CellSize=UDim2.fromOffset(190,74);grid.CellPadding=UDim2.fromOffset(8,8);grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.Parent=fighterContent
 for i,id in ipairs(Fighters.Order) do
  local f=Fighters.Get(id)
  local b=button(fighterContent,id,f.DisplayName,UDim2.fromOffset(190,74),UDim2.fromOffset(0,0));b.LayoutOrder=i;b.ZIndex=54
  label(b,"Special",f.Special,UDim2.new(1,-16,0,17),UDim2.fromOffset(8,30),Enum.Font.GothamBold,8,C.UI.Accent,Enum.TextXAlignment.Left)
  label(b,"Domain",f.Domain,UDim2.new(1,-16,0,15),UDim2.fromOffset(8,48),Enum.Font.Gotham,7,C.UI.Muted,Enum.TextXAlignment.Left)
 end

 local quests=modal("QuestPanel",UDim2.fromOffset(520,370))
 label(quests,"Title","MISSIONS",UDim2.fromOffset(300,32),UDim2.fromOffset(20,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 button(quests,"Close","×",UDim2.fromOffset(42,36),UDim2.new(1,-58,0,11))
 for i,item in ipairs({{"Daily","DAILY • 3 KOs"},{"Weekly","WEEKLY • 25 KOs"},{"Lifetime","LIFETIME • 100 KOs"}}) do
  local row=frame(quests,item[1],UDim2.new(1,-40,0,72),UDim2.fromOffset(20,64+(i-1)*82),C.UI.PanelSoft,.02,10)
  label(row,"Name",item[2],UDim2.fromOffset(310,24),UDim2.fromOffset(12,8),Enum.Font.GothamBlack,12,C.UI.Text,Enum.TextXAlignment.Left)
  label(row,"Progress","0 / 0",UDim2.fromOffset(190,18),UDim2.fromOffset(12,38),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)
  local b=button(row,"Claim","CLAIM",UDim2.fromOffset(86,34),UDim2.new(1,-98,.5,-17));b.ZIndex=54;b:SetAttribute("MissionKind",item[1])
 end

 local profile=modal("ProfilePanel",UDim2.fromOffset(520,350))
 label(profile,"Title","PROFILE",UDim2.fromOffset(300,32),UDim2.fromOffset(20,16),Enum.Font.GothamBlack,22,C.UI.Text,Enum.TextXAlignment.Left)
 button(profile,"Close","×",UDim2.fromOffset(42,36),UDim2.new(1,-58,0,11))
 label(profile,"Stats","LEVEL 1\n0 KOs\n0 CREDITS\n0 STREAK",UDim2.fromOffset(480,190),UDim2.fromOffset(20,68),Enum.Font.GothamBlack,18,C.UI.Text,Enum.TextXAlignment.Left)
 label(profile,"Build","COLLISION BATTLESTAR  •  V4",UDim2.fromOffset(470,20),UDim2.fromOffset(20,280),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Left)

 local clash=frame(gui,"ClashPanel",UDim2.fromOffset(520,128),UDim2.new(.5,-260,0,84),C.UI.Panel,.04,110)
 clash.Visible=false;outline(clash,C.UI.Accent2,.45)
 label(clash,"Title","DOMAIN CLASH",UDim2.fromOffset(220,25),UDim2.fromOffset(15,9),Enum.Font.GothamBlack,15,C.UI.Text,Enum.TextXAlignment.Left)
 label(clash,"Score","0  •  0",UDim2.fromOffset(150,22),UDim2.new(1,-165,0,10),Enum.Font.GothamBlack,12,C.UI.Accent2,Enum.TextXAlignment.Right)
 label(clash,"Hint","FOUR UNIVERSAL CLASH MOVES",UDim2.fromOffset(300,16),UDim2.fromOffset(15,34),Enum.Font.GothamBold,7,C.UI.Muted,Enum.TextXAlignment.Left)
 for i,name in ipairs({"STRIKE","COUNTER","BREAK","FINISH"}) do
  local b=button(clash,"Clash"..i,name,UDim2.fromOffset(113,48),UDim2.fromOffset(10+(i-1)*125,61))
  b.ZIndex=113
 end

 local notice=frame(gui,"Notice",UDim2.fromOffset(420,48),UDim2.new(.5,-210,0,76),C.UI.Panel,.06,12);notice.Visible=false;notice.ZIndex=120
 label(notice,"Text","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),Enum.Font.GothamBlack,11,C.UI.Text,Enum.TextXAlignment.Center)
 outline(notice,C.UI.Muted,.65)

 local loading=frame(gui,"LoadingScreen",UDim2.fromScale(1,1),UDim2.fromScale(0,0),C.UI.Panel,.01,0);loading.ZIndex=200;loading.Active=true
 frame(loading,"Backdrop",UDim2.fromScale(1,1),UDim2.fromScale(0,0),C.UI.PanelSoft,.16,0).ZIndex=200
 label(loading,"Title","COLLISION BATTLESTAR",UDim2.fromScale(.86,.10),UDim2.fromScale(.07,.18),Enum.Font.GothamBlack,30,C.UI.Text,Enum.TextXAlignment.Center).ZIndex=202
 label(loading,"Subtitle","SYNCING BATTLE LINE",UDim2.fromScale(.86,.05),UDim2.fromScale(.07,.29),Enum.Font.GothamBold,11,C.UI.Muted,Enum.TextXAlignment.Center).ZIndex=202
 label(loading,"Status","STARTING INTERNAL AGENTS",UDim2.fromScale(.86,.055),UDim2.fromScale(.07,.38),Enum.Font.GothamBlack,13,C.UI.Accent,Enum.TextXAlignment.Center).ZIndex=202
 label(loading,"Detail","Verifying combat, HUD and world state…",UDim2.fromScale(.86,.05),UDim2.fromScale(.07,.445),Enum.Font.Gotham,10,C.UI.Muted,Enum.TextXAlignment.Center).ZIndex=202
 local track=frame(loading,"ProgressTrack",UDim2.fromScale(.62,.012),UDim2.fromScale(.19,.53),C.UI.PanelAlt,0,6);track.ZIndex=202
 frame(track,"Fill",UDim2.fromScale(.02,1),UDim2.fromScale(0,0),C.UI.Accent,0,6).ZIndex=203
 local agents=frame(loading,"Agents",UDim2.fromScale(.72,.22),UDim2.fromScale(.14,.59),Color3.new(),1,0);agents.ZIndex=202
 for i,name in ipairs({"QA","HUD","COMBAT","ASSETS"}) do
  local card=frame(agents,"Agent_"..name,UDim2.fromScale(.235,.70),UDim2.fromScale((i-1)*.25,0),C.UI.PanelAlt,.05,9);card.ZIndex=203
  frame(card,"Dot",UDim2.fromOffset(8,8),UDim2.fromOffset(10,11),C.UI.Muted,0,4).ZIndex=204
  label(card,"Name",name,UDim2.new(1,-28,0,18),UDim2.fromOffset(24,6),Enum.Font.GothamBlack,9,C.UI.Text,Enum.TextXAlignment.Left).ZIndex=204
  label(card,"State","WAIT",UDim2.new(1,-18,0,18),UDim2.fromOffset(9,31),Enum.Font.GothamBold,8,C.UI.Muted,Enum.TextXAlignment.Center).ZIndex=204
 end
 label(loading,"Footer","4 internal startup agents  •  mobile/console aware  •  safe area locked",UDim2.fromScale(.88,.04),UDim2.fromScale(.06,.91),Enum.Font.Gotham,8,C.UI.Muted,Enum.TextXAlignment.Center).ZIndex=202

 gui:SetAttribute("LoadingScreenReady",true)
 return gui
end
return M