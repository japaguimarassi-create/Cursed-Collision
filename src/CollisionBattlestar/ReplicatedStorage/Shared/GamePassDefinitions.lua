--!strict
export type PassDefinition={Id:number,TargetPrice:number,Category:string,Actions:{string},Enabled:boolean}
export type DefinitionMap={[string]:PassDefinition}

local P:DefinitionMap={
	VIPBattlestar={Id=1998326480,TargetPrice=59,Category="Premium",Actions={"VipTag","VipArea","VipChatStyle"},Enabled=true},
	KillEffects={Id=1999886466,TargetPrice=49,Category="Cosmetic",Actions={"EquipKillEffect"},Enabled=true},
	KillSounds={Id=1998290500,TargetPrice=39,Category="Cosmetic",Actions={"EquipKillSound"},Enabled=true},
	AuraCollection={Id=1998770486,TargetPrice=49,Category="Cosmetic",Actions={"EquipAura"},Enabled=true},
	EmoteMaster={Id=1999034470,TargetPrice=35,Category="Cosmetic",Actions={"UsePremiumEmote"},Enabled=true},
	FinisherCollection={Id=1999298510,TargetPrice=59,Category="Cosmetic",Actions={"UseFinisher"},Enabled=true},
	NameplatePlus={Id=1997834514,TargetPrice=25,Category="Cosmetic",Actions={"UsePremiumNameplate"},Enabled=true},
	SpawnEffects={Id=1999358487,TargetPrice=29,Category="Cosmetic",Actions={"UseSpawnEffect"},Enabled=true},
	DomainCollection={Id=1999940469,TargetPrice=59,Category="Premium",Actions={"UseDomainCosmetic"},Enabled=true},
	AwakeningVault={Id=1999832493,TargetPrice=60,Category="Premium",Actions={"UseAwakeningSkin"},Enabled=true},
	RiftExplorer={Id=1999688503,TargetPrice=45,Category="World",Actions={"EnterRiftExplorer"},Enabled=true},
	BattleArchitect={Id=1999568482,TargetPrice=55,Category="PrivateServer",Actions={"ConfigurePrivateServer"},Enabled=true},
	InventoryPlus={Id=1999064496,TargetPrice=25,Category="Convenience",Actions={"UseExtraInventory"},Enabled=true},
	QuestExpansion={Id=1999772485,TargetPrice=20,Category="Convenience",Actions={"UseExtraQuestSlots"},Enabled=true},
	CreditBooster={Id=1998380489,TargetPrice=30,Category="Convenience",Actions={"CreditBoost"},Enabled=true},
	Founder={Id=1998008493,TargetPrice=60,Category="Exclusive",Actions={"FounderCosmetics"},Enabled=true},
	PremiumCombatHUD={Id=1998188485,TargetPrice=29,Category="Cosmetic",Actions={"UsePremiumCombatHUD"},Enabled=true},
	RealityAura={Id=1999448482,TargetPrice=45,Category="Cosmetic",Actions={"UseRealityAura"},Enabled=true},
	VictoryPosePack={Id=1998482487,TargetPrice=25,Category="Cosmetic",Actions={"UseVictoryPose"},Enabled=true},
	BattleStreakBanner={Id=2000018489,TargetPrice=35,Category="Cosmetic",Actions={"UseBattleStreakBanner"},Enabled=true},
	ProfileShowcase={Id=1998710501,TargetPrice=40,Category="Cosmetic",Actions={"UseProfileShowcase"},Enabled=true},
	LobbyAnimations={Id=1998128491,TargetPrice=30,Category="Cosmetic",Actions={"UseLobbyAnimation"},Enabled=true},
	SpectatorFX={Id=1998986479,TargetPrice=30,Category="Cosmetic",Actions={"UseSpectatorFX"},Enabled=true},
	CinematicIntros={Id=1999004500,TargetPrice=55,Category="Premium",Actions={"UseCinematicIntro"},Enabled=true},
	CharacterPosePack={Id=1999172493,TargetPrice=20,Category="Cosmetic",Actions={"UseCharacterPose"},Enabled=true},
	DamageNumbersPlus={Id=1998020520,TargetPrice=24,Category="Cosmetic",Actions={"UsePremiumDamageNumbers"},Enabled=true},
	PremiumCrosshair={Id=1998026507,TargetPrice=22,Category="Cosmetic",Actions={"UsePremiumCrosshair"},Enabled=false}}
}

local A:{[string]:string}={}
for passKey,definition in P do
	for _,action in definition.Actions do
		A[action]=passKey
	end
end

return {Passes=P,ActionRequirements=A,MinPrice=20,MaxPrice=60}
