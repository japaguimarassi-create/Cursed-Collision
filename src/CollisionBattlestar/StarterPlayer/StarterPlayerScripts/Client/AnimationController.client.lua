--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local feedback=ReplicatedStorage:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local current:Model?
local tracks:{[string]:{Motor6D}}={}

local function findMotor(character:Model,name:string):Motor6D?
	local found=character:FindFirstChild(name,true)
	return found and found:IsA("Motor6D") and found or nil
end

local function bind(character:Model)
	current=character
	tracks={Root={},Left={},Right={}}
	for _,name in ipairs({"RootJoint","Waist","LeftShoulder","RightShoulder","LeftHip","RightHip"}) do
		local motor=findMotor(character,name)
		if motor then
			if name=="RootJoint" or name=="Waist" then table.insert(tracks.Root,motor)
			elseif string.find(name,"Left") then table.insert(tracks.Left,motor)
			else table.insert(tracks.Right,motor) end
		end
	end
end

local function tweenMotor(motor:Motor6D,target:CFrame,duration:number)
	local value=Instance.new("CFrameValue")
	value.Value=motor.Transform
	local connection=value.Changed:Connect(function(cf) if motor.Parent then motor.Transform=cf end end)
	local tween=TweenService:Create(value,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=target})
	tween.Completed:Connect(function() connection:Disconnect();value:Destroy() end)
	tween:Play()
end

local function pose(combo:number)
	if not current then return end
	for _,motor in ipairs(tracks.Left) do tweenMotor(motor,CFrame.Angles(math.rad(-8),math.rad(-10),math.rad(-22)),.05) end
	for _,motor in ipairs(tracks.Right) do tweenMotor(motor,CFrame.Angles(math.rad(12+combo*3),math.rad(8),math.rad(35-combo*8)),.05) end
	task.delay(.08,function()
		if current then
			for _,motor in ipairs(tracks.Left) do if motor.Parent then tweenMotor(motor,CFrame.new(),.11) end end
			for _,motor in ipairs(tracks.Right) do if motor.Parent then tweenMotor(motor,CFrame.new(),.11) end end
		end
	end)
end

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="Swing" and typeof(value)=="table" then pose(math.clamp(tonumber(value.Combo)or 1,1,4)) end
	if kind=="Dash" and current then
		for _,motor in ipairs(tracks.Root) do if motor.Parent then tweenMotor(motor,CFrame.Angles(math.rad(-7),0,0),.06) end end
		task.delay(.08,function() for _,motor in ipairs(tracks.Root) do if motor.Parent then tweenMotor(motor,CFrame.new(),.10) end end end)
	end
	if kind=="HitTaken" and current then
		for _,motor in ipairs(tracks.Root) do if motor.Parent then tweenMotor(motor,CFrame.Angles(math.rad(6),0,math.rad(-6)),.05) end end
		task.delay(.06,function() for _,motor in ipairs(tracks.Root) do if motor.Parent then tweenMotor(motor,CFrame.new(),.12) end end end)
	end
end)

player.CharacterAdded:Connect(bind)
if player.Character then bind(player.Character) end
