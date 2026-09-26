--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Stats=game:GetService("Stats")
local TweenService=game:GetService("TweenService")

local C=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Fighters=require(ReplicatedStorage.Shared.CharacterDefinitions)
local Catalog=require(ReplicatedStorage.Shared.StoreCatalog)

local M={}
local player=Players.LocalPlayer
local gui:ScreenGui
local remotes
local combat:RemoteEvent
local utility:RemoteEvent
local travel:RemoteEvent
local feedback:RemoteEvent
local owned:{[string]:boolean}={}
local activeMarketTab="Featured"
local bound:{[RBXScriptConnection]:boolean}={}
local feedEntries:{string}={}

local function bind(signal:RBXScriptSignal,fn:(...any)->())
 local c=signal:Connect(fn)
 bound[c]=true
 return c
end

local function find(root:Instance?,name:string):Instance?
 return root and root:FindFirstChild(name)
end

local function label(root:Instance?,name:string):TextLabel?
 local x=find(root,name)
 return x and x:IsA("TextLabel") and x or nil
end

local function show(name:string,visible:boolean)
 local x=find(gui,name)
 if x and x:IsA("GuiObject") then x.Visible=visible end
end

local function closePanels()
 for _,name in ipairs({"QuickMenu","MapPanel","ShopPanel","FighterPanel","QuestPanel","ProfilePanel","ScoreboardPanel","SettingsPanel"}) do
  show(name,false)
 end
end

local function toast(message:string,duration:number?)
 local n=find(gui,"Notice")
 local t=label(n,"Text")
 if not n or not n:IsA("GuiObject") or not t then return end
 t.Text=message
 n.Visible=true
 task.delay(duration or 1.2,function()
  if t.Parent and t.Text==message then
   n.Visible=false
  end
 end)
end

local function clear(parent:Instance)
 for _,x in ipairs(parent:GetChildren()) do
  if not x:IsA("UIGridLayout") and not x:IsA("UIListLayout") then
   x:Destroy()
  end
 end
end

local function buttonCard(parent:Instance,name:string,title:string,desc:string,price:string,actionText:string,ownedState:boolean):TextButton
 local b=Instance.new("TextButton")
 b.Name=name
 b.Size=UDim2.fromOffset(230,108)
 b.BackgroundColor3=C.UI.PanelSoft
 b.BackgroundTransparency=.02
 b.BorderSizePixel=0
 b.AutoButtonColor=false
 b.Text=""
 b.ZIndex=54
 b.Parent=parent

 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,13)
 c.Parent=b

 local s=Instance.new("UIStroke")
 s.Color=C.UI.Muted
 s.Transparency=.80
 s.Parent=b

 local t=Instance.new("TextLabel")
 t.Name="Title"
 t.Text=title
 t.Size=UDim2.new(1,-20,0,22)
 t.Position=UDim2.fromOffset(10,8)
 t.BackgroundTransparency=1
 t.Font=Enum.Font.GothamBlack
 t.TextSize=12
 t.TextColor3=C.UI.Text
 t.TextXAlignment=Enum.TextXAlignment.Left
 t.Parent=b

 local d=Instance.new("TextLabel")
 d.Name="Desc"
 d.Text=desc
 d.Size=UDim2.new(1,-20,0,32)
 d.Position=UDim2.fromOffset(10,32)
 d.BackgroundTransparency=1
 d.Font=Enum.Font.Gotham
 d.TextSize=8
 d.TextColor3=C.UI.Muted
 d.TextWrapped=true
 d.TextXAlignment=Enum.TextXAlignment.Left
 d.TextYAlignment=Enum.TextYAlignment.Top
 d.Parent=b

 local p=Instance.new("TextLabel")
 p.Name="Price"
 p.Text=price
 p.Size=UDim2.fromOffset(100,18)
 p.Position=UDim2.fromOffset(10,82)
 p.BackgroundTransparency=1
 p.Font=Enum.Font.GothamBlack
 p.TextSize=8
 p.TextColor3=ownedState and C.UI.Success or C.UI.Gold
 p.TextXAlignment=Enum.TextXAlignment.Left
 p.Parent=b

 local a=Instance.new("TextLabel")
 a.Name="Action"
 a.Text=actionText
 a.Size=UDim2.fromOffset(82,26)
 a.Position=UDim2.new(1,-92,1,-34)
 a.BackgroundColor3=C.UI.PanelAlt
 a.BorderSizePixel=0
 a.Font=Enum.Font.GothamBlack
 a.TextSize=7
 a.TextColor3=C.UI.Text
 a.Parent=b
 local ac=Instance.new("UICorner")
 ac.CornerRadius=UDim.new(0,8)
 ac.Parent=a

 return b
end

local function addFeed(message:string)
 table.insert(feedEntries,1,message)
 while #feedEntries>4 do
  table.remove(feedEntries)
 end

 local feed=find(gui,"CombatFeed")
 if not feed or not feed:IsA("GuiObject") then return end
 for _,child in ipairs(feed:GetChildren()) do
  if child:IsA("TextLabel") and child.Name:match("^Entry") then
   child:Destroy()
  end
 end

 for i,value in ipairs(feedEntries) do
  local t=Instance.new("TextLabel")
  t.Name="Entry"..i
  t.Text=value
  t.Size=UDim2.new(1,0,0,23)
  t.Position=UDim2.fromOffset(0,18+(i-1)*25)
  t.BackgroundColor3=C.UI.Panel
  t.BackgroundTransparency=.16
  t.BorderSizePixel=0
  t.Font=Enum.Font.GothamBold
  t.TextSize=8
  t.TextColor3=i==1 and C.UI.Text or C.UI.Muted
  t.TextXAlignment=Enum.TextXAlignment.Left
  t.TextTruncate=Enum.TextTruncate.AtEnd
  t.ZIndex=31
  t.Parent=feed
  local c=Instance.new("UICorner")
  c.CornerRadius=UDim.new(0,7)
  c.Parent=t
 end
end

local function refreshHeader()
 local fighter=Fighters.Get(tostring(player:GetAttribute("EquippedCharacter") or "Yuji"))
 local playerCard=find(gui,"PlayerCard")
 local meta=label(playerCard,"Meta")
 local credits=label(playerCard,"Credits")
 if meta and fighter then
  meta.Text=("LEVEL %s  •  %s  •  %s"):format(
   tostring(player:GetAttribute("Level") or 1),
   fighter.DisplayName,
   tostring(player:GetAttribute("EquippedTitle") or "RIVAL")
  )
 end
 if credits then
  credits.Text=tostring(math.floor(tonumber(player:GetAttribute("Credits")) or 0)).." C"
 end

 local objective=find(gui,"Objective")
 local mode=label(objective,"Mode")
 local location=label(objective,"Location")
 local status=label(objective,"Status")
 local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
 if mode then mode.Text="OPEN BATTLE" end
 if location and node then location.Text="BATTLE LINE  •  "..node.Name:upper() end
 if status then
  status.Text=player:GetAttribute("Respawning")==true and "RESPAWNING" or "LIVE COMBAT  •  SERVER VERIFIED"
  status.TextColor3=player:GetAttribute("Respawning")==true and C.UI.Gold or C.UI.Success
 end

 local topScore=find(gui,"ScoreButton")
 if topScore and topScore:IsA("GuiButton") then
  topScore.Text="KOs "..tostring(player:GetAttribute("KOs") or 0)
 end

 local mission=find(gui,"MissionChip")
 local mv=label(mission,"Value")
 if mv then
  mv.Text="GET 3 KOs  •  "..tostring(player:GetAttribute("DailyKOs") or 0).."/3"
 end
end

function M:RefreshHUD()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local playerCard=find(gui,"PlayerCard")
 local hp=find(playerCard,"Health")
 local fill=find(hp,"Fill")
 local value=label(hp,"Value")

 if humanoid and fill and fill:IsA("Frame") then
  local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
  fill.Size=UDim2.fromScale(ratio,1)
  if value then
   value.Text=("%d HP"):format(math.floor(humanoid.Health+0.5))
  end
 end

 local energy=math.clamp(
  tonumber(player:GetAttribute("Energy")) or 0,
  0,
  tonumber(player:GetAttribute("MaxEnergy")) or C.Resources.MaxEnergy
 )
 local energyBar=find(playerCard,"Energy")
 local energyFill=find(energyBar,"Fill")
 local energyValue=label(energyBar,"Value")
 if energyFill and energyFill:IsA("Frame") then
  energyFill.Size=UDim2.fromScale(energy/100,1)
 end
 if energyValue then
  energyValue.Text="CE "..math.floor(energy)
 end

 local over=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
 local awaken=find(gui,"Awaken")
 if awaken and awaken:IsA("GuiButton") then
  awaken.Text=player:GetAttribute("AwakeningActive")==true and "AWAKENING" or ("AWAKEN "..math.floor(over).."%")
 end

 local domain=find(gui,"Domain")
 if domain and domain:IsA("GuiButton") then
  domain.Text="DOMAIN"
 end

 local clash=find(gui,"ClashPanel")
 if clash and clash:IsA("GuiObject") then
  clash.Visible=(tonumber(player:GetAttribute("DomainClash")) or 0)>0
  local score=label(clash,"Score")
  if score then
   score.Text=tostring(player:GetAttribute("ClashScore") or 0).."  •  CLASH"
  end
 end

 refreshHeader()
 self:RefreshCooldowns()
 self:RefreshPing()
end

function M:RefreshCooldowns()
 local actionBar=find(gui,"ActionBar")
 local actionMap={{"Light","NextLight"},{"Dash","NextDash"},{"Block","Blocking"},{"Special","NextSpecial"}}
 for _,pair in ipairs(actionMap) do
  local b=find(actionBar,pair[1])
  local cd=label(b,"Cooldown")
  local state=label(b,"Name")
  if pair[1]=="Block" then
   if state then
    state.Text=player:GetAttribute("Blocking")==true and "GUARDING" or "GUARD"
    state.TextColor3=player:GetAttribute("Blocking")==true and C.UI.Success or C.UI.Muted
   end
  else
   local remain=math.max(0,(tonumber(player:GetAttribute(pair[2])) or 0)-os.clock())
   if cd then cd.Text=remain>.03 and ("%.1f"):format(remain) or "READY" end
   if state then
    state.Text=pair[1]=="Light" and "ATTACK" or pair[1]=="Dash" and "MOVE" or pair[1]=="Special" and "SPECIAL" or state.Text
   end
  end
 end

 local power=find(gui,"PowerActions")
 local awaken=power and find(power,"Awaken")
 local domain=power and find(power,"Domain")
 if awaken and awaken:IsA("GuiButton") then
  local over=math.floor(math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100))
  awaken.Text=player:GetAttribute("AwakeningActive")==true and "AWAKENING" or ("AWAKEN "..over.."%")
 end
 if domain and domain:IsA("GuiButton") then
  local remain=math.max(0,(tonumber(player:GetAttribute("NextDomain")) or 0)-os.clock())
  domain.Text=remain>.03 and ("DOMAIN "..("%.0f"):format(remain)) or "DOMAIN"
 end

 local mobile=find(gui,"MobileActions")
 if mobile and mobile.Visible then
  local function mobileCooldown(name:string,attribute:string,prefix:string)
   local b=find(mobile,name)
   if b and b:IsA("GuiButton") then
    local remain=math.max(0,(tonumber(player:GetAttribute(attribute)) or 0)-os.clock())
    b.Text=remain>.03 and (prefix.." "..("%.1f"):format(remain)) or prefix
   end
  end
  mobileCooldown("MobileDash","NextDash","DASH")
  mobileCooldown("MobileSpecial","NextSpecial","SPECIAL")
  local ma=find(mobile,"MobileAwaken")
  if ma and ma:IsA("GuiButton") then
   ma.Text=player:GetAttribute("AwakeningActive")==true and "AWAKENING" or ("AWAKEN "..math.floor(tonumber(player:GetAttribute("Overdrive")) or 0).."%")
  end
 end
end

function M:RefreshPing()
 local signal=find(gui,"Signal")
 local p=label(signal,"Ping")
 if not p then return end
 local ok,textValue=pcall(function()
  local item=Stats.Network.ServerStatsItem["Data Ping"]
  return item:GetValueString()
 end)
 p.Text=ok and ("PING "..tostring(textValue):gsub(" ms","")) or "PING —"
end

function M:RenderShop()
 local panel=find(gui,"ShopPanel")
 local content=find(panel,"Content")
 if not panel or not content then return end
 clear(content)

 local credits=label(panel,"Credits")
 if credits then
  credits.Text=tostring(math.floor(tonumber(player:GetAttribute("Credits")) or 0)).." C"
 end

 if activeMarketTab=="Robux" then
  local note=Instance.new("TextLabel")
  note.Size=UDim2.new(1,0,0,24)
  note.BackgroundTransparency=1
  note.Text="CREDIT PACKS"
  note.Font=Enum.Font.GothamBlack
  note.TextSize=15
  note.TextColor3=C.UI.Text
  note.TextXAlignment=Enum.TextXAlignment.Left
  note.Parent=content

  for i,bundle in ipairs(Catalog.Bundles) do
   local col=(i-1)%2
   local row=math.floor((i-1)/2)
   local b=buttonCard(
    content,
    bundle.Id,
    bundle.Name,
    "Server-processed developer product.",
    tostring(bundle.Robux).." R$",
    bundle.ProductId>0 and "BUY" or "NOT LINKED",
    false
   )
   b.Position=UDim2.fromOffset(col*242,row*116+34)
  end
  return
 end

 local items={}
 for _,item in ipairs(Catalog.Items) do
  if item.Category==activeMarketTab and item.Kind~="Emote" then
   table.insert(items,item)
  end
 end

 for i,item in ipairs(items) do
  local col=(i-1)%3
  local row=math.floor((i-1)/3)
  local isOwned=owned[item.Id]==true
  local b=buttonCard(
   content,
   item.Id,
   item.Name,
   item.Description,
   tostring(item.Price).." C",
   isOwned and "EQUIP" or "UNLOCK",
   isOwned
  )
  b.Position=UDim2.fromOffset(col*238,row*116)
  b.Activated:Connect(function()
   utility:FireServer(isOwned and "EquipItem" or "BuyItem",item.Id)
  end)
 end
end

function M:RenderMissions()
 local panel=find(gui,"QuestPanel")
 if not panel then return end
 local values={
  Daily={tonumber(player:GetAttribute("DailyKOs")) or 0,C.Missions.Daily.Goal},
  Weekly={tonumber(player:GetAttribute("WeeklyKOs")) or 0,C.Missions.Weekly.Goal},
  Lifetime={tonumber(player:GetAttribute("LifetimeKOs")) or 0,C.Missions.Lifetime.Goal},
 }
 for kind,v in pairs(values) do
  local row=find(panel,kind)
  local progress=label(row,"Progress")
  if progress then
   progress.Text=tostring(v[1]).." / "..tostring(v[2]).." KOs"
  end
 end
end

function M:RefreshProfile()
 local panel=find(gui,"ProfilePanel")
 local stats=label(find(panel,"StatsCard"),"Stats")
 if not stats then return end
 stats.Text=("LEVEL %d\n%d KOs\n%d CREDITS\n%d STREAK"):format(
  tonumber(player:GetAttribute("Level")) or 1,
  tonumber(player:GetAttribute("KOs")) or 0,
  tonumber(player:GetAttribute("Credits")) or 0,
  tonumber(player:GetAttribute("Streak")) or 0
 )
end

function M:RenderScoreboard()
 local panel=find(gui,"ScoreboardPanel")
 local content=find(panel,"Content")
 if not panel or not content then return end
 clear(content)
 local players=Players:GetPlayers()
 table.sort(players,function(a,b)
  local ak=tonumber(a:GetAttribute("KOs")) or 0
  local bk=tonumber(b:GetAttribute("KOs")) or 0
  return ak>bk
 end)

 for i,target in ipairs(players) do
  local row=Instance.new("Frame")
  row.Name="PlayerRow"..target.UserId
  row.Size=UDim2.new(1,-4,0,56)
  row.BackgroundColor3=target==player and C.UI.PanelAlt or C.UI.PanelSoft
  row.BackgroundTransparency=.04
  row.BorderSizePixel=0
  row.LayoutOrder=i
  row.Parent=content

  local c=Instance.new("UICorner")
  c.CornerRadius=UDim.new(0,10)
  c.Parent=row

  local name=Instance.new("TextLabel")
  name.Size=UDim2.new(1,-160,0,20)
  name.Position=UDim2.fromOffset(12,7)
  name.BackgroundTransparency=1
  name.Text=target.DisplayName
  name.Font=Enum.Font.GothamBlack
  name.TextSize=10
  name.TextColor3=C.UI.Text
  name.TextXAlignment=Enum.TextXAlignment.Left
  name.Parent=row

  local meta=Instance.new("TextLabel")
  meta.Size=UDim2.new(1,-160,0,16)
  meta.Position=UDim2.fromOffset(12,29)
  meta.BackgroundTransparency=1
  meta.Text=("LV %d"):format(tonumber(target:GetAttribute("Level")) or 1)
  meta.Font=Enum.Font.Gotham
  meta.TextSize=7
  meta.TextColor3=C.UI.Muted
  meta.TextXAlignment=Enum.TextXAlignment.Left
  meta.Parent=row

  local score=Instance.new("TextLabel")
  score.Size=UDim2.fromOffset(125,24)
  score.Position=UDim2.new(1,-137,.5,-12)
  score.BackgroundTransparency=1
  score.Text=("KO %d"):format(tonumber(target:GetAttribute("KOs")) or 0)
  score.Font=Enum.Font.GothamBlack
  score.TextSize=10
  score.TextColor3=C.UI.Gold
  score.TextXAlignment=Enum.TextXAlignment.Right
  score.Parent=row
 end
end

function M:Open(name:string)
 closePanels()
 show(name,true)
 if name=="ShopPanel" then self:RenderShop() end
 if name=="QuestPanel" then self:RenderMissions() end
 if name=="ProfilePanel" then self:RefreshProfile() end
 if name=="ScoreboardPanel" then self:RenderScoreboard() end
end

function M:Bind(guiArg:ScreenGui,remotesArg)
 gui=guiArg
 remotes=remotesArg
 local mobile=find(gui,"MobileActions")
 if mobile and mobile:IsA("GuiObject") then
  mobile.Visible=UserInputService.TouchEnabled
 end

 combat=remotes:WaitForChild("CombatRequest") :: RemoteEvent
 utility=remotes:WaitForChild("UtilityRequest") :: RemoteEvent
 travel=remotes:WaitForChild("MapTravelRequest") :: RemoteEvent
 feedback=remotes:WaitForChild("Feedback") :: RemoteEvent

 local actionBar=find(gui,"ActionBar")
 local light=find(actionBar,"Light")
 local dash=find(actionBar,"Dash")
 local guard=find(actionBar,"Block")
 local special=find(actionBar,"Special")
 if light and light:IsA("GuiButton") then bind(light.Activated,function() combat:FireServer("Light") end) end
 if dash and dash:IsA("GuiButton") then bind(dash.Activated,function() combat:FireServer("Dash") end) end
 if special and special:IsA("GuiButton") then bind(special.Activated,function() combat:FireServer("Special") end) end
 if guard and guard:IsA("GuiButton") then
  bind(guard.MouseButton1Down,function() combat:FireServer("BlockStart") end)
  bind(guard.MouseButton1Up,function() combat:FireServer("BlockEnd") end)
 end

 local mobilePanel=find(gui,"MobileActions")
 local function bindTap(name:string,action:string)
  local b=mobilePanel and find(mobilePanel,name)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function() combat:FireServer(action) end)
  end
 end
 bindTap("MobileM1","Light")
 bindTap("MobileDash","Dash")
 bindTap("MobileSpecial","Special")
 bindTap("MobileAwaken","Awaken")
 bindTap("MobileDomain","Domain")

 local mobileGuard=mobilePanel and find(mobilePanel,"MobileGuard")
 if mobileGuard and mobileGuard:IsA("GuiButton") then
  bind(mobileGuard.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
    combat:FireServer("BlockStart")
   end
  end)
  bind(mobileGuard.InputEnded,function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
    combat:FireServer("BlockEnd")
   end
  end)
 end

 local topRight=find(gui,"TopRight")
 local scoreButton=find(topRight,"ScoreButton")
 local marketButton=find(topRight,"MarketButton")
 local menuButton=find(topRight,"MenuButton")
 if scoreButton and scoreButton:IsA("GuiButton") then bind(scoreButton.Activated,function() self:Open("ScoreboardPanel") end) end
 if marketButton and marketButton:IsA("GuiButton") then bind(marketButton.Activated,function() self:Open("ShopPanel") end) end
 if menuButton and menuButton:IsA("GuiButton") then bind(menuButton.Activated,function() self:Open("QuickMenu") end) end

 local dock=find(gui,"QuickDock")
 local dockMap={FightersButton="FighterPanel",MapButton="MapPanel",MissionsButton="QuestPanel",ProfileButton="ProfilePanel"}
 for buttonName,panelName in pairs(dockMap) do
  local b=find(dock,buttonName)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function() self:Open(panelName) end)
  end
 end

 local missionButton=find(gui,"OpenMission")
 if missionButton and missionButton:IsA("GuiButton") then
  bind(missionButton.Activated,function() self:Open("QuestPanel") end)
 end

 local power=find(gui,"PowerActions")
 local awaken=find(power,"Awaken")
 local domain=find(power,"Domain")
 if awaken and awaken:IsA("GuiButton") then bind(awaken.Activated,function() combat:FireServer("Awaken") end) end
 if domain and domain:IsA("GuiButton") then bind(domain.Activated,function() combat:FireServer("Domain") end) end

 local quick=find(gui,"QuickMenu")
 local quickMap={
  M_Fighters="FighterPanel",
  M_Map="MapPanel",
  M_Missions="QuestPanel",
  M_Profile="ProfilePanel",
  M_Market="ShopPanel",
  M_Scoreboard="ScoreboardPanel",
  M_Settings="SettingsPanel",
 }
 for buttonName,panelName in pairs(quickMap) do
  local b=find(quick,buttonName)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function() self:Open(panelName) end)
  end
 end

 for _,pair in ipairs({
  {"QuickMenu","Close"},
  {"MapPanel","Close"},
  {"ShopPanel","Close"},
  {"FighterPanel","Close"},
  {"QuestPanel","Close"},
  {"ProfilePanel","Close"},
  {"ScoreboardPanel","Close"},
  {"SettingsPanel","Close"},
 }) do
  local panel=find(gui,pair[1])
  local b=find(panel,pair[2])
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function() show(pair[1],false) end)
  end
 end

 local tabs=find(find(gui,"ShopPanel"),"Tabs")
 for _,name in ipairs({"TabFeatured","TabRobux"}) do
  local b=tabs and find(tabs,name)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function()
    activeMarketTab=name:sub(4)
    self:RenderShop()
   end)
  end
 end

 local map=find(gui,"MapPanel")
 for _,id in ipairs(Routes.Order) do
  local b=find(map,id)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function()
    travel:FireServer(id)
    show("MapPanel",false)
   end)
  end
 end

 local fighterPanel=find(gui,"FighterPanel")
 for _,id in ipairs(Fighters.Order) do
  local b=find(fighterPanel,id)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function()
    utility:FireServer("SetCharacter",id)
    show("FighterPanel",false)
   end)
  end
 end

 local clash=find(gui,"ClashPanel")
 for i=1,4 do
  local b=find(clash,"Clash"..i)
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function() combat:FireServer("Clash"..tostring(i)) end)
  end
 end

 local quest=find(gui,"QuestPanel")
 for _,kind in ipairs({"Daily","Weekly","Lifetime"}) do
  local row=find(quest,kind)
  local b=find(row,"Claim")
  if b and b:IsA("GuiButton") then
   bind(b.Activated,function() utility:FireServer("ClaimMission",kind) end)
  end
 end

 if tabs then
  local shopPanel=find(gui,"ShopPanel")
  if shopPanel then
   bind(player:GetAttributeChangedSignal("Credits"),function() self:RenderShop() end)
  end
 end

 bind(player.CharacterAdded,function(character)
  local humanoid=character:WaitForChild("Humanoid",8)
  if humanoid then
   bind(humanoid.HealthChanged,function() self:RefreshHUD() end)
  end
  task.defer(function() self:RefreshHUD() end)
 end)

 for _,attribute in ipairs({
  "Energy","MaxEnergy","Overdrive","Level","EquippedCharacter","EquippedTitle",
  "CurrentMapNode","Combo","Blocking","AwakeningActive","NextLight","NextDash",
  "NextSpecial","NextDomain","DomainClash","ClashScore","Credits","KOs","Streak",
  "DailyKOs","WeeklyKOs","LifetimeKOs","Respawning",
 }) do
  bind(player:GetAttributeChangedSignal(attribute),function()
   self:RefreshHUD()
   self:RenderMissions()
   self:RefreshProfile()
  end)
 end

 bind(Players.PlayerAdded,function() self:RenderScoreboard() end)
 bind(Players.PlayerRemoving,function() self:RenderScoreboard() end)

 bind(feedback.OnClientEvent,function(kind,value)
  if kind=="ShopState" and typeof(value)=="table" then
   table.clear(owned)
   for _,id in ipairs(value.Owned or {}) do
    owned[tostring(id)]=true
   end
   self:RenderShop()
  elseif kind=="Message" then
   toast(tostring(value),1.15)
   addFeed(tostring(value))
   self:RenderShop()
  elseif kind=="CharacterChanged" then
   toast("FIGHTER  •  "..tostring(value),.85)
   addFeed("Fighter selected  •  "..tostring(value))
   self:RefreshHUD()
  elseif kind=="KOReward" then
   local credits=tonumber(value and value.Credits) or 5
   toast("KO  + "..credits.." C",.8)
   addFeed("KNOCKOUT  •  +"..credits.." C")
  elseif kind=="LevelUp" then
   toast("LEVEL UP  •  "..tostring(value),1)
   addFeed("LEVEL UP  •  "..tostring(value))
  elseif kind=="Travel" then
   addFeed("TRAVEL  •  "..tostring(value.Name or value.Id or "DISTRICT"))
  elseif kind=="Parry" then
   addFeed("PARRY")
  elseif kind=="Guard" then
   addFeed("GUARD")
  elseif kind=="Special" then
   addFeed("SPECIAL  •  "..tostring(value and value.Name or "READY"))
  elseif kind=="Awaken" then
   addFeed("AWAKENING  •  ACTIVE")
  elseif kind=="Domain" then
   addFeed("DOMAIN  •  "..tostring(value and value.Name or "OPEN"))
  end
 end)

 self:RefreshHUD()
 self:RenderMissions()
 self:RefreshProfile()
 self:RenderScoreboard()
 addFeed("BATTLE ONLINE")
end

return M
