--!strict

local TweenService = game:GetService("TweenService")

local CombatStateMachine = require(script.Parent.CombatStateMachine)

local AnimationService = {}

local stateMachine = CombatStateMachine.new()
type Joint = Motor6D | AnimationConstraint

local cache: {[Model]: {[string]: Joint}} = setmetatable({}, {__mode = "k"}) :: any
local tokens: {[Model]: number} = setmetatable({}, {__mode = "k"}) :: any

local JOINT_ALIASES = {
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

local function rad(value: number): number
    return math.rad(value)
end

local function pose(rx: number?, ry: number?, rz: number?): CFrame
    return CFrame.Angles(
        rad(rx or 0),
        rad(ry or 0),
        rad(rz or 0)
    )
end

local function findJoints(character: Model): {[string]: Joint}
    local existing = cache[character]
    if existing then
        local alive = false
        for _, joint in pairs(existing) do
            if joint.Parent then
                alive = true
                break
            end
        end
        if alive then
            return existing
        end
    end

    local result: {[string]: Joint} = {}
    for name, aliases in pairs(JOINT_ALIASES) do
        for _, alias in ipairs(aliases) do
            local object = character:FindFirstChild(alias, true)
            if object and (object:IsA("AnimationConstraint") or object:IsA("Motor6D")) then
                result[name] = object :: Joint
                break
            end
        end
    end

    cache[character] = result
    return result
end

local function nextToken(character: Model, state: string): number
    local current = (tokens[character] or 0) + 1
    tokens[character] = current
    stateMachine:Begin(character, state, true)
    return current
end

local function valid(character: Model, token: number): boolean
    return character.Parent ~= nil
        and tokens[character] == token
        and stateMachine:GetState(character) ~= "Dead"
end

local function tween(joint: Joint?, target: CFrame, duration: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween?
    if not joint or not joint.Parent then
        return nil
    end

    local info = TweenInfo.new(
        math.max(0.01, duration),
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )

    local track = TweenService:Create(joint, info, {
        Transform = target
    })
    track:Play()
    return track
end

local function apply(joints: {[string]: Joint}, transforms: {[string]: CFrame}, duration: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
    for name, target in pairs(transforms) do
        tween(joints[name], target, duration, style, direction)
    end
end

local function reset(character: Model, duration: number)
    local joints = findJoints(character)
    apply(joints, {
        RootJoint = CFrame.identity,
        Waist = CFrame.identity,
        Neck = CFrame.identity,
        LeftShoulder = CFrame.identity,
        RightShoulder = CFrame.identity,
        LeftElbow = CFrame.identity,
        RightElbow = CFrame.identity,
        LeftWrist = CFrame.identity,
        RightWrist = CFrame.identity,
        LeftHip = CFrame.identity,
        RightHip = CFrame.identity,
        LeftKnee = CFrame.identity,
        RightKnee = CFrame.identity
    }, duration)
end

local function characterId(character: Model): string
    return tostring(
        character:GetAttribute("CharacterId")
            or character:GetAttribute("Character")
            or ""
    )
end

local function suppressed(character: Model): boolean
    return character:GetAttribute("IsAttacking") == true
        or character:GetAttribute("Blocking") == true
        or character:GetAttribute("Ragdolled") == true
        or character:GetAttribute("Stunned") == true
        or character:GetAttribute("CombatStunned") == true
        or character:GetAttribute("UsingAbility") == true
end

local function basicProfile(character: Model, transformed: boolean?): {[string]: CFrame}
    local id = characterId(character)
    local profile: {[string]: CFrame}

    if id == "Gojo" then
        profile = {
            RootJoint = pose(-3, 0, 0),
            Waist = pose(-2, 0, 0),
            Neck = pose(-1, 0, 0),
            LeftShoulder = pose(-12, 0, 26),
            RightShoulder = pose(-12, 0, -26),
            LeftElbow = pose(-8, -8, 4),
            RightElbow = pose(-8, 8, -4)
        }
    elseif id == "Megumi" then
        profile = {
            RootJoint = pose(4, 0, 0),
            Waist = pose(6, 0, 0),
            Neck = pose(3, 0, 0),
            LeftShoulder = pose(-20, -10, 22),
            RightShoulder = pose(-20, 10, -22),
            LeftElbow = pose(-28, 12, 0),
            RightElbow = pose(-28, -12, 0)
        }
    elseif id == "Sukuna" then
        profile = {
            RootJoint = pose(-2, 0, -2),
            Waist = pose(-3, 0, -4),
            Neck = pose(0, 0, 3),
            LeftShoulder = pose(-18, 4, 28),
            RightShoulder = pose(-18, -4, -28),
            LeftElbow = pose(-14, 18, 0),
            RightElbow = pose(-14, -18, 0)
        }
    else
        profile = {
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
        profile.RootJoint = profile.RootJoint * pose(-2, 0, 0)
        profile.Waist = profile.Waist * pose(-3, 0, 0)
    end

    return profile
end

local function resolveProfile(character: Model, move: string, transformed: boolean?): ({[string]: CFrame}, number, number, number)
    local lower = string.lower(move)
    local id = characterId(character)
    local base = basicProfile(character, transformed)
    local entry = transformed and 0.055 or 0.065
    local hold = transformed and 0.075 or 0.065
    local exit = transformed and 0.16 or 0.13

    local function set(values: {[string]: CFrame})
        for name, transform in pairs(values) do
            base[name] = transform
        end
    end

    if string.match(lower, "^m1_1$") then
        entry, hold, exit = 0.035, 0.045, 0.11
        set({
            RootJoint = pose(-6, 0, -4),
            Waist = pose(-5, -3, -3),
            RightShoulder = pose(-66, -12, -48),
            RightElbow = pose(8, -22, 0),
            LeftShoulder = pose(10, 4, 20)
        })
    elseif string.match(lower, "^m1_2$") then
        entry, hold, exit = 0.035, 0.050, 0.11
        set({
            RootJoint = pose(-5, 0, 6),
            Waist = pose(-5, 4, 5),
            LeftShoulder = pose(-68, 12, 48),
            LeftElbow = pose(8, 22, 0),
            RightShoulder = pose(12, -4, -20)
        })
    elseif string.match(lower, "^m1_3$") then
        entry, hold, exit = 0.040, 0.055, 0.12
        set({
            RootJoint = pose(-9, 0, -8),
            Waist = pose(-8, -6, -6),
            RightShoulder = pose(-76, -20, -52),
            RightElbow = pose(12, -28, 0),
            LeftShoulder = pose(20, 10, 30)
        })
    elseif string.match(lower, "^m1_4$") then
        entry, hold, exit = 0.055, 0.075, 0.16
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
        entry, hold, exit = 0.09, 0.18, 0.20
        set({
            RootJoint = pose(-6, 0, -10),
            Waist = pose(-8, 0, -7),
            RightShoulder = pose(-84, 6, -25),
            RightElbow = pose(-18, -14, 0),
            LeftShoulder = pose(-48, 12, 34),
            LeftElbow = pose(-18, 14, 0),
            RightWrist = pose(0, 0, -10)
        })
    elseif string.find(lower, "red") then
        entry, hold, exit = 0.08, 0.16, 0.20
        set({
            RootJoint = pose(-8, 0, 0),
            Waist = pose(-6, 0, 0),
            RightShoulder = pose(-44, 0, 60),
            LeftShoulder = pose(-44, 0, -60),
            RightElbow = pose(-14, 24, 0),
            LeftElbow = pose(-14, -24, 0)
        })
    elseif string.find(lower, "purple") or string.find(lower, "void") then
        entry, hold, exit = 0.13, 0.22, 0.25
        set({
            RootJoint = pose(-7, 0, 0),
            Waist = pose(-8, 0, 0),
            Neck = pose(-5, 0, 0),
            RightShoulder = pose(-64, -16, -40),
            LeftShoulder = pose(-64, 16, 40),
            RightElbow = pose(-10, -20, 0),
            LeftElbow = pose(-10, 20, 0),
            RightWrist = pose(0, 0, -18),
            LeftWrist = pose(0, 0, 18)
        })
    elseif string.find(lower, "dismantle") or string.find(lower, "cleave") or string.find(lower, "slash") then
        entry, hold, exit = 0.055, 0.065, 0.15
        set({
            RootJoint = pose(-8, -10, -4),
            Waist = pose(-6, -8, -5),
            RightShoulder = pose(-78, 16, -52),
            RightElbow = pose(10, -24, -5),
            LeftShoulder = pose(8, -6, 22),
            LeftElbow = pose(-6, 12, 4)
        })
    elseif string.find(lower, "punch") or string.find(lower, "fist") or string.find(lower, "strike") then
        entry, hold, exit = 0.045, 0.055, 0.14
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
        entry, hold, exit = 0.055, 0.07, 0.17
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
        entry, hold, exit = 0.08, 0.15, 0.18
        set({
            RootJoint = pose(-6, 0, -4),
            Waist = pose(-4, 0, -3),
            RightShoulder = pose(-62, 0, -16),
            RightElbow = pose(-8, -16, 0),
            LeftShoulder = pose(-45, 0, 28),
            LeftElbow = pose(-8, 18, 0)
        })
    elseif string.find(lower, "elephant") or string.find(lower, "gravity") then
        entry, hold, exit = 0.10, 0.18, 0.22
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
        entry, hold, exit = 0.12, 0.28, 0.26
        set({
            RootJoint = pose(-4, 0, 0),
            Waist = pose(-7, 0, 0),
            Neck = pose(-6, 0, 0),
            LeftShoulder = pose(-74, -8, 48),
            RightShoulder = pose(-74, 8, -48),
            LeftElbow = pose(-18, 22, 4),
            RightElbow = pose(-18, -22, -4)
        })
    elseif string.find(lower, "domain") or string.find(lower, "shrine") or string.find(lower, "void") then
        entry, hold, exit = 0.16, 0.34, 0.28
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
        entry, hold, exit = 0.11, 0.20, 0.23
        set({
            RootJoint = pose(-7, 0, 4),
            Waist = pose(-6, 0, 3),
            RightShoulder = pose(-86, -2, -18),
            RightElbow = pose(-20, -12, 0),
            LeftShoulder = pose(-34, 0, 22),
            LeftElbow = pose(-12, 16, 0)
        })
    elseif string.find(lower, "rush") then
        entry, hold, exit = 0.06, 0.08, 0.16
        set({
            RootJoint = pose(-13, 0, -8),
            Waist = pose(-12, 0, -5),
            RightShoulder = pose(-58, -10, -48),
            LeftShoulder = pose(18, 8, 28),
            RightHip = pose(12, 0, 10),
            LeftHip = pose(-14, 0, -10)
        })
    elseif string.find(lower, "toad") or string.find(lower, "serpent") or string.find(lower, "nue") then
        entry, hold, exit = 0.09, 0.16, 0.20
        set({
            RootJoint = pose(4, 0, 0),
            Waist = pose(4, 0, 0),
            LeftShoulder = pose(-50, -12, 34),
            RightShoulder = pose(-50, 12, -34),
            LeftElbow = pose(-20, 18, 0),
            RightElbow = pose(-20, -18, 0)
        })
    elseif string.find(lower, "deer") or string.find(lower, "garden") then
        entry, hold, exit = 0.10, 0.24, 0.24
        set({
            RootJoint = pose(-5, 0, 0),
            Waist = pose(-7, 0, 0),
            LeftShoulder = pose(-42, 0, 54),
            RightShoulder = pose(-42, 0, -54),
            LeftElbow = pose(-12, 18, 0),
            RightElbow = pose(-12, -18, 0)
        })
    elseif string.find(lower, "blue") == nil and string.find(lower, "red") == nil and id == "Megumi" then
        set({
            RootJoint = pose(5, 0, 0),
            Waist = pose(4, 0, 0),
            LeftShoulder = pose(-28, -8, 34),
            RightShoulder = pose(-28, 8, -34)
        })
    end

    return base, entry, hold, exit
end

function AnimationService:Cancel(character: Model)
    if not character then
        return
    end

    tokens[character] = (tokens[character] or 0) + 1
    stateMachine:Cancel(character)
end

function AnimationService:ResetJoints(character: Model, duration: number?)
    if not character then
        return false
    end

    self:Cancel(character)
    reset(character, duration or 0.12)
    return true
end

function AnimationService.PlayAttack(character: Model, move: string, options: any?)
    options = options or {}

    local joints = findJoints(character)
    local token = nextToken(character, tostring(options.state or "Attacking"))
    local transformed = options.transformed == true
        or character:GetAttribute("AwakeningActive") == true
        or character:GetAttribute("UltimateActive") == true
    local resolvedMove = tostring(move or "Attack")
    local combo = tonumber(options.combo)
    if combo then
        resolvedMove = "M1_" .. tostring(math.clamp(math.floor(combo), 1, 4))
    end

    local transforms, entry, hold, exit = resolveProfile(
        character,
        resolvedMove,
        transformed
    )

    local entryOverride = tonumber(options.entry)
    local holdOverride = tonumber(options.hold)
    local exitOverride = tonumber(options.exit)

    if entryOverride then
        entry = entryOverride
    end
    if holdOverride then
        hold = holdOverride
    end
    if exitOverride then
        exit = exitOverride
    end

    apply(
        joints,
        transforms,
        entry,
        options.style or Enum.EasingStyle.Quart,
        options.direction or Enum.EasingDirection.Out
    )

    task.delay(entry + hold, function()
        if not valid(character, token) then
            return
        end

        if tonumber(options.pulse) and tonumber(options.pulse) > 0 then
            local pulse = tonumber(options.pulse) or 2
            apply(joints, {
                RootJoint = transforms.RootJoint and transforms.RootJoint * pose(pulse, 0, pulse * 0.18) or CFrame.identity,
                Waist = transforms.Waist and transforms.Waist * pose(-pulse * 0.35, 0, 0) or CFrame.identity
            }, 0.045, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.wait(0.05)
        end

        if valid(character, token) then
            reset(character, exit)
            stateMachine:Finish(character, token, "Idle")
        end
    end)

    return true, token
end

function AnimationService.PlaySkill(character: Model, skill: string, options: {[string]: any}?)
    local config: {[string]: any} = options or {}
    config.transformed = config.transformed == true
        or character:GetAttribute("AwakeningActive") == true
        or character:GetAttribute("UltimateActive") == true
    config.state = config.state or "UsingAbility"
    config.pulse = config.pulse or (config.transformed and 4 or 3)
    return AnimationService.PlayAttack(character, skill, config)
end

function AnimationService.PlayDomain(character: Model, options: {[string]: any}?)
    local config: {[string]: any} = options or {}
    config.transformed = true
    config.state = "Ultimate"
    config.pulse = config.pulse or 4
    config.entry = config.entry or 0.18
    config.hold = config.hold or 0.38
    return AnimationService.PlayAttack(character, "Domain Expansion", config)
end

function AnimationService.HitReact(character: Model, intensity: number, reaction: string, direction: Vector3?)
    if not character or not character.Parent then
        return false
    end

    local joints = findJoints(character)
    local amount = math.clamp(tonumber(intensity) or 1, 0.4, 2.2)
    local spread = math.random(-13, 13) * amount

    local profile = {
        Light = {back = 7, twist = 1.0, arm = 5, recovery = 0.11},
        Air = {back = 4, twist = 1.5, arm = 6, recovery = 0.10},
        Heavy = {back = 13, twist = 1.4, arm = 9, recovery = 0.16},
        Launcher = {back = 11, twist = 1.8, arm = 8, recovery = 0.17},
        Slam = {back = 19, twist = 0.8, arm = 12, recovery = 0.21},
        Special = {back = 15, twist = 1.7, arm = 11, recovery = 0.19},
        Parry = {back = 5, twist = 2.6, arm = 4, recovery = 0.10},
        Counter = {back = 12, twist = 2.0, arm = 8, recovery = 0.16},
        Death = {back = 22, twist = 2.5, arm = 15, recovery = 0.29},
        BlackFlash = {back = 18, twist = 2.3, arm = 13, recovery = 0.22}
    }

    local selected = profile[reaction] or profile.Light
    local sign = 1

    if typeof(direction) == "Vector3" and direction.Magnitude > 0.01 then
        local characterRoot = character:FindFirstChild("HumanoidRootPart")
        if characterRoot and characterRoot:IsA("BasePart") then
            local localVector = characterRoot.CFrame:VectorToObjectSpace(direction.Unit)
            sign = localVector.X >= 0 and -1 or 1
        end
    end

    apply(joints, {
        RootJoint = pose(selected.back * amount, 0, spread * selected.twist * sign),
        Waist = pose(selected.back * 0.45 * amount, 0, spread * 0.35 * selected.twist * sign),
        Neck = pose(-8 * amount, spread * 0.22 * sign, 0),
        RightShoulder = pose(-selected.arm * amount, 0, -spread * 0.6 * sign),
        LeftShoulder = pose(-selected.arm * amount, 0, spread * 0.6 * sign),
        RightElbow = pose(4 * amount, 0, -spread * 0.18),
        LeftElbow = pose(4 * amount, 0, spread * 0.18)
    }, 0.035, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    task.delay(selected.recovery, function()
        if character.Parent then
            reset(character, 0.12)
        end
    end)

    return true
end

function AnimationService.UpdateLocomotion(character: Model, movementState: string, speed: number, timeNow: number?)
    if not character or not character.Parent or suppressed(character) then
        return false
    end

    local joints = findJoints(character)
    local t = timeNow or os.clock()
    local normalizedSpeed = math.clamp(speed / 18, 0, 2.4)
    local phase = t * (3.2 + normalizedSpeed * 2.2)
    local state = tostring(movementState)

    if state == "Jump" then
        apply(joints, {
            RootJoint = pose(-4, 0, 0),
            Waist = pose(-7, 0, 0),
            LeftHip = pose(-12, 0, -6),
            RightHip = pose(-12, 0, 6),
            LeftShoulder = pose(10, 0, 18),
            RightShoulder = pose(10, 0, -18)
        }, 0.08)
        return true
    end

    if state == "Fall" then
        apply(joints, {
            RootJoint = pose(10, 0, 0),
            Waist = pose(8, 0, 0),
            LeftHip = pose(14, 0, -8),
            RightHip = pose(14, 0, 8),
            LeftShoulder = pose(-5, 0, 16),
            RightShoulder = pose(-5, 0, -16)
        }, 0.10)
        return true
    end

    if state == "Idle" then
        local breathe = math.sin(phase * 0.55) * 1.8
        apply(joints, {
            RootJoint = pose(1.4 + breathe * 0.2, 0, math.sin(phase * 0.45) * 0.8),
            Waist = pose(-1.1 + breathe * 0.18, 0, math.sin(phase * 0.45) * 1.1),
            Neck = pose(-0.6 + breathe * 0.10, 0, math.sin(phase * 0.45) * -0.6)
        }, 0.09)
        return true
    end

    local locomotionScale = state == "Sprint" and 1.25
        or state == "Running" and 1.05
        or 0.82
    local bob = math.sin(phase) * 2.6 * locomotionScale
    local sway = math.cos(phase) * 2.1 * locomotionScale
    local lift = math.abs(math.sin(phase)) * 1.4 * locomotionScale

    apply(joints, {
        RootJoint = pose(2.4 + lift, 0, sway * 0.45),
        Waist = pose(-1.4, 0, sway * 0.75),
        Neck = pose(-0.6, 0, -sway * 0.35),
        LeftShoulder = pose(-8, 0, 17 + bob),
        RightShoulder = pose(-8, 0, -17 - bob),
        LeftHip = pose(-bob * 0.9, 0, -3),
        RightHip = pose(bob * 0.9, 0, 3)
    }, 0.055)

    return true
end

function AnimationService.StartIdleCombat(character: Model, intensity: number?)
    if not character or not character.Parent then
        return false
    end

    local strength = math.clamp(tonumber(intensity) or 1, 0.5, 1.5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    task.spawn(function()
        while character.Parent and humanoid.Health > 0 do
            if not suppressed(character) then
                AnimationService.UpdateLocomotion(character, "Idle", 0, os.clock() * strength)
            end
            task.wait(0.09)
        end
    end)

    return true
end

function AnimationService.StopIdleCombat(_character: Model)
    return
end

return AnimationService
