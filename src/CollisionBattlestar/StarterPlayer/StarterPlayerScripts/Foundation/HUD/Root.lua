--!strict

local Players = game:GetService("Players")

local Root = {}

local function label(parent: Instance, name: string, value: string, size: UDim2, position: UDim2, font: Enum.Font, color: Color3): TextLabel
    local object = Instance.new("TextLabel")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundTransparency = 1
    object.Font = font
    object.Text = value
    object.TextColor3 = color
    object.TextScaled = true
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.Parent = parent
    return object
end

local function button(parent: Instance, name: string, value: string, size: UDim2, position: UDim2, color: Color3): TextButton
    local object = Instance.new("TextButton")
    object.Name = name
    object.Size = size
    object.Position = position
    object.BackgroundColor3 = color
    object.BackgroundTransparency = 0.08
    object.BorderSizePixel = 0
    object.Font = Enum.Font.GothamBold
    object.Text = value
    object.TextColor3 = Color3.fromRGB(240, 245, 255)
    object.TextScaled = true
    object.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = object

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.2
    stroke.Transparency = 0.5
    stroke.Color = Color3.fromRGB(210, 220, 235)
    stroke.Parent = object

    return object
end

function Root.Create(player: Player)
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("CollisionBattlestarHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local status = Instance.new("Frame")
    status.Name = "Status"
    status.Size = UDim2.fromOffset(340, 94)
    status.Position = UDim2.fromOffset(16, 16)
    status.BackgroundColor3 = Color3.fromRGB(19, 24, 33)
    status.BackgroundTransparency = 0.1
    status.BorderSizePixel = 0
    status.Parent = gui

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 16)
    statusCorner.Parent = status

    local statusStroke = Instance.new("UIStroke")
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.45
    statusStroke.Color = Color3.fromRGB(75, 92, 118)
    statusStroke.Parent = status

    local health = label(status, "Health", "HP 100/100", UDim2.fromOffset(170, 28), UDim2.fromOffset(14, 12), Enum.Font.GothamBold, Color3.fromRGB(102, 243, 164))
    local credits = label(status, "Credits", "CREDITS 0", UDim2.fromOffset(140, 28), UDim2.fromOffset(185, 12), Enum.Font.GothamBold, Color3.fromRGB(255, 224, 100))
    local wave = label(status, "Wave", "WAVE 00", UDim2.fromOffset(150, 28), UDim2.fromOffset(14, 52), Enum.Font.GothamBlack, Color3.fromRGB(238, 244, 252))
    local enemies = label(status, "Enemies", "HOSTILES 0", UDim2.fromOffset(160, 28), UDim2.fromOffset(175, 52), Enum.Font.GothamBold, Color3.fromRGB(186, 205, 228))

    local elite = label(gui, "Elite", "ELITE ACTIVE", UDim2.fromOffset(230, 42), UDim2.new(0.5, 0, 0, 15), Enum.Font.GothamBlack, Color3.fromRGB(255, 74, 88))
    elite.AnchorPoint = Vector2.new(0.5, 0)
    elite.TextXAlignment = Enum.TextXAlignment.Center
    elite.Visible = false

    local menu = button(gui, "Menu", "MENU", UDim2.fromOffset(90, 50), UDim2.new(1, -106, 0, 18), Color3.fromRGB(34, 43, 56))

    local panel = Instance.new("Frame")
    panel.Name = "MenuPanel"
    panel.Size = UDim2.fromOffset(308, 190)
    panel.Position = UDim2.new(1, -324, 0, 78)
    panel.BackgroundColor3 = Color3.fromRGB(17, 22, 31)
    panel.BackgroundTransparency = 0.03
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 16)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.35
    panelStroke.Color = Color3.fromRGB(70, 90, 118)
    panelStroke.Parent = panel

    label(panel, "Title", "COLLISION BATTLESTAR", UDim2.fromOffset(280, 28), UDim2.fromOffset(14, 12), Enum.Font.GothamBlack, Color3.fromRGB(235, 242, 251))
    local info = label(panel, "Info", "Survive the wave. Defeat the red Elite.\nUse the green Combat Station in the south to upgrade damage.", UDim2.fromOffset(280, 70), UDim2.fromOffset(14, 48), Enum.Font.Gotham, Color3.fromRGB(180, 194, 216))
    info.TextWrapped = true
    info.TextYAlignment = Enum.TextYAlignment.Top
    label(panel, "Controls", "M1: Left Click / R2     Dash: Q / B", UDim2.fromOffset(280, 34), UDim2.fromOffset(14, 126), Enum.Font.GothamBold, Color3.fromRGB(100, 221, 255))
    label(panel, "Upgrade", "Each upgrade adds +5 M1 damage.", UDim2.fromOffset(280, 26), UDim2.fromOffset(14, 157), Enum.Font.Gotham, Color3.fromRGB(165, 176, 196))

    local m1 = button(gui, "M1", "M1", UDim2.fromOffset(90, 90), UDim2.new(1, -206, 1, -126), Color3.fromRGB(42, 52, 68))
    local dash = button(gui, "Dash", "DASH", UDim2.fromOffset(96, 70), UDim2.new(1, -104, 1, -104), Color3.fromRGB(49, 68, 88))

    local callbacks = {
        attack = function() end,
        dash = function() end,
    }

    m1.Activated:Connect(function()
        callbacks.attack()
    end)

    dash.Activated:Connect(function()
        callbacks.dash()
    end)

    menu.Activated:Connect(function()
        panel.Visible = not panel.Visible
    end)

    local humanoidConnection
    local function bindCharacter(character: Model)
        if humanoidConnection then
            humanoidConnection:Disconnect()
            humanoidConnection = nil
        end

        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            local function update()
                health.Text = ("HP %d/%d"):format(math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5))
            end
            humanoidConnection = humanoid.HealthChanged:Connect(update)
            update()
        end
    end

    if player.Character then
        bindCharacter(player.Character)
    end
    player.CharacterAdded:Connect(bindCharacter)

    player:GetAttributeChangedSignal("Credits"):Connect(function()
        credits.Text = ("CREDITS %d"):format(player:GetAttribute("Credits") or 0)
    end)

    workspace:GetAttributeChangedSignal("CollisionWave"):Connect(function()
        wave.Text = ("WAVE %02d"):format(workspace:GetAttribute("CollisionWave") or 0)
    end)

    workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(function()
        enemies.Text = ("HOSTILES %d"):format(workspace:GetAttribute("CollisionEnemies") or 0)
    end)

    workspace:GetAttributeChangedSignal("CollisionElite"):Connect(function()
        elite.Visible = workspace:GetAttribute("CollisionElite") == true
    end)

    credits.Text = ("CREDITS %d"):format(player:GetAttribute("Credits") or 0)
    wave.Text = ("WAVE %02d"):format(workspace:GetAttribute("CollisionWave") or 0)
    enemies.Text = ("HOSTILES %d"):format(workspace:GetAttribute("CollisionEnemies") or 0)
    elite.Visible = workspace:GetAttribute("CollisionElite") == true

    return {
        Gui = gui,
        M1 = m1,
        Dash = dash,
        SetActionCallbacks = function(_, onAttack, onDash)
            callbacks.attack = onAttack
            callbacks.dash = onDash
        end,
    }
end

return Root