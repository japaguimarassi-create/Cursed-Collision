--!strict
local TweenService = game:GetService("TweenService")
local Feedback = {}
local currentToken = 0

function Feedback.Mount(root, config)
    local holder = Instance.new("Frame")
    holder.Name = "BattleFeedback"
    holder.Size = UDim2.fromOffset(360, 40)
    holder.Position = UDim2.new(0.5, 0, 1, -128)
    holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.BackgroundTransparency = 1
    holder.Parent = root.Gui

    local line = Instance.new("Frame")
    line.Size = UDim2.fromOffset(4, 28)
    line.Position = UDim2.fromOffset(0, 6)
    line.BackgroundColor3 = config.UI.Accent
    line.BorderSizePixel = 0
    line.Parent = holder
    root.Rounded(line, 2)

    local label = root.Label(holder, "READY", 11, config.UI.Muted)
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Position = UDim2.fromOffset(14, 0)
    label.TextXAlignment = Enum.TextXAlignment.Center

    root.AnimateIn(holder, "Down")
    return {Holder = holder, Label = label, Accent = line}
end

function Feedback.Show(view, config, message, color, duration)
    currentToken += 1
    local token = currentToken
    view.Label.Text = message
    view.Label.TextColor3 = color
    view.Accent.BackgroundColor3 = color
    view.Label.TextTransparency = 0
    view.Holder.Visible = true
    view.Holder.Position = UDim2.new(0.5, 0, 1, -128)

    local pulse = TweenService:Create(view.Holder, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 1, -134),
    })
    pulse:Play()

    if duration and duration > 0 then
        task.delay(duration, function()
            if token ~= currentToken or not view.Holder.Parent then
                return
            end
            TweenService:Create(view.Label, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        end)
    end
end

return Feedback
