--!strict
local Quest=require(script.Parent.QuestService);local U=require(game.ReplicatedStorage.Shared.Util)
local S={};local npcs={}
local function make(name:string,pos:Vector3,path:{Vector3},quest:boolean)
	local m=Instance.new("Model");m.Name=name;local root=U.Part(m,"HumanoidRootPart",Vector3.new(2.5,4,2.5),CFrame.new(pos),Enum.Material.SmoothPlastic,Color3.fromRGB(65,72,90),false);local head=U.Part(m,"Head",Vector3.new(2,2,2),CFrame.new(pos+Vector3.new(0,3,0)),Enum.Material.SmoothPlastic,Color3.fromRGB(210,175,150),false);head.Shape=Enum.PartType.Ball;local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=head;w.Parent=root;m.PrimaryPart=root;m.Parent=workspace.CBSNPCs;U.Nameplate(root,name,Color3.fromRGB(240,240,255))
	if quest then local p=Instance.new("ProximityPrompt");p.ActionText="Request Assignment";p.ObjectText="Fracture Response";p.HoldDuration=.4;p.MaxActivationDistance=10;p.Parent=root;p.Triggered:Connect(function(plr)Quest.Start(plr);game.ReplicatedStorage.CollisionRemotes.Feedback:FireClient(plr,"QuestStart","FIRST RESPONSE • DEFEAT 6 COLLISION CREATURES")end)end
	table.insert(npcs,{Model=m,Path=path,Index=1,Next=os.clock()+1})
end
function S.Init()
	local f=workspace:FindFirstChild("CBSNPCs")or Instance.new("Folder");f.Name="CBSNPCs";f.Parent=workspace
	make("Rhea",Vector3.new(-18,4,24),{Vector3.new(-18,4,24),Vector3.new(-18,4,40),Vector3.new(5,4,40),Vector3.new(5,4,24)},true)
	make("Orin",Vector3.new(22,4,-8),{Vector3.new(22,4,-8),Vector3.new(38,4,-8),Vector3.new(38,4,-26),Vector3.new(22,4,-26)},false)
	task.spawn(function()while task.wait(1)do for _,n in npcs do if n.Model.Parent and n.Model.PrimaryPart and os.clock()>=n.Next then n.Index=n.Index%#n.Path+1;local pos=n.Path[n.Index];n.Model:PivotTo(CFrame.lookAt(pos,pos+Vector3.new(1,0,0)));n.Next=os.clock()+3 end end end end)
end
return S
