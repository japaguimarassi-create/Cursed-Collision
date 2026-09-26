--!strict
local C={}
C.GameName="Collision Battlestar";C.SchemaVersion=1
C.Region={Name="Battle Line",Size=1680,Spawn=Vector3.new(-720,4,18),EventAnchor=Vector3.new(0,6,0)}
C.Movement={WalkSpeed=16,SprintSpeed=23}
C.Combat={BaseWalkSpeed=16,MaxRequestRate=18,MomentumMax=100,InstabilityMax=100,ParryWindow=.22,BlockMultiplier=.20,Actions={
Light={Startup=.10,Recovery=.22,Cooldown=.16,Damage=9,Range=8,Width=6,Height=6,Knockback=22,MomentumGain=7},
Heavy={Startup=.34,Recovery=.42,Cooldown=1.2,Damage=24,Range=10,Width=8,Height=7,Knockback=55,MomentumGain=12,GuardBreak=true},
Special={Startup=.28,Recovery=.60,Cooldown=6,Damage=38,Range=16,Width=16,Height=12,Knockback=70,MomentumGain=18},
Dash={Cooldown=1.1,Distance=26,Duration=.16,MomentumGain=5},
Overdrive={Cooldown=18,MinimumMomentum=35,InstabilityPerAction=7,InstabilityDrain=12,Power=1.35}}}
C.Styles={Blade={Light=1,Heavy=1.1,Special=1.2,Range=1.05},Martial={Light=.92,Heavy=.95,Special=1.08,Range=.92}}
C.Enemies={
Riftling={Health=70,Speed=10,Damage=8,Range=5,Cooldown=1.4,Reward=8,Color=Color3.fromRGB(145,85,255)},
Warden={Health=130,Speed=6,Damage=12,Range=6,Cooldown=2,Reward=14,Color=Color3.fromRGB(85,125,255)},
Caster={Health=85,Speed=8,Damage=14,Range=24,Cooldown=2.4,Reward=16,Color=Color3.fromRGB(255,115,220)},
Hunter={Health=100,Speed=13,Damage=10,Range=7,Cooldown=1.1,Reward=18,Color=Color3.fromRGB(255,165,70)},
MiniBoss={Health=550,Speed=8,Damage=20,Range=10,Cooldown=1.5,Reward=90,Color=Color3.fromRGB(255,75,85)},
Boss={Health=1400,Speed=9,Damage=27,Range=12,Cooldown=1.3,Reward=250,Color=Color3.fromRGB(255,205,80)}}
C.Data={StoreName="CollisionBattlestar_Player_v1",AutosaveSeconds=120,SessionTimeoutSeconds=180,MaxRetries=5}
C.Events={FirstRealityBreakDelay=65,RealityBreakCooldown=150,ChainKillThreshold=12}
return C
