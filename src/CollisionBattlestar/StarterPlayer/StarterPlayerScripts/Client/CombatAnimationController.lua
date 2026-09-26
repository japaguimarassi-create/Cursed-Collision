--!strict
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")

type Cache={base:{[Motor6D]:CFrame},token:number}
local M={}
local caches:{[Model]:Cache}={}

local function findMotor(character:Model,names:{string}):Motor6D?
 for _,name in ipairs(names) do
  local item=character:FindFirstChild(name,true)
  if item and item:IsA("Motor6D") then return item end
 end
 return nil
end

local function getCache(character:Model):Cache
 local cache=caches[character]
 if cache then return cache end
 cache={base={},token=0}
 caches[character]=cache
 character.AncestryChanged:Connect(function(_,parent)
  if not parent then caches[character]=nil end
 end)
 return cache
end

local function joint(character:Model,cache:Cache,names:{string}):Motor6D?
 local motor=findMotor(character,names)
 if not motor then return nil end
 if not cache.base[motor] then cache.base[motor]=motor.C0 end
 return motor
end

local function playPose(character:Model,poses:{[string]:{names:{string},offset:CFrame}},attackTime:number,returnTime:number)
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return end
 local cache=getCache(character)
 cache.token+=1
 local token=cache.token
 for _,pose in pairs(poses) do
  local motor=joint(character,cache,pose.names)
  if motor then
   TweenService:Create(motor,TweenInfo.new(attackTime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{C0=cache.base[motor]*pose.offset}):Play()
   task.delay(attackTime,function()
    if cache.token~=token or not motor.Parent then return end
    TweenService:Create(motor,TweenInfo.new(returnTime,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{C0=cache.base[motor]}):Play()
   end)
  end
 end
end

local RShoulder={"RightShoulder","Right Shoulder"}
local LShoulder={"LeftShoulder","Left Shoulder"}
local Waist={"Waist","RootJoint"}
local RHip={"RightHip","Right Hip"}
local LHip={"LeftHip","Left Hip"}

function M:Init()
 Players.PlayerRemoving:Connect(function(player)
  if player.Character then caches[player.Character]=nil end
 end)
end

function M:PlayByUserId(userId:number,kind:string,combo:number?,variant:string?)
 local player=Players:GetPlayerByUserId(userId)
 local character=player and player.Character
 if character then self:Play(character,kind,combo,variant) end
end

function M:Play(character:Model,kind:string,combo:number?,variant:string?)
 if not character or not character:IsA("Model") then return end
 local a=math.rad
 if kind=="Swing" then
  local index=combo or 1
  local side=index%2==0 and -1 or 1
  if variant=="Uppercut" then
   playPose(character,{
    Right={names=RShoulder,offset=CFrame.Angles(a(-105),a(18),a(52))},
    Left={names=LShoulder,offset=CFrame.Angles(a(-25),a(-8),a(-18))},
    Waist={names=Waist,offset=CFrame.Angles(a(-7),a(0),a(side*7))},
   },.055,.10)
  elseif variant=="Downslam" then
   playPose(character,{
    Right={names=RShoulder,offset=CFrame.Angles(a(72),a(18),a(48))},
    Left={names=LShoulder,offset=CFrame.Angles(a(55),a(-10),a(-42))},
    Waist={names=Waist,offset=CFrame.Angles(a(18),a(0),a(side*6))},
   },.055,.12)
  else
   playPose(character,{
    Right={names=RShoulder,offset=CFrame.Angles(a(-72),a(28),a(65*side))},
    Left={names=LShoulder,offset=CFrame.Angles(a(18),a(-8),a(-18*side))},
    Waist={names=Waist,offset=CFrame.Angles(a(-2),a(side*9),0)},
    RHip={names=RHip,offset=CFrame.Angles(0,a(-side*3),0)},
    LHip={names=LHip,offset=CFrame.Angles(0,a(-side*3),0)},
   },.045,.095)
  end
 elseif kind=="Dash" then
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(22),a(0),a(24))},
   Left={names=LShoulder,offset=CFrame.Angles(a(18),a(0),a(-24))},
   Waist={names=Waist,offset=CFrame.Angles(a(10),0,0)},
   RHip={names=RHip,offset=CFrame.Angles(a(-8),0,0)},
   LHip={names=LHip,offset=CFrame.Angles(a(-8),0,0)},
  },.06,.13)
 elseif kind=="Guard" then
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(-42),a(18),a(25))},
   Left={names=LShoulder,offset=CFrame.Angles(a(-42),a(-18),a(-25))},
   Waist={names=Waist,offset=CFrame.Angles(a(-4),0,0)},
  },.07,.16)
 elseif kind=="Parry" then
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(-80),a(20),a(42))},
   Left={names=LShoulder,offset=CFrame.Angles(a(-80),a(-20),a(-42))},
   Waist={names=Waist,offset=CFrame.Angles(0,0,a(8))},
  },.05,.14)
 elseif kind=="Special" then
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(-95),a(10),a(45))},
   Left={names=LShoulder,offset=CFrame.Angles(a(-95),a(-10),a(-45))},
   Waist={names=Waist,offset=CFrame.Angles(a(-8),0,0)},
  },.08,.18)
 elseif kind=="Awaken" then
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(-25),a(0),a(90))},
   Left={names=LShoulder,offset=CFrame.Angles(a(-25),a(0),a(-90))},
   Waist={names=Waist,offset=CFrame.Angles(a(-10),0,0)},
  },.14,.25)
 elseif kind=="Hit" then
  local side=variant=="Left" and -1 or 1
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(10),a(0),a(-18*side))},
   Left={names=LShoulder,offset=CFrame.Angles(a(8),a(0),a(18*side))},
   Waist={names=Waist,offset=CFrame.Angles(a(8),a(-8*side),0)},
  },.035,.12)
 elseif kind=="Domain" then
  playPose(character,{
   Right={names=RShoulder,offset=CFrame.Angles(a(-48),0,a(65))},
   Left={names=LShoulder,offset=CFrame.Angles(a(-48),0,a(-65))},
   Waist={names=Waist,offset=CFrame.Angles(a(-6),0,0)},
  },.12,.22)
 end
end

return M
