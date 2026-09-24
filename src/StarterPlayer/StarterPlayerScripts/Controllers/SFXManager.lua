--!strict

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local SFXManager = {}

local IDS: {[string]: string} = {
    LightHit = "rbxasset://sounds/hit.mp3",
    HeavyHit = "rbxasset://sounds/swordslash.mp3",
    Block = "rbxasset://sounds/snap.mp3",
    Parry = "rbxasset://sounds/electronicpingshort.mp3",
    Dash = "rbxasset://sounds/unsheath.mp3",
    Ultimate = "rbxasset://sounds/victory.mp3",
    Awakening = "rbxasset://sounds/victory.mp3",
    UI = "rbxasset://sounds/electronicpingshort.mp3"
}

local function reduced(): boolean
    return game:GetService("Players").LocalPlayer:GetAttribute("CC_ReducedEffects") == true
end

local function playSound(soundId: string, volume: number, speed: number)
    if soundId == "" then
        return
    end

    local sound = Instance.new("Sound")
    sound.Name = "CC_SFX"
    sound.SoundId = soundId
    sound.Volume = math.clamp(reduced() and volume * 0.72 or volume, 0, 3)
    sound.PlaybackSpeed = math.clamp(speed, 0.75, 1.35)
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 8
    sound.RollOffMaxDistance = 120
    sound.Parent = SoundService
    sound:Play()

    Debris:AddItem(sound, 4)
end

function SFXManager:Play(kind: string)
    local soundId = IDS[kind]
    if not soundId then
        return
    end

    local speed = 1
    if kind == "LightHit" then
        speed = 0.94 + math.random() * 0.10
    elseif kind == "HeavyHit" then
        speed = 0.88 + math.random() * 0.08
    elseif kind == "Dash" then
        speed = 1.16 + math.random() * 0.08
    elseif kind == "Parry" then
        speed = 1.05 + math.random() * 0.12
    elseif kind == "Ultimate" or kind == "Awakening" then
        speed = 0.92
    end

    local volume = ({
        LightHit = 0.52,
        HeavyHit = 0.82,
        Block = 0.60,
        Parry = 0.76,
        Dash = 0.34,
        Ultimate = 0.60,
        Awakening = 0.70,
        UI = 0.28
    })[kind] or 0.5

    playSound(soundId, volume, speed)
end

function SFXManager:Set(kind: string, soundId: string)
    if IDS[kind] ~= nil then
        IDS[kind] = soundId
    end
end

return SFXManager
