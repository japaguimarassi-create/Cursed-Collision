--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")

local player=Players.LocalPlayer
local playerScripts=player:WaitForChild("PlayerScripts")
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local bootRequest=remotes:WaitForChild("BootRequest")
local bootFeedback=remotes:WaitForChild("BootFeedback")

local screen=Instance.new("ScreenGui")
screen.Name="CollisionBootScreen"
screen.ResetOnSpawn=false
screen.IgnoreGuiInset=false
screen.DisplayOrder=10000
screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screen.Parent=playerGui

local backdrop=Instance.new("Frame")
backdrop.Size=UDim2.fromScale(1,1)
backdrop.BackgroundColor3=Color3.fromRGB(7,10,15)
backdrop.BorderSizePixel=0
backdrop.Parent=screen

local glow=Instance.new("Frame")
glow.AnchorPoint=Vector2.new(.5,.5)
glow.Position=UDim2.fromScale(.5,.43)
glow.Size=UDim2.fromOffset(420,160)
glow.BackgroundColor3=Color3.fromRGB(25,38,58)
glow.BackgroundTransparency=.35
glow.BorderSizePixel=0
glow.Parent=backdrop
local glowCorner=Instance.new("UICorner")
glowCorner.CornerRadius=UDim.new(0,26)
glowCorner.Parent=glow

local card=Instance.new("Frame")
card.AnchorPoint=Vector2.new(.5,.5)
card.Position=UDim2.fromScale(.5,.46)
card.Size=UDim2.fromOffset(420,190)
card.BackgroundColor3=Color3.fromRGB(14,18,25)
card.BackgroundTransparency=.05
card.BorderSizePixel=0
card.Parent=backdrop
local cardCorner=Instance.new("UICorner")
cardCorner.CornerRadius=UDim.new(0,20)
cardCorner.Parent=card
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(69,84,106)
stroke.Transparency=.35
stroke.Thickness=1
stroke.Parent=card

local title=Instance.new("TextLabel")
title.BackgroundTransparency=1
title.Size=UDim2.new(1,-40,0,36)
title.Position=UDim2.fromOffset(20,22)
title.Font=Enum.Font.GothamBlack
title.Text="COLLISION BATTLESTAR"
title.TextColor3=Color3.fromRGB(244,247,252)
title.TextSize=24
title.TextXAlignment=Enum.TextXAlignment.Center
title.Parent=card

local stage=Instance.new("TextLabel")
stage.BackgroundTransparency=1
stage.Size=UDim2.new(1,-40,0,24)
stage.Position=UDim2.fromOffset(20,61)
stage.Font=Enum.Font.GothamSemibold
stage.Text="STARTING CORE"
stage.TextColor3=Color3.fromRGB(94,205,255)
stage.TextSize=13
stage.TextXAlignment=Enum.TextXAlignment.Center
stage.Parent=card

local status=Instance.new("TextLabel")
status.BackgroundTransparency=1
status.Size=UDim2.new(1,-48,0,44)
status.Position=UDim2.fromOffset(24,88)
status.Font=Enum.Font.Gotham
status.Text="Verificando mundo, HUD e sistemas..."
status.TextColor3=Color3.fromRGB(170,180,194)
status.TextSize=13
status.TextWrapped=true
status.TextXAlignment=Enum.TextXAlignment.Center
status.Parent=card

local barBack=Instance.new("Frame")
barBack.Size=UDim2.new(1,-48,0,8)
barBack.Position=UDim2.fromOffset(24,144)
barBack.BackgroundColor3=Color3.fromRGB(38,44,54)
barBack.BorderSizePixel=0
barBack.Parent=card
local barCorner=Instance.new("UICorner")
barCorner.CornerRadius=UDim.new(0,4)
barCorner.Parent=barBack

local bar=Instance.new("Frame")
bar.Size=UDim2.fromScale(0,1)
bar.BackgroundColor3=Color3.fromRGB(94,205,255)
bar.BorderSizePixel=0
bar.Parent=barBack
local barFillCorner=Instance.new("UICorner")
barFillCorner.CornerRadius=UDim.new(0,4)
barFillCorner.Parent=bar

local detail=Instance.new("TextLabel")
detail.BackgroundTransparency=1
detail.Size=UDim2.new(1,-48,0,20)
detail.Position=UDim2.fromOffset(24,158)
detail.Font=Enum.Font.GothamMedium
detail.Text="0 / 5 checks"
detail.TextColor3=Color3.fromRGB(118,128,143)
detail.TextSize=10
detail.TextXAlignment=Enum.TextXAlignment.Center
detail.Parent=card

local function setProgress(done:number,total:number)
	bar.Size=UDim2.new(math.clamp(done/total,0,1),0,1,0)
	detail.Text=("%d / %d checks"):format(done,total)
end

local function mapReady():boolean
	local world=workspace:FindFirstChild("CollisionBattlestarWorld")
	local map=world and world:FindFirstChild("Map")
	local spawns=world and world:FindFirstChild("Spawns")
	if not world or not map or not spawns then return false end
	if workspace:GetAttribute("CollisionBattlestarMapReady")~=true then return false end
	if world:GetAttribute("MapLoaded")~=true then return false end
	local plazas=0
	for _,name in ipairs({"Origin_Plaza","Metro_Plaza","Core_Plaza","Iron_Plaza","Apex_Plaza"}) do
		if map:FindFirstChild(name) then plazas+=1 end
	end
	local spawnCount=0
	for _,item in ipairs(spawns:GetChildren()) do
		if item:IsA("SpawnLocation") then spawnCount+=1 end
	end
	return plazas==5 and spawnCount>=5
end

local function hudReady():boolean
	local gui=playerGui:FindFirstChild("CollisionHUD")
	if not gui or not gui:IsA("ScreenGui") then return false end
	if not gui:FindFirstChild("Identity") then return false end
	if not gui:FindFirstChild("ActionBar") then return false end
	if not gui:FindFirstChild("OverdriveMeter") then return false end
	local action=gui:FindFirstChild("ActionBar")
	for _,name in ipairs({"Light","Dash","Block","Special"}) do
		if not action or not action:FindFirstChild(name) then return false end
	end
	return true
end

local function coreReady():boolean
	return ReplicatedStorage:FindFirstChild("Shared")~=nil and ReplicatedStorage:FindFirstChild("CollisionRemotes")~=nil
end

local function characterReady():boolean
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	return humanoid~=nil and root~=nil and humanoid.Health>0
end

local function restartLocalScript(name:string)
	local existing=playerScripts:FindFirstChild(name)
	local template=playerScripts:FindFirstChild(name)
	if template and template:IsA("LocalScript") then
		local clone=template:Clone()
		clone.Name=name.."_Recovery"
		clone.Disabled=false
		clone.Parent=playerScripts
		return true
	end
	return false
end

local function recover()
	status.Text="Falha detectada. Forçando correção e recarregamento..."
	stage.Text="RECOVERY"
	bar.BackgroundColor3=Color3.fromRGB(255,120,120)
	pcall(function() bootRequest:FireServer("Recover") end)
	for _,name in ipairs({"MainController.client","PlatformHUDController.client","AnimationController.client","VFXController.client","CameraController.client"}) do
		restartLocalScript(name)
	end
	task.wait(1)
end

bootFeedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Retry" then
		status.Text="Servidor encontrou uma falha. Recriando componentes..."
	elseif kind=="Ready" then
		status.Text="Servidor pronto. Finalizando verificações locais..."
	elseif kind=="Checking" then
		status.Text="Executando verificação do núcleo..."
	end
end)

local start=os.clock()
local lastRecovery=0
local recoveryCount=0
local completed=false

while screen.Parent and not completed do
	local checks={
		coreReady(),
		workspace:GetAttribute("CollisionBattlestarReady")==true,
		mapReady(),
		hudReady(),
		characterReady(),
	}
	local done=0
	for _,ok in ipairs(checks) do if ok then done+=1 end end
	setProgress(done,#checks)

	if checks[1]==false then
		stage.Text="CORE"
		status.Text="Aguardando os sistemas básicos do servidor..."
	elseif checks[2]==false then
		stage.Text="BOOT"
		status.Text=tostring(workspace:GetAttribute("CollisionBattlestarBootStage") or "starting").."..."
	elseif checks[3]==false then
		stage.Text="MAP"
		status.Text="Construindo e verificando o mapa urbano..."
	elseif checks[4]==false then
		stage.Text="HUD"
		status.Text="Carregando interface de combate..."
	elseif checks[5]==false then
		stage.Text="PLAYER"
		status.Text="Preparando o personagem..."
	else
		stage.Text="READY"
		status.Text="Todos os sistemas responderam corretamente."
		completed=true
		break
	end

	local elapsed=os.clock()-start
	if elapsed>7 and done<5 and os.clock()-lastRecovery>4 and recoveryCount<5 then
		lastRecovery=os.clock()
		recoveryCount+=1
		recover()
	elseif elapsed>32 and done<5 then
		status.Text="Recuperação contínua em andamento..."
		pcall(function() bootRequest:FireServer("Recover") end)
	end
	task.wait(.2)
end

if completed then
	TweenService:Create(card,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.43)}):Play()
	task.wait(.18)
	screen:Destroy()
end
