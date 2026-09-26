--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local Net=require(ReplicatedStorage.Shared.Net)
local WorldService=require(script.Parent.Systems.WorldService)
local DataService=require(script.Parent.Systems.DataService)
local CombatService=require(script.Parent.Systems.CombatService)
local EconomyService=require(script.Parent.Systems.EconomyService)
local Config=require(ReplicatedStorage.Shared.Config)
local Routes=require(ReplicatedStorage.Shared.MapDefinitions)
local Catalog=require(ReplicatedStorage.Shared.StoreCatalog)

Players.CharacterAutoLoads=false

local remotes=ReplicatedStorage:FindFirstChild("CollisionRemotes")
if not remotes then
 remotes=Instance.new("Folder");remotes.Name="CollisionRemotes";remotes.Parent=ReplicatedStorage
end

local function ensureRemote(name:string,className:string):Instance
 local existing=remotes:FindFirstChild(name)
 if existing and existing.ClassName==className then return existing end
 if existing then existing:Destroy() end
 local object=Instance.new(className);object.Name=name;object.Parent=remotes
 return object
end

for _,name in pairs(Net.Reliable) do ensureRemote(name,"RemoteEvent") end
for _,name in pairs(Net.Unreliable) do ensureRemote(name,"UnreliableRemoteEvent") end

local combat=remotes:WaitForChild(Net.Reliable.CombatRequest) :: RemoteEvent
local movement=remotes:WaitForChild(Net.Reliable.MovementRequest) :: RemoteEvent
local utility=remotes:WaitForChild(Net.Reliable.UtilityRequest) :: RemoteEvent
local travel=remotes:WaitForChild(Net.Reliable.MapTravelRequest) :: RemoteEvent
local feedback=remotes:WaitForChild(Net.Reliable.Feedback) :: RemoteEvent
local gameState=remotes:WaitForChild(Net.Reliable.GameState) :: RemoteEvent
local fx=remotes:WaitForChild(Net.Unreliable.CombatFX) :: UnreliableRemoteEvent

WorldService:Build()
DataService:Init()
EconomyService:Init(DataService)
CombatService:Init(DataService,feedback,fx)

workspace:SetAttribute("CollisionBattlestarServerReady",true)
workspace:SetAttribute("CollisionBattlestarProtocol","CBS4")

local travelRate:{[Player]:number}={}
local utilityRate:{[Player]:number}={}

local function characterReady(player:Player,character:Model)
 local root=character:WaitForChild("HumanoidRootPart",8)
 local humanoid=character:WaitForChild("Humanoid",8)
 local spawn=WorldService:GetSpawn(tostring(player:GetAttribute("CurrentMapNode") or "Origin"))
 if root and root:IsA("BasePart") and spawn then
  character:PivotTo(CFrame.lookAt(spawn.Position+Vector3.new(0,4,0),spawn.Position+Vector3.new(8,4,0)))
 end
 if humanoid and humanoid:IsA("Humanoid") then
  humanoid.WalkSpeed=Config.Movement.WalkSpeed
  humanoid.JumpPower=Config.Movement.JumpPower
 end
 if player.Parent then gameState:FireClient(player,"Ready","server/runtime") end
end

local function bootPlayer(player:Player)
 task.spawn(function()
  while player.Parent and player:GetAttribute("DataReady")~=true do task.wait(.1) end
  if not player.Parent then return end
  gameState:FireClient(player,"ProfileReady",true)
  player.CharacterAdded:Connect(function(character) characterReady(player,character) end)
  task.wait(.05)
  if player.Parent then
   player:LoadCharacter()
  end
 end)
end

combat.OnServerEvent:Connect(function(player,action)
 if typeof(action)~="string" then return end
 CombatService:Handle(player,action)
end)

movement.OnServerEvent:Connect(function(player,action,value)
 if action=="Sprint" then CombatService:Movement(player,value) end
end)

travel.OnServerEvent:Connect(function(player,nodeId)
 if typeof(nodeId)~="string" then return end
 local t=os.clock()
 if t-(travelRate[player] or 0)<1.2 then return end
 travelRate[player]=t
 if not Routes.Get(nodeId) then return end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return end
 if (tonumber(player:GetAttribute("HitStunUntil")) or 0)>t then return end
 if WorldService:Teleport(player,nodeId) then feedback:FireClient(player,"Travel",{Name=Routes.Nodes[nodeId].Name,Id=nodeId}) end
end)

utility.OnServerEvent:Connect(function(player,action,value)
 local t=os.clock()
 if t-(utilityRate[player] or 0)<.12 then return end
 utilityRate[player]=t
 if typeof(action)~="string" then return end
 if action=="ShopState" then EconomyService:ShopState(player,feedback)
 elseif action=="BuyItem" and typeof(value)=="string" then EconomyService:BuyItem(player,value,feedback)
 elseif action=="EquipItem" and typeof(value)=="string" then EconomyService:EquipItem(player,value,feedback)
 elseif action=="SetCharacter" and typeof(value)=="string" then EconomyService:SetCharacter(player,value,feedback)
 elseif action=="RedeemCode" and typeof(value)=="string" then EconomyService:RedeemCode(player,value,feedback)
 elseif action=="ClaimMission" and typeof(value)=="string" then EconomyService:ClaimMission(player,value,feedback)
 elseif action=="Emote" and typeof(value)=="string" then
  local item=Catalog.Get(value)
  local p=DataService:Get(player)
  if item and item.Kind=="Emote" and p and (p.Owned[value]==true) then feedback:FireClient(player,"Emote",value) end
 elseif action=="Ping" and typeof(value)=="Vector3" then
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if root and (value-root.Position).Magnitude<=250 then fx:FireAllClients("Ping",value,{userId=player.UserId}) end
 end
end)

local productRewards:{[number]:number}={}
for _,bundle in ipairs(Catalog.Bundles) do
 if bundle.ProductId and bundle.ProductId>0 then productRewards[bundle.ProductId]=bundle.Robux end
end
MarketplaceService.ProcessReceipt=function(receiptInfo)
 local player=Players:GetPlayerByUserId(receiptInfo.PlayerId)
 local reward=productRewards[receiptInfo.ProductId]
 if not player or not reward then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local rewardMap={[49]=350,[119]=1000,[239]=2500,[399]=5000,[849]=7500,[2499]=15000,[5399]=30000}
 local credits=rewardMap[reward]
 if not credits then return Enum.ProductPurchaseDecision.NotProcessedYet end
 DataService:AddCredits(player,credits)
 feedback:FireClient(player,"Message","PURCHASE COMPLETE  •  +"..credits.." C")
 task.spawn(function() DataService:Save(player) end)
 return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerRemoving:Connect(function(player)
 travelRate[player]=nil;utilityRate[player]=nil
end)

for _,player in ipairs(Players:GetPlayers()) do bootPlayer(player) end
Players.PlayerAdded:Connect(bootPlayer)