--!strict

export type CharacterProfile = {
    Id: string,
    Name: string,
    Subtitle: string,
    Archetype: string,
    SpecialCooldown: number,
    SkillCooldown: number,
    Unique: string,
    AwakeningName: string,
    Domain: string?
}

local Profiles: {[string]: CharacterProfile} = {
    Yuji = {
        Id = "Yuji",
        Name = "Yuji Itadori",
        Subtitle = "Black Flash Momentum",
        Archetype = "Rushdown / pressure / close-range burst",
        SpecialCooldown = 0.65,
        SkillCooldown = 0.70,
        Unique = "Divergent Soul",
        AwakeningName = "Divergent Soul",
        Domain = "SoulTrainingGround"
    },

    Gojo = {
        Id = "Gojo",
        Name = "Satoru Gojo",
        Subtitle = "Limitless / Six Eyes",
        Archetype = "Control / spacing / burst",
        SpecialCooldown = 0.80,
        SkillCooldown = 0.75,
        Unique = "Infinity",
        AwakeningName = "Six Eyes Unleashed",
        Domain = "UnlimitedVoid"
    },

    Sukuna = {
        Id = "Sukuna",
        Name = "Ryomen Sukuna",
        Subtitle = "Shrine / Flame / World Cut",
        Archetype = "Pressure / zoning / finisher",
        SpecialCooldown = 0.70,
        SkillCooldown = 0.80,
        Unique = "Shrine Adaptation",
        AwakeningName = "King of Curses",
        Domain = "MalevolentShrine"
    },

    Megumi = {
        Id = "Megumi",
        Name = "Megumi Fushiguro",
        Subtitle = "Ten Shadows",
        Archetype = "Setup / summons / control",
        SpecialCooldown = 0.85,
        SkillCooldown = 0.80,
        Unique = "Ten Shadows",
        AwakeningName = "Chimera Shadow Garden",
        Domain = "ChimeraShadowGarden"
    }
}

return Profiles
