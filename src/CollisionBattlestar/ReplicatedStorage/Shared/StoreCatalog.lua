--!strict
local C={}
C.Items={
{Id="Emote_Salute",Name="SALUTE",Category="Emotes",Price=125,Kind="Emote",Description="A clean competitive salute."},
{Id="Emote_Charge",Name="CHARGE UP",Category="Emotes",Price=150,Kind="Emote",Description="Short energy stance."},
{Id="Emote_Point",Name="LOCK ON",Category="Emotes",Price=175,Kind="Emote",Description="Choose your next target."},
{Id="Emote_Victory",Name="VICTORY",Category="Emotes",Price=200,Kind="Emote",Description="Post-KO celebration."},
{Id="Emote_Ready",Name="READY",Category="Emotes",Price=225,Kind="Emote",Description="Competitive ready pose."},
{Id="Skin_Neon",Name="NEON VECTOR",Category="Featured",Price=750,Kind="Skin",Description="Blue-violet combat palette."},
{Id="Skin_Iron",Name="IRON CORE",Category="Featured",Price=900,Kind="Skin",Description="Industrial combat palette."},
{Id="Skin_Apex",Name="APEX SIGNAL",Category="Featured",Price=1100,Kind="Skin",Description="High-contrast arena palette."},
{Id="Title_Rival",Name="RIVAL",Category="Featured",Price=300,Kind="Title",Description="Profile title."},
{Id="Title_Veteran",Name="VETERAN",Category="Featured",Price=600,Kind="Title",Description="Profile title."}}
C.Bundles={{Id="Bundle350",Name="350 CREDITS",Robux=49},{Id="Bundle1000",Name="1,000 CREDITS",Robux=119},{Id="Bundle2500",Name="2,500 CREDITS",Robux=239},{Id="Bundle5000",Name="5,000 CREDITS",Robux=399},{Id="Bundle7500",Name="7,500 CREDITS",Robux=849},{Id="Bundle15000",Name="15,000 CREDITS",Robux=2499},{Id="Bundle30000",Name="30,000 CREDITS",Robux=5399,Best=true}}
function C.Get(id:string)
  for _,item in ipairs(C.Items) do if item.Id==id then return item end end
  return nil
end
return C
