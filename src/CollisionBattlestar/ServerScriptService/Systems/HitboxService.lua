--!strict
local Players=game:GetService("Players")

local M={}

local function validRoot(model:Model?):BasePart?
 local root=model and model:FindFirstChild("HumanoidRootPart")
 return root and root:IsA("BasePart") and root or nil
end

local function collect(attacker:Player,parts:{BasePart},facingDot:number?):{Humanoid}
 local attackerRoot=validRoot(attacker.Character)
 local out:{Humanoid}={}
 local seen:{[Humanoid]:boolean}={}
 if not attackerRoot then return out end

 for _,part in ipairs(parts) do
  local model=part:FindFirstAncestorOfClass("Model")
  local humanoid=model and model:FindFirstChildOfClass("Humanoid")
  local victimRoot=model and validRoot(model)
  local victim=model and Players:GetPlayerFromCharacter(model)
  if humanoid and victim and victim~=attacker and humanoid.Health>0 and victimRoot and not seen[humanoid] then
   local delta=victimRoot.Position-attackerRoot.Position
   local distance=delta.Magnitude
   if distance<=0 then
    seen[humanoid]=true
    table.insert(out,humanoid)
   elseif not facingDot or attackerRoot.CFrame.LookVector:Dot(delta.Unit)>=facingDot then
    seen[humanoid]=true
    table.insert(out,humanoid)
   end
  end
 end

 return out
end

function M.Box(attacker:Player,cframe:CFrame,size:Vector3,facingDot:number?):{Humanoid}
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={attacker.Character}
 params.MaxParts=96
 return collect(attacker,workspace:GetPartBoundsInBox(cframe,size,params),facingDot)
end

function M.Radius(attacker:Player,position:Vector3,radius:number,facingDot:number?):{Humanoid}
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={attacker.Character}
 params.MaxParts=96
 return collect(attacker,workspace:GetPartBoundsInRadius(position,radius,params),facingDot)
end

return M
