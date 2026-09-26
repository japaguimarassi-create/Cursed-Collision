--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local Config=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Definitions=require(ReplicatedStorage.Shared.CombatDefinitions)
local Theme=require(ReplicatedStorage.Shared.HUDTheme)

local M={}
local created=false

local function frame(name:string,size:UDim2,pos:UDim2,parent:Instance,background:Color3,transparency:number,corner:UDim):Frame
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
end

local function label(name:string,textValue:string,size:UDim2,pos:UDim2,parent:Instance,textSize:number,color:Color3,font:Enum.Font,align:Enum.TextXAlignment?)
	local l=Instance.new("TextLabel")
	l.Name=name
	l.Text=textValue
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

local function button(name:string,textValue:string,size:UDim2,pos:UDim2,parent:Instance):TextButton
	local b=Instance.new("TextButton")
	b.Name=name
	b.Text=textValue
	b.Size=size
	b.Position=pos
	b.BackgroundColor3=Config.UI.PanelAlt
	b.BackgroundTransparency=.04
	b.BorderSizePixel=0
	b.AutoButtonColor=false
	b.Font=Theme.FontBold
	b.TextSize=13
	b.TextColor3=Config.UI.Text
	b.Parent=parent
	local c=Instance.new("UICorner")
	c.CornerRadius=Theme.Corner
	c.Parent=b
	stroke(b,Theme.Stroke,.55,1)
	local scale=Instance.new("UIScale")
	scale.Parent=b
	b.MouseEnter:Connect(function()
		TweenService:Create(scale,TweenInfo.new(.09,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1.03}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(scale,TweenInfo.new(.09,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
	end)
	return b
end

local function build():ScreenGui?
	if created then
		local existing=player.PlayerGui:FindFirstChild("CollisionHUD")
		if existing and existing:IsA("ScreenGui") then return existing end
	end
	local existing=player.PlayerGui:FindFirstChild("CollisionHUD")
	if existing then
		existing:Destroy()
	end

	local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
	local combat=remotes:WaitForChild("CombatRequest")
	local movement=remotes:WaitForChild("MovementRequest")
	local travel=remotes:WaitForChild("MapTravelRequest")
	local travelFeedback=remotes:WaitForChild("MapTravelFeedback")
	local feedback=remotes:WaitForChild("Feedback")

	local gui=Instance.new("ScreenGui")
	gui.Name="CollisionHUD"
	gui.ResetOnSpawn=false
	gui.IgnoreGuiInset=false
	gui.DisplayOrder=20
	gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("ManagedByFallback",true)
	gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
	gui.Parent=player.PlayerGui

	local scale=Instance.new("UIScale")
	scale.Name="ResponsiveScale"
	scale.Parent=gui

	local function refreshScale()
		local camera=workspace.CurrentCamera
		local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
		scale.Scale=math.clamp(math.min(viewport.X/1200,viewport.Y/720),.72,1.08)
	end
	refreshScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
	end

	local identity=frame("Identity",UDim2.fromOffset(320,82),UDim2.fromOffset(18,18),gui,Config.UI.Panel,.08,Theme.Corner)
	stroke(identity,Theme.Stroke,.55,1)
	frame("Avatar",UDim2.fromOffset(52,52),UDim2.fromOffset(12,15),identity,Config.UI.PanelSoft,.02,UDim.new(1,0))
	label("Initial",string.sub(player.DisplayName,1,1):upper(),UDim2.fromScale(1,1),UDim2.fromScale(0,0),identity:FindFirstChild("Avatar") or identity,24,Config.UI.Accent,Theme.FontBold,Enum.TextXAlignment.Center)
	label("Name",player.DisplayName,UDim2.fromOffset(190,22),UDim2.fromOffset(76,9),identity,17,Config.UI.Text,Theme.FontBold)
	label("Role","RIFT FIGHTER",UDim2.fromOffset(190,16),UDim2.fromOffset(76,31),identity,10,Config.UI.Muted,Theme.FontSemi)
	local hpBack=frame("HPBack",UDim2.fromOffset(214,9),UDim2.fromOffset(76,53),identity,Color3.fromRGB(50,55,64),0,UDim.new(0,5))
	frame("HPFill",UDim2.fromScale(1,1),UDim2.fromScale(0,0),hpBack,Config.UI.Danger,0,UDim.new(0,5))
	label("HPText","100 / 100",UDim2.fromOffset(90,16),UDim2.fromOffset(204,3),identity,10,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)

	local quick=frame("QuickInfo",UDim2.fromOffset(330,36),UDim2.fromOffset(18,104),gui,Config.UI.Panel,.12,Theme.SmallCorner)
	label("Location","ORIGIN PLAZA",UDim2.fromOffset(150,36),UDim2.fromOffset(12,0),quick,11,Config.UI.Muted,Theme.FontSemi)
	label("Level","LV 1",UDim2.fromOffset(68,36),UDim2.fromOffset(166,0),quick,11,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)
	label("Credits","0 C",UDim2.fromOffset(78,36),UDim2.fromOffset(240,0),quick,11,Config.UI.Accent,Theme.FontBold,Enum.TextXAlignment.Right)

	local mapButton=button("MapButton","MAP",UDim2.fromOffset(84,40),UDim2.new(1,-102,0,18),gui)
	local menuButton=button("MenuButton","•••",UDim2.fromOffset(44,40),UDim2.new(1,-154,0,18),gui)

	local meter=frame("OverdriveMeter",UDim2.fromOffset(430,38),UDim2.new(.5,0,1,-92),gui,Config.UI.Panel,.09,Theme.SmallCorner)
	meter.AnchorPoint=Vector2.new(.5,1)
	frame("Back",UDim2.new(1,-118,0,8),UDim2.fromOffset(96,15),meter,Color3.fromRGB(44,48,58),0,UDim.new(0,4))
	frame("Fill",UDim2.fromScale(0,1),UDim2.fromScale(0,0),meter:FindFirstChild("Back") or meter,Config.UI.Accent2,0,UDim.new(0,4))
	label("Tag","OVERDRIVE",UDim2.fromOffset(82,24),UDim2.fromOffset(10,7),meter,10,Config.UI.Muted,Theme.FontBold)
	label("Value","0%",UDim2.fromOffset(72,24),UDim2.new(1,-82,0,7),meter,10,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Right)

	local actionBar=frame("ActionBar",UDim2.fromOffset(430,86),UDim2.new(.5,0,1,-4),gui,Config.UI.Panel,.09,Theme.Corner)
	actionBar.AnchorPoint=Vector2.new(.5,1)
	stroke(actionBar,Theme.Stroke,.58,1)
	local slots:{[string]:TextButton}={}
	for index,slot in ipairs(Definitions.Slots) do
		local b=button(slot.Id,slot.Label,UDim2.fromOffset(94,68),UDim2.fromOffset(8+(index-1)*102,9),actionBar)
		slots[slot.Id]=b
		label("Hint",slot.Hint,UDim2.fromOffset(86,14),UDim2.fromOffset(4,4),b,9,Config.UI.Muted,Theme.FontBold,Enum.TextXAlignment.Right)
		label("Cooldown","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),b,18,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)
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
		b.Activated:Connect(function() travel:FireServer(id) end)
	end

	local toast=frame("Notice",UDim2.fromOffset(370,48),UDim2.new(.5,0,0,22),gui,Config.UI.Panel,.08,Theme.Corner)
	toast.AnchorPoint=Vector2.new(.5,0)
	toast.Visible=false
	local toastText=label("Text","",UDim2.fromScale(1,1),UDim2.fromScale(0,0),toast,14,Config.UI.Text,Theme.FontBold,Enum.TextXAlignment.Center)

	local holdBlock=false
	local function blockStart()
		if not holdBlock then holdBlock=true;combat:FireServer("BlockStart") end
	end
	local function blockEnd()
		if holdBlock then holdBlock=false;combat:FireServer("BlockEnd") end
	end
	slots.Light.Activated:Connect(function() combat:FireServer("Light") end)
	slots.Dash.Activated:Connect(function() combat:FireServer("Dash") end)
	slots.Special.Activated:Connect(function() combat:FireServer("Special") end)
	slots.Block.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then blockStart() end
	end)
	slots.Block.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then blockEnd() end
	end)
	mapButton.Activated:Connect(function() mapPanel.Visible=not mapPanel.Visible end)
	menuButton.Activated:Connect(function() mapPanel.Visible=false end)
	close.Activated:Connect(function() mapPanel.Visible=false end)

	UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("Light")
		elseif input.KeyCode==Definitions.Keybinds.Dash then combat:FireServer("Dash")
		elseif input.KeyCode==Definitions.Keybinds.Block then blockStart()
		elseif input.KeyCode==Definitions.Keybinds.Special then combat:FireServer("Special")
		elseif input.KeyCode==Definitions.Keybinds.Map then mapPanel.Visible=not mapPanel.Visible
		elseif input.KeyCode==Definitions.Keybinds.Sprint then movement:FireServer("Sprint",true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode==Definitions.Keybinds.Block then blockEnd()
		elseif input.KeyCode==Definitions.Keybinds.Sprint then movement:FireServer("Sprint",false)
		end
	end)

	local function setToast(textValue:string,duration:number)
		toastText.Text=textValue
		toast.Visible=true
		local token=textValue
		task.delay(duration,function() if toast.Parent and toastText.Text==token then toast.Visible=false end end)
	end

	local function update()
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
			local hpFill=identity:FindFirstChild("HPBack") and identity.HPBack:FindFirstChild("HPFill")
			local hpText=identity:FindFirstChild("HPText")
			if hpFill and hpFill:IsA("Frame") then hpFill.Size=UDim2.new(ratio,0,1,0) end
			if hpText and hpText:IsA("TextLabel") then hpText.Text=("%d / %d"):format(math.floor(humanoid.Health),math.floor(humanoid.MaxHealth)) end
		end
		local stats=player:FindFirstChild("leaderstats")
		local credits=stats and stats:FindFirstChild("Credits")
		local level=quick:FindFirstChild("Level")
		local creditText=quick:FindFirstChild("Credits")
		if level and level:IsA("TextLabel") then level.Text=("LV %d"):format(tonumber(player:GetAttribute("Level")) or 1) end
		if creditText and creditText:IsA("TextLabel") then creditText.Text=("%d C"):format(credits and credits:IsA("IntValue") and credits.Value or 0) end
		local over=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
		local back=meter:FindFirstChild("Back")
		local fill=back and back:FindFirstChild("Fill")
		local value=meter:FindFirstChild("Value")
		if fill and fill:IsA("Frame") then fill.Size=UDim2.new(over/100,0,1,0) end
		if value and value:IsA("TextLabel") then value.Text=("%d%%"):format(math.floor(over)) end
		local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
		local loc=quick:FindFirstChild("Location")
		if node and loc and loc:IsA("TextLabel") then loc.Text=node.Name end
		local now=os.clock()
		local map={Light=player:GetAttribute("NextLight"),Dash=player:GetAttribute("NextDash"),Special=player:GetAttribute("NextSpecial")}
		for name,valueAttr in pairs(map) do
			local b=slots[name]
			local cd=b and b:FindFirstChild("Cooldown")
			if cd and cd:IsA("TextLabel") then
				local remaining=math.max(0,(tonumber(valueAttr) or 0)-now)
				cd.Text=remaining>.02 and ("%.1f"):format(remaining) or ""
			end
		end
	end

	player.CharacterAdded:Connect(function(char) char:WaitForChild("Humanoid",8) end)
	travelFeedback.OnClientEvent:Connect(function(kind:string,value:any)
		if kind=="Success" and typeof(value)=="table" then
			mapPanel.Visible=false
			setToast(value.Name.."  •  "..value.Subtitle,1.6)
		elseif kind=="Error" then
			setToast(tostring(value),1.2)
		end
	end)
	feedback.OnClientEvent:Connect(function(kind:string,value:any)
		if kind=="Parry" then setToast("PARRY",.7)
		elseif kind=="GuardBreak" then setToast("GUARD BREAK",.8)
		elseif kind=="Evade" then setToast("EVADED",.55)
		elseif kind=="KOReward" then setToast("+5 CREDITS",1)
		elseif kind=="LevelUp" then setToast("LEVEL UP  •  LV "..tostring(value),1.4)
		elseif kind=="Special" and typeof(value)=="table" and value.Charged then setToast("OVERDRIVE SPECIAL",1.1)
		end
	end)

	task.spawn(function()
		while gui.Parent do
			update()
			task.wait(.1)
		end
	end)

	created=true
	return gui
end

function M.Build():ScreenGui?
	local ok,result=pcall(build)
	if ok and result then return result end
	return nil
end

function M.IsReady():boolean
	local gui=player.PlayerGui:FindFirstChild("CollisionHUD")
	if not gui or not gui:IsA("ScreenGui") then return false end
	local action=gui:FindFirstChild("ActionBar")
	return gui:FindFirstChild("Identity")~=nil and action~=nil and gui:FindFirstChild("OverdriveMeter")~=nil and action:FindFirstChild("Light")~=nil and action:FindFirstChild("Dash")~=nil and action:FindFirstChild("Block")~=nil and action:FindFirstChild("Special")~=nil
end

return M
