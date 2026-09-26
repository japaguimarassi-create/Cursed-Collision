--!strict

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function create()
    local playerGui = player:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("CollisionBattlestarImmediateHUD")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarImmediateHUD"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 40
    gui.IgnoreGuiInset = false
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = playerGui

    local scale = Instance.new("UIScale")
    scale.Parent = gui

    local function resize()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local viewport = camera.ViewportSize
        scale.Scale = math.clamp(math.min(viewport.X / 1100, viewport.Y / 650), 0.76, 1.08)
    end

    local camera = workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
    end
    resize()

    local top = Instance.new("Frame")
    top.Size = UDim2.fromOffset(310, 70)
    top.Position = UDim2.fromScale(0.5, 0)
    top.AnchorPoint = Vector2.new(0.5, 0)
    top.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    top.BackgroundTransparency = 0.06
    top.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = top

    local wave = Instance.new("TextLabel")
    wave.BackgroundTransparency = 1
    wave.Size = UDim2.new(0.5, -12, 0, 42)
    wave.Position = UDim2.fromOffset(12, 5)
    wave.Font = Enum.Font.GothamBold
    wave.TextSize = 22
    wave.TextColor3 = Color3.fromRGB(242, 245, 250)
    wave.Text = "WAVE 0"
    wave.TextXAlignment = Enum.TextXAlignment.Left
    wave.Parent = top

    local enemies = Instance.new("TextLabel")
    enemies.BackgroundTransparency = 1
    enemies.Size = UDim2.new(0.5, -12, 0, 42)
    enemies.Position = UDim2.new(0.5, 0, 0, 5)
    enemies.Font = Enum.Font.GothamBold
    enemies.TextSize = 10
    enemies.TextColor3 = Color3.fromRGB(158, 167, 182)
    enemies.Text = "READY"
    enemies.TextXAlignment = Enum.TextXAlignment.Right
    enemies.Parent = top

    local hp = Instance.new("TextLabel")
    hp.BackgroundTransparency = 1
    hp.Size = UDim2.fromOffset(250, 28)
    hp.Position = UDim2.fromOffset(20, 16)
    hp.Font = Enum.Font.GothamBold
    hp.TextSize = 13
    hp.TextColor3 = Color3.fromRGB(110, 225, 170)
    hp.Text = "HP  — / —"
    hp.TextXAlignment = Enum.TextXAlignment.Left
    hp.Parent = gui

    local zone = Instance.new("TextLabel")
    zone.BackgroundTransparency = 1
    zone.Size = UDim2.fromOffset(180, 24)
    zone.Position = UDim2.fromOffset(20, 94)
    zone.Font = Enum.Font.GothamBold
    zone.TextSize = 9
    zone.TextColor3 = Color3.fromRGB(158, 167, 182)
    zone.Text = "PVE"
    zone.Parent = gui

    local function bindCharacter(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 6)
        if not humanoid then
            return
        end

        local function update()
            hp.Text = ("HP %d / %d"):format(math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5))
        end

        humanoid.HealthChanged:Connect(update)
        update()
    end

    player.CharacterAdded:Connect(bindCharacter)
    if player.Character then
        task.spawn(bindCharacter, player.Character)
    end

    local function sync()
        wave.Text = ("WAVE %d"):format(workspace:GetAttribute("CollisionWave") or 0)
        enemies.Text = ("%d ENEMIES"):format(workspace:GetAttribute("CollisionEnemies") or 0)
        zone.Text = (player:GetAttribute("Zone") or "PvE") == "PvP" and "PVP BATTLEGROUNDS" or "PVE"
    end

    workspace:GetAttributeChangedSignal("CollisionWave"):Connect(sync)
    workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(sync)
    player:GetAttributeChangedSignal("Zone"):Connect(sync)
    sync()

    task.spawn(function()
        while gui.Parent do
            RunService.Heartbeat:Wait()
            if player:GetAttribute("CollisionHUDReady") == true then
                task.wait(0.15)
                if gui.Parent then
                    gui:Destroy()
                end
                break
            end
        end
    end)

    return gui
end

pcall(function()
    ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

create()
