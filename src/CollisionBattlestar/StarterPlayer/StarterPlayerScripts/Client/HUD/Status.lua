--!strict
local TweenService = game:GetService("TweenService")
local Status = {}

function Status.Mount(root, config)
    local holder = Instance.new("Frame")
    holder.Name = "BattleStatus"
    holder.Size = UDim2.fromOffset(320, 64)
    holder.Position = UDim2.fromScale(0.5, 0)
    holder.AnchorPoint = Vector2.new(0.5, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local live = root.Pill(holder, UDim2.fromOffset(86, 22), UDim2.fromOffset(117, 0), config.UI.Surface2, 0.06)
    local liveText = root.Label(live, "LIVE", 8, config.UI.Good, Enum.Font.GothamBold)
    liveText.Size = UDim2.fromScale(1, 1)
    liveText.TextXAlignment = Enum.TextXAlignment.Center

    local wave = root.Label(holder, "WAVE 00", 20)
    wave.Size = UDim2.fromOffset(132, 26)
    wave.Position = UDim2.fromOffset(0, 22)

    local enemies = root.Label(holder, "0 HOSTILES", 9, config.UI.Muted, Enum.Font.GothamMedium)
    enemies.Size = UDim2.fromOffset(130, 18)
    enemies.Position = UDim2.fromOffset(190, 23)
    enemies.TextXAlignment = Enum.TextXAlignment.Right

    local _, progress = root.Progress(holder, UDim2.fromOffset(320, 5), UDim2.fromOffset(0, 58), config.UI.Accent, 3)

    local countdown = root.Label(holder, "", 9, config.UI.Warning, Enum.Font.GothamBold)
    countdown.Size = UDim2.fromOffset(140, 18)
    countdown.Position = UDim2.fromOffset(180, 42)
    countdown.TextXAlignment = Enum.TextXAlignment.Right
    countdown.Visible = false

    local function refreshProgress(currentWave, alive)
        local waveNumber = tonumber(currentWave) or 0
        local hostileCount = tonumber(alive) or 0
        local expected = math.min(config.Waves.FirstWaveEnemies + math.max(0, waveNumber - 1) * config.Waves.EnemyGrowth, config.Waves.MaxAliveEnemies)
        local ratio = if expected > 0 then math.clamp(hostileCount / expected, 0, 1) else 0
        progress.Size = UDim2.fromScale(ratio, 1)
    end

    local function pulse()
        local original = live.BackgroundColor3
        TweenService:Create(live, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = config.UI.Surface3}):Play()
        task.delay(0.14, function()
            if live.Parent then
                TweenService:Create(live, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundColor3 = original}):Play()
            end
        end)
    end

    root.AnimateIn(holder, "Up")
    return {
        Holder = holder,
        Live = liveText,
        Wave = wave,
        Enemies = enemies,
        Progress = progress,
        Countdown = countdown,
        RefreshProgress = refreshProgress,
        Pulse = pulse,
    }
end

return Status
