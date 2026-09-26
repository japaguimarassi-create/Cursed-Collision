local Players = game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local Vitals={}
function Vitals.Mount(root,config,player)
    local panel=root.Panel(root.Gui,UDim2.fromOffset(310,96),UDim2.new(0,20,1,-126)); panel.Name="Vitals"
    local avatar=Instance.new("ImageLabel"); avatar.Size=UDim2.fromOffset(58,58); avatar.Position=UDim2.fromOffset(14,18); avatar.BackgroundColor3=config.UI.Surface3; avatar.BorderSizePixel=0; avatar.Parent=panel; root.Rounded(avatar,13); root.Stroke(avatar,config.UI.Accent,0.35,1)
    local ok,image=pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end); if ok and image then avatar.Image=image end
    local name=root.Label(panel,player.DisplayName,12); name.Size=UDim2.fromOffset(190,20); name.Position=UDim2.fromOffset(84,11)
    local hpValue=root.Label(panel,"HP 100 / 100",10,config.UI.Muted); hpValue.Size=UDim2.fromOffset(190,20); hpValue.Position=UDim2.fromOffset(84,31)
    local _,fill=root.Progress(panel,UDim2.fromOffset(205,9),UDim2.fromOffset(84,57),config.UI.Good,5)
    local state=root.Label(panel,"READY",8,config.UI.Good); state.Size=UDim2.fromOffset(55,18); state.Position=UDim2.fromOffset(18,76); state.TextXAlignment=Enum.TextXAlignment.Center
    local characterConnection
    local function bind(character)
        if characterConnection then characterConnection:Disconnect() end
        local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",8); if not humanoid then return end
        local function refresh()
            local ratio=humanoid.MaxHealth>0 and math.clamp(humanoid.Health/humanoid.MaxHealth,0,1) or 0
            hpValue.Text=("HP %d / %d"):format(math.floor(humanoid.Health+0.5),math.floor(humanoid.MaxHealth+0.5))
            TweenService:Create(fill,TweenInfo.new(0.16,Enum.EasingStyle.Quint),{Size=UDim2.fromScale(ratio,1),BackgroundColor3=ratio>0.55 and config.UI.Good or (ratio>0.25 and config.UI.Warning or config.UI.Danger)}):Play()
            state.Text=ratio<=0 and "DOWN" or (ratio<0.35 and "DANGER" or "READY"); state.TextColor3=ratio<=0 and config.UI.Danger or (ratio<0.35 and config.UI.Warning or config.UI.Good)
        end
        characterConnection=humanoid.HealthChanged:Connect(refresh); humanoid.Died:Connect(function() if state.Parent then state.Text="DOWN" end end); refresh()
    end
    player.CharacterAdded:Connect(bind); if player.Character then task.spawn(bind,player.Character) end
    root.AnimateIn(panel,"Left"); return {Panel=panel,Value=hpValue,Fill=fill,State=state}
end
return Vitals