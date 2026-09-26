--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage.Shared.StoreCatalog)
local CharacterDefinitions=require(ReplicatedStorage.Shared.CharacterDefinitions)

local M={}
local DataService

function M:Init(dataService)
 DataService=dataService
end

function M:ShopState(player:Player,feedback:RemoteEvent)
 local p=DataService:Get(player)
 if not p then return end
 local owned={}
 for id,value in pairs(p.Owned) do if value then table.insert(owned,id) end end
 feedback:FireClient(player,"ShopState",{Credits=p.Credits,Owned=owned,Character=p.EquippedCharacter,Title=p.EquippedTitle})
end

function M:BuyItem(player:Player,itemId:string,feedback:RemoteEvent)
 local item=Catalog.Get(itemId)
 if not item then feedback:FireClient(player,"Message","ITEM NOT FOUND");return end
 if item.Category=="Emotes" or item.Category=="Featured" then
  if DataService:Buy(player,itemId,item.Price) then feedback:FireClient(player,"Message","UNLOCKED  •  "..item.Name);self:ShopState(player,feedback)
  else feedback:FireClient(player,"Message","NOT ENOUGH CREDITS") end
 end
end

function M:EquipItem(player:Player,itemId:string,feedback:RemoteEvent)
 local p=DataService:Get(player)
 local item=Catalog.Get(itemId)
 if not p or not item or not p.Owned[itemId] then return end
 if item.Kind=="Title" then
  DataService:SetTitle(player,item.Name)
 end
 feedback:FireClient(player,"Message","EQUIPPED  •  "..item.Name)
 self:ShopState(player,feedback)
end

function M:SetCharacter(player:Player,id:string,feedback:RemoteEvent)
 local fighter=CharacterDefinitions.Get(id)
 if not fighter then return end
 DataService:SetCharacter(player,id)
 feedback:FireClient(player,"CharacterChanged",fighter.DisplayName)
end

function M:RedeemCode(player:Player,code:string,feedback:RemoteEvent)
 local rewards={CBS2026=250,WELCOME=125,BATTLELINE=100}
 local normalized=string.upper(string.gsub(code or "","%s+",""))
 local reward=rewards[normalized]
 if reward and DataService:UseCode(player,normalized,reward) then
  feedback:FireClient(player,"Message","CODE REDEEMED  •  +"..reward.." C")
 else
  feedback:FireClient(player,"Message","INVALID OR USED CODE")
 end
end

function M:ClaimMission(player:Player,kind:string,feedback:RemoteEvent)
 local reward=DataService:ClaimMission(player,kind)
 if reward>0 then feedback:FireClient(player,"Message",kind.." MISSION  •  +"..reward.." C") else feedback:FireClient(player,"Message","MISSION NOT READY") end
end

return M