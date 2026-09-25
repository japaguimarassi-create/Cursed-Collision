--!strict
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local T=require(script.Parent.MapContext)

local M={}
local secretFound:{[Player]:boolean}={}
local P=T.Get().PALETTE

local function buildEventAnchor()
	local s=T.Get()
	local anchor=T.Part(s.gameplay,"RealityBreakCenter",Vector3.new(4,4,4),CFrame.new(s.eventAnchor),Enum.Material.Neon,P.Rift,false,false)
	anchor.Transparency=.08
	anchor:SetAttribute("EventAnchor",true)
	T.AddBreakPart(anchor)
	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText="Trigger Resonance"
	prompt.ObjectText="Reality Break"
	prompt.HoldDuration=1.2
	prompt.MaxActivationDistance=12
	prompt.Parent=anchor
	prompt.Triggered:Connect(function()
		require(game.ServerScriptService.Services.EventService).StartRealityBreak("ManualAnchor")
	end)
end

local function buildSecretTerminal()
	local s=T.Get()
	local secret=T.Part(s.gameplay,"HiddenTerminal",Vector3.new(5,4,2),CFrame.new(-354,3,-328),Enum.Material.Neon,P.Purple,false,false)
	secret.Transparency=.12
	local secretPrompt=Instance.new("ProximityPrompt")
	secretPrompt.ActionText="Decode"
	secretPrompt.ObjectText="Anomalous Terminal"
	secretPrompt.HoldDuration=1
	secretPrompt.MaxActivationDistance=10
	secretPrompt.Parent=secret
	secretPrompt.Triggered:Connect(function(player:Player)
		if secretFound[player] then return end
		secretFound[player]=true
		player:SetAttribute("SecretTerminalFound",true)
		Data.AddCoins(player,40)
		Data.AddExploration(player,40)
		game.ReplicatedStorage.CollisionRemotes.Feedback:FireClient(player,"SecretFound","ANOMALOUS TERMINAL • +40 CR")
	end)
end

local function buildBossArena()
	local s=T.Get()
	s.bossArena=Vector3.new(0,2,-312)
	local arena=T.Part(s.landmarks,"BossArena",Vector3.new(160,2,110),CFrame.new(s.bossArena),Enum.Material.Slate,Color3.fromRGB(44,47,57),true,true)
	arena:SetAttribute("BossArena",true)
	for _,pos in ipairs({
		Vector3.new(-55,2,-345),Vector3.new(55,2,-345),Vector3.new(-55,2,-280),Vector3.new(55,2,-280)
	})do
		T.DestructibleProp(s.gameplay,"ArenaCover",pos,Vector3.new(8,5,3),P.Metal)
	end
end

local function buildBattleStreakArena()
	local s=T.Get()
	local streak=Instance.new("Folder")
	streak.Name="BattleStreakArena"
	streak.Parent=workspace
	T.Part(streak,"Floor",Vector3.new(120,2,90),CFrame.new(-365,1,330),Enum.Material.Slate,Color3.fromRGB(46,49,60),true,true)
	local ring=T.Part(streak,"Ring",Vector3.new(72,.6,72),CFrame.new(-365,2,330),Enum.Material.Neon,P.Neon,true,false)
	ring.Shape=Enum.PartType.Cylinder
	ring.Transparency=.55
	ring.CanTouch=false
	ring.CanQuery=false
	local start=T.Part(streak,"StartPoint",Vector3.new(5,4,5),CFrame.new(-365,5,330),Enum.Material.Neon,P.Neon,false,false)
	start:SetAttribute("BattleStreakStart",true)
	for angle=0,315,45 do
		local a=math.rad(angle)
		local pos=Vector3.new(-365+math.cos(a)*42,5,330+math.sin(a)*28)
		T.Part(streak,"ArenaPillar",Vector3.new(3,10,3),CFrame.new(pos),Enum.Material.Metal,P.DarkMetal,true,true)
		local glow=T.Part(streak,"ArenaGlow",Vector3.new(.7,8,.7),CFrame.new(pos+Vector3.new(0,0,1.7)),Enum.Material.Neon,P.Neon,false,false)
		glow.CanTouch=false
		glow.CanQuery=false
	end
	T.Part(streak,"Gate",Vector3.new(42,18,3),CFrame.new(-365,9,375),Enum.Material.Metal,P.DarkMetal,true,true)
end

function M.Build()
	local s=T.Get()
	T.SetEventAnchor(Vector3.new(0,6,-286))
	buildEventAnchor()
	buildSecretTerminal()
	buildBossArena()
	buildBattleStreakArena()
	T.SetSpawns({
		Vector3.new(-68,4,60),Vector3.new(68,4,60),Vector3.new(-68,4,-60),Vector3.new(68,4,-60),
		Vector3.new(-190,4,40),Vector3.new(190,4,40),Vector3.new(-190,4,-180),Vector3.new(190,4,-180),
		Vector3.new(-335,4,120),Vector3.new(340,4,150),Vector3.new(-350,4,-10),Vector3.new(350,4,-20),
		Vector3.new(-240,4,285),Vector3.new(235,4,285),Vector3.new(90,4,-280),Vector3.new(-100,4,-330)
	})
	s.arenaFloorY=0
end

return M
