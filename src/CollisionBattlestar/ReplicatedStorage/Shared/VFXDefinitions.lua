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
	Reality=Color3.fromRGB(197,92,255),
}
V.Limits={
	MaxEffects=40,
	ImpactLifetime=.35,
	HeavyLifetime=.55,
	DashLifetime=.3,
	OverdriveLifetime=.7,
	BladeTrailLifetime=.13,
	ShockwaveLifetime=.32,
	RealityPulseLifetime=.8,
}
V.BladeTrail={Lifetime=.13,Width=Vector2.new(1.05,.08),MinLength=.08,Fade=.12}
V.Shockwave={Thickness=.2,Duration=.32,Expansion=4}
V.RealityBreak={WarningStrength=.55,BeginStrength=.75,EscalationStrength=1,ClimaxStrength=1.35,EndDuration=1.2}
return V
