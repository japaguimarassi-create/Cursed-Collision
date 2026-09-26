--!strict
local Q={}
Q.Version="1.0"
Q.ReportEvent="QAReport"
Q.ControlEvent="QAControl"
Q.DummyName="CBS_QA_BOT"
Q.RequiredHUD={"CollisionHUD","PlayerPanel","Health","Energy","Awakening","Hotbar","MobileActions","MapPanel","ShopPanel","QuestPanel","ProfilePanel"}
Q.RequiredActions={"Light","Dash","Block","Special","Map","Shop","Missions","Profile"}
return Q
