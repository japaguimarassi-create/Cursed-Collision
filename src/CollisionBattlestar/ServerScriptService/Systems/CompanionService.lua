--!strict
local CollectionService=game:GetService("CollectionService")
local PathfindingService=game:GetService("PathfindingService")
local Players=game:GetService("Players")
local AnimationService=require(script.Parent:WaitForChild("NPCAnimation"))
local Service={}
local Config
local DataService
type FriendInfo={UserId:number,Username:string,DisplayName:string}
type ActiveCompanion={
    Model:Model,
    Key:string,
    Slot:number,
    Target:Model?,
    NextThink:number,
    LastAttack:number,
    Path:Path?,
    Waypoints:{PathWaypoint}?,
    NextWaypoint:number,
    PathBlocked:RBXScriptConnection?,
    Animation:any,
}
local active:{[Player]:{ActiveCompanion}}={}
local friendCache:{[Player]:FriendInfo}={}
local rng=Random.new(2609261)

local function definitionFor(key:string)
    for _,definition in ipairs(Config.Shop.Companions) do
        if definition.Key==key then return definition end
    end
    return nil
end

local function ownedDefinitions(player:Player)
    local profile=DataService:Get(player)
    if not profile then return {} end
    local result={}
    for index,definition in ipairs(Config.Shop.Companions) do
        local amount=profile.Companions[definition.Key] or 0
        if amount>0 or (definition.Key=="Scout" and player:GetAttribute("Pass_StarterCompanion")==true) then
            table.insert(result,{index=index,definition=definition})
        end
    end
    return result
end

local function loadFriend(player:Player):FriendInfo?
    if friendCache[player] then return friendCache[player] end
    local ok,pages=pcall(function() return Players:GetFriendsAsync(player.UserId) end)
    if not ok or not pages then return nil end
    local friends:{FriendInfo}={}
    while true do
        for _,friend in ipairs(pages:GetCurrentPage()) do
            if type(friend)=="table" and type(friend.Id)=="number" then
                table.insert(friends,{
                    UserId=friend.Id,
                    Username=tostring(friend.Username or "Friend"),
                    DisplayName=tostring(friend.DisplayName or friend.Username or "Friend"),
                })
            end
        end
        if pages.IsFinished or #friends>=120 then break end
        local advanced=pcall(function() pages:AdvanceToNextPageAsync() end)
        if not advanced then break end
    end
    if #friends==0 then return nil end
    local selected=friends[rng:NextInteger(1,#friends)]
    friendCache[player]=selected
    return selected
end

local function destroyState(state:ActiveCompanion)
    if state.PathBlocked then
        state.PathBlocked:Disconnect()
        state.PathBlocked=nil
    end
    if state.Model.Parent then
        state.Model:Destroy()
    end
end

local function createCompanion(player:Player,definition,slot:number)
    local character=player.Character
    local playerRoot=character and character:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not playerRoot:IsA("BasePart") then return nil end

    local friend=loadFriend(player)
    if not friend then return nil end

    local ok,model=pcall(function()
        return Players:CreateHumanoidModelFromUserIdAsync(friend.UserId)
    end)
    if not ok or not model then return nil end

    model.Name=("Companion_%s_%s"):format(definition.Key,friend.Username)
    model.Parent=workspace

    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        return nil
    end

    local lateral=if slot==1 then -5 else 5
    model:PivotTo(playerRoot.CFrame*CFrame.new(lateral,0,5))
    model.PrimaryPart=root
    humanoid.MaxHealth=definition.Health
    humanoid.Health=definition.Health
    humanoid.WalkSpeed=definition.Speed
    humanoid.JumpPower=44
    humanoid.AutoRotate=true
    humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None

    model:SetAttribute("Companion",true)
    model:SetAttribute("OwnerUserId",player.UserId)
    model:SetAttribute("CompanionKey",definition.Key)
    model:SetAttribute("Damage",definition.Damage)
    model:SetAttribute("FriendUserId",friend.UserId)
    model:SetAttribute("FriendUsername",friend.Username)
    model:SetAttribute("FriendDisplayName",friend.DisplayName)

    for _,descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanTouch=false
            descendant.CanQuery=false
            descendant:SetNetworkOwner(nil)
        end
    end

    local head=model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local billboard=Instance.new("BillboardGui")
        billboard.Name="FriendCompanionLabel"
        billboard.Size=UDim2.fromOffset(210,40)
        billboard.StudsOffset=Vector3.new(0,3.15,0)
        billboard.AlwaysOnTop=true
        billboard.MaxDistance=75
        billboard.Adornee=head
        billboard.Parent=model
        local label=Instance.new("TextLabel")
        label.BackgroundTransparency=1
        label.Size=UDim2.fromScale(1,1)
        label.Font=Enum.Font.GothamBold
        label.TextSize=10
        label.TextColor3=Color3.fromRGB(225,238,255)
        label.TextStrokeTransparency=0.5
        label.Text=("ALLY  •  %s"):format(friend.DisplayName)
        label.Parent=billboard
    end

    CollectionService:AddTag(model,"CompanionNPC")
    local animation=AnimationService.Setup(humanoid,Config)

    local state:ActiveCompanion={
        Model=model,
        Key=definition.Key,
        Slot=slot,
        Target=nil,
        NextThink=0,
        LastAttack=0,
        Path=nil,
        Waypoints=nil,
        NextWaypoint=2,
        PathBlocked=nil,
        Animation=animation,
    }

    humanoid.StateChanged:Connect(function(_,newState)
        if state.Animation then
            state.Animation:SetLocomotion(root.AssemblyLinearVelocity.Magnitude,newState)
        end
    end)

    humanoid.Died:Connect(function()
        state.Target=nil
        if state.PathBlocked then state.PathBlocked:Disconnect() end
        task.delay(1,function()
            if model.Parent then model:Destroy() end
        end)
    end)

    return state
end

local function nearestEnemy(state:ActiveCompanion,maxDistance:number):Model?
    local root=state.Model.PrimaryPart
    if not root then return nil end

    local best:Model?
    local bestScore=math.huge

    for _,enemy in ipairs(CollectionService:GetTagged("EnemyNPC")) do
        if enemy:IsA("Model") and enemy.PrimaryPart then
            local humanoid=enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health>0 then
                local distance=(enemy.PrimaryPart.Position-root.Position).Magnitude
                if distance<=maxDistance then
                    local score=distance+(humanoid.Health/math.max(1,humanoid.MaxHealth))*5
                    if state.Target==enemy then score-=18 end
                    if score<bestScore then
                        bestScore=score
                        best=enemy
                    end
                end
            end
        end
    end

    return best
end

local function hasLineOfSight(state:ActiveCompanion,target:Model)
    local root=state.Model.PrimaryPart
    local targetRoot=target.PrimaryPart
    if not root or not targetRoot then return false end

    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={state.Model}
    params.IgnoreWater=true

    local hit=workspace:Raycast(root.Position+Vector3.new(0,1.5,0),targetRoot.Position-root.Position,params)
    return hit==nil or hit.Instance:IsDescendantOf(target)
end

local function repath(state:ActiveCompanion,target:Model)
    local root=state.Model.PrimaryPart
    local targetRoot=target.PrimaryPart
    if not root or not targetRoot then return false end

    if state.PathBlocked then
        state.PathBlocked:Disconnect()
        state.PathBlocked=nil
    end

    local path=PathfindingService:CreatePath({
        AgentRadius=2,
        AgentHeight=5,
        AgentCanJump=true,
        WaypointSpacing=3.5,
    })

    local ok=pcall(function()
        path:ComputeAsync(root.Position,targetRoot.Position)
    end)

    if not ok or path.Status~=Enum.PathStatus.Success then
        state.Waypoints=nil
        state.Path=nil
        return false
    end

    state.Path=path
    state.Waypoints=path:GetWaypoints()
    state.NextWaypoint=2
    state.PathBlocked=path.Blocked:Connect(function(index)
        if index>=state.NextWaypoint then
            state.NextThink=0
        end
    end)
    return true
end

local function think(player:Player,state:ActiveCompanion)
    local model=state.Model
    if not model.Parent or not model.PrimaryPart or player:GetAttribute("Zone")=="PvP" then return end

    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local playerRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health<=0 or not playerRoot or not playerRoot:IsA("BasePart") then return end

    local definition=definitionFor(state.Key)
    if not definition then return end

    if state.Target and (not state.Target.Parent or not state.Target.PrimaryPart) then
        state.Target=nil
    end

    if not state.Target then
        state.Target=nearestEnemy(state,definition.AttackRange+30)
    end

    local modelRoot=model.PrimaryPart
    state.Animation:SetLocomotion(Vector3.new(modelRoot.AssemblyLinearVelocity.X,0,modelRoot.AssemblyLinearVelocity.Z).Magnitude,humanoid:GetState())

    local enemy=state.Target
    if enemy and enemy.PrimaryPart then
        local targetHumanoid=enemy:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid or targetHumanoid.Health<=0 then
            state.Target=nil
            enemy=nil
        end
    end

    if enemy and enemy.PrimaryPart then
        local distance=(enemy.PrimaryPart.Position-modelRoot.Position).Magnitude

        if distance<=definition.AttackRange and os.clock()-state.LastAttack>=definition.AttackCooldown then
            state.LastAttack=os.clock()
            humanoid:MoveTo(modelRoot.Position)
            state.Animation:Play("Attack",0.05,1)

            task.delay(0.12,function()
                if not model.Parent or not enemy.Parent or not enemy.PrimaryPart then return end
                local liveHumanoid=enemy:FindFirstChildOfClass("Humanoid")
                if liveHumanoid and liveHumanoid.Health>0 and (enemy.PrimaryPart.Position-modelRoot.Position).Magnitude<=definition.AttackRange+1 and hasLineOfSight(state,enemy) then
                    liveHumanoid:SetAttribute("LastAttackerUserId",player.UserId)
                    liveHumanoid:SetAttribute("LastAttackerAt",workspace:GetServerTimeNow())
                    liveHumanoid:TakeDamage(definition.Damage)
                end
            end)
            return
        end

        if distance<=definition.AttackRange+10 and hasLineOfSight(state,enemy) then
            local dir=Vector3.new(enemy.PrimaryPart.Position.X-modelRoot.Position.X,0,enemy.PrimaryPart.Position.Z-modelRoot.Position.Z)
            local flat=dir.Magnitude>0 and dir.Unit or Vector3.new(0,0,1)
            local side=Vector3.new(-flat.Z,0,flat.X)*(state.Slot==1 and 2.5 or -2.5)
            humanoid:MoveTo(enemy.PrimaryPart.Position-flat*(definition.AttackRange*0.8)+side)
            return
        end

        if os.clock()>=state.NextThink or not state.Waypoints then
            state.NextThink=os.clock()+0.8
            repath(state,enemy)
        end

        local points=state.Waypoints
        local waypoint=points and points[math.min(state.NextWaypoint,#points)]
        if waypoint then
            if (waypoint.Position-modelRoot.Position).Magnitude<3.5 and state.NextWaypoint<#points then
                state.NextWaypoint+=1
                waypoint=points[state.NextWaypoint]
            end
            if waypoint.Action==Enum.PathWaypointAction.Jump then
                humanoid.Jump=true
            end
            humanoid:MoveTo(waypoint.Position)
            return
        end
    end

    local formation=playerRoot.CFrame*CFrame.new(state.Slot==1 and -5 or 5,0,5)
    local desired=formation.Position
    if (desired-modelRoot.Position).Magnitude>7 then
        humanoid:MoveTo(desired)
    else
        humanoid:MoveTo(modelRoot.Position)
    end
end

local function refresh(player:Player)
    for _,state in ipairs(active[player] or {}) do
        destroyState(state)
    end
    active[player]={}

    if player:GetAttribute("Zone")=="PvP" then return end

    local owned=ownedDefinitions(player)
    local slots=if player:GetAttribute("Pass_SecondCompanion")==true then 2 else 1
    local startIndex=math.max(1,#owned-slots+1)
    local slot=1

    for index=#owned,startIndex,-1 do
        local state=createCompanion(player,owned[index].definition,slot)
        if state then
            table.insert(active[player],state)
            slot+=1
        end
    end
end

function Service:Init(config,dataService)
    Config=config
    DataService=dataService

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            refresh(player)
        end)

        player:GetAttributeChangedSignal("DataReady"):Connect(function()
            if player:GetAttribute("DataReady")==true then refresh(player) end
        end)

        for _,attribute in ipairs({"Pass_SecondCompanion","Pass_StarterCompanion","Zone"}) do
            player:GetAttributeChangedSignal(attribute):Connect(function() refresh(player) end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        for _,state in ipairs(active[player] or {}) do destroyState(state) end
        active[player]=nil
        friendCache[player]=nil
    end)

    for _,player in ipairs(Players:GetPlayers()) do
        task.spawn(refresh,player)
    end

    task.spawn(function()
        while true do
            for player,states in pairs(active) do
                if player.Parent then
                    for _,state in ipairs(states) do think(player,state) end
                end
            end
            task.wait(0.14)
        end
    end)
end

return Service