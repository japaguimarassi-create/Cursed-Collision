--!strict
local C={}
C.GameName="Collision Battlestar"
C.Version=1
C.MapSize=1100
C.SpawnPosition=Vector3.new(-420,4,0)
C.Movement={WalkSpeed=16,SprintSpeed=22}
C.Combat={
	RequestRate=16,
	ComboReset=.8,
	ParryWindow=.18,
	BlockMultiplier=.18,
	Dash={Cooldown=1.1,Speed=78,Duration=.14},
	Actions={
		Light={Cooldown=.17,Damage=9,Size=Vector3.new(8,7,10),Offset=5,Knockback=25},
		Special={Cooldown=7,Damage=34,Radius=14,Knockback=62}
	}
}
C.UI={Accent=Color3.fromRGB(92,198,255),Panel=Color3.fromRGB(20,23,29),PanelAlt=Color3.fromRGB(29,33,41),Text=Color3.fromRGB(242,245,250),Muted=Color3.fromRGB(151,158,170)}
return C
