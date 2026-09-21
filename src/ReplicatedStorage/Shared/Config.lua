local Config = {
    Combat = {
        M1 = {
            Cooldown = 0.23,
            Damage = {5, 5, 6, 8},
            Range = 7,
            Width = 5,
            Height = 5,
            Stun = 0.28
        },
        Heavy = {
            Cooldown = 1.25,
            Damage = 12,
            Range = 7,
            Width = 6,
            Height = 5,
            Stun = 0.55,
            Knockback = 62
        },
        Grab = {
            Cooldown = 1.8,
            Damage = 5,
            Range = 5.5,
            Width = 5,
            Height = 5,
            Stun = 0.9
        },
        Dash = {
            Cooldown = 0.9,
            Speed = 74,
            Duration = 0.18
        },
        Dodge = {
            Cooldown = 1.15,
            IFrame = 0.28
        },
        Block = {
            PerfectWindow = 0.16,
            DamageReduction = 0.78
        },
        Combo = {
            ResetAfter = 1.15,
            Max = 4
        },
        Hitstop = 0.045
    },
    CE = {
        Max = 100,
        RegenPerSecond = 7,
        Costs = {
            M1 = 0,
            Heavy = 4,
            Grab = 2,
            Dash = 0,
            Dodge = 2,
            Special = 14,
            Skill = 18,
            Awakening = 0,
            Domain = 60,
            OneTime = 0,
            ClashSpecial = 8
        }
    },
    Awakening = {
        Max = 100,
        MinToActivate = 100,
        Duration = 25,
        GainDamageDealt = 2.5,
        GainDamageTaken = 1.4
    },
    Domain = {
        Radius = 34,
        Duration = 18,
        Cooldown = 45
    },
    Clash = {
        DecisionWindow = 1.8,
        Moves = {
            [1] = "Crush",
            [2] = "Counter",
            [3] = "Feint",
            [4] = "Break"
        },
        Beats = {
            [1] = 2,
            [2] = 3,
            [3] = 4,
            [4] = 1
        },
        PressurePerSpecial = 12,
        PressureToConvertNeutral = 20,
        RecoilStun = 0.2,
        OpeningStun = 1.05
    },
    PerfectCombo = {
        StepWindow = 1.15,
        Sequences = {
            Yuji = {"Skill", "Special", "M1", "M1"},
            Gojo = {"Skill", "Special", "M1", "Special"},
            Sukuna = {"Special", "Skill", "Special", "M1"}
        }
    },
    OneTime = {
        Damage = 42,
        Radius = 16
    },
    AntiCheat = {
        Window = 1,
        MaxActions = 22,
        MaxRemotePayloadBytes = 2048
    }
}

return Config
