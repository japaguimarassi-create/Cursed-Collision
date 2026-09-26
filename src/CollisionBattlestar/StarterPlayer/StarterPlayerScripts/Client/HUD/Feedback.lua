--!strict

local Feedback = {}
local currentToken = 0

function Feedback.Mount(root, config)
    local panel = root.Panel(root.Gui, UDim2.fromOffset(390, 56), UDim2.new(0.5, 0, 1, -34), Vector2.new(0.5, 1))
    local label = root.Label(panel, "Prepare-se.", 11, config.UI.Muted)
    label.Size = UDim2.new(1, -18, 1, -8)
    label.Position = UDim2.fromOffset(9, 4)
    label.TextXAlignment = Enum.TextXAlignment.Center

    return label
end

function Feedback.Show(label, config, message, color, duration)
    currentToken += 1
    local token = currentToken
    label.Text = message
    label.TextColor3 = color
    if duration and duration > 0 then
        task.delay(duration, function()
            if token == currentToken and label.Parent then
                label.Text = "Prepare-se."
                label.TextColor3 = config.UI.Muted
            end
        end)
    end
end

return Feedback
