--!strict
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local feedback=ReplicatedStorage:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local Config=require(ReplicatedStorage.Shared.Config)
local active=0
local limit=20

local function spawnPart(position:Vector3,size:Vector3,color:Color3,shape:Enum.PartType,life:number)
	if active>=limit then return nil end
	active+=1
	local part=Instance.new("Part")
	part.Name="CBS_FX"
	part.Anchored=true
	part.CanCollide=false
	part.CanTouch=false
	part.CanQuery=false
	part.Material=Enum.Material.Neon
	part.Color=color
	part.Transparency=.16
	part.Size=size
	part.Shape=shape
	part.CFrame=CFrame.new(position)
	part.Parent=workspace
	Debris:AddItem(part,life)
	task.delay(life+.05,function() active=math.max(0,active-1) end)
	return part
end

local function ring(position:Vector3,color:Color3,big:boolean)
	local p=spawnPart(position,Vector3.new(1,.16,1),color,Enum.PartType.Cylinder,.42)
	if not p then return end
	p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.rad(90))
	TweenService:Create(p,TweenInfo.new(.34,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=big and Vector3.new(1,7,7) or Vector3.new(1,4.5,4.5),Transparency=1}):Play()
end

local function burst(position:Vector3,color:Color3)
	for i=1,4 do
		local p=spawnPart(position,Vector3.new(.25,.25,.25),color,Enum.PartType.Ball,.35)
		if p then
			local angle=(math.pi*2)*((i-1)/4)
			TweenService:Create(p,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
				Position=position+Vector3.new(math.cos(angle),.35,math.sin(angle))*5,
				Transparency=1,
				Size=Vector3.new(.08,.08,.08),
			}):Play()
		end
	end
end

local function damageText(position:Vector3,damage:number,critical:boolean)
	if active>=limit then return end
	active+=1
	local gui=Instance.new("BillboardGui")
	gui.Name="Damage"
	gui.Size=UDim2.fromOffset(100,40)
	gui.StudsOffset=Vector3.new(0,2.8,0)
	gui.AlwaysOnTop=true
	gui.MaxDistance=90
	gui.Parent=workspace
	local holder=Instance.new("TextLabel")
	holder.Size=UDim2.fromScale(1,1)
	holder.BackgroundTransparency=1
	holder.Text=tostring(math.floor(damage+.5))
	holder.TextColor3=critical and Config.UI.Accent2 or Config.UI.Text
	holder.TextStrokeTransparency=.55
	holder.Font=Enum.Font.GothamBlack
	holder.TextSize=critical and 24 or 19
	holder.Parent=gui
	local anchor=Instance.new("Part")
	anchor.Anchored=true
	anchor.CanCollide=false
	anchor.CanTouch=false
	anchor.CanQuery=false
	anchor.Transparency=1
	anchor.Size=Vector3.new(.2,.2,.2)
	anchor.Position=position
	anchor.Parent=workspace
	gui.Adornee=anchor
	TweenService:Create(gui,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{StudsOffset=Vector3.new(0,5,0)}):Play()
	TweenService:Create(holder,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1,TextStrokeTransparency=1}):Play()
	Debris:AddItem(anchor,.55)
	Debris:AddItem(gui,.55)
	task.delay(.6,function() active=math.max(0,active-1) end)
end

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if player:GetAttribute("LocalFXHigh") == false and (kind=="Hit" or kind=="HitTaken" or kind=="Guard" or kind=="GuardBreak" or kind=="Evade" or kind=="Special" or kind=="Dash" or kind=="Swing" or kind=="DestructHit") then
		return
	end
	if typeof(value)=="table" and typeof(value.Position)=="Vector3" then
		local position=value.Position
		if kind=="Hit" then
			ring(position,Config.UI.Accent,value.Finisher==true)
			burst(position,Config.UI.Accent)
			if typeof(value.Damage)=="number" then damageText(position,value.Damage,value.Finisher==true) end
		elseif kind=="HitTaken" then
			ring(position,Config.UI.Danger,false)
		elseif kind=="Guard" then
			ring(position,Config.UI.Accent,false)
		elseif kind=="GuardBreak" then
			ring(position,Config.UI.Danger,true)
		elseif kind=="Evade" then
			burst(position,Config.UI.Text)
		elseif kind=="Special" then
			ring(position,Config.UI.Accent2,true)
			burst(position,Config.UI.Accent2)
		end
	elseif kind=="Dash" and typeof(value)=="table" and typeof(value.Position)=="Vector3" then
		ring(value.Position,Config.UI.Accent,false)
	elseif kind=="Parry" then
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then burst(root.Position,Config.UI.Accent2) end
	elseif kind=="Swing" and typeof(value)=="table" and typeof(value.Position)=="Vector3" then
		ring(value.Position,Config.UI.Accent,false)
	elseif kind=="DestructHit" and typeof(value)=="table" and typeof(value.Position)=="Vector3" then
		ring(value.Position,Config.UI.Accent2,false)
	end
end)
