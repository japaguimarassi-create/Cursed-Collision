--!strict
export type Node={Id:string,Name:string,Subtitle:string,Position:Vector3,Color:Color3}
local Nodes={
Origin={Id="Origin",Name="ORIGIN PLAZA",Subtitle="Spawn district",Position=Vector3.new(-520,0,0),Color=Color3.fromRGB(76,202,255)},
Metro={Id="Metro",Name="METRO ROW",Subtitle="Tight streets and cover",Position=Vector3.new(-260,0,0),Color=Color3.fromRGB(82,220,180)},
Core={Id="Core",Name="BATTLE CORE",Subtitle="Main combat district",Position=Vector3.new(0,0,0),Color=Color3.fromRGB(180,94,255)},
Iron={Id="Iron",Name="IRON MARKET",Subtitle="Industrial close-range zone",Position=Vector3.new(260,0,0),Color=Color3.fromRGB(255,181,82)},
Apex={Id="Apex",Name="APEX YARD",Subtitle="Open showdown district",Position=Vector3.new(520,0,0),Color=Color3.fromRGB(255,92,122)}}
local M={Nodes=Nodes,Order={"Origin","Metro","Core","Iron","Apex"},Version="BattleLine_Urban_v4"}
function M.Get(id:string):Node? return Nodes[id] end
return M
