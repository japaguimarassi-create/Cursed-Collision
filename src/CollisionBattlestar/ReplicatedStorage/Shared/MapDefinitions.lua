--!strict
export type Node={Id:string,Name:string,Subtitle:string,Position:Vector3,Color:Color3}
local Nodes={Origin={Id="Origin",Name="ORIGIN PLAZA",Subtitle="Spawn hub and open court",Position=Vector3.new(-580,0,0),Color=Color3.fromRGB(91,211,255)},Metro={Id="Metro",Name="METRO ROW",Subtitle="Station blocks and tight streets",Position=Vector3.new(-290,0,0),Color=Color3.fromRGB(91,227,181)},Core={Id="Core",Name="BATTLE CORE",Subtitle="Central ring and rooftops",Position=Vector3.new(0,0,0),Color=Color3.fromRGB(183,112,255)},Iron={Id="Iron",Name="IRON MARKET",Subtitle="Industrial alleys and cover",Position=Vector3.new(290,0,0),Color=Color3.fromRGB(255,190,91)},Apex={Id="Apex",Name="APEX YARD",Subtitle="Open yard and high platforms",Position=Vector3.new(580,0,0),Color=Color3.fromRGB(255,101,128)}}
local M={Nodes=Nodes,Order={"Origin","Metro","Core","Iron","Apex"},Version="BattleLine_Urban_V5"}
function M.Get(id:string):Node? return Nodes[id] end
return M