--!strict

local Config = {
    Combat = {
        M1 = {
            Cooldown = 0.20,
            ComboReset = 0.92,
            MaxCombo = 4,
            Damage = {5, 5, 7, 10},
            Range = 6.8,
            Width = 5.2,
            Height = 5.8,
            Stun = {0.20, 0.22, 0.25, 0.42},
            Knockback = {8, 9, 11, 48},
            Lift = {1.5, 1.5, 2.0, 8},
            FinalRagdoll = 0.38
        },
        Dash = {
            Cooldown = 0.78,
            Duration = 0.16,
            Invulnerable = 0.115,
            ForwardSpeed = 78,
            BackSpeed = 66,
            SideSpeed = 72
        },
        Block = {
            WalkSpeed = 8,
            DamageMultiplier = 0.10
        },
        Special = {
            Cooldown = 4.0
        },
        Skill = {
            MinCooldown = 0.25,
            MaxCooldown = 10.0
        },
        Hitstop = 0.045
    },
    Movement = {
        WalkSpeed = 16,
        JumpPower = 50
    },
    PerfectCombo = {
        StepWindow = 1.15
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
        OpeningStun = 1.05,
        TimeoutReset = 0.15
    },
    AntiCheat = {
        Window = 1,
        MaxActions = 18,
        MaxPayloadLength = 40,
        SuspiciousStrikes = 8
    }
}

return Config