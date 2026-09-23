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

local function burst(position: Vector3, radius: number, accent: Color3, count: number)
    ring(position, radius, accent)
    sparks(position, accent, count)
end

local function slash(position: Vector3, direction: Vector3, length: number, accent: Color3)
    if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.01 then
        direction = Vector3.zAxis
    end

    local part = Instance.new("Part")
    part.Name = "CC_VFX_Slash"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = accent
    part.Transparency = 0.22
    part.Size = Vector3.new(0.18, 0.18, length)
    part.CFrame = CFrame.lookAt(position, position + direction.Unit)
    part.Parent = workspace

    TweenService:Create(
        part,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.05, 0.05, length * 1.15),
            Transparency = 1
        }
    ):Play()

    Debris:AddItem(part, 0.20)
end

function VFXManager:Play(kind: string, position: Vector3, payload: any)
    local accent=Color3.fromRGB(175,130,255)

    if kind=="CharacterMove" and payload then
        local move = tostring(payload.move or "")
        local character = tostring(payload.character or "")
        local direction = payload.direction

        if character == "Gojo" then
            if string.find(move, "Blue") then
                burst(position, 8, Color3.fromRGB(90,180,255), 16)
            elseif string.find(move, "Red") then
                burst(position, 10, Color3.fromRGB(255,92,92), 22)
            elseif string.find(move, "Purple") then
                burst(position, 16, Color3.fromRGB(190,100,255), 34)
                slash(position, direction, 18, Color3.fromRGB(205,120,255))
            elseif string.find(move, "Void") then
                burst(position, 20, Color3.fromRGB(105,150,255), 28)
            elseif string.find(move, "Infinity") then
                burst(position, 7, Color3.fromRGB(160,220,255), 12)
            end
        elseif character == "Yuji" then
            if string.find(move, "Black Flash") or string.find(move, "BlackFlash") then
                burst(position, 9, Color3.fromRGB(30,30,35), 24)
                sparks(position, Color3.fromRGB(255,70,100), 18)
            elseif string.find(move, "Dismantle") then
                slash(position, direction, 15, Color3.fromRGB(205,70,80))
            elseif string.find(move, "Piercing Blood") then
                slash(position, direction, 20, Color3.fromRGB(180,35,50))
            elseif string.find(move, "Simple Domain") then
                burst(position, 12, Color3.fromRGB(235,235,255), 18)
            end
        elseif character == "Megumi" then
            if string.find(move, "Mahoraga") or payload.shikigami == "Mahoraga" then
                burst(position, 16, Color3.fromRGB(215,205,180), 30)
                ring(position, 11, Color3.fromRGB(255,220,130))
            elseif payload.shikigami then
                burst(position, 8, Color3.fromRGB(80,70,115), 12)
            elseif string.find(move, "Garden") then
                burst(position, 18, Color3.fromRGB(65,65,115), 24)
            end
        elseif character == "Sukuna" then
            if string.find(move, "Dismantle") or string.find(move, "Cleave") then
                slash(position, direction, 17, Color3.fromRGB(220,50,55))
                sparks(position, Color3.fromRGB(255,95,65), 10)
            elseif string.find(move, "Fuga") then
                burst(position, 15, Color3.fromRGB(255,120,45), 28)
            elseif string.find(move, "Rush") then
                sparks(position, Color3.fromRGB(225,55,65), 14)
            end
        end

        return
    end

    if kind=="Enchain" then
        burst(position, 14, Color3.fromRGB(165,70,180), 30)
        return
    end

    if kind=="TechniqueSwitch" then
        burst(position, 9, Color3.fromRGB(115,80,180), 14)
        return
    end

    if kind=="MahoragaSummon" then
        burst(position, 18, Color3.fromRGB(230,205,150), 38)
        return
    end

    if kind=="MahoragaMode" then
        ring(position, 12, Color3.fromRGB(255,215,125))
        sparks(position, Color3.fromRGB(205,205,220), 22)
        return
    end

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
