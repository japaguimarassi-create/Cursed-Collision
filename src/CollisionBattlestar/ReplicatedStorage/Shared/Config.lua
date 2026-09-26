--!strict
local C={}
C.GameName="Collision Battlestar"
C.Version=2
C.MapSize=1320
C.SpawnPosition=Vector3.new(-520,4,0)
C.Movement={WalkSpeed=16,SprintSpeed=23,JumpPower=50}
C.Combat={
	RequestRate=22,
	ComboReset=.82,
	ParryWindow=.20,
	BlockMultiplier=.16,
	FrontBlockDot=.15,
	Stun=.24,
	Dash={Cooldown=.95,Speed=82,Duration=.16},
	Actions={
		Light={Cooldown=.16,Damage=9,Size=Vector3.new(7.5,6.5,10.5),Offset=5,Knockback=25},
		Special={Cooldown=7.5,Damage=32,Radius=15,Knockback=64,OverdriveBonus=18},
	},
	ComboDamage={ [1]=9,[2]=10,[3]=12,[4]=16 },
}
C.Progression={KOReward=5,KOXP=40,HitXP=1,LevelBase=350,LevelStep=175}
C.Map={Width=1320,Depth=760,RoadWidth=58,SidewalkWidth=10,BlockGap=18,BuildingChance=.86}
C.UI={
	Accent=Color3.fromRGB(94,205,255),
	Accent2=Color3.fromRGB(176,112,255),
	Danger=Color3.fromRGB(255,94,94),
	Panel=Color3.fromRGB(15,18,24),
	PanelAlt=Color3.fromRGB(25,30,39),
	PanelSoft=Color3.fromRGB(34,40,50),
	Text=Color3.fromRGB(244,247,252),
	Muted=Color3.fromRGB(146,155,169),
	Success=Color3.fromRGB(98,232,157),
}
C.Assets={Bench=400850371,Dumpster=42942436,Car=282662596}
return C
