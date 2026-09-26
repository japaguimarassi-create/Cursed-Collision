--!strict
local Players=game:GetService("Players")
local ContentProvider=game:GetService("ContentProvider")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local feedback=remotes:WaitForChild("Feedback")
local Profiles=require(ReplicatedStorage.Shared.AnimationProfiles)

type TrackMap={[string]:AnimationTrack}
local character:Model?
local humanoid:Humanoid?
local animator:Animator?
local tracks:TrackMap={}
local failed:{[string]:boolean}={}
local active:{[string]:string}={}
local guiConnections:{RBXScriptConnection}={}
local inputBound=false
local locomotionSerial=0

local function makeAnimation(id:string,name:string):Animation
	local animation=Instance.new("Animation")
	animation.Name=name
	animation.AnimationId=id
	return animation
end

local function loadTrack(name:string,clip:any):AnimationTrack?
	if not animator or failed[name] then return nil end
	local animation=makeAnimation(clip.Id,name)
	local okPreload=pcall(function()
		ContentProvider:PreloadAsync({animation})
	end)
	if not okPreload then
		failed[name]=true
		animation:Destroy()
		return nil
	end
	local ok,track=pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track or not track:IsA("AnimationTrack") then
		failed[name]=true
		animation:Destroy()
		return nil
	end
	track.Priority=clip.Priority
	track.Looped=clip.Looped
	track:AdjustSpeed(clip.Speed)
	animation.Parent=script
	return track
end

local function stop(name:string,fade:number)
	local track=tracks[name]
	if track and track.IsPlaying then track:Stop(fade) end
end

local function stopGroup(group:string,fade:number)
	local key=active[group]
	if key then stop(key,fade) end
	active[group]=nil
end

local function play(name:string,group:string,speed:number?,fade:number?):boolean
	local track=tracks[name]
	if not track then return false end
	stopGroup(group,fade or .04)
	local clipSpeed=speed or track.Speed
	track:Play(fade or .04,1,clipSpeed)
	track:AdjustWeight(1,fade or .04)
	track:AdjustSpeed(clipSpeed)
	active[group]=name
	return true
end

local function fallbackPose(kind:string,combo:number?)
	if not character then return end
	local function motor(name:string):Motor6D?
		local v=character:FindFirstChild(name,true)
		return v and v:IsA("Motor6D") and v or nil
	end
	local right=motor("RightShoulder")
	local left=motor("LeftShoulder")
	local root=motor("RootJoint") or motor("Waist")
	if kind=="attack" then
		local c=combo or 1
		if right then
			right.Transform=CFrame.Angles(math.rad(10+c*3),math.rad(8),math.rad(34-c*7))
			task.delay(.10,function() if right.Parent then TweenService:Create(right,TweenInfo.new(.10),{Transform=CFrame.new()}):Play() end end)
		end
		if left then
			left.Transform=CFrame.Angles(math.rad(-8),math.rad(-10),math.rad(-22))
			task.delay(.09,function() if left.Parent then TweenService:Create(left,TweenInfo.new(.10),{Transform=CFrame.new()}):Play() end end)
		end
	elseif kind=="dash" and root then
		root.Transform=CFrame.Angles(math.rad(-9),0,0)
		task.delay(.10,function() if root.Parent then TweenService:Create(root,TweenInfo.new(.12),{Transform=CFrame.new()}):Play() end end)
	elseif kind=="reaction" and root then
		root.Transform=CFrame.Angles(math.rad(7),0,math.rad(-7))
		task.delay(.07,function() if root.Parent then TweenService:Create(root,TweenInfo.new(.12),{Transform=CFrame.new()}):Play() end end)
	end
end

local function loadSet(setName:string)
	for _,track in pairs(tracks) do
		if track.IsPlaying then track:Stop(.02) end
		track:Destroy()
	end
	tracks={}
	failed={}
	active={}
	local set=Profiles.Sets[setName]
	if not set or not animator then return end
	for name,clip in pairs(set.Clips) do
		local track=loadTrack(name,clip)
		if track then tracks[name]=track end
	end
	player:SetAttribute("AnimationSet",set.Name)
	player:SetAttribute("AnimationRuntimeReady",tracks.Walk~=nil or tracks.M1_1~=nil)
end

local function locomotion(state:Enum.HumanoidStateType?)
	locomotionSerial+=1
	local serial=locomotionSerial
	if not humanoid then return end
	local move=humanoid.MoveDirection.Magnitude
	local current=state or humanoid:GetState()
	if current==Enum.HumanoidStateType.Jumping then
		if not play("Jump","Movement",1,.04) then fallbackPose("jump") end
	elseif current==Enum.HumanoidStateType.Freefall then
		if not play("Fall","Movement",1,.08) then fallbackPose("fall") end
	elseif move>.05 then
		local speed=math.clamp(humanoid.WalkSpeed/14.5,.72,1.65)
		if not play("Walk","Movement",speed,.08) then fallbackPose("walk") end
	else
		if not play("Idle","Movement",1,.12) then fallbackPose("idle") end
	end
	task.defer(function()
		if serial~=locomotionSerial then return end
	end)
end

local function bindCombatInput()
	if inputBound then return end
	inputBound=true
	UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			local combo=math.clamp(tonumber(player:GetAttribute("Combo"))or 1,1,4)
			local key="M1_"..combo
			if not play(key,"Attack",combo==4 and .94 or nil,.02) then
				if not play("M1_1","Attack",1,.02) then fallbackPose("attack",combo) end
			end
		elseif input.KeyCode==Enum.KeyCode.Q then
			if not play("Dash","Movement",1.6,.02) then fallbackPose("dash") end
		elseif input.KeyCode==Enum.KeyCode.R then
			if not play("Special","Special",.9,.03) then fallbackPose("attack",4) end
		end
	end)
end

local function bindGui()
	for _,connection in ipairs(guiConnections) do connection:Disconnect() end
	table.clear(guiConnections)
	local gui=playerGui:FindFirstChild("CollisionHUD")
	if not gui then return end
	local hotbar=gui:FindFirstChild("Hotbar")
	if hotbar then
		for _,name in ipairs({"Light","Dash","Special"}) do
			local button=hotbar:FindFirstChild(name)
			if button and button:IsA("GuiButton") then
				table.insert(guiConnections,button.Activated:Connect(function()
					if name=="Light" then
						local combo=math.clamp(tonumber(player:GetAttribute("Combo"))or 1,1,4)
						if not play("M1_"..combo,"Attack",1,.02) then
							if not play("M1_1","Attack",1,.02) then fallbackPose("attack",combo) end
						end
					elseif name=="Dash" then
						if not play("Dash","Movement",1.6,.02) then fallbackPose("dash") end
					else
						if not play("Special","Special",.9,.03) then fallbackPose("attack",4) end
					end
				end))
			end
		end
	end
	local mobile=gui:FindFirstChild("MobileActions")
	if mobile then
		for _,name in ipairs({"MobileM1","MobileDash","MobileSpecial"}) do
			local button=mobile:FindFirstChild(name)
			if button and button:IsA("GuiButton") then
				table.insert(guiConnections,button.Activated:Connect(function()
					local action=name=="MobileM1" and "Light" or name=="MobileDash" and "Dash" or "Special"
					if action=="Light" then
						local combo=math.clamp(tonumber(player:GetAttribute("Combo"))or 1,1,4)
						if not play("M1_"..combo,"Attack",1,.02) then fallbackPose("attack",combo) end
					elseif action=="Dash" then
						if not play("Dash","Movement",1.6,.02) then fallbackPose("dash") end
					else
						if not play("Special","Special",.9,.03) then fallbackPose("attack",4) end
					end
				end))
			end
		end
	end
end

local function bind(newCharacter:Model)
	character=newCharacter
	humanoid=nil
	animator=nil
	tracks={}
	failed={}
	active={}
	local h=newCharacter:WaitForChild("Humanoid",8)
	if not h or not h:IsA("Humanoid") then return end
	humanoid=h
	animator=h:FindFirstChildOfClass("Animator")
	if not animator then
		animator=Instance.new("Animator")
		animator.Parent=h
	end
	local setName=(player.UserId%2==0) and "Vanguard" or "Impact"
	loadSet(setName)
	humanoid.Running:Connect(function() locomotion() end)
	humanoid.StateChanged:Connect(function(_,state) locomotion(state) end)
	humanoid.Died:Connect(function() for _,track in pairs(tracks) do track:Stop(.05) end end)
	task.defer(function() locomotion() end)
	bindCombatInput()
	bindGui()
end

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Swing" and typeof(value)=="table" then
		local combo=math.clamp(tonumber(value.Combo)or 1,1,4)
		if not play("M1_"..combo,"Attack",combo==4 and .94 or nil,.02) then
			if not play("M1_1","Attack",1,.02) then fallbackPose("attack",combo) end
		end
	elseif kind=="Special" then
		if not play("Special","Special",.9,.03) then fallbackPose("attack",4) end
	elseif kind=="Dash" then
		if not play("Dash","Movement",1.6,.02) then fallbackPose("dash") end
	elseif kind=="HitTaken" then
		if not play("HitTaken","Reaction",1,.02) then fallbackPose("reaction") end
	elseif kind=="Block" and value==true then
		stopGroup("Attack",.04)
	end
end)

playerGui.ChildAdded:Connect(function(child)
	if child.Name=="CollisionHUD" then task.defer(bindGui) end
end)

player.CharacterAdded:Connect(bind)
if player.Character then bind(player.Character) end
