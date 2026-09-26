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
local gui:ScreenGui
local remotes
local combat:RemoteEvent
local utility:RemoteEvent
local travel:RemoteEvent
local feedback:RemoteEvent
local owned:{[string]:boolean}={}
local activeTab="Featured"
local bound:{[RBXScriptConnection]:boolean}={}

local function bind(signal:RBXScriptSignal,fn:(...any)->())
 local c=signal:Connect(fn);bound[c]=true;return c
end

local function find(root:Instance?,name:string):Instance?
 return root and root:FindFirstChild(name)
end

local function lbl(root:Instance?,name:string):TextLabel?
 local x=find(root,name)
 return x and x:IsA("TextLabel") and x or nil
end

local function show(name:string,visible:boolean)
 local x=find(gui,name)
 if x and x:IsA("GuiObject") then x.Visible=visible end
end

local function closePanels()
 for _,name in ipairs({"MapPanel","ShopPanel","FighterPanel","QuestPanel","ProfilePanel","QuickMenu"}) do show(name,false) end
end

local function toast(message:string,duration:number?)
 local n=find(gui,"Notice")
 local t=lbl(n,"Text")
 if not n or not t then return end
 t.Text=message
 n.Visible=true
 task.delay(duration or 1,function() if t.Parent and t.Text==message then n.Visible=false end end)
end

local function clear(parent:Instance)
 for _,x in ipairs(parent:GetChildren()) do
  if not x:IsA("UIGridLayout") and not x:IsA("UIListLayout") then x:Destroy() end
 end
end

local function cardButton(parent:Instance,name:string,title:string,desc:string,price:string?,ownedState:boolean):TextButton
 local b=Instance.new("TextButton")
 b.Name=name;b.Size=UDim2.fromOffset(250,120);b.BackgroundColor3=C.UI.PanelSoft;b.BackgroundTransparency=.02;b.BorderSizePixel=0;b.AutoButtonColor=false;b.Text="";b.ZIndex=54;b.Parent=parent
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,11);c.Parent=b
 local s=Instance.new("UIStroke");s.Color=C.UI.Muted;s.Transparency=.78;s.Thickness=1;s.Parent=b
 local t=Instance.new("TextLabel");t.Name="Title";t.Text=title;t.Size=UDim2.new(1,-20,0,24);t.Position=UDim2.fromOffset(10,8);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBlack;t.TextSize=13;t.TextColor3=C.UI.Text;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=b
 local d=Instance.new("TextLabel");d.Name="Desc";d.Text=desc;d.Size=UDim2.new(1,-20,0,35);d.Position=UDim2.fromOffset(10,35);d.BackgroundTransparency=1;d.Font=Enum.Font.Gotham;d.TextSize=8;d.TextColor3=C.UI.Muted;d.TextWrapped=true;d.TextXAlignment=Enum.TextXAlignment.Left;d.TextYAlignment=Enum.TextYAlignment.Top;d.Parent=b
 local p=Instance.new("TextLabel");p.Name="Price";p.Text=price or (ownedState and "OWNED" or "");p.Size=UDim2.fromOffset(100,22);p.Position=UDim2.fromOffset(10,91);p.BackgroundTransparency=1;p.Font=Enum.Font.GothamBlack;p.TextSize=9;p.TextColor3=ownedState and C.UI.Success or C.UI.Gold;p.TextXAlignment=Enum.TextXAlignment.Left;p.Parent=b
 local a=Instance.new("TextLabel");a.Name="Action";a.Text=ownedState and "EQUIP" or "UNLOCK";a.Size=UDim2.fromOffset(84,28);a.Position=UDim2.new(1,-94,1,-36);a.BackgroundColor3=C.UI.PanelAlt;a.BorderSizePixel=0;a.Font=Enum.Font.GothamBlack;a.TextSize=8;a.TextColor3=C.UI.Text;a.Parent=b
 local ac=Instance.new("UICorner");ac.CornerRadius=UDim.new(0,8);ac.Parent=a
 return b
end

function M:RefreshHUD()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local panel=find(gui,"PlayerPanel")
 local hp=panel and find(panel,"Health")
 local hf=hp and find(hp,"Fill")
 local hv=lbl(hp,"Value")
 if humanoid and hf and hf:IsA("Frame") then
  local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
  hf.Size=UDim2.fromScale(ratio,1)
  if hv then hv.Text=("%d / %d"):format(math.floor(humanoid.Health+0.5),math.floor(humanoid.MaxHealth+0.5)) end
 end
 local energy=math.clamp(tonumber(player:GetAttribute("Energy")) or 0,0,tonumber(player:GetAttribute("MaxEnergy")) or 100)
 local ef=find(panel,"Energy");local efill=ef and find(ef,"Fill");local ev=lbl(ef,"Value")
 if efill and efill:IsA("Frame") then efill.Size=UDim2.fromScale(energy/100,1) end
 if ev then ev.Text="CE "..math.floor(energy) end
 local over=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
 local clash=find(gui,"ClashPanel")
 if clash and clash:IsA("GuiObject") then
  local active=(tonumber(player:GetAttribute("DomainClash")) or 0)>0
  clash.Visible=active
  local score=lbl(clash,"Score")
  if score then score.Text=tostring(player:GetAttribute("ClashScore") or 0).."  •  CLASH" end
 end
 local af=find(panel,"Awakening");local afill=af and find(af,"Fill");local av=lbl(af,"Value")
 if afill and afill:IsA("Frame") then afill.Size=UDim2.fromScale(over/100,1) end
 if av then av.Text=(player:GetAttribute("AwakeningActive")==true and "AWAKENING ACTIVE" or "AWAKENING "..math.floor(over).."%") end
 local charLabel=lbl(panel,"Character")
 local fighter=Fighters.Get(tostring(player:GetAttribute("EquippedCharacter") or "Yuji"))
 if charLabel and fighter then charLabel.Text=fighter.DisplayName.."  •  "..tostring(player:GetAttribute("EquippedTitle") or "RIVAL") end
 local location=find(gui,"Location")
 local lt=lbl(location,"Text")
 local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
 if lt and node then lt.Text=node.Name.."  •  LV "..tostring(player:GetAttribute("Level") or 1) end
 self:RefreshCooldowns()
end

function M:RefreshCooldowns()
 local hotbar=find(gui,"Hotbar")
 local mobile=find(gui,"MobileActions")
 local pairsList={{"Light","NextLight"},{"Dash","NextDash"},{"Special","NextSpecial"}}
 for _,pair in ipairs(pairsList) do
  local b=hotbar and find(hotbar,pair[1])
  local cd=lbl(b,"Cooldown");local st=lbl(b,"State")
  local remain=math.max(0,(tonumber(player:GetAttribute(pair[2])) or 0)-os.clock())
  if cd then cd.Text=remain>.03 and ("%.1f"):format(remain) or "" end
  if st then st.Text=remain>.03 and "COOLDOWN" or "READY" end
  local mb=mobile and find(mobile,pair[1]=="Light" and "MobileM1" or pair[1]=="Dash" and "MobileDash" or pair[1]=="Special" and "MobileSpecial" or "")
  if mb and mb:IsA("TextButton") then mb.Text=pair[1]:upper()..(remain>.03 and (" "..("%.1f"):format(remain)) or "") end
 end
 local b=find(hotbar,"Block");local bs=lbl(b,"State")
 if bs then bs.Text=player:GetAttribute("Blocking")==true and "GUARDING" or "HOLD F" end
end

function M:RenderShop()
 local panel=find(gui,"ShopPanel");local content=find(panel,"Content")
 if not panel or not content then return end
 clear(content)
 local credit=lbl(panel,"Credits");if credit then credit.Text=tostring(math.floor(tonumber(player:GetAttribute("Credits")) or 0)).." C" end
 if activeTab=="Robux" then
  local note=Instance.new("TextLabel");note.Size=UDim2.fromOffset(700,32);note.BackgroundTransparency=1;note.Text="CREDIT PACKS";note.Font=Enum.Font.GothamBlack;note.TextSize=18;note.TextColor3=C.UI.Text;note.TextXAlignment=Enum.TextXAlignment.Left;note.Parent=content
  local hint=Instance.new("TextLabel");hint.Size=UDim2.fromOffset(700,28);hint.Position=UDim2.fromOffset(0,32);hint.BackgroundTransparency=1;hint.Text="Developer Product IDs are required before real Robux checkout can be enabled.";hint.Font=Enum.Font.Gotham;hint.TextSize=9;hint.TextColor3=C.UI.Muted;hint.TextXAlignment=Enum.TextXAlignment.Left;hint.Parent=content
  for i,bundle in ipairs(Catalog.Bundles) do
   local col=(i-1)%2;local row=math.floor((i-1)/2)
   local b=cardButton(content,bundle.Id,bundle.Name,"Robux product",tostring(bundle.Robux).." R$",false);b.Position=UDim2.fromOffset(col*270,row*128+65)
   local action=b:FindFirstChild("Action");if action and action:IsA("TextLabel") then action.Text=bundle.ProductId>0 and "BUY" or "NOT LINKED" end
   b.Activated:Connect(function() toast(bundle.ProductId>0 and "OPENING PURCHASE" or "PRODUCT ID NOT CONFIGURED",1.2) end)
  end
  return
 end
 local items={}
 for _,item in ipairs(Catalog.Items) do if item.Category==activeTab then table.insert(items,item) end end
 for i,item in ipairs(items) do
  local col=(i-1)%3;local row=math.floor((i-1)/3)
  local isOwned=owned[item.Id]==true
  local b=cardButton(content,item.Id,item.Name,item.Description,tostring(item.Price).." C",isOwned)
  b.Position=UDim2.fromOffset(col*258,row*128)
  b.Activated:Connect(function() utility:FireServer(isOwned and "EquipItem" or "BuyItem",item.Id) end)
 end
end

function M:RenderMissions()
 local panel=find(gui,"QuestPanel");if not panel then return end
 local values={Daily={tonumber(player:GetAttribute("DailyKOs")) or 0, C.Missions.Daily.Goal},Weekly={tonumber(player:GetAttribute("WeeklyKOs")) or 0,C.Missions.Weekly.Goal},Lifetime={tonumber(player:GetAttribute("LifetimeKOs")) or 0,C.Missions.Lifetime.Goal}}
 for kind,v in pairs(values) do
  local row=find(panel,kind);local p=lbl(row,"Progress")
  if p then p.Text=tostring(v[1]).." / "..tostring(v[2]).." KOs" end
 end
end

function M:RefreshProfile()
 local panel=find(gui,"ProfilePanel");local stats=lbl(panel,"Stats");if not stats then return end
 stats.Text=("LEVEL %d\n%d KOs\n%d CREDITS\n%d STREAK"):format(
  tonumber(player:GetAttribute("Level")) or 1,
  tonumber(player:GetAttribute("KOs")) or 0,
  tonumber(player:GetAttribute("Credits")) or 0,
  tonumber(player:GetAttribute("Streak")) or 0
 )
end

function M:Open(name:string)
 closePanels()
 show(name,true)
 if name=="ShopPanel" then self:RenderShop() end
 if name=="QuestPanel" then self:RenderMissions() end
 if name=="ProfilePanel" then self:RefreshProfile() end
end

function M:Bind(guiArg:ScreenGui,remotesArg)
 gui=guiArg;remotes=remotesArg
 combat=remotes:WaitForChild("CombatRequest") :: RemoteEvent
 utility=remotes:WaitForChild("UtilityRequest") :: RemoteEvent
 travel=remotes:WaitForChild("MapTravelRequest") :: RemoteEvent
 feedback=remotes:WaitForChild("Feedback") :: RemoteEvent

 local bar=find(gui,"Utility")
 for buttonName,panelName in pairs({ShopButton="ShopPanel",MapButton="MapPanel",FighterButton="FighterPanel"}) do
  local b=find(bar,buttonName)
  if b and b:IsA("GuiButton") then bind(b.Activated,function() self:Open(panelName) end) end
 end
 local menu=find(bar,"MenuButton")
 if menu and menu:IsA("GuiButton") then
  bind(menu.Activated,function()
   closePanels()
   local panel=find(gui,"QuickMenu")
   if panel and panel:IsA("GuiObject") then panel:Destroy() end
   local p=Instance.new("Frame");p.Name="QuickMenu";p.Size=UDim2.fromOffset(315,285);p.Position=UDim2.new(1,-330,0,65);p.BackgroundColor3=C.UI.Panel;p.BorderSizePixel=0;p.ZIndex=70;p.Parent=gui
   local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=p
   local s=Instance.new("UIStroke");s.Color=C.UI.Muted;s.Transparency=.65;s.Parent=p
   local t=Instance.new("TextLabel");t.Size=UDim2.fromOffset(280,30);t.Position=UDim2.fromOffset(16,12);t.BackgroundTransparency=1;t.Text="CONTROL DECK";t.Font=Enum.Font.GothamBlack;t.TextSize=18;t.TextColor3=C.UI.Text;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=p
   local entries={{"Shop","MARKET"},{"Fighters","FIGHTERS"},{"Missions","MISSIONS"},{"Profile","PROFILE"},{"Map","MAP"}}
   for i,e in ipairs(entries) do
    local b=Instance.new("TextButton");b.Size=UDim2.fromOffset(130,44);b.Position=UDim2.fromOffset(16+((i-1)%2)*142,56+math.floor((i-1)/2)*53);b.BackgroundColor3=C.UI.PanelAlt;b.BorderSizePixel=0;b.Text=e[2];b.Font=Enum.Font.GothamBlack;b.TextSize=9;b.TextColor3=C.UI.Text;b.ZIndex=71;b.Parent=p
    local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,9);bc.Parent=b
    b.Activated:Connect(function() p:Destroy();self:Open(e[1]=="Shop" and "ShopPanel" or e[1]=="Fighters" and "FighterPanel" or e[1]=="Missions" and "QuestPanel" or e[1]=="Profile" and "ProfilePanel" or "MapPanel") end)
   end
  end)
 end

 for _,pair in ipairs({{"ShopPanel","Close"},{"MapPanel","Close"},{"FighterPanel","Close"},{"QuestPanel","Close"},{"ProfilePanel","Close"}}) do
  local panel=find(gui,pair[1]);local b=find(panel,pair[2])
  if b and b:IsA("GuiButton") then bind(b.Activated,function() show(pair[1],false) end) end
 end

 local tabs=find(find(gui,"ShopPanel"),"Tabs")
 if tabs then
  for _,name in ipairs({"TabFeatured","TabEmotes","TabRobux"}) do
   local b=find(tabs,name)
   if b and b:IsA("GuiButton") then bind(b.Activated,function() activeTab=name:sub(4);self:RenderShop() end) end
  end
 end

 local code=find(find(gui,"ShopPanel"),"Code");local input=find(code,"Input");local redeem=find(code,"Redeem")
 if input and redeem and input:IsA("TextBox") and redeem:IsA("GuiButton") then
  bind(redeem.Activated,function() utility:FireServer("RedeemCode",input.Text);input.Text="" end)
 end

 local map=find(gui,"MapPanel")
 for _,id in ipairs(Routes.Order) do
  local b=find(map,id)
  if b and b:IsA("GuiButton") then bind(b.Activated,function() travel:FireServer(id);show("MapPanel",false) end) end
 end

 local fighterPanel=find(gui,"FighterPanel")
 for _,id in ipairs(Fighters.Order) do
  local b=find(fighterPanel,id)
  if b and b:IsA("GuiButton") then bind(b.Activated,function() utility:FireServer("SetCharacter",id);show("FighterPanel",false) end) end
 end

 local clashPanel=find(gui,"ClashPanel")
 if clashPanel then
  for i=1,4 do
   local b=find(clashPanel,"Clash"..i)
   if b and b:IsA("GuiButton") then
    bind(b.Activated,function() combat:FireServer("Clash"..tostring(i)) end)
   end
  end
 end

 local quest=find(gui,"QuestPanel")
 for _,kind in ipairs({"Daily","Weekly","Lifetime"}) do
  local row=find(quest,kind);local b=find(row,"Claim")
  if b and b:IsA("GuiButton") then bind(b.Activated,function() utility:FireServer("ClaimMission",kind) end) end
 end

 local character=player.Character
 if character then
  local humanoid=character:FindFirstChildOfClass("Humanoid")
  if humanoid then bind(humanoid.HealthChanged,function() self:RefreshHUD() end) end
 end
 bind(player.CharacterAdded,function(character)
  local humanoid=character:WaitForChild("Humanoid",8)
  if humanoid then bind(humanoid.HealthChanged,function() self:RefreshHUD() end) end
  task.defer(function() self:RefreshHUD() end)
 end)

 for _,attribute in ipairs({"Energy","MaxEnergy","Overdrive","Level","EquippedCharacter","EquippedTitle","CurrentMapNode","Combo","Blocking","AwakeningActive","NextLight","NextDash","NextSpecial","NextDomain","DomainClash","ClashScore","Credits","KOs","Streak","DailyKOs","WeeklyKOs","LifetimeKOs"}) do
  bind(player:GetAttributeChangedSignal(attribute),function() self:RefreshHUD();self:RenderMissions();self:RefreshProfile() end)
 end

 bind(feedback.OnClientEvent,function(kind,value)
  if kind=="ShopState" and typeof(value)=="table" then
   table.clear(owned)
   for _,id in ipairs(value.Owned or {}) do owned[tostring(id)]=true end
   self:RenderShop()
  elseif kind=="Message" then
   toast(tostring(value),1.25)
   self:RenderShop()
  elseif kind=="CharacterChanged" then
   toast("FIGHTER SELECTED  •  "..tostring(value),.9)
   self:RefreshHUD()
  elseif kind=="KOReward" then
   toast("KO  •  +"..tostring(value.Credits or 5).." C",.8)
  elseif kind=="LevelUp" then
   toast("LEVEL UP  •  "..tostring(value),1)
  elseif kind=="Emote" then
   toast("EMOTE  •  "..tostring(value),.6)
  elseif kind=="Travel" then
   toast(tostring(value.Name),.7)
  end
 end)

 task.spawn(function()
  while gui.Parent do
   self:RefreshCooldowns()
   task.wait(.12)
  end
 end)
 self:RefreshHUD();self:RenderMissions();self:RefreshProfile()
end

return M