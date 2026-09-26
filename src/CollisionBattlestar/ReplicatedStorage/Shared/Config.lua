--!strict
local C={}
C.GameName="Collision Battlestar"
C.Version="4.0.0"
C.Movement={WalkSpeed=16,SprintSpeed=23,JumpPower=50,BlockWalkSpeed=8}
C.Combat={RequestRate=18,RequestBurst=12,ComboReset=.82,M1Recovery=.14,ParryWindow=.18,BlockDot=.08,Stun=.42,HitPull=18,Dash={Cooldown=.85,Speed=72,Duration=.17,BackSpeed=62,SideSpeed=66},Light={Cooldown=.17,Damage={7,7,9,12},Hitbox=Vector3.new(7.5,6.5,8.5),Offset=4.8,Knockback={16,18,24,46}},Special={Cooldown=6.5,EnergyCost=35,BaseDamage=34,OverdriveBonus=18,Radius=12,Knockback=58},Awakening={Required=100,Duration=45,DamageMultiplier=1.18,SpecialMultiplier=1.25},Domain={Cooldown=32,Cost=100,Duration=15,Radius=37,ClashWindow=1.35,ClashDuration=15}}
C.Resources={MaxEnergy=100,EnergyRegen=14,HitEnergy=4,DamageAwakening=.35}
C.Progression={KOReward=5,KOXP=40,HitXP=1,BaseXP=300,StepXP=150,MaxLevel=200}
C.Missions={Daily={Goal=3,Reward=50},Weekly={Goal=25,Reward=300},Lifetime={Goal=100,Reward=1000}}
C.Performance={MaxFX=14,MaxDamageTexts=8,DestructionRestore=8,MaxWorldParts=900}
C.Map={Width=1460,Depth=250,DistrictWidth=240,Gap=50,RoadWidth=54}
C.UI={Accent=Color3.fromRGB(91,211,255),Accent2=Color3.fromRGB(183,112,255),Danger=Color3.fromRGB(255,92,108),Success=Color3.fromRGB(84,228,164),Gold=Color3.fromRGB(255,196,82),Panel=Color3.fromRGB(9,14,23),PanelSoft=Color3.fromRGB(16,23,34),PanelAlt=Color3.fromRGB(24,33,47),Text=Color3.fromRGB(246,248,252),Muted=Color3.fromRGB(143,157,177)}
return C