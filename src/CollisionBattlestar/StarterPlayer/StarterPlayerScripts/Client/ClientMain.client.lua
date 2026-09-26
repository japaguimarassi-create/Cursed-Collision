--!strict
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local root = script.Parent

local fallback: ScreenGui? = nil
local booting = false

local function makeFallback()
    if fallback and fallback.Parent then
        return
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "CollisionBattlestarHUDFallback"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 95
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    gui.Parent = playerGui

    local top = Instance.new("Frame")
    top.Size = UDim2.fromOffset(250, 62)
    top.Position = UDim2.fromOffset(18, 18)
    top.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
    top.BackgroundTransparency = 0.06
    top.BorderSizePixel = 0
    top.Parent = gui
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 16)
    topCorner.Parent = top

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -28, 0, 24)
    title.Position = UDim2.fromOffset(14, 8)
    title.Font = Enum.Font.GothamBold
    title.Text = "COLLISION BATTLESTAR"
    title.TextColor3 = Color3.fromRGB(245, 247, 252)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = top

    local state = Instance.new("TextLabel")
    state.BackgroundTransparency = 1
    state.Size = UDim2.new(1, -28, 0, 18)
    state.Position = UDim2.fromOffset(14, 32)
    state.Font = Enum.Font.GothamMedium
    state.Text = "CONNECTING HUD"
    state.TextColor3 = Color3.fromRGB(151, 162, 181)
    state.TextSize = 8
    state.TextXAlignment = Enum.TextXAlignment.Left
    state.Parent = top

    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.fromOffset(286, 54)
    bottom.Position = UDim2.new(0, 18, 1, -18)
    bottom.AnchorPoint = Vector2.new(0, 1)
    bottom.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
    bottom.BackgroundTransparency = 0.06
    bottom.BorderSizePixel = 0
    bottom.Parent = gui
    local bottomCorner = Instance.new("UICorner")
    bottomCorner.CornerRadius = UDim.new(0, 16)
    bottomCorner.Parent = bottom

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(1, -24, 1, 0)
    status.Position = UDim2.fromOffset(12, 0)
    status.Font = Enum.Font.GothamBold
    status.Text = "WAVE 0   •   0 TARGETS   •   HP 100"
    status.TextColor3 = Color3.fromRGB(245, 247, 252)
    status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = bottom

    fallback = gui

    local function refresh()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local hp = humanoid and math.floor(humanoid.Health + 0.5) or 0
        local wave = workspace:GetAttribute("CollisionWave") or 0
        local enemies = workspace:GetAttribute("CollisionEnemies") or 0
        status.Text = ("WAVE %d   •   %d TARGETS   •   HP %d"):format(wave, enemies, hp)
    end

    workspace:GetAttributeChangedSignal("CollisionWave"):Connect(refresh)
    workspace:GetAttributeChangedSignal("CollisionEnemies"):Connect(refresh)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 8)
        if humanoid then
            humanoid.HealthChanged:Connect(refresh)
        end
        refresh()
    end)
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthChanged:Connect(refresh)
        end
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
    makeFallback()

    for attempt = 1, 24 do
        local ok, controller = pcall(function()
            return require(root:WaitForChild("UIController", 8))
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
        task.wait(math.min(1.25, 0.2 + attempt * 0.04))
    end
    booting = false
end

task.spawn(tryBoot)

task.spawn(function()
    local input = root:FindFirstChild("InputController")
    if input then
        pcall(function()
            require(input):Init()
        end)
    end
end)

player.CharacterAdded:Connect(function()
    task.delay(0.8, tryBoot)
end)

task.spawn(function()
    while player.Parent do
        task.wait(4)
        local gui = playerGui:FindFirstChild("CollisionBattlestarHUD")
        if not gui or not gui:IsA("ScreenGui") then
            task.spawn(tryBoot)
        else
            gui.Enabled = true
        end
    end
end)
