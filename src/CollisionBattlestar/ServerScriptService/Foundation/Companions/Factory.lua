--!strict

local Factory = {}

local function makeFallback(classId: string): Model
    local colors = {
        Vanguard = {Color3.fromRGB(68,78,94), Color3.fromRGB(88,190,255)},
        Striker = {Color3.fromRGB(70,52,96), Color3.fromRGB(190,100,255)},
        Guardian = {Color3.fromRGB(58,86,78), Color3.fromRGB(88,220,172)},
        Support = {Color3.fromRGB(92,82,58), Color3.fromRGB(255,202,96)},
    }
    local palette = colors[classId] or colors.Vanguard
    local model = Instance.new("Model")
    model.Name = "FriendEcho"
    model:SetAttribute("FriendEcho", true)
    model:SetAttribute("ClassId", classId)
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2.2,3.2,2.2)
    root.Transparency = 1
    root.CanCollide = false
    root.CanTouch = false
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 250
    humanoid.Health = 250
    humanoid.WalkSpeed = 13
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    local parts = {
        {"Torso",Vector3.new(2.8,3,1.8),Vector3.new(0,1.7,0)},
        {"Head",Vector3.new(2,2,2),Vector3.new(0,4.2,0)},
        {"LeftArm",Vector3.new(.8,2.8,.8),Vector3.new(-1.8,1.7,0)},
        {"RightArm",Vector3.new(.8,2.8,.8),Vector3.new(1.8,1.7,0)},
        {"LeftLeg",Vector3.new(.9,3,.9),Vector3.new(-.65,-1.6,0)},
        {"RightLeg",Vector3.new(.9,3,.9),Vector3.new(.65,-1.6,0)},
    }
    for _, item in ipairs(parts) do
        local part = Instance.new("Part")
        part.Name=item[1]
        part.Size=item[2]
        part.CFrame=root.CFrame*CFrame.new(item[3])
        part.Color=palette[1]
        part.Material=Enum.Material.SmoothPlastic
        part.CanCollide=false
        part.CanTouch=false
        part.CanQuery=true
        part.Massless=true
        part.Parent=model
        local weld=Instance.new("WeldConstraint")
        weld.Part0=root
        weld.Part1=part
        weld.Parent=root
    end
    local core=Instance.new("Part")
    core.Name="EchoCore"
    core.Shape=Enum.PartType.Ball
    core.Size=Vector3.new(.8,.8,.8)
    core.CFrame=root.CFrame*CFrame.new(0,2.3,-1)
    core.Color=palette[2]
    core.Material=Enum.Material.Neon
    core.CanCollide=false
    core.CanTouch=false
    core.CanQuery=false
    core.Massless=true
    core.Parent=model
    local weld=Instance.new("WeldConstraint")
    weld.Part0=root
    weld.Part1=core
    weld.Parent=root
    return model
end

function Factory.Create(friendUserId:number,classId:string,avatarModel:Model?,spawnCFrame:CFrame):Model
    local model=if avatarModel then avatarModel else makeFallback(classId)
    model.Name="Echo_"..tostring(friendUserId)
    model:SetAttribute("FriendEcho",true)
    model:SetAttribute("FriendUserId",friendUserId)
    model:SetAttribute("ClassId",classId)
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        model=makeFallback(classId)
        model:SetAttribute("FriendEcho",true)
        model:SetAttribute("FriendUserId",friendUserId)
        model:SetAttribute("ClassId",classId)
        root=model:FindFirstChild("HumanoidRootPart")
    end
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide=false
            d.CanTouch=false
            d.CanQuery=d.Name~="HumanoidRootPart"
            d.Massless=true
        elseif d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end
    if humanoid then
        humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
        humanoid.AutoRotate=true
    end
    local head=model:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local tag=Instance.new("BillboardGui")
        tag.Name="EchoLabel"
        tag.Size=UDim2.fromOffset(150,28)
        tag.StudsOffsetWorldSpace=Vector3.new(0,2,0)
        tag.AlwaysOnTop=true
        tag.Adornee=head
        tag.Parent=head
        local label=Instance.new("TextLabel")
        label.Size=UDim2.fromScale(1,1)
        label.BackgroundTransparency=1
        label.Text="FRIEND ECHO • "..classId
        label.TextColor3=Color3.fromRGB(95,210,255)
        label.TextStrokeTransparency=.25
        label.Font=Enum.Font.GothamBold
        label.TextScaled=true
        label.Parent=tag
    end
    local folder=workspace:FindFirstChild("Companions")
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="Companions"
        folder.Parent=workspace
    end
    model.Parent=folder
    if root and root:IsA("BasePart") then model:PivotTo(spawnCFrame) end
    return model
end

return Factory
