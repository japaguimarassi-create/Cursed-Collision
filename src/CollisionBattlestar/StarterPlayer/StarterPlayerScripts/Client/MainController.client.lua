--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local existingHud=playerGui:FindFirstChild("CollisionHUD")
if existingHud and existingHud:IsA("ScreenGui") and existingHud:GetAttribute("ManagedByFallback")==true then
	return
end
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local combat=remotes:WaitForChild("CombatRequest")
local movement=remotes:WaitForChild("MovementRequest")
local feedback=remotes:WaitForChild("Feedback")
local travel=remotes:WaitForChild("MapTravelRequest")
local travelFeedback=remotes:WaitForChild("MapTravelFeedback")
local Config=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Definitions=require(ReplicatedStorage.Shared.CombatDefinitions)
local Theme=require(ReplicatedStorage.Shared.HUDTheme)

local gui=Instance.new("ScreenGui")
gui.Name="CollisionHUD"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=20
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")

local uiScale=Instance.new("UIScale")
uiScale.Name="ResponsiveScale"
uiScale.Parent=gui

local function refreshScale()
	local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
	local base=math.min(viewport.X/1200,viewport.Y/720)
	uiScale.Scale=math.clamp(base,.74,1.08)
end
refreshScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale) end

local function frame(name:string,size:UDim2,pos:UDim2,parent:Instance,background:Color3,transparency:number,corner:UDim)
	local f=Instance.new("Frame")
	f.Name=name
	f.Size=size
	f.Position=pos
	f.BackgroundColor3=background
	f.BackgroundTransparency=transparency
	f.BorderSizePixel=0
	f.Parent=parent
	local c=Instance.new("UICorner")
	c.CornerRadius=corner
	c.Parent=f
	return f
end

local function stroke(parent:Instance,color:Color3,transparency:number,thickness:number)
	local s=Instance.new("UIStroke")
	s.Color=color
	s.Transparency=transparency
	s.Thickness=thickness
	s.Parent=parent
	return s
end

local function label(name:string,text:string,size:UDim2,pos:UDim2,parent:Instance,textSize:number,color:Color3,font:Enum.Font,xAlign:Enum.TextXAlignment?)
	local l=Instance.new("TextLabel")
	l.Name=name
	l.Text=text
	l.Size=size
	l.Position=pos
	l.BackgroundTransparency=1
	l.Font=font
	l.TextSize=textSize
	l.TextColor3=color
	l.TextXAlignment=xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment=Enum.TextYAlignment.Center
	l.Parent=parent
	return l
end

local function button(name:string,text:string,size:UDim2,pos:UDim2,parent:Instance)
	local b=Instance.new("TextButton")
	b.Name=name
	b.Text=text
	b.Size=size
	b.Position=pos
	b.AutoButtonColor=false
	b.BackgroundColor3=Config.UI.PanelAlt
	b.BackgroundTransparency=.04
	b.BorderSizePixel=0
	b.Font=Theme.FontBold
	b.TextSize=14
	b.TextColor3=Config.UI.Text
	b.Parent=parent
	local c=Instance.new("UICorner")
	c.CornerRadius=Theme.Corner
	c.Parent=b
	stroke(b,Theme.Stroke,.5,1)
	return b
end

local identity=frame("Identity",UDim2.fromOffset(320,82),UDim2.fromOffset(18,18),gui,Config.UI.Panel,.08,Theme.Corner)
stroke(identity,Theme.Stroke,.55,1)
local avatar=frame("Avatar",UDim2.fromOffset(52,52),UDim2.fromOffset(12,15),identity,Config.UI.PanelSoft,.02,UDim.new(1,0))
label("Initial",string.sub(player.DisplayName,1,1):upper(),UDim2.fromScale(1,1),UDim2.fromScale(0,0),avatar,24,Config.UI.Accent,Theme.FontBold,Enum.TextXAlignment.Center)
local nameLabel=label("Name",player.DisplayName,UDim2.fromOffset(190,22),UDim2.fromOffset(76,9),identity,17,Config.UI.Text,Theme.FontBold)
local roleLabel=label("Role","RIFT FIGHTER",UDim2.fromOffset(190,16),UDim2.fromOffset(76,31),identity,10,Config.UI.Muted,Theme.FontSemi)
local hpBack=frame("HPBack",UDim2.fromOffset(214,9),UDim2.fromOffset(76,53),identity,Color3.fromRGB(50,55,64),0,UDim.new(0,5))
local hpFill=frame("HPFill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),hpBack,Config.UI.Danger,0,UDim.new(0,5))
local hpText=label("HPText","100 / 100",UDim2.fromOffset(90,16),UDim2.fromOffset(204,4),identity,10,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)

local quick=frame("QuickInfo",UDim2.fromOffset(330,36),UDim2.fromOffset(18,104),gui,Config.UI.Panel,.12,Theme.SmallCorner)
label("Location","ORIGIN PLAZA",UDim2.fromOffset(150,36),UDim2.fromOffset(12,0),quick,11,Config.UI.Muted,Theme.FontSemi)
local levelLabel=label("Level","LV 1",UDim2.fromOffset(68,36),UDim2.fromOffset(166,0),quick,11,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)
local creditsLabel=label("Credits","0 C",UDim2.fromOffset(78,36),UDim2.fromOffset(240,0),quick,11,Config.UI.Accent,Theme.FontBold,Enum.TextXAlignment.Right)

local mapButton=button("MapButton","MAP",UDim2.fromOffset(88,40),UDim2.new(1,-106,0,18),gui)
local menuButton=button("MenuButton","•••",UDim2.fromOffset(44,40),UDim2.new(1,-154,0,18),gui)

local notice=frame("Notice",UDim2.fromOffset(370,48),UDim2.new(.5,0,0,22),gui,Config.UI.Panel,.08,Theme.Corner)
notice.AnchorPoint=Vector2.new(.5,0)
notice.Visible=false
local noticeText=label("Text","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),notice,14,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)

local meter=frame("OverdriveMeter",UDim2.fromOffset(430,38),UDim2.new(.5,0,1,-92),gui,Config.UI.Panel,.09,Theme.SmallCorner)
meter.AnchorPoint=Vector2.new(.5,1)
local overBack=frame("Back",UDim2.new(1,-118,0,8),UDim2.fromOffset(96,15),meter,Color3.fromRGB(44,48,58),0,UDim.new(0,4))
local overFill=frame("Fill",UDim2.fromScale(0,1),UDim2.fromScale(0,0),overBack,Config.UI.Accent2,0,UDim.new(0,4))
label("Tag","OVERDRIVE",UDim2.fromOffset(82,24),UDim2.fromOffset(10,7),meter,10,Config.UI.Muted,Theme.FontBold)
local overText=label("Value","0%",UDim2.fromOffset(72,24),UDim2.new(1,-82,0,7),meter,10,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)

local actionBar=frame("ActionBar",UDim2.fromOffset(430,86),UDim2.new(.5,0,1,-4),gui,Config.UI.Panel,.09,Theme.Corner)
actionBar.AnchorPoint=Vector2.new(.5,1)
stroke(actionBar,Theme.Stroke,.58,1)
local slotButtons:{[string]:TextButton}={}
local slotCooldown:{[string]:TextLabel}={}
local holdBlock=false
for index,slot in ipairs(Definitions.Slots) do
	local x=(index-1)*102+8
	local b=button(slot.Id,slot.Label,UDim2.fromOffset(94,68),UDim2.fromOffset(x,9),actionBar)
	slotButtons[slot.Id]=b
	label("Hint",slot.Hint,UDim2.fromOffset(86,14),UDim2.fromOffset(4,4),b,9,Config.UI.Muted,Theme.FontBold,Enum.TextXAlignment.Right)
	local cd=label("Cooldown","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),b,18,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)
	slotCooldown[slot.Id]=cd
end

local mapPanel=frame("MapPanel",UDim2.fromOffset(420,400),UDim2.new(.5,0,.5,0),gui,Config.UI.Panel,.02,Theme.Corner)
mapPanel.AnchorPoint=Vector2.new(.5,.5)
mapPanel.Visible=false
stroke(mapPanel,Theme.Stroke,.42,1)
label("Title","BATTLE LINE",UDim2.fromOffset(220,28),UDim2.fromOffset(18,15),mapPanel,18,Config.UI.Text,Theme.FontBold)
label("Sub","Select a district to reposition",UDim2.fromOffset(270,20),UDim2.fromOffset(18,43),mapPanel,10,Config.UI.Muted,Theme.FontSemi)
local close=button("Close","×",UDim2.fromOffset(38,34),UDim2.new(1,-56,0,13),mapPanel)
for index,id in ipairs(Routes.Order) do
	local node=Routes.Nodes[id]
	local b=button(id,node.Name,UDim2.new(1,-36,0,52),UDim2.fromOffset(18,76+(index-1)*58),mapPanel)
	label("Desc",node.Subtitle,UDim2.new(1,-110,0,18),UDim2.fromOffset(12,27),b,10,Config.UI.Muted,Theme.FontSemi)
	local dot=frame("Dot",UDim2.fromOffset(8,8),UDim2.new(1,-22,0,22),b,node.Color,0,UDim.new(1,0))
	b.Activated:Connect(function() travel:FireServer(id) end)
end

local function setMapVisible(value:boolean)
	mapPanel.Visible=value
	if value then
		mapPanel.Position=UDim2.new(.5,0,.5,12)
		TweenService:Create(mapPanel,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,.5,0)}):Play()
	end
end

local function attack() combat:FireServer("Light") end
local function dash() combat:FireServer("Dash") end
local function blockStart() if not holdBlock then holdBlock=true;combat:FireServer("BlockStart") end end
local function blockEnd() if holdBlock then holdBlock=false;combat:FireServer("BlockEnd") end end
local function special() combat:FireServer("Special") end

slotButtons.Light.Activated:Connect(attack)
slotButtons.Dash.Activated:Connect(dash)
slotButtons.Special.Activated:Connect(special)
slotButtons.Block.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then blockStart() end
end)
slotButtons.Block.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then blockEnd() end
end)
mapButton.Activated:Connect(function() setMapVisible(not mapPanel.Visible) end)
menuButton.Activated:Connect(function() setMapVisible(false) end)
close.Activated:Connect(function() setMapVisible(false) end)

UserInputService.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then attack()
	elseif input.KeyCode==Definitions.Keybinds.Dash then dash()
	elseif input.KeyCode==Definitions.Keybinds.Block then blockStart()
	elseif input.KeyCode==Definitions.Keybinds.Special then special()
	elseif input.KeyCode==Definitions.Keybinds.Map then setMapVisible(not mapPanel.Visible)
	elseif input.KeyCode==Definitions.Keybinds.Sprint then movement:FireServer("Sprint",true)
	end
end)
UserInputService.InputEnded:Connect(function(input,gpe)
	if gpe then return end
	if input.KeyCode==Definitions.Keybinds.Block then blockEnd()
	elseif input.KeyCode==Definitions.Keybinds.Sprint then movement:FireServer("Sprint",false)
	end
end)

local function setNotice(textValue:string,duration:number)
	noticeText.Text=textValue
	notice.Visible=true
	local token=noticeText.Text
	task.delay(duration,function() if notice.Parent and noticeText.Text==token then notice.Visible=false end end)
end

local function updateHealth(character:Model)
	local humanoid=character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local function update()
		local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
		hpFill.Size=UDim2.new(ratio,0,1,0)
		hpText.Text=("%d / %d"):format(math.floor(humanoid.Health),math.floor(humanoid.MaxHealth))
	end
	humanoid.HealthChanged:Connect(update)
	update()
end

local function updateStats()
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	levelLabel.Text=("LV %d"):format(tonumber(player:GetAttribute("Level"))or 1)
	creditsLabel.Text=("%d C"):format(credits and credits:IsA("IntValue") and credits.Value or 0)
end

local function refreshOverdrive()
	local value=math.clamp(tonumber(player:GetAttribute("Overdrive"))or 0,0,100)
	overFill.Size=UDim2.new(value/100,0,1,0)
	overText.Text=("%d%%"):format(math.floor(value))
end

local function refreshLocation()
	local id=tostring(player:GetAttribute("CurrentMapNode")or "Origin")
	local node=Routes.Get(id)
	local loc=quick:FindFirstChild("Location")
	if loc and loc:IsA("TextLabel") and node then loc.Text=node.Name end
end

local function refreshCooldowns()
	local now=os.clock()
	local values={Light=player:GetAttribute("NextLight"),Dash=player:GetAttribute("NextDash"),Special=player:GetAttribute("NextSpecial")}
	for id,value in pairs(values) do
		local remaining=math.max(0,(tonumber(value)or 0)-now)
		local cd=slotCooldown[id]
		if cd then cd.Text=remaining>.02 and ("%.1f"):format(remaining) or "" end
	end
end

task.spawn(function()
	while gui.Parent do
		updateStats()
		refreshOverdrive()
		refreshLocation()
		refreshCooldowns()
		task.wait(.08)
	end
end)

player:GetAttributeChangedSignal("Level"):Connect(updateStats)
player:GetAttributeChangedSignal("Overdrive"):Connect(refreshOverdrive)
player:GetAttributeChangedSignal("CurrentMapNode"):Connect(refreshLocation)
local stats=player:WaitForChild("leaderstats")
local credits=stats:WaitForChild("Credits")
credits:GetPropertyChangedSignal("Value"):Connect(updateStats)

player.CharacterAdded:Connect(updateHealth)
if player.Character then updateHealth(player.Character) end

travelFeedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Success" and typeof(value)=="table" then
		setMapVisible(false)
		setNotice(value.Name.."  •  "..value.Subtitle,1.6)
	elseif kind=="Error" then
		setNotice(tostring(value),1.2)
	end
end)

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Parry" then setNotice("PARRY",.7)
	elseif kind=="GuardBreak" then setNotice("GUARD BREAK",.8)
	elseif kind=="Evade" then setNotice("EVADED",.55)
	elseif kind=="KOReward" then setNotice("+5 CREDITS",1)
	elseif kind=="LevelUp" then setNotice("LEVEL UP  •  LV "..tostring(value),1.4)
	elseif kind=="Special" and typeof(value)=="table" and value.Charged then setNotice("OVERDRIVE SPECIAL",1.1)
	end
end)

if UserInputService.TouchEnabled then
	actionBar.Size=UDim2.fromOffset(410,86)
	meter.Position=UDim2.new(.5,0,1,-98)
else
	actionBar.Size=UDim2.fromOffset(430,86)
end

GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function() refreshScale() end)
