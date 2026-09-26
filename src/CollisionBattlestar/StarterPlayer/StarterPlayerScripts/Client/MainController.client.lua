--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local combat=remotes:WaitForChild("CombatRequest")
local feedback=remotes:WaitForChild("Feedback")
local travel=remotes:WaitForChild("MapTravelRequest")
local travelFeedback=remotes:WaitForChild("MapTravelFeedback")
local Config=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)

local gui=Instance.new("ScreenGui")
gui.Name="CollisionHUD"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=10
gui.Parent=player:WaitForChild("PlayerGui")

local function frame(name:string,size:UDim2,pos:UDim2,parent:Instance,background:Color3,transparency:number)
	local f=Instance.new("Frame")
	f.Name=name
	f.Size=size
	f.Position=pos
	f.BackgroundColor3=background
	f.BackgroundTransparency=transparency
	f.BorderSizePixel=0
	f.Parent=parent
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,10)
	corner.Parent=f
	return f
end

local function label(name:string,text:string,size:UDim2,pos:UDim2,parent:Instance,textSize:number,color:Color3)
	local l=Instance.new("TextLabel")
	l.Name=name
	l.Text=text
	l.Size=size
	l.Position=pos
	l.BackgroundTransparency=1
	l.Font=Enum.Font.GothamSemibold
	l.TextSize=textSize
	l.TextColor3=color
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.Parent=parent
	return l
end

local function button(name:string,text:string,size:UDim2,pos:UDim2,parent:Instance)
	local b=Instance.new("TextButton")
	b.Name=name
	b.Text=text
	b.Size=size
	b.Position=pos
	b.BackgroundColor3=Config.UI.PanelAlt
	b.BackgroundTransparency=.05
	b.BorderSizePixel=0
	b.Font=Enum.Font.GothamBold
	b.TextSize=14
	b.TextColor3=Config.UI.Text
	b.AutoButtonColor=true
	b.Parent=parent
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,9)
	c.Parent=b
	local s=Instance.new("UIStroke")
	s.Thickness=1
	s.Color=Color3.fromRGB(55,61,72)
	s.Transparency=.2
	s.Parent=b
	return b
end

local status=frame("Status",UDim2.fromOffset(255,74),UDim2.fromOffset(16,16),gui,Config.UI.Panel,.06)
local hpLabel=label("HP","HP 100",UDim2.fromOffset(108,24),UDim2.fromOffset(12,8),status,16,Config.UI.Text)
local energyLabel=label("Energy","ENERGY 100",UDim2.fromOffset(120,20),UDim2.fromOffset(12,39),status,12,Config.UI.Muted)
local streakLabel=label("Streak","STREAK 0",UDim2.fromOffset(100,20),UDim2.fromOffset(143,39),status,12,Config.UI.Muted)

local mapButton=button("MapButton","MAP",UDim2.fromOffset(78,38),UDim2.new(1,-94,0,16),gui)
mapButton.AnchorPoint=Vector2.new(0,0)

local actionBar=frame("ActionBar",UDim2.fromOffset(332,64),UDim2.new(.5,0,1,-18),gui,Config.UI.Panel,.08)
actionBar.AnchorPoint=Vector2.new(.5,1)
local lightButton=button("Attack","ATTACK",UDim2.fromOffset(76,44),UDim2.fromOffset(8,10),actionBar)
local dashButton=button("Dash","DASH",UDim2.fromOffset(76,44),UDim2.fromOffset(88,10),actionBar)
local blockButton=button("Block","BLOCK",UDim2.fromOffset(76,44),UDim2.fromOffset(168,10),actionBar)
local specialButton=button("Special","SPECIAL",UDim2.fromOffset(76,44),UDim2.fromOffset(248,10),actionBar)

local mapPanel=frame("MapPanel",UDim2.fromOffset(300,240),UDim2.new(.5,0,.5,0),gui,Config.UI.Panel,.02)
mapPanel.AnchorPoint=Vector2.new(.5,.5)
mapPanel.Visible=false
label("Title","BATTLE LINE",UDim2.fromOffset(200,28),UDim2.fromOffset(18,16),mapPanel,18,Config.UI.Text)
local close=button("Close","X",UDim2.fromOffset(36,32),UDim2.new(1,-52,0,14),mapPanel)
local nodeButtons={}
for index,id in ipairs(Routes.Order) do
	local node=Routes.Nodes[id]
	local b=button(id,node.Name,UDim2.new(1,-36,0,46),UDim2.fromOffset(18,52+(index-1)*54),mapPanel)
	b.Activated:Connect(function()
		travel:FireServer(id)
	end)
	nodeButtons[id]=b
end

local function setMapVisible(value:boolean)
	mapPanel.Visible=value
end

local function attack()
	combat:FireServer("Light")
end

local function dash()
	combat:FireServer("Dash")
end

local function blockStart()
	combat:FireServer("BlockStart")
end

local function blockEnd()
	combat:FireServer("BlockEnd")
end

local function special()
	combat:FireServer("Special")
end

lightButton.Activated:Connect(attack)
dashButton.Activated:Connect(dash)
specialButton.Activated:Connect(special)
blockButton.MouseButton1Down:Connect(blockStart)
blockButton.MouseButton1Up:Connect(blockEnd)
blockButton.TouchLongPress:Connect(function(_,state)
	if state==Enum.UserInputState.Begin then blockStart() else blockEnd() end
end)
mapButton.Activated:Connect(function()
	setMapVisible(not mapPanel.Visible)
end)
close.Activated:Connect(function()
	setMapVisible(false)
end)

UserInputService.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then attack()
	elseif input.KeyCode==Enum.KeyCode.Q then dash()
	elseif input.KeyCode==Enum.KeyCode.F then blockStart()
	elseif input.KeyCode==Enum.KeyCode.R then special()
	elseif input.KeyCode==Enum.KeyCode.M then setMapVisible(not mapPanel.Visible)
	elseif input.KeyCode==Enum.KeyCode.LeftShift then combat:FireServer("Sprint",true)
	end
end)

UserInputService.InputEnded:Connect(function(input,gpe)
	if gpe then return end
	if input.KeyCode==Enum.KeyCode.F then blockEnd()
	elseif input.KeyCode==Enum.KeyCode.LeftShift then combat:FireServer("Sprint",false) end
end)

local function bindCharacter(character:Model)
	local humanoid=character:WaitForChild("Humanoid",8)
	if not humanoid or not humanoid:IsA("Humanoid") then return end
	local function update()
		hpLabel.Text=("HP %d"):format(math.floor(humanoid.Health))
	end
	humanoid.HealthChanged:Connect(update)
	update()
end

local function bindStats()
	local stats=player:WaitForChild("leaderstats")
	local streak=stats:WaitForChild("Streak")
	streak:GetPropertyChangedSignal("Value"):Connect(function()
		streakLabel.Text=("STREAK %d"):format(streak.Value)
	end)
	streakLabel.Text=("STREAK %d"):format(streak.Value)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end
task.spawn(bindStats)

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Hit" then
		energyLabel.Text="ENERGY 100"
	elseif kind=="Special" then
		energyLabel.Text="SPECIAL FIRED"
		task.delay(1,function()
			if energyLabel.Parent then energyLabel.Text="ENERGY 100" end
		end)
	elseif kind=="Block" then
		energyLabel.Text=value==true and "BLOCKING" or "ENERGY 100"
	elseif kind=="Parry" then
		energyLabel.Text="PARRY"
		task.delay(.8,function()
			if energyLabel.Parent then energyLabel.Text="ENERGY 100" end
		end)
	end
end)

travelFeedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Success" then
		setMapVisible(false)
		energyLabel.Text=tostring(value)
		task.delay(1.4,function()
			if energyLabel.Parent then energyLabel.Text="ENERGY 100" end
		end)
	end
end)

if not UserInputService.TouchEnabled then
	actionBar.Visible=false
end
