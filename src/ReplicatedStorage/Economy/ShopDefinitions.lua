local characters = {
    "PotentialMan","Yuji","Gojo","Sukuna","Megumi","Yuta","Maki","Toji","Mahito","Todo","Hakari",
    "Choso","Kashimo","Naoya","Kenjaku","Jogo","Dagon","Hanami","Higuruma","Takaba","Uraume",
    "Yorozu","Ryu","Uro","Kusakabe"
}

local skinStyles = {
    {
        key = "Shadow",
        price = 650,
        body = Color3.fromRGB(28, 30, 38),
        accent = Color3.fromRGB(130, 108, 182),
        material = Enum.Material.SmoothPlastic
    },
    {
        key = "Crimson",
        price = 950,
        body = Color3.fromRGB(92, 30, 39),
        accent = Color3.fromRGB(238, 77, 89),
        material = Enum.Material.Metal
    },
    {
        key = "Eclipse",
        price = 1400,
        body = Color3.fromRGB(18, 20, 28),
        accent = Color3.fromRGB(224, 194, 97),
        material = Enum.Material.Neon
    }
}

local Shop = {
    Skins = {},
    CharacterOrder = characters
}

for characterIndex, character in ipairs(characters) do
    for styleIndex, style in ipairs(skinStyles) do
        local id = string.format("skin_%s_%s", string.lower(character), string.lower(style.key))
        Shop.Skins[id] = {
            Id = id,
            Name = character .. " • " .. style.key,
            Character = character,
            Price = style.price + ((characterIndex - 1) % 5) * 80 + (styleIndex - 1) * 50,
            BodyColor = style.body,
            AccentColor = style.accent,
            Material = style.material,
            Rarity = styleIndex == 1 and "Rare" or styleIndex == 2 and "Epic" or "Legendary"
        }
    end
end

return Shop
