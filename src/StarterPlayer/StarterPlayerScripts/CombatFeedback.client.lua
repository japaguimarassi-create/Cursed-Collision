--!strict

local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")

local remotes=require(ReplicatedStorage.Shared.RemoteService):Get()
local Camera=require(script.Parent.Controllers.CameraController)
local VFX=require(script.Parent.Controllers.VFXManager)
local SFX=require(script.Parent.Controllers.SFXManager)


local function popup(position: Vector3, text: string, strong: boolean)
    local gui=Instance.new("BillboardGui")
    gui.Name="CC_DamagePopup"
    gui.Size=UDim2.fromOffset(strong and 150 or 110,strong and 50 or 34)
    gui.StudsOffset=Vector3.new(0,2.4,0)
    gui.AlwaysOnTop=true

    local holder=Instance.new("Frame")
    holder.Size=UDim2.fromScale(1,1)
    holder.BackgroundTransparency=1
    holder.Parent=gui

    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=strong and Color3.fromRGB(255,208,104) or Color3.fromRGB(242,243,248)
    label.Font=Enum.Font.GothamBlack
    label.TextScaled=true
    label.Parent=holder

    gui.Parent=workspace.Terrain
    gui:SetAttribute("WorldPosition",position)

    local anchor=Instance.new("Attachment")
    anchor.WorldPosition=position+Vector3.new((math.random()-0.5)*0.7,0,0)
    anchor.Parent=workspace.Terrain
    gui.Adornee=anchor

    task.delay(0.45,function()
        if label.Parent then
            label.TextTransparency=1
        end
    end)

    Debris:AddItem(anchor,0.8)
    Debris:AddItem(gui,0.8)
end

remotes.CombatFX.OnClientEvent:Connect(function(kind,position,payload)
    VFX:Play(kind,position,payload)
    Camera:OnCombatEvent(kind,payload)

    if kind=="Hit" and payload then
        local damage=math.floor(tonumber(payload.damage) or 0)
        if damage>0 then
            local strong=payload.final==true or payload.reaction=="Heavy" or payload.reaction=="Slam"
            popup(position,tostring(damage),strong)

            if strong then
                SFX:Play("HeavyHit")
            else
                SFX:Play("LightHit")
            end
        end
    elseif kind=="BlockImpact" then
        SFX:Play("Block")
    elseif kind=="PerfectBlock" then
        SFX:Play("Parry")
    elseif kind=="CombatAction" and payload then
        if payload.action=="Dash" then
            SFX:Play("Dash")
        end
    elseif kind=="Ultimate" then
        SFX:Play("Ultimate")
    elseif kind=="Awakening" then
        SFX:Play("Awakening")
    end
end)

return nil
