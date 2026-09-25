--!strict
local Players=game:GetService("Players");local R=game:GetService("ReplicatedStorage");local Data=require(script.Parent.PlayerDataService)
local S={};local ID="FractureDistrict_FirstResponse"
function S.Init(defeated:BindableEvent)defeated.Event:Connect(function(_,uid:number)if uid<=0 then return end;for _,p in Players:GetPlayers()do if p.UserId==uid then if Data.ProgressQuest(p,ID,1)then R.CollisionRemotes.Feedback:FireClient(p,"QuestComplete","FIRST RESPONSE COMPLETE • +50 CR")end;break end end end)end
function S.Start(p:Player)local d=Data.Get(p);if d and(not d.Quest.Id or d.Quest.Completed)then Data.StartQuest(p,ID,6)end end
return S
