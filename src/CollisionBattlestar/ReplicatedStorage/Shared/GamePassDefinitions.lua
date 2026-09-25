--!strict
export type PassDefinition={Id:number,TargetPrice:number,Category:string,Actions:{string},Enabled:boolean}
export type DefinitionMap={[string]:PassDefinition}

local P:DefinitionMap={
	VIPBattlestar={Id=0,TargetPrice=59,Category="Premium",Actions={"VipTag","VipArea","VipChatStyle"},Enabled=false}},
	KillEffects={Id=0,TargetPrice=49,Category="Cosmetic",Actions={"EquipKillEffect"},Enabled=false}},
	KillSounds={Id=0,TargetPrice=39,Category="Cosmetic",Actions={"EquipKillSound"},Enabled=false}},
	AuraCollection={Id=0,TargetPrice=49,Category="Cosmetic",Actions={"EquipAura"},Enabled=false}},
	EmoteMaster={Id=0,TargetPrice=35,Category="Cosmetic",Actions={"UsePremiumEmote"},Enabled=false}},
	FinisherCollection={Id=0,TargetPrice=59,Category="Cosmetic",Actions={"UseFinisher"},Enabled=false}},
	NameplatePlus={Id=0,TargetPrice=25,Category="Cosmetic",Actions={"UsePremiumNameplate"},Enabled=false}},
	SpawnEffects={Id=0,TargetPrice=29,Category="Cosmetic",Actions={"UseSpawnEffect"},Enabled=false}},
	DomainCollection={Id=0,TargetPrice=59,Category="Premium",Actions={"UseDomainCosmetic"},Enabled=false}},
	AwakeningVault={Id=0,TargetPrice=60,Category="Premium",Actions={"UseAwakeningSkin"},Enabled=false}},
	RiftExplorer={Id=0,TargetPrice=45,Category="World",Actions={"EnterRiftExplorer"},Enabled=false}},
	BattleArchitect={Id=0,TargetPrice=55,Category="PrivateServer",Actions={"ConfigurePrivateServer"},Enabled=false}},
	InventoryPlus={Id=0,TargetPrice=25,Category="Convenience",Actions={"UseExtraInventory"},Enabled=false}},
	QuestExpansion={Id=0,TargetPrice=20,Category="Convenience",Actions={"UseExtraQuestSlots"},Enabled=false}},
	CreditBooster={Id=0,TargetPrice=30,Category="Convenience",Actions={"CreditBoost"},Enabled=false}},
	Founder={Id=0,TargetPrice=60,Category="Exclusive",Actions={"FounderCosmetics"},Enabled=false}}
}

local A:{[string]:string}={}
for passKey,definition in P do
	for _,action in definition.Actions do
		A[action]=passKey
	end
end

return {Passes=P,ActionRequirements=A,MinPrice=20,MaxPrice=60}
