--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.HUDTheme)

local Widgets = {}

function Widgets.Corner(object: GuiObject, radius: number)
    local ui = Instance.new("UICorner")
    ui.CornerRadius = UDim.new(0, radius)
    ui.Parent = object
end

function Widgets.Stroke(object: GuiObject, transparency: number?)
    local ui = Instance.new("UIStroke")
    ui.Thickness = 1
    ui.Transparency = transparency or 0.55
    ui.Color = Theme.Colors.Border
    ui.Parent = object
end

function Widgets.Label(
    parent: Instance,
    textValue: string,
    size: UDim2,
    position: UDim2,
    textSize: number
): TextLabel
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Size = size
    object.Position = position
    object.Text = textValue
    object.TextColor3 = Theme.Colors.Text
    object.Font = Enum.Font.GothamBold
    object.TextSize = textSize
    object.TextWrapped = true
    object.TextXAlignment = Enum.TextXAlignment.Center
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

function Widgets.Button(
    parent: Instance,
    name: string,
    textValue: string,
    radius: number?
): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundColor3 = Theme.Colors.Surface
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.Text = textValue
    button.TextColor3 = Theme.Colors.Text
    button.Font = Enum.Font.GothamBlack
    button.TextSize = 11
    button.TextWrapped = true
    button.AutoButtonColor = false
    button.Active = true
    button.Selectable = true
    button.Parent = parent

    Widgets.Corner(button, radius or Theme.Radius.Medium)
    Widgets.Stroke(button, 0.56)

    button.Activated:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.06), {
            BackgroundColor3 = Theme.Colors.SurfacePressed
        }):Play()

        task.delay(0.09, function()
            if button.Parent then
                TweenService:Create(button, TweenInfo.new(0.10), {
                    BackgroundColor3 = Theme.Colors.Surface
                }):Play()
            end
        end)
    end)

    return button
end

function Widgets.IconButton(parent: Instance, name: string, icon: string): TextButton
    local holder = Instance.new("Frame")
    holder.Name = name .. "Holder"
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local button = Widgets.Button(holder, name, icon, Theme.Radius.Pill)
    button.TextSize = 19
    return button
end

function Widgets.Aspect(object: GuiObject, ratio: number)
    local constraint = Instance.new("UIAspectRatioConstraint")
    constraint.AspectRatio = ratio
    constraint.Parent = object
end

function Widgets.Dim(parent: Instance): Frame
    local dim = Instance.new("Frame")
    dim.Name = "Dim"
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Theme.Colors.Background
    dim.BackgroundTransparency = 0.28
    dim.BorderSizePixel = 0
    dim.Active = true
    dim.Parent = parent
    return dim
end

return Widgets
