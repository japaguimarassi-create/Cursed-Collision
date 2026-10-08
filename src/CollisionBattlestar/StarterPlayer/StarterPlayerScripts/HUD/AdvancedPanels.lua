--!strict

local AdvancedPanels = {}
AdvancedPanels.__index = AdvancedPanels

local function corner(instance: GuiObject, radius: number)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, radius)
    value.Parent = instance
end

local function stroke(instance: GuiObject)
    local value = Instance.new("UIStroke")
    value.Color = Color3.fromRGB(125, 130, 150)
    value.Transparency = 0.5
    value.Thickness = 1
    value.Parent = instance
end

local function button(parent: Instance, name: string, title: string, size: UDim2)
    local item = Instance.new("TextButton")
    item.Name = name
    item.Text = title
    item.Size = size
    item.BackgroundColor3 = Color3.fromRGB(32, 37, 49)
    item.BorderSizePixel = 0
    item.TextColor3 = Color3.fromRGB(240, 242, 248)
    item.Font = Enum.Font.GothamBold
    item.TextSize = 12
    item.AutoButtonColor = true
    item.Parent = parent
    corner(item, 10)
    stroke(item)
    return item
end

local function label(parent: Instance, name: string, title: string, size: UDim2)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Text = title
    item.Size = size
    item.BackgroundTransparency = 1
    item.TextColor3 = Color3.fromRGB(235, 238, 246)
    item.Font = Enum.Font.Gotham
    item.TextSize = 14
    item.TextWrapped = true
    item.Parent = parent
    return item
end

function AdvancedPanels.new(hud, remotes, socialInvite)
    local self = setmetatable({
        hud = hud,
        remotes = remotes,
        socialInvite = socialInvite,
        shopOpen = false,
        companionOpen = false,
        missionOpen = false,
        pvpOpen = false,
        adminOpen = false,
        selectedFriend = nil,
        selectedClass = "Vanguard",
        friendRows = {},
        itemRows = {},
        missionRows = {},
        adminButtons = {},
        connections = {},
    }, AdvancedPanels)

    local root = hud.root

    local utilityBar = Instance.new("ScrollingFrame")
    utilityBar.Name = "UtilityBar"
    utilityBar.Size = UDim2.fromOffset(372, 46)
    utilityBar.Position = UDim2.new(0, 10, 1, -122)
    utilityBar.BackgroundTransparency = 1
    utilityBar.BorderSizePixel = 0
    utilityBar.ScrollBarThickness = 0
    utilityBar.ScrollingDirection = Enum.ScrollingDirection.X
    utilityBar.CanvasSize = UDim2.fromOffset(0, 0)
    utilityBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    utilityBar.Parent = root

    local utilityLayout = Instance.new("UIListLayout")
    utilityLayout.FillDirection = Enum.FillDirection.Horizontal
    utilityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    utilityLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    utilityLayout.Padding = UDim.new(0, 4)
    utilityLayout.Parent = utilityBar

    self.shopButton = button(utilityBar, "ShopButton", "SHOP", UDim2.fromOffset(60, 44))
    self.companionButton = button(utilityBar, "CompanionButton", "ECHO", UDim2.fromOffset(60, 44))
    self.missionButton = button(utilityBar, "MissionButton", "MISSIONS", UDim2.fromOffset(72, 44))
    self.pvpButton = button(utilityBar, "PvPButton", "PVP", UDim2.fromOffset(52, 44))
    self.inviteButton = button(utilityBar, "InviteButton", "INVITE", UDim2.fromOffset(60, 44))

    self.missionPanel = self:BuildMissionPanel(root)
    self.shopPanel = self:BuildShopPanel(root)
    self.companionPanel = self:BuildCompanionPanel(root)
    self.pvpPanel = self:BuildPvPPanel(root)

    if game.CreatorType == Enum.CreatorType.User and game.CreatorId > 0 then
        self.adminButton = button(utilityBar, "AdminButton", "ADMIN", UDim2.fromOffset(60, 44))
        self.adminPanel = self:BuildAdminPanel(root)
    end

    self:Bind()
    return self
end

function AdvancedPanels:CreateOverlay(root, name: string, title: string, width: number, height: number)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(width, height)
    width = math.max(280, math.min(width, viewport.X - 20))
    height = math.max(240, math.min(height, viewport.Y - 100))

    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = UDim2.fromOffset(width, height)
    panel.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    panel.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 50
    panel.Parent = root
    corner(panel, 16)
    stroke(panel)

    local titleLabel = label(panel, "Title", title, UDim2.new(1, -80, 0, 42))
    titleLabel.Position = UDim2.fromOffset(16, 10)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.ZIndex = 51

    local close = button(panel, "Close", "X", UDim2.fromOffset(42, 42))
    close.Position = UDim2.new(1, -54, 0, 10)
    close.TextSize = 18
    close.ZIndex = 51

    close.Activated:Connect(function()
        panel.Visible = false
        self:SetPanelOpen(name, false)
    end)

    return panel
end

function AdvancedPanels:SetPanelOpen(name: string, open: boolean)
    if name == "ShopOverlay" then
        self.shopOpen = open
        if not open then
            self.shopPanel.Visible = false
        end
    elseif name == "CompanionOverlay" then
        self.companionOpen = open
        if not open then
            self.companionPanel.Visible = false
        end
    elseif name == "MissionOverlay" then
        self.missionOpen = open
        if not open then
            self.missionPanel.Visible = false
        end
    elseif name == "PvPOverlay" then
        self.pvpOpen = open
        if not open then
            self.pvpPanel.Visible = false
        end
    elseif name == "AdminOverlay" and self.adminPanel then
        self.adminOpen = open
        if not open then
            self.adminPanel.Visible = false
        end
    end
end

function AdvancedPanels:CloseAll(except: string?)
    local panels = {
        {"ShopOverlay", self.shopPanel},
        {"CompanionOverlay", self.companionPanel},
        {"MissionOverlay", self.missionPanel},
        {"PvPOverlay", self.pvpPanel},
        {"AdminOverlay", self.adminPanel},
    }

    for _, data in ipairs(panels) do
        if data[1] ~= except and data[2] then
            data[2].Visible = false
            self:SetPanelOpen(data[1], false)
        end
    end
end

function AdvancedPanels:Open(name: string)
    self:CloseAll(name)

    local panel = ({
        ShopOverlay = self.shopPanel,
        CompanionOverlay = self.companionPanel,
        MissionOverlay = self.missionPanel,
        PvPOverlay = self.pvpPanel,
        AdminOverlay = self.adminPanel,
    })[name]

    if panel then
        panel.Visible = true
        self:SetPanelOpen(name, true)
    end
end

function AdvancedPanels:BuildShopPanel(root: Frame)
    local panel = self:CreateOverlay(root, "ShopOverlay", "FULL SHOP", 560, 440)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Items"
    scroll.Size = UDim2.new(1, -28, 1, -72)
    scroll.Position = UDim2.fromOffset(14, 60)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    self.shopScroll = scroll
    self.shopLayout = layout

    return panel
end

function AdvancedPanels:AddShopItem(entry)
    if type(entry) ~= "table" or type(entry.ItemId) ~= "string" then
        return
    end

    local row = Instance.new("Frame")
    row.Name = "Item_" .. entry.ItemId
    row.Size = UDim2.new(1, -8, 0, 64)
    row.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    row.BorderSizePixel = 0
    row.Parent = self.shopScroll
    corner(row, 10)

    local title = label(row, "Name", entry.DisplayName or entry.ItemId, UDim2.new(0.52, 0, 0, 26))
    title.Position = UDim2.fromOffset(12, 7)
    title.Font = Enum.Font.GothamBold

    local info = label(row, "Info", "", UDim2.new(0.52, 0, 0, 24))
    info.Position = UDim2.fromOffset(12, 34)
    info.TextSize = 12

    local action = button(row, "Action", "BUY", UDim2.fromOffset(112, 42))
    action.Position = UDim2.new(1, -124, 0.5, -21)
    action.TextSize = 13

    local owned = entry.Owned == true
    local price = tonumber(entry.Price) or 0
    local level = tonumber(entry.Level)

    if level then
        info.Text = ("Level %d / %d  •  %s C"):format(
            level,
            tonumber(entry.MaxLevel) or 0,
            price == math.huge and "MAX" or tostring(price)
        )
    else
        info.Text = price == math.huge and "MAX" or (tostring(price) .. " Credits")
    end

    if owned then
        action.Text = "EQUIP"
    end

    action.Activated:Connect(function()
        if owned then
            self.remotes.Commerce:FireServer({
                action = "Equip",
                itemId = entry.ItemId,
            })
        else
            self.remotes.Commerce:FireServer({
                action = "Purchase",
                itemId = entry.ItemId,
            })
        end
    end)

    table.insert(self.itemRows, row)
end

function AdvancedPanels:RefreshShop(catalog)
    for _, row in ipairs(self.itemRows) do
        row:Destroy()
    end
    self.itemRows = {}

    if type(catalog) ~= "table" then
        return
    end

    for _, entry in ipairs(catalog) do
        self:AddShopItem(entry)
    end
end

function AdvancedPanels:BuildCompanionPanel(root: Frame)
    local panel = self:CreateOverlay(root, "CompanionOverlay", "FRIEND ECHO", 560, 440)

    local active = label(panel, "Active", "No Echo active.", UDim2.new(1, -28, 0, 54))
    active.Position = UDim2.fromOffset(14, 58)
    active.TextXAlignment = Enum.TextXAlignment.Left
    active.TextSize = 15
    self.echoStatus = active

    local classBar = Instance.new("Frame")
    classBar.Name = "ClassBar"
    classBar.Size = UDim2.new(1, -28, 0, 44)
    classBar.Position = UDim2.fromOffset(14, 112)
    classBar.BackgroundTransparency = 1
    classBar.Parent = panel

    local classes = {"Vanguard", "Striker", "Guardian", "Support"}
    for index, classId in ipairs(classes) do
        local classButton = button(classBar, classId, classId:upper(), UDim2.new(0.25, -6, 1, 0))
        classButton.Position = UDim2.new((index - 1) * 0.25, index == 1 and 0 or 6, 0, 0)
        classButton.TextSize = 11
        classButton.Activated:Connect(function()
            self.selectedClass = classId
            self:HighlightSelectedClass(classBar)
        end)
        if index == 1 then
            classButton.BackgroundColor3 = Color3.fromRGB(70, 75, 100)
        end
    end
    self.classBar = classBar

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Friends"
    scroll.Size = UDim2.new(1, -28, 1, -170)
    scroll.Position = UDim2.fromOffset(14, 164)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = scroll

    self.friendScroll = scroll

    local refresh = button(panel, "RefreshFriends", "REFRESH", UDim2.fromOffset(96, 42))
    refresh.Position = UDim2.new(1, -110, 0, 58)
    refresh.Activated:Connect(function()
        self.remotes.Companion:FireServer({
            action = "ListFriends",
        })
    end)

    local unsummon = button(panel, "Unsummon", "UNSUMMON", UDim2.fromOffset(96, 42))
    unsummon.Position = UDim2.fromOffset(14, 58)
    unsummon.Activated:Connect(function()
        self.remotes.Companion:FireServer({
            action = "Unsummon",
        })
    end)

    return panel
end

function AdvancedPanels:HighlightSelectedClass(classBar)
    for _, child in ipairs(classBar:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = child.Name == self.selectedClass
                and Color3.fromRGB(70, 75, 100)
                or Color3.fromRGB(32, 37, 49)
        end
    end
end

function AdvancedPanels:AddFriend(friend)
    if type(friend) ~= "table" or type(friend.Id) ~= "number" then
        return
    end

    local row = Instance.new("Frame")
    row.Name = "Friend_" .. tostring(friend.Id)
    row.Size = UDim2.new(1, -8, 0, 58)
    row.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    row.BorderSizePixel = 0
    row.Parent = self.friendScroll
    corner(row, 10)

    local name = label(row, "Name", friend.DisplayName ~= "" and friend.DisplayName or friend.Username, UDim2.new(0.55, 0, 1, 0))
    name.Position = UDim2.fromOffset(12, 0)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 14

    local summon = button(row, "Summon", "SUMMON", UDim2.fromOffset(110, 40))
    summon.Position = UDim2.new(1, -122, 0.5, -20)
    summon.TextSize = 12
    summon.Activated:Connect(function()
        self.selectedFriend = friend.Id
        self.remotes.Companion:FireServer({
            action = "Summon",
            friendUserId = friend.Id,
            classId = self.selectedClass,
        })
    end)

    table.insert(self.friendRows, row)
end

function AdvancedPanels:RefreshFriends(friends)
    for _, row in ipairs(self.friendRows) do
        row:Destroy()
    end
    self.friendRows = {}

    if type(friends) ~= "table" then
        return
    end

    for _, friend in ipairs(friends) do
        self:AddFriend(friend)
    end
end

function AdvancedPanels:BuildMissionPanel(root: Frame)
    local panel = self:CreateOverlay(root, "MissionOverlay", "MISSIONS", 520, 360)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "List"
    scroll.Size = UDim2.new(1, -28, 1, -72)
    scroll.Position = UDim2.fromOffset(14, 60)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    self.missionScroll = scroll
    return panel
end

function AdvancedPanels:AddMission(entry)
    if type(entry) ~= "table" or type(entry.Id) ~= "string" then
        return
    end

    local row = Instance.new("Frame")
    row.Name = entry.Id
    row.Size = UDim2.new(1, -8, 0, 72)
    row.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    row.BorderSizePixel = 0
    row.Parent = self.missionScroll
    corner(row, 10)

    local title = label(row, "Title", entry.DisplayName or entry.Id, UDim2.new(0.58, 0, 0, 26))
    title.Position = UDim2.fromOffset(12, 8)
    title.Font = Enum.Font.GothamBold

    local current = tonumber(entry.Progress) or 0
    local goal = tonumber(entry.Goal) or 0
    local reward = tonumber(entry.Reward) or 0

    local progress = label(row, "Progress", entry.Completed and "COMPLETE" or ("%d / %d  •  Reward %d"):format(current, goal, reward), UDim2.new(0.58, 0, 0, 28))
    progress.Position = UDim2.fromOffset(12, 36)
    progress.TextSize = 12

    local status = label(row, "Status", entry.Completed and "DONE" or "ACTIVE", UDim2.fromOffset(100, 28))
    status.Position = UDim2.new(1, -112, 0.5, -14)
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12

    table.insert(self.missionRows, row)
end

function AdvancedPanels:RefreshMissions(snapshot)
    for _, row in ipairs(self.missionRows) do
        row:Destroy()
    end
    self.missionRows = {}

    if type(snapshot) ~= "table" then
        return
    end

    for _, entry in pairs(snapshot) do
        self:AddMission(entry)
    end
end

function AdvancedPanels:BuildPvPPanel(root: Frame)
    local panel = self:CreateOverlay(root, "PvPOverlay", "PVP ARENA", 380, 250)

    local description = label(
        panel,
        "Description",
        "Enter the distant battleground. PvE enemies will not follow you there.",
        UDim2.new(1, -28, 0, 62)
    )
    description.Position = UDim2.fromOffset(14, 62)

    self.pvpStatus = label(panel, "Status", "STATUS: PvE", UDim2.new(1, -28, 0, 28))
    self.pvpStatus.Position = UDim2.fromOffset(14, 124)
    self.pvpStatus.TextXAlignment = Enum.TextXAlignment.Center
    self.pvpStatus.Font = Enum.Font.GothamBold

    self.pvpJoin = button(panel, "Join", "ENTER PVP", UDim2.fromOffset(150, 50))
    self.pvpJoin.Position = UDim2.fromOffset(16, 166)

    self.pvpLeave = button(panel, "Leave", "RETURN", UDim2.fromOffset(150, 50))
    self.pvpLeave.Position = UDim2.new(1, -166, 0, 166)

    return panel
end

function AdvancedPanels:BuildAdminPanel(root: Frame)
    local panel = self:CreateOverlay(root, "AdminOverlay", "TEST LAB", 420, 360)

    local actions = {
        {"FullHeal", "FULL HEAL"},
        {"AddCredits", "+1000 CREDITS"},
        {"SpawnElite", "SPAWN ELITE"},
        {"ClearArena", "CLEAR ARENA"},
        {"NextWave", "NEXT WAVE"},
        {"ReturnToArena", "RETURN TO ARENA"},
    }

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Actions"
    scroll.Size = UDim2.new(1, -28, 1, -68)
    scroll.Position = UDim2.fromOffset(14, 58)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    for _, action in ipairs(actions) do
        local actionButton = button(scroll, action[1], action[2], UDim2.new(1, -8, 0, 48))
        actionButton.TextSize = 13
        actionButton.Activated:Connect(function()
            self.remotes.Admin:FireServer({
                action = action[1],
            })
        end)
        table.insert(self.adminButtons, actionButton)
    end

    return panel
end

function AdvancedPanels:Bind()
    table.insert(self.connections, self.shopButton.Activated:Connect(function()
        if self.shopOpen then
            self:CloseAll()
        else
            self:Open("ShopOverlay")
            self.remotes.Commerce:FireServer({action = "Catalog"})
        end
    end))

    table.insert(self.connections, self.companionButton.Activated:Connect(function()
        if self.companionOpen then
            self:CloseAll()
        else
            self:Open("CompanionOverlay")
            self.remotes.Companion:FireServer({action = "ListFriends"})
        end
    end))

    table.insert(self.connections, self.missionButton.Activated:Connect(function()
        if self.missionOpen then
            self:CloseAll()
        else
            self:Open("MissionOverlay")
            self.remotes.Mission:FireServer({action = "Snapshot"})
        end
    end))

    table.insert(self.connections, self.pvpButton.Activated:Connect(function()
        if self.pvpOpen then
            self:CloseAll()
        else
            self:Open("PvPOverlay")
            self.remotes.PvP:FireServer({action = "State"})
        end
    end))

    table.insert(self.connections, self.inviteButton.Activated:Connect(function()
        self.socialInvite:Prompt()
    end))

    if self.adminButton then
        table.insert(self.connections, self.adminButton.Activated:Connect(function()
            if self.adminOpen then
                self:CloseAll()
            else
                self:Open("AdminOverlay")
            end
        end))
    end

    self.pvpJoin.Activated:Connect(function()
        self.remotes.PvP:FireServer({action = "Join"})
    end)

    self.pvpLeave.Activated:Connect(function()
        self.remotes.PvP:FireServer({action = "Leave"})
    end)

    table.insert(self.connections, self.remotes.Commerce.OnClientEvent:Connect(function(kind, payload)
        if kind == "Catalog" then
            self:RefreshShop(payload)
        elseif kind == "PurchaseResult" or kind == "EquipResult" then
            self.remotes.Commerce:FireServer({action = "Catalog"})
        end
    end))

    table.insert(self.connections, self.remotes.Companion.OnClientEvent:Connect(function(kind, payload)
        if type(payload) ~= "table" then
            return
        end

        if kind == "Friends" then
            self:RefreshFriends(payload.friends)
        elseif kind == "SummonResult" or kind == "UnsummonResult" then
            local snapshot = payload.snapshot
            if snapshot and snapshot.active then
                self.echoStatus.Text = ("Echo: %s\nState: %s  •  Level %d  •  Bond %d"):format(
                    snapshot.classId,
                    snapshot.state,
                    snapshot.level,
                    snapshot.bond
                )
            else
                self.echoStatus.Text = "No Echo active."
            end
        end
    end))

    table.insert(self.connections, self.remotes.Mission.OnClientEvent:Connect(function(kind, payload)
        if kind == "Snapshot" then
            self:RefreshMissions(payload)
        elseif kind == "Completed" and type(payload) == "table" then
            self:RefreshMissions(payload.snapshot or {})
        end
    end))

    table.insert(self.connections, self.remotes.PvP.OnClientEvent:Connect(function(kind, payload)
        if kind ~= "Result" or type(payload) ~= "table" then
            return
        end

        local active = payload.active == true
        self.pvpStatus.Text = active and "STATUS: PVP" or "STATUS: PVE"
        self.pvpJoin.Active = not active
        self.pvpLeave.Active = active
    end))

    if self.adminButton then
        table.insert(self.connections, self.remotes.Admin.OnClientEvent:Connect(function(kind, payload)
            if kind == "Result" and type(payload) == "table" then
                self:CloseAll()
            end
        end))
    end
end

function AdvancedPanels:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    local panels = {
        self.shopPanel,
        self.companionPanel,
        self.missionPanel,
        self.pvpPanel,
        self.adminPanel,
    }

    for _, panel in ipairs(panels) do
        if panel then
            panel:Destroy()
        end
    end
end

return AdvancedPanels
