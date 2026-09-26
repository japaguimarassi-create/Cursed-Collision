--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local HUDLayout=require(ReplicatedStorage.Shared.UI.HUDLayout)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Config=require(ReplicatedStorage.Shared.Config)

local M={}
local currentGui:ScreenGui?
local inputBound=false
local feedbackBound=false
local characterBound=false
local lastError=""

local function text(parent:Instance,name:string):TextLabel?
	local item=parent:FindFirstChild(name)
	return item and item:IsA("TextLabel") and item or nil
end

local function updateScale(gui:ScreenGui)
	local scale=gui:FindFirstChild("ResponsiveScale")
	local camera=workspace.CurrentCamera
	if not scale or not scale:IsA("UIScale") then return end
	local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
	scale.Scale=math.clamp(math.min(viewport.X/1200,viewport.Y/720),.70,1.08)
end

local function toast(message:string,duration:number)
	local gui=currentGui
	local notice=gui and gui:FindFirstChild("Notice")
	local label=notice and text(notice,"Text")
	if not notice or not label then return end
	label.Text=message
	notice.Visible=true
	local token=message
	task.delay(duration,function()
		if currentGui==gui and notice.Parent and label.Text==token then notice.Visible=false end
	end)
end

local function renderHealth()
	local gui=currentGui
	if not gui then return end
	local status=gui:FindFirstChild("StatusFrame")
	local back=status and status:FindFirstChild("HealthBackground")
	local fill=back and back:FindFirstChild("Fill")
	local label=back and text(back,"HealthText")
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

local function renderEnergy()
	local gui=currentGui
	if not gui then return end
	local status=gui:FindFirstChild("StatusFrame")
	local back=status and status:FindFirstChild("EnergyBackground")
	local fill=back and back:FindFirstChild("Fill")
	local label=back and text(back,"EnergyText")
	if not fill or not fill:IsA("Frame") then return end
	local maximum=math.max(1,tonumber(player:GetAttribute("MaxEnergy")) or 100)
	local energy=math.clamp(tonumber(player:GetAttribute("Energy")) or maximum,0,maximum)
	fill.Size=UDim2.new(energy/maximum,0,1,0)
	if label then label.Text=("ENERGY %d"):format(math.floor(energy)) end
end

local function renderAwakening()
	local gui=currentGui
	if not gui then return end
	local status=gui:FindFirstChild("StatusFrame")
	local back=status and status:FindFirstChild("UltBackground")
	local fill=back and back:FindFirstChild("Fill")
	local label=back and text(back,"UltText")
	if not fill or not fill:IsA("Frame") then return end
	local percent=math.clamp(tonumber(player:GetAttribute("Overdrive")) or 0,0,100)
	fill.Size=UDim2.new(percent/100,0,1,0)
	if label then
		label.Text=percent>=100 and "AWAKENING READY  •  G" or ("AWAKENING %d%%"):format(math.floor(percent))
		label.TextColor3=percent>=100 and Color3.fromRGB(255,215,0) or Config.UI.Text
	end
end

local function renderStats()
	local gui=currentGui
	if not gui then return end
	local status=gui:FindFirstChild("StatusFrame")
	local profile=status and status:FindFirstChild("Profile")
	local initial=profile and text(profile,"Initial")
	local nameLabel=status and text(status,"Name")
	if initial then initial.Text=string.sub(player.DisplayName,1,1):upper() end
	if nameLabel then nameLabel.Text=player.DisplayName end
	local quick=gui:FindFirstChild("QuickInfo")
	if not quick then return end
	local level=text(quick,"Level")
	local credits=text(quick,"Credits")
	local location=text(quick,"Location")
	local stats=player:FindFirstChild("leaderstats")
	local creditValue=stats and stats:FindFirstChild("Credits")
	if level then level.Text=("LV %d"):format(tonumber(player:GetAttribute("Level")) or 1) end
	if credits then credits.Text=("%d C"):format(creditValue and creditValue:IsA("IntValue") and creditValue.Value or 0) end
	local node=Routes.Get(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
	if location then location.Text=node and node.Name or "ORIGIN PLAZA" end
	local center=gui:FindFirstChild("CenterState")
	local combo=text(center or gui,"Combo")
	if combo then combo.Text=("COMBO %d"):format(tonumber(player:GetAttribute("Combo")) or 0) end
end

local function renderCooldowns()
	local gui=currentGui
	if not gui then return end
	local hotbar=gui:FindFirstChild("Hotbar")
	if not hotbar then return end
	local map={
		Light="NextLight",
		Dash="NextDash",
		Special="NextSpecial",
	}
	local now=os.clock()
	for name,attribute in pairs(map) do
		local button=hotbar:FindFirstChild(name)
		local cd=button and text(button,"Cooldown")
		local state=button and text(button,"State")
		if cd and state then
			local remaining=math.max(0,(tonumber(player:GetAttribute(attribute)) or 0)-now)
			cd.Text=remaining>.02 and ("%.1f"):format(remaining) or ""
			state.Text=remaining>.02 and "COOLDOWN" or "READY"
		end
	end
end

local function refreshPlatform()
	local gui=currentGui
	if not gui then return end
	local hotbar=gui:FindFirstChild("Hotbar")
	local mobile=gui:FindFirstChild("MobileActions")
	local hints=gui:FindFirstChild("ControllerHints")
	if not hotbar or not mobile or not hints then return end
	local preferred=UserInputService.PreferredInput
	local touch=preferred==Enum.PreferredInput.Touch
	local gamepad=preferred==Enum.PreferredInput.Gamepad or preferred==Enum.PreferredInput.MicroGamepad
	hotbar.Visible=not touch
	mobile.Visible=touch
	hints.Visible=gamepad
	if touch then
		local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
		mobile.Position=UDim2.new(1,-12,.5,18)
		mobile.Size=viewport.X<900 and UDim2.fromOffset(178,238) or UDim2.fromOffset(190,252)
	elseif gamepad then
		GuiService.GuiNavigationEnabled=true
		local first=hotbar:FindFirstChild("Light")
		if first and first:IsA("GuiButton") then
			GuiService.SelectedObject=first
		end
	else
		GuiService.GuiNavigationEnabled=false
	end
	if gamepad then
		for name,key in pairs({
			Light=Enum.KeyCode.ButtonR2,
			Dash=Enum.KeyCode.ButtonB,
			Block=Enum.KeyCode.ButtonL2,
			Special=Enum.KeyCode.ButtonY,
		}) do
			local button=hotbar:FindFirstChild(name)
			if button and button:IsA("GuiButton") then
				local image=button:FindFirstChild("GamepadPrompt")
				if not image then
					image=Instance.new("ImageLabel")
					image.Name="GamepadPrompt"
					image.BackgroundTransparency=1
					image.Size=UDim2.fromOffset(20,20)
					image.Position=UDim2.new(1,-26,0,6)
					image.Parent=button
				end
				local ok,result=pcall(function() return UserInputService:GetImageForKeyCode(key) end)
				if ok and result~="" then
					image.Image=result
					image.Visible=true
				else
					image.Visible=false
				end
			end
		end
	end
end

local function bindGui(gui:ScreenGui)
	local combat=ReplicatedStorage.CollisionRemotes.CombatRequest
	local movement=ReplicatedStorage.CollisionRemotes.MovementRequest
	local travel=ReplicatedStorage.CollisionRemotes.MapTravelRequest
	local hotbar=gui:WaitForChild("Hotbar")
	for name,action in pairs({Light="Light",Dash="Dash",Special="Special"}) do
		local button=hotbar:FindFirstChild(name)
		if button and button:IsA("TextButton") then
			button.Activated:Connect(function() combat:FireServer(action) end)
		end
	end
	local block=hotbar:FindFirstChild("Block")
	if block and block:IsA("TextButton") then
		block.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonL2 then combat:FireServer("BlockStart") end
		end)
		block.InputEnded:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonL2 then combat:FireServer("BlockEnd") end
		end)
	end
	local mobile=gui:WaitForChild("MobileActions")
	for name,action in pairs({MobileM1="Light",MobileDash="Dash",MobileSpecial="Special"}) do
		local button=mobile:FindFirstChild(name)
		if button and button:IsA("TextButton") then
			button.Activated:Connect(function() combat:FireServer(action) end)
		end
	end
	local guard=mobile:FindFirstChild("MobileGuard")
	if guard and guard:IsA("TextButton") then
		guard.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("BlockStart") end
		end)
		guard.InputEnded:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then combat:FireServer("BlockEnd") end
		end)
	end
	local utility=gui:WaitForChild("UtilityBar")
	local mapButton=utility:WaitForChild("MapButton")
	local menuButton=utility:WaitForChild("MenuButton")
	local pingButton=utility:WaitForChild("PingButton")
	local mapPanel=gui:WaitForChild("MapPanel")
	mapButton.Activated:Connect(function() mapPanel.Visible=not mapPanel.Visible end)
	menuButton.Activated:Connect(function() mapPanel.Visible=false;toast("MENU",.6) end)
	pingButton.Activated:Connect(function() toast("PING",.6) end)
	local close=mapPanel:WaitForChild("Close")
	if close:IsA("GuiButton") then close.Activated:Connect(function() mapPanel.Visible=false end) end
	for _,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do
		local button=mapPanel:FindFirstChild(id)
		if button and button:IsA("TextButton") then
			button.Activated:Connect(function() travel:FireServer(id) end)
		end
	end
end

local function bindGlobals()
	if not inputBound then
		inputBound=true
		UserInputService.InputBegan:Connect(function(input,gpe)
			if gpe then return end
			if input.UserInputType==Enum.UserInputType.MouseButton1 then ReplicatedStorage.CollisionRemotes.CombatRequest:FireServer("Light")
			elseif input.KeyCode==Enum.KeyCode.Q then ReplicatedStorage.CollisionRemotes.CombatRequest:FireServer("Dash")
			elseif input.KeyCode==Enum.KeyCode.F then ReplicatedStorage.CollisionRemotes.CombatRequest:FireServer("BlockStart")
			elseif input.KeyCode==Enum.KeyCode.R then ReplicatedStorage.CollisionRemotes.CombatRequest:FireServer("Special")
			elseif input.KeyCode==Enum.KeyCode.M and currentGui then
				local panel=currentGui:FindFirstChild("MapPanel")
				if panel then panel.Visible=not panel.Visible end
			elseif input.KeyCode==Enum.KeyCode.LeftShift then ReplicatedStorage.CollisionRemotes.MovementRequest:FireServer("Sprint",true)
			end
		end)
		UserInputService.InputEnded:Connect(function(input,gpe)
			if gpe then return end
			if input.KeyCode==Enum.KeyCode.F then ReplicatedStorage.CollisionRemotes.CombatRequest:FireServer("BlockEnd")
			elseif input.KeyCode==Enum.KeyCode.LeftShift then ReplicatedStorage.CollisionRemotes.MovementRequest:FireServer("Sprint",false)
			end
		end)
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshPlatform)
	end
	if not feedbackBound then
		feedbackBound=true
		ReplicatedStorage.CollisionRemotes.Feedback.OnClientEvent:Connect(function(kind:string,value:any)
			if kind=="Parry" then toast("PARRY",.65)
			elseif kind=="GuardBreak" then toast("GUARD BREAK",.8)
			elseif kind=="Evade" then toast("EVADED",.55)
			elseif kind=="KOReward" then toast("+5 CREDITS",.9)
			elseif kind=="LevelUp" then toast("LEVEL UP  •  LV "..tostring(value),1.3)
			elseif kind=="Special" and typeof(value)=="table" and value.Charged then toast("OVERDRIVE SPECIAL",1) end
		end)
		ReplicatedStorage.CollisionRemotes.MapTravelFeedback.OnClientEvent:Connect(function(kind:string,value:any)
			if kind=="Success" and typeof(value)=="table" then toast(value.Name.."  •  "..value.Subtitle,1.5)
			elseif kind=="Error" then toast(tostring(value),1.1) end
		end)
	end
end

function M.Build():ScreenGui?
	local existing=playerGui:FindFirstChild("CollisionHUD")
	if existing and existing:IsA("ScreenGui") and existing:GetAttribute("HUDRuntimeReady")==true then
		currentGui=existing
		return existing
	end
	if existing then existing:Destroy() end
	local ok,result=pcall(function()
		local gui=HUDLayout.Build()
		gui.Parent=playerGui
		currentGui=gui
		bindGui(gui)
		bindGlobals()
		updateScale(gui)
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() updateScale(gui) end)
		end
		renderHealth()
		renderEnergy()
		renderAwakening()
		renderStats()
		refreshPlatform()
		gui:SetAttribute("HUDRuntimeReady",true)
		player:SetAttribute("HUDRuntimeReady",true)
		player:SetAttribute("HUDRecoveryError","")
		return gui
	end)
	if not ok or not result or not result:IsA("ScreenGui") then
		lastError=tostring(result or "HUD runtime build failed")
		player:SetAttribute("HUDRecoveryError",lastError)
		return nil
	end
	lastError=""
	return result
end

function M.IsReady():boolean
	local gui=playerGui:FindFirstChild("CollisionHUD")
	if not gui or not gui:IsA("ScreenGui") then return false end
	if gui:GetAttribute("HUDLayoutReady")~=true or gui:GetAttribute("HUDRuntimeReady")~=true then return false end
	local status=gui:FindFirstChild("StatusFrame")
	local hotbar=gui:FindFirstChild("Hotbar")
	local mobile=gui:FindFirstChild("MobileActions")
	return status~=nil and hotbar~=nil and mobile~=nil
end

function M.GetLastError():string
	return lastError
end

if not characterBound then
	characterBound=true
	player.CharacterAdded:Connect(function(character)
		local humanoid=character:WaitForChild("Humanoid",8)
		if humanoid and humanoid:IsA("Humanoid") then humanoid.HealthChanged:Connect(renderHealth) end
		renderHealth()
	end)
	if player.Character then
		local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.HealthChanged:Connect(renderHealth) end
	end
end

task.spawn(function()
	while true do
		if currentGui and currentGui.Parent then
			renderHealth()
			renderEnergy()
			renderAwakening()
			renderStats()
			renderCooldowns()
		end
		task.wait(.1)
	end
end)

return M
