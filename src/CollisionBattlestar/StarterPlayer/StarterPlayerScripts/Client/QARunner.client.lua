--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local CaptureService=game:GetService("CaptureService")

local player=Players.LocalPlayer
if player.UserId~=game.CreatorId then return end

local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local control=remotes:WaitForChild("QAControl")
local reportEvent=remotes:WaitForChild("QAReport")
local guiParent=player:WaitForChild("PlayerGui")

local function exists(path:string):Instance?
	local current:Instance=guiParent
	for part in string.gmatch(path,"[^%.]+") do
		local nextValue=current:FindFirstChild(part)
		if not nextValue then return nil end
		current=nextValue
	end
	return current
end

local function visible(path:string):boolean
	local v=exists(path)
	return v~=nil and v:IsA("GuiObject") and v.Visible and (v.AbsoluteSize.X>0 and v.AbsoluteSize.Y>0)
end

local function inSafeBounds(v:GuiObject):boolean
	local camera=workspace.CurrentCamera
	if not camera then return false end
	local size=camera.ViewportSize
	local p=v.AbsolutePosition
	local s=v.AbsoluteSize
	return p.X>=-8 and p.Y>=-8 and p.X+s.X<=size.X+8 and p.Y+s.Y<=size.Y+8
end

local results={}
local function check(name:string,condition:boolean,detail:string)
	table.insert(results,{name=name,pass=condition,detail=detail})
end

local function waitFor(condition:()->boolean,timeout:number):boolean
	local expires=os.clock()+timeout
	while os.clock()<expires do
		if condition() then return true end
		task.wait(.1)
	end
	return false
end

local function detectorOverlay()
	local old=guiParent:FindFirstChild("CollisionQAOverlay")
	if old then old:Destroy() end
	local g=Instance.new("ScreenGui")
	g.Name="CollisionQAOverlay"
	g.DisplayOrder=2000
	g.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
	g.IgnoreGuiInset=false
	g.Parent=guiParent
	local panel=Instance.new("Frame")
	panel.Size=UDim2.fromOffset(330,320)
	panel.Position=UDim2.fromOffset(10,70)
	panel.BackgroundColor3=Color3.fromRGB(8,12,18)
	panel.BackgroundTransparency=.05
	panel.BorderSizePixel=0
	panel.Parent=g
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=panel
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,-20,0,32)
	title.Position=UDim2.fromOffset(10,8)
	title.BackgroundTransparency=1
	title.Font=Enum.Font.GothamBlack
	title.TextSize=17
	title.TextColor3=Color3.fromRGB(245,248,253)
	title.Text="COLLISION QA BOT"
	title.Parent=panel
	local list=Instance.new("Frame")
	list.Size=UDim2.new(1,-20,1,-52)
	list.Position=UDim2.fromOffset(10,44)
	list.BackgroundTransparency=1
	list.Parent=panel
	local layout=Instance.new("UIListLayout")
	layout.Padding=UDim.new(0,4)
	layout.Parent=list
	for _,r in ipairs(results) do
		local row=Instance.new("TextLabel")
		row.Size=UDim2.new(1,0,0,22)
		row.BackgroundTransparency=1
		row.Font=Enum.Font.GothamBold
		row.TextSize=10
		row.TextXAlignment=Enum.TextXAlignment.Left
		row.Text=(r.pass and "✓ " or "✗ ")..r.name.."  •  "..r.detail
		row.TextColor3=r.pass and Color3.fromRGB(90,230,150) or Color3.fromRGB(255,92,110)
		row.Parent=list
	end
	return g
end

local function capture()
	local report={}
	local ok,result=pcall(function()
		CaptureService:TakeScreenshotCaptureAsync(function(captureResult,screenshot)
			report.captureResult=tostring(captureResult)
			report.captureAvailable=screenshot~=nil
			if screenshot then
				local uploadOk,uploadResult=pcall(function() return CaptureService:UploadCaptureAsync(screenshot) end)
				report.captureUpload=uploadOk
				if uploadOk then report.captureAsset=tostring(uploadResult) end
			end
		end,{UICaptureMode=Enum.UICaptureMode.All})
		return true
	end)
	report.captureRequest=ok
	report.captureError=ok and "" or tostring(result)
	return report
end

local function run()
	results={}
	task.wait(1.5)

	local hud=exists("CollisionHUD")
	check("HUD exists",hud~=nil,"ScreenGui")
	check("HUD enabled",hud~=nil and hud:IsA("ScreenGui") and hud.Enabled,"Enabled")
	if hud and hud:IsA("ScreenGui") then
		check("Core UI safe area",hud.ScreenInsets==Enum.ScreenInsets.CoreUISafeInsets,tostring(hud.ScreenInsets))
	end

	for _,name in ipairs({"PlayerPanel","Health","Energy","Awakening","Hotbar","MobileActions","ShopPanel","MapPanel","QuestPanel","ProfilePanel"}) do
		check(name,exists("CollisionHUD."..name)~=nil,"found")
	end

	local camera=workspace.CurrentCamera
	if camera then
		local checks={"CollisionHUD.PlayerPanel","CollisionHUD.Utility","CollisionHUD.Location","CollisionHUD.Hotbar","CollisionHUD.MobileActions"}
		for _,path in ipairs(checks) do
			local v=exists(path)
			check(path.." bounds",v~=nil and v:IsA("GuiObject") and inSafeBounds(v),"safe bounds")
		end
	end

	control:FireServer("START")
	local botReady=waitFor(function() return workspace:FindFirstChild("CBS_QA_BOT")~=nil end,3)
	check("QA bot spawn",botReady,"server dummy")

	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local dummy=workspace:FindFirstChild("CBS_QA_BOT")
	local dummyHumanoid=dummy and dummy:FindFirstChildOfClass("Humanoid")
	if root and dummy and dummyHumanoid then
		root.CFrame=dummy:GetPivot()*CFrame.new(0,0,8)
		local before=dummyHumanoid.Health
		local light=find and nil
		combat:FireServer("Light")
		local hit=waitFor(function() return dummyHumanoid.Health<before end,1.5)
		check("M1 reaches QA bot",hit,"damage detected")
		local beforeDash=root.Position
		combat:FireServer("Dash")
		local dashMoved=waitFor(function() return (root.Position-beforeDash).Magnitude>4 end,.7)
		check("Dash moves player",dashMoved,"position changed")
		local okBlock=true
		combat:FireServer("BlockStart")
		task.wait(.1)
		local blocking=player:GetAttribute("Blocking")==true
		combat:FireServer("BlockEnd")
		okBlock=blocking and player:GetAttribute("Blocking")~=true
		check("Block state toggles",okBlock,"attribute toggled")
		combat:FireServer("Special")
		check("Special request accepted",true,"request sent")
	end

	for _,name in ipairs({"ShopPanel","MapPanel","QuestPanel","ProfilePanel"}) do
		local panel=exists("CollisionHUD."..name)
		check(name.." hidden by default",panel~=nil and panel:IsA("GuiObject") and not panel.Visible,"hidden")
	end

	local touch=UserInputService.TouchEnabled
	check("Mobile detector",touch==false or exists("CollisionHUD.MobileActions")~=nil,"touch branch")
	local screenshot=capture()
	local passed=0
	for _,r in ipairs(results) do if r.pass then passed+=1 end end
	local report={
		version="1.0",
		status=passed==#results and "PASS" or "FAIL",
		passed=passed,
		total=#results,
		results=results,
		platform={
			touch=UserInputService.TouchEnabled,
			keyboard=UserInputService.KeyboardEnabled,
			gamepad=UserInputService.GamepadEnabled,
			viewport=camera and tostring(camera.ViewportSize) or "unknown",
		},
		screenshot=screenshot,
	}
	local overlay=detectorOverlay()
	reportEvent:FireServer(report)
	task.delay(8,function() if overlay then overlay:Destroy() end end)
	control:FireServer("STOP")
end

task.spawn(run)
