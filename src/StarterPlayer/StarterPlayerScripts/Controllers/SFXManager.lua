--!strict

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local SFXManager = {}

local IDs = {
    LightHit="",
    HeavyHit="",
    Block="",
    Parry="",
    Dash="",
    Ultimate="",
    Awakening="",
    UI=""
}

local function play(id: string, volume: number, pitch: number)
    if id=="" then return end

    local sound=Instance.new("Sound")
    sound.SoundId=id
    sound.Volume=math.clamp(volume,0,3)
    sound.PlaybackSpeed=math.clamp(pitch,0.85,1.2)
    sound.Parent=SoundService
    sound:Play()
    Debris:AddItem(sound,5)
end

function SFXManager:Play(kind: string)
    local id=IDs[kind]
    if not id then return end

    local pitch=1
    if kind=="LightHit" or kind=="HeavyHit" then
        pitch=0.96+math.random()*0.08
    end

    play(id,kind=="HeavyHit" and 1.15 or 0.85,pitch)
end

function SFXManager:Set(kind: string, soundId: string)
    if IDs[kind]~=nil then
        IDs[kind]=soundId
    end
end

return SFXManager
