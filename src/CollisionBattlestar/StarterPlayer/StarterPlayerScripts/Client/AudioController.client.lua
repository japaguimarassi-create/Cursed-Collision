--!strict
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")

local ROOT=SoundService:FindFirstChild("CollisionAudio")or Instance.new("Folder")
ROOT.Name="CollisionAudio"
ROOT.Parent=SoundService
ROOT:SetAttribute("SystemReady",true)
ROOT:SetAttribute("ContentStatus","PUBLIC_FREE_CREATOR_STORE_IMPACT_ASSET")

local IMPACT_ID="rbxassetid://9075325599"
-- Verified source: Creator Store "Punch Sound Effect Sfx 2 (free to use)", asset 9075325599.
-- The listing explicitly says "free to use" and reports a 2-second sound effect.
local function playAt(position:Vector3,volume:number,speed:number)
	local holder=Instance.new("Part")
	holder.Name="CollisionAudioSource"
	holder.Anchored=true
	holder.CanCollide=false
	holder.CanTouch=false
	holder.CanQuery=false
	holder.Transparency=1
	holder.Size=Vector3.one
	holder.CFrame=CFrame.new(position)
	holder.Parent=workspace
	local sound=Instance.new("Sound")
	sound.Name="Impact"
	sound.SoundId=IMPACT_ID
	sound.Volume=math.clamp(volume,.08,1)
	sound.PlaybackSpeed=math.clamp(speed,.72,1.35)
	sound.RollOffMode=Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance=8
	sound.RollOffMaxDistance=70
	sound.Parent=holder
	sound:Play()
	Debris:AddItem(holder,2.2)
end

local function rootPosition():Vector3?
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart")and root.Position or nil
end

local feedback=game:GetService("ReplicatedStorage"):WaitForChild("CollisionRemotes"):WaitForChild("Feedback")
feedback.OnClientEvent:Connect(function(key:string,value:any)
	if key=="Hit"or key=="HitTaken"or key=="Parried"or key=="ParrySuccess"then
		if typeof(value)=="table"and typeof(value.Position)=="Vector3"then
			local action=typeof(value.Action)=="string"and value.Action or"Light"
			local volume=key=="HitTaken"and .24 or .34
			local speed=action=="Special"and .84 or action=="Heavy"and .92 or 1.03
			playAt(value.Position,volume,speed)
		else
			local pos=rootPosition()
			if pos then playAt(pos,.26,1.05)end
		end
	elseif key=="GuardBreak"or key=="BreakFX"or key=="WallImpact"then
		local pos=typeof(value)=="table"and typeof(value.Position)=="Vector3"and value.Position or rootPosition()
		if pos then playAt(pos,.48,.86)end
	elseif key=="Dash"then
		local pos=rootPosition()
		if pos then playAt(pos,.16,1.22)end
	elseif key=="OverdriveStart"then
		local pos=rootPosition()
		if pos then playAt(pos,.25,.78)end
	end
end)