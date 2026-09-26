--!strict
local Admin={}
function Admin.Mount(root,config,player,remote)
    if player:GetAttribute("IsOwner")~=true then return nil end
    local button=root.Button(root.Gui,"AdminMenuButton","CONTROL",UDim2.fromOffset(128,42)); button.Position=UDim2.fromOffset(20,112); button.BackgroundColor3=config.UI.Danger; button.TextSize=9
    local panel=root.Panel(root.Gui,UDim2.fromOffset(278,286),UDim2.fromOffset(20,160)); panel.Name="AdminMenuPanel"; panel.Visible=false
    local title=root.Label(panel,"OWNER CONTROL",14); title.Size=UDim2.new(1,-30,0,28); title.Position=UDim2.fromOffset(15,10)
    local hint=root.Label(panel,"SERVER AUTHORITY",8,config.UI.Muted); hint.Size=UDim2.new(1,-30,0,18); hint.Position=UDim2.fromOffset(15,37)
    local list=Instance.new("Frame"); list.BackgroundTransparency=1; list.Size=UDim2.new(1,-24,1,-69); list.Position=UDim2.fromOffset(12,63); list.Parent=panel
    local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,7); layout.Parent=list
    local function action(name,text,order)
        local b=root.Button(list,"Action_"..name,text,UDim2.new(1,0,0,38)); b.LayoutOrder=order; b.Activated:Connect(function() remote:FireServer(name) end)
    end
    action("NextWave","NEXT WAVE",1); action("Reward","+1000 CREDITS",2); action("Heal","HEAL PLAYER",3); action("Clear","CLEAR ENEMIES",4)
    button.Activated:Connect(function() panel.Visible=not panel.Visible end)
    return {Button=button,Panel=panel}
end
return Admin