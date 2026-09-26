--!strict
local Players=game:GetService("Players")

local S={}

local function setup(player:Player)
	player:SetAttribute("Blocking",false)
	player:SetAttribute("BlockStarted",0)
	player:SetAttribute("LastCombatAt",0)
	player:SetAttribute("CurrentMapNode","Spawn")
	player:SetAttribute("Combo",0)
	player:SetAttribute("ComboStarted",0)
	player:SetAttribute("NextLight",0)
	player:SetAttribute("NextDash",0)
	player:SetAttribute("NextSpecial",0)

	local leaderstats=Instance.new("Folder")
	leaderstats.Name="leaderstats"
	leaderstats.Parent=player

	local kos=Instance.new("IntValue")
	kos.Name="KOs"
	kos.Parent=leaderstats

	local streak=Instance.new("IntValue")
	streak.Name="Streak"
	streak.Parent=leaderstats
end

function S.Init()
	Players.PlayerAdded:Connect(setup)
	for _,player in ipairs(Players:GetPlayers()) do setup(player) end
end

function S.AddKO(player:Player)
	local stats=player:FindFirstChild("leaderstats")
	local kos=stats and stats:FindFirstChild("KOs")
	local streak=stats and stats:FindFirstChild("Streak")
	if kos and kos:IsA("IntValue") then kos.Value+=1 end
	if streak and streak:IsA("IntValue") then streak.Value+=1 end
end

function S.ResetStreak(player:Player)
	local stats=player:FindFirstChild("leaderstats")
	local streak=stats and stats:FindFirstChild("Streak")
	if streak and streak:IsA("IntValue") then streak.Value=0 end
end

return S
