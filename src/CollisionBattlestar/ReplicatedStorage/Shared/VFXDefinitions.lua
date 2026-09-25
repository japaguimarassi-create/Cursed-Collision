--!strict
local V={}
V.Palette={
	Light=Color3.fromRGB(180,105,255),
	Heavy=Color3.fromRGB(90,205,255),
	Special=Color3.fromRGB(255,145,75),
	Parry=Color3.fromRGB(255,230,100),
	Dash=Color3.fromRGB(110,200,255),
	HitTaken=Color3.fromRGB(255,100,110),
	Overdrive=Color3.fromRGB(255,130,75),
	Break=Color3.fromRGB(175,76,255),
}
V.Limits={MaxEffects=40,ImpactLifetime=.35,HeavyLifetime=.55,DashLifetime=.3,OverdriveLifetime=.7}
return V
