--!strict

local RunService = game:GetService("RunService")

local Animator = {}

type JointMap = {[string]: any}

type State = {
    joints: JointMap,
    activeUntil: number,
    actionStart: number,
    actionHit: number,
    actionEnd: number,
    actionPose: {[string]: CFrame},
    movementState: string,
    movementSpeed: number,
    seed: number
}

local states: {[Model]: State} = setmetatable({}, {__mode = "k"})

local ALIASES = {
    RootJoint = {"RootJoint", "Root"},
    Waist = {"Waist"},
    Neck = {"Neck"},
    LeftShoulder = {"Left Shoulder", "LeftShoulder"},
    RightShoulder = {"Right Shoulder", "RightShoulder"},
    LeftElbow = {"Left Elbow", "LeftElbow"},
    RightElbow = {"Right Elbow", "RightElbow"},
    LeftWrist = {"Left Wrist", "LeftWrist"},
    RightWrist = {"Right Wrist", "RightWrist"},
    LeftHip = {"Left Hip", "LeftHip"},
    RightHip = {"Right Hip", "RightHip"},
    LeftKnee = {"Left Knee", "LeftKnee"},
    RightKnee = {"Right Knee", "RightKnee"}
}

local function rad(v: number): number
    return math.rad(v)
end

local function pose(x: number?, y: number?, z: number?): CFrame
    return CFrame.Angles(rad(x or 0), rad(y or 0), rad(z or 0))
end

local function findJoints(character: Model): JointMap
    local result: JointMap = {}

    for name, aliases in pairs(ALIASES) do
        for _, alias in ipairs(aliases) do
            local object = character:FindFirstChild(alias, true)
            if object and (object:IsA("AnimationConstraint") or object:IsA("Motor6D")) then
                result[name] = object
                break
            end
        end
    end

    return result
end

local function isSupported(character: Model): boolean
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("AnimationConstraint") then
            return true
        end
    end
    return false
end

local function write(joints: JointMap, transforms: {[string]: CFrame})
    for name, value in pairs(transforms) do
        local joint = joints[name]
        if joint and joint.Parent then
            joint.Transform = value
        end
    end
end

local function basePose(character: Model, transformed: boolean): {[string]: CFrame}
    local id = tostring(character:GetAttribute("CharacterId") or "")
    local result

    if id == "Gojo" then
        result = {
            RootJoint = pose(-3, 0, 0),
            Waist = pose(-2, 0, 0),
            Neck = pose(-1, 0, 0),
            LeftShoulder = pose(-12, 0, 26),
            RightShoulder = pose(-12, 0, -26),
            LeftElbow = pose(-8, -8, 4),
            RightElbow = pose(-8, 8, -4)
        }
    elseif id == "Megumi" then
        result = {
            RootJoint = pose(4, 0, 0),
            Waist = pose(6, 0, 0),
            Neck = pose(3, 0, 0),
            LeftShoulder = pose(-20, -10, 22),
            RightShoulder = pose(-20, 10, -22),
            LeftElbow = pose(-28, 12, 0),
            RightElbow = pose(-28, -12, 0)
        }
    elseif id == "Sukuna" then
        result = {
            RootJoint = pose(-2, 0, -2),
            Waist = pose(-3, 0, -4),
            Neck = pose(0, 0, 3),
            LeftShoulder = pose(-18, 4, 28),
            RightShoulder = pose(-18, -4, -28),
            LeftElbow = pose(-14, 18, 0),
            RightElbow = pose(-14, -18, 0)
        }
    else
        result = {
            RootJoint = pose(-2, 0, 0),
            Waist = pose(-1, 0, -2),
            Neck = pose(0, 0, 1),
            LeftShoulder = pose(-14, 5, 20),
            RightShoulder = pose(-14, -5, -20),
            LeftElbow = pose(-8, 12, 0),
            RightElbow = pose(-8, -12, 0)
        }
    end

    if transformed then
        result.RootJoint = result.RootJoint * pose(-2, 0, 0)
        result.Waist = result.Waist * pose(-3, 0, 0)
    end

    return result
end

local function resolveAction(character: Model, move: string, transformed: boolean): ({[string]: CFrame}, number, number, number)
    local result = basePose(character, transformed)
    local lower = string.lower(move)
    local startTime = 0.065
    local hitTime = 0.055
    local endTime = 0.16

    local function set(values: {[string]: CFrame})
        for key, value in pairs(values) do
            result[key] = value
        end
    end

    if string.match(lower, "^m1_1$") then
        startTime, hitTime, endTime = 0.035, 0.045, 0.11
        set({
            RootJoint = pose(-6, 0, -4),
            Waist = pose(-5, -3, -3),
            RightShoulder = pose(-66, -12, -48),
            RightElbow = pose(8, -22, 0),
            LeftShoulder = pose(10, 4, 20)
        })
    elseif string.match(lower, "^m1_2$") then
        startTime, hitTime, endTime = 0.035, 0.05, 0.11
        set({
            RootJoint = pose(-5, 0, 6),
            Waist = pose(-5, 4, 5),
            LeftShoulder = pose(-68, 12, 48),
            LeftElbow = pose(8, 22, 0),
            RightShoulder = pose(12, -4, -20)
        })
    elseif string.match(lower, "^m1_3$") then
        startTime, hitTime, endTime = 0.04, 0.055, 0.12
        set({
            RootJoint = pose(-9, 0, -8),
            Waist = pose(-8, -6, -6),
            RightShoulder = pose(-76, -20, -52),
            RightElbow = pose(12, -28, 0),
            LeftShoulder = pose(20, 10, 30)
        })
    elseif string.match(lower, "^m1_4$") then
        startTime, hitTime, endTime = 0.055, 0.075, 0.16
        set({
            RootJoint = pose(-12, 0, -10),
            Waist = pose(-10, -8, -8),
            RightShoulder = pose(-82, -18, -52),
            RightElbow = pose(16, -32, 0),
            LeftShoulder = pose(28, 12, 34),
            RightHip = pose(-12, 8, 6),
            LeftHip = pose(8, -5, -6)
        })
    elseif string.find(lower, "blue") then
        startTime, hitTime, endTime = 0.09, 0.18, 0.20
        set({
            RootJoint = pose(-6, 0, -10),
            Waist = pose(-8, 0, -7),
            RightShoulder = pose(-84, 6, -25),
            RightElbow = pose(-18, -14, 0),
            LeftShoulder = pose(-48, 12, 34),
            LeftElbow = pose(-18, 14, 0)
        })
    elseif string.find(lower, "red") then
        startTime, hitTime, endTime = 0.08, 0.16, 0.20
        set({
            RootJoint = pose(-8, 0, 0),
            Waist = pose(-6, 0, 0),
            RightShoulder = pose(-44, 0, 60),
            LeftShoulder = pose(-44, 0, -60),
            RightElbow = pose(-14, 24, 0),
            LeftElbow = pose(-14, -24, 0)
        })
    elseif string.find(lower, "purple") or string.find(lower, "void") then
        startTime, hitTime, endTime = 0.13, 0.22, 0.25
        set({
            RootJoint = pose(-7, 0, 0),
            Waist = pose(-8, 0, 0),
            Neck = pose(-5, 0, 0),
            RightShoulder = pose(-64, -16, -40),
            LeftShoulder = pose(-64, 16, 40),
            RightElbow = pose(-10, -20, 0),
            LeftElbow = pose(-10, 20, 0)
        })
    elseif string.find(lower, "dismantle") or string.find(lower, "cleave") or string.find(lower, "slash") then
        startTime, hitTime, endTime = 0.055, 0.065, 0.15
        set({
            RootJoint = pose(-8, -10, -4),
            Waist = pose(-6, -8, -5),
            RightShoulder = pose(-78, 16, -52),
            RightElbow = pose(10, -24, -5),
            LeftShoulder = pose(8, -6, 22),
            LeftElbow = pose(-6, 12, 4)
        })
    elseif string.find(lower, "punch") or string.find(lower, "fist") or string.find(lower, "strike") then
        startTime, hitTime, endTime = 0.045, 0.055, 0.14
        set({
            RootJoint = pose(-9, 0, -7),
            Waist = pose(-7, -5, -5),
            Neck = pose(-4, 0, 4),
            RightShoulder = pose(-72, -18, -50),
            RightElbow = pose(12, -28, 0),
            LeftShoulder = pose(18, 8, 26),
            LeftElbow = pose(-8, 14, 4)
        })
    elseif string.find(lower, "kick") then
        startTime, hitTime, endTime = 0.055, 0.07, 0.17
        set({
            RootJoint = pose(-10, 0, -7),
            Waist = pose(-8, 0, -5),
            RightShoulder = pose(-24, 0, -30),
            LeftShoulder = pose(-18, 0, 30),
            RightHip = pose(-22, 18, -6),
            RightKnee = pose(-30, 0, 0),
            LeftHip = pose(12, 0, 8)
        })
    elseif string.find(lower, "blood") then
        startTime, hitTime, endTime = 0.08, 0.15, 0.18
        set({
            RootJoint = pose(-6, 0, -4),
            Waist = pose(-4, 0, -3),
            RightShoulder = pose(-62, 0, -16),
            RightElbow = pose(-8, -16, 0),
            LeftShoulder = pose(-45, 0, 28),
            LeftElbow = pose(-8, 18, 0)
        })
    elseif string.find(lower, "elephant") or string.find(lower, "gravity") then
        startTime, hitTime, endTime = 0.10, 0.18, 0.22
        set({
            RootJoint = pose(7, 0, 0),
            Waist = pose(6, 0, 0),
            LeftShoulder = pose(32, 0, 48),
            RightShoulder = pose(32, 0, -48),
            LeftElbow = pose(18, -8, 0),
            RightElbow = pose(18, 8, 0),
            LeftHip = pose(8, 0, -5),
            RightHip = pose(8, 0, 5)
        })
    elseif string.find(lower, "mahoraga") then
        startTime, hitTime, endTime = 0.12, 0.28, 0.26
        set({
            RootJoint = pose(-4, 0, 0),
            Waist = pose(-7, 0, 0),
            Neck = pose(-6, 0, 0),
            LeftShoulder = pose(-74, -8, 48),
            RightShoulder = pose(-74, 8, -48),
            LeftElbow = pose(-18, 22, 4),
            RightElbow = pose(-18, -22, -4)
        })
    elseif string.find(lower, "domain") or string.find(lower, "shrine") then
        startTime, hitTime, endTime = 0.16, 0.34, 0.28
        set({
            RootJoint = pose(-5, 0, 0),
            Waist = pose(-9, 0, 0),
            Neck = pose(-10, 0, 0),
            LeftShoulder = pose(-74, 0, 34),
            RightShoulder = pose(-74, 0, -34),
            LeftElbow = pose(-18, -10, 0),
            RightElbow = pose(-18, 10, 0)
        })
    elseif string.find(lower, "fuga") or string.find(lower, "fire") then
        startTime, hitTime, endTime = 0.11, 0.20, 0.23
        set({
            RootJoint = pose(-7, 0, 4),
            Waist = pose(-6, 0, 3),
            RightShoulder = pose(-86, -2, -18),
            RightElbow = pose(-20, -12, 0),
            LeftShoulder = pose(-34, 0, 22),
            LeftElbow = pose(-12, 16, 0)
        })
    elseif string.find(lower, "rush") then
        startTime, hitTime, endTime = 0.06, 0.08, 0.16
        set({
            RootJoint = pose(-13, 0, -8),
            Waist = pose(-12, 0, -5),
            RightShoulder = pose(-58, -10, -48),
            LeftShoulder = pose(18, 8, 28),
            RightHip = pose(12, 0, 10),
            LeftHip = pose(-14, 0, -10)
        })
    elseif string.find(lower, "toad") or string.find(lower, "serpent") or string.find(lower, "nue") then
        startTime, hitTime, endTime = 0.09, 0.16, 0.20
        set({
            RootJoint = pose(4, 0, 0),
            Waist = pose(4, 0, 0),
            LeftShoulder = pose(-50, -12, 34),
            RightShoulder = pose(-50, 12, -34),
            LeftElbow = pose(-20, 18, 0),
            RightElbow = pose(-20, -18, 0)
        })
    elseif string.find(lower, "deer") or string.find(lower, "garden") then
        startTime, hitTime, endTime = 0.10, 0.24, 0.24
        set({
            RootJoint = pose(-5, 0, 0),
            Waist = pose(-7, 0, 0),
            LeftShoulder = pose(-42, 0, 54),
            RightShoulder = pose(-42, 0, -54),
            LeftElbow = pose(-12, 18, 0),
            RightElbow = pose(-12, -18, 0)
        })
    end

    return result, startTime, hitTime, endTime
end

local function getState(character: Model): State?
    return states[character]
end

function Animator:Bind(character: Model): boolean
    if not character.Parent or not isSupported(character) then
        return false
    end

    local current = states[character]
    if current then
        return true
    end

    states[character] = {
        joints = findJoints(character),
        activeUntil = 0,
        actionStart = 0,
        actionHit = 0,
        actionEnd = 0,
        actionPose = {},
        movementState = "Idle",
        movementSpeed = 0,
        seed = math.random() * math.pi * 2
    }

    return true
end

function Animator:Play(character: Model, move: string, options: any?): boolean
    if not self:Bind(character) then
        return false
    end

    local state = getState(character)
    if not state then
        return false
    end

    options = type(options) == "table" and options or {}
    local transformed = options.transformed == true
        or character:GetAttribute("TransformationActive") == true
        or character:GetAttribute("AwakeningActive") == true
        or character:GetAttribute("UltimateActive") == true

    local transforms, startup, hold, recovery = resolveAction(character, tostring(move), transformed)
    local now = os.clock()

    state.actionStart = now
    state.actionHit = now + startup
    state.actionEnd = state.actionHit + hold + recovery
    state.activeUntil = state.actionEnd
    state.actionPose = transforms

    return true
end

function Animator:HitReact(character: Model, intensity: number?, reaction: string?): boolean
    if not self:Bind(character) then
        return false
    end

    local state = states[character]
    if not state then
        return false
    end

    local amount = math.clamp(tonumber(intensity) or 1, 0.4, 2.2)
    local kind = tostring(reaction or "Light")
    local back, twist, arm, duration = 7, 1, 5, 0.12

    if kind == "Heavy" then
        back, twist, arm, duration = 13, 1.4, 9, 0.16
    elseif kind == "Launcher" then
        back, twist, arm, duration = 11, 1.8, 8, 0.17
    elseif kind == "Slam" then
        back, twist, arm, duration = 19, 0.8, 12, 0.21
    elseif kind == "Special" then
        back, twist, arm, duration = 15, 1.7, 11, 0.19
    elseif kind == "Parry" then
        back, twist, arm, duration = 5, 2.6, 4, 0.10
    elseif kind == "Counter" then
        back, twist, arm, duration = 12, 2.0, 8, 0.16
    elseif kind == "Death" or kind == "Finisher" then
        back, twist, arm, duration = 22, 2.5, 15, 0.29
    elseif kind == "BlackFlash" then
        back, twist, arm, duration = 18, 2.3, 13, 0.22
    end

    local side = math.random(-12, 12) * amount
    local now = os.clock()

    state.actionStart = now
    state.actionHit = now
    state.actionEnd = now + duration
    state.activeUntil = state.actionEnd
    state.actionPose = {
        RootJoint = pose(back * amount, 0, side * twist),
        Waist = pose(back * 0.45 * amount, 0, side * 0.35 * twist),
        Neck = pose(-8 * amount, side * 0.22, 0),
        RightShoulder = pose(-arm * amount, 0, -side * 0.6),
        LeftShoulder = pose(-arm * amount, 0, side * 0.6),
        RightElbow = pose(4 * amount, 0, -side * 0.18),
        LeftElbow = pose(4 * amount, 0, side * 0.18)
    }

    return true
end

function Animator:UpdateLocomotion(character: Model, movementState: string, speed: number): boolean
    if not self:Bind(character) then
        return false
    end

    local state = states[character]
    if not state then
        return false
    end

    state.movementState = tostring(movementState)
    state.movementSpeed = tonumber(speed) or 0
    return true
end

function Animator:Step(character: Model, now: number?)
    local state = states[character]
    if not state or not character.Parent then
        return
    end

    local t = now or os.clock()
    local active = t < state.activeUntil

    if active then
        local duration = math.max(0.01, state.actionEnd - state.actionStart)
        local alpha = math.clamp((t - state.actionStart) / duration, 0, 1)
        local eased = 1 - math.pow(1 - alpha, 3)
        local poseTarget = {}

        for key, value in pairs(state.actionPose) do
            poseTarget[key] = CFrame.identity:Lerp(value, eased)
        end

        write(state.joints, poseTarget)
        return
    end

    local movementState = state.movementState
    local speed = math.clamp(state.movementSpeed, 0, 2.4)
    local phase = t * (3.1 + speed * 2.3) + state.seed
    local id = tostring(character:GetAttribute("CharacterId") or "")
    local transformed = character:GetAttribute("TransformationActive") == true

    if movementState == "Jump" then
        write(state.joints, {
            RootJoint = pose(-4, 0, 0),
            Waist = pose(-7, 0, 0),
            LeftHip = pose(-12, 0, -6),
            RightHip = pose(-12, 0, 6),
            LeftShoulder = pose(10, 0, 18),
            RightShoulder = pose(10, 0, -18)
        })
        return
    end

    if movementState == "Fall" then
        write(state.joints, {
            RootJoint = pose(10, 0, 0),
            Waist = pose(8, 0, 0),
            LeftHip = pose(14, 0, -8),
            RightHip = pose(14, 0, 8),
            LeftShoulder = pose(-5, 0, 16),
            RightShoulder = pose(-5, 0, -16)
        })
        return
    end

    if movementState == "Idle" then
        local breath = math.sin(phase * 0.55) * (transformed and 2.1 or 1.8)
        local shoulder = id == "Sukuna" and 1.15 or id == "Gojo" and 0.8 or 1
        write(state.joints, {
            RootJoint = pose(1.4 + breath * 0.2, 0, math.sin(phase * 0.45) * shoulder),
            Waist = pose(-1.1 + breath * 0.18, 0, math.sin(phase * 0.45) * 1.1),
            Neck = pose(-0.6 + breath * 0.10, 0, math.sin(phase * 0.45) * -0.6)
        })
        return
    end

    local scale = movementState == "Sprint" and 1.25
        or movementState == "Running" and 1.05
        or 0.82
    local bob = math.sin(phase) * 2.6 * scale
    local sway = math.cos(phase) * 2.1 * scale
    local lift = math.abs(math.sin(phase)) * 1.4 * scale

    write(state.joints, {
        RootJoint = pose(2.4 + lift, 0, sway * 0.45),
        Waist = pose(-1.4, 0, sway * 0.75),
        Neck = pose(-0.6, 0, -sway * 0.35),
        LeftShoulder = pose(-8, 0, 17 + bob),
        RightShoulder = pose(-8, 0, -17 - bob),
        LeftHip = pose(-bob * 0.9, 0, -3),
        RightHip = pose(bob * 0.9, 0, 3)
    })
end

function Animator:StepAll(now: number?)
    local t = now or os.clock()
    for character in pairs(states) do
        self:Step(character, t)
    end
end

function Animator:Unbind(character: Model)
    states[character] = nil
end

return Animator