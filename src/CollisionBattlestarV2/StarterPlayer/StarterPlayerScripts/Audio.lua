--!strict

local SoundService = game:GetService("SoundService")

local Audio = {}
Audio.__index = Audio

local IDS = {
    Hit = "",
    Critical = "",
    Dash = "",
    Defeat = "",
    Boss = "",
    Wave = "",
    LevelUp = "",
    Click = "",
}

function Audio.new(remotes)
    return setmetatable({
        remotes = remotes,
        connection = nil,
        stateConnection = nil,
        sounds = {},
    }, Audio)
end

function Audio:Prepare()
    local folder = SoundService:FindFirstChild("CBS2_Audio")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CBS2_Audio"
        folder.Parent = SoundService
    end

    for name, id in pairs(IDS) do
        if id ~= "" then
            local sound = folder:FindFirstChild(name)
            if not sound then
                sound = Instance.new("Sound")
                sound.Name = name
                sound.SoundId = id
                sound.Volume = name == "Hit" and 0.18 or 0.25
                sound.Parent = folder
            end
            self.sounds[name] = sound
        end
    end

    return folder
end

function Audio:Play(name: string)
    local sound = self.sounds[name]
    if sound then
        sound.TimePosition = 0
        sound:Play()
    end
end

function Audio:Start()
    self:Prepare()

    self.connection = self.remotes.FX.OnClientEvent:Connect(function(kind)
        local sound = ({
            Hit = "Hit",
            Critical = "Critical",
            Dash = "Dash",
            Defeat = "Defeat",
            Boss = "Boss",
            WaveStart = "Wave",
        })[kind]

        if sound then
            self:Play(sound)
        end
    end)

    self.stateConnection = self.remotes.State.OnClientEvent:Connect(function(kind)
        if kind == "LevelUp" then
            self:Play("LevelUp")
        end
    end)
end

function Audio:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.stateConnection then
        self.stateConnection:Disconnect()
        self.stateConnection = nil
    end
end

return Audio
