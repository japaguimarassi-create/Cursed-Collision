--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local player=Players.LocalPlayer
local guiParent=player:WaitForChild("PlayerGui")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local C=require(Shared.Config)
local Routes=require(Shared.MapDefinitions)
local Catalog=require(Shared.StoreCatalog)
local HUD=require(Shared.UI.HUDLayout)
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local combat=remotes:WaitForChild("CombatRequest")
local movement=remotes:WaitForChild("MovementRequest")
local utility=remotes:WaitForChild("UtilityRequest")
local travel=remotes:WaitForChild("MapTravelRequest")
local feedback=remotes:WaitForChild("Feedback")

local gui
local buildOk,buildResult=pcall(HUD.Build)
if buildOk and buildResult and buildResult:IsA("ScreenGui") then
  gui=buildResult
  gui.Enabled=true
  gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
  gui.Parent=guiParent
else
  gui=Instance.new("ScreenGui")
  gui.Name="CollisionHUD"
  gui.ResetOnSpawn=false
  gui.DisplayOrder=1000
  gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
  gui.Parent=guiParent
  local emergency=Instance.new("TextLabel")
  emergency.Size=UDim2.fromScale(.92,.18)
  emergency.Position=UDim2.fromScale(.04,.41)
  emergency.BackgroundColor3=C.UI.Panel
  emergency.TextColor3=C.UI.Danger
  emergency.TextScaled=true
  emergency.Font=Enum.Font.GothamBlack
  emergency.Text="COLLISION BATTLESTAR\nHUD BOOT ERROR"
  emergency.Parent=gui
  local s=Instance.new("UIStroke")
  s.Color=C.UI.Danger
  s.Thickness=2
  s.Parent=emergency
  player:SetAttribute("HUDRuntimeError",tostring(buildResult))
end

local connections:{RBXScriptConnection}={}
local owned:{[string]:boolean}={}
local activeTab="Featured"
local fxCount=0
local damageCount=0
local lastEmote=0

local function bind(signal:any,fn:any)
  table.insert(connections,signal:Connect(fn))
end

local function find(parent:Instance?,name:string):Instance?
  return parent and parent:FindFirstChild(name)
end

local function label(parent:Instance?,name:string):TextLabel?
  local v=find(parent,name)
  return v and v:IsA("TextLabel") and v or nil
end

local function show(parent:Instance,name:string,on:boolean)
  local v=find(parent,name)
  if v and v:IsA("GuiObject") then v.Visible=on end
end

local function clear(parent:Instance)
  for _,v in ipairs(parent:GetChildren()) do
    if v:IsA("GuiObject") and not v:IsA("UIListLayout") then v:Destroy() end
  end
end

local function btn(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2):TextButton
  local b=Instance.new("TextButton")
  b.Name=name
  b.Text=value
  b.Size=size
  b.Position=pos
  b.BackgroundColor3=C.UI.PanelAlt
  b.BackgroundTransparency=.02
  b.BorderSizePixel=0
  b.AutoButtonColor=false
  b.Font=Enum.Font.GothamBold
  b.TextSize=10
  b.TextColor3=C.UI.Text
  b.Parent=parent
  local c=Instance.new("UICorner")
  c.CornerRadius=UDim.new(0,10)
  c.Parent=b
  local s=Instance.new("UIStroke")
  s.Color=C.UI.Muted
  s.Transparency=.72
  s.Thickness=1
  s.Parent=b
  return b
end

local function txt(parent:Instance,name:string,value:string,size:UDim2,pos:UDim2,textSize:number,color:Color3,font:Enum.Font,align:Enum.TextXAlignment)
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

local function round(parent:Instance,r:number)
  local c=Instance.new("UICorner")
  c.CornerRadius=UDim.new(0,r)
  c.Parent=parent
end

local function panelStroke(parent:Instance)
  local s=Instance.new("UIStroke")
  s.Color=C.UI.Muted
  s.Transparency=.55
  s.Thickness=1
  s.Parent=parent
end

local function setMeter(frameObject:Instance?,ratio:number,textValue:string?)
  if not frameObject then return end
  local fill=find(frameObject,"Fill")
  if fill and fill:IsA("Frame") then fill.Size=UDim2.new(math.clamp(ratio,0,1),0,1,0) end
  if textValue then
    local t=label(frameObject,"Value")
    if t then t.Text=textValue end
  end
end

local function updatePlayerPanel()
  local panel=find(gui,"PlayerPanel")
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if humanoid then
    local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
    setMeter(find(panel,"Health"),ratio,("%d / %d"):format(math.floor(humanoid.Health),math.floor(humanoid.MaxHealth)))
  end
  local energy=math.clamp(tonumber(player:GetAttribute("Energy"))or 100,0,100)
  setMeter(find(panel,"Energy"),energy/100,("CE %d"):format(math.floor(energy)))
  local over=math.clamp(tonumber(player:GetAttribute("Overdrive"))or 0,0,100)
  setMeter(find(panel,"Awakening"),over/100,over>=100 and "AWAKENING READY" or ("AWAKENING %d%%"):format(math.floor(over)))
  local level=tonumber(player:GetAttribute("Level"))or 1
  local title=label(panel,"Title")
  if title then title.Text=(player:GetAttribute("EquippedItem")~="" and "EQUIPPED • "..tostring(player:GetAttribute("EquippedItem"))) or "RIVAL • BATTLE PILOT" end
  local loc=find(gui,"Location")
  local locText=label(loc,"Text")
  local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode")or "Origin"))
  local stats=player:FindFirstChild("leaderstats")
  local credits=stats and stats:FindFirstChild("Credits")
  if locText then locText.Text=(node and node.Name or "ORIGIN PLAZA").."  •  LV "..level end
  local quickCredits=label(find(gui,"QuickCredits"),"Value")
  if quickCredits then quickCredits.Text=tostring(credits and credits:IsA("IntValue") and credits.Value or 0).." C" end
end

local function updateCombatState()
  local center=find(gui,"CombatState")
  local combo=label(center,"Combo")
  if combo then combo.Text="COMBO "..tostring(player:GetAttribute("Combo")or 0) end
end

local function refreshProfilePanel()
  local panel=find(gui,"ProfilePanel")
  local stats=player:FindFirstChild("leaderstats")
  local credits=stats and stats:FindFirstChild("Credits")
  local kos=stats and stats:FindFirstChild("KOs")
  local streak=stats and stats:FindFirstChild("Streak")
  local profile=label(panel,"Stats")
  if profile then
    profile.Text=("LEVEL %d\n%d KOs\n%d CREDITS\n%d STREAK"):format(
      tonumber(player:GetAttribute("Level"))or 1,
      kos and kos:IsA("IntValue") and kos.Value or 0,
      credits and credits:IsA("IntValue") and credits.Value or 0,
      streak and streak:IsA("IntValue") and streak.Value or 0
    )
  end
end

local function toast(message:string,duration:number)
  local notice=find(gui,"Notice")
  local t=label(notice,"Text")
  if not notice or not t then return end
  t.Text=message
  notice.Visible=true
  task.delay(duration,function()
    if t.Parent and t.Text==message then notice.Visible=false end
  end)
end

local function closePanels()
  for _,name in ipairs({"MapPanel","ShopPanel","QuestPanel","ProfilePanel"}) do
    show(gui,name,false)
  end
end

local function renderShop()
  local shop=find(gui,"ShopPanel")
  local content=find(shop,"Content")
  if not shop or not content or not content:IsA("Frame") then return end
  clear(content)
  local stats=player:FindFirstChild("leaderstats")
  local credits=stats and stats:FindFirstChild("Credits")
  local creditText=label(shop,"Credits")
  if creditText then creditText.Text=tostring(credits and credits:IsA("IntValue") and credits.Value or 0).." C" end
  if activeTab=="Robux" then
    local note=txt(content,"Note","CREDIT PACKS",UDim2.fromOffset(400,26),UDim2.fromOffset(0,0),18,C.UI.Text,Enum.Font.GothamBlack,Enum.TextXAlignment.Left)
    txt(content,"Hint","Connect Developer Product IDs to enable real Robux purchases.",UDim2.fromOffset(700,20),UDim2.fromOffset(0,30),9,C.UI.Muted,Enum.Font.Gotham,Enum.TextXAlignment.Left)
    for i,bundle in ipairs(Catalog.Bundles) do
      local col=(i-1)%2
      local row=math.floor((i-1)/2)
      local card=Instance.new("Frame")
      card.Size=UDim2.fromOffset(395,92)
      card.Position=UDim2.fromOffset(col*408,65+row*101)
      card.BackgroundColor3=C.UI.PanelSoft
      card.BorderSizePixel=0
      card.Parent=content
      round(card,12);panelStroke(card)
      txt(card,"Amount",bundle.Name,UDim2.fromOffset(250,28),UDim2.fromOffset(14,11),16,C.UI.Text,Enum.Font.GothamBlack,Enum.TextXAlignment.Left)
      txt(card,"Price",tostring(bundle.Robux).." R$",UDim2.fromOffset(120,22),UDim2.fromOffset(14,43),11,C.UI.Gold,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
      local buy=btn(card,"Buy","PURCHASE",UDim2.fromOffset(112,36),UDim2.new(1,-126,0,28))
      if bundle.Best then buy.Text="BEST VALUE" end
      buy.Activated:Connect(function() toast("DEVELOPER PRODUCT ID NOT CONNECTED",1.4) end)
    end
    return
  end
  local items={}
  for _,item in ipairs(Catalog.Items) do
    if item.Category==activeTab then table.insert(items,item) end
  end
  for i,item in ipairs(items) do
    local col=(i-1)%3
    local row=math.floor((i-1)/3)
    local card=Instance.new("Frame")
    card.Size=UDim2.fromOffset(258,126)
    card.Position=UDim2.fromOffset(col*267,row*136)
    card.BackgroundColor3=C.UI.PanelSoft
    card.BorderSizePixel=0
    card.Parent=content
    round(card,12);panelStroke(card)
    txt(card,"Name",item.Name,UDim2.fromOffset(230,24),UDim2.fromOffset(12,8),14,C.UI.Text,Enum.Font.GothamBlack,Enum.TextXAlignment.Left)
    txt(card,"Desc",item.Description,UDim2.fromOffset(230,32),UDim2.fromOffset(12,34),9,C.UI.Muted,Enum.Font.Gotham,Enum.TextXAlignment.Left).TextWrapped=true
    txt(card,"Price",tostring(item.Price).." C",UDim2.fromOffset(90,22),UDim2.fromOffset(12,92),10,C.UI.ShopGreen,Enum.Font.GothamBlack,Enum.TextXAlignment.Left)
    local action=btn(card,"Action",owned[item.Id] and "EQUIP" or "UNLOCK",UDim2.fromOffset(90,30),UDim2.new(1,-102,1,-40))
    action.Activated:Connect(function()
      utility:FireServer(owned[item.Id] and "EquipItem" or "BuyItem",item.Id)
    end)
  end
end

local function openShop(tab:string?)
  closePanels()
  activeTab=tab or "Featured"
  show(gui,"ShopPanel",true)
  renderShop()
  utility:FireServer("ShopState")
end

local function openMap()
  closePanels()
  show(gui,"MapPanel",true)
end

local function openQuests()
  closePanels()
  show(gui,"QuestPanel",true)
end

local function openProfile()
  closePanels()
  show(gui,"ProfilePanel",true)
  refreshProfilePanel()
end

local function bindUI()
  local utilityBar=find(gui,"Utility")
  local shopBtn=utilityBar and utilityBar:FindFirstChild("ShopButton")
  local mapBtn=utilityBar and utilityBar:FindFirstChild("MapButton")
  local pingBtn=utilityBar and utilityBar:FindFirstChild("PingButton")
  local menuBtn=utilityBar and utilityBar:FindFirstChild("MenuButton")
  if shopBtn and shopBtn:IsA("GuiButton") then bind(shopBtn.Activated,function() openShop() end) end
  if mapBtn and mapBtn:IsA("GuiButton") then bind(mapBtn.Activated,openMap) end
  if pingBtn and pingBtn:IsA("GuiButton") then bind(pingBtn.Activated,function()
    local camera=workspace.CurrentCamera
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not camera or not root then return end
    local v=camera.ViewportSize
    local ray=camera:ViewportPointToRay(v.X*.5,v.Y*.52)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={player.Character}
    local result=workspace:Raycast(ray.Origin,ray.Direction*220,params)
    if result then utility:FireServer("Ping",result.Position);toast("PING",.6) end
  end) end
  if menuBtn and menuBtn:IsA("GuiButton") then bind(menuBtn.Activated,function()
    closePanels()
    local panel=Instance.new("Frame")
    panel.Name="QuickMenu"
    panel.Size=UDim2.fromOffset(300,260)
    panel.Position=UDim2.new(1,-316,0,64)
    panel.BackgroundColor3=C.UI.Panel
    panel.BorderSizePixel=0
    panel.ZIndex=60
    panel.Parent=gui
    round(panel,14);panelStroke(panel)
    txt(panel,"Title","CONTROL DECK",UDim2.fromOffset(250,28),UDim2.fromOffset(16,14),17,C.UI.Text,Enum.Font.GothamBlack,Enum.TextXAlignment.Left)
    local entries={{"Shop","SHOP"},{"Emotes","EMOTES"},{"Quests","MISSIONS"},{"Profile","PROFILE"},{"Map","MAP"}}
    for i,e in ipairs(entries) do
      local b=btn(panel,e[1],e[2],UDim2.fromOffset(128,42),UDim2.fromOffset(16+((i-1)%2)*138,55+math.floor((i-1)/2)*52))
      b.ZIndex=61
      b.Activated:Connect(function()
        panel:Destroy()
        if e[1]=="Shop" then openShop("Featured")
        elseif e[1]=="Emotes" then openShop("Emotes")
        elseif e[1]=="Quests" then openQuests()
        elseif e[1]=="Profile" then openProfile()
        else openMap() end
      end)
    end
  end) end

  local shop=find(gui,"ShopPanel")
  local shopClose=shop and shop:FindFirstChild("Close")
  if shopClose and shopClose:IsA("GuiButton") then bind(shopClose.Activated,function() show(gui,"ShopPanel",false) end) end
  local tabs=shop and shop:FindFirstChild("Tabs")
  if tabs then
    for _,name in ipairs({"TabFeatured","TabEmotes","TabRobux"}) do
      local b=tabs:FindFirstChild(name)
      if b and b:IsA("GuiButton") then
        bind(b.Activated,function()
          activeTab=name:sub(4)
          renderShop()
        end)
      end
    end
  end
  local code=shop and shop:FindFirstChild("Code")
  local input=code and code:FindFirstChild("Input")
  local redeem=code and code:FindFirstChild("Redeem")
  if input and redeem and input:IsA("TextBox") and redeem:IsA("GuiButton") then
    bind(redeem.Activated,function()
      utility:FireServer("RedeemCode",input.Text)
      input.Text=""
    end)
  end

  local map=find(gui,"MapPanel")
  local mapClose=map and map:FindFirstChild("Close")
  if mapClose and mapClose:IsA("GuiButton") then bind(mapClose.Activated,function() show(gui,"MapPanel",false) end) end
  for _,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
    local b=map and map:FindFirstChild(id)
    if b and b:IsA("GuiButton") then bind(b.Activated,function() travel:FireServer(id);show(gui,"MapPanel",false) end) end
  end
  local qclose=find(gui,"QuestPanel") and find(gui,"QuestPanel"):FindFirstChild("Close")
  if qclose and qclose:IsA("GuiButton") then bind(qclose.Activated,function() show(gui,"QuestPanel",false) end) end
  local pclose=find(gui,"ProfilePanel") and find(gui,"ProfilePanel"):FindFirstChild("Close")
  if pclose and pclose:IsA("GuiButton") then bind(pclose.Activated,function() show(gui,"ProfilePanel",false) end) end
end

local function attackPose(kind:string)
  local character=player.Character
  if not character then return end
  local root=character:FindFirstChild("HumanoidRootPart")
  if not root or not root:IsA("BasePart") then return end
  if kind=="Dash" then
    local old=root.CFrame
    root.CFrame=root.CFrame*CFrame.Angles(math.rad(-4),0,0)
    task.delay(.08,function() if root.Parent then root.CFrame=old end end)
  end
end

local function spawnRing(position:Vector3,color:Color3,big:boolean)
  if fxCount>=C.Performance.MaxFX then return end
  fxCount+=1
  local p=Instance.new("Part")
  p.Name="CBSFX"
  p.Shape=Enum.PartType.Cylinder
  p.Size=Vector3.new(.18,big and 7 or 4.5,big and 7 or 4.5)
  p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.rad(90))
  p.Anchored=true
  p.CanCollide=false
  p.CanTouch=false
  p.CanQuery=false
  p.CastShadow=false
  p.Material=Enum.Material.Neon
  p.Color=color
  p.Transparency=.1
  p.Parent=workspace
  local tween=TweenService:Create(p,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.18,p.Size.Y*1.25,p.Size.Z*1.25),Transparency=1})
  tween:Play()
  Debris:AddItem(p,.3)
  task.delay(.36,function() fxCount=math.max(0,fxCount-1) end)
end

local function spawnDamage(position:Vector3,damage:number)
  if damageCount>=C.Performance.MaxDamageTexts then return end
  damageCount+=1
  local holder=Instance.new("Part")
  holder.Name="CBDamage"
  holder.Size=Vector3.new(.1,.1,.1)
  holder.Transparency=1
  holder.Anchored=true
  holder.CanCollide=false
  holder.CanTouch=false
  holder.CanQuery=false
  holder.Position=position+Vector3.new(0,2,0)
  holder.Parent=workspace
  local billboard=Instance.new("BillboardGui")
  billboard.Size=UDim2.fromOffset(80,30)
  billboard.AlwaysOnTop=true
  billboard.MaxDistance=80
  billboard.Adornee=holder
  billboard.Parent=holder
  local t=txt(billboard,"Text",tostring(math.floor(damage)),UDim2.fromScale(1,1),UDim2.fromScale(0,0),18,C.UI.Text,Enum.Font.GothamBlack,Enum.TextXAlignment.Center)
  local tween=TweenService:Create(billboard,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{StudsOffset=Vector3.new(0,2,0)})
  tween:Play()
  TweenService:Create(t,TweenInfo.new(.45),{TextTransparency=1,TextStrokeTransparency=1}):Play()
  Debris:AddItem(holder,.5)
  task.delay(.55,function() damageCount=math.max(0,damageCount-1) end)
end

local function platformRefresh()
  local preferred=UserInputService.PreferredInput
  local touch=UserInputService.TouchEnabled and (preferred==Enum.PreferredInput.Touch or not UserInputService.KeyboardEnabled)
  local gamepad=UserInputService.GamepadEnabled and preferred==Enum.PreferredInput.Gamepad
  show(gui,"Hotbar",not touch)
  show(gui,"MobileActions",touch)
  show(gui,"ControllerHints",gamepad)
  local mobile=find(gui,"MobileActions")
  local shop=find(gui,"ShopPanel")
  if touch and mobile and mobile:IsA("Frame") then
    local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(720,1280)
    mobile.Position=UDim2.new(1,-8,.58,0)
    mobile.Size=UDim2.fromOffset(math.clamp(math.floor(v.X*.27),168,205),math.clamp(math.floor(v.Y*.32),225,290))
  end
  if shop and shop:IsA("Frame") then
    shop.Size=touch and UDim2.fromScale(.94,.78) or UDim2.fromScale(.70,.76)
  end
end

bindUI()
platformRefresh()

bind(UserInputService:GetPropertyChangedSignal("PreferredInput"),platformRefresh)
bind(UserInputService.InputBegan,function(input,gpe)
  if gpe then return end
  if input.UserInputType==Enum.UserInputType.MouseButton1 then
    combat:FireServer("Light")
  elseif input.KeyCode==Enum.KeyCode.Q then
    combat:FireServer("Dash")
  elseif input.KeyCode==Enum.KeyCode.F then
    combat:FireServer("BlockStart")
  elseif input.KeyCode==Enum.KeyCode.R then
    combat:FireServer("Special")
  elseif input.KeyCode==Enum.KeyCode.LeftShift then
    movement:FireServer("Sprint",true)
  elseif input.KeyCode==Enum.KeyCode.M then
    openMap()
  end
end)

bind(UserInputService.InputEnded,function(input,gpe)
  if gpe then return end
  if input.KeyCode==Enum.KeyCode.F then combat:FireServer("BlockEnd")
  elseif input.KeyCode==Enum.KeyCode.LeftShift then movement:FireServer("Sprint",false) end
end)

for _,name in ipairs({"Light","Dash","Block","Special"}) do
  local b=find(find(gui,"Hotbar"),name)
  if b and b:IsA("GuiButton") then
    if name=="Light" then bind(b.Activated,function() combat:FireServer("Light") end)
    elseif name=="Dash" then bind(b.Activated,function() combat:FireServer("Dash") end)
    elseif name=="Special" then bind(b.Activated,function() combat:FireServer("Special") end)
    end
  end
end

local block=find(find(gui,"Hotbar"),"Block")
if block and block:IsA("GuiButton") then
  bind(block.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonL2 then combat:FireServer("BlockStart") end
  end)
  bind(block.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonL2 then combat:FireServer("BlockEnd") end
  end)
end

for _,mapping in ipairs({{"MobileM1","Light"},{"MobileDash","Dash"},{"MobileSpecial","Special"}}) do
  local b=find(find(gui,"MobileActions"),mapping[1])
  if b and b:IsA("GuiButton") then bind(b.Activated,function() combat:FireServer(mapping[2]) end) end
end

local mobileGuard=find(find(gui,"MobileActions"),"MobileGuard")
if mobileGuard and mobileGuard:IsA("GuiButton") then
  bind(mobileGuard.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.Touch then combat:FireServer("BlockStart") end
  end)
  bind(mobileGuard.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.Touch then combat:FireServer("BlockEnd") end
  end)
end

bind(player.CharacterAdded,function(character)
  local humanoid=character:WaitForChild("Humanoid",8)
  if humanoid and humanoid:IsA("Humanoid") then
    bind(humanoid.HealthChanged,updatePlayerPanel)
  end
  task.defer(updatePlayerPanel)
end)

local stats=player:WaitForChild("leaderstats",20)
if stats then
  local credits=stats:FindFirstChild("Credits")
  if credits and credits:IsA("IntValue") then bind(credits:GetPropertyChangedSignal("Value"),function() updatePlayerPanel();renderShop() end) end
end

for _,attribute in ipairs({"Energy","Overdrive","Level","CurrentMapNode","Combo"}) do
  bind(player:GetAttributeChangedSignal(attribute),function() updatePlayerPanel();updateCombatState() end)
end

bind(feedback.OnClientEvent,function(kind:string,value:any)
  if kind=="ShopSync" and typeof(value)=="table" then
    table.clear(owned)
    for _,id in ipairs(value.Owned or {}) do owned[tostring(id)]=true end
    renderShop()
  elseif kind=="Message" then
    toast(tostring(value),1.2)
    renderShop()
  elseif kind=="Swing" and typeof(value)=="table" then
    spawnRing(value.Position, C.UI.Accent, tonumber(value.Combo)==4)
  elseif kind=="Hit" and typeof(value)=="table" then
    spawnDamage(value.Position,tonumber(value.Damage)or 0)
    spawnRing(value.Position,C.UI.Accent, value.Finisher==true)
  elseif kind=="HitTaken" and typeof(value)=="table" then
    spawnRing(value.Position,C.UI.Danger,false)
  elseif kind=="Guard" and typeof(value)=="table" then
    spawnRing(value.Position,C.UI.Accent,false)
  elseif kind=="Parry" and typeof(value)=="table" then
    spawnRing(value.Position,C.UI.Accent2,true)
    toast("PARRY",.6)
  elseif kind=="Guarded" then
    toast("GUARD",.45)
  elseif kind=="Special" and typeof(value)=="table" then
    spawnRing(value.Position,C.UI.Accent2,true)
    toast(value.Charged and "AWAKENING SPECIAL" or "SPECIAL",.65)
  elseif kind=="Dash" and typeof(value)=="table" then
    attackPose("Dash")
    spawnRing(value.Position,C.UI.Accent,false)
  elseif kind=="KOReward" and typeof(value)=="table" then
    toast("KO  •  +"..tostring(value.Credits or 5).." CREDITS",.9)
  elseif kind=="LevelUp" then
    toast("LEVEL UP  •  LV "..tostring(value),1.1)
  elseif kind=="Travel" and typeof(value)=="table" then
    toast(tostring(value.Name),.7)
  elseif kind=="Ping" then
    toast("PING",.45)
  elseif kind=="Emote" then
    local now=os.clock()
    if now-lastEmote>.8 then
      lastEmote=now
      local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
      if root and root:IsA("BasePart") then
        root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(15),0)
        task.delay(.45,function() if root.Parent then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(-15),0) end end)
      end
    end
  end
end)

updatePlayerPanel()
updateCombatState()

task.spawn(function()
  while gui.Parent do
    local now=os.clock()
    local hotbar=find(gui,"Hotbar")
    local mapping={Light="NextLight",Dash="NextDash",Special="NextSpecial"}
    if hotbar then
      for name,attribute in pairs(mapping) do
        local b=find(hotbar,name)
        local cd=label(b,"Cooldown")
        local state=label(b,"State")
        if cd and state then
          local remain=math.max(0,(tonumber(player:GetAttribute(attribute))or 0)-now)
          cd.Text=remain>.03 and ("%.1f"):format(remain) or ""
          state.Text=remain>.03 and "COOLDOWN" or "READY"
        end
      end
    end
    task.wait(.2)
  end
end)
