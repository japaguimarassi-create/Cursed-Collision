--!strict

local TweenService = game:GetService("TweenService")

local UIController = {}

function UIController:Pulse(guiObject: GuiObject, scale: number?)
    if not guiObject or not guiObject.Parent then
        return
    end

    local original = guiObject:GetAttribute("UIOriginalScale")
    if type(original) ~= "number" then
        original = 1
        guiObject:SetAttribute("UIOriginalScale", original)
    end

    local value = guiObject:FindFirstChildOfClass("UIScale")
    if not value then
        value = Instance.new("UIScale")
        value.Scale = original
        value.Parent = guiObject
    end

    value.Scale = original + (scale or 0.06)
    TweenService:Create(value, TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = original
    }):Play()
end

function UIController:SetEnabled(guiObject: GuiObject, enabled: boolean)
    if guiObject then
        guiObject.Visible = enabled
    end
end

return UIController
