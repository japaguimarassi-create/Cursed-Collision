--!strict
local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local remotes=ReplicatedStorage:WaitForChild("CollisionRemotes")
local feedback=remotes:WaitForChild("Feedback")

local S={}
local cooldown:{[BasePart]:number}={}
local broken:{[BasePart]:boolean}={}

local function restore(part:BasePart,originalSize:Vector3,originalTransparency:number)
	task.delay(7,function()
		if not part.Parent then
			broken[part]=nil
			cooldown[part]=nil
			return
		end
		part.CanCollide=true
		part.CanQuery=true
		part.Transparency=originalTransparency
		part.Size=originalSize
		part:SetAttribute("DestructibleHP",part:GetAttribute("DestructibleMaxHP") or 20)
		broken[part]=nil
	end)
end

function S.TryDamage(player:Player,position:Vector3,radius:number,damage:number)
	local params=OverlapParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={player.Character}
	params.MaxParts=32
	local seen:{[BasePart]:boolean}={}
	for _,instance in ipairs(workspace:GetPartBoundsInRadius(position,radius,params)) do
		if instance:IsA("BasePart") and CollectionService:HasTag(instance,"CBS_Destructible") and not seen[instance] and not broken[instance] then
			seen[instance]=true
			if (cooldown[instance] or 0)>os.clock() then continue end
			cooldown[instance]=os.clock()+.18
			local hp=tonumber(instance:GetAttribute("DestructibleHP")) or tonumber(instance:GetAttribute("DestructibleMaxHP")) or 20
			hp-=damage
			instance:SetAttribute("DestructibleHP",hp)
			feedback:FireAllClients("DestructHit",{Position=instance.Position,Damage=damage,HP=math.max(0,hp)})
			if hp<=0 then
				broken[instance]=true
				local originalSize=instance.Size
				local originalTransparency=instance.Transparency
				instance.CanCollide=false
				instance.CanQuery=false
				TweenService:Create(instance,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
					Size=originalSize*.72,
					Transparency=.82,
				}):Play()
				restore(instance,originalSize,originalTransparency)
			end
		end
	end
end

function S.ResetAll()
	for _,instance in ipairs(CollectionService:GetTagged("CBS_Destructible")) do
		if instance:IsA("BasePart") then
			instance.CanCollide=true
			instance.CanQuery=true
			instance.Transparency=0
			instance.Size=instance:GetAttribute("DestructibleOriginalSize") or instance.Size
			instance:SetAttribute("DestructibleHP",instance:GetAttribute("DestructibleMaxHP") or 20)
			broken[instance]=nil
		end
	end
end

function S.Init() end
return S
