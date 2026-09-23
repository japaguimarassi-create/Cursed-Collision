--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Emotes.EmoteDefinitions)

local HUDEmoteWheel = {}
HUDEmoteWheel.__index = HUDEmoteWheel

local player = Players.LocalPlayer

function HUDEmoteWheel.new(core: any)
    local root = Instance.new("Frame")
    root.Name = "EmoteWheelLayer"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.Visible = false
    root.Parent = core.Root

    local wheel = Instance.new("Frame")
    wheel.Name = "Wheel"
    wheel.Size = UDim2.fromScale(0.58, 0.64)
    wheel.Position = UDim2.fromScale(0.50, 0.50)
    wheel.AnchorPoint = Vector2.new(0.5, 0.5)
    wheel.BackgroundColor3 = core.Palette.Surface
    wheel.BackgroundTransparency = 0.08
    wheel.BorderSizePixel = 0
    wheel.Parent = root

    local wc = Instance.new("UICorner")
    wc.CornerRadius = UDim.new(0, 24)
    wc.Parent = wheel

    local title = core:Label(wheel, "Title", "EMOTES")
    title.Size = UDim2.fromScale(0.36, 0.12)
    title.Position = UDim2.fromScale(0.32, 0.44)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16

    local center = core:Button(wheel, "Close", "CLOSE")
    center.Size = UDim2.fromScale(0.22, 0.12)
    center.Position = UDim2.fromScale(0.39, 0.57)
    center.Activated:Connect(function()
        self:Close()
    end)

    local ids = {"emote_001", "emote_002", "emote_003", "emote_004", "emote_005"}
    local buttons = {}

    for index = 1, 5 do
        local angle = math.rad(-90 + (index - 1) * 72)
        local button = core:Button(wheel, "Slot" .. index, "")
        button.Size = UDim2.fromScale(0.24, 0.18)
        button.Position = UDim2.fromScale(
            0.50 + math.cos(angle) * 0.38,
            0.50 + math.sin(angle) * 0.38
        )
        button.AnchorPoint = Vector2.new(0.5, 0.5)

        local id = ids[index]
        local info = Definitions[id]
        button.Text = tostring(index) .. "\n" .. (info and info.Name or id)
        button.Activated:Connect(function()
            local remotes = ReplicatedStorage:WaitForChild("Remotes")
            remotes.EmoteAction:FireServer("Start", {Id = id})
            self:Close()
        end)
        buttons[index] = button
    end

    self.Root = root
    self.Buttons = buttons
    self.Opened = false
    return setmetatable(self, HUDEmoteWheel)
end

function HUDEmoteWheel:Open()
    player:SetAttribute("CCHUD_EmoteWheelOpen", true)
    player:SetAttribute("CCHUD_MenuOpen", true)
    self.Root.Visible = true
    self.Opened = true
end

function HUDEmoteWheel:Close()
    self.Root.Visible = false
    self.Opened = false
    player:SetAttribute("CCHUD_EmoteWheelOpen", false)
    player:SetAttribute("CCHUD_MenuOpen", false)
end

function HUDEmoteWheel:Toggle()
    if self.Opened then
        self:Close()
    else
        self:Open()
    end
end

return HUDEmoteWheel
