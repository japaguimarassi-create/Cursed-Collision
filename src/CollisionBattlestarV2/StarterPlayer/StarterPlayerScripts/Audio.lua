--!strict

local SoundService = game:GetService("SoundService")

local Audio = {}
Audio.__index = Audio

local IDS = {
    Hit = "rbxassetid://9075325599",
    Critical = "",
    Dash = "",
    Defeat = "",
    Boss = "",
    Wave = "",
    LevelUp = "",
    Click = "rbxassetid://82845990304289",
    Music = "",
}

function Audio.new(remotes)
    return setmetatable({
        remotes = remotes,
        connection = nil,
        stateConnection = nil,
        guiConnection = nil,
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

function Audio:BindGui()
    local player = game:GetService("Players").LocalPlayer
    local gui = player:FindFirstChildOfClass("PlayerGui")
    if not gui then
        return
    end

    if self.guiConnection then
        self.guiConnection:Disconnect()
    end

    self.guiConnection = gui.DescendantAdded:Connect(function(instance)
        if instance:IsA("GuiButton") then
            instance.Activated:Connect(function()
                self:Play("Click")
            end)
        end
    end)

    for _, instance in ipairs(gui:GetDescendants()) do
        if instance:IsA("GuiButton") then
            instance.Activated:Connect(function()
                self:Play("Click")
            end)
        end
    end
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
    self:BindGui()

    local music = self.sounds.Music
    if music then
        music.Looped = true
        music:Play()
    end

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
    if self.guiConnection then
        self.guiConnection:Disconnect()
        self.guiConnection = nil
    end

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
