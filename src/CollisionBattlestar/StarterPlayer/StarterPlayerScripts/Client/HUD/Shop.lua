--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Shop = {}

local function rounded(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, transparency: number?, thickness: number?)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0.2
    s.Thickness = thickness or 1
    s.Parent = parent
end

local function text(parent: Instance, value: string, size: number, color: Color3, align: Enum.TextXAlignment?)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = value
    l.TextColor3 = color
    l.Font = Enum.Font.GothamBold
    l.TextSize = size
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = parent
    return l
end

local function makeButton(parent: Instance, name: string, value: string, size: UDim2, color: Color3)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.BackgroundColor3 = color
    b.BackgroundTransparency = 0.04
    b.BorderSizePixel = 0
    b.Text = value
    b.TextColor3 = Color3.fromRGB(245,247,252)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.AutoButtonColor = false
    b.Parent = parent
    rounded(b, 12)
    stroke(b, Color3.fromRGB(72,82,103), 0.26, 1)
    return b
end

function Shop.Mount(root, config, player: Player, remote: RemoteEvent, stateRemote: RemoteEvent)
    local launcher = makeButton(root.Gui, "ShopButton", "STORE", UDim2.fromOffset(92, 34), config.UI.Surface2)
    launcher.Position = UDim2.new(1, -18, 0, 118)
    launcher.AnchorPoint = Vector2.new(1, 0)

    local overlay = Instance.new("Frame")
    overlay.Name = "ShopOverlay"
    overlay.Size = UDim2.fromScale(1,1)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.34
    overlay.BorderSizePixel = 0
    overlay.Visible = false
    overlay.ZIndex = 200
    overlay.Parent = root.Gui

    local window = Instance.new("Frame")
    window.Name = "ShopWindow"
    window.Size = UDim2.fromScale(0.9,0.84)
    window.Position = UDim2.fromScale(0.5,0.5)
    window.AnchorPoint = Vector2.new(0.5,0.5)
    window.BackgroundColor3 = config.UI.Surface
    window.BorderSizePixel = 0
    window.ZIndex = 201
    window.Parent = overlay
    rounded(window,22)
    stroke(window,config.UI.Stroke,0.08,1)

    local title = text(window,"STORE",20,config.UI.Text)
    title.Size = UDim2.fromOffset(150,28)
    title.Position = UDim2.fromOffset(20,14)
    title.ZIndex = 202

    local subtitle = text(window,"COSMETICS  •  COMPANIONS  •  UPGRADES  •  ROBUX",7,config.UI.Muted)
    subtitle.Size = UDim2.fromOffset(340,18)
    subtitle.Position = UDim2.fromOffset(21,42)
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.ZIndex = 202

    local balance = Instance.new("Frame")
    balance.Size = UDim2.fromOffset(150,36)
    balance.Position = UDim2.new(1,-200,0,15)
    balance.BackgroundColor3 = config.UI.Surface2
    balance.BackgroundTransparency = 0.04
    balance.BorderSizePixel = 0
    balance.ZIndex = 203
    balance.Parent = window
    rounded(balance,12)
    stroke(balance,config.UI.Stroke,0.24,1)
    local balanceText = text(balance,"◈ 0",11,config.UI.Warning)
    balanceText.Size = UDim2.new(1,-14,1,0)
    balanceText.Position = UDim2.fromOffset(7,0)
    balanceText.ZIndex = 204

    local closeButton = makeButton(window,"Close","×",UDim2.fromOffset(36,36),config.UI.Surface3)
    closeButton.Position = UDim2.new(1,-50,0,15)
    closeButton.TextSize = 18
    closeButton.ZIndex = 204
    balance.Position = UDim2.new(1,-194,0,15)

    local multiplierBar = Instance.new("Frame")
    multiplierBar.Size = UDim2.new(1,-40,0,40)
    multiplierBar.Position = UDim2.fromOffset(20,69)
    multiplierBar.BackgroundColor3 = config.UI.Surface2
    multiplierBar.BackgroundTransparency = 0.08
    multiplierBar.BorderSizePixel = 0
    multiplierBar.ZIndex = 202
    multiplierBar.Parent = window
    rounded(multiplierBar,12)

    local multiplierText = text(multiplierBar,"MONEY x1     DAMAGE x1     SPEED x1",8,config.UI.Text,Enum.TextXAlignment.Center)
    multiplierText.Size = UDim2.fromScale(1,1)
    multiplierText.ZIndex = 203

    local tabs = Instance.new("ScrollingFrame")
    tabs.Name = "Tabs"
    tabs.Size = UDim2.new(1,-40,0,38)
    tabs.Position = UDim2.fromOffset(20,117)
    tabs.BackgroundTransparency = 1
    tabs.BorderSizePixel = 0
    tabs.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabs.CanvasSize = UDim2.new()
    tabs.ScrollingDirection = Enum.ScrollingDirection.X
    tabs.ScrollBarThickness = 0
    tabs.ZIndex = 202
    tabs.Parent = window

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,7)
    tabLayout.Parent = tabs

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1,-40,1,-174)
    content.Position = UDim2.fromOffset(20,164)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageTransparency = 0.3
    content.ZIndex = 202
    content.Parent = window

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0,2)
    padding.PaddingRight = UDim.new(0,7)
    padding.PaddingBottom = UDim.new(0,12)
    padding.Parent = content

    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.fromOffset(10,10)
    grid.CellSize = UDim2.new(0.5,-7,0,148)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = content

    local category = "FEATURED"
    local categories = {"FEATURED","SKINS","COMPANIONS","PASSES","CREDITS","BOOSTS","UPGRADES"}

    local function refreshHeader()
        balanceText.Text = ("◈ %s"):format(tostring(player:GetAttribute("Credits") or 0))
        multiplierText.Text = ("MONEY x%d     DAMAGE x%d     SPEED x%d"):format(
            player:GetAttribute("MoneyMultiplier") or 1,
            player:GetAttribute("DamageMultiplier") or 1,
            player:GetAttribute("SpeedMultiplier") or 1
        )
    end

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.fromOffset(0,grid.AbsoluteContentSize.Y+20)
    end)

    local function updateGrid()
        local camera = workspace.CurrentCamera
        local width = camera and camera.ViewportSize.X or 1000
        grid.CellSize = if width < 720 then UDim2.new(1,-4,0,148) else UDim2.new(0.5,-7,0,148)
    end

    local function createCard(item, order)
        local card = Instance.new("Frame")
        card.Name = "Item_"..order
        card.LayoutOrder = order
        card.BackgroundColor3 = config.UI.Surface2
        card.BackgroundTransparency = 0.04
        card.BorderSizePixel = 0
        card.ZIndex = 203
        card.Parent = content
        rounded(card,16)
        stroke(card,config.UI.Stroke,0.27,1)

        local preview = Instance.new("Frame")
        preview.Size = UDim2.fromOffset(64,64)
        preview.Position = UDim2.fromOffset(12,12)
        preview.BackgroundColor3 = item.Color or config.UI.Surface3
        preview.BorderSizePixel = 0
        preview.ZIndex = 204
        preview.Parent = card
        rounded(preview,14)

        local glyph = text(preview,item.Glyph or "✦",22,Color3.fromRGB(245,247,252),Enum.TextXAlignment.Center)
        glyph.Size = UDim2.fromScale(1,1)
        glyph.ZIndex = 205

        local name = text(card,item.Name,10,config.UI.Text)
        name.Size = UDim2.new(1,-90,0,20)
        name.Position = UDim2.fromOffset(88,11)
        name.ZIndex = 205

        local description = text(card,item.Description or "",7,config.UI.Muted)
        description.Size = UDim2.new(1,-90,0,37)
        description.Position = UDim2.fromOffset(88,30)
        description.Font = Enum.Font.GothamMedium
        description.TextWrapped = true
        description.ZIndex = 205

        local info = text(card,"",8,config.UI.Muted)
        info.Size = UDim2.new(1,-24,0,18)
        info.Position = UDim2.fromOffset(12,82)
        info.ZIndex = 205

        local buy = makeButton(card,"Action_"..order,"BUY",UDim2.new(1,-24,0,34),config.UI.Surface3)
        buy.Position = UDim2.fromOffset(12,106)
        buy.ZIndex = 206

        local function render()
            if item.Type == "Skin" then
                local owned = item.Key == "Default" or player:GetAttribute("Skin_"..item.Key) == true
                local equipped = (player:GetAttribute("EquippedSkin") or "Default") == item.Key
                info.Text = item.Key == "Default" and "FREE" or ("◈ %d C"):format(item.Cost)
                buy.Text = equipped and "EQUIPPED" or (owned and "EQUIP" or ("BUY • %d C"):format(item.Cost))
                buy.BackgroundColor3 = equipped and config.UI.Good or config.UI.Surface3
                buy.Active = not equipped
            elseif item.Type == "Companion" then
                local amount = player:GetAttribute("Companion_"..item.Key) or 0
                info.Text = ("%d/2 OWNED • %d DAMAGE"):format(amount,item.Damage)
                buy.Text = amount >= 2 and "MAXED" or ("BUY • %d C"):format(item.Cost)
                buy.BackgroundColor3 = amount >= 2 and config.UI.Good or config.UI.Surface3
                buy.Active = amount < 2
            elseif item.Type == "Pass" then
                local owned = player:GetAttribute("Pass_"..item.Key) == true
                info.Text = item.Id > 0 and ("R$ %d"):format(item.Price) or "PASS ID NOT CONFIGURED"
                buy.Text = owned and "OWNED" or (item.Id > 0 and ("BUY • R$ %d"):format(item.Price) or "UNAVAILABLE")
                buy.BackgroundColor3 = owned and config.UI.Good or config.UI.Surface3
                buy.Active = not owned and item.Id > 0
            elseif item.Type == "Product" then
                info.Text = item.Id > 0 and ("R$ %d"):format(item.Price) or "PRODUCT ID NOT CONFIGURED"
                buy.Text = item.Id > 0 and ("BUY • R$ %d"):format(item.Price) or "UNAVAILABLE"
                buy.Active = item.Id > 0
            elseif item.Type == "Boost" then
                local current = player:GetAttribute(item.Attribute) or 1
                info.Text = ("x%d  →  x%d"):format(current,current+1)
                buy.Text = item.Id > 0 and ("BUY +1x • R$ %d"):format(item.Price) or "UNAVAILABLE"
                buy.Active = item.Id > 0
            elseif item.Type == "Upgrade" then
                local level = player:GetAttribute(item.Key.."Level") or 0
                local def = config.Shop[item.Key]
                local max = def and def.MaxLevel or level
                local cost = def and math.floor(def.BaseCost * def.Growth ^ level) or 0
                info.Text = ("LEVEL %d/%d"):format(level,max)
                buy.Text = level >= max and "MAXED" or ("UPGRADE • %d C"):format(cost)
                buy.BackgroundColor3 = level >= max and config.UI.Good or config.UI.Surface3
                buy.Active = level < max
            end
        end

        buy.Activated:Connect(function()
            if not buy.Active then return end
            if item.Type == "Skin" then
                local owned = item.Key == "Default" or player:GetAttribute("Skin_"..item.Key) == true
                remote:FireServer(owned and "EquipSkin" or "PurchaseSkin",item.Key)
            elseif item.Type == "Companion" then
                remote:FireServer("PurchaseCompanion",item.Key)
            elseif item.Type == "Pass" then
                remote:FireServer("PromptPass",item.Key)
            elseif item.Type == "Product" or item.Type == "Boost" then
                if item.Id > 0 then
                    MarketplaceService:PromptProductPurchase(player,item.Id)
                end
            elseif item.Type == "Upgrade" then
                remote:FireServer("Upgrade",item.Key)
            end
        end)

        render()
    end

    local function buildItems()
        local items = {}

        if category == "FEATURED" then
            table.insert(items,{Type="Skin",Key="ShadowRonin",Name="Shadow Ronin",Description="Skin anime urbana de energia sombria.",Cost=500,Color=Color3.fromRGB(95,105,180),Glyph="✦"})
            table.insert(items,{Type="Companion",Key="Scout",Name="Scout",Description="Aliado rápido para começar.",Cost=250,Damage=14,Color=config.UI.Info,Glyph="C"})
            for _,pass in ipairs(config.GamePasses) do
                if pass.Key == "VIP" then
                    table.insert(items,{Type="Pass",Key=pass.Key,Name=pass.Name,Description=pass.Description,Price=pass.Price or 0,Id=pass.Id,Color=config.UI.Warning,Glyph="★"})
                    break
                end
            end
            local moneyProduct = nil
            for _,product in ipairs(config.Shop.DeveloperProducts) do
                if product.Kind == "MoneyMultiplier" then moneyProduct = product break end
            end
            if moneyProduct then
                table.insert(items,{Type="Boost",Key=moneyProduct.Key,Name="2x Money",Description="Cada compra soma +1x aos Credits.",Id=moneyProduct.Id,Price=moneyProduct.Price,Attribute="MoneyMultiplier",Color=config.UI.Good,Glyph="◈"})
            end
        elseif category == "SKINS" then
            for _,skin in ipairs(config.Shop.Skins) do
                table.insert(items,{Type="Skin",Key=skin.Key,Name=skin.DisplayName,Description=skin.Description,Cost=skin.Cost,Color=skin.Color,Glyph=skin.Key=="Default" and "○" or "✦"})
            end
        elseif category == "COMPANIONS" then
            for _,companion in ipairs(config.Shop.Companions) do
                table.insert(items,{Type="Companion",Key=companion.Key,Name=companion.DisplayName,Description=("HP %d • SPD %d • RNG %d"):format(companion.Health,companion.Speed,companion.AttackRange),Cost=companion.Cost,Damage=companion.Damage,Color=config.UI.Info,Glyph="C"})
            end
        elseif category == "PASSES" then
            for _,pass in ipairs(config.GamePasses) do
                table.insert(items,{Type="Pass",Key=pass.Key,Name=pass.Name,Description=pass.Description,Price=pass.Price,Id=pass.Id,Color=config.UI.Warning,Glyph="★"})
            end
        elseif category == "CREDITS" then
            for _,product in ipairs(config.Shop.DeveloperProducts) do
                if product.Kind == "Credits" then
                    table.insert(items,{Type="Product",Key=product.Key,Name=product.Name,Description=product.Description,Price=product.Price,Id=product.Id,Color=config.UI.Warning,Glyph="◈"})
                end
            end
        elseif category == "BOOSTS" then
            local defs={
                {Kind="MoneyMultiplier",Attribute="MoneyMultiplier",Name="2x Money",Description="Créditos recebidos usam este multiplicador.",Color=config.UI.Good,Glyph="◈"},
                {Kind="DamageMultiplier",Attribute="DamageMultiplier",Name="2x Damage",Description="Seu dano final usa este multiplicador.",Color=config.UI.Danger,Glyph="⚔"},
                {Kind="SpeedMultiplier",Attribute="SpeedMultiplier",Name="2x Speed",Description="Velocidade e dash usam este multiplicador.",Color=config.UI.Info,Glyph="↯"},
            }
            for _,def in ipairs(defs) do
                for _,product in ipairs(config.Shop.DeveloperProducts) do
                    if product.Kind == def.Kind then
                        table.insert(items,{Type="Boost",Key=product.Key,Name=def.Name,Description=def.Description,Price=product.Price,Id=product.Id,Attribute=def.Attribute,Color=def.Color,Glyph=def.Glyph})
                    end
                end
            end
        elseif category == "UPGRADES" then
            for _,key in ipairs({"Damage","Defense","Speed"}) do
                table.insert(items,{Type="Upgrade",Key=key,Name=key:upper(),Description="Upgrade permanente comprado com Credits.",Color=config.UI.Accent,Glyph=key=="Damage" and "⚔" or (key=="Defense" and "◆" or "↯")})
            end
        end

        return items
    end

    local function repopulate()
        for _,child in ipairs(content:GetChildren()) do
            if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
        for order,item in ipairs(buildItems()) do
            createCard(item,order)
        end
        updateGrid()
        refreshHeader()
    end

    for index,name in ipairs(categories) do
        local tab=makeButton(tabs,"Tab_"..name,name,UDim2.fromOffset(98,34),config.UI.Surface2)
        tab.LayoutOrder=index
        tab.TextSize=8
        tab.ZIndex=203
        tab.Activated:Connect(function()
            category=name
            repopulate()
        end)
    end

    local function open()
        overlay.Visible=true
        repopulate()
        local target=window.Size
        window.Size=UDim2.fromScale(0.84,0.78)
        TweenService:Create(window,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=target}):Play()
    end

    local function close()
        overlay.Visible=false
    end

    launcher.Activated:Connect(open)
    closeButton.Activated:Connect(close)

    player:GetAttributeChangedSignal("Credits"):Connect(function()
        refreshHeader()
        if overlay.Visible then repopulate() end
    end)

    for _,attribute in ipairs({"MoneyMultiplier","DamageMultiplier","SpeedMultiplier","EquippedSkin"}) do
        player:GetAttributeChangedSignal(attribute):Connect(function()
            if overlay.Visible then repopulate() end
            refreshHeader()
        end)
    end

    for _,pass in ipairs(config.GamePasses) do
        player:GetAttributeChangedSignal("Pass_"..pass.Key):Connect(function()
            if overlay.Visible then repopulate() end
        end)
    end

    for _,skin in ipairs(config.Shop.Skins) do
        player:GetAttributeChangedSignal("Skin_"..skin.Key):Connect(function()
            if overlay.Visible then repopulate() end
        end)
    end

    for _,companion in ipairs(config.Shop.Companions) do
        player:GetAttributeChangedSignal("Companion_"..companion.Key):Connect(function()
            if overlay.Visible then repopulate() end
        end)
    end

    stateRemote.OnClientEvent:Connect(function(kind)
        if kind == "ShopMessage" or kind == "ProductGranted" then
            refreshHeader()
            if overlay.Visible then repopulate() end
        end
    end)

    refreshHeader()
    return {Open=open,Close=close,Button=launcher}
end

return Shop
