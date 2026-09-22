local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Economy.ShopDefinitions)

local CosmeticService = {}

local function setPartAppearance(part, bodyColor, material)
    if not part:IsA("BasePart") then
        return
    end

    if part.Name ~= "HumanoidRootPart" then
        part.Color = bodyColor
        if material then
            part.Material = material
        end
    end
end

function CosmeticService:ApplySkin(player, skinId)
    local skin = Shop.Skins[skinId]
    local character = player.Character

    if not skin or not character then
        return false
    end

    if skin.Character ~= (player:GetAttribute("CharacterId") or "") then
        return false
    end

    for _, descendant in ipairs(character:GetDescendants()) do
        setPartAppearance(descendant, skin.BodyColor, skin.Material)
    end

    local highlight = character:FindFirstChild("CursedCollisionSkin")
    if highlight then
        highlight:Destroy()
    end

    highlight = Instance.new("Highlight")
    highlight.Name = "CursedCollisionSkin"
    highlight.FillColor = skin.AccentColor
    highlight.FillTransparency = 0.82
    highlight.OutlineColor = skin.AccentColor
    highlight.OutlineTransparency = 0.15
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character

    player:SetAttribute("EquippedSkin", skinId)
    return true
end

function CosmeticService:ClearSkin(player)
    local character = player.Character
    if not character then
        return
    end

    local highlight = character:FindFirstChild("CursedCollisionSkin")
    if highlight then
        highlight:Destroy()
    end

    player:SetAttribute("EquippedSkin", "")
end

return CosmeticService
