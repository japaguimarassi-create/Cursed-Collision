--!strict
local TweenService=game:GetService("TweenService")
local Status={}
function Status.Mount(root,config)
    local panel=root.Panel(root.Gui,UDim2.fromOffset(350,84),UDim2.fromScale(0.5,0),Vector2.new(0.5,0)); panel.Name="BattleStatus"
    local phase=root.Label(panel,"BATTLEFIELD",8,config.UI.Subtle); phase.Size=UDim2.fromOffset(160,18); phase.Position=UDim2.fromOffset(18,8)
    local wave=root.Label(panel,"WAVE 0",23); wave.Size=UDim2.fromOffset(170,36); wave.Position=UDim2.fromOffset(17,25)
    local enemies=root.Label(panel,"0 TARGETS",11,config.UI.Muted); enemies.Size=UDim2.fromOffset(145,22); enemies.Position=UDim2.new(1,-160,0,30); enemies.TextXAlignment=Enum.TextXAlignment.Right
    local accent=Instance.new("Frame"); accent.Size=UDim2.fromOffset(3,52); accent.Position=UDim2.fromOffset(9,19); accent.BackgroundColor3=config.UI.Accent; accent.BorderSizePixel=0; accent.Parent=panel; root.Rounded(accent,2)
    local zone=root.Label(root.Gui,"PVE",9,config.UI.Muted); zone.Size=UDim2.fromOffset(240,24); zone.Position=UDim2.fromOffset(22,92)
    local countdown=root.Label(panel,"",10,config.UI.Warning); countdown.Size=UDim2.fromOffset(140,20); countdown.Position=UDim2.new(1,-154,0,49); countdown.TextXAlignment=Enum.TextXAlignment.Right; countdown.Visible=false
    root.AnimateIn(panel,"Up")
    local function pulse()
        local original=accent.Size
        TweenService:Create(accent,TweenInfo.new(0.1,Enum.EasingStyle.Quad),{Size=UDim2.fromOffset(7,58),BackgroundColor3=config.UI.Warning}):Play()
        task.delay(0.12,function() if accent.Parent then TweenService:Create(accent,TweenInfo.new(0.26,Enum.EasingStyle.Quint),{Size=original,BackgroundColor3=config.UI.Accent}):Play() end end)
    end
    return {Panel=panel,Phase=phase,Wave=wave,Enemies=enemies,Zone=zone,Countdown=countdown,Pulse=pulse}
end
return Status