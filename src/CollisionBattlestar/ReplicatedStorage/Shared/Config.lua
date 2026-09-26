--!strict
local C={}
C.GameName="Collision Battlestar"
C.Version="3.0.0"
C.BuildTag="collision-battlestar-rebuild-2026-09-26"
C.Movement={WalkSpeed=16,SprintSpeed=22,JumpPower=50}
C.Combat={RequestRate=24,ComboReset=.82,ParryWindow=.18,BlockDot=.12,Stun=.28,Dash={Cooldown=.85,Speed=74,Duration=.16},Light={Cooldown=.17,Damage={9,10,12,16},Hitbox=Vector3.new(7,6,10),Offset=5.4,Knockback={20,22,25,42}},Special={Cooldown=7,EnergyCost=35,Damage=34,OverdriveBonus=22,Radius=13,Knockback=58}}
C.Resources={MaxEnergy=100,EnergyRegen=12,HitEnergy=4,HitOverdrive=7,DamageOverdrive=.45}
C.Progression={KOReward=5,KOXP=40,HitXP=1,BaseXP=350,StepXP=175,MaxLevel=200}
C.Performance={MaxFX=8,MaxDamageTexts=5,DestructionRestore=7}
C.Map={Width=1320,DistrictSize=210,DistrictGap=55,RoadWidth=54}
C.UI={Accent=Color3.fromRGB(76,202,255),Accent2=Color3.fromRGB(180,94,255),Danger=Color3.fromRGB(255,86,100),Success=Color3.fromRGB(76,226,154),Gold=Color3.fromRGB(255,192,72),Panel=Color3.fromRGB(10,15,24),PanelSoft=Color3.fromRGB(19,27,40),PanelAlt=Color3.fromRGB(27,37,52),Text=Color3.fromRGB(245,248,253),Muted=Color3.fromRGB(145,158,177),ShopGreen=Color3.fromRGB(82,226,78)}
return C
