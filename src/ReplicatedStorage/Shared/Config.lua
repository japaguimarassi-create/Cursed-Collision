local Config = {
    Combat = {
        M1 = {
            Cooldown = 0.23,
            Damage = {5, 5, 6, 8},
            AirDamage = {5, 6, 7, 10},
            Range = 7,
            Width = 5,
            Height = 5,
            Stun = 0.28,
            AirStun = 0.22,
            LauncherPower = 58,
            SlamRadius = 8,
            SlamDamage = 12
        },
        Heavy = {
            Cooldown = 1.15,
            Damage = 12,
            AirDamage = 18,
            Range = 7,
            Width = 6,
            Height = 5,
            Stun = 0.55,
            Knockback = 62,
            AirKnockback = 18,
            LauncherPower = 64
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
            Duration = 0.18,
            BackSpeed = 68,
            SideSpeed = 72,
            AttackWindow = 0.14,
            AttackRange = 6.5,
            AttackWidth = 4.5,
            AttackHeight = 5
        },
        Dodge = {
            Cooldown = 1.15,
            IFrame = 0.28,
            Speed = 58
        },
        Counter = {
            Cooldown = 2.2,
            Window = 0.34,
            Stun = 0.72,
            Damage = 18,
            Knockback = 42
        },
        Block = {
            PerfectWindow = 0.16,
            PerfectStun = 0.36,
            DamageReduction = 0.78
        },
        Combo = {
            ResetAfter = 1.15,
            Max = 4,
            ChainWindow = 0.42
        },
        Air = {
            MaxHeight = 42,
            SlamSpeed = 92,
            SlamCooldown = 1.1
        },
        Wall = {
            DetectionDistance = 4.2,
            BonusDamage = 8,
            Stun = 0.55,
            RagdollDuration = 0.45
        },
        Hitstop = 0.045
    },
    Movement = {
        WalkSpeed = 16,
        CombatWalkSpeed = 17,
        BlockWalkSpeed = 8,
        JumpPower = 50,
        AirControl = 0.55,
        Acceleration = 0.18,
        Braking = 0.22,
        FallRecovery = 0.18
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
        OpeningStun = 1.05,
        TimeoutReset = 0.15
    },
    PerfectCombo = {
        StepWindow = 1.15
    },
    AntiCheat = {
        Window = 1,
        MaxActions = 22,
        MaxRemotePayloadBytes = 2048,
        SuspiciousStrikes = 6
    }
}
return Config
