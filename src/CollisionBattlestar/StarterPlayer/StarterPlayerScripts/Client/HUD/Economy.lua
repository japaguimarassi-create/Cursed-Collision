--!strict
local TweenService=game:GetService("TweenService")
local Economy={}
function Economy.Mount(root,config,player)
    local panel=root.Panel(root.Gui,UDim2.fromOffset(238,78),UDim2.new(1,-20,0,18),Vector2.new(1,0)); panel.Name="Economy"
    local credits=root.Label(panel,"0",19); credits.Size=UDim2.new(1,-58,0,34); credits.Position=UDim2.fromOffset(18,7)
    local icon=root.Label(panel,"◈",17,config.UI.Warning); icon.Size=UDim2.fromOffset(28,28); icon.Position=UDim2.new(1,-43,0,8); icon.TextXAlignment=Enum.TextXAlignment.Center
    local stats=root.Label(panel,"DMG 0   DEF 0   SPD 0",9,config.UI.Muted); stats.Size=UDim2.new(1,-36,0,20); stats.Position=UDim2.fromOffset(18,43)
    local flash=Instance.new("Frame"); flash.BackgroundColor3=config.UI.Warning; flash.BackgroundTransparency=1; flash.Size=UDim2.fromScale(1,1); flash.BorderSizePixel=0; flash.ZIndex=panel.ZIndex+2; flash.Parent=panel; root.Rounded(flash,16)
    local function refresh()
        credits.Text=("%d"):format(player:GetAttribute("Credits") or 0)
        stats.Text=("DMG %d   DEF %d   SPD %d"):format(player:GetAttribute("DamageLevel") or 0,player:GetAttribute("DefenseLevel") or 0,player:GetAttribute("SpeedLevel") or 0)
    end
    local lastCredits=player:GetAttribute("Credits") or 0
    player:GetAttributeChangedSignal("Credits"):Connect(function()
        local current=player:GetAttribute("Credits") or 0
        if current~=lastCredits then
            flash.BackgroundTransparency=0.86
            TweenService:Create(flash,TweenInfo.new(0.35,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
        end
        lastCredits=current; refresh()
    end)
    for _,attribute in ipairs({"DamageLevel","DefenseLevel","SpeedLevel"}) do player:GetAttributeChangedSignal(attribute):Connect(refresh) end
    refresh(); root.AnimateIn(panel,"Right"); return {Credits=credits,Stats=stats}
end
return Economy