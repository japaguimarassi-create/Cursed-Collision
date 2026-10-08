--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local HUD = {}
HUD.__index = HUD

local function corner(gui: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = gui
end

local function button(parent: Instance, name: string, text: string, size: UDim2)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Size = size
    b.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(245, 247, 252)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 12)
    return b
end

local function label(parent: Instance, name: string, text: string, size: UDim2)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Text = text
    l.Size = size
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(235, 238, 246)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.Parent = parent
    return l
end

function HUD.new(remotes)
    local player = Players.LocalPlayer
    local guiParent = player:WaitForChild("PlayerGui")
    local old = guiParent:FindFirstChild("CBS2_HUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CBS2_HUD"
    gui.ResetOnSpawn = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = guiParent

    local root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = gui

    local stats = Instance.new("Frame")
    stats.Name = "Stats"
    stats.Size = UDim2.fromOffset(270, 88)
    stats.Position = UDim2.fromOffset(12, 12)
    stats.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
    stats.BackgroundTransparency = 0.08
    stats.BorderSizePixel = 0
    stats.Parent = root
    corner(stats, 14)

    local hp = label(stats, "HP", "HP 100 / 100", UDim2.new(1, -20, 0, 22))
    hp.Position = UDim2.fromOffset(10, 7)

    local score = label(stats, "Score", "LEVEL 1  •  SCORE 0", UDim2.new(1, -20, 0, 22))
    score.Position = UDim2.fromOffset(10, 31)

    local credits = label(stats, "Credits", "CREDITS 0", UDim2.new(1, -20, 0, 22))
    credits.Position = UDim2.fromOffset(10, 55)

    local wave = Instance.new("Frame")
    wave.Size = UDim2.fromOffset(220, 70)
    wave.Position = UDim2.new(0.5, -110, 0, 12)
    wave.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
    wave.BackgroundTransparency = 0.08
    wave.BorderSizePixel = 0
    wave.Parent = root
    corner(wave, 14)

    local waveLabel = label(wave, "Wave", "WAVE 0", UDim2.fromScale(1, 0.45))
    waveLabel.TextXAlignment = Enum.TextXAlignment.Center
    local enemyLabel = label(wave, "Enemies", "ENEMIES 0", UDim2.fromScale(1, 0.4))
    enemyLabel.TextXAlignment = Enum.TextXAlignment.Center
    enemyLabel.Position = UDim2.fromScale(0, 0.5)

    local status = label(root, "Status", "READY", UDim2.fromOffset(420, 28))
    status.Position = UDim2.new(0.5, -210, 0, 90)
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.TextSize = 13

    local menu = button(root, "Menu", "MENU", UDim2.fromOffset(100, 48))
    menu.Position = UDim2.fromOffset(12, 12 + 96)

    local attack = button(root, "Attack", "M1", UDim2.fromOffset(112, 112))
    attack.Position = UDim2.new(1, -126, 1, -126)
    attack.TextSize = 24

    local dash = button(root, "Dash", "DASH", UDim2.fromOffset(112, 62))
    dash.Position = UDim2.new(1, -126, 1, -198)

    local utility = Instance.new("ScrollingFrame")
    utility.Name = "Utility"
    utility.Size = UDim2.new(1, -140, 0, 46)
    utility.Position = UDim2.new(0, 12, 1, -58)
    utility.BackgroundTransparency = 1
    utility.BorderSizePixel = 0
    utility.ScrollBarThickness = 0
    utility.ScrollingDirection = Enum.ScrollingDirection.X
    utility.AutomaticCanvasSize = Enum.AutomaticSize.X
    utility.Parent = root

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 5)
    layout.Parent = utility

    local shop = button(utility, "Shop", "SHOP", UDim2.fromOffset(62, 44))
    local mission = button(utility, "Mission", "CHALLENGE", UDim2.fromOffset(92, 44))
    local echo = button(utility, "Echo", "ECHO", UDim2.fromOffset(62, 44))
    local pvp = button(utility, "PVP", "PVP", UDim2.fromOffset(56, 44))
    local rank = button(utility, "Rank", "RANK", UDim2.fromOffset(62, 44))

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, -20, 1, -120)
    overlay.Position = UDim2.fromOffset(10, 60)
    overlay.BackgroundTransparency = 1
    overlay.Visible = false
    overlay.Parent = root

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
    panel.BackgroundTransparency = 0.02
    panel.BorderSizePixel = 0
    panel.Parent = overlay
    corner(panel, 16)

    local title = label(panel, "Title", "MENU", UDim2.new(1, -70, 0, 38))
    title.Position = UDim2.fromOffset(16, 12)
    title.TextSize = 20

    local close = button(panel, "Close", "X", UDim2.fromOffset(42, 42))
    close.Position = UDim2.new(1, -54, 0, 10)

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -66)
    content.Position = UDim2.fromOffset(12, 58)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = panel

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content

    local self = setmetatable({
        gui = gui,
        remotes = remotes,
        hp = hp,
        score = score,
        credits = credits,
        wave = waveLabel,
        enemies = enemyLabel,
        status = status,
        overlay = overlay,
        title = title,
        content = content,
        menu = menu,
        attack = attack,
        dash = dash,
        stateConnection = nil,
        characterConnection = nil,
        healthConnection = nil,
        disabled = false,
    }, HUD)

    local function open(name: string)
        self:Open(name)
    end

    menu.Activated:Connect(function()
        open("MENU")
    end)
    shop.Activated:Connect(function()
        open("SHOP")
        remotes.Shop:FireServer({action = "Catalog"})
    end)
    mission.Activated:Connect(function()
        open("CHALLENGES")
        remotes.State:FireServer({action = "Missions"})
    end)
    echo.Activated:Connect(function()
        open("ECHO")
        remotes.Echo:FireServer({action = "State"})
    end)
    pvp.Activated:Connect(function()
        open("PVP")
    end)
    rank.Activated:Connect(function()
        open("RANKING")
        remotes.State:FireServer({action = "Ranking"})
    end)
    close.Activated:Connect(function()
        self.overlay.Visible = false
    end)

    attack.Activated:Connect(function()
        if not self.disabled then
            remotes.Combat:FireServer({action = "Attack"})
        end
    end)

    dash.Activated:Connect(function()
        if not self.disabled then
            local camera = workspace.CurrentCamera
            local look = camera and camera.CFrame.LookVector or Vector3.zAxis
            remotes.Combat:FireServer({
                action = "Dash",
                direction = Vector3.new(look.X, 0, look.Z),
            })
        end
    end)

    self.stateConnection = remotes.State.OnClientEvent:Connect(function(kind, payload)
        if kind == "Snapshot" and type(payload) == "table" then
            self:SetState(payload)
        elseif kind == "RuntimeReloading" then
            self.disabled = true
            self.status.Text = "RUNTIME RECOVERY..."
        elseif kind == "RuntimeRestored" then
            self.disabled = false
            self.status.Text = "RUNTIME RESTORED"
        elseif kind == "RuntimeFailed" then
            self.disabled = true
            self.status.Text = "RUNTIME FAILURE"
        elseif kind == "LevelUp" and type(payload) == "table" then
            self.status.Text = ("LEVEL %d!"):format(payload.level or 1)
        elseif kind == "Ranking" and type(payload) == "table" then
            self:ShowRanking(payload)
        elseif kind == "Missions" and type(payload) == "table" then
            self:ShowMissions(payload)
        end
    end)

    self:BindCharacter()
    return self
end

function HUD:SetState(snapshot)
    self.wave.Text = ("WAVE %d"):format(snapshot.wave or 0)
    self.enemies.Text = ("ENEMIES %d"):format(snapshot.enemiesAlive or 0)

    if snapshot.phase == "Wave" then
        self.status.Text = snapshot.boss and "BOSS WAVE" or snapshot.event or "FIGHT"
    elseif snapshot.phase == "Intermission" then
        self.status.Text = "PREPARE"
    elseif snapshot.phase == "Error" then
        self.status.Text = "RUNTIME ERROR"
    end

    local player = Players.LocalPlayer
    self.credits.Text = ("CREDITS %d"):format(player:GetAttribute("CBS_Credits") or 0)
    self.score.Text = ("LEVEL %d  •  SCORE %d"):format(
        player:GetAttribute("CBS_Level") or 1,
        player:GetAttribute("CBS_Score") or 0
    )
end

function HUD:BindCharacter()
    local player = Players.LocalPlayer

    local function bind(character)
        if self.healthConnection then
            self.healthConnection:Disconnect()
        end

        local humanoid = character:WaitForChild("Humanoid", 8)
        if not humanoid then
            return
        end

        local function update()
            self.hp.Text = ("HP %d / %d"):format(
                math.floor(humanoid.Health + 0.5),
                math.floor(humanoid.MaxHealth + 0.5)
            )
        end

        self.healthConnection = humanoid.HealthChanged:Connect(update)
        humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
        update()
    end

    self.characterConnection = player.CharacterAdded:Connect(bind)
    if player.Character then
        bind(player.Character)
    end
end

function HUD:ClearContent()
    for _, child in ipairs(self.content:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

function HUD:Open(name: string)
    self.overlay.Visible = true
    self.title.Text = name
    self:ClearContent()

    if name == "MENU" then
        local info = label(self.content, "Info", "Collision Battlestar • Where Worlds Collide", UDim2.new(1, -10, 0, 50))
        info.TextXAlignment = Enum.TextXAlignment.Center
        info.TextSize = 17
    elseif name == "SHOP" then
        local info = label(self.content, "Info", "Upgrades and cosmetics", UDim2.new(1, -10, 0, 34))
        info.TextXAlignment = Enum.TextXAlignment.Center
    elseif name == "ECHO" then
        local summon = button(self.content, "Summon", "SUMMON ECHO", UDim2.new(1, -10, 0, 54))
        summon.Activated:Connect(function()
            self.remotes.Echo:FireServer({action = "Summon"})
        end)
        local dismiss = button(self.content, "Dismiss", "DISMISS", UDim2.new(1, -10, 0, 46))
        dismiss.Activated:Connect(function()
            self.remotes.Echo:FireServer({action = "Dismiss"})
        end)
    elseif name == "PVP" then
        local join = button(self.content, "JoinPVP", "ENTER PVP", UDim2.new(1, -10, 0, 54))
        join.Activated:Connect(function()
            self.remotes.PvP:FireServer({action = "Join"})
        end)
        local leave = button(self.content, "LeavePVP", "RETURN TO PVE", UDim2.new(1, -10, 0, 46))
        leave.Activated:Connect(function()
            self.remotes.PvP:FireServer({action = "Leave"})
        end)
    end
end

function HUD:ShowRanking(payload)
    self:Open("RANKING")
    local rows = payload.rows or {}
    for _, entry in ipairs(rows) do
        local row = label(
            self.content,
            "Row" .. tostring(entry.rank),
            ("#%d  %s  •  %d"):format(entry.rank or 0, entry.name or "?", entry.score or 0),
            UDim2.new(1, -10, 0, 42)
        )
        row.TextXAlignment = Enum.TextXAlignment.Center
        row.BackgroundTransparency = 0
        row.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
        corner(row, 10)
    end
end

function HUD:ShowMissions(payload)
    self:Open("CHALLENGES")
    for id, entry in pairs(payload) do
        local row = label(
            self.content,
            id,
            ("%s  •  %d / %d  •  %d C"):format(
                entry.name or id,
                entry.progress or 0,
                entry.goal or 0,
                entry.reward or 0
            ),
            UDim2.new(1, -10, 0, 48)
        )
        row.BackgroundTransparency = 0
        row.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
        corner(row, 10)
    end
end

function HUD:Stop()
    if self.stateConnection then
        self.stateConnection:Disconnect()
        self.stateConnection = nil
    end
    if self.characterConnection then
        self.characterConnection:Disconnect()
        self.characterConnection = nil
    end
    if self.healthConnection then
        self.healthConnection:Disconnect()
        self.healthConnection = nil
    end
    self.gui:Destroy()
end

return HUD
