--!strict

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local SFXController = {}

local SOUNDS = {
    Swing = "rbxasset://sounds/swordlunge.mp3",
    Heavy = "rbxasset://sounds/swordslash.mp3",
    Impact = "rbxasset://sounds/hit.mp3",
    Snap = "rbxasset://sounds/snap.mp3",
    Dash = "rbxasset://sounds/unsheath.mp3",
    Ping = "rbxasset://sounds/electronicpingshort.mp3",
    Victory = "rbxasset://sounds/victory.mp3",
}

local function emit(soundId, position, volume, pitch)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 0.5
    sound.PlaybackSpeed = pitch or 1
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 150

    if typeof(position) == "Vector3" then
        local anchor = Instance.new("Part")
        anchor.Size = Vector3.new(0.1, 0.1, 0.1)
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.Transparency = 1
        anchor.CFrame = CFrame.new(position)
        anchor.Parent = Workspace
        sound.Parent = anchor
        sound:Play()
        Debris:AddItem(anchor, 3)
    else
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 3)
    end
end

function SFXController:Universal(kind, position)
    if kind == "MeleeSwing" then
        emit(SOUNDS.Swing, position, 0.45, 1.04)
    elseif kind == "Heavy" then
        emit(SOUNDS.Heavy, position, 0.72, 0.82)
    elseif kind == "Grab" then
        emit(SOUNDS.Impact, position, 0.58, 0.9)
    elseif kind == "Dash" or kind == "Dodge" then
        emit(SOUNDS.Dash, position, 0.38, 1.28)
    elseif kind == "Block" then
        emit(SOUNDS.Snap, position, 0.52, 1.0)
    end
end

function SFXController:Impact(position, tag)
    local pitch = tag == "BlackFlash" and 0.72 or (tag == "Slam" and 0.78 or 1)
    emit(SOUNDS.Impact, position, tag == "BlackFlash" and 0.9 or 0.5, pitch)
end

function SFXController:PerfectBlock(position)
    emit(SOUNDS.Snap, position, 0.8, 1.3)
    emit(SOUNDS.Ping, position, 0.5, 1.15)
end

function SFXController:KillConfirm()
    emit(SOUNDS.Victory, nil, 0.5, 1)
end

return SFXController
