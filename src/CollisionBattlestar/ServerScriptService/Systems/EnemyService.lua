--!strict
local CollectionService=game:GetService("CollectionService")
local PathfindingService=game:GetService("PathfindingService")
local Players=game:GetService("Players")
local AnimationService=require(script.Parent:WaitForChild("NPCAnimation"))
local Service={}
local Config
local DataService
local stateEvent
local AI
local enemies:{[Model]:any}={}
local rng=Random.new(260926)
local skins={
    Urban={Shirt=607785314,Pants=398633812,Hair=8022080793,Body=Color3.fromRGB(72,86,104),Head=Color3.fromRGB(172,182,194),Accent=Color3.fromRGB(102,126,166)},
    Street={Shirt=398633584,Pants=398634487,Hair=99947960733959,Body=Color3.fromRGB(72,74,82),Head=Color3.fromRGB(186,178,164),Accent=Color3.fromRGB(74,112,154)},
    Rider={Shirt=144076358,Pants=398633812,Hair=6346833550,Body=Color3.fromRGB(48,57,68),Head=Color3.fromRGB(176,184,192),Accent=Color3.fromRGB(72,132,202)},
    Neo={Shirt=382538059,Pants=398633812,Hair=14892977317,Body=Color3.fromRGB(40,55,65),Head=Color3.fromRGB(178,190,194),Accent=Color3.fromRGB(102,208,180)},
    Monster={Shirt=398633584,Pants=398633812,Hair=8022080793,Horns=13343410419,Body=Color3.fromRGB(50,76,59),Head=Color3.fromRGB(152,180,156),Accent=Color3.fromRGB(82,214,125)},
    Elite={Shirt=398633584,Pants=398633812,Hair=14892977317,Horns=13472644423,Body=Color3.fromRGB(76,42,52),Head=Color3.fromRGB(210,188,184),Accent=Color3.fromRGB(240,76,82)},
}
local regularSkins={"Urban","Street","Rider","Neo"}
local function now() return os.clock() end
local function validPlayer(player:Player)
    if player:GetAttribute("Zone")=="PvP" then return false end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    return root and root:IsA("BasePart") and humanoid and humanoid.Health>0
end
local function targetRoot(player:Player):BasePart?
    if not validPlayer(player) then return nil end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end
local function crowdLoad(player:Player)
    local count=0
    for _,runtime in pairs(enemies) do if runtime.Target==player then count+=1 end end
    return count
end
local function chooseTarget(model:Model,runtime)
    local root=model.PrimaryPart
    if not root then return nil end
    local currentRoot=runtime.Target and targetRoot(runtime.Target)
    if currentRoot and (currentRoot.Position-root.Position).Magnitude<AI.RetargetDistance then return runtime.Target end
    local best:Player?=nil
    local bestScore=math.huge
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local attackerId=humanoid and humanoid:GetAttribute("LastAttackerUserId")
    for _,player in ipairs(Players:GetPlayers()) do
        local pRoot=targetRoot(player)
        if pRoot then
            local distance=(pRoot.Position-root.Position).Magnitude
            local score=distance+crowdLoad(player)*AI.CrowdPenalty
            if type(attackerId)=="number" and player.UserId==attackerId then score-=AI.KillerBias end
            local pHum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if pHum and pHum.MaxHealth>0 and pHum.Health/pHum.MaxHealth<0.35 then score-=AI.LowHealthBias end
            if score<bestScore then bestScore=score; best=player end
        end
    end
    runtime.Target=best
    return best
end
local function separation(model:Model)
    local root=model.PrimaryPart
    if not root then return Vector3.zero end
    local result=Vector3.zero
    for _,other in ipairs(CollectionService:GetTagged("EnemyNPC")) do
        if other~=model and other:IsA("Model") and other.PrimaryPart then
            local delta=root.Position-other.PrimaryPart.Position
            local distance=delta.Magnitude
            if distance>0 and distance<AI.SeparationRadius then result+=delta.Unit*(AI.SeparationRadius-distance)/AI.SeparationRadius end
        end
    end
    return result
end
local function hasLineOfSight(model:Model,target:Player)
    local root=model.PrimaryPart
    local tRoot=targetRoot(target)
    if not root or not tRoot then return false end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={model}
    params.IgnoreWater=true
    local direction=tRoot.Position-root.Position
    local hit=workspace:Raycast(root.Position+Vector3.new(0,1.7,0),direction,params)
    return hit==nil or hit.Instance:IsDescendantOf(target.Character)
end
local function applyDisplay(model:Model,tier:number,elite:boolean,skin)
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local head=model:FindFirstChild("Head")
    if not humanoid or not head or not head:IsA("BasePart") then return end
    humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    local billboard=Instance.new("BillboardGui")
    billboard.Name="EnemyTitle"; billboard.Size=UDim2.fromOffset(154,elite and 42 or 30); billboard.StudsOffset=Vector3.new(0,3.25,0); billboard.AlwaysOnTop=true; billboard.MaxDistance=90; billboard.Adornee=head; billboard.Parent=model
    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1; title.Size=UDim2.new(1,0,0.68,0); title.Font=Enum.Font.GothamBold; title.TextSize=elite and 11 or 9; title.TextColor3=if elite then Config.UI.Danger else skin.Accent; title.TextStrokeTransparency=0.45; title.Text=if elite then "ELITE" elseif tier>=3 then "ABERRANT" else ("TIER %d"):format(tier); title.Parent=billboard
    local back=Instance.new("Frame"); back.Size=UDim2.new(0.78,0,0,5); back.Position=UDim2.new(0.11,0,0.76,0); back.BackgroundColor3=Color3.fromRGB(24,26,32); back.BorderSizePixel=0; back.Parent=billboard; local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=back
    local fill=Instance.new("Frame"); fill.Name="HealthFill"; fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=if elite then Config.UI.Danger else skin.Accent; fill.BorderSizePixel=0; fill.Parent=back; local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(1,0); fc.Parent=fill
    humanoid.HealthChanged:Connect(function(health) if fill.Parent and humanoid.MaxHealth>0 then fill.Size=UDim2.fromScale(math.clamp(health/humanoid.MaxHealth,0,1),1) end end)
end
local function createEnemy(position:Vector3,tier:number,elite:boolean):Model?
    local skinName=if elite then "Elite" elseif tier>=3 then (rng:NextNumber()<0.55 and "Monster" or "Neo") else regularSkins[rng:NextInteger(1,#regularSkins)]
    local skin=skins[skinName]
    local description=Instance.new("HumanoidDescription")
    description.Shirt=skin.Shirt; description.Pants=skin.Pants; description.HairAccessory=tostring(skin.Hair); description.HatAccessory=skin.Horns and tostring(skin.Horns) or ""
    description.HeadColor=skin.Head; description.TorsoColor=skin.Body; description.LeftArmColor=skin.Body; description.RightArmColor=skin.Body; description.LeftLegColor=skin.Body; description.RightLegColor=skin.Body
    description.BodyTypeScale=if elite then 0.5 else 0.42; description.ProportionScale=0.7; description.WidthScale=if elite then 1.02 else 0.86; description.DepthScale=if elite then 0.96 else 0.84; description.HeightScale=if elite then 1.06 else 1; description.HeadScale=0.96
    local ok,model=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) end)
    if not ok or not model then return nil end
    model.Name=if elite then "EliteEnemy" else ("Enemy_Tier%d"):format(tier); model.Parent=workspace; model:PivotTo(CFrame.new(position))
    local humanoid=model:FindFirstChildOfClass("Humanoid"); local root=model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then model:Destroy(); return nil end
    local baseConfig=if tier>=3 then Config.Enemies.Tier3 elseif tier==2 then Config.Enemies.Tier2 else Config.Enemies.Tier1
    local mult=if elite then Config.Enemies.Elite else nil
    local health=baseConfig.Health*(mult and mult.HealthMultiplier or 1); local speed=baseConfig.Speed*(mult and mult.SpeedMultiplier or 1); local damage=baseConfig.Damage*(mult and mult.DamageMultiplier or 1); local reward=baseConfig.Reward*(mult and mult.RewardMultiplier or 1)
    humanoid.MaxHealth=health; humanoid.Health=health; humanoid.WalkSpeed=speed; humanoid.JumpPower=44; humanoid.AutoRotate=true; model.PrimaryPart=root
    model:SetAttribute("Enemy",true); model:SetAttribute("Tier",tier); model:SetAttribute("Elite",elite); model:SetAttribute("Damage",damage); model:SetAttribute("Reward",reward); model:SetAttribute("Skin",skinName); model:SetAttribute("SkinShirtId",skin.Shirt); model:SetAttribute("SkinPantsId",skin.Pants); model:SetAttribute("SkinHairId",skin.Hair); if skin.Horns then model:SetAttribute("SkinMonsterId",skin.Horns) end
    CollectionService:AddTag(model,"EnemyNPC")
    for _,d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.CanTouch=false; d:SetNetworkOwner(nil) end end
    applyDisplay(model,tier,elite,skin)
    if elite or tier>=3 then
        local h=Instance.new("Highlight"); h.Name="ThreatMarker"; h.FillColor=skin.Accent; h.FillTransparency=if elite then 0.48 else 0.72; h.OutlineColor=Color3.fromRGB(255,235,235); h.OutlineTransparency=if elite then 0 else 0.45; h.DepthMode=Enum.HighlightDepthMode.Occluded; h.Adornee=model; h.Parent=model
    end
    skins.Urban.Hair=Config.NPCAssets.Hair.MessyBlack
    skins.Street.Hair=Config.NPCAssets.Hair.SpikyBlack
    skins.Rider.Hair=Config.NPCAssets.Hair.ShortBlack
    skins.Neo.Hair=Config.NPCAssets.Hair.AnimeBlack
    skins.Monster.Hair=Config.NPCAssets.Hair.MessyBlack
    skins.Monster.Horns=Config.NPCAssets.Monster.BlackLongHorns
    skins.Elite.Hair=Config.NPCAssets.Hair.AnimeBlack
    skins.Elite.Horns=Config.NPCAssets.Monster.RedStripedHorns
    local animationState=AnimationService.Setup(humanoid,Config)
    local runtime={Tier=tier,Elite=elite,LastAttack=0,ThinkAt=0,Target=nil,Path=nil,Waypoints=nil,NextWaypoint=2,PathBlocked=nil,LastPosition=root.Position,StuckAt=now(),StrafeSign=if rng:NextNumber()<0.5 then -1 else 1,DodgeAt=now()+rng:NextNumber(AI.EliteDodgeMin,AI.EliteDodgeMax),Attacking=false,Animation=animationState}
    enemies[model]=runtime
    humanoid.StateChanged:Connect(function(_,newState) if runtime.Animation then runtime.Animation:SetLocomotion(root.AssemblyLinearVelocity.Magnitude,newState) end end)
    humanoid.Died:Connect(function()
        enemies[model]=nil
        if runtime.PathBlocked then runtime.PathBlocked:Disconnect() end
        local attackerId=humanoid:GetAttribute("LastAttackerUserId"); local rewardAmount=tonumber(model:GetAttribute("Reward")) or 0
        if type(attackerId)=="number" then
            local attacker=Players:GetPlayerByUserId(attackerId)
            if attacker and attacker:GetAttribute("Zone")~="PvP" then
                local finalReward=rewardAmount
                if elite and attacker:GetAttribute("Pass_EliteBonus")==true then finalReward*=2 end
                if attacker:GetAttribute("Pass_VIP")==true then finalReward*=1.1 end
                finalReward=math.floor(finalReward)
                local _,granted = DataService:AddCredits(attacker,finalReward)
                stateEvent:FireClient(attacker,"Reward",granted,elite)
            end
        end
        task.delay(1.2,function() if model.Parent then model:Destroy() end end)
    end)
    return model
end
local function attackPlayer(model:Model,runtime,target:Player)
    local root=model.PrimaryPart; local tRoot=targetRoot(target); local character=target.Character; local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not tRoot or not humanoid or humanoid.Health<=0 then return end
    local baseDamage=tonumber(model:GetAttribute("Damage")) or 5; local stats=DataService:GetCombatStats(target); local mitigation=stats and stats.Defense or 1; humanoid:TakeDamage(math.max(1,baseDamage*mitigation)); runtime.LastAttack=now()
end
local function repath(model:Model,runtime,target:Player)
    local root=model.PrimaryPart; local tRoot=targetRoot(target)
    if not root or not tRoot then return false end
    if runtime.PathBlocked then runtime.PathBlocked:Disconnect(); runtime.PathBlocked=nil end
    local path=PathfindingService:CreatePath({AgentRadius=AI.AgentRadius,AgentHeight=AI.AgentHeight,AgentCanJump=true,WaypointSpacing=AI.WaypointSpacing})
    local ok=pcall(function() path:ComputeAsync(root.Position,tRoot.Position) end)
    if not ok or path.Status~=Enum.PathStatus.Success then runtime.Path=nil; runtime.Waypoints=nil; return false end
    runtime.Path=path; runtime.Waypoints=path:GetWaypoints(); runtime.NextWaypoint=2
    runtime.PathBlocked=path.Blocked:Connect(function(index) if index>=runtime.NextWaypoint then runtime.ThinkAt=0 end end)
    return true
end
local function chase(model:Model,runtime,target:Player)
    local root=model.PrimaryPart; local tRoot=targetRoot(target); local humanoid=model:FindFirstChildOfClass("Humanoid")
    if not root or not tRoot or not humanoid then return end
    local distance=(tRoot.Position-root.Position).Magnitude
    local attackRange=if runtime.Tier>=3 then 6 elseif runtime.Tier==2 then 5.5 else 5
    runtime.Animation:SetLocomotion(Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude,humanoid:GetState())
    if distance<=attackRange and not runtime.Attacking and now()-runtime.LastAttack>=(if runtime.Elite then 0.78 elseif runtime.Tier>=3 then 0.92 else 1.08) then
        runtime.Attacking=true; runtime.Animation:Play("Attack",0.05,if runtime.Elite then 1.18 else 1)
        task.delay(AI.AttackWindup,function()
            if not model.Parent or humanoid.Health<=0 then runtime.Attacking=false; return end
            if targetRoot(target) and (targetRoot(target).Position-root.Position).Magnitude<=attackRange+0.8 and hasLineOfSight(model,target) then attackPlayer(model,runtime,target) end
            runtime.Attacking=false
        end)
    end
    if runtime.Attacking then humanoid:MoveTo(root.Position); return end
    local sep=separation(model); local toTarget=Vector3.new(tRoot.Position.X-root.Position.X,0,tRoot.Position.Z-root.Position.Z); local flat=toTarget.Magnitude>0 and toTarget.Unit or Vector3.new(0,0,1); local right=Vector3.new(-flat.Z,0,flat.X)*runtime.StrafeSign
    if runtime.Elite and distance>AI.EliteDodgeMin and distance<AI.EliteDodgeMax and now()>=runtime.DodgeAt then runtime.DodgeAt=now()+rng:NextNumber(AI.EliteDodgeCooldownMin,AI.EliteDodgeCooldownMax); humanoid:MoveTo(root.Position+right*8+sep*3); return end
    if distance<=AI.DirectChaseDistance and hasLineOfSight(model,target) then
        local desired=tRoot.Position-flat*(attackRange*0.78)+right*(runtime.Tier==1 and 1.0 or 2.3)+sep*4
        humanoid:MoveTo(desired); return
    end
    if now()>=runtime.ThinkAt or not runtime.Waypoints then runtime.ThinkAt=now()+AI.RepathInterval; repath(model,runtime,target) end
    local points=runtime.Waypoints
    if points and #points>=2 then
        local wp=points[math.min(runtime.NextWaypoint,#points)]
        if wp then
            if (wp.Position-root.Position).Magnitude<3.5 and runtime.NextWaypoint<#points then runtime.NextWaypoint+=1; wp=points[runtime.NextWaypoint] end
            if wp.Action==Enum.PathWaypointAction.Jump then humanoid.Jump=true end
            humanoid:MoveTo(wp.Position+sep*3); return
        end
    end
    humanoid:MoveTo(tRoot.Position+sep*3)
end
function Service:Init(config,dataService,stateRemote)
    Config=config; DataService=dataService; stateEvent=stateRemote; AI=config.AI.Enemy
    task.spawn(function()
        while true do
            local t=now()
            for model,runtime in pairs(enemies) do
                if model.Parent and model.PrimaryPart then
                    local root=model.PrimaryPart
                    if (root.Position-runtime.LastPosition).Magnitude<0.65 then
                        if runtime.StuckAt==0 then runtime.StuckAt=t end
                        if t-runtime.StuckAt>AI.StuckTimeout then
                            local humanoid=model:FindFirstChildOfClass("Humanoid")
                            if humanoid then humanoid.Jump=true; runtime.ThinkAt=0; runtime.StuckAt=t+0.25; runtime.StrafeSign*=-1 end
                        end
                    else
                        runtime.LastPosition=root.Position; runtime.StuckAt=t
                    end
                    local target=chooseTarget(model,runtime)
                    if target then chase(model,runtime,target) else local humanoid=model:FindFirstChildOfClass("Humanoid"); if humanoid then humanoid:MoveTo(root.Position); runtime.Animation:SetLocomotion(0,humanoid:GetState()) end end
                else enemies[model]=nil end
            end
            task.wait(AI.ThinkInterval)
        end
    end)
end
function Service:Spawn(position:Vector3,tier:number,elite:boolean) return createEnemy(position,tier,elite) end
function Service:Count():number local count=0; for model in pairs(enemies) do if model.Parent then count+=1 end end return count end
function Service:Clear() for model in pairs(enemies) do if model.Parent then model:Destroy() end end table.clear(enemies) end
return Service