--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local HUD = {}
HUD.__index = HUD

local function addCorner(instance: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function addStroke(instance: GuiObject, transparency: number)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = transparency
    stroke.Color = Color3.fromRGB(125, 130, 150)
    stroke.Parent = instance
end

local function makeText(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, fontSize: number)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(240, 242, 248)
    label.Font = Enum.Font.GothamBold
    label.TextSize = fontSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makePanel(parent: Instance, name: string, size: UDim2, position: UDim2)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.Parent = parent
    addCorner(frame, 12)
    addStroke(frame, 0.45)
    return frame
end

local function makeButton(parent: Instance, name: string, text: string, size: UDim2, position: UDim2)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
    button.BackgroundTransparency = 0.05
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(245, 247, 252)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.AutoButtonColor = true
    button.Parent = parent
    addCorner(button, 14)
    addStroke(button, 0.35)
    return button
end

function HUD.new(remotes)
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUD"
    gui.DisplayOrder = 10
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = playerGui

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local topLeft = makePanel(root, "PlayerPanel", UDim2.fromOffset(250, 78), UDim2.fromOffset(16, 16))
    local healthLabel = makeText(topLeft, "HealthLabel", "HP 100 / 100", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 10), 17)

    local healthTrack = Instance.new("Frame")
    healthTrack.Name = "HealthTrack"
    healthTrack.Size = UDim2.new(1, -28, 0, 14)
    healthTrack.Position = UDim2.fromOffset(14, 42)
    healthTrack.BackgroundColor3 = Color3.fromRGB(50, 54, 66)
    healthTrack.BorderSizePixel = 0
    healthTrack.Parent = topLeft
    addCorner(healthTrack, 7)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.fromScale(1, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(75, 205, 115)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthTrack
    addCorner(healthFill, 7)

    local wavePanel = makePanel(root, "WavePanel", UDim2.fromOffset(250, 88), UDim2.new(0.5, -125, 0, 16))
    local waveLabel = makeText(wavePanel, "WaveLabel", "WAVE 0", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 21)
    waveLabel.TextXAlignment = Enum.TextXAlignment.Center
    local enemiesLabel = makeText(wavePanel, "EnemiesLabel", "Enemies 0", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 39), 15)
    enemiesLabel.TextXAlignment = Enum.TextXAlignment.Center
    local eliteLabel = makeText(wavePanel, "EliteLabel", "ELITE ACTIVE", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(14, 61), 15)
    eliteLabel.TextXAlignment = Enum.TextXAlignment.Center
    eliteLabel.TextColor3 = Color3.fromRGB(255, 80, 90)
    eliteLabel.Visible = false

    local creditsPanel = makePanel(root, "CreditsPanel", UDim2.fromOffset(190, 66), UDim2.new(1, -206, 0, 16))
    local creditsLabel = makeText(creditsPanel, "CreditsLabel", "CREDITS 0", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 18)
    creditsLabel.TextXAlignment = Enum.TextXAlignment.Center

    local status = makeText(root, "Status", "CONNECTING...", UDim2.fromOffset(420, 32), UDim2.new(0.5, -210, 0, 114), 15)
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.TextColor3 = Color3.fromRGB(190, 198, 214)

    local menuButton = makeButton(root, "MenuButton", "MENU", UDim2.fromOffset(118, 54), UDim2.new(0, 16, 1, -70))

    local actionFrame = Instance.new("Frame")
    actionFrame.Name = "Actions"
    actionFrame.Size = UDim2.fromOffset(250, 120)
    actionFrame.Position = UDim2.new(1, -270, 1, -136)
    actionFrame.BackgroundTransparency = 1
    actionFrame.Parent = root

    local attackButton = makeButton(actionFrame, "AttackButton", "M1", UDim2.fromOffset(112, 112), UDim2.fromOffset(0, 0))
    attackButton.TextSize = 26

    local dashButton = makeButton(actionFrame, "DashButton", "DASH", UDim2.fromOffset(112, 72), UDim2.fromOffset(126, 20))
    dashButton.TextSize = 20

    local menuPanel = makePanel(root, "MenuPanel", UDim2.fromOffset(300, 220), UDim2.new(0, 16, 1, -304))
    menuPanel.Visible = false

    local menuTitle = makeText(menuPanel, "Title", "COLLISION BATTLESTAR", UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 12), 18)
    menuTitle.TextXAlignment = Enum.TextXAlignment.Center

    local powerLabel = makeText(menuPanel, "PowerLabel", "POWER 1", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 52), 16)
    powerLabel.TextXAlignment = Enum.TextXAlignment.Center

    local upgradeButton = makeButton(menuPanel, "UpgradeButton", "UPGRADE", UDim2.new(1, -28, 0, 54), UDim2.fromOffset(14, 92))
    local closeButton = makeButton(menuPanel, "CloseButton", "CLOSE", UDim2.new(1, -28, 0, 40), UDim2.fromOffset(14, 158))
    closeButton.TextSize = 15

    if not UserInputService.TouchEnabled then
        actionFrame.Visible = true
    end

    local self = setmetatable({
        gui = gui,
        root = root,
        remotes = remotes,
        healthLabel = healthLabel,
        healthFill = healthFill,
        waveLabel = waveLabel,
        enemiesLabel = enemiesLabel,
        eliteLabel = eliteLabel,
        creditsLabel = creditsLabel,
        status = status,
        menuPanel = menuPanel,
        powerLabel = powerLabel,
        upgradeButton = upgradeButton,
        actionFrame = actionFrame,
        attackButton = attackButton,
        dashButton = dashButton,
        snapshot = nil,
        stateConnection = nil,
        humanoidConnection = nil,
    }, HUD)

    menuButton.Activated:Connect(function()
        menuPanel.Visible = not menuPanel.Visible
    end)

    closeButton.Activated:Connect(function()
        menuPanel.Visible = false
    end)

    upgradeButton.Activated:Connect(function()
        remotes.State:FireServer({
            action = "Upgrade",
        })
    end)

    self:BindState()
    self:BindCharacter()

    return self
end

function HUD:BindState()
    self.stateConnection = self.remotes.State.OnClientEvent:Connect(function(kind, payload)
        if kind == "Snapshot" then
            self:SetSnapshot(payload)
        elseif kind == "UpgradeResult" then
            if payload.success then
                self.status.Text = "UPGRADE COMPLETE"
                self.status.TextColor3 = Color3.fromRGB(110, 225, 135)
            else
                self.status.Text = "NEED MORE CREDITS"
                self.status.TextColor3 = Color3.fromRGB(255, 200, 90)
            end
        end
    end)

    self.remotes.State:FireServer({
        action = "RequestState",
    })
end

function HUD:SetSnapshot(snapshot)
    if type(snapshot) ~= "table" then
        return
    end

    self.snapshot = snapshot
    self.waveLabel.Text = ("WAVE %d"):format(tonumber(snapshot.wave) or 0)
    self.enemiesLabel.Text = ("Enemies %d"):format(tonumber(snapshot.enemiesAlive) or 0)
    self.eliteLabel.Visible = snapshot.eliteAlive == true

    local player = Players.LocalPlayer
    local credits = player:GetAttribute("CBS_Credits") or 0
    local power = player:GetAttribute("CBS_PowerLevel") or 1

    self.creditsLabel.Text = ("CREDITS %d"):format(credits)
    self.powerLabel.Text = ("POWER %d"):format(power)

    if snapshot.phase == "Intermission" then
        self.status.Text = "NEXT WAVE IN A MOMENT"
        self.status.TextColor3 = Color3.fromRGB(190, 198, 214)
    elseif snapshot.phase == "Wave" then
        self.status.Text = "FIGHT"
        self.status.TextColor3 = Color3.fromRGB(240, 242, 248)
    elseif snapshot.phase == "Booting" then
        self.status.Text = "CONNECTING..."
        self.status.TextColor3 = Color3.fromRGB(190, 198, 214)
    end
end

function HUD:BindCharacter()
    local player = Players.LocalPlayer

    local function bindCharacter(character: Model)
        if self.humanoidConnection then
            self.humanoidConnection:Disconnect()
            self.humanoidConnection = nil
        end

        local humanoid = character:WaitForChild("Humanoid", 8)
        if not humanoid or not humanoid:IsA("Humanoid") then
            return
        end

        local function updateHealth()
            local maxHealth = math.max(1, humanoid.MaxHealth)
            local health = math.max(0, humanoid.Health)
            local ratio = math.clamp(health / maxHealth, 0, 1)

            self.healthLabel.Text = ("HP %d / %d"):format(math.floor(health + 0.5), math.floor(maxHealth + 0.5))
            TweenService:Create(
                self.healthFill,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.fromScale(ratio, 1)}
            ):Play()
        end

        self.humanoidConnection = humanoid.HealthChanged:Connect(updateHealth)
        humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
        updateHealth()
    end

    player.CharacterAdded:Connect(bindCharacter)

    if player.Character then
        bindCharacter(player.Character)
    end

    player:GetAttributeChangedSignal("CBS_Credits"):Connect(function()
        self.creditsLabel.Text = ("CREDITS %d"):format(player:GetAttribute("CBS_Credits") or 0)
    end)

    player:GetAttributeChangedSignal("CBS_PowerLevel"):Connect(function()
        self.powerLabel.Text = ("POWER %d"):format(player:GetAttribute("CBS_PowerLevel") or 1)
    end)
end

function HUD:GetAttackButton()
    return self.attackButton
end

function HUD:GetDashButton()
    return self.dashButton
end

function HUD:IsTouchEnabled()
    return UserInputService.TouchEnabled
end

function HUD:SetControlsEnabled(enabled: boolean)
    self.attackButton.Active = enabled
    self.dashButton.Active = enabled
    self.attackButton.AutoButtonColor = enabled
    self.dashButton.AutoButtonColor = enabled
end

function HUD:Destroy()
    if self.stateConnection then
        self.stateConnection:Disconnect()
    end

    if self.humanoidConnection then
        self.humanoidConnection:Disconnect()
    end

    if self.gui then
        self.gui:Destroy()
    end
end

return HUD
