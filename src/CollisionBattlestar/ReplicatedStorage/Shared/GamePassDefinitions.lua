--!strict
export type PassDefinition={Id:number,TargetPrice:number,Category:string,Actions:{string}}
export type DefinitionMap={[string]:PassDefinition}

local P:DefinitionMap={
	VIPBattlestar={Id=0,TargetPrice=59,Category="Premium",Actions={"VipTag","VipArea","VipChatStyle"}},
	KillEffects={Id=0,TargetPrice=49,Category="Cosmetic",Actions={"EquipKillEffect"}},
	KillSounds={Id=0,TargetPrice=39,Category="Cosmetic",Actions={"EquipKillSound"}},
	AuraCollection={Id=0,TargetPrice=49,Category="Cosmetic",Actions={"EquipAura"}},
	EmoteMaster={Id=0,TargetPrice=35,Category="Cosmetic",Actions={"UsePremiumEmote"}},
	FinisherCollection={Id=0,TargetPrice=59,Category="Cosmetic",Actions={"UseFinisher"}},
	NameplatePlus={Id=0,TargetPrice=25,Category="Cosmetic",Actions={"UsePremiumNameplate"}},
	SpawnEffects={Id=0,TargetPrice=29,Category="Cosmetic",Actions={"UseSpawnEffect"}},
	DomainCollection={Id=0,TargetPrice=59,Category="Premium",Actions={"UseDomainCosmetic"}},
	AwakeningVault={Id=0,TargetPrice=60,Category="Premium",Actions={"UseAwakeningSkin"}},
	RiftExplorer={Id=0,TargetPrice=45,Category="World",Actions={"EnterRiftExplorer"}},
	BattleArchitect={Id=0,TargetPrice=55,Category="PrivateServer",Actions={"ConfigurePrivateServer"}},
	InventoryPlus={Id=0,TargetPrice=25,Category="Convenience",Actions={"UseExtraInventory"}},
	QuestExpansion={Id=0,TargetPrice=20,Category="Convenience",Actions={"UseExtraQuestSlots"}},
	CreditBooster={Id=0,TargetPrice=30,Category="Convenience",Actions={"CreditBoost"}},
	Founder={Id=0,TargetPrice=60,Category="Exclusive",Actions={"FounderCosmetics"}}
}

local A:{[string]:string}={}
for passKey,definition in P do
	for _,action in definition.Actions do
		A[action]=passKey
	end
end

return {Passes=P,ActionRequirements=A,MinPrice=20,MaxPrice=60}
