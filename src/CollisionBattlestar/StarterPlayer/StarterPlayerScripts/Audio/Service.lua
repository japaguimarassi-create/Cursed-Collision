--!strict

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local AudioService = {}
AudioService.__index = AudioService

local AUDIO_FOLDER_NAME = "CollisionBattlestarAudio"

local function findSound(folder: Instance?, name: string)
    if not folder then
        return nil
    end

    local sound = folder:FindFirstChild(name)
    if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
        return sound
    end

    return nil
end

function AudioService.new(remotes)
    return setmetatable({
        remotes = remotes,
        running = false,
        connection = nil,
        music = nil,
    }, AudioService)
end

function AudioService:GetFolder()
    return SoundService:FindFirstChild(AUDIO_FOLDER_NAME)
end

function AudioService:Play(name: string)
    local template = findSound(self:GetFolder(), name)
    if not template then
        return false
    end

    local sound = template:Clone()
    sound.Looped = false
    sound.Parent = SoundService
    sound:Play()

    local lifetime = math.max(1, sound.TimeLength > 0 and sound.TimeLength + 0.5 or 5)
    Debris:AddItem(sound, lifetime)

    return true
end

function AudioService:StartMusic()
    local template = findSound(self:GetFolder(), "Music")
    if not template then
        return false
    end

    if self.music then
        self.music:Stop()
        self.music:Destroy()
    end

    self.music = template:Clone()
    self.music.Looped = true
    self.music.Parent = SoundService
    self.music:Play()

    return true
end

function AudioService:Start()
    if self.running then
        return
    end

    self.running = true
    self:StartMusic()

    self.connection = self.remotes.FX.OnClientEvent:Connect(function(kind)
        if kind == "Hit" then
            self:Play("Hit")
        elseif kind == "PvPHit" then
            self:Play("PvPHit")
        elseif kind == "Dash" then
            self:Play("Dash")
        elseif kind == "EnemyDefeated" then
            self:Play("Defeat")
        elseif kind == "BossSpawn" then
            self:Play("Boss")
        elseif kind == "WaveStart" then
            self:Play("Wave")
        elseif kind == "EchoHeal" then
            self:Play("Heal")
        end
    end)

    self.remotes.State.OnClientEvent:Connect(function(kind)
        if kind == "LevelUp" then
            self:Play("LevelUp")
        elseif kind == "RuntimeReloaded" then
            self:Play("RuntimeRestored")
        end
    end)
end

function AudioService:Stop()
    self.running = false

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    if self.music then
        self.music:Stop()
        self.music:Destroy()
        self.music = nil
    end
end

function AudioService:HealthCheck()
    return self.running
end

return AudioService
