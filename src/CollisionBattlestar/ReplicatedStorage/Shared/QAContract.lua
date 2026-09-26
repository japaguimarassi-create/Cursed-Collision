--!strict
local Q={}
Q.Version="2.0"
Q.ReportEvent="QAReport"
Q.ControlEvent="QAControl"
Q.DummyName="CBS_QA_BOT"
Q.RequiredHUD={"CollisionHUD","LoadingScreen","PlayerPanel","Health","Energy","Awakening","Hotbar","MobileActions","MapPanel","ShopPanel","FighterPanel","QuestPanel","ProfilePanel","QuickMenu","Notice"}
Q.RequiredActions={"Light","Dash","Block","Special","Awaken","Domain","Map","Shop","Fighters","Missions","Profile"}
Q.RequiredDistricts={"Origin","Metro","Core","Iron","Apex"}
return Q