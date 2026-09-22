local TweenService = game:GetService("TweenService")
local CombatStateMachine = require(script.Parent.CombatStateMachine)

local AnimationService = {}

local cache = setmetatable({}, {__mode = "k"})
local stateMachine = CombatStateMachine.new()
local idleTokens = setmetatable({}, {__mode = "k"})
local tokens = setmetatable({}, {__mode = "k"})

local JOINT_ALIASES = {
    RootJoint = {"RootJoint", "Root"},
    Waist = {"Waist"},
    Neck = {"Neck"},
    LeftShoulder = {"Left Shoulder", "LeftShoulder"},
    RightShoulder = {"Right Shoulder", "RightShoulder"},
    LeftElbow = {"Left Elbow", "LeftElbow"},
    RightElbow = {"Right Elbow", "RightElbow"},
    LeftHip = {"Left Hip", "LeftHip"},
    RightHip = {"Right Hip", "RightHip"}
}

local function rad(x)
    return math.rad(x)
end

local function pose(rx, ry, rz)
    return CFrame.Angles(rad(rx or 0), rad(ry or 0), rad(rz or 0))
end

local function getJoints(character)
    local cached = cache[character]
    if cached then
        local valid = false
        for _, joint in pairs(cached) do
            if joint and joint.Parent then
                valid = true
                break
            end
        end
        if valid then
            return cached
        end
    end

    local result = {}
    for key, aliases in pairs(JOINT_ALIASES) do
        for _, alias in ipairs(aliases) do
            local joint = character:FindFirstChild(alias, true)
            if joint and joint:IsA("Motor6D") then
                result[key] = joint
                break
            end
        end
    end

    cache[character] = result
    return result
end

local function nextToken(character, state)
    return stateMachine:Begin(character, state or "Attack", true)
end

local function valid(character, token)
    return type(token) == "number" and stateMachine:IsCurrent(character, token)
end

local function tween(joint, target, duration, style, direction)
    if not joint or not joint.Parent then
        return nil
    end
    local info = TweenInfo.new(
        math.max(0, duration or 0.08),
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(joint, info, {Transform = target})
    t:Play()
    return t
end

local function apply(joints, transforms, duration, style, direction)
    for key, transform in pairs(transforms) do
        tween(joints[key], transform, duration, style, direction)
    end
end

local function reset(character, joints, duration)
    for _, joint in pairs(joints) do
        tween(joint, CFrame.identity, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
end

local function merge(base, extra)
    local result = {}
    for key, value in pairs(base) do
        result[key] = value
    end
    if extra then
        for key, value in pairs(extra) do
            result[key] = value
        end
    end
    return result
end

local Poses = {
    ["Divergent Fist"] = {
        entry = 0.07, hold = 0.06, exit = 0.16,
        pose = {
            RootJoint = pose(-6, 0, -4),
            Waist = pose(2, 0, -3),
            Neck = pose(-2, 0, 3),
            RightShoulder = pose(-42, 8, -42),
            RightElbow = pose(0, -18, -8),
            LeftShoulder = pose(10, -7, 20),
            LeftElbow = pose(-8, 12, 4),
            RightHip = pose(3, 0, 4),
            LeftHip = pose(-3, 0, -2)
        }
    },
    ["Black Flash"] = {
        entry = 0.055, hold = 0.075, exit = 0.18,
        pose = {
            RootJoint = pose(-13, 0, -8),
            Waist = pose(-8, -3, -5),
            Neck = pose(-7, 0, 6),
            RightShoulder = pose(-68, -18, -54),
            RightElbow = pose(18, -28, -6),
            LeftShoulder = pose(17, 10, 28),
            LeftElbow = pose(-10, 15, 8),
            RightHip = pose(5, -2, 7),
            LeftHip = pose(-4, 1, -5)
        }
    },
    ["Lapse Blue"] = {
        entry = 0.1, hold = 0.16, exit = 0.22,
        pose = {
            RootJoint = pose(-5, 0, -10),
            Waist = pose(-10, 0, -5),
            Neck = pose(-8, 0, 8),
            RightShoulder = pose(-82, 4, -30),
            RightElbow = pose(-8, -18, -6),
            LeftShoulder = pose(-52, 12, 34),
            LeftElbow = pose(-12, 20, 5),
            RightHip = pose(5, 0, 7),
            LeftHip = pose(-5, 0, -7)
        }
    },
    ["Reversal Red"] = {
        entry = 0.09, hold = 0.14, exit = 0.2,
        pose = {
            RootJoint = pose(-7, 0, 0),
            Waist = pose(-5, 0, 0),
            Neck = pose(-4, 0, 0),
            RightShoulder = pose(-35, 0, 58),
            RightElbow = pose(-15, 22, 0),
            LeftShoulder = pose(-35, 0, -58),
            LeftElbow = pose(-15, -22, 0),
            RightHip = pose(3, 0, 4),
            LeftHip = pose(-3, 0, -4)
        }
    },
    ["Domain Expansion"] = {
        entry = 0.18, hold = 0.35, exit = 0.28,
        pose = {
            RootJoint = pose(-4, 0, 0),
            Waist = pose(-8, 0, 0),
            Neck = pose(-10, 0, 0),
            RightShoulder = pose(-72, 0, -34),
            RightElbow = pose(-20, 12, 5),
            LeftShoulder = pose(-72, 0, 34),
            LeftElbow = pose(-20, -12, -5),
            RightHip = pose(4, 0, 5),
            LeftHip = pose(-4, 0, -5)
        }
    },
    ["Counter"] = {
        entry = 0.05, hold = 0.2, exit = 0.16,
        pose = {
            RootJoint = pose(-6, 0, 0),
            Waist = pose(-5, 0, 0),
            Neck = pose(-4, 0, 0),
            RightShoulder = pose(-36, 12, -44),
            RightElbow = pose(-20, -20, -6),
            LeftShoulder = pose(-36, -12, 44),
            LeftElbow = pose(-20, 20, 6)
        }
    },
    ["Slam"] = {
        entry = 0.06, hold = 0.12, exit = 0.2,
        pose = {
            RootJoint = pose(12, 0, 0),
            Waist = pose(9, 0, 0),
            Neck = pose(6, 0, 0),
            RightShoulder = pose(-52, 6, -38),
            RightElbow = pose(18, -16, 0),
            LeftShoulder = pose(-52, -6, 38),
            LeftElbow = pose(18, 16, 0),
            RightHip = pose(12, 0, 6),
            LeftHip = pose(12, 0, -6)
        }
    },
    ["AirM1"] = {
        entry = 0.045, hold = 0.04, exit = 0.12,
        pose = {
            RootJoint = pose(7, -6, -4),
            Waist = pose(5, -5, -3),
            Neck = pose(3, 0, 4),
            RightShoulder = pose(-58, 8, -44),
            RightElbow = pose(12, -18, -6),
            LeftShoulder = pose(-12, -6, 24),
            LeftElbow = pose(-8, 12, 4),
            RightHip = pose(14, -3, 8),
            LeftHip = pose(10, 2, -6)
        }
    },
    ["M1_1"] = {
        entry = 0.045, hold = 0.035, exit = 0.11,
        pose = {
            RootJoint = pose(-4, 0, -3),
            Waist = pose(-3, -4, -2),
            RightShoulder = pose(-45, -8, -48),
            RightElbow = pose(8, -18, -6),
            LeftShoulder = pose(8, 6, 18),
            LeftElbow = pose(-6, 10, 3)
        }
    },
    ["M1_2"] = {
        entry = 0.045, hold = 0.035, exit = 0.11,
        pose = {
            RootJoint = pose(-3, 8, 5),
            Waist = pose(-3, 7, 4),
            RightShoulder = pose(10, -8, 18),
            RightElbow = pose(-10, 18, 5),
            LeftShoulder = pose(-52, 10, -52),
            LeftElbow = pose(8, -18, -4)
        }
    },
    ["M1_3"] = {
        entry = 0.05, hold = 0.04, exit = 0.12,
        pose = {
            RootJoint = pose(-6, -8, -5),
            Waist = pose(-4, -7, -4),
            RightShoulder = pose(-58, -12, -38),
            RightElbow = pose(10, -20, -5),
            LeftShoulder = pose(12, 5, 22),
            LeftElbow = pose(-5, 10, 4)
        }
    },
    ["M1_4"] = {
        entry = 0.055, hold = 0.05, exit = 0.14,
        pose = {
            RootJoint = pose(-11, 0, 7),
            Waist = pose(-7, 0, 6),
            Neck = pose(-6, 0, -5),
            RightShoulder = pose(-70, 6, -42),
            RightElbow = pose(16, -22, -5),
            LeftShoulder = pose(20, -4, 25),
            LeftElbow = pose(-10, 14, 5)
        }
    },
    ["Heavy"] = {
        entry = 0.08, hold = 0.08, exit = 0.18,
        pose = {
            RootJoint = pose(-14, 0, -7),
            Waist = pose(-10, 0, -5),
            Neck = pose(-5, 0, 4),
            RightShoulder = pose(-78, -10, -52),
            RightElbow = pose(22, -28, -5),
            LeftShoulder = pose(22, 8, 28),
            LeftElbow = pose(-12, 18, 5)
        }
    },
    ["Grab"] = {
        entry = 0.07, hold = 0.12, exit = 0.17,
        pose = {
            RootJoint = pose(-8, 0, 0),
            Waist = pose(-6, 0, 0),
            RightShoulder = pose(-44, 0, -48),
            RightElbow = pose(-18, 22, 0),
            LeftShoulder = pose(-44, 0, 48),
            LeftElbow = pose(-18, -22, 0)
        }
    },
    ["Dash"] = {
        entry = 0.055, hold = 0.09, exit = 0.14,
        pose = {
            RootJoint = pose(8, 0, -4),
            Waist = pose(8, 0, -3),
            Neck = pose(4, 0, 3),
            RightShoulder = pose(-35, 0, -28),
            LeftShoulder = pose(18, 0, 26),
            RightHip = pose(16, 0, 12),
            LeftHip = pose(-12, 0, -10)
        }
    },
    ["Divergent"] = {
        entry = 0.07, hold = 0.06, exit = 0.16,
        pose = {
            RootJoint = pose(-6, 0, -4),
            Waist = pose(2, 0, -3),
            RightShoulder = pose(-42, 8, -42),
            LeftShoulder = pose(10, -7, 20)
        }
    },
    ["Cursed Slash"] = {
        entry = 0.06, hold = 0.05, exit = 0.15,
        pose = {
            RootJoint = pose(-5, -12, -7),
            Waist = pose(-4, -10, -6),
            Neck = pose(-3, -8, 4),
            RightShoulder = pose(-74, 18, -56),
            RightElbow = pose(8, -24, -8),
            LeftShoulder = pose(12, -10, 22),
            LeftElbow = pose(-8, 14, 4)
        }
    },
    ["Fire Arrow"] = {
        entry = 0.1, hold = 0.18, exit = 0.2,
        pose = {
            RootJoint = pose(-5, 0, 4),
            Waist = pose(-4, 0, 3),
            RightShoulder = pose(-84, 0, -15),
            RightElbow = pose(-18, -10, 0),
            LeftShoulder = pose(-28, 0, 18),
            LeftElbow = pose(-10, 16, 0)
        }
    },
    ["Piercing Blood"] = {
        entry = 0.09, hold = 0.14, exit = 0.19,
        pose = {
            RootJoint = pose(-6, 0, -4),
            Waist = pose(-4, 0, -3),
            RightShoulder = pose(-62, 0, -16),
            RightElbow = pose(-8, -16, 0),
            LeftShoulder = pose(-45, 0, 28),
            LeftElbow = pose(-8, 18, 0)
        }
    },
    ["Gravity"] = {
        entry = 0.1, hold = 0.18, exit = 0.2,
        pose = {
            RootJoint = pose(-10, 0, 0),
            Waist = pose(-7, 0, 0),
            Neck = pose(-5, 0, 0),
            RightShoulder = pose(-42, 0, -54),
            LeftShoulder = pose(-42, 0, 54),
            RightElbow = pose(-12, 16, 0),
            LeftElbow = pose(-12, -16, 0)
        }
    },
    ["Ice Formation"] = {
        entry = 0.1, hold = 0.18, exit = 0.2,
        pose = {
            RootJoint = pose(-8, 0, 0),
            Waist = pose(-6, 0, 0),
            RightShoulder = pose(-66, 0, -28),
            LeftShoulder = pose(-66, 0, 28),
            RightElbow = pose(-16, 18, 0),
            LeftElbow = pose(-16, -18, 0)
        }
    }
}

local ALIASES = {
    ["BlackFlash"] = "Black Flash",
    ["Domain"] = "Domain Expansion",
    ["DomainExpansion"] = "Domain Expansion",
    ["Blue"] = "Lapse Blue",
    ["Red"] = "Reversal Red",
    ["DivergentFist"] = "Divergent Fist",
    ["CursedSlash"] = "Cursed Slash",
    ["IceFormation"] = "Ice Formation",
    ["PiercingBlood"] = "Piercing Blood",
    ["FireArrow"] = "Fire Arrow"
}

local function resolve(name)
    name = tostring(name or "")
    if Poses[name] then
        return Poses[name]
    end
    local alias = ALIASES[name]
    if alias and Poses[alias] then
        return Poses[alias]
    end
    local lower = string.lower(name)
    if string.find(lower, "black") and string.find(lower, "flash") then
        return Poses["Black Flash"]
    elseif string.find(lower, "divergent") then
        return Poses["Divergent Fist"]
    elseif string.find(lower, "domain") then
        return Poses["Domain Expansion"]
    elseif string.find(lower, "blue") then
        return Poses["Lapse Blue"]
    elseif string.find(lower, "red") then
        return Poses["Reversal Red"]
    elseif string.find(lower, "slash") then
        return Poses["Cursed Slash"]
    elseif string.find(lower, "blood") then
        return Poses["Piercing Blood"]
    elseif string.find(lower, "fire") then
        return Poses["Fire Arrow"]
    elseif string.find(lower, "ice") then
        return Poses["Ice Formation"]
    elseif string.find(lower, "grab") then
        return Poses["Grab"]
    elseif string.find(lower, "heavy") then
        return Poses["Heavy"]
    elseif string.find(lower, "dash") or string.find(lower, "ambush") or string.find(lower, "rush") then
        return Poses["Dash"]
    elseif string.find(lower, "kick") then
        return Poses["Heavy"]
    elseif string.find(lower, "palm") or string.find(lower, "punch") or string.find(lower, "strike") then
        return Poses["Divergent Fist"]
    elseif string.find(lower, "sphere") or string.find(lower, "blast") or string.find(lower, "meteor") or string.find(lower, "uzumaki") then
        return Poses["Hollow Purple"]
    elseif string.find(lower, "gravity") or string.find(lower, "domain") or string.find(lower, "garden") then
        return Poses["Domain Expansion"]
    end
    return Poses["M1_1"]
end

local function playPose(character, name, options)
    if not character or not character.Parent then
        return false
    end

    local joints = getJoints(character)
    if not joints.RootJoint and not joints.Waist and not joints.Neck then
        return false
    end

    options = options or {}

    local resolvedName = tostring(name or "")
    if resolvedName == "M1" and type(options.combo) == "number" then
        resolvedName = "M1_" .. tostring(math.clamp(math.floor(options.combo), 1, 4))
    elseif resolvedName == "AirM1" then
        resolvedName = "AirM1"
    end

    local definition = resolve(resolvedName)
    local token = nextToken(character, options.state or "Attack")
    local entry = options.entry or definition.entry
    local hold = options.hold or definition.hold
    local exit = options.exit or definition.exit
    local style = options.style or Enum.EasingStyle.Quart
    local direction = options.direction or Enum.EasingDirection.Out
    local transforms = definition.pose

    apply(joints, transforms, entry, style, direction)

    task.delay(entry + hold, function()
        if not valid(character, token) then
            return
        end

        if options.pulse then
            local accent = {}
            for key, value in pairs(transforms) do
                accent[key] = value * pose(options.pulse, 0, options.pulse * 0.35)
            end
            apply(joints, accent, 0.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.delay(0.05, function()
                if valid(character, token) then
                    apply(joints, transforms, 0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                end
            end)
        end

        task.delay(options.exitDelay or 0, function()
            if valid(character, token) then
                reset(character, joints, exit)
                stateMachine:Finish(character, token, "Idle")
            end
        end)
    end)

    return true, token
end

function AnimationService.Cancel(character)
    if character then
        stateMachine:Cancel(character)
        idleTokens[character] = (idleTokens[character] or 0) + 1
    end
end

function AnimationService.ResetJoints(character, duration)
    if not character then
        return
    end
    AnimationService.Cancel(character)
    local joints = getJoints(character)
    reset(character, joints, duration or 0.12)
end

function AnimationService.PlayAttack(character, move, options)
    options = options or {}
    options.pulse = options.pulse or 2
    return playPose(character, move, options)
end

function AnimationService.PlaySkill(character, skill, options)
    options = options or {}
    options.pulse = options.pulse or 3
    options.style = options.style or Enum.EasingStyle.Back
    return playPose(character, skill, options)
end

function AnimationService.PlayDomain(character, options)
    options = options or {}
    options.pulse = options.pulse or 2
    options.entry = options.entry or 0.2
    options.hold = options.hold or 0.4
    return playPose(character, "Domain Expansion", options)
end

function AnimationService.HitReact(character, intensity, tag)
    if not character or not character.Parent then
        return false
    end

    local joints = getJoints(character)
    local amount = math.clamp(tonumber(intensity) or 1, 0.4, 2)
    local token = nextToken(character, "HitReact")
    local spread = math.random(-12, 12) * amount

    local profile = {
        Light = {back = 7, twist = 1.0, arm = 5, recovery = 0.11},
        Air = {back = 4, twist = 1.6, arm = 6, recovery = 0.1},
        Heavy = {back = 13, twist = 1.3, arm = 9, recovery = 0.17},
        Launcher = {back = 10, twist = 2.0, arm = 8, recovery = 0.16},
        Slam = {back = 18, twist = 0.7, arm = 12, recovery = 0.2},
        Special = {back = 14, twist = 1.7, arm = 10, recovery = 0.19},
        Parry = {back = 5, twist = 2.8, arm = 4, recovery = 0.1},
        Counter = {back = 12, twist = 2.1, arm = 8, recovery = 0.16},
        Death = {back = 20, twist = 2.4, arm = 14, recovery = 0.28},
        BlackFlash = {back = 17, twist = 2.2, arm = 12, recovery = 0.22}
    }

    local selected = profile[tag] or profile.Light
    local root = pose(selected.back * amount, 0, spread * selected.twist)
    local neck = pose(-8 * amount, spread * 0.25, 0)
    local shoulder = pose(-selected.arm * amount, 0, -spread * 0.65)

    apply(joints, {
        RootJoint = root,
        Waist = pose(selected.back * 0.45 * amount, 0, spread * 0.35 * selected.twist),
        Neck = neck,
        RightShoulder = shoulder,
        LeftShoulder = shoulder:Inverse(),
        RightElbow = pose(4 * amount, 0, -spread * 0.18),
        LeftElbow = pose(4 * amount, 0, spread * 0.18)
    }, 0.035, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    task.delay(selected.recovery, function()
        if valid(character, token) then
            reset(character, joints, 0.13, Enum.EasingStyle.Back)
        end
    end)

    return true
end

function AnimationService.StartIdleCombat(character, intensity)
    if not character or not character.Parent then
        return false
    end

    local joints = getJoints(character)
    local token = (idleTokens[character] or 0) + 1
    idleTokens[character] = token
    stateMachine:Begin(character, "Idle", true)
    local amount = math.clamp(tonumber(intensity) or 1, 0.5, 1.4)

    task.spawn(function()
        local phase = 0
        while character.Parent and idleTokens[character] == token do
            if stateMachine:GetState(character) ~= "Idle" then
                task.wait(0.08)
                continue
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 and not character:GetAttribute("Ragdolled") then
                phase += 1
                local direction = phase % 2 == 0 and 1 or -1
                local speed = root.AssemblyLinearVelocity.Magnitude
                local movementScale = math.clamp(1 + speed / 55, 1, 1.55)
                local rootPose = pose(1.8 * amount * movementScale, 0, 1.2 * amount * direction)
                local waistPose = pose(-1.2 * amount * movementScale, 0, 1.8 * amount * direction)
                local neckPose = pose(-0.8 * amount, 0, -1.2 * amount * direction)

                apply(joints, {
                    RootJoint = rootPose,
                    Waist = waistPose,
                    Neck = neckPose
                }, 0.32, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            end

            task.wait(0.34)
        end
    end)

    return true
end
function AnimationService.StopIdleCombat(character)
    if not character then
        return
    end
    idleTokens[character] = (idleTokens[character] or 0) + 1
    stateMachine:Cancel(character)
end

function AnimationService.Play(character, move, action)
    if action == "Domain" or action == "DomainExpansion" then
        return AnimationService.PlayDomain(character)
    elseif action == "Skill" or action == "Special" or string.match(tostring(action), "^Skill%d$") then
        return AnimationService.PlaySkill(character, move)
    end
    return AnimationService.PlayAttack(character, move)
end

AnimationService.Poses = Poses

return AnimationService
