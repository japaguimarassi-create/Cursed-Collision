--!strict
local D={}
D.Actions={"Light","Dash","Block","Special"}
D.Keybinds={Dash=Enum.KeyCode.Q,Block=Enum.KeyCode.F,Special=Enum.KeyCode.R,Map=Enum.KeyCode.M,Sprint=Enum.KeyCode.LeftShift}
D.Slots={
	{Id="Light",Label="M1",Hint="LMB",Key=Enum.KeyCode.MouseButton1},
	{Id="Dash",Label="DASH",Hint="Q",Key=Enum.KeyCode.Q},
	{Id="Block",Label="GUARD",Hint="F",Key=Enum.KeyCode.F},
	{Id="Special",Label="SPECIAL",Hint="R",Key=Enum.KeyCode.R},
}
return D
