local CosmeticService = {}

local originals = {}

local function remember(character)
    if originals[character] then
        return originals[character]
    end

    local snapshot = {}

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart")
            and descendant.Name ~= "HumanoidRootPart"
            and not snapshot[descendant] then
            snapshot[descendant] = {
                Color = descendant.Color,
                Material = descendant.Material
            }
        end
    end

    originals[character] = snapshot
    return snapshot
end

local function restore(character)
    local snapshot = originals[character]
    if not snapshot then
        return
    end

    for part, values in pairs(snapshot) do
        if part and part.Parent then
            part.Color = values.Color
            part.Material = values.Material
        end
    end
end

local function removeHighlight(character)
    local highlight = character:FindFirstChild("CursedCollisionSkin")
    if highlight then
        highlight:Destroy()
    end
end

local function applyParts(character, bodyColor, material)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            descendant.Color = bodyColor
            if material then
                descendant.Material = material
            end
        end
    end
end

function CosmeticService:ApplySkin(player, skin)
    local character = player.Character

    if not character or type(skin) ~= "table" then
        return false
    end

    if typeof(skin.BodyColor) ~= "Color3" or typeof(skin.AccentColor) ~= "Color3" then
        return false
    end

    remember(character)
    applyParts(character, skin.BodyColor, skin.Material)
    removeHighlight(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = "CursedCollisionSkin"
    highlight.FillColor = skin.AccentColor
    highlight.FillTransparency = 0.82
    highlight.OutlineColor = skin.AccentColor
    highlight.OutlineTransparency = 0.15
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character

    player:SetAttribute("EquippedSkin", skin.Id or "")
    return true
end

function CosmeticService:ClearSkin(player)
    local character = player.Character

    if not character then
        return
    end

    remember(character)
    restore(character)
    removeHighlight(character)
    player:SetAttribute("EquippedSkin", "")
end

function CosmeticService:ResetCharacter(character)
    originals[character] = nil
end

return CosmeticService
