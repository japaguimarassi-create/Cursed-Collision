local TweenService = game:GetService("TweenService")

local AnimationService = {}

local activeTokens = {}

local function getJoints(character)
    local joints = {}
    for _, instance in ipairs(character:GetDescendants()) do
        if instance:IsA("Motor6D") then
            local name = instance.Name
            if name == "RootJoint" or name == "Root" or name == "Waist" or name == "Neck"
                or name == "Left Shoulder" or name == "Right Shoulder"
                or name == "LeftShoulder" or name == "RightShoulder"
                or name == "Left Elbow" or name == "Right Elbow"
                or name == "LeftElbow" or name == "RightElbow"
                or name == "Left Hip" or name == "Right Hip"
                or name == "LeftHip" or name == "RightHip" then
                joints[name] = instance
            end
        end
    end
    return joints
end

local function tweenJoint(joint, transform, duration, style, direction)
    if not joint then
        return
    end
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    TweenService:Create(joint, info, {Transform = transform}):Play()
end

local function pulseJoints(joints, poses, inTime, holdTime, outTime)
    for name, pose in pairs(poses) do
        tweenJoint(joints[name], pose, inTime)
    end
    task.wait(inTime + holdTime)
    for name in pairs(poses) do
        tweenJoint(joints[name], CFrame.identity, outTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    end
    task.wait(outTime)
end

local attackPoses = {
    ["Divergent Fist"] = {
        Right = CFrame.Angles(math.rad(-18), math.rad(8), math.rad(-35)),
        Left = CFrame.Angles(math.rad(8), math.rad(-6), math.rad(14)),
        Root = CFrame.Angles(math.rad(-4), 0, math.rad(-5))
    },
    ["Black Flash"] = {
        Right = CFrame.Angles(math.rad(-40), math.rad(-12), math.rad(-55)),
        Left = CFrame.Angles(math.rad(14), math.rad(10), math.rad(24)),
        Root = CFrame.Angles(math.rad(-10), 0, math.rad(-9)),
        Neck = CFrame.Angles(math.rad(-4), 0, math.rad(4))
    },
    ["Lapse Blue"] = {
        Right = CFrame.Angles(math.rad(-75), 0, math.rad(-26)),
        Left = CFrame.Angles(math.rad(-40), math.rad(12), math.rad(30)),
        Root = CFrame.Angles(0, 0, math.rad(-8))
    },
    ["Reversal Red"] = {
        Right = CFrame.Angles(math.rad(-30), 0, math.rad(50)),
        Left = CFrame.Angles(math.rad(-30), 0, math.rad(-50)),
        Root = CFrame.Angles(math.rad(-5), 0, 0)
    },
    ["Hollow Purple"] = {
        Right = CFrame.Angles(math.rad(-65), math.rad(-8), math.rad(-20)),
        Left = CFrame.Angles(math.rad(-65), math.rad(8), math.rad(20)),
        Root = CFrame.Angles(math.rad(-12), 0, 0),
        Neck = CFrame.Angles(math.rad(-7), 0, 0)
    },
    ["Cursed Slash"] = {
        Right = CFrame.Angles(math.rad(-70), math.rad(18), math.rad(-55)),
        Left = CFrame.Angles(math.rad(12), math.rad(-12), math.rad(22)),
        Root = CFrame.Angles(0, math.rad(-12), math.rad(-8))
    },
    ["Fire Arrow"] = {
        Right = CFrame.Angles(math.rad(-80), 0, math.rad(-12)),
        Left = CFrame.Angles(math.rad(-25), 0, math.rad(16)),
        Root = CFrame.Angles(math.rad(-4), 0, math.rad(4))
    },
    ["Rika Sword"] = {
        Right = CFrame.Angles(math.rad(-50), math.rad(12), math.rad(-40)),
        Left = CFrame.Angles(math.rad(-24), math.rad(-10), math.rad(25)),
        Root = CFrame.Angles(math.rad(-6), math.rad(6), math.rad(-7))
    },
    ["Piercing Blood"] = {
        Right = CFrame.Angles(math.rad(-58), 0, math.rad(-12)),
        Left = CFrame.Angles(math.rad(-42), 0, math.rad(26)),
        Root = CFrame.Angles(math.rad(-5), 0, math.rad(-4))
    },
    ["Lightning"] = {
        Right = CFrame.Angles(math.rad(-68), math.rad(-10), math.rad(-35)),
        Left = CFrame.Angles(math.rad(-42), math.rad(8), math.rad(30)),
        Root = CFrame.Angles(math.rad(-7), 0, math.rad(-6))
    },
    ["ProjectionStrike"] = {
        Right = CFrame.Angles(math.rad(-54), math.rad(-10), math.rad(-40)),
        Left = CFrame.Angles(math.rad(-28), math.rad(6), math.rad(22)),
        Root = CFrame.Angles(math.rad(-10), math.rad(-14), math.rad(-7))
    },
    ["Gravity"] = {
        Right = CFrame.Angles(math.rad(-38), 0, math.rad(-52)),
        Left = CFrame.Angles(math.rad(-38), 0, math.rad(52)),
        Root = CFrame.Angles(math.rad(-8), 0, 0)
    },
    ["VolcanicBurst"] = {
        Right = CFrame.Angles(math.rad(-48), 0, math.rad(-55)),
        Left = CFrame.Angles(math.rad(-48), 0, math.rad(55)),
        Root = CFrame.Angles(math.rad(-12), 0, 0)
    },
    ["DeathSwarm"] = {
        Right = CFrame.Angles(math.rad(-64), math.rad(-12), math.rad(-35)),
        Left = CFrame.Angles(math.rad(-40), math.rad(12), math.rad(35)),
        Root = CFrame.Angles(math.rad(-6), 0, 0)
    },
    ["RootGrab"] = {
        Right = CFrame.Angles(math.rad(-35), 0, math.rad(-48)),
        Left = CFrame.Angles(math.rad(-35), 0, math.rad(48)),
        Root = CFrame.Angles(math.rad(-8), 0, 0)
    },
    ["IceFormation"] = {
        Right = CFrame.Angles(math.rad(-62), 0, math.rad(-24)),
        Left = CFrame.Angles(math.rad(-62), 0, math.rad(24)),
        Root = CFrame.Angles(math.rad(-9), 0, 0)
    },
    ["GraniteShot"] = {
        Right = CFrame.Angles(math.rad(-60), 0, math.rad(-18)),
        Left = CFrame.Angles(math.rad(-30), 0, math.rad(18)),
        Root = CFrame.Angles(math.rad(-14), 0, 0)
    },
    ["SkyStrike"] = {
        Right = CFrame.Angles(math.rad(-48), math.rad(-12), math.rad(-36)),
        Left = CFrame.Angles(math.rad(-50), math.rad(12), math.rad(36)),
        Root = CFrame.Angles(math.rad(-7), 0, math.rad(-7))
    },
    ["New Shadow Slash"] = {
        Right = CFrame.Angles(math.rad(-76), math.rad(14), math.rad(-42)),
        Left = CFrame.Angles(math.rad(-22), math.rad(-8), math.rad(18)),
        Root = CFrame.Angles(math.rad(-9), math.rad(-8), math.rad(-6))
    }
}

local function resolvePose(move)
    local pose = attackPoses[move]
    if pose then
        return pose
    end
    local text = string.lower(move or "")
    if string.find(text, "strike") or string.find(text, "slash") or string.find(text, "sword") then
        return attackPoses["Cursed Slash"]
    elseif string.find(text, "blood") then
        return attackPoses["Piercing Blood"]
    elseif string.find(text, "fire") or string.find(text, "volcan") then
        return attackPoses["VolcanicBurst"]
    elseif string.find(text, "ice") or string.find(text, "frost") then
        return attackPoses["IceFormation"]
    elseif string.find(text, "shot") or string.find(text, "blast") then
        return attackPoses["GraniteShot"]
    end
    return attackPoses["Divergent Fist"]
end

local function remapPose(pose, joints)
    local mapped = {}
    local right = joints["Right Shoulder"] or joints.RightShoulder
    local left = joints["Left Shoulder"] or joints.LeftShoulder
    local root = joints.RootJoint or joints.Root or joints.Waist
    local neck = joints.Neck
    if pose.Right then mapped[right and (right.Name) or ""] = pose.Right end
    if pose.Left then mapped[left and (left.Name) or ""] = pose.Left end
    if pose.Root then mapped[root and (root.Name) or ""] = pose.Root end
    if pose.Neck and neck then mapped[neck.Name] = pose.Neck end
    return mapped
end

function AnimationService.Play(character, move, action)
    if not character or not character.Parent then
        return
    end

    local joints = getJoints(character)
    if not next(joints) then
        return
    end

    local token = (activeTokens[character] or 0) + 1
    activeTokens[character] = token

    local pose = resolvePose(move)
    local mapped = remapPose(pose, joints)

    for name, jointPose in pairs(mapped) do
        local joint = joints[name]
        tweenJoint(joint, jointPose, 0.055, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end

    task.delay(0.095, function()
        if activeTokens[character] ~= token or not character.Parent then
            return
        end
        for name in pairs(mapped) do
            tweenJoint(joints[name], CFrame.identity, 0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    if action == "Skill" then
        task.delay(0.17, function()
            if activeTokens[character] == token and character.Parent then
                for name, jointPose in pairs(mapped) do
                    tweenJoint(joints[name], jointPose * CFrame.Angles(math.rad(4), 0, math.rad(4)), 0.08)
                end
                task.delay(0.09, function()
                    if activeTokens[character] == token and character.Parent then
                        for name in pairs(mapped) do
                            tweenJoint(joints[name], CFrame.identity, 0.12)
                        end
                    end
                end)
            end
        end)
    end
end

function AnimationService.HitReact(character, intensity, tag)
    if not character or not character.Parent then
        return
    end

    local joints = getJoints(character)
    if not next(joints) then
        return
    end

    local token = (activeTokens[character] or 0) + 1
    activeTokens[character] = token

    local root = joints.RootJoint or joints.Root or joints.Waist
    local neck = joints.Neck
    local right = joints["Right Shoulder"] or joints.RightShoulder
    local left = joints["Left Shoulder"] or joints.LeftShoulder

    local amount = math.clamp(tonumber(intensity) or 1, 0.4, 1.8)
    local backwards = CFrame.Angles(math.rad(12 * amount), 0, math.rad((math.random() - 0.5) * 12 * amount))
    local shoulders = CFrame.Angles(math.rad(-8 * amount), 0, math.rad((math.random() - 0.5) * 18 * amount))

    tweenJoint(root, backwards, 0.035, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tweenJoint(neck, CFrame.Angles(math.rad(-10 * amount), 0, 0), 0.035, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tweenJoint(right, shoulders, 0.035, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tweenJoint(left, shoulders:Inverse(), 0.035, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    task.delay(tag == "BlackFlash" and 0.18 or 0.12, function()
        if activeTokens[character] ~= token or not character.Parent then
            return
        end
        tweenJoint(root, CFrame.identity, 0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tweenJoint(neck, CFrame.identity, 0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tweenJoint(right, CFrame.identity, 0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tweenJoint(left, CFrame.identity, 0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

return AnimationService
