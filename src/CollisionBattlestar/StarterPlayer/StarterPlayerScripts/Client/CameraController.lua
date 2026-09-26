--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local M={}
local player=Players.LocalPlayer

function M:Init()
 RunService.RenderStepped:Connect(function(dt)
  Camera=workspace.CurrentCamera
  if not Camera then return end
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not humanoid then return end
  if Camera.CameraType~=Enum.CameraType.Custom then Camera.CameraType=Enum.CameraType.Custom end
  local speed=humanoid.MoveDirection.Magnitude
  local target=70+speed*4
  Camera.FieldOfView=Camera.FieldOfView+(math.clamp(target,70,78)-Camera.FieldOfView)*math.min(1,dt*7)
 end)
end
return M