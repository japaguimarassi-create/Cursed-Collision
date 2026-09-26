--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local root = script.Parent

local fallback: ScreenGui? = nil
local booting = false

local function rounded(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function makeText(parent: Instance, textValue: string, size: number, bold: boolean?)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = textValue
    label.TextColor3 = Color3.fromRGB(245, 247, 252)
    label.Font = bold == false and Enum.Font.GothamMedium or Enum.Font.GothamBold
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeFallback()
    if fallback and fallback.Parent then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUDFallback"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 90
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = playerGui

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = gui

    local profile = Instance.new("Frame")
    profile.Size = UDim2.fromOffset(230, 54)
    profile.Position = UDim2.fromOffset(18, 18)
    profile.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
    profile.BackgroundTransparency = 0.08
    profile.BorderSizePixel = 0
    profile.Parent = gui
    rounded(profile, 16)

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(42, 42)
    avatar.Position = UDim2.fromOffset(6, 6)
    avatar.BackgroundTransparency = 1
    avatar.Parent = profile
    rounded(avatar, 99)

    pcall(function()
        avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)

    local name = makeText(profile, player.DisplayName, 12)
    name.Size = UDim2.new(1, -58, 0, 20)
    name.Position = UDim2.fromOffset(56, 5)

    local stats = makeText(profile, "DMG 0   DEF 0   SPD 0", 7, false)
    stats.TextColor3 = Color3.fromRGB(151, 162, 181)
    stats.Size = UDim2.new(1, -58, 0, 16)
    stats.Position = UDim2.fromOffset(56, 27)

    local wave = makeText(gui, "WAVE 00", 18)
    wave.AnchorPoint = Vector2.new(0.5, 0)
    wave.Position = UDim2.fromScale(0.5, 0)
    wave.Size = UDim2.fromOffset(180, 36)
    wave.TextXAlignment = Enum.TextXAlignment.Center

    local enemies = makeText(gui, "0 HOSTILES", 8, false)
    enemies.AnchorPoint = Vector2.new(0.5, 0)
    enemies.Position = UDim2.fromScale(0.5, 0)
    enemies.Size = UDim2.fromOffset(180, 18)
    enemies.Position += UDim2.fromOffset(0, 34)
    enemies.TextColor3 = Color3.fromRGB(151, 162, 181)
    enemies.TextXAlignment = Enum.TextXAlignment.Center

    local creditsPanel = Instance.new("Frame")
    creditsPanel.Size = UDim2.fromOffset(152, 44)
    creditsPanel.Position = UDim2.new(1, -18, 0, 18)
    creditsPanel.AnchorPoint = Vector2.new(1, 0)
    creditsPanel.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
    creditsPanel.BackgroundTransparency = 0.08
    creditsPanel.BorderSizePixel = 0
    creditsPanel.Parent = gui
    rounded(creditsPanel, 14)

    local credits = makeText(creditsPanel, "◈ 0", 13)
    credits.Size = UDim2.new(1, -14, 1, 0)
    credits.Position = UDim2.fromOffset(7, 0)

    local vitals = Instance.new("Frame")
    vitals.Size = UDim2.fromOffset(286, 54)
    vitals.Position = UDim2.new(0, 18, 1, -18)
    vitals.AnchorPoint = Vector2.new(0, 1)
    vitals.BackgroundTransparency = 1
    vitals.Parent = gui

    local hpBack = Instance.new("Frame")
    hpBack.Size = UDim2.fromOffset(236, 8)
    hpBack.Position = UDim2.fromOffset(48, 27)
    hpBack.BackgroundColor3 = Color3.fromRGB(31, 38, 54)
    hpBack.BorderSizePixel = 0
    hpBack.Parent = vitals
    rounded(hpBack, 4)

    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.BackgroundColor3 = Color3.fromRGB(106, 235, 163)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBack
    rounded(hpFill, 4)

    local hpText = makeText(vitals, "HP 100 / 100", 8, false)
    hpText.Size = UDim2.fromOffset(236, 18)
    hpText.Position = UDim2.fromOffset(48, 6)

    local attack = Instance.new("TextButton")
    attack.Size = UDim2.fromOffset(84, 84)
    attack.Position = UDim2.new(0.5, -90, 1, -18)
    attack.AnchorPoint = Vector2.new(0.5, 1)
    attack.BackgroundColor3 = Color3.fromRGB(22, 27, 39)
    attack.Text = "ATTACK"
    attack.TextColor3 = Color3.fromRGB(245, 247, 252)
    attack.Font = Enum.Font.GothamBold
    attack.TextSize = 9
    attack.AutoButtonColor = true
    attack.Parent = gui
    rounded(attack, 42)

    local dash = Instance.new("TextButton")
    dash.Size = UDim2.fromOffset(72, 72)
    dash.Position = UDim2.new(0.5, 48, 1, -24)
    dash.AnchorPoint = Vector2.new(0.5, 1)
    dash.BackgroundColor3 = Color3.fromRGB(22, 27, 39)
    dash.Text = "DASH"
    dash.TextColor3 = Color3.fromRGB(245, 247, 252)
    dash.Font = Enum.Font.GothamBold
    dash.TextSize = 8
    dash.AutoButtonColor = true
    dash.Parent = gui
    rounded(dash, 36)

    fallback = gui

    local function refresh()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hp = humanoid and humanoid.Health or 0
        local maxHp = humanoid and humanoid.MaxHealth or 100
        local waveValue = tonumber(workspace:GetAttribute("CollisionWave")) or 0
        local enemyValue = tonumber(workspace:GetAttribute("CollisionEnemies")) or 0

        wave.Text = ("WAVE %02d"):format(waveValue)
        enemies.Text = ("%d HOSTILES"):format(enemyValue)
        credits.Text = "◈ " .. tostring(player:GetAttribute("Credits") or 0)
        hpText.Text = ("HP %d / %d"):format(math.floor(hp + 0.5), math.floor(maxHp + 0.5))
        hpFill.Size = UDim2.fromScale(maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0, 1)
        stats.Text = ("DMG %d   DEF %d   SPD %d"):format(
            player:GetAttribute("DamageLevel") or 0,
            player:GetAttribute("DefenseLevel") or 0,
            player:GetAttribute("SpeedLevel") or 0
        )
    end

    local function hookCharacter(character: Model)
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 8)
        if humanoid then
            humanoid.HealthChanged:Connect(refresh)
            humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(refresh)
        end
        refresh()
    end

    player.CharacterAdded:Connect(hookCharacter)
    workspace:GetAttributeChangedSignal("CollisionWave"):Connect(refresh)
    workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(refresh)
    player:GetAttributeChangedSignal("Credits"):Connect(refresh)
    player:GetAttributeChangedSignal("DamageLevel"):Connect(refresh)
    player:GetAttributeChangedSignal("DefenseLevel"):Connect(refresh)
    player:GetAttributeChangedSignal("SpeedLevel"):Connect(refresh)

    if player.Character then
        task.spawn(hookCharacter, player.Character)
    end

    refresh()
end

local function destroyFallback()
    if fallback then
        fallback:Destroy()
        fallback = nil
    end
end

local function tryBoot()
    if booting then
        return
    end

    booting = true

    for attempt = 1, 18 do
        local ok, controller = pcall(function()
            return require(root:WaitForChild("UIController", 12))
        end)

        if ok and controller then
            local initialized = pcall(function()
                controller:Init()
            end)

            if initialized and playerGui:FindFirstChild("CollisionBattlestarHUD") then
                player:SetAttribute("CollisionHUDReady", true)
                destroyFallback()
                booting = false
                return
            end
        end

        task.wait(math.min(1.5, 0.25 + attempt * 0.05))
    end

    if not fallback then
        makeFallback()
    end

    booting = false
end

task.spawn(function()
    task.wait(2)
    tryBoot()
end)

task.spawn(function()
    local input = root:FindFirstChild("InputController")
    if input then
        pcall(function()
            require(input):Init()
        end)
    end
end)

player.CharacterAdded:Connect(function()
    task.delay(1, tryBoot)
end)

task.spawn(function()
    while player.Parent do
        task.wait(4)
        local gui = playerGui:FindFirstChild("CollisionBattlestarHUD")
        if gui and gui:IsA("ScreenGui") then
            gui.Enabled = true
            destroyFallback()
        elseif not booting then
            task.spawn(tryBoot)
        end
    end
end)
