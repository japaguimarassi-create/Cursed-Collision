--!strict
local SoundService=game:GetService("SoundService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local folder=SoundService:FindFirstChild("CollisionAudio")
if not folder then
	folder=Instance.new("Folder")
	folder.Name="CollisionAudio"
	folder.Parent=SoundService
end

-- 9075325599: Creator Store item explicitly "(free to use)". https://create.roblox.com/store/asset/9075325599/Punch-Sound-Effect-Sfx-2-free-to-use
-- 1198923651: Creator Store description says "feel free to use it". https://create.roblox.com/store/asset/1198923651
-- 1885641628: Creator Store description says "feel free to use". https://create.roblox.com/store/asset/1885641628/bounce-sound-effect
-- 82845990304289: Creator Store description says "Free to use". https://create.roblox.com/store/asset/82845990304289/User-Interface-Glass-Style-Button-Click

local cues={
	Hit={Id="rbxassetid://9075325599",Volume=.3,Speed=1.0,Source="https://create.roblox.com/store/asset/9075325599/Punch-Sound-Effect-Sfx-2-free-to-use"},
	Heavy={Id="rbxassetid://1198923651",Volume=.38,Speed=.95,Source="https://create.roblox.com/store/asset/1198923651"},
	Parry={Id="rbxassetid://1198923651",Volume=.34,Speed=1.15,Source="https://create.roblox.com/store/asset/1198923651"},
	Dash={Id="rbxassetid://1885641628",Volume=.22,Speed=1.15,Source="https://create.roblox.com/store/asset/1885641628/bounce-sound-effect"},
	UI={Id="rbxassetid://82845990304289",Volume=.18,Speed=1.0,Source="https://create.roblox.com/store/asset/82845990304289/User-Interface-Glass-Style-Button-Click"},
	Overdrive={Id="rbxassetid://1198923651",Volume=.28,Speed=.82,Source="https://create.roblox.com/store/asset/1198923651"},
}

local sounds:{[string]:Sound}={}

local function soundFor(name:string):Sound?
	local existing=sounds[name]
	if existing then return existing end
	local cue=cues[name]
	if not cue then return nil end
	local sound=Instance.new("Sound")
	sound.Name="CBS_"..name
	sound.SoundId=cue.Id
	sound.Volume=cue.Volume
	sound.PlaybackSpeed=cue.Speed
	sound.RollOffMaxDistance=70
	sound.Parent=folder
	sounds[name]=sound
	return sound
end

local function play(name:string)
	local sound=soundFor(name)
	if sound then sound:Play()end
end

local feedback=ReplicatedStorage:WaitForChild("CollisionRemotes"):WaitForChild("Feedback")

feedback.OnClientEvent:Connect(function(key:string,value:any)
	if key=="Swing"and typeof(value)=="table"then
		local action=typeof(value.Action)=="string"and value.Action or"Light"
		if action=="Heavy"then
			play("Heavy")
		else
			play("Hit")
		end
	elseif key=="Hit"or key=="HitTaken"or key=="WallImpact"then
		play("Hit")
	elseif key=="Parry"or key=="ParrySuccess"or key=="GuardBreak"then
		play("Parry")
	elseif key=="Dash"then
		play("Dash")
	elseif key=="OverdriveStart"or key=="OverdriveCollapse"then
		play("Overdrive")
	elseif key=="MapTravelSuccess"or key=="MapLocked"or key=="MapUnavailable"then
		play("UI")
	end
end)

folder:SetAttribute("SystemReady",true)
folder:SetAttribute("ContentStatus","VERIFIED_FREE_CREATOR_STORE_AUDIO")
