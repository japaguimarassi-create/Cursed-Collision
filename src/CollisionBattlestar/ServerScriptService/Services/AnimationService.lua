--!strict
local R=game:GetService("ReplicatedStorage")
local Animation=require(R.Shared.AnimationDefinitions)

local S={}
local cache:{[Model]:{[string]:AnimationTrack}}={}

local function animator(model:Model):Animator?
	local humanoid=model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local found=humanoid:FindFirstChildOfClass("Animator")
	if found then return found end
	local created=Instance.new("Animator")
	created.Parent=humanoid
	return created
end

local function track(model:Model,name:string):AnimationTrack?
	local definition=Animation.Get(name)
	if not definition or definition.Id=="" then return nil end
	local a=animator(model)
	if not a then return nil end
	local bucket=cache[model]
	if not bucket then
		bucket={}
		cache[model]=bucket
	end
	local existing=bucket[name]
	if existing then return existing end
	local animation=Instance.new("Animation")
	animation.Name="CBS_"..name
	animation.AnimationId=definition.Id
	local ok,result=pcall(function()
		return a:LoadAnimation(animation)
	end)
	animation:Destroy()
	if not ok or not result then return nil end
	local loaded=result::AnimationTrack
	loaded.Priority=definition.Priority
	loaded.Looped=definition.Looped
	bucket[name]=loaded
	return loaded
end

function S.Register(model:Model)
	if not animator(model) or cache[model] then return end
	cache[model]={}
	model.Destroying:Connect(function()
		cache[model]=nil
	end)
end

function S.Play(model:Model,name:string,fadeTime:number?,speed:number?):AnimationTrack?
	if not model.Parent then return nil end
	local loaded=track(model,name)
	if not loaded then return nil end
	loaded:Play(fadeTime or .08,1,speed or 1)
	return loaded
end

function S.Stop(model:Model,name:string,fadeTime:number?)
	local bucket=cache[model]
	local loaded=bucket and bucket[name]
	if loaded and loaded.IsPlaying then loaded:Stop(fadeTime or .08)end
end

function S.StopActions(model:Model,fadeTime:number?)
	local bucket=cache[model]
	if not bucket then return end
	for name,loaded in pairs(bucket)do
		local definition=Animation.Get(name)
		local actionPriority=definition and (
			definition.Priority==Enum.AnimationPriority.Action or
			definition.Priority==Enum.AnimationPriority.Action2 or
			definition.Priority==Enum.AnimationPriority.Action3 or
			definition.Priority==Enum.AnimationPriority.Action4
		)
		if actionPriority and loaded.IsPlaying then loaded:Stop(fadeTime or .08)end
	end
end

function S.BindMarker(model:Model,name:string,markerName:string,callback:(string)->())
	local loaded=track(model,name)
	if not loaded then return nil end
	return loaded:GetMarkerReachedSignal(markerName):Connect(callback)
end

return S
