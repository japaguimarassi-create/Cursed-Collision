--!strict
local R=game:GetService("ReplicatedStorage");local TweenService=game:GetService("TweenService");local Debris=game:GetService("Debris");local Players=game:GetService("Players")
local feedback=R.CollisionRemotes.Feedback;local p=Players.LocalPlayer
local function burst(pos:Vector3,color:Color3,size:number)local x=Instance.new("Part");x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.Shape=Enum.PartType.Ball;x.Material=Enum.Material.Neon;x.Color=color;x.Size=Vector3.new(size,size,size);x.CFrame=CFrame.new(pos);x.Parent=workspace;TweenService:Create(x,TweenInfo.new(.24,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(size*3,size*3,size*3),Transparency=1}):Play();Debris:AddItem(x,.3)end
local function ring(pos:Vector3,color:Color3)local x=Instance.new("Part");x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.Shape=Enum.PartType.Cylinder;x.Material=Enum.Material.Neon;x.Color=color;x.Size=Vector3.new(.2,.2,2);x.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90));x.Parent=workspace;TweenService:Create(x,TweenInfo.new(.22),{Size=Vector3.new(.2,.2,18),Transparency=1}):Play();Debris:AddItem(x,.28)end
feedback.OnClientEvent:Connect(function(k,v)
	if(k=="Hit"or k=="HitTaken")and v and typeof(v.Position)=="Vector3"then burst(v.Position,k=="Hit"and Color3.fromRGB(180,105,255)or Color3.fromRGB(255,110,110),.65)
	elseif k=="ParrySuccess"or k=="Parry"then local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then ring(r.Position,Color3.fromRGB(255,230,100))end
	elseif k=="Dash"then local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then burst(r.Position,Color3.fromRGB(110,200,255),.45)end
	elseif k=="OverdriveStart"then local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then burst(r.Position,Color3.fromRGB(255,130,75),1.2)end
	elseif k=="OverdriveCollapse"then local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then burst(r.Position,Color3.fromRGB(255,70,70),1.5)end end
end)
