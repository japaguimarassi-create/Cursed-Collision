--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFXManager = {}

local function ring(position: Vector3, radius: number, accent: Color3)
    local part=Instance.new("Part")
    part.Name="CC_VFX_Ring"
    part.Anchored=true
    part.CanCollide=false
    part.CanTouch=false
    part.CanQuery=false
    part.Transparency=0.18
    part.Material=Enum.Material.Neon
    part.Color=accent
    part.Shape=Enum.PartType.Cylinder
    part.Size=Vector3.new(0.12,0.4,0.4)
    part.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.rad(90))
    part.Parent=workspace

    TweenService:Create(
        part,
        TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
        {Size=Vector3.new(0.12,radius,radius),Transparency=1}
    ):Play()

    Debris:AddItem(part,0.25)
end

local function sparks(position: Vector3, accent: Color3, count: number)
    local attachment=Instance.new("Attachment")
    attachment.Name="CC_VFX_Attachment"
    attachment.WorldPosition=position
    attachment.Parent=workspace.Terrain

    local emitter=Instance.new("ParticleEmitter")
    emitter.Name="CC_VFX_Sparks"
    emitter.Color=ColorSequence.new(accent)
    emitter.LightEmission=0.9
    emitter.Rate=0
    emitter.Lifetime=NumberRange.new(0.18,0.34)
    emitter.Speed=NumberRange.new(5,12)
    emitter.SpreadAngle=Vector2.new(180,180)
    emitter.Size=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.30),
        NumberSequenceKeypoint.new(1,0)
    })
    emitter.Parent=attachment
    emitter:Emit(count)
    Debris:AddItem(attachment,0.6)
end

function VFXManager:Play(kind: string, position: Vector3, payload: any)
    local accent=Color3.fromRGB(175,130,255)

    if kind=="PerfectBlock" then
        accent=Color3.fromRGB(255,225,120)
        ring(position,8,accent)
        sparks(position,accent,20)
    elseif kind=="BlockImpact" then
        accent=Color3.fromRGB(120,180,255)
        sparks(position,accent,10)
    elseif kind=="Hit" then
        local reaction=tostring(payload and payload.reaction or "Light")
        accent=reaction=="Finisher" and Color3.fromRGB(255,82,100)
            or reaction=="Heavy" and Color3.fromRGB(255,160,90)
            or Color3.fromRGB(215,215,255)
        sparks(position,accent,reaction=="Finisher" and 26 or reaction=="Heavy" and 16 or 8)
    elseif kind=="ProjectileImpact" then
        ring(position,6,accent)
        sparks(position,accent,14)
    elseif kind=="Death" then
        ring(position,10,Color3.fromRGB(255,90,100))
        sparks(position,Color3.fromRGB(255,90,100),24)
    elseif kind=="AbilityTimeline" and payload then
        if tostring(payload.phase or "")=="HitFrame" then
            ring(position,5,accent)
        end
    elseif kind=="CombatAction" and payload then
        if payload.action=="Dash" then
            sparks(position,Color3.fromRGB(135,105,255),6)
        end
    elseif kind=="Ultimate" then
        ring(position,14,Color3.fromRGB(255,210,110))
        sparks(position,Color3.fromRGB(255,210,110),30)
    elseif kind=="Awakening" then
        ring(position,18,Color3.fromRGB(255,90,180))
        sparks(position,Color3.fromRGB(255,90,180),36)
    end
end

return VFXManager
