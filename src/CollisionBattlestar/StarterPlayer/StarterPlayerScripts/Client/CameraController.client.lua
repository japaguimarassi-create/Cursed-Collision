--!strict
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local camera=workspace.CurrentCamera
local feedback=ReplicatedStorage:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
local baseFov=70
local busy=false
local activeTween:Tween?

local function tweenFov(value:number,duration:number)
	if not camera then return end
	if activeTween then activeTween:Cancel() end
	activeTween=TweenService:Create(camera,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{FieldOfView=value})
	activeTween:Play()
end

feedback.OnClientEvent:Connect(function(kind:string)
	if kind=="Dash" then
		tweenFov(baseFov+9,.08)
		task.delay(.1,function() tweenFov(baseFov,.16) end)
	elseif kind=="Special" then
		tweenFov(baseFov+7,.10)
		task.delay(.14,function() tweenFov(baseFov,.22) end)
	elseif kind=="Parry" and not busy then
		busy=true
		tweenFov(baseFov-4,.06)
		task.delay(.11,function() tweenFov(baseFov,.16);busy=false end)
	end
end)

player.CharacterAdded:Connect(function()
	task.delay(.5,function() if camera then camera.FieldOfView=baseFov end end)
end)
if camera then camera.FieldOfView=baseFov end
