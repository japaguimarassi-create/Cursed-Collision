--!strict
local Players=game:GetService("Players")
local ServerStorage=game:GetService("ServerStorage")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local QA=require(ReplicatedStorage.Shared.QAContract)

local M={}
local reportsFolder=Instance.new("Folder")
reportsFolder.Name="CollisionQA"
reportsFolder.Parent=ServerStorage
local reportValue=Instance.new("StringValue")
reportValue.Name="LatestReport"
reportValue.Value="{}"
reportValue.Parent=reportsFolder
local bot:Model?

local function owner(player:Player):boolean
 return player.UserId==game.CreatorId
end

local function createPart(parent:Instance,name:string,size:Vector3,pos:Vector3,color:Color3):Part
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=pos;p.Anchored=true;p.CanCollide=true;p.CanTouch=true;p.CanQuery=true;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=parent
 return p
end

local function destroyBot()
 if bot and bot.Parent then bot:Destroy() end
 bot=nil
end

local function spawnBot(player:Player)
 destroyBot()
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return end
 local model=Instance.new("Model");model.Name=QA.DummyName;model.Parent=workspace
 local hrp=createPart(model,"HumanoidRootPart",Vector3.new(2,2,1),root.Position+root.CFrame.LookVector*10+Vector3.new(0,3,0),Color3.fromRGB(110,110,120))
 local torso=createPart(model,"Torso",Vector3.new(3,4,2),hrp.Position+Vector3.new(0,2.7,0),Color3.fromRGB(70,75,84))
 local head=createPart(model,"Head",Vector3.new(2,2,2),torso.Position+Vector3.new(0,3,0),Color3.fromRGB(214,178,151))
 local humanoid=Instance.new("Humanoid");humanoid.MaxHealth=1000;humanoid.Health=1000;humanoid.DisplayName="QA BOT";humanoid.Parent=model
 model.PrimaryPart=hrp
 local weld1=Instance.new("WeldConstraint");weld1.Part0=hrp;weld1.Part1=torso;weld1.Parent=hrp
 local weld2=Instance.new("WeldConstraint");weld2.Part0=torso;weld2.Part1=head;weld2.Parent=torso
 local highlight=Instance.new("Highlight");highlight.FillTransparency=.75;highlight.OutlineColor=Color3.fromRGB(255,196,82);highlight.Parent=model
 model:SetAttribute("CollisionQABot",true)
 bot=model
end

local function moveBot(position:Vector3)
 if not bot or not bot.PrimaryPart then return end
 bot:PivotTo(CFrame.new(position))
end

function M:Init(remotes)
 local reportEvent=remotes:WaitForChild(QA.ReportEvent) :: RemoteEvent
 local controlEvent=remotes:WaitForChild(QA.ControlEvent) :: RemoteEvent
 reportEvent.OnServerEvent:Connect(function(player,data)
  if not owner(player) or typeof(data)~="table" then return end
  local safe={}
  safe.status=tostring(data.status or "UNKNOWN")
  safe.timestamp=os.time()
  safe.playerCount=#Players:GetPlayers()
  safe.serverReady=workspace:GetAttribute("CollisionBattlestarServerReady")==true
  safe.mapReady=workspace:GetAttribute("CollisionBattlestarMapReady")==true
  safe.worldParts=tonumber(workspace:GetAttribute("CollisionBattlestarWorldPartCount")) or #workspace:GetDescendants()
  safe.detectors=typeof(data.detectors)=="table" and data.detectors or {}
  safe.runtime=typeof(data.runtime)=="table" and data.runtime or {}
  reportValue.Value=game:GetService("HttpService"):JSONEncode(safe)
 end)
 controlEvent.OnServerEvent:Connect(function(player,action,value)
  if not owner(player) or typeof(action)~="string" then return end
  if action=="SpawnBot" then spawnBot(player)
  elseif action=="DestroyBot" then destroyBot()
  elseif action=="MoveBot" and typeof(value)=="Vector3" then moveBot(value)
  end
 end)
 Players.PlayerRemoving:Connect(function(player) if owner(player) then destroyBot() end end)
end
return M