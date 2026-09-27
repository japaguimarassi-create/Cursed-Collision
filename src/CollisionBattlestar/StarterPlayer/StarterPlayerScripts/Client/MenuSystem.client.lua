--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateRemote = remotes:WaitForChild("State") :: RemoteEvent
local shopRemote = remotes:WaitForChild("Shop") :: RemoteEvent
local travelRemote = remotes:WaitForChild("Travel") :: RemoteEvent
local adminRemote = remotes:WaitForChild("AdminAction") :: RemoteEvent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local gui = Instance.new("ScreenGui")
gui.Name = "CollisionBattlestarMenuV6"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.DisplayOrder = 82
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(3, 5, 9)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 1
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "MenuPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.53)
panel.Size = UDim2.fromScale(0.9, 0.78)
panel.BackgroundColor3 = Config.UI.Surface
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
panel.Parent = gui

local panelConstraint = Instance.new("UISizeConstraint")
panelConstraint.MinSize = Vector2.new(320, 360)
panelConstraint.MaxSize = Vector2.new(980, 650)
panelConstraint.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 22)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Config.UI.Stroke
panelStroke.Thickness = 1
panelStroke.Transparency = 0.28
panelStroke.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundTransparency = 1
header.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -150, 0, 28)
title.Position = UDim2.fromOffset(24, 15)
title.BackgroundTransparency = 1
title.Text = "CONTROL CENTER"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Config.UI.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -150, 0, 18)
subtitle.Position = UDim2.fromOffset(24, 41)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Battleline systems, profile, shop and moderation"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 9
subtitle.TextColor3 = Config.UI.Muted
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local balance = Instance.new("TextLabel")
balance.Size = UDim2.fromOffset(110, 34)
balance.Position = UDim2.new(1, -156, 0, 18)
balance.BackgroundColor3 = Config.UI.Surface2
balance.BorderSizePixel = 0
balance.Text = "◈ 0"
balance.Font = Enum.Font.GothamBold
balance.TextSize = 11
balance.TextColor3 = Config.UI.Text
balance.Parent = header

local balanceCorner = Instance.new("UICorner")
balanceCorner.CornerRadius = UDim.new(0, 12)
balanceCorner.Parent = balance

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(34, 34)
closeButton.Position = UDim2.new(1, -50, 0, 18)
closeButton.BackgroundColor3 = Config.UI.Surface3
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.TextColor3 = Config.UI.Text
closeButton.AutoButtonColor = true
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeButton

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 154, 1, -86)
sidebar.Position = UDim2.fromOffset(14, 76)
sidebar.BackgroundColor3 = Config.UI.Background
sidebar.BorderSizePixel = 0
sidebar.Parent = panel

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 16)
sidebarCorner.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 10)
sidebarPadding.PaddingBottom = UDim.new(0, 10)
sidebarPadding.PaddingLeft = UDim.new(0, 9)
sidebarPadding.PaddingRight = UDim.new(0, 9)
sidebarPadding.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -186, 1, -86)
content.Position = UDim2.fromOffset(176, 76)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageTransparency = 0.45
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.CanvasSize = UDim2.new()
content.Parent = panel

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingBottom = UDim.new(0, 12)
contentPadding.PaddingLeft = UDim.new(0, 4)
contentPadding.PaddingRight = UDim.new(0, 10)
contentPadding.PaddingTop = UDim.new(0, 4)
contentPadding.Parent = content

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(9, 9)
grid.CellSize = UDim2.fromOffset(210, 132)
grid.FillDirectionMaxCells = 3
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = content

local openButton = Instance.new("TextButton")
openButton.Name = "ControlCenterButton"
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Position = UDim2.new(1, -16, 0, 84)
openButton.Size = UDim2.fromOffset(116, 40)
openButton.BackgroundColor3 = Config.UI.Surface
openButton.BorderSizePixel = 0
openButton.Text = "MENU"
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 10
openButton.TextColor3 = Config.UI.Text
openButton.AutoButtonColor = true
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 13)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Config.UI.Stroke
openStroke.Transparency = 0.35
openStroke.Parent = openButton

local activeTab = "Shop"
local menuOpen = false
local adminTabButton: TextButton? = nil
local adminTargetId: number? = nil
local cameraBlur: BlurEffect? = nil

local function corner(instance: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = instance
end

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function text(parent: Instance, value: string, size: number, color: Color3?, bold: boolean?)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = value
    label.Font = bold == false and Enum.Font.GothamMedium or Enum.Font.GothamBold
    label.TextSize = size
    label.TextColor3 = color or Config.UI.Text
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function button(parent: Instance, labelText: string, callback, size: UDim2?)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(1, 0, 0, 32)
    b.BackgroundColor3 = Config.UI.Surface2
    b.BorderSizePixel = 0
    b.Text = labelText
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = Config.UI.Text
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Config.UI.Stroke
    stroke.Transparency = 0.55
    stroke.Parent = b
    b.Activated:Connect(callback)
    return b
end

local function card(titleText: string, bodyText: string?)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Config.UI.Surface2
    frame.BorderSizePixel = 0
    frame.LayoutOrder = 1
    frame.Parent = content
    corner(frame, 15)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Config.UI.Stroke
    stroke.Transparency = 0.58
    stroke.Parent = frame

    local heading = text(frame, titleText, 11, Config.UI.Text, true)
    heading.Size = UDim2.new(1, -24, 0, 24)
    heading.Position = UDim2.fromOffset(12, 10)

    if bodyText then
        local body = text(frame, bodyText, 8, Config.UI.Muted, false)
        body.Size = UDim2.new(1, -24, 0, 34)
        body.Position = UDim2.fromOffset(12, 35)
    end

    return frame
end

local function headerCard(titleText: string, bodyText: string?)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(210, 92)
    frame.BackgroundColor3 = Config.UI.Surface3
    frame.BorderSizePixel = 0
    frame.LayoutOrder = 0
    frame.Parent = content
    corner(frame, 15)
    local heading = text(frame, titleText, 14, Config.UI.Text, true)
    heading.Size = UDim2.new(1, -20, 0, 26)
    heading.Position = UDim2.fromOffset(10, 9)
    if bodyText then
        local body = text(frame, bodyText, 8, Config.UI.Muted, false)
        body.Size = UDim2.new(1, -20, 0, 38)
        body.Position = UDim2.fromOffset(10, 37)
    end
    return frame
end

local function valueBox(parent: Instance, placeholder: string)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 34)
    box.BackgroundColor3 = Config.UI.Background
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Config.UI.Subtle
    box.Text = ""
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 9
    box.TextColor3 = Config.UI.Text
    box.ClearTextOnFocus = false
    box.Parent = parent
    corner(box, 10)
    return box
end

local function setCameraMenuBlur(enabled: boolean)
    local camera = workspace.CurrentCamera
    if not camera then return end
    if enabled then
        if not cameraBlur then
            cameraBlur = Instance.new("BlurEffect")
            cameraBlur.Name = "CBS_MenuBlur"
            cameraBlur.Size = 0
            cameraBlur.Parent = camera
        end
        TweenService:Create(cameraBlur, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {Size = 9}):Play()
    elseif cameraBlur then
        local tween = TweenService:Create(cameraBlur, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Size = 0})
        tween:Play()
        tween.Completed:Connect(function()
            if cameraBlur and cameraBlur.Size < 0.5 then
                cameraBlur:Destroy()
                cameraBlur = nil
            end
        end)
    end
end

local function openMenu()
    menuOpen = true
    panel.Visible = true
    overlay.Visible = true
    openButton.Visible = false
    panel.Position = UDim2.fromScale(0.5, 0.56)
    panel.BackgroundTransparency = 1
    TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
        Position = UDim2.fromScale(0.5, 0.53),
        BackgroundTransparency = 0,
    }):Play()
    setCameraMenuBlur(true)
end

local function closeMenu()
    menuOpen = false
    openButton.Visible = true
    setCameraMenuBlur(false)
    local tween = TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
        Position = UDim2.fromScale(0.5, 0.56),
        BackgroundTransparency = 1,
    })
    tween:Play()
    tween.Completed:Connect(function()
        if not menuOpen then
            panel.Visible = false
            overlay.Visible = false
        end
    end)
end

local function updateBalance()
    balance.Text = "◈ " .. tostring(player:GetAttribute("Credits") or 0)
end

local function skinOwned(key: string): boolean
    return key == "Default" or player:GetAttribute("Skin_" .. key) == true
end

local function upgradeCost(kind: string): number
    local data = Config.Shop[kind]
    if type(data) ~= "table" then return 0 end
    local level = tonumber(player:GetAttribute(kind .. "Level")) or 0
    return math.floor(data.BaseCost * data.Growth ^ level)
end

local function renderShop()
    clearContent()
    headerCard("UPGRADES", "Permanent combat stats. Prices scale with level.")
    for _, kind in ipairs({"Damage", "Defense", "Speed"}) do
        local level = tonumber(player:GetAttribute(kind .. "Level")) or 0
        local frame = card(kind:upper(), ("LEVEL %d"):format(level))
        frame.LayoutOrder = 2
        local cost = text(frame, ("◈ %d"):format(upgradeCost(kind)), 10, Config.UI.Warning, true)
        cost.Size = UDim2.new(1, -24, 0, 20)
        cost.Position = UDim2.fromOffset(12, 70)
        button(frame, "UPGRADE", function()
            shopRemote:FireServer("Upgrade", kind)
            task.delay(0.3, renderShop)
        end, UDim2.new(1, -24, 0, 28)).Position = UDim2.fromOffset(12, 98)
    end

    headerCard("SKINS", "Cosmetic loadouts with persistent ownership.")
    for _, skin in ipairs(Config.Shop.Skins) do
        local owned = skinOwned(skin.Key)
        local frame = card(skin.DisplayName, skin.Description)
        frame.LayoutOrder = 10
        local cost = text(frame, skin.Cost == 0 and "FREE" or ("◈ %d"):format(skin.Cost), 9, owned and Config.UI.Good or Config.UI.Warning, true)
        cost.Size = UDim2.new(1, -24, 0, 18)
        cost.Position = UDim2.fromOffset(12, 70)
        button(frame, skin.Key == (player:GetAttribute("EquippedSkin") or "Default") and "EQUIPPED" or (owned and "EQUIP" or "UNLOCK"), function()
            if owned then
                shopRemote:FireServer("EquipSkin", skin.Key)
            else
                shopRemote:FireServer("PurchaseSkin", skin.Key)
            end
            task.delay(0.35, renderShop)
        end, UDim2.new(1, -24, 0, 28)).Position = UDim2.fromOffset(12, 98)
    end

    headerCard("COMPANIONS", "Persistent NPC allies.")
    for _, companion in ipairs(Config.Shop.Companions) do
        local count = tonumber(player:GetAttribute("Companion_" .. companion.Key)) or 0
        local frame = card(companion.DisplayName, ("%d DMG  •  %d HP  •  %d SPD"):format(companion.Damage, companion.Health, companion.Speed))
        frame.LayoutOrder = 30
        local countText = text(frame, ("%d / 2  •  ◈ %d"):format(count, companion.Cost), 9, count >= 2 and Config.UI.Good or Config.UI.Warning, true)
        countText.Size = UDim2.new(1, -24, 0, 18)
        countText.Position = UDim2.fromOffset(12, 70)
        button(frame, count >= 2 and "MAXED" or "UNLOCK", function()
            shopRemote:FireServer("PurchaseCompanion", companion.Key)
            task.delay(0.35, renderShop)
        end, UDim2.new(1, -24, 0, 28)).Position = UDim2.fromOffset(12, 98)
    end

    headerCard("PASSES", "Permanent Roblox passes.")
    for _, pass in ipairs(Config.GamePasses) do
        local frame = card(pass.Name, pass.Description)
        frame.LayoutOrder = 50
        local price = text(frame, pass.Price > 0 and ("%d R$"):format(pass.Price) or "CONFIGURE ID", 9, Config.UI.Info, true)
        price.Size = UDim2.new(1, -24, 0, 18)
        price.Position = UDim2.fromOffset(12, 70)
        button(frame, player:GetAttribute("Pass_" .. pass.Key) == true and "OWNED" or "PURCHASE", function()
            if player:GetAttribute("Pass_" .. pass.Key) ~= true then
                shopRemote:FireServer("PromptPass", pass.Key)
            end
        end, UDim2.new(1, -24, 0, 28)).Position = UDim2.fromOffset(12, 98)
    end

    headerCard("ROBUX", "Developer products use Roblox's purchase prompt and server receipt processing.")
    for _, product in ipairs(Config.Shop.DeveloperProducts) do
        local frame = card(product.Name, product.Description)
        frame.LayoutOrder = 80
        local price = text(frame, product.Price > 0 and ("%d R$"):format(product.Price) or "CONFIGURE ID", 9, Config.UI.Info, true)
        price.Size = UDim2.new(1, -24, 0, 18)
        price.Position = UDim2.fromOffset(12, 70)
        button(frame, "BUY", function()
            if tonumber(product.Id) and product.Id > 0 then
                pcall(function()
                    MarketplaceService:PromptProductPurchase(player, product.Id)
                end)
            end
        end, UDim2.new(1, -24, 0, 28)).Position = UDim2.fromOffset(12, 98)
    end
end

local function renderMap()
    clearContent()
    headerCard("MAP", "Choose the active combat zone.")
    local frame = card("PVE BATTLELINE", "Main city, waves, enemy encounters and progression.")
    frame.LayoutOrder = 1
    button(frame, "ENTER PVE", function() travelRemote:FireServer("PvE") end, UDim2.new(1, -24, 0, 34)).Position = UDim2.fromOffset(12, 70)
    local pvp = card("PVP ARENA", "Separate combat space for player versus player.")
    pvp.LayoutOrder = 2
    button(pvp, "ENTER PVP", function() travelRemote:FireServer("PvP") end, UDim2.new(1, -24, 0, 34)).Position = UDim2.fromOffset(12, 70)
    local zone = text(content, "CURRENT ZONE: " .. tostring(player:GetAttribute("Zone") or "PvE"), 11, Config.UI.Text, true)
    zone.Size = UDim2.new(1, 0, 0, 24)
    zone.LayoutOrder = 3
end

local function renderProfile()
    clearContent()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    headerCard("PROFILE", player.DisplayName .. "  •  @" .. player.Name)
    local vitals = card("COMBAT PROFILE", ("HP %d / %d"):format(math.floor(humanoid and humanoid.Health or 0), math.floor(humanoid and humanoid.MaxHealth or 100)))
    vitals.LayoutOrder = 1
    local stat = text(vitals, ("DMG %d   DEF %d   SPD %d"):format(
        tonumber(player:GetAttribute("DamageLevel")) or 0,
        tonumber(player:GetAttribute("DefenseLevel")) or 0,
        tonumber(player:GetAttribute("SpeedLevel")) or 0
    ), 9, Config.UI.Muted, false)
    stat.Size = UDim2.new(1, -24, 0, 20)
    stat.Position = UDim2.fromOffset(12, 70)

    local skin = card("LOADOUT", "Current cosmetic state")
    skin.LayoutOrder = 2
    local equipped = text(skin, tostring(player:GetAttribute("EquippedSkin") or "Default"), 12, Config.UI.Accent, true)
    equipped.Size = UDim2.new(1, -24, 0, 24)
    equipped.Position = UDim2.fromOffset(12, 70)

    local economy = card("ECONOMY", "Persistent progression")
    economy.LayoutOrder = 3
    local economyText = text(economy, ("CREDITS %d  •  MONEY x%d  •  DAMAGE x%d  •  SPEED x%d"):format(
        tonumber(player:GetAttribute("Credits")) or 0,
        tonumber(player:GetAttribute("MoneyMultiplier")) or 1,
        tonumber(player:GetAttribute("DamageMultiplier")) or 1,
        tonumber(player:GetAttribute("SpeedMultiplier")) or 1
    ), 8, Config.UI.Muted, false)
    economyText.Size = UDim2.new(1, -24, 0, 34)
    economyText.Position = UDim2.fromOffset(12, 66)
end

local function renderObjectives()
    clearContent()
    headerCard("OBJECTIVES", "Live progression surface for the current server.")
    local wave = tonumber(workspace:GetAttribute("CollisionWave")) or 0
    local enemies = tonumber(workspace:GetAttribute("CollisionEnemies")) or 0
    local active = card("CURRENT WAVE", ("WAVE %02d  •  %d HOSTILES"):format(wave, enemies))
    active.LayoutOrder = 1
    local zone = card("ZONE", tostring(player:GetAttribute("Zone") or "PvE"))
    zone.LayoutOrder = 2
    local combat = card("COMBAT LOOP", "Attack → reposition → dash → finish targets → survive the next wave.")
    combat.LayoutOrder = 3
    local credits = card("REWARD LOOP", "Defeated enemies award Credits. Use them in Shop for progression.")
    credits.LayoutOrder = 4
end

local function renderPlayers()
    clearContent()
    headerCard("PLAYERS", "Live players in this server.")
    local list = Players:GetPlayers()
    table.sort(list, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
    for index, target in ipairs(list) do
        local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        local frame = card(target.DisplayName, "@" .. target.Name .. "  •  " .. tostring(target:GetAttribute("Zone") or "PvE"))
        frame.LayoutOrder = index
        local hp = text(frame, ("HP %d / %d"):format(math.floor(hum and hum.Health or 0), math.floor(hum and hum.MaxHealth or 100)), 9, Config.UI.Good, true)
        hp.Size = UDim2.new(1, -24, 0, 20)
        hp.Position = UDim2.fromOffset(12, 70)
    end
end

local function renderSettings()
    clearContent()
    headerCard("SETTINGS", "Local presentation options.")
    local shake = player:GetAttribute("CameraShakeEnabled") ~= false
    local fov = player:GetAttribute("CameraFOVEnabled") ~= false
    local reduced = player:GetAttribute("ReducedVFX") == true

    local shakeCard = card("CAMERA SHAKE", shake and "ENABLED" or "DISABLED")
    shakeCard.LayoutOrder = 1
    button(shakeCard, shake and "DISABLE" or "ENABLE", function()
        player:SetAttribute("CameraShakeEnabled", not shake)
        renderSettings()
    end, UDim2.new(1, -24, 0, 34)).Position = UDim2.fromOffset(12, 70)

    local fovCard = card("COMBAT FOV", fov and "PULSE ON ATTACK AND DASH" or "STATIC")
    fovCard.LayoutOrder = 2
    button(fovCard, fov and "DISABLE" or "ENABLE", function()
        player:SetAttribute("CameraFOVEnabled", not fov)
        renderSettings()
    end, UDim2.new(1, -24, 0, 34)).Position = UDim2.fromOffset(12, 70)

    local fxCard = card("REDUCED VFX", reduced and "LOWER LOCAL FX LOAD" or "FULL FX")
    fxCard.LayoutOrder = 3
    button(fxCard, reduced and "DISABLE" or "ENABLE", function()
        player:SetAttribute("ReducedVFX", not reduced)
        renderSettings()
    end, UDim2.new(1, -24, 0, 34)).Position = UDim2.fromOffset(12, 70)

    local shopCard = card("ROBLOX SHOP", "Open Roblox's native in-experience shop surface.")
    shopCard.LayoutOrder = 4
    button(shopCard, "OPEN ROBLOX SHOP", function()
        pcall(function()
            MarketplaceService:OpenShop(player)
        end)
    end, UDim2.new(1, -24, 0, 34)).Position = UDim2.fromOffset(12, 70)
end

local function renderAdmin()
    clearContent()
    headerCard("OWNER CONSOLE", "Server moderation and live operations. Owner-only.")
    local targetCard = card("TARGET", "Select a player from the buttons below.")
    targetCard.LayoutOrder = 1
    targetCard.Size = UDim2.fromOffset(210, 132)
    for index, target in ipairs(Players:GetPlayers()) do
        local b = button(targetCard, target.DisplayName, function()
            adminTargetId = target.UserId
            renderAdmin()
        end, UDim2.new(1, -24, 0, 26))
        b.Position = UDim2.fromOffset(12 + ((index - 1) % 2) * 96, 44 + math.floor((index - 1) / 2) * 29)
        if adminTargetId == target.UserId then
            b.BackgroundColor3 = Config.UI.Accent
        end
    end

    local selected = Players:GetPlayerByUserId(adminTargetId or 0)
    local actionCard = card("MODERATION", selected and ("Selected: " .. selected.DisplayName) or "No target selected.")
    actionCard.LayoutOrder = 2
    local actions = {
        {"Heal", "HEAL"},
        {"Kill", "KILL"},
        {"Respawn", "RESPAWN"},
        {"Bring", "BRING"},
        {"Goto", "GOTO"},
        {"Freeze", "FREEZE"},
        {"Unfreeze", "UNFREEZE"},
        {"God", "GOD"},
        {"Normal", "NORMAL"},
        {"ZonePvE", "PVE"},
        {"ZonePvP", "PVP"},
        {"MaxStats", "MAX STATS"},
    }
    for index, item in ipairs(actions) do
        local b = button(actionCard, item[2], function()
            if adminTargetId then
                adminRemote:FireServer(item[1], adminTargetId)
            end
        end, UDim2.fromOffset(88, 28))
        b.Position = UDim2.fromOffset(12 + ((index - 1) % 2) * 96, 70 + math.floor((index - 1) / 2) * 33)
    end

    local values = card("VALUES", "Set a numeric value before using a value action.")
    values.LayoutOrder = 3
    values.Size = UDim2.fromOffset(210, 132)
    local value = valueBox(values, "amount / wave / gravity")
    value.Position = UDim2.fromOffset(12, 44)
    button(values, "+ CREDITS", function()
        if adminTargetId then adminRemote:FireServer("Credits", adminTargetId, value.Text) end
    end, UDim2.new(1, -24, 0, 27)).Position = UDim2.fromOffset(12, 84)
    button(values, "SET CREDITS", function()
        if adminTargetId then adminRemote:FireServer("SetCredits", adminTargetId, value.Text) end
    end, UDim2.new(1, -24, 0, 27)).Position = UDim2.fromOffset(12, 114)

    local waves = card("SERVER", "Wave and server controls.")
    waves.LayoutOrder = 4
    waves.Size = UDim2.fromOffset(210, 132)
    local serverActions = {
        {"NextWave", "NEXT WAVE"},
        {"RestartWave", "RESTART WAVE"},
        {"ClearEnemies", "CLEAR ENEMIES"},
        {"SpawnEnemy", "SPAWN T1-3"},
        {"SpawnElite", "SPAWN ELITE"},
        {"TimeDay", "DAY"},
        {"TimeNight", "NIGHT"},
        {"Status", "STATUS"},
        {"Logs", "LOGS"},
        {"Lock", "LOCK"},
        {"Unlock", "UNLOCK"},
        {"Shutdown", "SHUTDOWN"},
    }
    for index, item in ipairs(serverActions) do
        local b = button(waves, item[2], function()
            adminRemote:FireServer(item[1], nil, value.Text)
        end, UDim2.fromOffset(88, 28))
        b.Position = UDim2.fromOffset(12 + ((index - 1) % 2) * 96, 44 + math.floor((index - 1) / 2) * 30)
    end

    local moderation = card("BAN", "Ban target with the reason below.")
    moderation.LayoutOrder = 5
    moderation.Size = UDim2.fromOffset(210, 132)
    local reason = valueBox(moderation, "reason")
    reason.Position = UDim2.fromOffset(12, 44)
    for index, duration in ipairs({{"1H", "BAN 1H"}, {"1D", "BAN 1D"}, {"7D", "BAN 7D"}, {"FOREVER", "BAN FOREVER"}}) do
        local b = button(moderation, duration[2], function()
            if adminTargetId then adminRemote:FireServer("Ban", adminTargetId, duration[1], reason.Text) end
        end, UDim2.fromOffset(88, 27))
        b.Position = UDim2.fromOffset(12 + ((index - 1) % 2) * 96, 84 + math.floor((index - 1) / 2) * 30)
    end

    local comms = card("ANNOUNCEMENT", "Public owner message.")
    comms.LayoutOrder = 6
    comms.Size = UDim2.fromOffset(210, 132)
    local messageBox = valueBox(comms, "announcement text")
    messageBox.Position = UDim2.fromOffset(12, 44)
    button(comms, "BROADCAST", function()
        adminRemote:FireServer("Announcement", nil, nil, messageBox.Text)
    end, UDim2.new(1, -24, 0, 32)).Position = UDim2.fromOffset(12, 84)
end

local tabDefs = {
    {Name = "Shop", Label = "SHOP"},
    {Name = "Map", Label = "MAP"},
    {Name = "Objectives", Label = "OBJECTIVES"},
    {Name = "Profile", Label = "PROFILE"},
    {Name = "Players", Label = "PLAYERS"},
    {Name = "Settings", Label = "SETTINGS"},
}

local renderers = {
    Shop = renderShop,
    Map = renderMap,
    Objectives = renderObjectives,
    Profile = renderProfile,
    Players = renderPlayers,
    Settings = renderSettings,
    Admin = renderAdmin,
}

local function setTab(name: string)
    activeTab = name
    grid.CellSize = name == "Admin" and UDim2.fromOffset(210, 320) or UDim2.fromOffset(210, 132)
    for _, child in ipairs(sidebar:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = child:GetAttribute("TabName") == name and Config.UI.Accent or Config.UI.Background
        end
    end
    local renderer = renderers[name]
    if renderer then renderer() end
end

local function rebuildTabs()
    for _, child in ipairs(sidebar:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, data in ipairs(tabDefs) do
        local b = button(sidebar, data.Label, function()
            setTab(data.Name)
        end, UDim2.new(1, 0, 0, 34))
        b:SetAttribute("TabName", data.Name)
        b.BackgroundColor3 = data.Name == activeTab and Config.UI.Accent or Config.UI.Background
        b.LayoutOrder = #sidebar:GetChildren()
    end
    if player:GetAttribute("IsOwner") == true then
        local b = button(sidebar, "ADMIN", function()
            setTab("Admin")
        end, UDim2.new(1, 0, 0, 34))
        b:SetAttribute("TabName", "Admin")
        b.BackgroundColor3 = activeTab == "Admin" and Config.UI.Warning or Config.UI.Background
        b.LayoutOrder = 80
        adminTabButton = b
    else
        adminTabButton = nil
        if activeTab == "Admin" then
            activeTab = "Shop"
        end
    end
end

openButton.Activated:Connect(openMenu)
closeButton.Activated:Connect(closeMenu)
overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        closeMenu()
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M and not UserInputService:GetFocusedTextBox() then
        if menuOpen then closeMenu() else openMenu() end
    elseif input.KeyCode == Enum.KeyCode.ButtonStart then
        if menuOpen then closeMenu() else openMenu() end
    end
end)

for _, attribute in ipairs({"Credits", "DamageLevel", "DefenseLevel", "SpeedLevel", "EquippedSkin", "Zone", "IsOwner"}) do
    player:GetAttributeChangedSignal(attribute):Connect(function()
        updateBalance()
        if menuOpen then
            rebuildTabs()
            local renderer = renderers[activeTab]
            if renderer then renderer() end
        end
    end)
end

Players.PlayerAdded:Connect(function()
    if menuOpen and activeTab == "Players" then renderPlayers() end
    if menuOpen and activeTab == "Admin" then renderAdmin() end
end)

Players.PlayerRemoving:Connect(function(target)
    if adminTargetId == target.UserId then adminTargetId = nil end
    if menuOpen and activeTab == "Players" then renderPlayers() end
    if menuOpen and activeTab == "Admin" then renderAdmin() end
end)

stateRemote.OnClientEvent:Connect(function(kind: string)
    if kind == "ShopMessage" or kind == "AdminMessage" or kind == "ProductGranted" then
        updateBalance()
        if menuOpen and activeTab == "Shop" then
            task.delay(0.2, renderShop)
        end
    end
end)

rebuildTabs()
updateBalance()
setTab(activeTab)
