--!strict
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local utility=remotes:WaitForChild("UtilityRequest")
local feedback=remotes:WaitForChild("UtilityFeedback")

local function waitForHud():ScreenGui
	while true do
		local gui=playerGui:FindFirstChild("CollisionHUD")
		if gui and gui:IsA("ScreenGui") and gui:GetAttribute("HUDRuntimeReady")==true then return gui end
		task.wait(.2)
	end
end

local gui=waitForHud()
local utilityBar=gui:FindFirstChild("UtilityBar")
local mapButton=utilityBar and utilityBar:FindFirstChild("MapButton")
local menuButton=utilityBar and utilityBar:FindFirstChild("MenuButton")
local pingButton=utilityBar and utilityBar:FindFirstChild("PingButton")

if not utilityBar or not mapButton or not menuButton or not pingButton then return end

local menu=Instance.new("Frame")
menu.Name="MenuPanel"
menu.AnchorPoint=Vector2.new(1,0)
menu.Position=UDim2.new(1,-16,0,64)
menu.Size=UDim2.fromOffset(320,356)
menu.BackgroundColor3=Color3.fromRGB(14,18,25)
menu.BackgroundTransparency=.03
menu.BorderSizePixel=0
menu.Visible=false
menu.Parent=gui

local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,16)
corner.Parent=menu
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(74,89,112)
stroke.Transparency=.35
stroke.Thickness=1
stroke.Parent=menu

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-36,0,34)
title.Position=UDim2.fromOffset(18,12)
title.BackgroundTransparency=1
title.Font=Enum.Font.GothamBlack
title.Text="SYSTEM MENU"
title.TextSize=18
title.TextColor3=Color3.fromRGB(244,247,252)
title.Parent=menu

local subtitle=Instance.new("TextLabel")
subtitle.Size=UDim2.new(1,-36,0,22)
subtitle.Position=UDim2.fromOffset(18,44)
subtitle.BackgroundTransparency=1
subtitle.Font=Enum.Font.GothamMedium
subtitle.Text="Collision Battlestar"
subtitle.TextSize=10
subtitle.TextColor3=Color3.fromRGB(142,153,170)
subtitle.Parent=menu

local content=Instance.new("Frame")
content.Size=UDim2.new(1,-36,0,246)
content.Position=UDim2.fromOffset(18,78)
content.BackgroundTransparency=1
content.Parent=menu

local function makeButton(name:string,textValue:string,y:number):TextButton
	local b=Instance.new("TextButton")
	b.Name=name
	b.Size=UDim2.new(1,0,0,48)
	b.Position=UDim2.fromOffset(0,y)
	b.BackgroundColor3=Color3.fromRGB(25,31,41)
	b.BorderSizePixel=0
	b.AutoButtonColor=false
	b.Font=Enum.Font.GothamBold
	b.Text=textValue
	b.TextSize=12
	b.TextColor3=Color3.fromRGB(244,247,252)
	b.Parent=content
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,11)
	c.Parent=b
	return b
end

local resume=makeButton("Resume","RESUME",0)
local respawn=makeButton("Respawn","RESPAWN",58)
local settings=makeButton("Settings","COMBAT SETTINGS",116)
local controls=makeButton("Controls","CONTROLS",174)

local settingsPanel=Instance.new("Frame")
settingsPanel.Name="SettingsPanel"
settingsPanel.Size=UDim2.new(1,-36,0,210)
settingsPanel.Position=UDim2.fromOffset(18,92)
settingsPanel.BackgroundColor3=Color3.fromRGB(20,25,34)
settingsPanel.BorderSizePixel=0
settingsPanel.Visible=false
settingsPanel.Parent=menu
local spc=Instance.new("UICorner")
spc.CornerRadius=UDim.new(0,12)
spc.Parent=settingsPanel

local fx=Instance.new("TextButton")
fx.Name="FX"
fx.Size=UDim2.new(1,-20,0,46)
fx.Position=UDim2.fromOffset(10,10)
fx.BackgroundColor3=Color3.fromRGB(29,36,48)
fx.BorderSizePixel=0
fx.AutoButtonColor=false
fx.Font=Enum.Font.GothamBold
fx.TextSize=11
fx.TextColor3=Color3.fromRGB(244,247,252)
fx.Text="EFFECTS: HIGH"
fx.Parent=settingsPanel
local fxc=Instance.new("UICorner")
fxc.CornerRadius=UDim.new(0,9)
fxc.Parent=fx

local hint=Instance.new("TextLabel")
hint.Size=UDim2.new(1,-20,0,80)
hint.Position=UDim2.fromOffset(10,66)
hint.BackgroundTransparency=1
hint.Font=Enum.Font.Gotham
hint.Text="Performance settings are local. Combat simulation remains server-authoritative."
hint.TextWrapped=true
hint.TextSize=10
hint.TextColor3=Color3.fromRGB(145,155,171)
hint.Parent=settingsPanel

local close=makeButton("Close","CLOSE MENU",306)

local controlsPanel=Instance.new("Frame")
controlsPanel.Name="ControlsPanel"
controlsPanel.Size=UDim2.new(1,-36,0,210)
controlsPanel.Position=UDim2.fromOffset(18,92)
controlsPanel.BackgroundColor3=Color3.fromRGB(20,25,34)
controlsPanel.BorderSizePixel=0
controlsPanel.Visible=false
controlsPanel.Parent=menu
local cpc=Instance.new("UICorner")
cpc.CornerRadius=UDim.new(0,12)
cpc.Parent=controlsPanel
local controlText=Instance.new("TextLabel")
controlText.Size=UDim2.new(1,-20,1,-20)
controlText.Position=UDim2.fromOffset(10,10)
controlText.BackgroundTransparency=1
controlText.Font=Enum.Font.Gotham
controlText.Text="KEYBOARD\nLMB  M1\nQ  DASH\nF  GUARD\nR  SPECIAL\nM  MAP\n\nGAMEPAD\nR2  M1   B  DASH   L2  GUARD   Y  SPECIAL"
controlText.TextWrapped=true
controlText.TextSize=10
controlText.TextColor3=Color3.fromRGB(193,201,214)
controlText.TextYAlignment=Enum.TextYAlignment.Top
controlText.Parent=controlsPanel

local function openMenu()
	menu.Visible=true
	menu.Position=UDim2.new(1,-16,0,72)
	TweenService:Create(menu,TweenInfo.new(.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(1,-16,0,64)}):Play()
end

local function closeMenu()
	menu.Visible=false
	settingsPanel.Visible=false
	controlsPanel.Visible=false
end

menuButton.Activated:Connect(function()
	if menu.Visible then closeMenu() else openMenu() end
end)

resume.Activated:Connect(closeMenu)
close.Activated:Connect(closeMenu)
respawn.Activated:Connect(function()
	utility:FireServer("Respawn")
	closeMenu()
end)

controls.Activated:Connect(function()
	settingsPanel.Visible=false
	controlsPanel.Visible=not controlsPanel.Visible
end)

settings.Activated:Connect(function()
	controlsPanel.Visible=false
	settingsPanel.Visible=not settingsPanel.Visible
end)

fx.Activated:Connect(function()
	local enabled=player:GetAttribute("LocalFXHigh")~=false
	enabled=not enabled
	player:SetAttribute("LocalFXHigh",enabled)
	fx.Text=enabled and "EFFECTS: HIGH" or "EFFECTS: LOW"
end)

local function getPingPosition():Vector3?
	local camera=workspace.CurrentCamera
	if not camera then return nil end
	local viewport=camera.ViewportSize
	local point=Vector2.new(viewport.X*.5,viewport.Y*.55)
	local ray=camera:ViewportPointToRay(point.X,point.Y)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={player.Character}
	local result=workspace:Raycast(ray.Origin,ray.Direction*220,params)
	return result and result.Position or nil
end

pingButton.Activated:Connect(function()
	local position=getPingPosition()
	if position then utility:FireServer("Ping",position) end
end)

feedback.OnClientEvent:Connect(function(kind:string)
	if kind=="Respawned" then
		closeMenu()
	elseif kind=="Ping" then
		if player:GetAttribute("LocalFXHigh")~=false then
			local camera=workspace.CurrentCamera
			if camera then
				local original=camera.FieldOfView
				TweenService:Create(camera,TweenInfo.new(.05),{FieldOfView=original+2}):Play()
				task.delay(.06,function() if camera then TweenService:Create(camera,TweenInfo.new(.12),{FieldOfView=original}):Play() end end)
			end
		end
	end
end)

player:SetAttribute("LocalFXHigh",true)
