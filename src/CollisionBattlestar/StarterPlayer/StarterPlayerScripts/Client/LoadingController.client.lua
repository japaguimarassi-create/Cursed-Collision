--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local bootRequest=remotes:WaitForChild("BootRequest")
local bootFeedback=remotes:WaitForChild("BootFeedback")
local HUDRecovery=require(ReplicatedStorage.Shared.HUDRecovery)

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
local cardStroke=Instance.new("UIStroke")
cardStroke.Color=Color3.fromRGB(69,84,106)
cardStroke.Transparency=.35
cardStroke.Thickness=1
cardStroke.Parent=card

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
	return HUDRecovery.IsReady()
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

local function forceHudRecovery():boolean
	local result=HUDRecovery.Build()
	return result~=nil and HUDRecovery.IsReady()
end

bootFeedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Retry" then
		stage.Text="RECOVERY"
		status.Text="Servidor encontrou uma falha. Recriando os componentes..."
	elseif kind=="Ready" then
		status.Text="Servidor pronto. Finalizando verificações locais..."
	elseif kind=="Checking" then
		status.Text="Executando verificação do núcleo..."
	end
end)

task.defer(function()
	pcall(function() bootRequest:FireServer("Initial") end)
end)

local start=os.clock()
local lastServerRepair=0
local lastHudRepair=0
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

	if not checks[1] then
		stage.Text="CORE"
		status.Text="Aguardando os sistemas básicos..."
	elseif not checks[2] then
		stage.Text="BOOT"
		status.Text=tostring(workspace:GetAttribute("CollisionBattlestarBootStage") or "starting").."..."
		if os.clock()-lastServerRepair>2 then
			lastServerRepair=os.clock()
			pcall(function() bootRequest:FireServer("Repair") end)
		end
	elseif not checks[3] then
		stage.Text="MAP"
		status.Text="Verificando e reconstruindo o mapa urbano..."
	elseif not checks[4] then
		stage.Text="HUD"
		status.Text="Reconstruindo a interface de combate..."
		if os.clock()-lastHudRepair>.8 then
			lastHudRepair=os.clock()
			if forceHudRecovery() then
				status.Text="Interface recuperada. Verificando..."
			end
		end
	elseif not checks[5] then
		stage.Text="PLAYER"
		status.Text="Preparando o personagem..."
	else
		stage.Text="READY"
		status.Text="Todos os sistemas responderam corretamente."
		completed=true
		break
	end

	if os.clock()-start>30 and not completed then
		stage.Text="RECOVERY"
		status.Text="Recuperação automática contínua..."
		pcall(function() bootRequest:FireServer("Recovery") end)
		for _=1,2 do forceHudRecovery() end
	end

	task.wait(.2)
end

if completed then
	TweenService:Create(card,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.43)}):Play()
	task.wait(.18)
	screen:Destroy()
end
