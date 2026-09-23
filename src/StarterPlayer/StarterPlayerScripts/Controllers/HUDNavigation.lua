--!strict

local HUDNavigation = {}
HUDNavigation.__index = HUDNavigation

function HUDNavigation.new(core: any, openMenu: (string) -> ())
    local root = Instance.new("Frame")
    root.Name = "Navigation"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Parent = core.Root

    local left = Instance.new("Frame")
    left.Size = UDim2.fromScale(0.31, 0.065)
    left.Position = UDim2.fromScale(0.020, 0.018)
    left.BackgroundTransparency = 1
    left.Parent = root

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.Parent = left

    local logo = core:Button(left, "Logo", "CC")
    logo.Size = UDim2.fromOffset(52, 48)
    logo.TextSize = 14

    local characters = core:Button(left, "Characters", "CHARACTERS")
    characters.Size = UDim2.fromOffset(112, 48)
    characters.Activated:Connect(function()
        openMenu("Characters")
    end)

    local emotes = core:Button(left, "Emotes", "EMOTES")
    emotes.Size = UDim2.fromOffset(88, 48)
    emotes.Activated:Connect(function()
        openMenu("Emotes")
    end)

    local right = Instance.new("Frame")
    right.Size = UDim2.fromScale(0.26, 0.065)
    right.Position = UDim2.fromScale(0.974, 0.018)
    right.AnchorPoint = Vector2.new(1, 0)
    right.BackgroundTransparency = 1
    right.Parent = root

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Horizontal
    rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rightLayout.Padding = UDim.new(0, 6)
    rightLayout.Parent = right

    local leaderboard = core:Button(right, "Leaderboard", "PLAYERS")
    leaderboard.Size = UDim2.fromOffset(92, 48)
    leaderboard.Activated:Connect(function()
        openMenu("Leaderboard")
    end)

    local menu = core:Button(right, "Menu", "MENU")
    menu.Size = UDim2.fromOffset(78, 48)
    menu.Activated:Connect(function()
        openMenu("Menu")
    end)

    return setmetatable({
        Root = root,
        Buttons = {
            Characters = characters,
            Emotes = emotes,
            Leaderboard = leaderboard,
            Menu = menu
        }
    }, HUDNavigation)
end

return HUDNavigation
