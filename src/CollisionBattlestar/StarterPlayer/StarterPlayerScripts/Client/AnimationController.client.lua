--!strict
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local feedback=remotes:WaitForChild("Feedback")
local Profiles=require(ReplicatedStorage.Shared.AnimationProfiles)

type TrackMap={[string]:AnimationTrack}
local character:Model?
local animator:Animator?
local tracks:TrackMap={}
local loaded:{[string]:boolean}={}
local activeGroup:{[string]:string}={}

local function makeAnimation(id:string):Animation
	local animation=Instance.new("Animation")
	animation.AnimationId=id
	return animation
end

local function loadClip(name:string,id:string):AnimationTrack?
	if not animator then return nil end
	if loaded[name] == false then return nil end
	local animation=makeAnimation(id)
	local preloaded=pcall(function() ContentProvider:PreloadAsync({animation}) end)
	if not preloaded then
		loaded[name]=false
		animation:Destroy()
		return nil
	end
	local ok,result=pcall(function() return animator:LoadAnimation(animation) end)
	animation:Destroy()
	if not ok or not result or not result:IsA("AnimationTrack") then
		loaded[name]=false
		return nil
	end
	loaded[name]=true
	return result
end

local function stopGroup(group:string,fade:number)
	local active=activeGroup[group]
	if active then
		local track=tracks[active]
		if track and track.IsPlaying then track:Stop(fade) end
	end
	activeGroup[group]=nil
end

local function loadSet(setName:string)
	tracks={}
	loaded={}
	activeGroup={}
	local set=Profiles.Sets[setName]
	if not set then return end
	for key,clip in pairs(set.Clips) do
		local track=loadClip(key,clip.Id)
		if track then
			track.Priority=clip.Priority
			track.Looped=false
			tracks[key]=track
		end
	end
	player:SetAttribute("AnimationSet",set.Name)
	player:SetAttribute("AnimationSetSource",set.Source)
	player:SetAttribute("AnimationRuntimeReady",next(tracks)~=nil)
end

local function fallbackPose(kind:string,combo:number?)
	local current=character
	if not current then return end
	local function findMotor(name:string):Motor6D?
		local part=current:FindFirstChild(name,true)
		return part and part:IsA("Motor6D") and part or nil
	end
	local right=findMotor("RightShoulder")
	local left=findMotor("LeftShoulder")
	local root=findMotor("RootJoint") or findMotor("Waist")
	if kind=="Swing" then
		if right then
			right.Transform=CFrame.Angles(math.rad(12+(combo or 1)*4),math.rad(8),math.rad(34-(combo or 1)*8))
			task.delay(.11,function() if right.Parent then TweenService:Create(right,TweenInfo.new(.1),{Transform=CFrame.new()}):Play() end end)
		end
		if left then
			left.Transform=CFrame.Angles(math.rad(-8),math.rad(-10),math.rad(-20))
			task.delay(.1,function() if left.Parent then TweenService:Create(left,TweenInfo.new(.1),{Transform=CFrame.new()}):Play() end end)
		end
	elseif kind=="Dash" and root then
		root.Transform=CFrame.Angles(math.rad(-7),0,0)
		task.delay(.1,function() if root.Parent then TweenService:Create(root,TweenInfo.new(.11),{Transform=CFrame.new()}):Play() end end)
	elseif kind=="HitTaken" and root then
		root.Transform=CFrame.Angles(math.rad(6),0,math.rad(-6))
		task.delay(.07,function() if root.Parent then TweenService:Create(root,TweenInfo.new(.12),{Transform=CFrame.new()}):Play() end end)
	end
end

local function playClip(name:string,group:string,speed:number?)
	local track=tracks[name]
	if not track then return false end
	stopGroup(group,.025)
	track:Play(.035,0, speed or 1)
	track:AdjustWeight(1,.035)
	track:AdjustSpeed(speed or 1)
	activeGroup[group]=name
	return true
end

local function bind(newCharacter:Model)
	character=newCharacter
	animator=nil
	tracks={}
	loaded={}
	activeGroup={}
	local humanoid=newCharacter:WaitForChild("Humanoid",8)
	if not humanoid or not humanoid:IsA("Humanoid") then return end
	animator=humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator=Instance.new("Animator")
		animator.Parent=humanoid
	end
	local setName=(player.UserId%2==0) and "Vanguard" or "Impact"
	loadSet(setName)
	humanoid.Died:Connect(function()
		for _,track in pairs(tracks) do if track.IsPlaying then track:Stop(.05) end end
	end)
end

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Swing" and typeof(value)=="table" then
		local combo=math.clamp(tonumber(value.Combo)or 1,1,4)
		local clip=combo==1 and "M1_1" or combo==2 and "M1_2" or combo==3 and "M1_3" or "M1_2"
		if not playClip(clip,"Attack",combo==4 and .94 or nil) then fallbackPose("Swing",combo) end
	elseif kind=="Special" then
		local speed=typeof(value)=="table" and value.Charged and .82 or .92
		if not playClip("Special","Special",speed) then fallbackPose("Swing",4) end
	elseif kind=="Dash" then
		if not playClip("Dash","Movement",1.0) then fallbackPose("Dash") end
	elseif kind=="HitTaken" then
		if not playClip("HitTaken","Reaction",1.0) then fallbackPose("HitTaken") end
	end
end)

player.CharacterAdded:Connect(bind)
if player.Character then bind(player.Character) end
