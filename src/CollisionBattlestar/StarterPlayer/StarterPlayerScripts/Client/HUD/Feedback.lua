--!strict
local TweenService=game:GetService("TweenService")
local Feedback={}; local currentToken=0
function Feedback.Mount(root,config)
    local panel=root.Panel(root.Gui,UDim2.fromOffset(430,66),UDim2.new(0.5,0,1,-122),Vector2.new(0.5,1)); panel.Name="BattleFeedback"; panel.BackgroundTransparency=0.12
    local accent=Instance.new("Frame"); accent.Size=UDim2.fromOffset(4,42); accent.Position=UDim2.fromOffset(10,12); accent.BackgroundColor3=config.UI.Accent; accent.BorderSizePixel=0; accent.Parent=panel; root.Rounded(accent,2)
    local label=root.Label(panel,"READY",12,config.UI.Muted); label.Size=UDim2.new(1,-34,1,0); label.Position=UDim2.fromOffset(24,0); label.TextXAlignment=Enum.TextXAlignment.Center
    root.AnimateIn(panel,"Down"); return {Panel=panel,Label=label,Accent=accent}
end
function Feedback.Show(view,config,message,color,duration)
    currentToken+=1; local token=currentToken
    view.Label.Text=message; view.Label.TextColor3=color; view.Accent.BackgroundColor3=color; view.Panel.Visible=true; view.Panel.BackgroundTransparency=0.04; view.Label.TextTransparency=0
    local pulse=TweenService:Create(view.Panel,TweenInfo.new(0.12,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(450,70)}); pulse:Play()
    pulse.Completed:Connect(function() if view.Panel.Parent then TweenService:Create(view.Panel,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.fromOffset(430,66)}):Play() end end)
    if duration and duration>0 then task.delay(duration,function() if token==currentToken and view.Panel.Parent then TweenService:Create(view.Panel,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play(); TweenService:Create(view.Label,TweenInfo.new(0.22),{TextTransparency=1}):Play() end end) end
end
return Feedback