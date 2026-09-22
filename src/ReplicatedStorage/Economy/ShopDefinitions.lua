local characters = {
    "Yuji","Gojo","Sukuna","Megumi","Yuta","Maki","Toji","Mahito","Todo","Hakari",
    "Choso","Kashimo","Naoya","Kenjaku","Jogo","Dagon","Hanami","Higuruma","Takaba",
    "Uraume","Yorozu","Ryu","Uro","Kusakabe"
}

local emoteAnimations = {
    "Wave","Point","Laugh","Cheer","Dance","Dance2","Dance3","Salute","Shrug","Tilt"
}

local emoteMoods = {
    {"Calm", Color3.fromRGB(176, 196, 255)},
    {"Bold", Color3.fromRGB(255, 102, 117)},
    {"Royal", Color3.fromRGB(205, 161, 255)},
    {"Electric", Color3.fromRGB(101, 222, 255)},
    {"Golden", Color3.fromRGB(255, 210, 92)},
    {"Emerald", Color3.fromRGB(113, 225, 143)},
    {"Frost", Color3.fromRGB(180, 241, 255)},
    {"Shadow", Color3.fromRGB(118, 121, 145)},
    {"Rose", Color3.fromRGB(255, 143, 194)},
    {"Inferno", Color3.fromRGB(255, 132, 66)},
    {"Void", Color3.fromRGB(126, 92, 168)},
    {"Neon", Color3.fromRGB(113, 255, 220)},
    {"Crimson", Color3.fromRGB(204, 63, 78)},
    {"Azure", Color3.fromRGB(91, 166, 255)},
    {"Prism", Color3.fromRGB(230, 190, 255)}
}

local emoteActions = {
    "Entrance","Victory","Focus","Challenge","Respect","Taunt","Celebration","Pose","Reaction","Energy"
}

local Shop = {
    Emotes = {},
    Skins = {}
}

for index = 1, 150 do
    local mood = emoteMoods[((index - 1) % #emoteMoods) + 1]
    local action = emoteActions[(math.floor((index - 1) / #emoteMoods) % #emoteActions) + 1]
    local animation = emoteAnimations[((index - 1) % #emoteAnimations) + 1]
    local id = string.format("emote_%03d", index)

    Shop.Emotes[id] = {
        Id = id,
        Name = mood[1] .. " " .. action,
        Animation = animation,
        AnimationId = 0,
        Accent = mood[2],
        Price = index == 1 and 0 or (60 + ((index * 37) % 790)),
        Rarity = index <= 30 and "Common" or index <= 75 and "Rare" or index <= 120 and "Epic" or "Legendary"
    }
end

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

Shop.CharacterOrder = characters
return Shop
