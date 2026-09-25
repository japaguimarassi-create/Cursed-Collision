--!strict
local M={}
function M.GetWeightedReasons(world:any,history:{string})
	local recent={}
	for _,name in ipairs(history)do recent[name]=(recent[name]or 0)+1 end
	local base={{Name="Pressure",Weight=world.Threat>=55 and .55 or .18},{Name="Distortion",Weight=world.Energy>=45 and .35 or .14},{Name="Invasion",Weight=world.Activity>=60 and .24 or .10},{Name="Rare",Weight=.06}}
	local total=0
	for _,e in ipairs(base)do local hits=recent[e.Name]or 0;e.Weight*=1/(1+hits*.75);total+=e.Weight end
	if total<=0 then return {} end
	for _,e in ipairs(base)do e.Weight/=total end
	return base
end
return M
