--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local gui=playerGui:WaitForChild("CollisionHUD")
local actionBar=gui:WaitForChild("ActionBar")
local meter=gui:WaitForChild("OverdriveMeter")
local mapButton=gui:WaitForChild("MapButton")
local menuButton=gui:WaitForChild("MenuButton")
local touchIcon="rbxasset://textures/ui/Controls/TouchTapIcon.png"

local gamepadBindings={
	Light=Enum.KeyCode.ButtonR2,
	Dash=Enum.KeyCode.ButtonB,
	Block=Enum.KeyCode.ButtonL2,
	Special=Enum.KeyCode.ButtonY,
	Map=Enum.KeyCode.ButtonSelect,
	Menu=Enum.KeyCode.ButtonStart,
}

local basePositions={
	Light=UDim2.fromOffset(8,9),
	Dash=UDim2.fromOffset(110,9),
	Block=UDim2.fromOffset(212,9),
	Special=UDim2.fromOffset(314,9),
}

local mobilePositions={
	Light=UDim2.fromOffset(8,100),
	Dash=UDim2.fromOffset(108,8),
	Block=UDim2.fromOffset(108,108),
	Special=UDim2.fromOffset(208,58),
}

local mobileSize=UDim2.fromOffset(92,92)
local desktopSize=UDim2.fromOffset(94,68)

local function addIcon(button:GuiButton,name:string)
	local existing=button:FindFirstChild(name)
	if existing and existing:IsA("ImageLabel") then return existing end
	local image=Instance.new("ImageLabel")
	image.Name=name
	image.BackgroundTransparency=1
	image.Size=UDim2.fromOffset(23,23)
	image.Position=UDim2.new(1,-29,0,6)
	image.ImageTransparency=0
	image.ScaleType=Enum.ScaleType.Fit
	image.Parent=button
	return image
end

local function addMobileTouchMark(button:GuiButton)
	local image=addIcon(button,"TouchIcon")
	image.Image=touchIcon
	image.ImageTransparency=.12
	image.Size=UDim2.fromOffset(19,19)
	image.Position=UDim2.new(1,-25,0,8)
end

local function addGamepadPrompt(button:GuiButton,key:Enum.KeyCode)
	local image=addIcon(button,"GamepadPrompt")
	local ok,result=pcall(function()
		return UserInputService:GetImageForKeyCode(key)
	end)
	if ok and result then
		image.Image=result
		image.Visible=true
	else
		image.Visible=false
	end
end

local function clearModeVisuals(button:GuiButton)
	local touch=button:FindFirstChild("TouchIcon")
	if touch and touch:IsA("ImageLabel") then touch.Visible=false end
	local gamepad=button:FindFirstChild("GamepadPrompt")
	if gamepad and gamepad:IsA("ImageLabel") then gamepad.Visible=false end
end

local function setButtonText(button:GuiButton,text:string)
	local label=button:FindFirstChild("TextLabel")
	if label and label:IsA("TextLabel") then
		label.Text=text
	else
		button.Text=text
	end
end

local function decorateButton(button:GuiButton)
	button.Active=true
	button.Selectable=true
	button.AutoButtonColor=false
	local scale=button:FindFirstChildOfClass("UIScale")
	if not scale then
		scale=Instance.new("UIScale")
		scale.Scale=1
		scale.Parent=button
	end
	if not button:GetAttribute("PlatformHoverBound") then
		button:SetAttribute("PlatformHoverBound",true)
		button.MouseEnter:Connect(function()
			TweenService:Create(scale,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1.035}):Play()
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(scale,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
		end)
		button.SelectionGained:Connect(function()
			TweenService:Create(scale,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1.055}):Play()
		end)
		button.SelectionLost:Connect(function()
			TweenService:Create(scale,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
		end)
	end
end

local function setDesktop()
	actionBar.AnchorPoint=Vector2.new(.5,1)
	actionBar.Position=UDim2.new(.5,0,1,-4)
	actionBar.Size=UDim2.fromOffset(430,86)
	actionBar.BackgroundTransparency=.09
	meter.AnchorPoint=Vector2.new(.5,1)
	meter.Position=UDim2.new(.5,0,1,-92)
	for name,pos in pairs(basePositions) do
		local button=actionBar:FindFirstChild(name)
		if button and button:IsA("TextButton") then
			button.Size=desktopSize
			button.Position=pos
			button:SetAttribute("PlatformLayout","desktop")
			clearModeVisuals(button)
			local key=gamepadBindings[name]
			if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad then
				addGamepadPrompt(button,key)
			end
		end
	end
end

local function setTouch()
	actionBar.AnchorPoint=Vector2.new(1,1)
	actionBar.Position=UDim2.new(1,-20,1,-112)
	actionBar.Size=UDim2.fromOffset(308,208)
	actionBar.BackgroundTransparency=1
	meter.AnchorPoint=Vector2.new(.5,1)
	meter.Position=UDim2.new(.5,0,1,-96)
	for name,pos in pairs(mobilePositions) do
		local button=actionBar:FindFirstChild(name)
		if button and button:IsA("TextButton") then
			button.Size=mobileSize
			button.Position=pos
			button:SetAttribute("PlatformLayout","touch")
			clearModeVisuals(button)
			addMobileTouchMark(button)
		end
	end
end

local function setGamepad()
	setDesktop()
	for name,key in pairs(gamepadBindings) do
		local target=name=="Map" and mapButton or name=="Menu" and menuButton or actionBar:FindFirstChild(name)
		if target and target:IsA("GuiButton") then
			target.Selectable=true
			addGamepadPrompt(target,key)
		end
	end
	GuiService.GuiNavigationEnabled=true
	local light=actionBar:FindFirstChild("Light")
	if light and light:IsA("GuiButton") then GuiService.SelectedObject=light end
end

local function setMode()
	local preferred=UserInputService.PreferredInput
	if preferred==Enum.PreferredInput.Touch or preferred==Enum.PreferredInput.MicroGamepad then
		if preferred==Enum.PreferredInput.Touch then
			setTouch()
		else
			setDesktop()
		end
	elseif preferred==Enum.PreferredInput.Gamepad then
		setGamepad()
	else
		setDesktop()
	end
end

for _,name in ipairs({"Light","Dash","Block","Special","MapButton","MenuButton"}) do
	local target=gui:FindFirstChild(name,true)
	if target and target:IsA("GuiButton") then decorateButton(target) end
end

gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
gui.ClipToDeviceSafeArea=true
GuiService.TouchControlsEnabled=true

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(setMode)
GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(setMode)
setMode()
