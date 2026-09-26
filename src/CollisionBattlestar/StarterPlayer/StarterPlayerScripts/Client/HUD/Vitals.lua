--!strict

local Players = game:GetService("Players")

local Vitals = {}

function Vitals.Mount(root, config, player)
    local panel = root.Panel(root.Gui, UDim2.fromOffset(250, 70), UDim2.new(0, 20, 1, -112))

    local value = root.Label(panel, "HP 100 / 100", 13)
    value.Size = UDim2.new(1, -20, 0, 23)
    value.Position = UDim2.fromOffset(10, 4)

    local bar = Instance.new("Frame")
    bar.Name = "HealthBar"
    bar.Size = UDim2.new(1, -20, 0, 9)
    bar.Position = UDim2.fromOffset(10, 34)
    bar.BackgroundColor3 = Color3.fromRGB(32, 36, 44)
    bar.BorderSizePixel = 0
    bar.Parent = panel
    root.Rounded(bar, 6)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = config.UI.Good
    fill.BorderSizePixel = 0
    fill.Parent = bar
    root.Rounded(fill, 6)

    local characterConnection

    local function bind(character)
        if characterConnection then
            characterConnection:Disconnect()
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 8)
        if not humanoid then
            return
        end

        local function refresh()
            local ratio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
            value.Text = ("HP %d / %d"):format(math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5))
            fill.Size = UDim2.fromScale(ratio, 1)
            fill.BackgroundColor3 = ratio > 0.55 and config.UI.Good or (ratio > 0.25 and config.UI.Warning or config.UI.Danger)
        end

        characterConnection = humanoid.HealthChanged:Connect(refresh)
        refresh()
    end

    player.CharacterAdded:Connect(bind)
    if player.Character then
        task.spawn(bind, player.Character)
    end

    return {
        Value = value,
        Fill = fill,
    }
end

return Vitals
