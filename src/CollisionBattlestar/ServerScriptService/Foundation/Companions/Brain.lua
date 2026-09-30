--!strict

local CompanionDefinitions=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CompanionDefinitions"))

local Brain={}
Brain.__index=Brain

local function nearestEnemy(origin:Vector3): (Model?,number)
    local folder=workspace:FindFirstChild("Enemies")
    local best,distance=nil,math.huge
    if not folder then return nil,distance end
    for _,model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("Enemy")==true then
            local humanoid=model:FindFirstChildOfClass("Humanoid")
            local root=model:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health>0 and root and root:IsA("BasePart") then
                local d=(root.Position-origin).Magnitude
                if d<distance then best,distance=model,d end
            end
        end
    end
    return best,distance
end

local function eliteTarget(origin:Vector3): (Model?,number)
    local folder=workspace:FindFirstChild("Enemies")
    local best,distance=nil,math.huge
    if not folder then return nil,distance end
    for _,model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("Enemy")==true and model:GetAttribute("Tier")=="Elite" then
            local humanoid=model:FindFirstChildOfClass("Humanoid")
            local root=model:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health>0 and root and root:IsA("BasePart") then
                local d=(root.Position-origin).Magnitude
                if d<distance then best,distance=model,d end
            end
        end
    end
    return best,distance
end

local function hasLineOfSight(origin:Vector3,target:BasePart,character:Model):boolean
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.IgnoreWater=true
    local result=workspace:Raycast(origin,target.Position-origin,params)
    return not result or result.Instance:IsDescendantOf(target.Parent)
end

function Brain.new(model:Model,owner:Player,classId:string)
    local def=CompanionDefinitions.Classes[classId]
    return setmetatable({model=model,owner=owner,classId=classId,definition=def,nextAttack=0,nextHeal=0,state="Follow"},Brain)
end

function Brain:Update(now:number):boolean
    local model,owner,def=self.model,self.owner,self.definition
    if not model.Parent or not owner.Parent or not def then return false end
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    local character=owner.Character
    local ownerHumanoid=character and character:FindFirstChildOfClass("Humanoid")
    local ownerRoot=character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not ownerRoot or not ownerHumanoid or ownerHumanoid.Health<=0 then
        return true
    end

    local followDistance=(root.Position-ownerRoot.Position).Magnitude
    if followDistance>28 then
        model:PivotTo(ownerRoot.CFrame*CFrame.new(-4,0,3))
    elseif followDistance>8 then
        humanoid:MoveTo(ownerRoot.Position-ownerRoot.CFrame.RightVector*4)
        self.state="Follow"
    end

    if def.HealAmount>0 and now>=self.nextHeal and ownerHumanoid.Health<ownerHumanoid.MaxHealth and followDistance<=def.HealRange then
        ownerHumanoid.Health=math.min(ownerHumanoid.MaxHealth,ownerHumanoid.Health+def.HealAmount)
        self.nextHeal=now+def.HealCooldown
        self.state="Support"
    end

    local target,distance=if self.classId=="Striker" then eliteTarget(root.Position) else nearestEnemy(root.Position)
    if target and distance<=def.Range then
        local targetRoot=target:FindFirstChild("HumanoidRootPart")
        local targetHumanoid=target:FindFirstChildOfClass("Humanoid")
        if targetRoot and targetHumanoid and now>=self.nextAttack and hasLineOfSight(root.Position,targetRoot,model) then
            self.nextAttack=now+def.Cooldown
            targetHumanoid:TakeDamage(def.Damage)
            local delta=targetRoot.Position-root.Position
            if delta.Magnitude>0.05 then
                targetRoot.AssemblyLinearVelocity=delta.Unit*15+Vector3.new(0,2,0)
            end
            self.state="Attack"
        elseif targetRoot then
            local delta=root.Position-targetRoot.Position
            local offset=if delta.Magnitude>0.05 then delta.Unit*def.PreferredDistance else Vector3.zero
            humanoid:MoveTo(targetRoot.Position+offset)
            self.state="Acquire"
        end
    elseif followDistance<=8 then
        self.state="Follow"
    end

    return true
end

return Brain
