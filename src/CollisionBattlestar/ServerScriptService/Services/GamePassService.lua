--!strict
local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local R=game:GetService("ReplicatedStorage")
local Definitions=require(R.Shared.GamePassDefinitions)

type Cache={[Player]:{[string]:boolean}}

local S={}
local cache:Cache={}

local function setState(player:Player,passKey:string,owned:boolean)
	local state=cache[player]
	if not state then state={};cache[player]=state end
	state[passKey]=owned
	player:SetAttribute("Pass_"..passKey,owned)
end

local function check(player:Player,passKey:string):boolean
	local definition=Definitions.Passes[passKey]
	if not definition or definition.Id<=0 then
		setState(player,passKey,false)
		return false
	end
	local success,owned=pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId,definition.Id)
	end)
	if not success then
		return false
	end
	setState(player,passKey,owned==true)
	return owned==true
end

local function refresh(player:Player,passKey:string?)
	if not player.Parent then return end
	if passKey then
		check(player,passKey)
		return
	end
	for key in Definitions.Passes do
		task.spawn(check,player,key)
	end
end

function S.Init(requestRemote:RemoteEvent)
	requestRemote.OnServerEvent:Connect(function(player:Player,passKey:any)
		if typeof(passKey)~="string" then return end
		local definition=Definitions.Passes[passKey]
		if not definition or definition.Id<=0 then return end
		if S.HasPass(player,passKey) then return end
		local success=pcall(function()
			MarketplaceService:PromptGamePassPurchase(player,definition.Id)
		end)
		if not success then
			R.CollisionRemotes.Feedback:FireClient(player,"PassError","PASS PURCHASE UNAVAILABLE")
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player:Player,gamePassId:number,wasPurchased:boolean)
		for passKey,definition in Definitions.Passes do
			if definition.Id==gamePassId then
				if wasPurchased then
					setState(player,passKey,true)
					R.CollisionRemotes.Feedback:FireClient(player,"PassUnlocked",passKey)
				else
					refresh(player,passKey)
				end
				break
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player:Player)
		cache[player]={}
		refresh(player)
	end)

	Players.PlayerRemoving:Connect(function(player:Player)
		cache[player]=nil
	end)

	for _,player in Players:GetPlayers() do
		cache[player]={}
		task.defer(refresh,player)
	end
end

function S.HasPass(player:Player,passKey:string):boolean
	local state=cache[player]
	if state and state[passKey]~=nil then
		return state[passKey]
	end
	return check(player,passKey)
end

function S.HasAction(player:Player,actionName:string):boolean
	local passKey=Definitions.ActionRequirements[actionName]
	if not passKey then
		return false
	end
	return S.HasPass(player,passKey)
end

function S.GetRequiredPass(actionName:string):string?
	return Definitions.ActionRequirements[actionName]
end

function S.RequireAction(player:Player,actionName:string):boolean
	local passKey=Definitions.ActionRequirements[actionName]
	if not passKey then
		return false
	end
	if S.HasPass(player,passKey) then
		return true
	end
	R.CollisionRemotes.Feedback:FireClient(player,"PassRequired",{Action=actionName,Pass=passKey})
	return false
end

function S.RequireAnyPass(player:Player,passKeys:{string}):boolean
	for _,passKey in passKeys do
		if S.HasPass(player,passKey) then
			return true
		end
	end
	R.CollisionRemotes.Feedback:FireClient(player,"PassRequired",{Action="AnyPass",Pass=table.concat(passKeys,",")})
	return false
end

function S.GetOwnedPasses(player:Player):{string}
	local owned={}
	for passKey in Definitions.Passes do
		if S.HasPass(player,passKey) then
			table.insert(owned,passKey)
		end
	end
	return owned
end

return S
