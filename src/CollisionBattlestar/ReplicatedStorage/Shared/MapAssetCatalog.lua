--!strict
local A={}
export type AssetReference={Id:number,Name:string,Use:string,Budget:string,License:string,ContainsScripts:boolean}

A.References:{
	AssetReference
}={
	{Id=400850371,Name="Bench",Use="park seating",Budget="228 tris",License="Creator Store: explicitly free in description",ContainsScripts=false},
	{Id=42942436,Name="Dumpster -Free-",Use="alley clutter",Budget="82 tris",License="Creator Store: explicitly free in title",ContainsScripts=false},
	{Id=4987899016,Name="Bus Stop [FREE!]",Use="transport stop",Budget="1,432 tris / 2 decals",License="Creator Store: explicitly FREE",ContainsScripts=false},
	{Id=8673868211,Name="Bus Stop Sign [FREE]",Use="route signage",Budget="14 tris / 1 decal",License="Creator Store: explicitly FREE",ContainsScripts=false},
	{Id=18143058886,Name="Bus Stop Pole",Use="route signage",Budget="648 tris / 2 decals",License="Creator Store: description says free",ContainsScripts=false},
	{Id=5157346970,Name="[FREE] Car Showcase",Use="parked vehicle hero prop",Budget="2,120 tris / 4 decals",License="Creator Store: explicitly FREE",ContainsScripts=false},
	{Id=72984214938380,Name="City Props Pack Street Building Car RP",Use="future research only",Budget="not accepted into runtime without license/asset inspection",License="Creator Store listing includes Free tag; runtime not selected",ContainsScripts=false},
	{Id=16663903306,Name="Free R6 battleground animations (v7)",Use="animation source pack",Budget="1,066 tris / 727 vertices",License="Creator Store: open source; explicitly permits battleground use/monetization",ContainsScripts=false},
}

function A.GetByUse(use:string):{AssetReference}
	local out:{AssetReference}={}
	for _,item in ipairs(A.References)do
		if item.Use==use then table.insert(out,item)end
	end
	return out
end

return A