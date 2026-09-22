-- UI controller

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

    local value = guiObject:FindFirstChildOfClass("UIScale") :: UIScale?
    if not value then
        local created = Instance.new("UIScale")
        created.Scale = original
        created.Parent = guiObject
        value = created
    end

    local uiScale = value :: UIScale
    uiScale.Scale = original + (scale or 0.06)
    TweenService:Create(uiScale, TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = original
    }):Play()
end

function UIController:SetEnabled(guiObject: GuiObject, enabled: boolean)
    if guiObject then
        guiObject.Visible = enabled
    end
end

return UIController
