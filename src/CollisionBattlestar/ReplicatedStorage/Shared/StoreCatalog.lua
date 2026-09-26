--!strict
local C={}
C.Items={
    {Id="Emote_Salute",Name="Salute",Category="Emotes",Price=125,Kind="Emote",Description="Clean competitive salute."},
    {Id="Emote_Cross",Name="Cross Guard",Category="Emotes",Price=150,Kind="Emote",Description="Confident defensive pose."},
    {Id="Emote_Charge",Name="Charge Up",Category="Emotes",Price=175,Kind="Emote",Description="Short energy charge pose."},
    {Id="Emote_Point",Name="Target Lock",Category="Emotes",Price=200,Kind="Emote",Description="Point at your next target."},
    {Id="Emote_Victory",Name="Victory",Category="Emotes",Price=250,Kind="Emote",Description="Fast post-KO celebration."},
    {Id="Skin_NeonRunner",Name="Neon Runner",Category="Featured",Price=750,Kind="Skin",Description="Blue-violet urban combat palette."},
    {Id="Skin_IronCore",Name="Iron Core",Category="Featured",Price=900,Kind="Skin",Description="Industrial dark-metal palette."},
    {Id="Skin_Apex",Name="Apex Signal",Category="Featured",Price=1100,Kind="Skin",Description="High-contrast arena palette."},
    {Id="Title_Rival",Name="Rival",Category="Featured",Price=300,Kind="Title",Description="Profile title: RIVAL."},
    {Id="Title_Veteran",Name="Veteran",Category="Featured",Price=600,Kind="Title",Description="Profile title: VETERAN."},
}
C.Bundles={
    {Id="Bundle_350",Name="350 CREDITS",Robux=49},
    {Id="Bundle_1000",Name="1,000 CREDITS",Robux=119},
    {Id="Bundle_2500",Name="2,500 CREDITS",Robux=239},
    {Id="Bundle_5000",Name="5,000 CREDITS",Robux=399},
    {Id="Bundle_7500",Name="7,500 CREDITS",Robux=849},
    {Id="Bundle_15000",Name="15,000 CREDITS",Robux=2499},
    {Id="Bundle_30000",Name="30,000 CREDITS",Robux=5399,Best=true},
}
function C.Get(id:string)
    for _,item in ipairs(C.Items) do
        if item.Id==id then return item end
    end
    return nil
end
return C
