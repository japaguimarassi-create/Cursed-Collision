--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LayoutRules = require(Shared:WaitForChild("HUDLayoutRules"))
local Components = require(script.Parent:WaitForChild("Components"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local Root = {}
Root.__index = Root

local WHITE = Theme.Colors.White

local function formatInteger(value: number): string
    return tostring(math.max(0, math.floor(value + 0.5)))
end

local function setBar(fill: Frame, ratio: number)
    fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
end

local function setTextColor(label: TextLabel, ratio: number)
    if ratio <= 0.3 then
        label.TextColor3 = Theme.Colors.Red
    elseif ratio <= 0.6 then
        label.TextColor3 = Theme.Colors.Yellow
    else
        label.TextColor3 = Theme.Colors.Green
    end
end

local function addButtonState(button: TextButton)
    local normal = button.BackgroundColor3
    local hover = normal:Lerp(WHITE, 0.12)

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hover
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normal
    end)
end

function Root.Create(player: Player)
    local self = setmetatable({}, Root)
    self.Player = player
    self.Touch = UserInputService.TouchEnabled
    self.Connections = {}
    self.ActionCallbacks = {
        Attack = function() end,
        Dash = function() end,
        Shop = nil,
        Companion = nil,
    }
    self.DashToken = 0
    self.ToastToken = 0
    self.ComboToken = 0

    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 20
    gui.Parent = playerGui
    self.Gui = gui

    local rootFrame = Instance.new("Frame")
    rootFrame.Name = "Root"
    rootFrame.Size = UDim2.fromScale(1, 1)
    rootFrame.BackgroundTransparency = 1
    rootFrame.BorderSizePixel = 0
    rootFrame.Parent = gui
    self.RootFrame = rootFrame

    self:_buildPlayerStatus()
    self:_buildWaveStatus()
    self:_buildEliteBanner()
    self:_buildNavigation()
    self:_buildMenuPanel()
    self:_buildCombatControls()
    self:_buildToast()
    self:_bindCharacter()
    self:_bindReplicatedState()
    self:_applyResponsiveLayout()

    local camera = Workspace.CurrentCamera
    if camera then
        table.insert(self.Connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self:_applyResponsiveLayout()
        end))
    end

    table.insert(self.Connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local nextCamera = Workspace.CurrentCamera
        if nextCamera then
            table.insert(self.Connections, nextCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                self:_applyResponsiveLayout()
            end))
            self:_applyResponsiveLayout()
        end
    end))

    return self
end

function Root:_buildPlayerStatus()
    local panel = Components.Panel(
        self.RootFrame,
        "PlayerStatus",
        UDim2.fromOffset(320, 96),
        UDim2.fromOffset(16, 16),
        15
    )
    self.PlayerStatus = panel

    local title = Components.Label(
        panel,
        "Title",
        "PLAYER",
        UDim2.fromOffset(62, 18),
        UDim2.fromOffset(12, 7),
        10,
        Theme.Colors.Muted,
        true
    )

    self.HealthValue = Components.Label(
        panel,
        "HealthValue",
        "100 / 100",
        UDim2.fromOffset(104, 24),
        UDim2.fromOffset(12, 23),
        17,
        Theme.Colors.Green,
        true
    )

    self.CreditsValue = Components.Label(
        panel,
        "CreditsValue",
        "0",
        UDim2.fromOffset(120, 24),
        UDim2.fromOffset(183, 23),
        17,
        Theme.Colors.Gold,
        true
    )

    local creditsTitle = Components.Label(
        panel,
        "CreditsTitle",
        "CREDITS",
        UDim2.fromOffset(92, 18),
        UDim2.fromOffset(183, 7),
        10,
        Theme.Colors.Muted,
        true
    )
    self.CreditsTitle = creditsTitle

    local _, fill = Components.ProgressBar(
        panel,
        "HealthBar",
        UDim2.fromOffset(296, 10),
        UDim2.fromOffset(12, 62),
        Theme.Colors.Green
    )
    self.HealthFill = fill

    local level = Components.Label(
        panel,
        "Level",
        "DMG LV 0",
        UDim2.fromOffset(92, 16),
        UDim2.fromOffset(204, 60),
        10,
        Theme.Colors.Cyan,
        true
    )
    level.TextXAlignment = Enum.TextXAlignment.Right
    self.DamageLevel = level

    title.TextXAlignment = Enum.TextXAlignment.Left
    creditsTitle.TextXAlignment = Enum.TextXAlignment.Left
end

function Root:_buildWaveStatus()
    local panel = Components.Panel(
        self.RootFrame,
        "WaveStatus",
        UDim2.fromOffset(292, 72),
        UDim2.new(0.5, -146, 0, 14),
        14
    )
    self.WaveStatus = panel

    local label = Components.Label(
        panel,
        "WaveValue",
        "WAVE 00",
        UDim2.new(0.55, 0, 0, 30),
        UDim2.fromOffset(14, 8),
        22,
        Theme.Colors.Text,
        true
    )
    self.WaveValue = label

    local enemies = Components.Label(
        panel,
        "EnemiesValue",
        "HOSTILES 0",
        UDim2.new(0.45, -14, 0, 22),
        UDim2.new(0.55, 0, 0, 12),
        14,
        Theme.Colors.Muted,
        true
    )
    enemies.TextXAlignment = Enum.TextXAlignment.Right
    self.EnemiesValue = enemies

    local phase = Components.Label(
        panel,
        "Phase",
        "WAITING",
        UDim2.new(1, -28, 0, 16),
        UDim2.fromOffset(14, 47),
        10,
        Theme.Colors.Cyan,
        true
    )
    self.PhaseValue = phase
end

function Root:_buildEliteBanner()
    local banner = Components.Panel(
        self.RootFrame,
        "EliteBanner",
        UDim2.fromOffset(270, 42),
        UDim2.new(0.5, -135, 0, 94),
        11
    )
    banner.BackgroundColor3 = Theme.Colors.RedDark
    banner.Visible = false
    banner.ZIndex = 8
    self.EliteBanner = banner

    local label = Components.Label(
        banner,
        "Value",
        "ELITE TARGET ACTIVE",
        UDim2.new(1, -20, 1, 0),
        UDim2.fromOffset(10, 0),
        13,
        Theme.Colors.Red,
        true
    )
    label.TextXAlignment = Enum.TextXAlignment.Center
    self.EliteLabel = label
end

function Root:_buildNavigation()
    local holder = Instance.new("Frame")
    holder.Name = "Navigation"
    holder.Size = UDim2.fromOffset(252, 48)
    holder.Position = UDim2.new(1, -268, 0, 14)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = self.RootFrame
    self.Navigation = holder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = holder

    local menu = Components.Button(
        holder,
        "Menu",
        "MENU",
        UDim2.fromOffset(82, 44),
        UDim2.fromOffset(0, 0),
        Theme.Colors.PanelSoft,
        12,
        11
    )
    menu.LayoutOrder = 1
    addButtonState(menu)
    menu.Activated:Connect(function()
        self:SetMenuOpen(not self.MenuPanel.Visible)
    end)
    self.MenuButton = menu

    local companion = Components.Button(
        holder,
        "Companion",
        "ECHO",
        UDim2.fromOffset(78, 44),
        UDim2.fromOffset(0, 0),
        Theme.Colors.CyanDark,
        12,
        11
    )
    companion.LayoutOrder = 2
    companion.Activated:Connect(function()
        if self.ActionCallbacks.Companion then
            self.ActionCallbacks.Companion()
        else
            self:Notify("Friend Echo is not connected in this build.")
        end
    end)
    self.CompanionButton = companion

    local shop = Components.Button(
        holder,
        "Shop",
        "SHOP",
        UDim2.fromOffset(78, 44),
        UDim2.fromOffset(0, 0),
        Theme.Colors.PanelSoft,
        12,
        11
    )
    shop.LayoutOrder = 3
    shop.Activated:Connect(function()
        if self.ActionCallbacks.Shop then
            self.ActionCallbacks.Shop()
        else
            self:Notify("Shop service is not connected in this build.")
        end
    end)
    self.ShopButton = shop
end

function Root:_buildMenuPanel()
    local panel = Components.Panel(
        self.RootFrame,
        "MenuPanel",
        UDim2.fromOffset(340, 248),
        UDim2.new(1, -358, 0, 70),
        15
    )
    panel.Visible = false
    panel.ZIndex = 30
    self.MenuPanel = panel

    local title = Components.Label(
        panel,
        "Title",
        "COLLISION BATTLESTAR",
        UDim2.new(1, -28, 0, 26),
        UDim2.fromOffset(14, 12),
        17,
        Theme.Colors.Text,
        true
    )
    title.ZIndex = 31

    local subtitle = Components.Label(
        panel,
        "Subtitle",
        "SURVIVE THE COLLISION",
        UDim2.new(1, -28, 0, 18),
        UDim2.fromOffset(14, 38),
        10,
        Theme.Colors.Cyan,
        true
    )
    subtitle.ZIndex = 31

    local info = Components.Label(
        panel,
        "Info",
        "M1: attack and chain up to 3 hits\nQ / B: dash\nGreen Combat Station: damage upgrade\nRed Elite: highest-value target",
        UDim2.new(1, -28, 0, 92),
        UDim2.fromOffset(14, 68),
        13,
        Theme.Colors.Muted,
        false
    )
    info.TextWrapped = true
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.ZIndex = 31

    local status = Components.Label(
        panel,
        "Status",
        "SYSTEMS ONLINE",
        UDim2.new(1, -28, 0, 20),
        UDim2.fromOffset(14, 170),
        11,
        Theme.Colors.Green,
        true
    )
    status.ZIndex = 31
    self.MenuStatus = status

    local close = Components.Button(
        panel,
        "Close",
        "CLOSE",
        UDim2.fromOffset(78, 32),
        UDim2.new(1, -92, 1, -46),
        Theme.Colors.PanelSoft,
        11,
        9
    )
    close.ZIndex = 31
    close.Activated:Connect(function()
        self:SetMenuOpen(false)
    end)
end

function Root:_buildCombatControls()
    local combat = Instance.new("Frame")
    combat.Name = "CombatControls"
    combat.Size = UDim2.fromOffset(206, 210)
    combat.AnchorPoint = Vector2.new(1, 1)
    combat.Position = UDim2.new(1, -16, 1, -16)
    combat.BackgroundTransparency = 1
    combat.BorderSizePixel = 0
    combat.Parent = self.RootFrame
    self.CombatControls = combat

    local dash = Components.Button(
        combat,
        "Dash",
        "DASH",
        UDim2.fromOffset(92, 58),
        UDim2.fromOffset(8, 0),
        Theme.Colors.CyanDark,
        14,
        29
    )
    dash.AnchorPoint = Vector2.new(0, 0)
    dash.LayoutOrder = 1
    addButtonState(dash)
    dash.Activated:Connect(function()
        self.ActionCallbacks.Dash()
    end)
    self.DashButton = dash

    local dashCooldown = Components.Label(
        dash,
        "Cooldown",
        "",
        UDim2.fromScale(1, 1),
        UDim2.fromOffset(0, 0),
        16,
        WHITE,
        true
    )
    dashCooldown.TextXAlignment = Enum.TextXAlignment.Center
    dashCooldown.Visible = false
    dashCooldown.ZIndex = dash.ZIndex + 2
    self.DashCooldown = dashCooldown

    local dashOverlay = Instance.new("Frame")
    dashOverlay.Name = "CooldownFill"
    dashOverlay.Size = UDim2.fromScale(1, 0)
    dashOverlay.Position = UDim2.fromScale(0, 1)
    dashOverlay.AnchorPoint = Vector2.new(0, 1)
    dashOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dashOverlay.BackgroundTransparency = 0.42
    dashOverlay.BorderSizePixel = 0
    dashOverlay.ClipsDescendants = true
    dashOverlay.ZIndex = dash.ZIndex + 1
    dashOverlay.Parent = dash
    Theme.Corner(dashOverlay, 29)
    self.DashOverlay = dashOverlay

    local m1Size = self.Touch and 96 or 88
    local m1 = Components.Button(
        combat,
        "M1",
        "M1",
        UDim2.fromOffset(m1Size, m1Size),
        UDim2.new(1, -m1Size, 1, -m1Size),
        Theme.Colors.PanelSoft,
        22,
        m1Size
    )
    m1.AnchorPoint = Vector2.new(0, 0)
    m1.Activated:Connect(function()
        self.ActionCallbacks.Attack()
    end)
    self.M1Button = m1

    local combo = Instance.new("Frame")
    combo.Name = "Combo"
    combo.Size = UDim2.fromOffset(54, 10)
    combo.AnchorPoint = Vector2.new(0.5, 1)
    combo.Position = UDim2.new(0.5, 0, 1, -10)
    combo.BackgroundTransparency = 1
    combo.BorderSizePixel = 0
    combo.Parent = m1
    self.ComboDots = {}

    for index = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. index
        dot.Size = UDim2.fromOffset(10, 10)
        dot.BackgroundColor3 = Theme.Colors.Stroke
        dot.BorderSizePixel = 0
        dot.Parent = combo
        Theme.Corner(dot, 5)
        table.insert(self.ComboDots, dot)
    end

    local dotLayout = Instance.new("UIListLayout")
    dotLayout.FillDirection = Enum.FillDirection.Horizontal
    dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dotLayout.Padding = UDim.new(0, 6)
    dotLayout.Parent = combo
end

function Root:_buildToast()
    local holder = Instance.new("Frame")
    holder.Name = "Notifications"
    holder.Size = UDim2.fromOffset(360, 58)
    holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.Position = UDim2.new(0.5, 0, 1, -126)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = self.RootFrame
    self.ToastHolder = holder

    local label = Components.Label(
        holder,
        "Message",
        "",
        UDim2.new(1, -30, 1, 0),
        UDim2.fromOffset(15, 0),
        14,
        WHITE,
        true
    )
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Visible = false
    self.Toast = label
end

function Root:_bindCharacter()
    local characterConnection
    characterConnection = self.Player.CharacterAdded:Connect(function(character)
        self:_attachHumanoid(character)
    end)
    table.insert(self.Connections, characterConnection)

    if self.Player.Character then
        self:_attachHumanoid(self.Player.Character)
    end
end

function Root:_attachHumanoid(character: Model)
    if self.HumanoidConnections then
        for _, connection in ipairs(self.HumanoidConnections) do
            connection:Disconnect()
        end
    end
    self.HumanoidConnections = {}

    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
    if not humanoid then
        return
    end

    local function update()
        local maxHealth = math.max(humanoid.MaxHealth, 1)
        local health = math.clamp(humanoid.Health, 0, maxHealth)
        local ratio = health / maxHealth
        self.HealthValue.Text = formatInteger(health) .. " / " .. formatInteger(maxHealth)
        self.HealthFill.BackgroundColor3 =
            if ratio <= 0.3 then Theme.Colors.Red
            elseif ratio <= 0.6 then Theme.Colors.Yellow
            else Theme.Colors.Green
        setBar(self.HealthFill, ratio)
        setTextColor(self.HealthValue, ratio)
    end

    update()
    table.insert(self.HumanoidConnections, humanoid.HealthChanged:Connect(update))
    table.insert(self.HumanoidConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update))
end

function Root:_bindReplicatedState()
    table.insert(self.Connections, self.Player:GetAttributeChangedSignal("Credits"):Connect(function()
        self:_updateCredits(self.Player:GetAttribute("Credits") or 0)
    end))

    table.insert(self.Connections, self.Player:GetAttributeChangedSignal("DamageLevel"):Connect(function()
        self.DamageLevel.Text = "DMG LV " .. formatInteger(self.Player:GetAttribute("DamageLevel") or 0)
    end))

    table.insert(self.Connections, Workspace:GetAttributeChangedSignal("CollisionWave"):Connect(function()
        self:_updateWave(Workspace:GetAttribute("CollisionWave") or 0)
    end))

    table.insert(self.Connections, Workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(function()
        self:_updateEnemies(Workspace:GetAttribute("CollisionEnemies") or 0)
    end))

    table.insert(self.Connections, Workspace:GetAttributeChangedSignal("CollisionPhase"):Connect(function()
        self:_updatePhase(Workspace:GetAttribute("CollisionPhase") or "Waiting")
    end))

    table.insert(self.Connections, Workspace:GetAttributeChangedSignal("CollisionElite"):Connect(function()
        self:_updateElite(Workspace:GetAttribute("CollisionElite") == true)
    end))

    self:_updateCredits(self.Player:GetAttribute("Credits") or 0)
    self.DamageLevel.Text = "DMG LV " .. formatInteger(self.Player:GetAttribute("DamageLevel") or 0)
    self:_updateWave(Workspace:GetAttribute("CollisionWave") or 0)
    self:_updateEnemies(Workspace:GetAttribute("CollisionEnemies") or 0)
    self:_updatePhase(Workspace:GetAttribute("CollisionPhase") or "Waiting")
    self:_updateElite(Workspace:GetAttribute("CollisionElite") == true)
end

function Root:_updateCredits(value)
    self.CreditsValue.Text = formatInteger(tonumber(value) or 0)
end

function Root:_updateWave(value)
    self.WaveValue.Text = ("WAVE %02d"):format(math.max(0, math.floor(tonumber(value) or 0)))
end

function Root:_updateEnemies(value)
    self.EnemiesValue.Text = "HOSTILES " .. formatInteger(tonumber(value) or 0)
end

function Root:_updatePhase(value: string)
    local phase = string.upper(value)
    self.PhaseValue.Text = phase

    if phase == "CLEARED" then
        self.PhaseValue.TextColor3 = Theme.Colors.Green
    elseif phase == "ACTIVE" then
        self.PhaseValue.TextColor3 = Theme.Colors.Cyan
    elseif phase == "SPAWNING" then
        self.PhaseValue.TextColor3 = Theme.Colors.Yellow
    else
        self.PhaseValue.TextColor3 = Theme.Colors.Muted
    end
end

function Root:_updateElite(active: boolean)
    self.EliteBanner.Visible = active
    if active then
        self.MenuStatus.Text = "ELITE DETECTED"
        self.MenuStatus.TextColor3 = Theme.Colors.Red
    else
        self.MenuStatus.Text = "SYSTEMS ONLINE"
        self.MenuStatus.TextColor3 = Theme.Colors.Green
    end
end

function Root:_applyResponsiveLayout()
    local camera = Workspace.CurrentCamera
    local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
    local metrics = LayoutRules.get(viewport.X, viewport.Y, self.Touch)

    self.PlayerStatus.Size = UDim2.fromOffset(metrics.StatsWidth, 96)
    self.PlayerStatus.Position = UDim2.new(0, metrics.Edge, 1, -metrics.BottomClearance)
    self.HealthFill.Parent.Size = UDim2.fromOffset(math.max(104, metrics.StatsWidth - 24), 10)

    local mobile = metrics.TouchControls
    local compact = mobile and viewport.X < 500
    if compact then
        self.HealthValue.Size = UDim2.fromOffset(math.max(64, math.floor(metrics.StatsWidth * 0.46)), 24)
        self.HealthValue.Position = UDim2.fromOffset(12, 23)
        self.CreditsTitle.Position = UDim2.fromOffset(math.floor(metrics.StatsWidth * 0.52), 7)
        self.CreditsTitle.Size = UDim2.fromOffset(math.max(58, metrics.StatsWidth - math.floor(metrics.StatsWidth * 0.52) - 8), 18)
        self.CreditsValue.Position = UDim2.fromOffset(math.floor(metrics.StatsWidth * 0.52), 23)
        self.CreditsValue.Size = UDim2.fromOffset(math.max(58, metrics.StatsWidth - math.floor(metrics.StatsWidth * 0.52) - 8), 24)
        self.CreditsValue.TextSize = 15
        self.DamageLevel.Visible = false
    else
        self.HealthValue.Size = UDim2.fromOffset(104, 24)
        self.HealthValue.Position = UDim2.fromOffset(12, 23)
        self.CreditsTitle.Position = UDim2.fromOffset(183, 7)
        self.CreditsTitle.Size = UDim2.fromOffset(92, 18)
        self.CreditsValue.Position = UDim2.fromOffset(183, 23)
        self.CreditsValue.Size = UDim2.fromOffset(120, 24)
        self.CreditsValue.TextSize = 17
        self.DamageLevel.Visible = true
    end
    local navMenuWidth = if mobile then 64 else 82
    local navEchoWidth = if mobile then 62 else 78
    local navShopWidth = if mobile then 62 else 78
    local navGap = if mobile then 6 else 8
    local topRightWidth = navMenuWidth + navEchoWidth + navShopWidth + navGap * 2
    self.Navigation.Size = UDim2.fromOffset(topRightWidth, 48)
    self.MenuButton.Size = UDim2.fromOffset(navMenuWidth, 44)
    self.CompanionButton.Size = UDim2.fromOffset(navEchoWidth, 44)
    self.ShopButton.Size = UDim2.fromOffset(navShopWidth, 44)
    self.MenuButton.TextSize = if mobile then 10 else 12
    self.CompanionButton.TextSize = if mobile then 10 else 12
    self.ShopButton.TextSize = if mobile then 10 else 12
    local navigationLayout = self.Navigation:FindFirstChildOfClass("UIListLayout")
    if navigationLayout then
        navigationLayout.Padding = UDim.new(0, navGap)
    end
    self.Navigation.Position = UDim2.new(1, -topRightWidth - metrics.Edge, 0, metrics.Edge)

    local waveWidth = if mobile then math.min(292, viewport.X * 0.72) else 292
    self.WaveStatus.Size = UDim2.fromOffset(math.floor(waveWidth), 72)
    local waveTop = if mobile then metrics.Edge + 52 else metrics.Edge
    self.WaveStatus.Position = UDim2.new(0.5, -math.floor(waveWidth / 2), 0, waveTop)

    self.EliteBanner.Position = UDim2.new(0.5, -135, 0, waveTop + 80)

    local menuWidth = math.min(340, math.max(260, viewport.X - metrics.Edge * 2))
    self.MenuPanel.Size = UDim2.fromOffset(menuWidth, 248)
    self.MenuPanel.Position = UDim2.new(1, -menuWidth - metrics.Edge, 0, metrics.Edge + 52)

    self.CombatControls.Visible = metrics.UseCustomControls
    self.CombatControls.Size = UDim2.fromOffset(metrics.CombatWidth, if mobile then 242 else 210)
    self.CombatControls.Position = UDim2.new(
        1,
        -metrics.Edge,
        1,
        -(if mobile then metrics.BottomClearance else metrics.BottomGap)
    )

    local m1Size = metrics.ActionSize
    self.M1Button.Size = UDim2.fromOffset(m1Size, m1Size)
    self.M1Button.Position = UDim2.new(1, -m1Size, 1, -m1Size)

    self.DashButton.Size = UDim2.fromOffset(metrics.DashWidth, 58)
    self.DashButton.Position = UDim2.fromOffset(8, 0)

    local toastWidth = math.min(360, math.max(220, viewport.X - metrics.Edge * 2))
    self.ToastHolder.Size = UDim2.fromOffset(toastWidth, 58)
    self.ToastHolder.Position = UDim2.new(
        0.5,
        0,
        1,
        -(if mobile then metrics.BottomClearance + m1Size * 0.35 else 126)
    )
end

function Root:SetActionCallbacks(onAttack, onDash)
    self.ActionCallbacks.Attack = onAttack or function() end
    self.ActionCallbacks.Dash = onDash or function() end
end

function Root:SetShopCallback(callback)
    self.ActionCallbacks.Shop = callback
end

function Root:SetCompanionCallback(callback)
    self.ActionCallbacks.Companion = callback
end

function Root:SetMenuOpen(open: boolean)
    self.MenuPanel.Visible = open
    self.MenuButton.Text = if open then "CLOSE" else "MENU"
end

function Root:ApplyCombatState(kind: string, a, b)
    if kind == "Attack" then
        local combo = math.clamp(tonumber(a) or 1, 1, 3)
        self.ComboToken += 1
        local token = self.ComboToken

        for index, dot in ipairs(self.ComboDots) do
            dot.BackgroundColor3 = if index <= combo then Theme.Colors.Cyan else Theme.Colors.Stroke
        end

        self.Toast.Text = if b == true then "HIT" else "MISS"
        self.Toast.TextColor3 = if b == true then Theme.Colors.Cyan else Theme.Colors.Muted
        self.Toast.Visible = true

        task.delay(0.16, function()
            if self.ComboToken == token then
                self.Toast.Visible = false
            end
        end)
    elseif kind == "Dash" then
        self:StartDashCooldown(tonumber(a) or 0)
    elseif kind == "Upgrade" then
        self.DamageLevel.Text = "DMG LV " .. formatInteger(tonumber(a) or 0)
        self:Notify("Damage upgraded.")
    elseif kind == "UpgradeFailed" then
        self:Notify("Need " .. formatInteger(tonumber(a) or 0) .. " Credits.")
    elseif kind == "Credits" then
        self:_updateCredits(tonumber(a) or 0)
        if b == "Defeat" or b == "Wave" then
            self:Notify("+" .. (b == "Wave" and "WAVE REWARD" or "CREDITS"))
        end
    end
end

function Root:StartDashCooldown(duration: number)
    self.DashToken += 1
    local token = self.DashToken
    local durationValue = math.max(0, duration)

    if durationValue <= 0 then
        self.DashCooldown.Visible = false
        self.DashOverlay.Size = UDim2.fromScale(1, 0)
        return
    end

    self.DashCooldown.Visible = true
    local started = os.clock()

    task.spawn(function()
        while self.DashToken == token do
            local elapsed = os.clock() - started
            local remaining = math.max(0, durationValue - elapsed)
            local ratio = if durationValue > 0 then remaining / durationValue else 0

            self.DashCooldown.Text = string.format("%.1f", remaining)
            self.DashOverlay.Size = UDim2.fromScale(1, ratio)

            if remaining <= 0 then
                break
            end

            task.wait(0.05)
        end

        if self.DashToken == token then
            self.DashCooldown.Visible = false
            self.DashOverlay.Size = UDim2.fromScale(1, 0)
        end
    end)
end

function Root:Notify(message: string)
    self.ToastToken += 1
    local token = self.ToastToken

    self.Toast.Text = message
    self.Toast.TextColor3 = Theme.Colors.Text
    self.Toast.Visible = true

    task.delay(1.35, function()
        if self.ToastToken == token then
            self.Toast.Visible = false
        end
    end)
end

function Root:Destroy()
    self.DashToken += 1
    self.ToastToken += 1
    self.ComboToken += 1

    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    for _, connection in ipairs(self.HumanoidConnections or {}) do
        connection:Disconnect()
    end

    if self.Gui then
        self.Gui:Destroy()
    end
end

return Root
