--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local UIS=game:GetService("UserInputService")
local p=Players.LocalPlayer;local remote=R:WaitForChild("CollisionRemotes"):WaitForChild("CombatRequest");local feedback=R.CollisionRemotes.Feedback
local function request(a:string)remote:FireServer(a)end
local function joint(c:Model,names:{string}):Motor6D?for _,n in names do local x=c:FindFirstChild(n,true);if x and x:IsA("Motor6D")then return x end end;return nil end
local function animate(kind:string)local c=p.Character;if not c then return end;local r=joint(c,{"Right Shoulder","RightShoulder"});local l=joint(c,{"Left Shoulder","LeftShoulder"});local root=joint(c,{"RootJoint","Root"});local d=kind=="Heavy"and .34 or kind=="Special"and .42 or .2;local m=kind=="Heavy"and 1.25 or kind=="Special"and 1.6 or .9;task.spawn(function()local t=os.clock();while c.Parent and os.clock()-t<d do local a=(os.clock()-t)/d;local q=math.sin(math.min(a,1)*math.pi)*m;if r then r.Transform=CFrame.Angles(-q,0,q*.35)end;if l then l.Transform=CFrame.Angles(q*.6,0,-q*.2)end;if root then root.Transform=CFrame.Angles(0,0,-q*.12)end;task.wait()end;if r then r.Transform=CFrame.identity end;if l then l.Transform=CFrame.identity end;if root then root.Transform=CFrame.identity end end)end
feedback.OnClientEvent:Connect(function(k)if k=="Swing"then animate("Light")elseif k=="Special"then animate("Special")end end)
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.UserInputType==Enum.UserInputType.MouseButton1 then request("Light");return end
	if input.UserInputType==Enum.UserInputType.MouseButton2 then request("BlockStart");return end
	if input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonX then request("Heavy")
	elseif input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.ButtonB then request("Dash")
	elseif input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonY then request("Special")
	elseif input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonA then request("Overdrive")
	elseif input.KeyCode==Enum.KeyCode.T or input.KeyCode==Enum.KeyCode.DPadUp then request("StyleToggle")
	elseif input.KeyCode==Enum.KeyCode.Space then request("Parry")
	elseif input.KeyCode==Enum.KeyCode.ButtonR2 then request("Light")
	elseif input.KeyCode==Enum.KeyCode.ButtonL2 then request("BlockStart") end
end)
UIS.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton2 or input.KeyCode==Enum.KeyCode.ButtonL2 then request("BlockEnd")end end)
return {}
