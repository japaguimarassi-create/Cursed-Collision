--!strict
export type Node={Id:string,Name:string,Subtitle:string,Position:Vector3,Spawn:Vector3}
local Nodes:{[string]:Node}={
	Spawn={Id="Spawn",Name="ORIGIN",Subtitle="Spawn and warm-up",Position=Vector3.new(-420,0,0),Spawn=Vector3.new(-420,4,0)},
	Core={Id="Core",Name="CORE DISTRICT",Subtitle="Main PvP zone",Position=Vector3.new(0,0,0),Spawn=Vector3.new(0,4,0)},
	Apex={Id="Apex",Name="APEX YARD",Subtitle="Open final arena",Position=Vector3.new(420,0,0),Spawn=Vector3.new(420,4,0)}
}
local M={Nodes=Nodes,Order={"Spawn","Core","Apex"},Version="BattleLine_Clean_v1"}
function M.Get(id:string):Node? return Nodes[id] end
return M
