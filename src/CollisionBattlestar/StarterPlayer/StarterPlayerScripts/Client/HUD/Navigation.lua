--!strict
local Navigation={}
function Navigation.Mount(root,config,player,travel)
    local holder=Instance.new("Frame"); holder.Name="Navigation"; holder.BackgroundTransparency=1; holder.Size=UDim2.fromOffset(224,48); holder.Position=UDim2.new(1,-268,0,112); holder.Parent=root.Gui
    local zone=root.Badge(holder,"PVE",config.UI.Good); zone.Size=UDim2.fromOffset(66,30); zone.Position=UDim2.fromOffset(0,9)
    local button=root.Button(holder,"BattlegroundsButton","BATTLEGROUNDS",UDim2.fromOffset(148,42)); button.Position=UDim2.fromOffset(76,3); button.TextSize=9
    local function refresh()
        local current=player:GetAttribute("Zone") or "PvE"; local pvp=current=="PvP"
        zone.Text=pvp and "PVP" or "PVE"; zone.TextColor3=pvp and config.UI.Danger or config.UI.Good; zone.BackgroundColor3=pvp and config.UI.Danger or config.UI.Good; zone.BackgroundTransparency=0.84
        button.Text=pvp and "RETURN TO CITY" or "BATTLEGROUNDS"
    end
    button.Activated:Connect(function() local current=player:GetAttribute("Zone") or "PvE"; travel:FireServer(current=="PvP" and "PvE" or "PvP") end)
    player:GetAttributeChangedSignal("Zone"):Connect(refresh); refresh(); root.AnimateIn(holder,"Right"); return {Travel=button,Zone=zone}
end
return Navigation