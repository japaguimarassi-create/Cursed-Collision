--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
    item.TextSize = 15
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
        selectedFriend = nil,
        selectedClass = "Vanguard",
        friendRows = {},
        itemRows = {},
        connections = {},
    }, AdvancedPanels)

    local root = hud.root

    self.shopButton = button(root, "ShopButton", "SHOP", UDim2.fromOffset(112, 54))
    self.shopButton.Position = UDim2.new(0, 146, 1, -70)

    self.companionButton = button(root, "CompanionButton", "ECHO", UDim2.fromOffset(112, 54))
    self.companionButton.Position = UDim2.new(0, 266, 1, -70)

    self.inviteButton = button(root, "InviteButton", "INVITE", UDim2.fromOffset(112, 54))
    self.inviteButton.Position = UDim2.new(0, 386, 1, -70)

    self.shopPanel = self:BuildShopPanel(root)
    self.companionPanel = self:BuildCompanionPanel(root)

    self:Bind()
    return self
end

function AdvancedPanels:CreateOverlay(root, name: string, title: string, width: number, height: number)
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = UDim2.fromOffset(width, height)
    panel.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    panel.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = root
    corner(panel, 16)
    stroke(panel)

    local titleLabel = label(panel, "Title", title, UDim2.new(1, -80, 0, 42))
    titleLabel.Position = UDim2.fromOffset(16, 10)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20

    local close = button(panel, "Close", "X", UDim2.fromOffset(42, 42))
    close.Position = UDim2.new(1, -54, 0, 10)
    close.TextSize = 18

    close.Activated:Connect(function()
        panel.Visible = false
        if name == "ShopOverlay" then
            self.shopOpen = false
        else
            self.companionOpen = false
        end
    end)

    return panel
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
    scroll.CanvasSize = UDim2.new()
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
    local row = Instance.new("Frame")
    row.Name = "Item_" .. tostring(entry.ItemId)
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

    local refresh = button(panel, "RefreshFriends", "REFRESH", UDim2.fromOffset(110, 42))
    refresh.Position = UDim2.new(1, -124, 0, 58)
    refresh.Activated:Connect(function()
        self.remotes.Companion:FireServer({
            action = "ListFriends",
        })
    end)

    local unsummon = button(panel, "Unsummon", "UNSUMMON", UDim2.fromOffset(110, 42))
    unsummon.Position = UDim2.new(0, 14, 0, 58)
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

function AdvancedPanels:Bind()
    table.insert(self.connections, self.shopButton.Activated:Connect(function()
        self.shopOpen = not self.shopOpen
        self.companionOpen = false
        self.shopPanel.Visible = self.shopOpen
        self.companionPanel.Visible = false
        if self.shopOpen then
            self.remotes.Commerce:FireServer({action = "Catalog"})
        end
    end))

    table.insert(self.connections, self.companionButton.Activated:Connect(function()
        self.companionOpen = not self.companionOpen
        self.shopOpen = false
        self.companionPanel.Visible = self.companionOpen
        self.shopPanel.Visible = false
        if self.companionOpen then
            self.remotes.Companion:FireServer({action = "ListFriends"})
        end
    end))

    table.insert(self.connections, self.inviteButton.Activated:Connect(function()
        self.socialInvite:Prompt()
    end))

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
                self.echoStatus.Text = ("Echo: %s
State: %s  •  Level %d  •  Bond %d"):format(
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
end

function AdvancedPanels:Destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.shopPanel:Destroy()
    self.companionPanel:Destroy()
end

return AdvancedPanels
