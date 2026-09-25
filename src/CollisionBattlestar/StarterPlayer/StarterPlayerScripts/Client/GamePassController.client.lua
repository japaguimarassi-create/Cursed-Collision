--!strict
local Players=game:GetService("Players")
local R=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local remotes=R:WaitForChild("CollisionRemotes")
local request=remotes:WaitForChild("GamePassRequest")::RemoteEvent


remotes.Feedback.OnClientEvent:Connect(function(kind:string,value:any)
	if kind=="PassUnlocked" then
		player:SetAttribute("PassPurchaseNotice",tostring(value))
	elseif kind=="PassRequired" then
		local data=value
		if typeof(data)=="table" then
			player:SetAttribute("PassRequiredFor",tostring(data.Action))
			player:SetAttribute("PassRequiredKey",tostring(data.Pass))
		end
	end
end)

