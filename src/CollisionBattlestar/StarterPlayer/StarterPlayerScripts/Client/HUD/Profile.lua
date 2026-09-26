--!strict
local Players = game:GetService("Players")
local Profile = {}

function Profile.Mount(root, config, player)
    local holder = Instance.new("Frame")
    holder.Name = "Profile"
    holder.Size = UDim2.fromOffset(250, 58)
    holder.Position = UDim2.fromOffset(18, 18)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local avatarBack = root.Pill(holder, UDim2.fromOffset(44, 44), UDim2.fromOffset(0, 0), config.UI.Surface2, 0.04)
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(36, 36)
    avatar.Position = UDim2.fromOffset(4, 4)
    avatar.BackgroundTransparency = 1
    avatar.Parent = avatarBack
    root.Circle(avatar)

    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and image then
        avatar.Image = image
    end

    local name = root.Label(holder, player.DisplayName, 13)
    name.Size = UDim2.fromOffset(170, 22)
    name.Position = UDim2.fromOffset(56, 1)

    local state = root.Label(holder, "ONLINE", 8, config.UI.Good, Enum.Font.GothamMedium)
    state.Size = UDim2.fromOffset(68, 15)
    state.Position = UDim2.fromOffset(56, 25)

    local stats = root.Label(holder, "DMG 0  DEF 0  SPD 0", 8, config.UI.Muted, Enum.Font.GothamMedium)
    stats.Size = UDim2.fromOffset(170, 15)
    stats.Position = UDim2.fromOffset(56, 40)

    local function refresh()
        stats.Text = ("DMG %d   DEF %d   SPD %d"):format(
            player:GetAttribute("DamageLevel") or 0,
            player:GetAttribute("DefenseLevel") or 0,
            player:GetAttribute("SpeedLevel") or 0
        )
    end

    for _, attribute in ipairs({"DamageLevel", "DefenseLevel", "SpeedLevel"}) do
        player:GetAttributeChangedSignal(attribute):Connect(refresh)
    end
    refresh()
    root.AnimateIn(holder, "Left")
    return {Holder = holder, Avatar = avatar, Name = name, State = state, Stats = stats}
end

return Profile
