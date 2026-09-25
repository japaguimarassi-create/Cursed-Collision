--!strict
local R=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local V=require(R.Shared.VFXDefinitions)

local feedback=R:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local player=Players.LocalPlayer
local active=0

local function anchor(pos:Vector3):Part?
	if active>=V.Limits.MaxEffects then return nil end
	active+=1
	local p=Instance.new("Part")
	p.Name="CBS_FX"
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.Transparency=1
	p.Size=Vector3.one
	p.CFrame=CFrame.new(pos)
	p.Parent=workspace
	Debris:AddItem(p,1)
	task.delay(1,function()active=math.max(0,active-1)end)
	return p
end

local function burst(pos:Vector3,color:Color3,size:number,lifetime:number)
	local p=anchor(pos)
	if not p then return end
	local emitter=Instance.new("ParticleEmitter")
	emitter.Rate=0
	emitter.Lifetime=NumberRange.new(.12,.24)
	emitter.Speed=NumberRange.new(size*7,size*11)
	emitter.SpreadAngle=Vector2.new(180,180)
	emitter.Rotation=NumberRange.new(0,360)
	emitter.RotSpeed=NumberRange.new(-180,180)
	emitter.Size=NumberSequence.new({
		NumberSequenceKeypoint.new(0,size),
		NumberSequenceKeypoint.new(1,0),
	})
	emitter.Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,.05),
		NumberSequenceKeypoint.new(1,1),
	})
	emitter.Color=ColorSequence.new(color)
	emitter.Parent=p
	emitter:Emit(math.clamp(math.floor(8+size*8),8,24))

	local flash=Instance.new("Part")
	flash.Name="CBS_Flash"
	flash.Anchored=true
	flash.CanCollide=false
	flash.CanTouch=false
	flash.CanQuery=false
	flash.Material=Enum.Material.Neon
	flash.Color=color
	flash.Shape=Enum.PartType.Ball
	flash.Size=Vector3.new(size,size,size)
	flash.CFrame=CFrame.new(pos)
	flash.Parent=workspace

	local tween=TweenService:Create(flash,TweenInfo.new(lifetime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
		Size=Vector3.new(size*3.5,size*3.5,size*3.5),
		Transparency=1,
	})
	tween:Play()
	Debris:AddItem(flash,lifetime+.05)
end

local function shockwave(pos:Vector3,color:Color3,size:number)
	local p=Instance.new("Part")
	p.Name="CBS_Shockwave"
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.Material=Enum.Material.Neon
	p.Color=color
	p.Shape=Enum.PartType.Cylinder
	p.Size=Vector3.new(.25,size,size)
	p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90))
	p.Parent=workspace
	local tween=TweenService:Create(p,TweenInfo.new(.32,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
		Size=Vector3.new(.25,size*4,size*4),
		Transparency=1,
	})
	tween:Play()
	Debris:AddItem(p,.4)
end

local function beamSlash(pos:Vector3,color:Color3,scale:number)
	local p=anchor(pos)
	if not p then return end
	local a0=Instance.new("Attachment")
	a0.Position=Vector3.new(-scale,0,0)
	a0.Parent=p
	local a1=Instance.new("Attachment")
	a1.Position=Vector3.new(scale,0,0)
	a1.Parent=p
	local beam=Instance.new("Beam")
	beam.Attachment0=a0
	beam.Attachment1=a1
	beam.Width0=.75
	beam.Width1=.05
	beam.CurveSize0=scale*.45
	beam.CurveSize1=-scale*.45
	beam.FaceCamera=true
	beam.LightEmission=1
	beam.Color=ColorSequence.new(color)
	beam.Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,.05),
		NumberSequenceKeypoint.new(.6,.25),
		NumberSequenceKeypoint.new(1,1),
	})
	beam.Parent=p
	task.delay(.12,function()
		if beam.Parent then beam.Enabled=false end
	end)
end

local function rootPosition():Vector3?
	local c=player.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root.Position or nil
end

feedback.OnClientEvent:Connect(function(key:string,value:any)
	if (key=="Hit"or key=="HitTaken")and typeof(value)=="table"and typeof(value.Position)=="Vector3"then
		local color=key=="Hit"and V.Palette.Light or V.Palette.HitTaken
		local action=typeof(value.Action)=="string"and value.Action or"Light"
		local scale=action=="Special"and 1.2 or action=="Heavy"and .9 or .65
		burst(value.Position,color,scale,V.Limits.ImpactLifetime)
		shockwave(value.Position,color,scale)
		beamSlash(value.Position,color,scale*2.5)
	elseif key=="ParrySuccess"or key=="Parry"then
		local pos=rootPosition()
		if pos then burst(pos,V.Palette.Parry,.8,.3);shockwave(pos,V.Palette.Parry,1.5)end
	elseif key=="Dash"then
		local pos=rootPosition()
		if pos then burst(pos,V.Palette.Dash,.55,V.Limits.DashLifetime)end
	elseif key=="Swing"and typeof(value)=="table"then
		local pos=rootPosition()
		if pos then
			local action=typeof(value.Action)=="string"and value.Action or"Light"
			local color=action=="Heavy"and V.Palette.Heavy or action=="Special"and V.Palette.Special or V.Palette.Light
			beamSlash(pos,color,action=="Special"and 3.5 or 2.1)
		end
	elseif key=="OverdriveStart"then
		local pos=rootPosition()
		if pos then burst(pos,V.Palette.Overdrive,1.25,V.Limits.OverdriveLifetime);shockwave(pos,V.Palette.Overdrive,2)end
	elseif key=="OverdriveCollapse"then
		local pos=rootPosition()
		if pos then burst(pos,V.Palette.HitTaken,1.5,.5);shockwave(pos,V.Palette.HitTaken,2.4)end
	elseif key=="BreakFX"and typeof(value)=="table"and typeof(value.Position)=="Vector3"then
		local strength=typeof(value.Strength)=="number"and value.Strength or 1
		local size=typeof(value.Size)=="Vector3"and value.Size or Vector3.new(8,5,8)
		local radius=math.clamp(math.max(size.X,size.Z)*.12,1.2,4)
		burst(value.Position,V.Palette.Break,radius,.45)
		shockwave(value.Position,V.Palette.Break,radius)
		if strength>=2 then beamSlash(value.Position,V.Palette.Break,radius*2.5)end
	elseif key=="GuardBreak"then
		local pos=rootPosition()
		if pos then beamSlash(pos,V.Palette.Heavy,2.8)end
	end
end)
