--!strict
local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local S={}
function S.Init(enemyDefeated:BindableEvent)
	enemyDefeated.Event:Connect(function(_,userId:number,_,reward:number)
		if userId<=0 then return end
		for _,p in Players:GetPlayers()do
			if p.UserId==userId then
				Data.AddCoins(p,math.max(0,math.floor(reward)))
				return
			end
		end
	end)
end
return S
