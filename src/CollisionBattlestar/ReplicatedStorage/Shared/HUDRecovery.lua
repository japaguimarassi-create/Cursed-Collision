--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local HUDLayout=require(ReplicatedStorage.Shared.UI.HUDLayout)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Config=require(ReplicatedStorage.Shared.Config)

local M={}
local gui:ScreenGui?
local connections:{RBXScriptConnection}={}
local cooldownRunning=false

local function disconnectAll()
	for _,c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
end

local function findLabel(parent:Instance?,name:string):TextLabel?
	local item=parent and parent:FindFirstChild(name)
	return item and item:IsA("TextLabel") and item or nil
end

local function refreshHealth()
	local g=gui
	if not g then return end
	local status=g:FindFirstChild("StatusFrame")
	local back=status and status:FindFirstChild("HealthBackground")
	local fill=back and back:FindFirstChild("Fill")
	local label=findLabel(back,"HealthText")
	if not fill or not fill:IsA("Frame") or not label then return end
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		fill.Size=UDim2.fromScale(0,1)
		label.Text="0 / 0"
		return
	end
	local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
	fill.Size=UDim2.new(ratio,0,1,0)
	label.Text=("%d / %d"):format(math.floor(humanoid.Health),math.floor(humanoid.MaxHealth))
end

local function refreshState()
	local g=gui
	if not g then return end
	local status=g:FindFirstChild("StatusFrame")
	local energyBack=status and status:FindFirstChild("EnergyBackground")
	local energyFill=energyBack and energyBack:FindFirstChild("Fill")
	local energyText=findLabel(energyBack,"EnergyText")
	local ultBack=status and status:FindFirstChild("UltBackground")
	local ultFill=ultBack and ultBack:FindFirstChild("Fill")
	local ultText=findLabel(ultBack,"UltText")
	local quick=g:FindFirstChild("QuickInfo")
	if energyFill and energyFill:IsA("Frame") then
		local maxEnergy=math.max(1,tonumber(player:GetAttribute("MaxEnergy")) or 100)
		local energy=math.clamp(tonumber(player:GetAttribute("Energy")) or maxEnergy,0,maxEnergy)
		energyFill.Size=UDim2.new(energy/maxEnergy,0,1,0)
		if energyText then energyText.Text=("ENERGY %d"):format(math.floor(energy)) end
	end
	if ultFill and ultFill:IsA("Frame") then
		local over=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
		ultFill.Size=UDim2.new(over/100,0,1,0)
		if ultText then
			ultText.Text=over>=100 and "AWAKENING READY" or ("AWAKENING %d%%"):format(math.floor(over))
			ultText.TextColor3=over>=100 and Color3.fromRGB(255,215,0) or Config.UI.Text
		end
	end
	if quick and quick:IsA("Frame") then
		local level=quick:FindFirstChild("Level")
		local credits=quick:FindFirstChild("Credits")
		local location=quick:FindFirstChild("Location")
		if level and level:IsA("TextLabel") then level.Text=("LV %d"):format(tonumber(player:GetAttribute("Level")) or 1) end
		local stats=player:FindFirstChild("leaderstats")
		local creditValue=stats and stats:FindFirstChild("Credits")
		if credits and credits:IsA("TextLabel") then credits.Text=("%d C"):format(creditValue and creditValue:IsA("IntValue") and creditValue.Value or 0) end
		local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
		if location and location:IsA("TextLabel") then location.Text=node and node.Name or "ORIGIN PLAZA" end
	end
	local center=g:FindFirstChild("CenterState")
	local combo=findLabel(center,"Combo")
	if combo then combo.Text=("COMBO %d"):format(tonumber(player:GetAttribute("Combo")) or 0) end
end

local function refreshCooldowns()
	local g=gui
	if not g then return end
	local hotbar=g:FindFirstChild("Hotbar")
	if not hotbar then return end
	local now=os.clock()
	for name,attribute in pairs({Light="NextLight",Dash="NextDash",Special="NextSpecial"}) do
		local button=hotbar:FindFirstChild(name)
		local cd=findLabel(button,"Cooldown")
		local state=findLabel(button,"State")
		if cd and state then
			local remaining=math.max(0,(tonumber(player:GetAttribute(attribute)) or 0)-now)
			cd.Text=remaining>.02 and ("%.1f"):format(remaining) or ""
			state.Text=remaining>.02 and "COOLDOWN" or "READY"
		end
	end
end

local function refreshPlatform()
	local g=gui
	if not g then return end
	local hotbar=g:FindFirstChild("Hotbar")
	local mobile=g:FindFirstChild("MobileActions")
	local hints=g:FindFirstChild("ControllerHints")
	if not hotbar or not mobile or not hints then return end
	local preferred=UserInputService.PreferredInput
	local touch=preferred==Enum.PreferredInput.Touch
	local gamepad=preferred==Enum.PreferredInput.Gamepad or preferred==Enum.PreferredInput.MicroGamepad
	hotbar.Visible=not touch
	mobile.Visible=touch
	hints.Visible=gamepad
	if touch then
		local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
		mobile.Position=UDim2.new(1,-10,.5,25)
		mobile.Size=viewport.X<900 and UDim2.fromOffset(178,238) or UDim2.fromOffset(190,250)
	elseif gamepad then
		GuiService.GuiNavigationEnabled=true
		local first=hotbar:FindFirstChild("Light")
		if first and first:IsA("GuiButton") then GuiService.SelectedObject=first end
	else
		GuiService.GuiNavigationEnabled=false
	end
end

local function toast(message:string,duration:number)
	local g=gui
	local notice=g and g:FindFirstChild("Notice")
	local label=findLabel(notice,"Text")
	if not notice or not label then return end
	label.Text=message
	notice.Visible=true
	task.delay(duration,function()
		if gui==g and notice.Parent and label.Text==message then notice.Visible=false end
	end)
end

local function bindInput()
	local combat=remotes:WaitForChild("CombatRequest")
	local movement=remotes:WaitForChild("MovementRequest")
	local travel=remotes:WaitForChild("MapTravelRequest")
	local g=gui
	if not g then return end
	local hotbar=g:WaitForChild("Hotbar")
	local mobile=g:WaitForChild("MobileActions")
	local utility=g:WaitForChild("UtilityBar")
	local mapPanel=g:WaitForChild("MapPanel")

	table.insert(connections,hotbar.Light.Activated:Connect(function() combat:FireServer("Light") end))
	table.insert(connections,hotbar.Dash.Activated:Connect(function() combat:FireServer("Dash") end))
	table.insert(connections,hotbar.Special.Activated:Connect(function() combat:FireServer("Special") end))

	local blockHeld=false
	table.insert(connections,hotbar.Block.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonL2 then
			if not blockHeld then blockHeld=true;combat:FireServer("BlockStart") end
		end
	end))
	table.insert(connections,hotbar.Block.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonL2 then
			blockHeld=false
			combat:FireServer("BlockEnd")
		end
	end))

	for _,entry in ipairs({{"MobileM1","Light"},{"MobileDash","Dash"},{"MobileSpecial","Special"}}) do
		local button=mobile:FindFirstChild(entry[1])
		if button and button:IsA("GuiButton") then
			table.insert(connections,button.Activated:Connect(function() combat:FireServer(entry[2]) end))
		end
	end
	local guard=mobile:FindFirstChild("MobileGuard")
	if guard and guard:IsA("GuiButton") then
		table.insert(connections,guard.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
				if not blockHeld then blockHeld=true;combat:FireServer("BlockStart") end
			end
		end))
		table.insert(connections,guard.InputEnded:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
				blockHeld=false;combat:FireServer("BlockEnd")
			end
		end))
	end

	local mapButton=utility:FindFirstChild("MapButton")
	local menuButton=utility:FindFirstChild("MenuButton")
	local pingButton=utility:FindFirstChild("PingButton")
	if mapButton and mapButton:IsA("GuiButton") then table.insert(connections,mapButton.Activated:Connect(function() mapPanel.Visible=not mapPanel.Visible end)) end
	if menuButton and menuButton:IsA("GuiButton") then table.insert(connections,menuButton.Activated:Connect(function() mapPanel.Visible=false;toast("MENU",.6) end)) end
	if pingButton and pingButton:IsA("GuiButton") then table.insert(connections,pingButton.Activated:Connect(function()
		local camera=workspace.CurrentCamera
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not camera or not root then return end
		local v=camera.ViewportSize
		local ray=camera:ViewportPointToRay(v.X*.5,v.Y*.55)
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={character}
		local result=workspace:Raycast(ray.Origin,ray.Direction*220,params)
		if result then remotes.UtilityRequest:FireServer("Ping",result.Position);toast("PING",.6) end
	end)) end
	local close=mapPanel:FindFirstChild("Close")
	if close and close:IsA("GuiButton") then table.insert(connections,close.Activated:Connect(function() mapPanel.Visible=false end)) end
	for _,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
		local button=mapPanel:FindFirstChild(id)
		if button and button:IsA("GuiButton") then table.insert(connections,button.Activated:Connect(function() travel:FireServer(id);mapPanel.Visible=false end)) end
	end

	table.insert(connections,UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("Light")
		elseif input.KeyCode==Enum.KeyCode.Q then combat:FireServer("Dash")
		elseif input.KeyCode==Enum.KeyCode.F then combat:FireServer("BlockStart")
		elseif input.KeyCode==Enum.KeyCode.R then combat:FireServer("Special")
		elseif input.KeyCode==Enum.KeyCode.M then mapPanel.Visible=not mapPanel.Visible
		elseif input.KeyCode==Enum.KeyCode.LeftShift then movement:FireServer("Sprint",true) end
	end))
	table.insert(connections,UserInputService.InputEnded:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode==Enum.KeyCode.F then combat:FireServer("BlockEnd")
		elseif input.KeyCode==Enum.KeyCode.LeftShift then movement:FireServer("Sprint",false) end
	end))
	table.insert(connections,UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshPlatform))
end

local function bindFeedback()
	local feedback=remotes:WaitForChild("Feedback")
	table.insert(connections,feedback.OnClientEvent:Connect(function(kind:string,value:any)
		if kind=="Parry" then toast("PARRY",.65)
		elseif kind=="GuardBreak" then toast("GUARD BREAK",.8)
		elseif kind=="Evade" then toast("EVADED",.55)
		elseif kind=="KOReward" then toast("+5 CREDITS",.9)
		elseif kind=="LevelUp" then toast("LEVEL UP  •  LV "..tostring(value),1.2)
		elseif kind=="Special" and typeof(value)=="table" and value.Charged then toast("OVERDRIVE SPECIAL",.9) end
	end))
end

function M.Build():ScreenGui?
	if gui and gui.Parent and gui:GetAttribute("HUDRuntimeReady")==true then return gui end
	disconnectAll()
	local existing=playerGui:FindFirstChild("CollisionHUD")
	if existing and existing:IsA("ScreenGui") then
		if existing:GetAttribute("HUDRuntimeReady")==true then gui=existing;return existing end
		existing:Destroy()
	end
	local ok,result=pcall(function()
		local built=HUDLayout.Build()
		built.Parent=playerGui
		gui=built
		bindInput()
		bindFeedback()
		refreshPlatform()
		refreshHealth()
		refreshState()
		built:SetAttribute("HUDRuntimeReady",true)
		player:SetAttribute("HUDRuntimeReady",true)
		player:SetAttribute("HUDRecoveryError","")
		return built
	end)
	if not ok or not result or not result:IsA("ScreenGui") then
		gui=nil
		player:SetAttribute("HUDRecoveryError",tostring(result or "HUD build failed"))
		return nil
	end
	return result
end

function M.IsReady():boolean
	return gui~=nil and gui.Parent~=nil and gui:GetAttribute("HUDRuntimeReady")==true
end

function M.GetLastError():string
	return tostring(player:GetAttribute("HUDRecoveryError") or "")
end

player.CharacterAdded:Connect(function(character)
	local humanoid=character:WaitForChild("Humanoid",8)
	if humanoid and humanoid:IsA("Humanoid") then
		table.insert(connections,humanoid.HealthChanged:Connect(refreshHealth))
	end
	refreshHealth()
	refreshState()
end)

for _,attribute in ipairs({"Energy","MaxEnergy","Overdrive","Level","CurrentMapNode","Combo"}) do
	table.insert(connections,player:GetAttributeChangedSignal(attribute):Connect(refreshState))
end

task.spawn(function()
	if cooldownRunning then return end
	cooldownRunning=true
	while true do
		if gui and gui.Parent then refreshCooldowns() end
		task.wait(.25)
	end
end)

return M
