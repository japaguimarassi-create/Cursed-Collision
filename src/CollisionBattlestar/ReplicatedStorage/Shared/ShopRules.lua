--!strict
local Rules={}
function Rules.price(itemId:string,catalog):number? local item=catalog[itemId] return item and item.Price or nil end
function Rules.canPurchase(credits:number,price:number,owned:boolean):boolean return credits>=0 and price>0 and credits>=price and not owned end
return table.freeze(Rules)
