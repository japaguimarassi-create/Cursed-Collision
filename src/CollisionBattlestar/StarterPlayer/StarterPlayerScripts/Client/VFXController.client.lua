--!strict
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local feedback=ReplicatedStorage:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local count=0
local limit=12

local function root():BasePart?
	local character=player.Character
	local part=character and character:FindFirstChild("HumanoidRootPart")
	return part and part:IsA("BasePart") and part or nil
end

local function effect(position:Vector3,kind:string)
	if count>=limit then return end
	count+=1
	local p=Instance.new("Part")
	p.Name="CBS_FX"
	p.Anchored=true
	p.CanCollide=false
	p.CanTouch=false
	p.CanQuery=false
	p.Material=Enum.Material.Neon
	p.Color=kind=="Special" and Color3.fromRGB(255,208,92) or Color3.fromRGB(92,198,255)
	p.Transparency=.2
	p.Size=kind=="Special" and Vector3.new(2,.2,2) or Vector3.new(1.2,.2,1.2)
	p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.rad(90))
	p.Shape=Enum.PartType.Cylinder
	p.Parent=workspace
	task.spawn(function()
		for step=1,8 do
			if not p.Parent then break end
			p.Size+=Vector3.new(0,.3,.3)
			p.Transparency=.2+step*.1
			task.wait(.025)
		end
	end)
	Debris:AddItem(p,.35)
	task.delay(.4,function() count=math.max(0,count-1) end)
end

feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if typeof(value)=="table" and typeof(value.Position)=="Vector3" then
		if kind=="Hit" or kind=="HitTaken" or kind=="Special" then effect(value.Position,kind) end
	elseif kind=="Dash" then
		local position=root()
		if position then effect(position.Position,"Dash") end
	end
end)
