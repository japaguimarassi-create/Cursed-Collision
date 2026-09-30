--!strict

local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog=require(Shared:WaitForChild("ShopDefinitions"))
local Rules=require(Shared:WaitForChild("ShopRules"))
local Inventory=require(script.Parent:WaitForChild("InventoryService"))

local Service={}
Service.__index=Service

function Service.new()
    return setmetatable({players=nil,inventory=nil,remote=nil,stateRemote=nil,lastRequest={}},Service)
end

function Service:Init(registry,remotes)
    self.players=registry:Get("PlayerState")
    self.inventory=Inventory.new(self.players)
    self.remote=remotes.Commerce
    self.stateRemote=remotes.State

    self.remote.OnServerEvent:Connect(function(player:Player,action,itemId)
        local now=os.clock()
        if now-(self.lastRequest[player] or 0)<0.25 then return end
        self.lastRequest[player]=now
        if action=="Catalog" then self:SendCatalog(player)
        elseif action=="Purchase" then self:Purchase(player,itemId)
        elseif action=="Equip" then self:EquipSkin(player,itemId)
        elseif action=="EquipEcho" then self:EquipEcho(player,itemId)
        end
    end)

    Players.PlayerRemoving:Connect(function(player) self.lastRequest[player]=nil end)
end

function Service:SendCatalog(player:Player)
    local items={}
    for itemId,item in pairs(Catalog.Items) do
        table.insert(items,{ItemId=itemId,Category=item.Category,Price=item.Price,DisplayName=item.DisplayName,Description=item.Description,Owned=self.inventory:Owns(player,itemId),Equipped=(
            item.Category=="Skin" and player:GetAttribute("EquippedSkin")==itemId)
            or (item.Category=="Echo" and player:GetAttribute("EquippedEcho")==itemId)})
    end
    table.sort(items,function(a,b) return a.ItemId<b.ItemId end)
    self.remote:FireClient(player,"Catalog",items,player:GetAttribute("Credits") or 0)
end

function Service:Purchase(player:Player,itemId)
    if type(itemId)~="string" then return end
    local item=Catalog.Items[itemId]
    if not item or item.Price<=0 or self.inventory:Owns(player,itemId) then
        self.remote:FireClient(player,"PurchaseFailed",itemId,"InvalidOrOwned")
        return
    end
    local credits=player:GetAttribute("Credits") or 0
    if not Rules.canPurchase(credits,item.Price,false) then
        self.remote:FireClient(player,"PurchaseFailed",itemId,"Credits")
        return
    end
    if not self.players:SpendCredits(player,item.Price) then return end
    if not self.inventory:Grant(player,itemId) then
        self.players:AddCredits(player,item.Price)
        self.remote:FireClient(player,"PurchaseFailed",itemId,"Grant")
        return
    end
    self.stateRemote:FireClient(player,"Credits",player:GetAttribute("Credits") or 0,"Shop")
    self.remote:FireClient(player,"Purchased",itemId)
end

function Service:EquipSkin(player:Player,itemId:string)
    local item=Catalog.Items[itemId]
    if not item or item.Category~="Skin" then return end
    if self.inventory:EquipSkin(player,itemId) then
        self.remote:FireClient(player,"Equipped",itemId)
    end
end

function Service:EquipEcho(player:Player,itemId:string)
    if type(itemId)~="string" then return end
    local item=Catalog.Items[itemId]
    if not item or item.Category~="Echo" then return end
    if not self.inventory:Owns(player,itemId) then return end
    if self.players:SetEquippedEcho(player,itemId) then
        self.remote:FireClient(player,"EquippedEcho",itemId)
        self:SendCatalog(player)
    end
end

return Service
