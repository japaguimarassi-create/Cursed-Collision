local Profiles = {
    Yuji = {
        Id="Yuji", Name="Yuji Itadori", Subtitle="Black Flash Momentum",
        SpecialCooldown=0.55, SkillCooldown=0.7, AwakeningName="Divergent Soul", Domain="YujiDomain", DomainRadius=34, DomainDuration=18,
        Unique="Momentum", PerfectCombo={"Skill","Special","M1","M1"}, OneTimeName="Soul Impact"
    },
    Gojo = {
        Id="Gojo", Name="Satoru Gojo", Subtitle="Infinity Management",
        SpecialCooldown=0.65, SkillCooldown=0.5, AwakeningName="Six Eyes Unleashed", Domain="UnlimitedVoid", DomainRadius=36, DomainDuration=18,
        Unique="Infinity", PerfectCombo={"Skill","Special","M1","Special"}, OneTimeName="Hollow Purple: Maximum"
    },
    Sukuna = {
        Id="Sukuna", Name="Ryomen Sukuna", Subtitle="Shrine / Slash Adaptation",
        SpecialCooldown=0.58, SkillCooldown=0.65, AwakeningName="King of Curses", Domain="MalevolentShrine", DomainRadius=40, DomainDuration=18,
        Unique="Slash Adaptation", PerfectCombo={"Special","Skill","Special","M1"}, OneTimeName="World Cutting Shrine"
    },
    Megumi = {
        Id="Megumi", Name="Megumi Fushiguro", Subtitle="Ten Shadows / Shikigami Management",
        SpecialCooldown=0.72, SkillCooldown=0.55, AwakeningName="Chimera Shadow", Domain="ChimeraShadowGarden", DomainRadius=34, DomainDuration=18,
        Unique="Shikigami", PerfectCombo={"Skill","Special","Skill","M1"}, OneTimeName="Mahoraga Adaptation"
    },
    Yuta = {
        Id="Yuta", Name="Yuta Okkotsu", Subtitle="Rika / Copy Slots",
        SpecialCooldown=0.62, SkillCooldown=0.62, AwakeningName="Rika Unleashed", Domain="AuthenticLove", DomainRadius=35, DomainDuration=18,
        Unique="Copy Slots", PerfectCombo={"Special","Skill","M1","Special"}, OneTimeName="Copy Barrage"
    },
    Maki = {
        Id="Maki", Name="Maki Zenin", Subtitle="Heavenly Restriction / Cursed Tools",
        SpecialCooldown=0.5, SkillCooldown=0.58, AwakeningName="Heavenly Restriction", Domain=nil,
        Unique="Cursed Tool Arsenal", PerfectCombo={"M1","Skill","Special","M1"}, OneTimeName="Dragon Bone Breaker"
    },
    Toji = {
        Id="Toji", Name="Toji Fushiguro", Subtitle="Heavenly Restriction / Weapon Mastery",
        SpecialCooldown=0.48, SkillCooldown=0.52, AwakeningName="Sorcerer Killer", Domain=nil,
        Unique="Cursed Tool Arsenal", PerfectCombo={"Skill","M1","Special","M1"}, OneTimeName="Split Soul Cut"
    },
    Mahito = {
        Id="Mahito", Name="Mahito", Subtitle="Soul Integrity / Idle Transfiguration",
        SpecialCooldown=0.68, SkillCooldown=0.65, AwakeningName="Instant Spirit Body", Domain="SelfEmbodiment", DomainRadius=32, DomainDuration=16,
        Unique="Soul Integrity", PerfectCombo={"Skill","Special","M1","Skill"}, OneTimeName="Instant Spirit Collapse"
    },
    Todo = {
        Id="Todo", Name="Aoi Todo", Subtitle="Boogie Woogie",
        SpecialCooldown=0.58, SkillCooldown=0.45, AwakeningName="Boogie Woogie Encore", Domain=nil,
        Unique="Swap Network", PerfectCombo={"Skill","Special","Skill","M1"}, OneTimeName="Four-Way Boogie"
    },
    Hakari = {
        Id="Hakari", Name="Kinji Hakari", Subtitle="Jackpot Probability",
        SpecialCooldown=0.62, SkillCooldown=0.72, AwakeningName="Jackpot", Domain="IdleDeathGamble", DomainRadius=32, DomainDuration=22,
        Unique="Jackpot", PerfectCombo={"Special","Skill","Special","M1"}, OneTimeName="Unlimited Jackpot"
    },
    Choso = {
        Id="Choso", Name="Choso", Subtitle="Blood Management",
        SpecialCooldown=0.6, SkillCooldown=0.56, AwakeningName="Blood Edge", Domain=nil,
        Unique="Blood", PerfectCombo={"Skill","Special","M1","Special"}, OneTimeName="Supernova: Maximum"
    },
    Kashimo = {
        Id="Kashimo", Name="Hajime Kashimo", Subtitle="Electrical Charge",
        SpecialCooldown=0.55, SkillCooldown=0.52, AwakeningName="Mythical Beast Amber", Domain=nil,
        Unique="Electrical Charge", PerfectCombo={"M1","Special","Skill","M1"}, OneTimeName="Mythical Discharge"
    },
    Naoya = {
        Id="Naoya", Name="Naoya Zenin", Subtitle="Projection Sorcery Frames",
        SpecialCooldown=0.5, SkillCooldown=0.38, AwakeningName="Worm Projection", Domain=nil,
        Unique="Frame Sequence", PerfectCombo={"Skill","Skill","Special","M1"}, OneTimeName="24 FPS Collapse"
    },
    Kenjaku = {
        Id="Kenjaku", Name="Kenjaku", Subtitle="Cursed Spirit Arsenal",
        SpecialCooldown=0.7, SkillCooldown=0.65, AwakeningName="Technique Extraction", Domain="WombProfusion", DomainRadius=37, DomainDuration=18,
        Unique="Technique Stock", PerfectCombo={"Skill","Special","M1","Skill"}, OneTimeName="Maximum Uzumaki"
    },
    Jogo = {
        Id="Jogo", Name="Jogo", Subtitle="Volcanic Heat",
        SpecialCooldown=0.57, SkillCooldown=0.6, AwakeningName="Volcanic Caldera", Domain="CoffinOfTheIronMountain", DomainRadius=34, DomainDuration=18,
        Unique="Heat", PerfectCombo={"Special","Skill","M1","Special"}, OneTimeName="Meteor"
    },
    Dagon = {
        Id="Dagon", Name="Dagon", Subtitle="Oceanic Shikigami",
        SpecialCooldown=0.65, SkillCooldown=0.62, AwakeningName="Horizon of Captivating Skandha", Domain="HorizonOfCaptivatingSkandha", DomainRadius=38, DomainDuration=18,
        Unique="Tide", PerfectCombo={"Skill","Special","Skill","M1"}, OneTimeName="Death Swarm"
    },
    Hanami = {
        Id="Hanami", Name="Hanami", Subtitle="Roots / Disaster Plants",
        SpecialCooldown=0.66, SkillCooldown=0.6, AwakeningName="Disaster Bloom", Domain=nil,
        Unique="Roots", PerfectCombo={"Special","Skill","M1","Skill"}, OneTimeName="Flower Field Crush"
    },
    Higuruma = {
        Id="Higuruma", Name="Hiromi Higuruma", Subtitle="Evidence / Deadly Sentencing",
        SpecialCooldown=0.62, SkillCooldown=0.7, AwakeningName="Execution", Domain="DeadlySentencing", DomainRadius=30, DomainDuration=18,
        Unique="Evidence", PerfectCombo={"Skill","Special","M1","Special"}, OneTimeName="Executioner Sword"
    },
    Takaba = {
        Id="Takaba", Name="Fumihiko Takaba", Subtitle="Comedian Context",
        SpecialCooldown=0.75, SkillCooldown=0.8, AwakeningName="Reality Joke", Domain=nil,
        Unique="Comedy Context", PerfectCombo={"Skill","M1","Special","Skill"}, OneTimeName="Unfunny Finale"
    },
    Uraume = {
        Id="Uraume", Name="Uraume", Subtitle="Ice Formation",
        SpecialCooldown=0.62, SkillCooldown=0.58, AwakeningName="Frozen Coffin", Domain=nil,
        Unique="Frost", PerfectCombo={"Special","Skill","M1","Special"}, OneTimeName="Icefall"
    },
    Yorozu = {
        Id="Yorozu", Name="Yorozu", Subtitle="Construction / Liquid Metal",
        SpecialCooldown=0.66, SkillCooldown=0.62, AwakeningName="Perfect Sphere", Domain=nil,
        Unique="Construction", PerfectCombo={"Skill","Special","M1","Skill"}, OneTimeName="Perfect Sphere"
    },
    Ryu = {
        Id="Ryu", Name="Ryu Ishigori", Subtitle="Granite Output",
        SpecialCooldown=0.58, SkillCooldown=0.62, AwakeningName="Maximum Output", Domain=nil,
        Unique="Output Charge", PerfectCombo={"M1","M1","Special","Skill"}, OneTimeName="Granite Blast"
    },
    Uro = {
        Id="Uro", Name="Takako Uro", Subtitle="Sky Manipulation",
        SpecialCooldown=0.63, SkillCooldown=0.55, AwakeningName="Thin Ice Breaker", Domain=nil,
        Unique="Sky Distortion", PerfectCombo={"Skill","Special","M1","Skill"}, OneTimeName="Sky Shatter"
    },
    Kusakabe = {
        Id="Kusakabe", Name="Atsuya Kusakabe", Subtitle="Simple Domain / New Shadow Style",
        SpecialCooldown=0.55, SkillCooldown=0.5, AwakeningName="Simple Domain Mastery", Domain=nil,
        Unique="Simple Domain Stance", PerfectCombo={"Skill","M1","Special","M1"}, OneTimeName="Evening Moon Sword"
    }
}

return Profiles