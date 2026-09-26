--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local CaptureService=game:GetService("CaptureService")
local QA=require(ReplicatedStorage.Shared.QAContract)

local M={}
local player=Players.LocalPlayer

local function owner():boolean
 return player.UserId==game.CreatorId
end

local function child(root:Instance?,name:string):boolean
 return root~=nil and root:FindFirstChild(name)~=nil
end

function M:Run(gui:ScreenGui,remotes)
 if not owner() then return end
 local control=remotes:WaitForChild(QA.ControlEvent) :: RemoteEvent
 local report=remotes:WaitForChild(QA.ReportEvent) :: RemoteEvent
 control:FireServer("SpawnBot")
 task.wait(.4)
 local detectors={}
 local passed=true
 local pg=player:FindFirstChildOfClass("PlayerGui")
 local current=pg and pg:FindFirstChild("CollisionHUD")
 detectors["HUD exists"]=current~=nil
 detectors["HUD enabled"]=current and current:IsA("ScreenGui") and current.Enabled==true or false
 detectors["Safe area"]=current and current:IsA("ScreenGui") and current.ScreenInsets==Enum.ScreenInsets.CoreUISafeInsets or false
 for _,name in ipairs(QA.RequiredHUD) do
  detectors["HUD node "..name]=current and child(current,name) or false
  if not detectors["HUD node "..name] then passed=false end
 end
 detectors["Server ready"]=workspace:GetAttribute("CollisionBattlestarServerReady")==true
 detectors["Map ready"]=workspace:GetAttribute("CollisionBattlestarMapReady")==true
 detectors["World"]=workspace:FindFirstChild("CollisionBattlestarWorld")~=nil
 for _,id in ipairs(QA.RequiredDistricts) do
  local world=workspace:FindFirstChild("CollisionBattlestarWorld")
  local map=world and world:FindFirstChild("Map")
  detectors["District "..id]=map and map:FindFirstChild(id)~=nil
 end
 detectors["QA bot spawn"]=workspace:FindFirstChild(QA.DummyName)~=nil
 local bot=workspace:FindFirstChild(QA.DummyName)
 local root=bot and bot:FindFirstChild("HumanoidRootPart")
 if root and root:IsA("BasePart") then
  control:FireServer("MoveBot",root.Position+Vector3.new(4,0,0))
  detectors["QA bot targetable"]=bot:FindFirstChildOfClass("Humanoid")~=nil
 end
 local okShot,capture=pcall(function() return CaptureService:TakeScreenshotCaptureAsync() end)
 detectors["Screenshot API"]=okShot and capture~=nil
 for _,value in pairs(detectors) do if value==false then passed=false end end
 report:FireServer({status=passed and "PASS" or "FAIL",detectors=detectors,runtime={gui=current and current.Name,worldReady=workspace:GetAttribute("CollisionBattlestarMapReady")==true,build=HttpService:JSONEncode({version="4.0"})}})
 task.delay(1,function() control:FireServer("DestroyBot") end)
end
return M