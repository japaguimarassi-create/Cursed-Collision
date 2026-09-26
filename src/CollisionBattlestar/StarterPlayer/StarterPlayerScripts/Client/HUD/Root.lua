--!strict
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Root={}
local function tween(object,info,goal) return TweenService:Create(object,info,goal) end
function Root.Create(player:Player):ScreenGui
    local playerGui=player:WaitForChild("PlayerGui")
    local old=playerGui:FindFirstChild("CollisionBattlestarHUD")
    if old then old:Destroy() end
    local gui=Instance.new("ScreenGui")
    gui.Name="CollisionBattlestarHUD"; gui.ResetOnSpawn=false; gui.DisplayOrder=70; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.Parent=playerGui
    local scale=Instance.new("UIScale"); scale.Name="ResponsiveScale"; scale.Parent=gui
    local function refresh()
        local camera=workspace.CurrentCamera
        if not camera then return end
        local v=camera.ViewportSize
        scale.Scale=math.clamp(math.min(v.X/1200,v.Y/720),0.72,1.06)
    end
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh) end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local c=workspace.CurrentCamera
        if c then c:GetPropertyChangedSignal("ViewportSize"):Connect(refresh) end
        refresh()
    end)
    refresh()
    player:SetAttribute("CollisionHUDRootReady",true)
    return gui
end
function Root.Rounded(parent:Instance,radius:number)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,radius); c.Parent=parent
end
function Root.Stroke(parent:Instance,color:Color3?,transparency:number?,thickness:number?)
    local s=Instance.new("UIStroke"); s.Color=color or Config.UI.Stroke; s.Transparency=transparency or 0.2; s.Thickness=thickness or 1; s.Parent=parent; return s
end
function Root.Gradient(parent:Instance,a:Color3,b:Color3,rotation:number?)
    local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(a,b); g.Rotation=rotation or 0; g.Parent=parent; return g
end
function Root.Shadow(parent:Instance)
    local s=Instance.new("ImageLabel"); s.Name="Shadow"; s.BackgroundTransparency=1; s.Image="rbxassetid://5028857084"; s.ImageTransparency=0.72; s.ScaleType=Enum.ScaleType.Slice; s.SliceCenter=Rect.new(24,24,276,276); s.Size=UDim2.new(1,34,1,34); s.Position=UDim2.fromOffset(-17,-10); s.ZIndex=math.max(0,parent.ZIndex-1); s.Parent=parent; return s
end
function Root.Panel(parent:Instance,size:UDim2,position:UDim2,anchorPoint:Vector2?,transparency:number?)
    local f=Instance.new("Frame"); f.Size=size; f.Position=position; f.AnchorPoint=anchorPoint or Vector2.zero; f.BackgroundColor3=Config.UI.Surface; f.BackgroundTransparency=transparency or 0.06; f.BorderSizePixel=0; f.Parent=parent
    Root.Rounded(f,16); Root.Stroke(f,nil,0.22); Root.Shadow(f); Root.Gradient(f,Config.UI.Surface2,Config.UI.Surface,90); return f
end
function Root.Label(parent:Instance,value:string,size:number,color:Color3?,font:Enum.Font?)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=value; l.TextColor3=color or Config.UI.Text; l.Font=font or Enum.Font.GothamBold; l.TextSize=size; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Center; l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=parent; return l
end
function Root.Button(parent:Instance,name:string,value:string,size:UDim2)
    local b=Instance.new("TextButton"); b.Name=name; b.Size=size; b.BackgroundColor3=Config.UI.Surface2; b.BackgroundTransparency=0.04; b.Text=value; b.TextColor3=Config.UI.Text; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.AutoButtonColor=false; b.BorderSizePixel=0; b.Parent=parent
    Root.Rounded(b,14); Root.Stroke(b,nil,0.24)
    local s=Instance.new("UIScale"); s.Scale=1; s.Parent=b
    b.MouseEnter:Connect(function() tween(s,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{Scale=1.025}):Play(); tween(b,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{BackgroundColor3=Config.UI.Surface3}):Play() end)
    b.MouseLeave:Connect(function() tween(s,TweenInfo.new(0.14,Enum.EasingStyle.Quad),{Scale=1}):Play(); tween(b,TweenInfo.new(0.14,Enum.EasingStyle.Quad),{BackgroundColor3=Config.UI.Surface2}):Play() end)
    b.Activated:Connect(function()
        local d=tween(s,TweenInfo.new(0.055,Enum.EasingStyle.Quad),{Scale=0.94}); d:Play()
        d.Completed:Connect(function() if b.Parent then tween(s,TweenInfo.new(0.18,Enum.EasingStyle.Back),{Scale=1}):Play() end end)
    end)
    return b
end
function Root.Badge(parent:Instance,text:string,color:Color3)
    local b=Instance.new("TextLabel"); b.Size=UDim2.fromOffset(76,24); b.BackgroundColor3=color; b.BackgroundTransparency=0.84; b.Text=text; b.TextColor3=color; b.Font=Enum.Font.GothamBold; b.TextSize=9; b.TextXAlignment=Enum.TextXAlignment.Center; b.TextYAlignment=Enum.TextYAlignment.Center; b.BorderSizePixel=0; b.Parent=parent
    Root.Rounded(b,8); Root.Stroke(b,color,0.55); return b
end
function Root.AnimateIn(object:GuiObject,direction:string?)
    local target=object.Position
    local x=if direction=="Left" then -28 elseif direction=="Right" then 28 else 0
    local y=if direction=="Up" then -28 elseif direction=="Down" then 28 else 0
    object.Position=UDim2.new(target.X.Scale,target.X.Offset+x,target.Y.Scale,target.Y.Offset+y)
    local transparency=object.BackgroundTransparency
    object.BackgroundTransparency=math.min(1,transparency+0.35)
    tween(object,TweenInfo.new(0.34,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=target,BackgroundTransparency=transparency}):Play()
end
function Root.Progress(parent:Instance,size:UDim2,position:UDim2,fillColor:Color3,radius:number?)
    local back=Instance.new("Frame"); back.Size=size; back.Position=position; back.BackgroundColor3=Color3.fromRGB(35,40,52); back.BorderSizePixel=0; back.Parent=parent; Root.Rounded(back,radius or 7)
    local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=fillColor; fill.BorderSizePixel=0; fill.Parent=back; Root.Rounded(fill,radius or 7)
    return back,fill
end
return Root