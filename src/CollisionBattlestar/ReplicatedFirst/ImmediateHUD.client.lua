--!strict
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)
local gui=Instance.new("ScreenGui")
gui.Name="CollisionBattlestarImmediateHUD"; gui.ResetOnSpawn=false; gui.DisplayOrder=60; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.Parent=player:WaitForChild("PlayerGui")
local scale=Instance.new("UIScale"); scale.Scale=0.9; scale.Parent=gui
local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(260,58); panel.Position=UDim2.fromScale(0.5,0); panel.AnchorPoint=Vector2.new(0.5,0); panel.BackgroundColor3=Color3.fromRGB(13,16,24); panel.BackgroundTransparency=0.03; panel.BorderSizePixel=0; panel.Parent=gui
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,16); corner.Parent=panel
local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(72,82,103); stroke.Transparency=0.2; stroke.Parent=panel
local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Size=UDim2.new(1,-32,0,24); title.Position=UDim2.fromOffset(16,8); title.Text="COLLISION BATTLESTAR"; title.TextColor3=Color3.fromRGB(245,247,252); title.Font=Enum.Font.GothamBold; title.TextSize=12; title.TextXAlignment=Enum.TextXAlignment.Center; title.Parent=panel
local state=Instance.new("TextLabel"); state.BackgroundTransparency=1; state.Size=UDim2.new(1,-32,0,18); state.Position=UDim2.fromOffset(16,31); state.Text="SYNCING BATTLE SYSTEMS"; state.TextColor3=Color3.fromRGB(151,162,181); state.Font=Enum.Font.GothamMedium; state.TextSize=8; state.TextXAlignment=Enum.TextXAlignment.Center; state.Parent=panel
TweenService:Create(panel,TweenInfo.new(0.34,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5,0.03)}):Play()
local function resize()
    local camera=workspace.CurrentCamera; if not camera then return end
    local viewport=camera.ViewportSize; scale.Scale=math.clamp(math.min(viewport.X/1200,viewport.Y/720),0.72,1.06)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()
task.spawn(function()
    while gui.Parent do
        RunService.Heartbeat:Wait()
        if player:GetAttribute("CollisionHUDReady")==true then
            TweenService:Create(panel,TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.fromScale(0.5,-0.08),BackgroundTransparency=1}):Play()
            task.wait(0.22)
            if gui.Parent then gui:Destroy() end
            break
        end
    end
end)