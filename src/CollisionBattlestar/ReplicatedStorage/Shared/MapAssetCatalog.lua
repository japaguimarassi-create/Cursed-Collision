--!strict
local A={}
A.References={
	{Id=6370681139,Name="City Props Pack",Use="street props",Budget="66k tris / 94 MeshParts",ContainsScripts=true},
	{Id=383275076,Name="Street Lamp",Use="street lighting reference",Budget="5.5k tris",ContainsScripts=false},
	{Id=11146095708,Name="Street Lamp",Use="low-cost street lighting reference",Budget="768 tris / 1 MeshPart",ContainsScripts=false},
	{Id=400850371,Name="Bench",Use="park seating",Budget="228 tris",ContainsScripts=false},
	{Id=70028753,Name="Traffic Cone",Use="construction clutter",Budget="326 tris",ContainsScripts=false},
	{Id=839465687,Name="Billboard",Use="billboards",Budget="2.1k tris",ContainsScripts=false},
	{Id=18210310901,Name="Billboard Set v1",Use="signage study",Budget="4.2k tris / 68 items",ContainsScripts=false},
	{Id=8959051,Name="Car Mesh example",Use="vehicle silhouette study",Budget="manual inspection required",ContainsScripts=true},
	{Id=87547058560755,Name="BUS stop",Use="bus stop detail",Budget="660 tris",ContainsScripts=false},
	{Id=8690810714,Name="Bus Stop",Use="bus stop study",Budget="2.3k tris / 1 MeshPart",ContainsScripts=false},
	{Id=42942436,Name="Dumpster Free",Use="alley clutter",Budget="82 tris",ContainsScripts=false},
	{Id=1508286074,Name="Pipe",Use="industrial detail",Budget="4.3k tris",ContainsScripts=false},
	{Id=5133239835,Name="Street Sign SG",Use="street signage",Budget="2.5k tris",ContainsScripts=false},
	{Id=11211451410,Name="Metro",Use="metro reference",Budget="54.7k tris / 32 MeshParts",ContainsScripts=false},
	{Id=112527318,Name="subway-station",Use="low-cost subway reference",Budget="6.6k tris",ContainsScripts=false},
	{Id=9844241406,Name="Low-Poly Tree",Use="vegetation reference",Budget="not specified",ContainsScripts=false},
	{Id=80500557091895,Name="Low Poly Tree",Use="vegetation reference",Budget="456 tris / 5 MeshParts",ContainsScripts=false},
	{Id=13168370735,Name="Modular Building Kit - Modern City",Use="building modularity study",Budget="796k tris / 3,025 MeshParts",ContainsScripts=true},
}
function A.GetByUse(use:string)
	local out={}
	for _,item in ipairs(A.References)do if item.Use==use then table.insert(out,item)end end
	return out
end
return A
