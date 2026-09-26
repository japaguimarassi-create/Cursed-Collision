--!strict
local R=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")
local V=require(R.Shared.VFXDefinitions)

local feedback=R:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local worldState=R:WaitForChild("CollisionRemotes"):WaitForChild("WorldState")
local player=Players.LocalPlayer
local active=0

local function acquire():boolean
	if active>=V.Limits.MaxEffects then return false end
	active+=1
	return true
end

local function release(delayTime:number)
	task.delay(delayTime,function()active=math.max(0,active-1)end)
end

local function anchor(pos:Vector3):Part?
	if not acquire()then return nil end
	local p=Instance.new("Part")
	p.Name="CBS_FX"
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.CastShadow=false
	p.Transparency=1
	p.Size=Vector3.one
	p.CFrame=CFrame.new(pos)
	p.Parent=workspace
	Debris:AddItem(p,1.1)
	release(1.1)
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
end

local function shockwave(pos:Vector3,color:Color3,size:number)
	local p=anchor(pos)
	if not p then return end
	p.Transparency=0.12
	p.Material=Enum.Material.Neon
	p.Color=color
	p.Shape=Enum.PartType.Cylinder
	p.Size=Vector3.new(.25,size,size)
	p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90))
	local tween=TweenService:Create(p,TweenInfo.new(V.ImpactWaves.Default,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
		Size=Vector3.new(.25,size*4,size*4),
		Transparency=1,
	})
	tween:Play()
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
	beam.Width0=V.Trails.BladeWidth
	beam.Width1=.04
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
	task.delay(V.Trails.SlashFade,function()
		if beam.Parent then beam.Enabled=false end
	end)
end

local function rootPosition():Vector3?
	local c=player.Character
	local root=c and c:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root.Position or nil
end

local function bladeLimb(character:Model):BasePart?
	for _,name in ipairs({"RightHand","RightLowerArm","RightUpperArm","Right Arm"})do
		local part=character:FindFirstChild(name,true)
		if part and part:IsA("BasePart")then return part end
	end
	return nil
end

local function bladeTrail(character:Model,color:Color3,scale:number)
	local limb=bladeLimb(character)
	if not limb or not acquire()then return end
	local a0=Instance.new("Attachment")
	a0.Position=Vector3.new(0,scale*.65,scale*.7)
	a0.Parent=limb
	local a1=Instance.new("Attachment")
	a1.Position=Vector3.new(0,-scale*.65,scale*.7)
	a1.Parent=limb
	local trail=Instance.new("Trail")
	trail.Name="CBS_BladeTrail"
	trail.Attachment0=a0
	trail.Attachment1=a1
	trail.Lifetime=V.BladeTrail.Lifetime
	trail.MinLength=V.BladeTrail.MinLength
	trail.FaceCamera=true
	trail.LightEmission=1
	trail.Color=ColorSequence.new(color)
	trail.WidthScale=NumberSequence.new({
		NumberSequenceKeypoint.new(0,V.BladeTrail.Width.X),
		NumberSequenceKeypoint.new(1,V.BladeTrail.Width.Y),
	})
	trail.Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,.08),
		NumberSequenceKeypoint.new(1,1),
	})
	trail.Parent=limb
	task.delay(V.BladeTrail.Lifetime+V.BladeTrail.Fade,function()
		if trail.Parent then trail:Destroy()end
		if a0.Parent then a0:Destroy()end
		if a1.Parent then a1:Destroy()end
	end)
	release(V.BladeTrail.Lifetime+V.BladeTrail.Fade)
end

local function realityPulse(strength:number)
	if not acquire()then return end
	local responsive=CollectionService:GetTagged("CollisionResponsive")
	local changed={}
	for _,item in ipairs(responsive)do
		if item:IsA("BasePart")then
			table.insert(changed,{part=item,color=item.Color})
			TweenService:Create(item,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=V.Palette.Reality}):Play()
		end
	end
	local color=Instance.new("ColorCorrectionEffect")
	color.Name="CBS_RealityBreak"
	color.Brightness=.04*strength
	color.Contrast=.10*strength
	color.Saturation=.18*strength
	color.Parent=game:GetService("Lighting")
	TweenService:Create(color,TweenInfo.new(V.Limits.RealityLifetime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
		Brightness=0,Contrast=0,Saturation=0
	}):Play()
	Debris:AddItem(color,V.Limits.RealityLifetime+.08)
	task.delay(.28,function()
		for _,entry in ipairs(changed)do
			local part=entry.part
			if part and part.Parent then
				TweenService:Create(part,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=entry.color}):Play()
			end
		end
	end)
	release(V.Limits.RealityLifetime+.08)
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
			local character=player.Character
			if character then
				bladeTrail(character,color,math.max(1,action=="Special"and 1.8 or action=="Heavy"and 1.4 or 1.1))
			end
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

worldState.OnClientEvent:Connect(function(key:string,value:any)
	if key=="Warning"or key=="Begin"or key=="Escalation"or key=="Climax"then
		realityPulse(key=="Warning"and 1.35 or key=="Climax"and 1.8 or 1)
	elseif key=="End"then
		realityPulse(.55)
	end
end)