--!strict

local Components=require(script.Parent:WaitForChild("Components"))
local Theme=require(script.Parent:WaitForChild("Theme"))

local Shop={}
Shop.__index=Shop

function Shop.Create(rootFrame:Frame,commerce:RemoteEvent,player:Player)
    local self=setmetatable({rootFrame=rootFrame,commerce=commerce,player=player,connections={},items={}},Shop)
    local panel=Components.Panel(rootFrame,"ShopPanel",UDim2.fromOffset(390,500),UDim2.new(.5,-195,.5,-250),16)
    panel.Visible=false
    panel.ZIndex=40
    self.panel=panel

    local title=Components.Label(panel,"Title","COLLISION SHOP",UDim2.new(1,-110,0,30),UDim2.fromOffset(18,14),20,Theme.Colors.Text,true)
    title.ZIndex=41
    self.balance=Components.Label(panel,"Balance","CREDITS 0",UDim2.fromOffset(150,22),UDim2.fromOffset(18,44),12,Theme.Colors.Gold,true)
    self.balance.ZIndex=41

    local close=Components.Button(panel,"Close","CLOSE",UDim2.fromOffset(72,32),UDim2.new(1,-88,0,12),Theme.Colors.PanelSoft,10,10)
    close.ZIndex=41
    close.Activated:Connect(function() self:Toggle(false) end)

    local list=Instance.new("ScrollingFrame")
    list.Name="Items"
    list.Size=UDim2.new(1,-28,1,-88)
    list.Position=UDim2.fromOffset(14,76)
    list.BackgroundTransparency=1
    list.BorderSizePixel=0
    list.ScrollBarThickness=5
    list.CanvasSize=UDim2.fromOffset(0,0)
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y
    list.Parent=panel
    list.ZIndex=41
    self.list=list

    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,9)
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Parent=list

    table.insert(self.connections,commerce.OnClientEvent:Connect(function(kind,...)
        local args={...}
        if kind=="Catalog" then
            self:Render(args[1],args[2])
        elseif kind=="Purchased" then
            self:RenderMessage("PURCHASED")
            self:Request()
        elseif kind=="PurchaseFailed" then
            self:RenderMessage("PURCHASE FAILED")
        elseif kind=="Equipped" or kind=="EchoEquipped" then
            self:RenderMessage("EQUIPPED")
            self:Request()
        end
    end))
    return self
end

function Shop:RenderMessage(text:string)
    self.balance.Text=text
    task.delay(1,function()
        if self.panel.Visible then self:Request() end
    end)
end

function Shop:Clear()
    for _,child in ipairs(self.list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

function Shop:Render(items,credits)
    self:Clear()
    self.balance.Text="CREDITS "..tostring(math.max(0,tonumber(credits) or 0))
    local order=0
    for _,item in ipairs(items or {}) do
        order+=1
        local card=Components.Panel(self.list,"Item",UDim2.new(1,-8,0,84),UDim2.fromOffset(0,0),12)
        card.LayoutOrder=order
        card.ZIndex=42

        local name=Components.Label(card,"Name",item.DisplayName,UDim2.new(1,-118,0,22),UDim2.fromOffset(12,8),14,Theme.Colors.Text,true)
        name.ZIndex=43
        local desc=Components.Label(card,"Description",item.Description,UDim2.new(1,-118,0,32),UDim2.fromOffset(12,31),10,Theme.Colors.Muted,false)
        desc.TextWrapped=true
        desc.ZIndex=43

        local action=Components.Button(card,"Action",item.Owned and "EQUIP" or ("BUY "..tostring(item.Price)),UDim2.fromOffset(92,42),UDim2.new(1,-104,0,20),item.Owned and Theme.Colors.CyanDark or Theme.Colors.PanelSoft,10,11)
        action.ZIndex=43
        action.Activated:Connect(function()
            if item.Owned then
                if item.Category=="Echo" then
                    self.commerce:FireServer("EquipEcho",item.ItemId)
                else
                    self.commerce:FireServer("Equip",item.ItemId)
                end
            else
                self.commerce:FireServer("Purchase",item.ItemId)
            end
        end)
    end
end

function Shop:Request()
    self.commerce:FireServer("Catalog")
end

function Shop:Toggle(open:boolean?)
    local value=if open==nil then not self.panel.Visible else open
    self.panel.Visible=value
    if value then self:Request() end
end

function Shop:Destroy()
    for _,c in ipairs(self.connections) do c:Disconnect() end
    if self.panel then self.panel:Destroy() end
end

return Shop
