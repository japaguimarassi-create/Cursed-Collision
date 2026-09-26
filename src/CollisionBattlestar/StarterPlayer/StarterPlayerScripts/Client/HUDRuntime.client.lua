--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local combat=remotes:WaitForChild("CombatRequest")
local movement=remotes:WaitForChild("MovementRequest")
local travel=remotes:WaitForChild("MapTravelRequest")
local feedback=remotes:WaitForChild("Feedback")
local travelFeedback=remotes:WaitForChild("MapTravelFeedback")
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Config=require(ReplicatedStorage.Shared.Config)
local HUDLayout=require(ReplicatedStorage.Shared.UI.HUDLayout)

local gui=HUDLayout.Build()
gui.Parent=playerGui

local status=gui:WaitForChild("StatusFrame")
local healthBack=status:WaitForChild("HealthBackground")
local healthFill=healthBack:WaitForChild("Fill")
local healthText=healthBack:WaitForChild("HealthText")
local energyBack=status:WaitForChild("EnergyBackground")
local energyFill=energyBack:WaitForChild("Fill")
local ultBack=status:WaitForChild("UltBackground")
local ultFill=ultBack:WaitForChild("Fill")
local ultText=ultBack:WaitForChild("UltText")
local profile=status:WaitForChild("Profile")
local initial=profile:WaitForChild("Initial")
local nameLabel=status:WaitForChild("Name")
local quick=gui:WaitForChild("QuickInfo")
local locationLabel=quick:WaitForChild("Location")
local levelLabel=quick:WaitForChild("Level")
local creditsLabel=quick:WaitForChild("Credits")
local hotbar=gui:WaitForChild("Hotbar")
local mobile=gui:WaitForChild("MobileActions")
local controllerHints=gui:WaitForChild("ControllerHints")
local mapPanel=gui:WaitForChild("MapPanel")
local centerState=gui:WaitForChild("CenterState")
local comboLabel=centerState:WaitForChild("Combo")
local toast=gui:WaitForChild("Notice")
local toastText=toast:WaitForChild("Text")

local actionButtons:{[string]:TextButton}={}
for _,name in ipairs({"Light","Dash","Block","Special"}) do
	local button=hotbar:WaitForChild(name)
	if button:IsA("TextButton") then actionButtons[name]=button end
end

local function findText(parent:Instance,name:string):TextLabel?
	local x=parent:FindFirstChild(name)
	return x and x:IsA("TextLabel") and x or nil
end

local function setButtonState(button:GuiButton,ready:boolean)
	local state=findText(button,"State")
	if state then state.Text=ready and "READY" or "LOCKED" end
	button.BackgroundTransparency=ready and .03 or .22
end

local function cooldown(button:GuiButton,nextTime:any)
	local cd=findText(button,"Cooldown")
	local state=findText(button,"State")
	if not cd or not state then return end
	local remaining=math.max(0,(tonumber(nextTime) or 0)-os.clock())
	cd.Text=remaining>.02 and ("%.1f"):format(remaining) or ""
	if remaining>.02 then state.Text="COOLDOWN" else state.Text="READY" end
end

local function toastMessage(message:string,duration:number)
	toastText.Text=message
	toast.Visible=true
	local token=message
	task.delay(duration,function()
		if toast.Parent and toastText.Text==token then toast.Visible=false end
	end)
end

local function healthUpdate()
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		healthFill.Size=UDim2.fromScale(0,1)
		healthText.Text="0 / 0"
		return
	end
	local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
	healthFill.Size=UDim2.new(ratio,0,1,0)
	healthText.Text=("%d / %d"):format(math.floor(humanoid.Health),math.floor(humanoid.MaxHealth))
end

local function energyUpdate()
	local maxEnergy=math.max(1,tonumber(player:GetAttribute("MaxEnergy")) or 100)
	local energy=math.clamp(tonumber(player:GetAttribute("Energy")) or maxEnergy,0,maxEnergy)
	energyFill.Size=UDim2.new(energy/maxEnergy,0,1,0)
	local energyText=findText(energyBack,"EnergyText")
	if energyText then energyText.Text=("ENERGY %d"):format(math.floor(energy)) end
end

local function awakeningUpdate()
	local value=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
	ultFill.Size=UDim2.new(value/100,0,1,0)
	ultText.Text=value>=100 and "AWAKENING READY  •  G" or ("AWAKENING %d%%"):format(math.floor(value))
	ultText.TextColor3=value>=100 and Color3.fromRGB(255,215,0) or Config.UI.Text
end

local function statsUpdate()
	initial.Text=string.sub(player.DisplayName,1,1):upper()
	nameLabel.Text=player.DisplayName
	levelLabel.Text=("LV %d"):format(tonumber(player:GetAttribute("Level")) or 1)
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	creditsLabel.Text=("%d C"):format(credits and credits:IsA("IntValue") and credits.Value or 0)
	local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
	locationLabel.Text=node and node.Name or "ORIGIN PLAZA"
end

local function comboUpdate()
	local combo=tonumber(player:GetAttribute("Combo")) or 0
	comboLabel.Text=("COMBO %d"):format(combo)
end

local function setMap(value:boolean)
	mapPanel.Visible=value
end

local function setPlatform()
	local preferred=UserInputService.PreferredInput
	local touch=preferred==Enum.PreferredInput.Touch
	local gamepad=preferred==Enum.PreferredInput.Gamepad or preferred==Enum.PreferredInput.MicroGamepad
	hotbar.Visible=not touch
	mobile.Visible=touch
	controllerHints.Visible=gamepad
	if touch then
		local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
		local compact=viewport.X<900
		mobile.Size=compact and UDim2.fromOffset(178,238) or UDim2.fromOffset(190,252)
		mobile.Position=UDim2.new(1,-12,.5,18)
	elseif gamepad then
		GuiService.GuiNavigationEnabled=true
		local first=actionButtons.Light
		if first then GuiService.SelectedObject=first end
	else
		GuiService.GuiNavigationEnabled=false
	end
	controllerHints.Visible=gamepad
end

local function mobileAction(name:string)
	if name=="MobileM1" then combat:FireServer("Light")
	elseif name=="MobileGuard" then combat:FireServer("BlockStart")
	elseif name=="MobileDash" then combat:FireServer("Dash")
	elseif name=="MobileSpecial" then combat:FireServer("Special") end
end

for _,button in pairs(actionButtons) do
	button.Activated:Connect(function()
		local id=button:GetAttribute("ActionId")
		if id=="Light" then combat:FireServer("Light")
		elseif id=="Dash" then combat:FireServer("Dash")
		elseif id=="Special" then combat:FireServer("Special")
		end
	end)
end

local blockButton=actionButtons.Block
if blockButton then
	blockButton.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonL2 then
			combat:FireServer("BlockStart")
		end
	end)
	blockButton.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonL2 then
			combat:FireServer("BlockEnd")
		end
	end)
end

for _,name in ipairs({"MobileM1","MobileDash","MobileSpecial"}) do
	local button=mobile:FindFirstChild(name)
	if button and button:IsA("TextButton") then button.Activated:Connect(function() mobileAction(name) end) end
end

local mobileGuard=mobile:FindFirstChild("MobileGuard")
if mobileGuard and mobileGuard:IsA("TextButton") then
	mobileGuard.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("BlockStart") end
	end)
	mobileGuard.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("BlockEnd") end
	end)
end

local mapButton=gui:WaitForChild("UtilityBar"):WaitForChild("MapButton")
local menuButton=gui.UtilityBar.MenuButton
local pingButton=gui.UtilityBar.PingButton
mapButton.Activated:Connect(function() setMap(not mapPanel.Visible) end)
menuButton.Activated:Connect(function() setMap(false);toastMessage("MENU",.7) end)
pingButton.Activated:Connect(function() toastMessage("PING",.7) end)
local close=mapPanel:WaitForChild("Close")
if close:IsA("TextButton") then close.Activated:Connect(function() setMap(false) end) end
for _,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
	local button=mapPanel:FindFirstChild(id)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(function() travel:FireServer(id) end)
	end
end

local function keyboardInput()
	UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("Light")
		elseif input.KeyCode==Enum.KeyCode.Q then combat:FireServer("Dash")
		elseif input.KeyCode==Enum.KeyCode.F then combat:FireServer("BlockStart")
		elseif input.KeyCode==Enum.KeyCode.R then combat:FireServer("Special")
		elseif input.KeyCode==Enum.KeyCode.M then setMap(not mapPanel.Visible)
		elseif input.KeyCode==Enum.KeyCode.LeftShift then movement:FireServer("Sprint",true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode==Enum.KeyCode.F then combat:FireServer("BlockEnd")
		elseif input.KeyCode==Enum.KeyCode.LeftShift then movement:FireServer("Sprint",false)
		end
	end)
end
keyboardInput()

local function characterBind(character:Model)
	local humanoid=character:WaitForChild("Humanoid",8)
	if humanoid and humanoid:IsA("Humanoid") then humanoid.HealthChanged:Connect(healthUpdate) end
	healthUpdate()
end

player.CharacterAdded:Connect(characterBind)
if player.Character then characterBind(player.Character) end
for _,attribute in ipairs({"Level","Overdrive","Energy","MaxEnergy","CurrentMapNode","Combo"}) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		statsUpdate()
		energyUpdate()
		awakeningUpdate()
		comboUpdate()
	end)
end
local stats=player:WaitForChild("leaderstats")
local credits=stats:WaitForChild("Credits")
credits:GetPropertyChangedSignal("Value"):Connect(statsUpdate)

travelFeedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Success" and typeof(value)=="table" then
		setMap(false)
		toastMessage(value.Name.."  •  "..value.Subtitle,1.5)
	elseif kind=="Error" then
		toastMessage(tostring(value),1.1)
	end
end)

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Parry" then toastMessage("PARRY",.65)
	elseif kind=="GuardBreak" then toastMessage("GUARD BREAK",.8)
	elseif kind=="Evade" then toastMessage("EVADED",.55)
	elseif kind=="KOReward" then toastMessage("+5 CREDITS",.9)
	elseif kind=="LevelUp" then toastMessage("LEVEL UP  •  LV "..tostring(value),1.3)
	elseif kind=="Special" and typeof(value)=="table" and value.Charged then toastMessage("OVERDRIVE SPECIAL",1)
	end
end)

task.spawn(function()
	while gui.Parent do
		healthUpdate()
		energyUpdate()
		awakeningUpdate()
		statsUpdate()
		comboUpdate()
		for name,button in pairs(actionButtons) do
			local attr=name=="Light" and "NextLight" or name=="Dash" and "NextDash" or name=="Special" and "NextSpecial" or ""
			if attr~="" then cooldown(button,player:GetAttribute(attr)) end
		end
		task.wait(.1)
	end
end)

local function resize()
	local camera=workspace.CurrentCamera
	local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
	local uiScale=gui:FindFirstChild("ResponsiveScale")
	if uiScale and uiScale:IsA("UIScale") then
		uiScale.Scale=math.clamp(math.min(viewport.X/1200,viewport.Y/720),.70,1.08)
	end
end
local camera=workspace.CurrentCamera
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(setPlatform)
resize()
setPlatform()
gui:SetAttribute("HUDRuntimeReady",true)
player:SetAttribute("HUDRuntimeReady",true)
