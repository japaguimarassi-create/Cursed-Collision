--!strict

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local AudioService = {}
AudioService.__index = AudioService

local AUDIO_FOLDER_NAME = "CollisionBattlestarAudio"

local DEFAULT_SOUND_IDS = {
    Hit = "rbxassetid://9075325599",
    Click = "rbxassetid://82845990304289",
}

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
        stateConnection = nil,
        buttonConnections = {},
        guiAddedConnection = nil,
        music = nil,
    }, AudioService)
end

function AudioService:GetFolder()
    local folder = SoundService:FindFirstChild(AUDIO_FOLDER_NAME)

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = AUDIO_FOLDER_NAME
        folder.Parent = SoundService
    end

    for name, soundId in pairs(DEFAULT_SOUND_IDS) do
        local sound = folder:FindFirstChild(name)

        if not sound then
            sound = Instance.new("Sound")
            sound.Name = name
            sound.SoundId = soundId
            sound.Volume = name == "Hit" and 0.24 or 0.16
            sound.Parent = folder
        end
    end

    return folder
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

    local function bindButton(instance)
        if not instance:IsA("GuiButton") then
            return
        end

        if self.buttonConnections[instance] then
            return
        end

        self.buttonConnections[instance] = instance.Activated:Connect(function()
            self:Play("Click")
        end)
    end

    for _, descendant in ipairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
        bindButton(descendant)
    end

    self.guiAddedConnection = game:GetService("Players").LocalPlayer.PlayerGui.DescendantAdded:Connect(bindButton)

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

    self.stateConnection = self.remotes.State.OnClientEvent:Connect(function(kind)
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

    if self.stateConnection then
        self.stateConnection:Disconnect()
        self.stateConnection = nil
    end

    if self.guiAddedConnection then
        self.guiAddedConnection:Disconnect()
        self.guiAddedConnection = nil
    end

    for instance, connection in pairs(self.buttonConnections) do
        connection:Disconnect()
        self.buttonConnections[instance] = nil
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
