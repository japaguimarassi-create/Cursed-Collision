--!strict

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

StarterPlayer.LoadCharacterAppearance = true

local function restoreAppearance(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then
        return
    end

    local deadline = os.clock() + 8
    while character.Parent and os.clock() < deadline do
        local head = character:FindFirstChild("Head")
        local bodyPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

        if head and bodyPart then
            break
        end

        task.wait(0.15)
    end

    local ok, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
    end)

    if ok and description and character.Parent then
        local applied = pcall(function()
            humanoid:ApplyDescriptionAsync(description, Enum.AssetTypeVerification.Default)
        end)

        if applied then
            character:SetAttribute("AppearanceLoaded", true)
            character:SetAttribute("AppearanceSource", "PlayerAvatar")
        end

        description:Destroy()
    end
end

local function bind(player: Player)
    player.CharacterAdded:Connect(function(character)
        task.defer(restoreAppearance, player, character)
    end)

    if player.Character then
        task.defer(restoreAppearance, player, player.Character)
    end
end

Players.PlayerAdded:Connect(bind)

for _, player in ipairs(Players:GetPlayers()) do
    bind(player)
end
