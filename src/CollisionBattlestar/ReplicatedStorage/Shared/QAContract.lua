--!strict
local Q={}
Q.Version="2.0"
Q.ReportEvent="QAReport"
Q.ControlEvent="QAControl"
Q.DummyName="CBS_QA_BOT"
Q.RequiredHUD={"CollisionHUD","LoadingScreen","PlayerCard","Objective","TopRight","Signal","MissionChip","CombatFeed","ActionBar","PowerActions","MobileActions","QuickDock","MapPanel","ShopPanel","FighterPanel","QuestPanel","ProfilePanel","ScoreboardPanel","SettingsPanel","Notice","ClashPanel"}
Q.RequiredActions={"Light","Dash","Block","Special","Awaken","Domain","Clash1","Clash2","Clash3","Clash4","Map","Shop","Fighters","Missions","Profile"}
Q.RequiredDistricts={"Origin","Metro","Core","Iron","Apex"}
return Q