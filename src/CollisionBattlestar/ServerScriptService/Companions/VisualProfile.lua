--!strict

local Profiles = {
    Vanguard = {
        Primary = Color3.fromRGB(80, 120, 190),
        Secondary = Color3.fromRGB(35, 45, 70),
        Accent = Color3.fromRGB(110, 205, 255),
        Height = 5.8,
        Width = 2.8,
    },
    Striker = {
        Primary = Color3.fromRGB(210, 95, 85),
        Secondary = Color3.fromRGB(70, 35, 40),
        Accent = Color3.fromRGB(255, 175, 105),
        Height = 5.6,
        Width = 2.5,
    },
    Guardian = {
        Primary = Color3.fromRGB(90, 155, 115),
        Secondary = Color3.fromRGB(35, 65, 50),
        Accent = Color3.fromRGB(150, 245, 175),
        Height = 6.1,
        Width = 3.1,
    },
    Support = {
        Primary = Color3.fromRGB(135, 110, 200),
        Secondary = Color3.fromRGB(55, 45, 80),
        Accent = Color3.fromRGB(220, 180, 255),
        Height = 5.7,
        Width = 2.6,
    },
}

return table.freeze(Profiles)
