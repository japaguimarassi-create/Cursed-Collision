--!strict
local R=game:GetService("ReplicatedStorage");local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local S={}
local function grant(p:Player,id:string,label:string)if Data.UnlockAchievement(p,id)then R.CollisionRemotes.Feedback:FireClient(p,"Achievement",label)end end
function S.Init(defeated:BindableEvent,eventStarted:BindableEvent)
	defeated.Event:Connect(function(_,uid:number,kind:string)
		for _,p in Players:GetPlayers()do if p.UserId==uid then grant(p,"FirstContact","ACHIEVEMENT • FIRST CONTACT");if kind=="Boss"then grant(p,"BossBreaker","ACHIEVEMENT • BOSS BREAKER")end;break end end
	end)
	eventStarted.Event:Connect(function()for _,p in Players:GetPlayers()do grant(p,"RealityWitness","ACHIEVEMENT • REALITY WITNESS")end end)
end
return S
