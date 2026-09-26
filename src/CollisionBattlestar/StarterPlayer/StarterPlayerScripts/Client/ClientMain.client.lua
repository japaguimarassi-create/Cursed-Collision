--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local ContentProvider=game:GetService("ContentProvider")

local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("Shared")
local HUD=require(Shared.UI.HUDLayout)
local UI=require(script.Parent.UIController)
local FX=require(script.Parent.FXController)
local Camera=require(script.Parent.CameraController)
local QA=require(script.Parent.QAClient)

local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local combat=remotes:WaitForChild("CombatRequest") :: RemoteEvent
local movement=remotes:WaitForChild("MovementRequest") :: RemoteEvent
local gameState=remotes:WaitForChild("GameState") :: RemoteEvent

local gui:ScreenGui
local bootDone=false
local serverProfileReady=false
local serverReady=false
local agentState:{[string]:string}={QA="WAIT",HUD="WAIT",COMBAT="WAIT",ASSETS="WAIT"}

local okGui,built=pcall(HUD.Build)
if okGui and built and built:IsA("ScreenGui") then
 gui=built
else
 return
end

UI:Bind(gui,remotes)
FX:Init(remotes)
Camera:Init()

local function node(name:string):Instance?
 return gui:FindFirstChild(name)
end

local function setBoot(agent:string,state:string)
 agentState[agent]=state
 local loading=node("LoadingScreen")
 if not loading then return end
 local card=loading:FindFirstChild("Agent_"..agent)
 local dot=card and card:FindFirstChild("Dot")
 local stateLabel=card and card:FindFirstChild("State")
 if stateLabel and stateLabel:IsA("TextLabel") then stateLabel.Text=state end
 if dot and dot:IsA("Frame") then
  dot.BackgroundColor3=state=="PASS" and Color3.fromRGB(84,228,164) or state=="FAIL" and Color3.fromRGB(255,92,108) or state=="RUN" and Color3.fromRGB(91,211,255) or Color3.fromRGB(143,157,177)
 end
end

local function setProgress(value:number,status:string,detail:string)
 local loading=node("LoadingScreen")
 if not loading then return end
 local s=loading:FindFirstChild("Status")
 local d=loading:FindFirstChild("Detail")
 local track=loading:FindFirstChild("ProgressTrack")
 local fill=track and track:FindFirstChild("Fill")
 if s and s:IsA("TextLabel") then s.Text=status end
 if d and d:IsA("TextLabel") then d.Text=detail end
 if fill and fill:IsA("Frame") then TweenService:Create(fill,TweenInfo.new(.2,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(math.clamp(value,0,1),1)}):Play() end
end

local function waitFor(predicate:()->boolean,timeout:number):boolean
 local deadline=os.clock()+timeout
 while os.clock()<deadline do
  if predicate() then return true end
  task.wait(.1)
 end
 return predicate()
end

local function checkQA():boolean
 if player.UserId~=game.CreatorId then return true end
 return remotes:FindFirstChild("QAReport")~=nil and remotes:FindFirstChild("QAControl")~=nil
end

local function checkHUD():boolean
 local required={"CollisionHUD","LoadingScreen","PlayerPanel","Health","Energy","Awakening","Hotbar","MobileActions","MapPanel","ShopPanel","FighterPanel","QuestPanel","ProfilePanel","Notice"}
 for _,name in ipairs(required) do
  if not node(name) then return false end
 end
 return gui.Enabled and gui.ScreenInsets==Enum.ScreenInsets.CoreUISafeInsets
end

local function checkCombat():boolean
 return serverReady and player:GetAttribute("DataReady")==true and waitFor(function()
  local c=player.Character
  return c~=nil and c:FindFirstChild("Humanoid")~=nil and c:FindFirstChild("HumanoidRootPart")~=nil
 end,5)
end

local function checkAssets():boolean
 local world=workspace:FindFirstChild("CollisionBattlestarWorld")
 local map=world and world:FindFirstChild("Map")
 if not world or not map then return false end
 if workspace:GetAttribute("CollisionBattlestarMapReady")~=true then return false end
 for _,id in ipairs({"Origin","Metro","Core","Iron","Apex"}) do if not map:FindFirstChild(id) then return false end end
 return true
end

local function startBoot()
 local loading=node("LoadingScreen")
 if not loading or not loading:IsA("Frame") then bootDone=true;return end
 loading.Visible=true
 local sequence={{"QA","INTERNAL QA",checkQA},{"HUD","HUD",checkHUD},{"COMBAT","COMBAT",checkCombat},{"ASSETS","ASSETS",checkAssets}}
 for index,item in ipairs(sequence) do
  local agent=item[1]
  setBoot(agent,"RUN")
  setProgress((index-1)/4,"RUNNING "..item[2],agent=="QA" and "Checking internal diagnostics." or agent=="HUD" and "Checking interactive layout and safe area." or agent=="COMBAT" and "Waiting for authoritative server and character." or "Checking the five connected districts.")
  local passed=item[3]()
  if not passed and agent=="HUD" then
   local ok,repaired=pcall(HUD.Build)
   if ok and repaired and repaired:IsA("ScreenGui") then
    gui=repaired
    UI:Bind(gui,remotes)
    passed=checkHUD()
   end
  end
  setBoot(agent,passed and "PASS" or "FAIL")
  if not passed then
   setProgress(index/4,"BOOT PAUSED",agent.." did not satisfy the startup contract.")
   task.wait(.6)
   setProgress(1,"RECOVERING","Rechecking runtime state before opening combat.")
   local recovered=checkCombat() and checkAssets() and checkHUD()
   if recovered then
    for _,name in ipairs({"QA","HUD","COMBAT","ASSETS"}) do if agentState[name]~="PASS" then setBoot(name,"PASS") end end
    break
   end
   setProgress(1,"BOOT FAILED","The session stayed locked to prevent a broken combat state.")
   return
  end
  setProgress(index/4,"RUNNING "..item[2],"Startup contract passed.")
 end
 bootDone=true
 setProgress(1,"BATTLE LINE READY","Server-authoritative combat is unlocked.")
 task.delay(.25,function()
  if loading.Parent then
   TweenService:Create(loading,TweenInfo.new(.28,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
   task.wait(.28)
   if loading.Parent then loading.Visible=false end
  end
 end)
 if player.UserId==game.CreatorId then task.spawn(function() QA:Run(gui,remotes) end) end
end

gameState.OnClientEvent:Connect(function(kind,value)
 if kind=="ProfileReady" then
  serverProfileReady=true
 elseif kind=="Ready" then
  serverReady=true
 end
end)

task.spawn(function()
 pcall(function() ContentProvider:PreloadAsync({gui}) end)
end)

UserInputService.InputBegan:Connect(function(input,gpe)
 if gpe or not bootDone then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then
  combat:FireServer("Light")
 elseif input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.ButtonB then
  combat:FireServer("Dash")
 elseif input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonL2 then
  combat:FireServer("BlockStart")
 elseif input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonX then
  combat:FireServer("Special")
 elseif input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonY then
  combat:FireServer("Awaken")
 elseif input.KeyCode==Enum.KeyCode.T or input.KeyCode==Enum.KeyCode.ButtonA then
  combat:FireServer("Domain")
 elseif (tonumber(input.KeyCode.Name:match("^One$")) or 0)>0 then
  combat:FireServer("Clash1")
 elseif input.KeyCode==Enum.KeyCode.Two then
  combat:FireServer("Clash2")
 elseif input.KeyCode==Enum.KeyCode.Three then
  combat:FireServer("Clash3")
 elseif input.KeyCode==Enum.KeyCode.Four then
  combat:FireServer("Clash4")
 elseif input.KeyCode==Enum.KeyCode.LeftShift then
  movement:FireServer("Sprint",true)
 end
end)

UserInputService.InputEnded:Connect(function(input,gpe)
 if gpe or not bootDone then return end
 if input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonL2 then
  combat:FireServer("BlockEnd")
 elseif input.KeyCode==Enum.KeyCode.LeftShift then
  movement:FireServer("Sprint",false)
 end
end)

task.spawn(startBoot)
