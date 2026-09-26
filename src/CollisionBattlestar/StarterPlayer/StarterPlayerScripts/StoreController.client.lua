--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local utility=remotes:WaitForChild("UtilityRequest")
local feedback=remotes:WaitForChild("UtilityFeedback")
local catalog=require(ReplicatedStorage.Shared.StoreCatalog)

local gui:ScreenGui
local panel:Frame?
local activeTab="Featured"
local owned:{[string]:boolean}={}
local render:()->()

local function waitHud():ScreenGui
	while true do
		local candidate=playerGui:FindFirstChild("CollisionHUD")
		if candidate and candidate:IsA("ScreenGui") and candidate:GetAttribute("HUDRuntimeReady")==true then return candidate end
		task.wait(.2)
	end
end

gui=waitHud()

local function corner(parent:Instance,radius:number)
	local c=Instance.new("UICorner")
	c.CornerRadius=UDim.new(0,radius)
	c.Parent=parent
end

local function stroke(parent:Instance,color:Color3,transparency:number,thickness:number)
	local s=Instance.new("UIStroke")
	s.Color=color
	s.Transparency=transparency
	s.Thickness=thickness
	s.Parent=parent
end

local function label(parent:Instance,name:string,textValue:string,size:number,pos:UDim2,color:Color3,bold:boolean):TextLabel
	local l=Instance.new("TextLabel")
	l.Name=name
	l.BackgroundTransparency=1
	l.Text=textValue
	l.TextColor3=color
	l.TextSize=size
	l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.Size=UDim2.new(1,0,0,24)
	l.Position=pos
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.TextYAlignment=Enum.TextYAlignment.Center
	l.Parent=parent
	return l
end

local function button(parent:Instance,name:string,textValue:string,size:UDim2,pos:UDim2):TextButton
	local b=Instance.new("TextButton")
	b.Name=name
	b.Text=textValue
	b.Size=size
	b.Position=pos
	b.BackgroundColor3=Color3.fromRGB(24,31,41)
	b.BackgroundTransparency=.02
	b.BorderSizePixel=0
	b.AutoButtonColor=false
	b.Font=Enum.Font.GothamBold
	b.TextColor3=Color3.fromRGB(244,247,252)
	b.TextSize=11
	b.Parent=parent
	corner(b,10)
	stroke(b,Color3.fromRGB(79,91,111),.45,1)
	return b
end

local function makeOverlay()
	local overlay=Instance.new("Frame")
	overlay.Name="MarketOverlay"
	overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.fromRGB(0,0,0)
	overlay.BackgroundTransparency=.52
	overlay.BorderSizePixel=0
	overlay.Visible=false
	overlay.ZIndex=50
	overlay.Parent=gui
	return overlay
end

local overlay=makeOverlay()

local function makePanel()
	local p=Instance.new("Frame")
	p.Name="StoreCenter"
	p.AnchorPoint=Vector2.new(.5,.5)
	p.Position=UDim2.fromScale(.5,.53)
	p.Size=UDim2.fromOffset(840,560)
	p.BackgroundColor3=Color3.fromRGB(10,14,20)
	p.BackgroundTransparency=.015
	p.BorderSizePixel=0
	p.Visible=false
	p.ZIndex=55
	p.Parent=gui
	corner(p,18)
	stroke(p,Color3.fromRGB(75,90,112),.25,1)
	panel=p

	label(p,"Title","BATTLE MARKET",22,UDim2.fromOffset(24,16),Color3.fromRGB(244,247,252),true)
	label(p,"Sub","Featured gear, emotes and premium currency",10,UDim2.fromOffset(24,43),Color3.fromRGB(143,153,168),false)

	local close=button(p,"Close","×",UDim2.fromOffset(42,38),UDim2.new(1,-58,0,12))
	close.TextSize=22
	close.ZIndex=58
	close.Activated:Connect(function()
		p.Visible=false
		overlay.Visible=false
	end)

	local tabBar=Instance.new("Frame")
	tabBar.Name="Tabs"
	tabBar.Size=UDim2.fromOffset(510,42)
	tabBar.Position=UDim2.fromOffset(24,73)
	tabBar.BackgroundTransparency=1
	tabBar.ZIndex=56
	tabBar.Parent=p

	for i,tab in ipairs({"Featured","Emotes","Robux"}) do
		local b=button(tabBar,"Tab"..tab,tab,UDim2.fromOffset(158,38),UDim2.fromOffset((i-1)*168,0))
		b.ZIndex=57
		b.Activated:Connect(function()
			activeTab=tab
			render()
		end)
	end

	local codeBox=Instance.new("Frame")
	codeBox.Name="CodeBox"
	codeBox.Size=UDim2.fromOffset(270,42)
	codeBox.Position=UDim2.new(1,-294,0,73)
	codeBox.BackgroundColor3=Color3.fromRGB(18,24,32)
	codeBox.BorderSizePixel=0
	codeBox.ZIndex=56
	codeBox.Parent=p
	corner(codeBox,10)

	local input=Instance.new("TextBox")
	input.Name="CodeInput"
	input.Size=UDim2.new(1,-78,1,0)
	input.Position=UDim2.fromOffset(10,0)
	input.BackgroundTransparency=1
	input.PlaceholderText="REDEEM CODE"
	input.TextColor3=Color3.fromRGB(244,247,252)
	input.PlaceholderColor3=Color3.fromRGB(110,120,136)
	input.Font=Enum.Font.GothamBold
	input.TextSize=11
	input.ClearTextOnFocus=false
	input.ZIndex=57
	input.Parent=codeBox

	local redeem=button(codeBox,"Redeem","REDEEM",UDim2.fromOffset(66,32),UDim2.new(1,-70,.5,-16))
	redeem.TextSize=9
	redeem.ZIndex=57
	redeem.Activated:Connect(function()
		utility:FireServer("RedeemCode",input.Text)
		input.Text=""
	end)

	local credit=label(p,"Credit","0 C",13,UDim2.new(1,-170,0,23),Color3.fromRGB(98,220,255),true)
	credit.TextXAlignment=Enum.TextXAlignment.Right

	local content=Instance.new("Frame")
	content.Name="Content"
	content.Size=UDim2.new(1,-48,1,-132)
	content.Position=UDim2.fromOffset(24,123)
	content.BackgroundTransparency=1
	content.ZIndex=56
	content.Parent=p
end

local function openStore(tab:string)
	activeTab=tab
	overlay.Visible=true
	if panel then
		panel.Visible=true
		render()
	end
end

local function renderFeatured(content:Frame)
	local items={}
	for _,item in ipairs(catalog.Items) do
		if item.Category=="Featured" then table.insert(items,item) end
	end
	for index,item in ipairs(items) do
		local col=(index-1)%3
		local row=math.floor((index-1)/3)
		local x=col*264
		local y=row*150
		local card=Instance.new("Frame")
		card.Name=item.Id
		card.Size=UDim2.fromOffset(254,138)
		card.Position=UDim2.fromOffset(x,y)
		card.BackgroundColor3=Color3.fromRGB(18,23,30)
		card.BorderSizePixel=0
		card.ZIndex=57
		card.Parent=content
		corner(card,12)
		stroke(card,Color3.fromRGB(72,84,103),.42,1)
		label(card,"Name",item.Name,16,UDim2.fromOffset(14,10),Color3.fromRGB(244,247,252),true)
		local desc=label(card,"Desc",item.Description,9,UDim2.fromOffset(14,38),Color3.fromRGB(143,153,168),false)
		desc.Size=UDim2.fromOffset(220,36)
		desc.TextWrapped=true
		label(card,"Price",tostring(item.Price).." C",12,UDim2.fromOffset(14,88),Color3.fromRGB(98,220,255),true)
		local action=button(card,"Action",owned[item.Id] and "EQUIP" or "UNLOCK",UDim2.fromOffset(96,30),UDim2.new(1,-110,1,-40))
		action.TextSize=9
		action.ZIndex=58
		action.Activated:Connect(function()
			if owned[item.Id] then utility:FireServer("EquipItem",item.Id) else utility:FireServer("BuyItem",item.Id) end
		end)
	end
end

local function renderEmotes(content:Frame)
	local items={}
	for _,item in ipairs(catalog.Items) do
		if item.Category=="Emotes" then table.insert(items,item) end
	end
	for index,item in ipairs(items) do
		local col=(index-1)%3
		local row=math.floor((index-1)/3)
		local x=col*264
		local y=row*150
		local card=Instance.new("Frame")
		card.Name=item.Id
		card.Size=UDim2.fromOffset(254,138)
		card.Position=UDim2.fromOffset(x,y)
		card.BackgroundColor3=Color3.fromRGB(18,23,30)
		card.BorderSizePixel=0
		card.ZIndex=57
		card.Parent=content
		corner(card,12)
		stroke(card,Color3.fromRGB(72,84,103),.42,1)
		label(card,"Name",item.Name,16,UDim2.fromOffset(14,10),Color3.fromRGB(244,247,252),true)
		local desc=label(card,"Desc",item.Description,9,UDim2.fromOffset(14,38),Color3.fromRGB(143,153,168),false)
		desc.Size=UDim2.fromOffset(220,36)
		desc.TextWrapped=true
		label(card,"Price",tostring(item.Price).." C",12,UDim2.fromOffset(14,88),Color3.fromRGB(98,220,255),true)
		local action=button(card,"Action",owned[item.Id] and "EQUIP" or "UNLOCK",UDim2.fromOffset(96,30),UDim2.new(1,-110,1,-40))
		action.TextSize=9
		action.ZIndex=58
		action.Activated:Connect(function()
			if owned[item.Id] then utility:FireServer("EquipItem",item.Id) else utility:FireServer("BuyItem",item.Id) end
		end)
	end
end

local function renderRobux(content:Frame)
	label(content,"Header","CREDIT BUNDLES",20,UDim2.fromOffset(0,0),Color3.fromRGB(244,247,252),true)
	label(content,"Hint","Storefront presentation follows the researched cash-card language. Real Robux products must be linked to Creator product IDs before charging.",10,UDim2.fromOffset(0,30),Color3.fromRGB(143,153,168),false)
	for index,bundle in ipairs(catalog.Bundles) do
		local col=(index-1)%2
		local row=math.floor((index-1)/2)
		local x=col*412
		local y=70+row*82
		local card=button(content,bundle.Id,bundle.Name,UDim2.fromOffset(400,68),UDim2.fromOffset(x,y))
		card.ZIndex=57
		local suffix=bundle.Best and "  •  BEST VALUE" or ""
		card.Text=bundle.Name.."   "..tostring(bundle.Robux).." R$"..suffix
		card.TextSize=13
		card.Activated:Connect(function()
			showStatus("ROBux product ID required")
		end)
	end
end

function render()
	if not panel then return end
	local content=panel:FindFirstChild("Content")
	if not content or not content:IsA("Frame") then return end
	for _,child in ipairs(content:GetChildren()) do child:Destroy() end
	local stats=player:FindFirstChild("leaderstats")
	local credits=stats and stats:FindFirstChild("Credits")
	local credit=panel:FindFirstChild("Credit")
	if credit and credit:IsA("TextLabel") then
		credit.Text=tostring(credits and credits:IsA("IntValue") and credits.Value or 0).." C"
	end
	if activeTab=="Featured" then renderFeatured(content)
	elseif activeTab=="Emotes" then renderEmotes(content)
	else renderRobux(content) end
end

local statusToken=0
function showStatus(textValue:string)
	statusToken+=1
	local token=statusToken
	local toast=gui:FindFirstChild("StoreToast")
	if not toast or not toast:IsA("Frame") then
		toast=Instance.new("Frame")
		toast.Name="StoreToast"
		toast.Size=UDim2.fromOffset(360,44)
		toast.AnchorPoint=Vector2.new(.5,0)
		toast.Position=UDim2.new(.5,0,.08,0)
		toast.BackgroundColor3=Color3.fromRGB(12,16,22)
		toast.BackgroundTransparency=.03
		toast.BorderSizePixel=0
		toast.ZIndex=80
		toast.Parent=gui
		corner(toast,11)
		stroke(toast,Color3.fromRGB(75,90,112),.3,1)
		label(toast,"Text","",12,UDim2.fromOffset(10,0),Color3.fromRGB(244,247,252),true).TextXAlignment=Enum.TextXAlignment.Center
	end
	local text=toast:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then text.Text=textValue end
	toast.Visible=true
	task.delay(1.5,function()
		if token==statusToken and toast and toast.Parent then toast.Visible=false end
	end)
end

makePanel()
render()

local nav=Instance.new("Frame")
nav.Name="MarketNav"
nav.AnchorPoint=Vector2.new(1,0)
nav.Position=UDim2.new(1,-16,0,112)
nav.Size=UDim2.fromOffset(118,196)
nav.BackgroundTransparency=1
nav.ZIndex=54
nav.Parent=gui

local navItems={{"Shop","STORE"},{"Emotes","EMOTES"},{"Quests","QUESTS"},{"Profile","PROFILE"}}
for i,item in ipairs(navItems) do
	local b=button(nav,item[1],item[2],UDim2.fromOffset(112,39),UDim2.fromOffset(0,(i-1)*48))
	b.ZIndex=55
	b.Activated:Connect(function()
		if item[1]=="Shop" then openStore("Featured")
		elseif item[1]=="Emotes" then openStore("Emotes")
		elseif item[1]=="Quests" then
			local stats=player:FindFirstChild("leaderstats")
			local kos=stats and stats:FindFirstChild("KOs")
			showStatus("DAILY 3 KOs • "..tostring(kos and kos:IsA("IntValue") and kos.Value or 0).." TOTAL KOs")
		elseif item[1]=="Profile" then
			local stats=player:FindFirstChild("leaderstats")
			local kos=stats and stats:FindFirstChild("KOs")
			local streak=stats and stats:FindFirstChild("Streak")
			showStatus("LV "..tostring(player:GetAttribute("Level") or 1).." • KOs "..tostring(kos and kos:IsA("IntValue") and kos.Value or 0).." • STREAK "..tostring(streak and streak:IsA("IntValue") and streak.Value or 0))
		end
	end)
end

local touchMenu=button(gui,"TouchMarketMenu","MENU",UDim2.fromOffset(66,36),UDim2.new(1,-16,0,68))
touchMenu.AnchorPoint=Vector2.new(1,0)
touchMenu.ZIndex=56

local function refreshNav()
	local touch=UserInputService.PreferredInput==Enum.PreferredInput.Touch
	nav.Visible=not touch
	touchMenu.Visible=touch
end

refreshNav()
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshNav)
touchMenu.Activated:Connect(function()
	openStore("Featured")
end)

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="ShopSync" and typeof(value)=="table" then
		table.clear(owned)
		for _,id in ipairs(value.Owned or {}) do owned[tostring(id)]=true end
		player:SetAttribute("EquippedEmote",tostring(value.EquippedEmote or ""))
		player:SetAttribute("EquippedSkin",tostring(value.EquippedSkin or ""))
		player:SetAttribute("EquippedTitle",tostring(value.EquippedTitle or ""))
		render()
	elseif kind=="ShopMessage" then
		showStatus(tostring(value))
		render()
	end
end)

local stats=player:WaitForChild("leaderstats",20)
if stats then
	local credits=stats:FindFirstChild("Credits")
	if credits and credits:IsA("IntValue") then
		credits:GetPropertyChangedSignal("Value"):Connect(function()
			if panel and panel.Visible then render() end
		end)
	end
end

utility:FireServer("ShopState")
