--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local Service = {}
Service.__index = Service

local function authorized(player: Player): boolean
    return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

function Service.new()
    return setmetatable({registry = nil, lab = nil, remote = nil}, Service)
end

function Service:IsAuthorized(player: Player): boolean
    return authorized(player)
end

function Service:CreateLab()
    local old = Workspace:FindFirstChild("CollisionTestLab")
    if old then
        old:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "CollisionTestLab"
    folder.Parent = Workspace
    self.lab = folder

    local base = Instance.new("Part")
    base.Name = "LabPlatform"
    base.Size = Vector3.new(96, 2, 72)
    base.Position = Vector3.new(0, 2, 260)
    base.Anchored = true
    base.Material = Enum.Material.Metal
    base.Color = Color3.fromRGB(24, 28, 38)
    base.Parent = folder

    local sign = Instance.new("Part")
    sign.Name = "LabSign"
    sign.Size = Vector3.new(26, 10, 1)
    sign.Position = Vector3.new(0, 9, 224)
    sign.Anchored = true
    sign.Material = Enum.Material.Neon
    sign.Color = Color3.fromRGB(48, 190, 255)
    sign.Parent = folder

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.Parent = sign
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Text = "COLLISION TEST LAB"
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = gui

    local commands = {
        {"FULL HEAL", "Heal"},
        {"+1000 CREDITS", "Credits"},
        {"SPAWN ELITE", "Elite"},
        {"CLEAR ARENA", "Clear"},
        {"NEXT WAVE", "Wave"},
    }
    for index, command in ipairs(commands) do
        local col = ((index - 1) % 3) - 1
        local row = math.floor((index - 1) / 3)
        local pad = Instance.new("Part")
        pad.Name = command[2]
        pad.Size = Vector3.new(24, 1, 12)
        pad.Position = Vector3.new(col * 27, 4, 242 + row * 18)
        pad.Anchored = true
        pad.Material = Enum.Material.Neon
        pad.Color = Color3.fromRGB(40, 60, 86)
        pad.Parent = folder

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = command[1]
        prompt.ObjectText = "Owner Test Lab"
        prompt.HoldDuration = 0.2
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = pad
        prompt.Triggered:Connect(function(player)
            if not authorized(player) then
                return
            end
            self:Execute(player, command[2])
        end)
    end

    local portal = Instance.new("Part")
    portal.Name = "ReturnPortal"
    portal.Size = Vector3.new(12, 1, 12)
    portal.Position = Vector3.new(40, 4, 290)
    portal.Anchored = true
    portal.Material = Enum.Material.Neon
    portal.Color = Color3.fromRGB(255, 80, 100)
    portal.Parent = folder
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "RETURN TO ARENA"
    prompt.ObjectText = "Test Lab"
    prompt.HoldDuration = 0.2
    prompt.RequiresLineOfSight = false
    prompt.Parent = portal
    prompt.Triggered:Connect(function(player)
        if authorized(player) then
            local spawn = Workspace:FindFirstChild("CollisionArena")
            local marker = spawn and spawn:FindFirstChild("PlayerSpawn", true)
            if marker and marker:IsA("BasePart") and player.Character then
                player.Character:PivotTo(marker.CFrame + Vector3.new(0,4,0))
            end
        end
    end)
end

function Service:TeleportOwner(player: Player)
    if not authorized(player) or not self.lab then
        return false
    end
    local platform = self.lab:FindFirstChild("LabPlatform")
    if platform and player.Character then
        player.Character:PivotTo(platform.CFrame + Vector3.new(0, 5, 0))
        return true
    end
    return false
end

function Service:Execute(player: Player, command: string)
    local state = self.registry:Get("PlayerState")
    if command == "Heal" then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
    elseif command == "Credits" then
        state:AddCredits(player, 1000)
    elseif command == "Elite" then
        self.registry:Get("Enemies"):Spawn("Elite", 99)
    elseif command == "Clear" then
        self.registry:Get("Enemies"):ClearAll()
    elseif command == "Wave" then
        self.registry:Get("Waves"):ForceNextWave()
    end
end

function Service:Init(registry, remotes)
    self.registry = registry
    self.remote = remotes.TestLab
    self:CreateLab()

    self.remote.OnServerEvent:Connect(function(player, action)
        if not authorized(player) then
            return
        end
        if action == "Teleport" then
            self:TeleportOwner(player)
        end
    end)
end

return Service
