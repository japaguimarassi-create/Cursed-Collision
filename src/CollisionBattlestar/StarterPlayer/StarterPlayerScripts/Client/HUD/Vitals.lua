--!strict
local Players = game:GetService("Players")
local Vitals = {}

function Vitals.Mount(root, config, player)
    local holder = Instance.new("Frame")
    holder.Name = "Vitals"
    holder.Size = UDim2.fromOffset(330, 70)
    holder.Position = UDim2.new(0, 18, 1, -18)
    holder.AnchorPoint = Vector2.new(0, 1)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local avatarBack = root.Pill(holder, UDim2.fromOffset(52, 52), UDim2.fromOffset(0, 0), config.UI.Surface2, 0.04)
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(44, 44)
    avatar.Position = UDim2.fromOffset(4, 4)
    avatar.BackgroundTransparency = 1
    avatar.Parent = avatarBack
    root.Circle(avatar)

    local name = root.Label(holder, player.DisplayName, 11)
    name.Size = UDim2.fromOffset(220, 18)
    name.Position = UDim2.fromOffset(64, -1)

    local hpValue = root.Label(holder, "HP 100 / 100", 9, config.UI.Muted, Enum.Font.GothamMedium)
    hpValue.Size = UDim2.fromOffset(160, 18)
    hpValue.Position = UDim2.fromOffset(64, 18)

    local _, fill = root.Progress(holder, UDim2.fromOffset(250, 9), UDim2.fromOffset(64, 40), config.UI.Good, 4)

    local state = root.Label(holder, "READY", 8, config.UI.Good)
    state.Size = UDim2.fromOffset(64, 18)
    state.Position = UDim2.fromOffset(0, 53)

    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and image then
        avatar.Image = image
    end

    local characterConnection: RBXScriptConnection?
    local function bind(character: Model)
        if characterConnection then
            characterConnection:Disconnect()
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 8)
        if not humanoid then
            return
        end

        local function refresh()
            local maxHealth = humanoid.MaxHealth
            local health = humanoid.Health
            local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
            hpValue.Text = ("HP %d / %d"):format(math.floor(health + 0.5), math.floor(maxHealth + 0.5))
            fill.Size = UDim2.fromScale(ratio, 1)
            fill.BackgroundColor3 = if ratio > 0.55 then config.UI.Good elseif ratio > 0.25 then config.UI.Warning else config.UI.Danger
            state.Text = if ratio <= 0 then "DOWN" elseif ratio < 0.35 then "DANGER" else "READY"
            state.TextColor3 = if ratio <= 0 then config.UI.Danger elseif ratio < 0.35 then config.UI.Warning else config.UI.Good
        end

        characterConnection = humanoid.HealthChanged:Connect(refresh)
        humanoid.Died:Connect(function()
            if state.Parent then
                state.Text = "DOWN"
                state.TextColor3 = config.UI.Danger
            end
        end)
        refresh()
    end

    player.CharacterAdded:Connect(bind)
    if player.Character then
        task.spawn(bind, player.Character)
    end

    root.AnimateIn(holder, "Left")
    return {Holder = holder, Avatar = avatar, Name = name, Value = hpValue, Fill = fill, State = state}
end

return Vitals
