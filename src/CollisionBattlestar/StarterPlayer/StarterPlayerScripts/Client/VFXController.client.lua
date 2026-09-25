--!strict
local R=game:GetService("ReplicatedStorage");local TweenService=game:GetService("TweenService");local Players=game:GetService("Players")
local feedback=R.CollisionRemotes.Feedback;local player=Players.LocalPlayer
local pool={};local busy={}
local function acquire():Part
	for _,p in ipairs(pool)do if not busy[p] then busy[p]=true;return p end end
	local p=Instance.new("Part");p.Name="CBS_FX";p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon;p.Size=Vector3.one;p.Parent=workspace;table.insert(pool,p);busy[p]=true;return p
end
local function release(p:Part)p.Transparency=1;busy[p]=nil end
local function burst(pos:Vector3,color:Color3,size:number)
	local p=acquire();p.Color=color;p.Size=Vector3.new(size,size,size);p.Transparency=.1;p.CFrame=CFrame.new(pos)
	local tw=TweenService:Create(p,TweenInfo.new(.24,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(size*3,size*3,size*3),Transparency=1});tw:Play();tw.Completed:Once(function()release(p)end)
end
local function ring(pos:Vector3,color:Color3)
	local p=acquire();p.Shape=Enum.PartType.Cylinder;p.Color=color;p.Size=Vector3.new(.2,.2,2);p.Transparency=.1;p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90))
	local tw=TweenService:Create(p,TweenInfo.new(.22),{Size=Vector3.new(.2,.2,18),Transparency=1});tw:Play();tw.Completed:Once(function()release(p)end)
end
feedback.OnClientEvent:Connect(function(k,v)
	if(k=="Hit"or k=="HitTaken")and v and typeof(v.Position)=="Vector3"then burst(v.Position,k=="Hit"and Color3.fromRGB(180,105,255)or Color3.fromRGB(255,110,110),.65)
	elseif k=="ParrySuccess"or k=="Parry"then local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then ring(r.Position,Color3.fromRGB(255,230,100))end
	elseif k=="Dash"then local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then burst(r.Position,Color3.fromRGB(110,200,255),.45)end
	elseif k=="OverdriveStart"then local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then burst(r.Position,Color3.fromRGB(255,130,75),1.2)end
	elseif k=="OverdriveCollapse"then local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if r and r:IsA("BasePart")then burst(r.Position,Color3.fromRGB(255,70,70),1.5)end end
end)
