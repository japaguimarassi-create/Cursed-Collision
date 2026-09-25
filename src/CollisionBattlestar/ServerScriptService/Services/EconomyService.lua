--!strict
local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local S={}
function S.Init(enemyDefeated:BindableEvent)
	enemyDefeated.Event:Connect(function(model:Model,userId:number,_,reward:number)
		if userId<=0 then return end
		for _,p in Players:GetPlayers()do
			if p.UserId==userId then
				if model:GetAttribute("BattleStreakOwnerUserId") and (model:GetAttribute("BattleStreakOwnerUserId")or 0)>0 then return end
				Data.AddCoins(p,math.max(0,math.floor(reward)))
				return
			end
		end
	end)
end
return S
