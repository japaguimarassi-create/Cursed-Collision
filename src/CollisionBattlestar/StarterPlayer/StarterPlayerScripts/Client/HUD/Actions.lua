--!strict
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Actions={}
local function createAction(root,name,glyph,labelText,hint,accent)
    local button=root.Button(root.Gui,name,"",UDim2.fromOffset(118,78))
    local glow=Instance.new("Frame"); glow.Size=UDim2.fromScale(1,1); glow.BackgroundColor3=accent; glow.BackgroundTransparency=0.92; glow.BorderSizePixel=0; glow.ZIndex=button.ZIndex+1; glow.Parent=button; root.Rounded(glow,14)
    local icon=root.Label(button,glyph,23,accent); icon.Size=UDim2.fromOffset(38,38); icon.Position=UDim2.fromOffset(12,9); icon.ZIndex=button.ZIndex+2; icon.TextXAlignment=Enum.TextXAlignment.Center
    local label=root.Label(button,labelText,11); label.Size=UDim2.fromOffset(62,22); label.Position=UDim2.fromOffset(51,8); label.ZIndex=button.ZIndex+2
    local key=root.Label(button,hint,8,Config.UI.Muted); key.Size=UDim2.fromOffset(62,18); key.Position=UDim2.fromOffset(51,30); key.ZIndex=button.ZIndex+2
    local cooldown=Instance.new("Frame"); cooldown.Size=UDim2.fromScale(1,1); cooldown.BackgroundColor3=Config.UI.Background; cooldown.BackgroundTransparency=0.3; cooldown.BorderSizePixel=0; cooldown.ZIndex=button.ZIndex+3; cooldown.Visible=false; cooldown.Parent=button; root.Rounded(cooldown,14)
    local cooldownText=root.Label(cooldown,"",12,Config.UI.Text); cooldownText.Size=UDim2.fromScale(1,1); cooldownText.TextXAlignment=Enum.TextXAlignment.Center; cooldownText.ZIndex=button.ZIndex+4
    local nextReady=0; local duration=if name=="M1" then Config.Combat.M1.Cooldown+0.035 else Config.Combat.Dash.Cooldown+0.08
    local function activate()
        if os.clock()<nextReady then return false end
        nextReady=os.clock()+duration; cooldown.Visible=true; cooldown.Size=UDim2.fromScale(1,1)
        TweenService:Create(cooldown,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,0)}):Play()
        task.spawn(function()
            while cooldown.Parent and os.clock()<nextReady do cooldownText.Text=("%.1f"):format(math.max(0,nextReady-os.clock())); task.wait(0.05) end
            if cooldown.Parent then cooldown.Visible=false; cooldownText.Text="" end
        end)
        glow.BackgroundTransparency=0.7; TweenService:Create(glow,TweenInfo.new(0.24,Enum.EasingStyle.Quint),{BackgroundTransparency=0.94}):Play()
        return true
    end
    return {Button=button,Activate=activate}
end
function Actions.Mount(root)
    local holder=Instance.new("Frame"); holder.Name="ActionBar"; holder.BackgroundTransparency=1; holder.Size=UDim2.fromOffset(252,90); holder.Position=UDim2.new(0.5,0,1,-20); holder.AnchorPoint=Vector2.new(0.5,1); holder.Parent=root.Gui
    local m1=createAction(root,"M1","⚔","ATTACK","CLICK / R2",Config.UI.Accent)
    local dash=createAction(root,"Dash","↯","DASH","Q / B",Config.UI.Info)
    m1.Button.Parent=holder; dash.Button.Parent=holder; m1.Button.Position=UDim2.fromOffset(0,0); dash.Button.Position=UDim2.fromOffset(126,0)
    root.AnimateIn(holder,"Down")
    return {M1=m1,Dash=dash,Holder=holder}
end
return Actions