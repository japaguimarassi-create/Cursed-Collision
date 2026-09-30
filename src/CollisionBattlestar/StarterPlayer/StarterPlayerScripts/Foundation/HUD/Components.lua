--!strict

local Theme = require(script.Parent:WaitForChild("Theme"))

local Components = {}

function Components.Panel(parent: Instance, name: string, size: UDim2, position: UDim2, radius: number?): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Theme.Colors.Panel
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Theme.Corner(frame, radius or 14)
    Theme.Stroke(frame, Theme.Colors.Stroke, 1.1, 0.3)
    Theme.Shadow(frame, radius or 14)
    return frame
end

function Components.Label(
    parent: Instance,
    name: string,
    text: string,
    size: UDim2,
    position: UDim2,
    textSize: number,
    color: Color3?,
    heavy: boolean?
): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = if heavy then Theme.FontHeavy else Theme.Font
    label.Text = text
    label.TextColor3 = color or Theme.Colors.Text
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = false
    label.Parent = parent
    return label
end

function Components.Button(
    parent: Instance,
    name: string,
    text: string,
    size: UDim2,
    position: UDim2,
    fill: Color3,
    textSize: number,
    radius: number?
): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = fill
    button.BackgroundTransparency = 0.04
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Theme.FontHeavy
    button.Text = text
    button.TextColor3 = Theme.Colors.Text
    button.TextSize = textSize
    button.TextWrapped = true
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.TextYAlignment = Enum.TextYAlignment.Center
    button.Parent = parent
    Theme.Corner(button, radius or 12)
    Theme.Stroke(button, Theme.Colors.Stroke, 1.2, 0.18)
    return button
end

function Components.StatChip(
    parent: Instance,
    name: string,
    title: string,
    value: string,
    width: number,
    accent: Color3
): Frame
    local chip = Instance.new("Frame")
    chip.Name = name
    chip.Size = UDim2.fromOffset(width, 46)
    chip.BackgroundColor3 = Theme.Colors.PanelSoft
    chip.BackgroundTransparency = 0.06
    chip.BorderSizePixel = 0
    chip.Parent = parent
    Theme.Corner(chip, 11)
    Theme.Stroke(chip, accent, 1, 0.55)

    local titleLabel = Components.Label(chip, "Title", title, UDim2.new(1, -16, 0, 16), UDim2.fromOffset(8, 3), 10, Theme.Colors.Muted, true)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Components.Label(chip, "Value", value, UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 18), 15, accent, true)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left

    return chip
end

function Components.ProgressBar(parent: Instance, name: string, size: UDim2, position: UDim2, fill: Color3): (Frame, Frame)
    local shell = Instance.new("Frame")
    shell.Name = name
    shell.Size = size
    shell.Position = position
    shell.BackgroundColor3 = Theme.Colors.Background
    shell.BackgroundTransparency = 0.12
    shell.BorderSizePixel = 0
    shell.ClipsDescendants = true
    shell.Parent = parent
    Theme.Corner(shell, 8)
    Theme.Stroke(shell, Theme.Colors.Stroke, 1, 0.6)

    local fillFrame = Instance.new("Frame")
    fillFrame.Name = "Fill"
    fillFrame.Size = UDim2.fromScale(1, 1)
    fillFrame.BackgroundColor3 = fill
    fillFrame.BorderSizePixel = 0
    fillFrame.Parent = shell
    Theme.Corner(fillFrame, 8)

    return shell, fillFrame
end

return Components
