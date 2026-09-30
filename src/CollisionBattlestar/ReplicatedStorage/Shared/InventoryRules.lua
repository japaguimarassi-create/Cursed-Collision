--!strict
local Rules={}
function Rules.canEquip(itemId:string,owned:{[string]:boolean}):boolean return type(itemId)=="string" and itemId~="" and owned[itemId]==true end
function Rules.owns(itemId:string,owned:{[string]:boolean}):boolean return type(itemId)=="string" and owned[itemId]==true end
return table.freeze(Rules)
