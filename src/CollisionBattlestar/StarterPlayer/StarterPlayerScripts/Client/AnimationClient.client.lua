--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local R=game:GetService("ReplicatedStorage")
local Animation=require(R.Shared.AnimationDefinitions)

local player=Players.LocalPlayer
local feedback=R:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local tracks:{[string]:AnimationTrack}={}
local character:Model?
local animator:Animator?
local fallbackToken=0

local function findJoint(model:Model,names:{string}):Motor6D?
	for _,name in ipairs(names)do
		local found=model:FindFirstChild(name,true)
		if found and found:IsA("Motor6D")then return found end
	end
	return nil
end

local function bind(c:Model)
	character=c
	tracks={}
	animator=nil
	local humanoid=c:WaitForChild("Humanoid",5)
	if not humanoid or not humanoid:IsA("Humanoid")then return end
	animator=humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator=Instance.new("Animator")
		animator.Parent=humanoid
	end
end

local function load(name:string):AnimationTrack?
	local def=Animation.Get(name)
	if not def or def.Id=="" or not animator then return nil end
	local existing=tracks[name]
	if existing then return existing end
	local animation=Instance.new("Animation")
	animation.Name="CBS_"..name
	animation.AnimationId=def.Id
	local ok,result=pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()
	if not ok or not result then return nil end
	local loaded=result::AnimationTrack
	loaded.Priority=def.Priority
	loaded.Looped=def.Looped
	tracks[name]=loaded
	return loaded
end

local function play(name:string,speed:number?)
	local loaded=load(name)
	if not loaded then return false end
	local def=Animation.Get(name)
	loaded:Play(.06,1,speed or (def and def.Speed or 1))
	return true
end

local function stop(name:string)
	local loaded=tracks[name]
	if loaded and loaded.IsPlaying then loaded:Stop(.06)end
end

local function fallback(action:string,combo:number)
	local c=character
	if not c then return end
	fallbackToken+=1
	local token=fallbackToken
	local right=findJoint(c,{"Right Shoulder","RightShoulder"})
	local left=findJoint(c,{"Left Shoulder","LeftShoulder"})
	local root=findJoint(c,{"RootJoint","Root"})
	local duration=action=="Heavy"and .34 or action=="Special"and .42 or action=="Dash"and .16 or action=="Parry"and .22 or .20
	local strength=action=="Heavy"and 1.25 or action=="Special"and 1.6 or action=="Dash"and .55 or action=="Parry"and .85 or (.72+.08*math.clamp(combo,0,4))
	if action=="BlockStart"then
		if right then right.Transform=CFrame.Angles(-.55,0,.35)end
		if left then left.Transform=CFrame.Angles(-.55,0,-.35)end
		return
	end
	task.spawn(function()
		local start=os.clock()
		while token==fallbackToken and c.Parent and os.clock()-start<duration do
			local alpha=math.clamp((os.clock()-start)/duration,0,1)
			local wave=math.sin(alpha*math.pi)*strength
			if right then right.Transform=CFrame.Angles(-wave,0,wave*.35)end
			if left then left.Transform=CFrame.Angles(wave*.55,0,-wave*.2)end
			if root then root.Transform=CFrame.Angles(0,0,-wave*.12)end
			RunService.RenderStepped:Wait()
		end
		if token==fallbackToken then
			if right then right.Transform=CFrame.identity end
			if left then left.Transform=CFrame.identity end
			if root then root.Transform=CFrame.identity end
		end
	end)
end

local function actionFromPayload(v:any):(string,number)
	if typeof(v)=="table"then
		local action=typeof(v.Action)=="string"and v.Action or"Light"
		local combo=typeof(v.Combo)=="number"and v.Combo or 1
		return action,math.floor(combo)
	end
	return"Light",1
end

feedback.OnClientEvent:Connect(function(key:string,value:any)
	if key=="Swing"then
		local action,combo=actionFromPayload(value)
		local trackName=action=="Light"and("Light"..tostring(math.clamp(combo,1,4)))or action
		if not play(trackName)then fallback(action,combo)end
	elseif key=="Special"then
		if not play("Special")then fallback("Special",0)end
	elseif key=="Dash"then
		if not play("Dash")then fallback("Dash",0)end
	elseif key=="Parry"then
		if not play("Parry")then fallback("Parry",0)end
	elseif key=="BlockStart"then
		if not play("Block")then fallback("BlockStart",0)end
	elseif key=="BlockEnd"then
		stop("Block")
		fallbackToken+=1
	end
end)

player.CharacterAdded:Connect(bind)
if player.Character then bind(player.Character)end
