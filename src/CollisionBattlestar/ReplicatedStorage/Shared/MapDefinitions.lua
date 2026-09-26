--!strict
export type Node={Id:string,Name:string,Subtitle:string,Position:Vector3,Spawn:Vector3,Color:Color3}
local Nodes:{[string]:Node}={
	Origin={Id="Origin",Name="ORIGIN PLAZA",Subtitle="Spawn / warm-up",Position=Vector3.new(-520,0,0),Spawn=Vector3.new(-520,4,0),Color=Color3.fromRGB(94,205,255)},
	Metro={Id="Metro",Name="METRO ROW",Subtitle="Tight streets / cover",Position=Vector3.new(-260,0,0),Spawn=Vector3.new(-260,4,0),Color=Color3.fromRGB(99,213,183)},
	Core={Id="Core",Name="BATTLE CORE",Subtitle="Main combat district",Position=Vector3.new(0,0,0),Spawn=Vector3.new(0,4,0),Color=Color3.fromRGB(176,112,255)},
	Iron={Id="Iron",Name="IRON MARKET",Subtitle="Dense industrial lane",Position=Vector3.new(270,0,0),Spawn=Vector3.new(270,4,0),Color=Color3.fromRGB(255,181,87)},
	Apex={Id="Apex",Name="APEX YARD",Subtitle="Open-end showdown",Position=Vector3.new(520,0,0),Spawn=Vector3.new(520,4,0),Color=Color3.fromRGB(255,105,126)},
}
local M={Nodes=Nodes,Order={"Origin","Metro","Core","Iron","Apex"},Version="BattleLine_Urban_v3"}
function M.Get(id:string):Node? return Nodes[id] end
return M
