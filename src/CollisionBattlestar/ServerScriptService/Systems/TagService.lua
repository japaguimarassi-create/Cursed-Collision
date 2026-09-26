--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}

local Config
local State: RemoteEvent

type Runtime = {
    tagger: Player?,
    roundActive: boolean,
    roundEndsAt: number,
    nextTagAt: number,
    elapsed: number,
}

local runtime: Runtime = {
    tagger = nil,
    roundActive = false,
    roundEndsAt = 0,
    nextTagAt = 0,
    elapsed = 0,
}

local function getRoot(player: Player): BasePart?
    local character = player.Character
    if not character then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
        return root
    end

    return nil
end

local function removeMarker(character: Model)
    local highlight = character:FindFirstChild("TaggerHighlight")
    if highlight then
        highlight:Destroy()
    end

    local marker = character:FindFirstChild("TaggerMarker")
    if marker then
        marker:Destroy()
    end

    character:SetAttribute("IsTagger", false)
end

local function addMarker(character: Model)
    removeMarker(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = "TaggerHighlight"
    highlight.FillColor = Config.UI.Danger
    highlight.FillTransparency = 0.45
    highlight.OutlineColor = Color3.fromRGB(255, 235, 235)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Adornee = character
    highlight.Parent = character

    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "TaggerMarker"
        billboard.Size = UDim2.fromOffset(130, 34)
        billboard.StudsOffset = Vector3.new(0, 3.1, 0)
        billboard.AlwaysOnTop = false
        billboard.Adornee = head
        billboard.Parent = character

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "PEGADOR"
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.TextColor3 = Color3.fromRGB(255, 80, 88)
        label.TextStrokeTransparency = 0.35
        label.Parent = billboard
    end

    character:SetAttribute("IsTagger", true)
end

local function setTagger(player: Player?)
    for _, other in ipairs(Players:GetPlayers()) do
        if other.Character then
            removeMarker(other.Character)
        end
    end

    runtime.tagger = player

    if player and player.Character then
        addMarker(player.Character)
    end
end

local function shuffledPlayers()
    local list = Players:GetPlayers()
    for index = #list, 2, -1 do
        local swap = math.random(index)
        list[index], list[swap] = list[swap], list[index]
    end
    return list
end

local function teleportPlayers()
    local spawns = workspace:FindFirstChild("TagSpawns")
    if not spawns then
        return
    end

    local spawnParts = spawns:GetChildren()
    if #spawnParts == 0 then
        return
    end

    for index, player in ipairs(shuffledPlayers()) do
        local character = player.Character
        local root = getRoot(player)
        if character and root then
            local point = spawnParts[((index - 1) % #spawnParts) + 1]
            if point:IsA("BasePart") then
                character:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
            end
        end
    end
end

local function broadcast(kind: string, ...)
    State:FireAllClients(kind, ...)
end

local function chooseTagger()
    local list = Players:GetPlayers()
    if #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

local function tryTag()
    local tagger = runtime.tagger
    if not tagger then
        return
    end

    local taggerRoot = getRoot(tagger)
    if not taggerRoot then
        return
    end

    local closest: Player?
    local closestDistance = Config.Tag.TagDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= tagger then
            local root = getRoot(player)
            if root then
                local distance = (root.Position - taggerRoot.Position).Magnitude
                if distance <= closestDistance then
                    closest = player
                    closestDistance = distance
                end
            end
        end
    end

    if closest then
        setTagger(closest)
        runtime.nextTagAt = os.clock() + Config.Tag.TagCooldown
        broadcast("TagTransfer", closest.UserId)
    end
end

local function endRound()
    if not runtime.roundActive then
        return
    end

    runtime.roundActive = false
    local survivorCount = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= runtime.tagger and getRoot(player) then
            survivorCount += 1
        end
    end

    broadcast("RoundEnd", survivorCount)
    setTagger(nil)
end

local function startRound()
    local players = Players:GetPlayers()
    if #players == 0 then
        return
    end

    teleportPlayers()
    setTagger(chooseTagger())

    runtime.roundActive = true
    runtime.roundEndsAt = os.clock() + Config.Tag.RoundDuration
    runtime.nextTagAt = os.clock() + 1.25
    runtime.elapsed = 0

    broadcast("RoundStart", Config.Tag.RoundDuration, runtime.tagger and runtime.tagger.UserId or 0)
end

function Service:Init(config)
    Config = config
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    Players.PlayerRemoving:Connect(function(player)
        if player == runtime.tagger then
            if runtime.roundActive then
                setTagger(chooseTagger())
                broadcast("TagTransfer", runtime.tagger and runtime.tagger.UserId or 0)
            else
                setTagger(nil)
            end
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            character:SetAttribute("IsTagger", false)
        end)
    end)

    task.spawn(function()
        while true do
            for remaining = Config.Tag.Intermission, 1, -1 do
                if #Players:GetPlayers() > 0 then
                    broadcast("Intermission", remaining)
                end
                task.wait(1)
            end

            startRound()

            local lastSecond = -1
            while runtime.roundActive do
                local now = os.clock()
                if now >= runtime.roundEndsAt then
                    endRound()
                    break
                end

                if now >= runtime.nextTagAt then
                    tryTag()
                end

                local remaining = math.max(0, math.ceil(runtime.roundEndsAt - now))
                if remaining ~= lastSecond then
                    lastSecond = remaining
                    broadcast("RoundTime", remaining, runtime.tagger and runtime.tagger.UserId or 0)
                end

                task.wait(0.08)
            end

            task.wait(2)
        end
    end)
end

return Service
