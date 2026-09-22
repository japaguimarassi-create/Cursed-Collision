local Movesets = {
    PotentialMan = {
        {Name="Shadow Jab", Type="Melee", Range=8, Damage=14, Stun=0.34, Knockback=24, Cooldown=0.55, Tag="ShadowJab"},
        {Name="Shade Step", Type="Mobility", Range=10, Damage=16, Stun=0.35, Knockback=34, Cooldown=1.2, Tag="ShadeStep"},
        {Name="Shadow Bind", Type="Control", Range=13, Damage=12, Stun=0.85, Knockback=0, Cooldown=2.4, Tag="ShadowBind"},
        {Name="Shadow Burst", Type="Burst", Radius=11, Damage=30, Stun=0.72, Knockback=68, Cooldown=5.0, Tag="ShadowBurst"}
    },
    Yuji = {
        {Name="Divergent Fist", Type="Melee", Range=8, Damage=14, Stun=0.32, Knockback=18, Cooldown=0.45, Tag="CursedStrikes"},
        {Name="Black Flash", Type="Melee", Range=8, Damage=18, Stun=0.44, Knockback=30, Cooldown=0.7, Tag="DivergentFist"},
        {Name="Black Flash", Type="Melee", Range=9, Damage=26, Stun=0.7, Knockback=58, Cooldown=4.2, Tag="BlackFlash", RequiresAwakening=false},
        {Name="Manji Kick", Type="Melee", Range=9, Damage=20, Stun=0.5, Knockback=52, Cooldown=2.4, Tag="ManjiKick"}
    },
    Gojo = {
        {Name="Lapse Blue", Type="Control", Range=18, Damage=16, Stun=0.38, Knockback=0, Cooldown=1.2, Tag="Blue", Pull=62},
        {Name="Limitless Shift", Type="Burst", Radius=13, Damage=23, Stun=0.55, Knockback=82, Cooldown=2.4, Tag="Red"},
        {Name="Limitless Shift", Type="Mobility", Range=12, Damage=12, Stun=0.3, Knockback=38, Cooldown=1.7, Tag="LimitlessShift"},
        {Name="Hollow Purple", Type="Projectile", Range=30, Damage=42, Stun=0.9, Knockback=118, Cooldown=8.5, Tag="HollowPurple"}
    },
    Sukuna = {
        {Name="Cursed Slash", Type="Projectile", Range=22, Damage=17, Stun=0.35, Knockback=28, Cooldown=0.95, Tag="Dismantle"},
        {Name="Shrine Stance", Type="Area", Radius=10, Damage=22, Stun=0.45, Knockback=36, Cooldown=1.5, Tag="Cleave"},
        {Name="Fire Arrow", Type="Projectile", Range=25, Damage=29, Stun=0.55, Knockback=62, Cooldown=3.0, Tag="FireArrow"},
        {Name="World Cutting Slash", Type="Projectile", Range=34, Damage=48, Stun=1.0, Knockback=110, Cooldown=9.0, Tag="WorldCuttingSlash"}
    },
    Megumi = {
        {Name="Shikigami Assault", Type="Melee", Range=11, Damage=16, Stun=0.4, Knockback=34, Cooldown=1.0, Tag="DivineDogs"},
        {Name="Ten Shadows", Type="Projectile", Range=24, Damage=20, Stun=0.42, Knockback=48, Cooldown=1.9, Tag="Nue"},
        {Name="Max Elephant", Type="Area", Radius=12, Damage=25, Stun=0.55, Knockback=72, Cooldown=3.1, Tag="MaxElephant"},
        {Name="Shadow Garden", Type="Control", Radius=15, Damage=12, Stun=0.25, Knockback=12, Cooldown=6.5, Tag="ShadowGarden"}
    },
    Yuta = {
        {Name="Rika Sword", Type="Melee", Range=10, Damage=17, Stun=0.4, Knockback=38, Cooldown=0.9, Tag="RikaRush"},
        {Name="Copy / Rika", Type="Melee", Range=11, Damage=22, Stun=0.5, Knockback=46, Cooldown=1.6, Tag="CopyBlade"},
        {Name="Cursed Speech", Type="Control", Range=16, Damage=10, Stun=1.0, Knockback=0, Cooldown=4.0, Tag="CursedSpeech"},
        {Name="Rika Barrage", Type="Burst", Radius=11, Damage=28, Stun=0.65, Knockback=70, Cooldown=5.0, Tag="RikaBarrage"}
    },
    Maki = {
        {Name="Tool Strike", Type="Melee", Range=9, Damage=19, Stun=0.42, Knockback=34, Cooldown=0.8, Tag="KatanaRush"},
        {Name="Arsenal Shift", Type="Area", Radius=9, Damage=22, Stun=0.45, Knockback=48, Cooldown=1.8, Tag="NaginataSweep"},
        {Name="Chain Lance", Type="Projectile", Range=18, Damage=20, Stun=0.5, Knockback=58, Cooldown=2.5, Tag="ChainLance"},
        {Name="Tool Vault", Type="Mobility", Range=10, Damage=26, Stun=0.55, Knockback=62, Cooldown=4.0, Tag="ToolVault"}
    },
    Toji = {
        {Name="Assassin Strike", Type="Melee", Range=10, Damage=24, Stun=0.46, Knockback=44, Cooldown=1.0, Tag="SplitSoulCut"},
        {Name="Arsenal Shift", Type="Melee", Range=9, Damage=20, Stun=0.4, Knockback=36, Cooldown=1.2, Tag="InventoryStrike"},
        {Name="Chain Trap", Type="Control", Range=18, Damage=12, Stun=0.9, Knockback=0, Cooldown=3.2, Tag="ChainTrap"},
        {Name="Heavenly Ambush", Type="Mobility", Range=14, Damage=30, Stun=0.62, Knockback=76, Cooldown=4.8, Tag="HeavenlyAmbush"}
    },
    Mahito = {
        {Name="Idle Transfiguration", Type="Melee", Range=8, Damage=16, Stun=0.55, Knockback=30, Cooldown=1.0, Tag="TransfiguredPalm"},
        {Name="Body Morph", Type="Mobility", Range=9, Damage=19, Stun=0.45, Knockback=40, Cooldown=1.8, Tag="IdleMorph"},
        {Name="Soul Touch", Type="Control", Range=8, Damage=14, Stun=0.85, Knockback=0, Cooldown=3.2, Tag="SoulTouch"},
        {Name="Instant Spirit Collapse", Type="Burst", Radius=12, Damage=34, Stun=0.85, Knockback=72, Cooldown=7.5, Tag="InstantSpiritCollapse"}
    },
    Todo = {
        {Name="Boogie Woogie", Type="Utility", Range=20, Damage=12, Stun=0.3, Knockback=20, Cooldown=1.0, Tag="ClapSwap"},
        {Name="Clap / Switch", Type="Melee", Range=9, Damage=20, Stun=0.48, Knockback=48, Cooldown=1.2, Tag="BoogieKick"},
        {Name="Feint Switch", Type="Mobility", Range=11, Damage=16, Stun=0.4, Knockback=42, Cooldown=2.4, Tag="FeintSwitch"},
        {Name="Four-Way Boogie", Type="Area", Radius=12, Damage=24, Stun=0.7, Knockback=64, Cooldown=5.8, Tag="FourWayBoogie"}
    },
    Hakari = {
        {Name="Private Pure Love", Type="Melee", Range=9, Damage=17, Stun=0.35, Knockback=28, Cooldown=0.85, Tag="PachinkoPunch"},
        {Name="Jackpot Roll", Type="Control", Radius=10, Damage=14, Stun=0.5, Knockback=30, Cooldown=2.0, Tag="PrivatePureLove"},
        {Name="Jackpot Rush", Type="Mobility", Range=11, Damage=23, Stun=0.5, Knockback=54, Cooldown=2.8, Tag="JackpotRush"},
        {Name="Reverse Beat", Type="Burst", Radius=10, Damage=30, Stun=0.65, Knockback=76, Cooldown=5.5, Tag="ReverseBeat"}
    },
    Choso = {
        {Name="Piercing Blood", Type="Melee", Range=9, Damage=18, Stun=0.42, Knockback=30, Cooldown=0.9, Tag="BloodEdge"},
        {Name="Blood Burst", Type="Projectile", Range=30, Damage=25, Stun=0.45, Knockback=68, Cooldown=2.0, Tag="PiercingBlood"},
        {Name="Slicing Exorcism", Type="Projectile", Range=20, Damage=21, Stun=0.4, Knockback=44, Cooldown=2.4, Tag="SlicingExorcism"},
        {Name="Supernova", Type="Area", Radius=13, Damage=36, Stun=0.8, Knockback=74, Cooldown=6.2, Tag="Supernova"}
    },
    Kashimo = {
        {Name="Electrified Strike", Type="Melee", Range=9, Damage=19, Stun=0.5, Knockback=34, Cooldown=0.8, Tag="LightningPalm"},
        {Name="Charge Burst", Type="Melee", Range=11, Damage=24, Stun=0.55, Knockback=48, Cooldown=1.6, Tag="StaffBreak"},
        {Name="Lightning Flash", Type="Projectile", Range=24, Damage=26, Stun=0.5, Knockback=72, Cooldown=2.6, Tag="LightningFlash"},
        {Name="Mythical Discharge", Type="Burst", Radius=12, Damage=40, Stun=0.85, Knockback=96, Cooldown=7.2, Tag="MythicalDischarge"}
    },
    Naoya = {
        {Name="Projection Strike", Type="Mobility", Range=12, Damage=15, Stun=0.35, Knockback=30, Cooldown=0.7, Tag="FrameDash"},
        {Name="Frame Step", Type="Melee", Range=12, Damage=21, Stun=0.42, Knockback=50, Cooldown=1.1, Tag="ProjectionRush"},
        {Name="Time Cell", Type="Control", Range=17, Damage=14, Stun=0.95, Knockback=0, Cooldown=3.0, Tag="TimeCell"},
        {Name="24 FPS Collapse", Type="Area", Radius=14, Damage=34, Stun=0.9, Knockback=80, Cooldown=7.0, Tag="24FPSCollapse"}
    },
    Kenjaku = {
        {Name="Cursed Spirit Burst", Type="Projectile", Range=23, Damage=18, Stun=0.4, Knockback=40, Cooldown=1.0, Tag="CursedSpiritShot"},
        {Name="Technique Stock", Type="Control", Radius=12, Damage=16, Stun=0.7, Knockback=0, Cooldown=2.8, Tag="GravityWell"},
        {Name="Antigravity", Type="Mobility", Range=12, Damage=20, Stun=0.42, Knockback=52, Cooldown=2.5, Tag="Antigravity"},
        {Name="Maximum Uzumaki", Type="Projectile", Range=30, Damage=44, Stun=0.9, Knockback=106, Cooldown=8.0, Tag="MaximumUzumaki"}
    },
    Jogo = {
        {Name="Volcanic Burst", Type="Projectile", Range=22, Damage=19, Stun=0.38, Knockback=42, Cooldown=0.9, Tag="EmberInflux"},
        {Name="Ember", Type="Melee", Range=9, Damage=20, Stun=0.46, Knockback=48, Cooldown=1.3, Tag="VolcanoPunch"},
        {Name="Meteor Call", Type="Area", Radius=14, Damage=31, Stun=0.7, Knockback=84, Cooldown=4.5, Tag="MeteorCall"},
        {Name="Maximum Meteor", Type="Projectile", Range=36, Damage=50, Stun=1.0, Knockback=126, Cooldown=9.5, Tag="MaximumMeteor"}
    },
    Dagon = {
        {Name="Death Swarm", Type="Melee", Range=10, Damage=16, Stun=0.38, Knockback=34, Cooldown=0.95, Tag="WaterShikigami"},
        {Name="Water Shikigami", Type="Control", Range=18, Damage=15, Stun=0.5, Knockback=0, Cooldown=2.2, Tag="OceanPull", Pull=46},
        {Name="Death Swarm", Type="Area", Radius=14, Damage=28, Stun=0.65, Knockback=50, Cooldown=4.2, Tag="DeathSwarm"},
        {Name="Domain Current", Type="Burst", Radius=16, Damage=38, Stun=0.9, Knockback=92, Cooldown=7.0, Tag="DomainCurrent"}
    },
    Hanami = {
        {Name="Disaster Plants", Type="Projectile", Range=20, Damage=20, Stun=0.5, Knockback=42, Cooldown=1.1, Tag="RootSpear"},
        {Name="Root Grab", Type="Burst", Radius=10, Damage=22, Stun=0.48, Knockback=46, Cooldown=2.0, Tag="BudBurst"},
        {Name="Branch Bind", Type="Control", Range=14, Damage=13, Stun=0.9, Knockback=0, Cooldown=3.4, Tag="BranchBind"},
        {Name="Disaster Bloom", Type="Area", Radius=15, Damage=36, Stun=0.85, Knockback=66, Cooldown=7.0, Tag="DisasterBloom"}
    },
    Higuruma = {
        {Name="Judgment Strike", Type="Melee", Range=9, Damage=19, Stun=0.5, Knockback=36, Cooldown=0.95, Tag="GavelStrike"},
        {Name="Evidence", Type="Control", Range=15, Damage=12, Stun=0.85, Knockback=0, Cooldown=2.3, Tag="JudgmentMark"},
        {Name="Confiscation", Type="Burst", Radius=10, Damage=25, Stun=0.65, Knockback=45, Cooldown=4.0, Tag="Confiscation"},
        {Name="Executioner Sword", Type="Melee", Range=11, Damage=40, Stun=0.95, Knockback=86, Cooldown=7.8, Tag="ExecutionerSword"}
    },
    Takaba = {
        {Name="Comedian", Type="Melee", Range=8, Damage=15, Stun=0.4, Knockback=30, Cooldown=0.9, Tag="JokePunch"},
        {Name="Reality Twist", Type="Utility", Range=18, Damage=17, Stun=0.55, Knockback=44, Cooldown=2.1, Tag="RealityTwist"},
        {Name="Comedic Counter", Type="Control", Range=10, Damage=12, Stun=0.9, Knockback=0, Cooldown=3.6, Tag="ComedicCounter"},
        {Name="Unfunny Finale", Type="Burst", Radius=14, Damage=38, Stun=0.85, Knockback=88, Cooldown=7.5, Tag="UnfunnyFinale"}
    },
    Uraume = {
        {Name="Ice Formation", Type="Melee", Range=9, Damage=17, Stun=0.46, Knockback=30, Cooldown=0.9, Tag="FrostPalm"},
        {Name="Frost Calamity", Type="Control", Radius=11, Damage=15, Stun=0.65, Knockback=24, Cooldown=2.4, Tag="IceFormation"},
        {Name="Frozen Coffin", Type="Area", Radius=13, Damage=29, Stun=0.85, Knockback=62, Cooldown=4.6, Tag="FrozenCoffin"},
        {Name="Icefall", Type="Burst", Radius=15, Damage=40, Stun=0.95, Knockback=92, Cooldown=7.8, Tag="Icefall"}
    },
    Yorozu = {
        {Name="Liquid Metal", Type="Melee", Range=9, Damage=18, Stun=0.42, Knockback=34, Cooldown=0.95, Tag="LiquidMetal"},
        {Name="Construction Armor", Type="Utility", Range=8, Damage=20, Stun=0.5, Knockback=38, Cooldown=2.3, Tag="ConstructionArmor"},
        {Name="Insect Blade", Type="Melee", Range=12, Damage=23, Stun=0.52, Knockback=48, Cooldown=2.0, Tag="InsectBlade"},
        {Name="Perfect Sphere", Type="Projectile", Range=28, Damage=46, Stun=1.0, Knockback=118, Cooldown=8.5, Tag="PerfectSphere"}
    },
    Ryu = {
        {Name="Granite Shot", Type="Projectile", Range=27, Damage=24, Stun=0.45, Knockback=72, Cooldown=1.8, Tag="GraniteShot"},
        {Name="Maximum Charge", Type="Burst", Radius=10, Damage=25, Stun=0.5, Knockback=55, Cooldown=2.1, Tag="CursedBurst"},
        {Name="Output Drive", Type="Melee", Range=10, Damage=26, Stun=0.55, Knockback=64, Cooldown=2.5, Tag="OutputDrive"},
        {Name="Granite Blast", Type="Projectile", Range=36, Damage=52, Stun=1.0, Knockback=130, Cooldown=8.8, Tag="GraniteBlast"}
    },
    Uro = {
        {Name="Sky Strike", Type="Control", Range=16, Damage=15, Stun=0.55, Knockback=0, Cooldown=1.4, Tag="SkyBend"},
        {Name="Sky Distortion", Type="Projectile", Range=20, Damage=23, Stun=0.52, Knockback=58, Cooldown=2.2, Tag="ThinIceBreaker"},
        {Name="Sky Distortion", Type="Area", Radius=12, Damage=28, Stun=0.65, Knockback=68, Cooldown=4.0, Tag="SkyDistortion"},
        {Name="Sky Shatter", Type="Burst", Radius=15, Damage=40, Stun=0.9, Knockback=108, Cooldown=7.6, Tag="SkyShatter"}
    },
    Kusakabe = {
        {Name="New Shadow Slash", Type="Melee", Range=10, Damage=20, Stun=0.46, Knockback=42, Cooldown=0.85, Tag="NewShadowSlash"},
        {Name="Simple Domain", Type="Control", Radius=10, Damage=12, Stun=0.55, Knockback=18, Cooldown=2.5, Tag="SimpleDomain"},
        {Name="Batto Sweep", Type="Melee", Range=12, Damage=25, Stun=0.58, Knockback=58, Cooldown=2.6, Tag="BattoSweep"},
        {Name="Evening Moon", Type="Melee", Range=14, Damage=42, Stun=0.95, Knockback=104, Cooldown=7.5, Tag="EveningMoon"}
    }
}

local function copyMove(move)
    local clone = {}
    for key, value in pairs(move) do
        clone[key] = value
    end
    return clone
end

function Movesets.Get(id)
    local source = Movesets[id] or Movesets.Yuji
    local result = {}
    for index, move in ipairs(source) do
        result[index] = copyMove(move)
        result[index].Slot = index
    end
    return result
end

function Movesets.GetMove(id, slot)
    local source = Movesets[id] or Movesets.Yuji
    return source[slot]
end

return Movesets
