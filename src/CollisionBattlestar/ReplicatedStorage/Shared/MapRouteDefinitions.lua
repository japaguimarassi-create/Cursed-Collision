--!strict
export type RouteNode={Id:string,Name:string,Subtitle:string,Position:Vector3,Spawn:Vector3,Color:Color3,UnlockLevel:number}
local R:{[string]:RouteNode}={
	Origin={Id="Origin",Name="ORIGIN PLAZA",Subtitle="Spawn / Training",Position=Vector3.new(-720,0,0),Spawn=Vector3.new(-720,4,18),Color=Color3.fromRGB(92,198,255),UnlockLevel=1},
	Neon={Id="Neon",Name="NEON STRIP",Subtitle="Urban Combat",Position=Vector3.new(-480,0,0),Spawn=Vector3.new(-480,4,-18),Color=Color3.fromRGB(178,92,255),UnlockLevel=1},
	Iron={Id="Iron",Name="IRON MARKET",Subtitle="Close Quarters",Position=Vector3.new(-240,0,0),Spawn=Vector3.new(-240,4,18),Color=Color3.fromRGB(255,150,84),UnlockLevel=1},
	Core={Id="Core",Name="COLLISION CORE",Subtitle="Main Battleground",Position=Vector3.new(0,0,0),Spawn=Vector3.new(0,4,-18),Color=Color3.fromRGB(255,216,92),UnlockLevel=1},
	Sky={Id="Sky",Name="SKYLINE",Subtitle="Vertical Combat",Position=Vector3.new(240,0,0),Spawn=Vector3.new(240,4,18),Color=Color3.fromRGB(83,220,193),UnlockLevel=1},
	Rift={Id="Rift",Name="RIFTWORKS",Subtitle="Reality Fracture",Position=Vector3.new(480,0,0),Spawn=Vector3.new(480,4,-18),Color=Color3.fromRGB(197,92,255),UnlockLevel=1},
	Apex={Id="Apex",Name="APEX YARD",Subtitle="Boss / Streak",Position=Vector3.new(720,0,0),Spawn=Vector3.new(720,4,18),Color=Color3.fromRGB(255,96,90),UnlockLevel=1}
}
local M={Nodes=R,Order={"Origin","Neon","Iron","Core","Sky","Rift","Apex"},Version="battleline_v1"}
function M.Get(id:string):RouteNode? return R[id] end
function M.IsUnlocked(player:Player,nodeId:string):boolean local n=R[nodeId];return n~=nil and (tonumber(player:GetAttribute("Level"))or 1)>=n.UnlockLevel end
return M
