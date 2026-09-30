--!strict
local Items={
    Skin_UrbanShadow={ItemId="Skin_UrbanShadow",Category="Skin",Price=125,DisplayName="Urban Shadow",Description="A clean tactical skin for your profile.",Stackable=false},
    Skin_NeonCircuit={ItemId="Skin_NeonCircuit",Category="Skin",Price=225,DisplayName="Neon Circuit",Description="A bright collision-tech style.",Stackable=false},
    Skin_ArcticPulse={ItemId="Skin_ArcticPulse",Category="Skin",Price=325,DisplayName="Arctic Pulse",Description="Cold steel with a bright accent.",Stackable=false},
    Echo_Vanguard={ItemId="Echo_Vanguard",Category="Echo",Price=250,DisplayName="Vanguard Echo",Description="Close-range protector.",Stackable=false},
    Echo_Striker={ItemId="Echo_Striker",Category="Echo",Price=350,DisplayName="Striker Echo",Description="Long-range Elite hunter.",Stackable=false},
    Echo_Guardian={ItemId="Echo_Guardian",Category="Echo",Price=300,DisplayName="Guardian Echo",Description="Protective frontline Echo.",Stackable=false},
    Echo_Support={ItemId="Echo_Support",Category="Echo",Price=300,DisplayName="Support Echo",Description="A combat medic Echo.",Stackable=false},
}
return {Items=table.freeze(Items)}
