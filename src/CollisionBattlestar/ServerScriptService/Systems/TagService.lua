--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local Config
local State: RemoteEvent

type Runtime = {
    tagger: Player?,
    roundActive: boolean,
    roundEndsAt: number,
    nextTagAt: number,
}

local runtime: Runtime = {
    tagger = nil,
    roundActive = false,
    roundEndsAt = 0,
    nextTagAt = 0,
}

local function rootOf(player: Player): BasePart?
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
        return root
    end

    return nil
end

local function clearMarker(character: Model)
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

local function markCharacter(character: Model)
    clearMarker(character)

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
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Text = "PEGADOR"
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.TextColor3 = Config.UI.Danger
        label.TextStrokeTransparency = 0.35
        label.Parent = billboard
    end

    character:SetAttribute("IsTagger", true)
end

local function applyRoleMarker(player: Player)
    local character = player.Character
    if not character then
        return
    end

    if player == runtime.tagger then
        markCharacter(character)
    else
        clearMarker(character)
    end
end

local function setTagger(player: Player?)
    runtime.tagger = player

    for _, other in ipairs(Players:GetPlayers()) do
        applyRoleMarker(other)
    end
end

local function chooseTagger(excluded: Player?): Player?
    local candidates = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= excluded then
            table.insert(candidates, player)
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[math.random(1, #candidates)]
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

    local points = {}
    for _, child in ipairs(spawns:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(points, child)
        end
    end

    if #points == 0 then
        return
    end

    for index, player in ipairs(shuffledPlayers()) do
        local root = rootOf(player)
        if root and player.Character then
            local point = points[((index - 1) % #points) + 1]
            player.Character:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
        end
    end
end

local function broadcast(kind: string, ...)
    State:FireAllClients(kind, ...)
end

local function tryTag()
    local tagger = runtime.tagger
    if not tagger then
        return
    end

    local taggerRoot = rootOf(tagger)
    if not taggerRoot then
        return
    end

    local target: Player?
    local best = Config.Tag.TagDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= tagger then
            local root = rootOf(player)
            if root then
                local distance = (root.Position - taggerRoot.Position).Magnitude
                if distance <= best then
                    best = distance
                    target = player
                end
            end
        end
    end

    if target then
        setTagger(target)
        runtime.nextTagAt = os.clock() + Config.Tag.TagCooldown
        broadcast("TagTransfer", target.UserId)
    end
end

local function endRound()
    if not runtime.roundActive then
        return
    end

    runtime.roundActive = false

    local freePlayers = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= runtime.tagger and rootOf(player) then
            freePlayers += 1
        end
    end

    broadcast("RoundEnd", freePlayers)
    setTagger(nil)
end

local function startRound()
    if #Players:GetPlayers() == 0 then
        return
    end

    teleportPlayers()
    setTagger(chooseTagger(nil))

    runtime.roundActive = true
    runtime.roundEndsAt = os.clock() + Config.Tag.RoundDuration
    runtime.nextTagAt = os.clock() + 1.25

    broadcast(
        "RoundStart",
        Config.Tag.RoundDuration,
        runtime.tagger and runtime.tagger.UserId or 0
    )
end

local function attachPlayer(player: Player)
    player.CharacterAdded:Connect(function(character)
        character:SetAttribute("IsTagger", false)
        if player == runtime.tagger then
            task.defer(function()
                if character.Parent then
                    markCharacter(character)
                end
            end)
        end
    end)
end

function Service:Init(config)
    Config = config

    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    State = remotes:WaitForChild("State") :: RemoteEvent

    Players.PlayerAdded:Connect(attachPlayer)

    Players.PlayerRemoving:Connect(function(player)
        if player == runtime.tagger then
            if runtime.roundActive then
                setTagger(chooseTagger(player))
                broadcast("TagTransfer", runtime.tagger and runtime.tagger.UserId or 0)
            else
                setTagger(nil)
            end
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        attachPlayer(player)
    end

    task.spawn(function()
        while true do
            for remaining = Config.Tag.Intermission, 1, -1 do
                broadcast("Intermission", remaining)
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
                    broadcast(
                        "RoundTime",
                        remaining,
                        runtime.tagger and runtime.tagger.UserId or 0
                    )
                end

                task.wait(0.08)
            end

            task.wait(2)
        end
    end)
end

return Service
