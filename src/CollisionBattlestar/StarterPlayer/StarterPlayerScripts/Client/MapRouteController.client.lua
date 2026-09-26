--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local Routes=require(R.Shared.MapRouteDefinitions)
local remotes=R:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("MapTravelRequest")
local feedback=remotes:WaitForChild("MapTravelFeedback")

local gui=Instance.new("ScreenGui")
gui.Name="BattleLineMap"
gui.ResetOnSpawn=false
gui.DisplayOrder=60
gui.Parent=player:WaitForChild("PlayerGui")

local open=Instance.new("TextButton")
open.Name="MapButton"
open.Size=UIS.TouchEnabled and UDim2.fromOffset(88,38)or UDim2.fromOffset(104,38)
open.Position=UDim2.new(0,14,0,112)
open.BackgroundColor3=Color3.fromRGB(24,27,34)
open.TextColor3=Color3.fromRGB(238,241,248)
open.Font=Enum.Font.GothamBold
open.TextSize=14
open.Text="MAP"
open.AutoButtonColor=false
open.Selectable=true
open.Parent=gui

local oc=Instance.new("UICorner");oc.CornerRadius=UDim.new(0,10);oc.Parent=open
local os=Instance.new("UIStroke");os.Color=Color3.fromRGB(92,198,255);os.Transparency=.45;os.Parent=open

local panel=Instance.new("Frame")
panel.Name="RoutePanel"
panel.Size=UIS.TouchEnabled and UDim2.new(.94,0,0,180)or UDim2.fromOffset(780,190)
panel.Position=UIS.TouchEnabled and UDim2.new(.03,0,.5,-90)or UDim2.new(.5,-390,.5,-95)
panel.BackgroundColor3=Color3.fromRGB(16,19,25)
panel.Visible=false
panel.Parent=gui

local pc=Instance.new("UICorner");pc.CornerRadius=UDim.new(0,16);pc.Parent=panel
local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(80,87,102);ps.Transparency=.2;ps.Parent=panel

local title=Instance.new("TextLabel")
title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(18,10)
title.Size=UDim2.new(1,-36,0,24)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Font=Enum.Font.GothamBold
title.TextSize=17
title.TextColor3=Color3.fromRGB(242,244,250)
title.Text="BATTLE ROUTE"
title.Parent=panel

local sub=Instance.new("TextLabel")
sub.BackgroundTransparency=1
sub.Position=UDim2.fromOffset(18,34)
sub.Size=UDim2.new(1,-36,0,18)
sub.TextXAlignment=Enum.TextXAlignment.Left
sub.Font=Enum.Font.Gotham
sub.TextSize=11
sub.TextColor3=Color3.fromRGB(151,158,172)
sub.Text="FAST TRAVEL • 1 PLACE • 7 ZONES"
sub.Parent=panel

local scroll=Instance.new("ScrollingFrame")
scroll.BackgroundTransparency=1
scroll.BorderSizePixel=0
scroll.Position=UDim2.fromOffset(12,60)
scroll.Size=UDim2.new(1,-24,1,-68)
scroll.CanvasSize=UDim2.new()
scroll.AutomaticCanvasSize=Enum.AutomaticSize.X
scroll.ScrollingDirection=Enum.ScrollingDirection.X
scroll.ScrollBarThickness=3
scroll.Parent=panel

local list=Instance.new("UIListLayout")
list.FillDirection=Enum.FillDirection.Horizontal
list.Padding=UDim.new(0,8)
list.VerticalAlignment=Enum.VerticalAlignment.Center
list.Parent=scroll

local buttons:{[string]:TextButton}={}
for index,id in ipairs(Routes.Order)do
	local node=Routes.Nodes[id]
	local b=Instance.new("TextButton")
	b.Name=node.Id
	b.Size=UIS.TouchEnabled and UDim2.fromOffset(132,84)or UDim2.fromOffset(136,84)
	b.BackgroundColor3=Color3.fromRGB(28,32,40)
	b.TextColor3=Color3.fromRGB(235,239,246)
	b.Font=Enum.Font.GothamBold
	b.TextSize=11
	b.TextWrapped=true
	b.Text=node.Name.."
"..node.Subtitle
	b.AutoButtonColor=false
	b.Selectable=true
	b.Parent=scroll
	local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,12);bc.Parent=b
	local bs=Instance.new("UIStroke");bs.Color=node.Color;bs.Transparency=.55;bs.Parent=b
	if index<#Routes.Order then
		local connector=Instance.new("Frame")
		connector.Name="Connector"
		connector.Size=UDim2.fromOffset(8,2)
		connector.Position=UDim2.new(1,2,.5,-1)
		connector.BackgroundColor3=Color3.fromRGB(85,92,106)
		connector.BorderSizePixel=0
		connector.Parent=b
	end
	b.Activated:Connect(function()
		if player:GetAttribute("MapTraveling")==true then return end
		request:FireServer(node.Id)
	end)
	buttons[id]=b
end

local function refresh()
	local current=tostring(player:GetAttribute("CurrentMapNode")or"Origin")
	for id,b in pairs(buttons)do
		b.BackgroundTransparency=id==current and 0 or .08
	end
end

open.Activated:Connect(function()
	panel.Visible=not panel.Visible
	refresh()
end)

if UIS.KeyboardEnabled then
	UIS.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode==Enum.KeyCode.M then panel.Visible=not panel.Visible;refresh()end
	end)
end

feedback.OnClientEvent:Connect(function(kind,value)
	if kind=="MapTravelSuccess"and typeof(value)=="table"then
		panel.Visible=false
		refresh()
	elseif kind=="MapLocked"or kind=="MapUnavailable"then
		open.Text=kind=="MapLocked"and"TRAVEL LOCK"or"LOADING"
		task.delay(1.1,function()if open.Parent then open.Text="MAP"end end)
	end
end)

player:GetAttributeChangedSignal("CurrentMapNode"):Connect(refresh)
refresh()
