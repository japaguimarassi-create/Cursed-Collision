--!strict
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local C=require(ReplicatedStorage.Shared.Config)

local M={}
local fxCount=0
local damageCount=0

local function color(extra:any,default:Color3):Color3
 return typeof(extra)=="table" and typeof(extra.color)=="Color3" and extra.color or default
end

local function ring(position:Vector3,ringColor:Color3,big:boolean)
 if fxCount>=C.Performance.MaxFX then return end
 fxCount+=1
 local p=Instance.new("Part");p.Name="CBSFX";p.Shape=Enum.PartType.Cylinder;p.Size=Vector3.new(.18,big and 7 or 4.5,big and 7 or 4.5);p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.rad(90));p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.Neon;p.Color=ringColor;p.Transparency=.1;p.Parent=workspace
 local endSize=Vector3.new(.18,p.Size.Y*1.3,p.Size.Z*1.3)
 TweenService:Create(p,TweenInfo.new(.26,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=endSize,Transparency=1}):Play()
 Debris:AddItem(p,.32)
 task.delay(.36,function() fxCount=math.max(0,fxCount-1) end)
end

local function burst(position:Vector3,ringColor:Color3)
 if fxCount>=C.Performance.MaxFX then return end
 fxCount+=1
 local holder=Instance.new("Part");holder.Name="CBSBurst";holder.Size=Vector3.one;holder.Position=position;holder.Transparency=1;holder.Anchored=true;holder.CanCollide=false;holder.CanTouch=false;holder.CanQuery=false;holder.Parent=workspace
 local emitter=Instance.new("ParticleEmitter");emitter.Color=ColorSequence.new(ringColor);emitter.LightEmission=1;emitter.Lifetime=NumberRange.new(.12,.22);emitter.Speed=NumberRange.new(14,27);emitter.SpreadAngle=Vector2.new(180,180);emitter.Rate=0;emitter.Texture="rbxasset://textures/particles/sparkles_main.dds";emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.24),NumberSequenceKeypoint.new(1,0)});emitter.Parent=holder
 emitter:Emit(18)
 Debris:AddItem(holder,.35)
 task.delay(.4,function() fxCount=math.max(0,fxCount-1) end)
end

local function damageText(position:Vector3,damage:number)
 if damageCount>=C.Performance.MaxDamageTexts then return end
 damageCount+=1
 local holder=Instance.new("Part");holder.Name="CBDamage";holder.Size=Vector3.new(.1,.1,.1);holder.Transparency=1;holder.Anchored=true;holder.CanCollide=false;holder.CanTouch=false;holder.CanQuery=false;holder.Position=position+Vector3.new(0,2,0);holder.Parent=workspace
 local bill=Instance.new("BillboardGui");bill.Size=UDim2.fromOffset(88,34);bill.AlwaysOnTop=true;bill.MaxDistance=85;bill.Adornee=holder;bill.Parent=holder
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=tostring(math.floor(damage+.5));t.Font=Enum.Font.GothamBlack;t.TextSize=18;t.TextColor3=C.UI.Text;t.TextStrokeTransparency=.35;t.Parent=bill
 TweenService:Create(t,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency=1,TextStrokeTransparency=1}):Play()
 TweenService:Create(bill,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{StudsOffset=Vector3.new(0,2.4,0)}):Play()
 Debris:AddItem(holder,.5)
 task.delay(.55,function() damageCount=math.max(0,damageCount-1) end)
end

function M:Init(remotes)
 local fx=remotes:WaitForChild("CombatFX") :: UnreliableRemoteEvent
 fx.OnClientEvent:Connect(function(kind:string,position:Vector3,extra:any)
  local c=color(extra,C.UI.Accent)
  if kind=="Hit" then burst(position,c);if typeof(extra)=="table" and typeof(extra.damage)=="number" then damageText(position,extra.damage) end
  elseif kind=="Swing" then ring(position,c,typeof(extra)=="table" and extra.combo==4)
  elseif kind=="Guard" then ring(position,C.UI.Accent,false)
  elseif kind=="Parry" then burst(position,C.UI.Accent2);ring(position,C.UI.Accent2,true)
  elseif kind=="Dash" then ring(position,c,false)
  elseif kind=="Special" then burst(position,c);ring(position,c,true)
  elseif kind=="Awaken" then burst(position,c);ring(position,c,true);ring(position,c,true)
  elseif kind=="Domain" then ring(position,c,true)
  elseif kind=="Ping" then ring(position,C.UI.Gold,false)
  end
 end)
end
return M