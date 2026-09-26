--!strict
local A={}
A.References={
	{Id=6370681139,Name="City Props Pack",Use="street props",Budget="66k tris / 94 MeshParts",ContainsScripts=true,RuntimeApproved=false,License="Creator Store reference; not approved for automatic runtime loading"},
	{Id=383275076,Name="Street Lamp",Use="street lighting reference",Budget="5.5k tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=11146095708,Name="Street Lamp",Use="low-cost street lighting reference",Budget="768 tris / 1 MeshPart",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=400850371,Name="Bench",Use="park seating",Budget="228 tris / 456 vertices",ContainsScripts=false,RuntimeApproved=true,License="Creator Store: description says free bench model",Source="https://create.roblox.com/store/asset/400850371/Bench"},
	{Id=70028753,Name="Traffic Cone",Use="construction clutter",Budget="326 tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=839465687,Name="Billboard",Use="billboards",Budget="2.1k tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=18210310901,Name="Billboard Set v1",Use="signage study",Budget="4.2k tris / 68 items",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=11573553721,Name="Car Mesh",Use="vehicle silhouette study",Budget="manual inspection required",ContainsScripts=true,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=87547058560755,Name="BUS stop",Use="bus stop detail",Budget="660 tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=8690810714,Name="Bus Stop",Use="bus stop study",Budget="2.3k tris / 1 MeshPart",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=42942436,Name="Dumpster Free",Use="alley clutter",Budget="82 tris / 164 vertices",ContainsScripts=false,RuntimeApproved=true,License="Creator Store item explicitly titled Dumpster Free",Source="https://create.roblox.com/store/asset/42942436/Dumpster-Free"},
	{Id=1508286074,Name="Pipe",Use="industrial detail",Budget="4.3k tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=5133239835,Name="Street Sign SG",Use="street signage",Budget="2.5k tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=11211451410,Name="Metro",Use="metro reference",Budget="54.7k tris / 32 MeshParts",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; too heavy for routine mobile loading"},
	{Id=112527318,Name="subway-station",Use="low-cost subway reference",Budget="6.6k tris",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=9844241406,Name="Low-Poly Tree",Use="vegetation reference",Budget="not specified",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=80500557091895,Name="Low Poly Tree",Use="vegetation reference",Budget="456 tris / 5 MeshParts",ContainsScripts=false,RuntimeApproved=false,License="Creator Store reference; runtime license not verified"},
	{Id=13168370735,Name="Modular Building Kit - Modern City",Use="building modularity study",Budget="796k tris / 3,025 MeshParts",ContainsScripts=true,RuntimeApproved=false,License="Creator Store reference; too heavy for routine mobile loading"},
	{Id=282662596,Name="Small Blocky Car",Use="street parking",Budget="792 tris / 1,272 vertices",ContainsScripts=true,RuntimeApproved=true,License="Creator Store title explicitly marks it FREE",Source="https://create.roblox.com/store/asset/282662596/FREE-Small-Blocky-Car"},
}
A.Runtime={Bench=400850371,Dumpster=42942436,Car=282662596}
function A.GetByUse(use:string)
	local out={}
	for _,item in ipairs(A.References)do
		if item.Use==use then table.insert(out,item)end
	end
	return out
end
function A.GetById(id:number)
	for _,item in ipairs(A.References)do
		if item.Id==id then return item end
	end
	return nil
end
return A
