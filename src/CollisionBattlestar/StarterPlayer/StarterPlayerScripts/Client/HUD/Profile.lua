--!strict
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Profile={}
function Profile.Mount(root,config,player)
    local panel=root.Panel(root.Gui,UDim2.fromOffset(278,78),UDim2.fromOffset(20,18)); panel.Name="Profile"
    local avatar=Instance.new("ImageLabel"); avatar.Size=UDim2.fromOffset(56,56); avatar.Position=UDim2.fromOffset(12,11); avatar.BackgroundColor3=config.UI.Surface3; avatar.BorderSizePixel=0; avatar.Parent=panel
    root.Rounded(avatar,13); root.Stroke(avatar,config.UI.Accent,0.35,1)
    local ok,image=pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end); if ok and image then avatar.Image=image end
    local name=root.Label(panel,player.DisplayName,13); name.Size=UDim2.fromOffset(184,22); name.Position=UDim2.fromOffset(80,12)
    local level=root.Label(panel,"BATTLE RUNNER",8,config.UI.Muted); level.Size=UDim2.fromOffset(184,18); level.Position=UDim2.fromOffset(80,32)
    local readiness=root.Label(panel,"● ONLINE",8,config.UI.Good); readiness.Size=UDim2.fromOffset(90,17); readiness.Position=UDim2.fromOffset(80,52)
    TweenService:Create(readiness,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{TextTransparency=0.45}):Play()
    root.AnimateIn(panel,"Left"); return {Panel=panel,Avatar=avatar,Name=name,Readiness=readiness}
end
return Profile