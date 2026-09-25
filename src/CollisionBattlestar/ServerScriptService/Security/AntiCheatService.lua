--!strict
local Players=game:GetService("Players")
local C=require(game.ReplicatedStorage.Shared.Config)
local D=require(game.ReplicatedStorage.CBShared.CombatDefinitions)
local S={};local windows:{[Player]:{t:number,n:number}}={}
function S.Init()Players.PlayerRemoving:Connect(function(p)windows[p]=nil end)end
function S.Allow(p:Player):boolean local now=os.clock();local w=windows[p];if not w or now-w.t>=1 then windows[p]={t=now,n=1};return true end;w.n+=1;return w.n<=C.Combat.MaxRequestRate end
function S.Validate(a:unknown):boolean return typeof(a)=="string"and#a<=32 and D.Valid[a]==true end
return S
