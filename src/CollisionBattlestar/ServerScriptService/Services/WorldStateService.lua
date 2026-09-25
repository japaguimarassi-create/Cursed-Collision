--!strict
local C=require(game.ReplicatedStorage.Shared.Config);local U=require(game.ReplicatedStorage.Shared.Util);local Lighting=game:GetService("Lighting")
local S={};S.Changed=Instance.new("BindableEvent")
local region={Name=C.Region.Name,Threat=18,Energy=10,Activity=25,Recovery=20,State="Stable",LastEvent="",EventCount=0}
local function derive():string
	local score=region.Threat+region.Energy*.8+region.Activity*.4-region.Recovery*.5
	if score>=125 then return "Collapsed" elseif score>=100 then return "Invaded" elseif score>=78 then return "Distorted" elseif score>=55 then return "Unstable" elseif region.Recovery>=70 then return "Resonating" elseif score<=18 then return "Recovering" end
	return "Stable"
end
local function apply()
	workspace:SetAttribute("CollisionState",region.State);workspace:SetAttribute("CollisionThreat",math.floor(region.Threat));workspace:SetAttribute("CollisionEnergy",math.floor(region.Energy))
	local times={Stable=17,Unstable=18,Distorted=22,Invaded=1,Collapsed=3,Resonating=20,Recovering=19};Lighting.ClockTime=times[region.State]or 19
	Lighting.Brightness=region.State=="Collapsed"and 1 or region.State=="Distorted"and 1.7 or 2
end
local function changed(old:string)apply();if old~=region.State then S.Changed:Fire(region.State,old,S.GetSnapshot())end end
function S.Init()
	region.State=derive();apply()
	task.spawn(function()while task.wait(10)do local old=region.State;region.Threat=U.Clamp(region.Threat-.25,0,100);region.Energy=U.Clamp(region.Energy-.18,0,100);region.Activity=U.Clamp(region.Activity+math.random(-2,2),0,100);region.Recovery=U.Clamp(region.Recovery+(region.Threat<35 and 2 or -1),0,100);region.State=derive();changed(old)end end)
end
function S.AddThreat(n:number)local old=region.State;region.Threat=U.Clamp(region.Threat+n,0,100);region.Activity=U.Clamp(region.Activity+n*.3,0,100);region.Recovery=U.Clamp(region.Recovery-n*.1,0,100);region.State=derive();changed(old)end
function S.AddEnergy(n:number)local old=region.State;region.Energy=U.Clamp(region.Energy+n,0,100);region.Recovery=U.Clamp(region.Recovery-n*.1,0,100);region.State=derive();changed(old)end
function S.RegisterEvent(name:string)region.LastEvent=name;region.EventCount+=1;region.Energy=U.Clamp(region.Energy+15,0,100);region.Threat=U.Clamp(region.Threat+12,0,100);region.Activity=U.Clamp(region.Activity+10,0,100);local old=region.State;region.State=derive();changed(old)end
function S.GetSnapshot()return table.clone(region)end
return S
