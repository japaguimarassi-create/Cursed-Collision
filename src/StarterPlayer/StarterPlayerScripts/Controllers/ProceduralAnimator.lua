--!strict

local RunService = game:GetService("RunService")

local ProceduralAnimator = {}
ProceduralAnimator.__index = ProceduralAnimator

type Keyframe = {
    t: number,
    pose: {[string]: CFrame}
}

type ActiveState = {
    name: string,
    joints: {[string]: Motor6D?},
    track: any,
    started: number
}

local active: {[Model]: ActiveState} =
    setmetatable({}, {__mode = "k"}) :: any

local function findJoint(character: Model, names: {string}): Motor6D?
    for _, name in ipairs(names) do
        local object = character:FindFirstChild(name, true)

        if object and object:IsA("Motor6D") then
            return object
        end
    end

    return nil
end

local function collectJoints(character: Model)
    return {
        Root = findJoint(character, {"Root", "RootJoint"}),
        Waist = findJoint(character, {"Waist"}),
        Neck = findJoint(character, {"Neck"}),
        LeftShoulder = findJoint(character, {"LeftShoulder", "Left Shoulder"}),
        RightShoulder = findJoint(character, {"RightShoulder", "Right Shoulder"}),
        LeftHip = findJoint(character, {"LeftHip", "Left Hip"}),
        RightHip = findJoint(character, {"RightHip", "Right Hip"})
    }
end

local function ease(alpha: number): number
    alpha = math.clamp(alpha, 0, 1)
    return alpha * alpha * (3 - 2 * alpha)
end

local function sample(track: any, time: number): {[string]: CFrame}
    if #track == 0 then
        return {}
    end

    if time <= track[1].t then
        return track[1].pose
    end

    for index = 2, #track do
        local a = track[index - 1]
        local b = track[index]

        if time <= b.t then
            local alpha = ease(
                (time - a.t)
                / math.max(0.0001, b.t - a.t)
            )

            local pose = {}
            local keys = {}

            for key in pairs(a.pose) do
                keys[key] = true
            end

            for key in pairs(b.pose) do
                keys[key] = true
            end

            for key in pairs(keys) do
                local from = a.pose[key] or CFrame.identity
                local to = b.pose[key] or CFrame.identity
                pose[key] = from:Lerp(to, alpha)
            end

            return pose
        end
    end

    return track[#track].pose
end

local function apply(data: ActiveState, pose: {[string]: CFrame})
    for name, joint in pairs(data.joints) do
        if joint and joint.Parent then
            joint.Transform = pose[name] or CFrame.identity
        end
    end
end

local function attackTrack(combo: number): any
    local yaw = ({-0.24, 0.18, -0.28, 0.10})[combo] or 0
    local arm = ({-0.55, 0.44, -0.62, 0.72})[combo] or 0.4

    local track: {any} = {
        {t=0.00, pose={
            Waist=CFrame.Angles(0, -yaw * 0.5, 0),
            LeftShoulder=CFrame.Angles(0, 0, arm * 0.25),
            RightShoulder=CFrame.Angles(0, 0, -arm * 0.55),
            Root=CFrame.Angles(0, yaw * 0.35, 0)
        }},
        {t=0.07, pose={
            Waist=CFrame.Angles(-0.10, yaw, 0),
            LeftShoulder=CFrame.Angles(-0.20, 0, -arm),
            RightShoulder=CFrame.Angles(-0.34, 0, arm)
        }},
        {t=0.13, pose={
            Waist=CFrame.Angles(0.06, -yaw * 0.35, 0),
            LeftShoulder=CFrame.Angles(0.34, 0, arm * 0.45),
            RightShoulder=CFrame.Angles(-0.58, 0, -arm * 0.95),
            Root=CFrame.Angles(0, -yaw * 0.5, 0)
        }},
        {t=0.24, pose={
            Waist=CFrame.identity,
            LeftShoulder=CFrame.identity,
            RightShoulder=CFrame.identity,
            Root=CFrame.identity
        }}
    }

    return track
end

local function dashTrack(direction: string): any
    local lean = direction == "Back" and 0.12 or 0.28
    local side = direction == "Right"
        and -0.22
        or direction == "Left"
        and 0.22
        or 0

    local track: {any} = {
        {t=0.00, pose={
            Waist=CFrame.Angles(lean, side, 0),
            Root=CFrame.Angles(0, side * 0.7, 0)
        }},
        {t=0.08, pose={
            Waist=CFrame.Angles(-lean * 0.4, side * 0.35, 0),
            Root=CFrame.Angles(0, side, 0)
        }},
        {t=0.18, pose={
            Waist=CFrame.identity,
            Root=CFrame.identity
        }}
    }

    return track
end

function ProceduralAnimator:Bind(character: Model)
    if active[character] then
        return
    end

    local name = "CC_Procedural_" .. character:GetDebugId()

    active[character] = {
        name = name,
        joints = collectJoints(character),
        track = nil,
        started = 0
    }

    RunService:BindToRenderStep(
        name,
        Enum.RenderPriority.Character.Value + 1,
        function()
            local data = active[character]

            if not data then
                return
            end

            if data.track then
                local elapsed = os.clock() - data.started
                apply(data, sample(data.track, elapsed))

                if elapsed >= data.track[#data.track].t then
                    data.track = nil
                    apply(data, {})
                end
            end
        end
    )
end

function ProceduralAnimator:Play(character: Model, action: string, payload: any)
    local data = active[character] :: any

    if not data then
        self:Bind(character)
        data = active[character]
    end

    if not data then
        return
    end

    if action == "M1" then
        data.track = attackTrack(math.clamp(
            tonumber(payload and payload.combo) or 1,
            1,
            4
        ))
        data.started = os.clock()
    elseif action == "Dash" then
        data.track = dashTrack(
            tostring(payload and payload.dashDirection or "Forward")
        )
        data.started = os.clock()
    elseif action == "BlockStart" then
        data.track = {
            {t=0.00, pose={
                Waist=CFrame.Angles(0.10, 0, 0),
                LeftShoulder=CFrame.Angles(-0.45, 0, 0.55),
                RightShoulder=CFrame.Angles(-0.45, 0, -0.55)
            }},
            {t=0.14, pose={
                Waist=CFrame.Angles(0.10, 0, 0),
                LeftShoulder=CFrame.Angles(-0.45, 0, 0.55),
                RightShoulder=CFrame.Angles(-0.45, 0, -0.55)
            }}
        }
        data.started = os.clock()
    elseif action == "BlockEnd" then
        data.track = {
            {t=0.00, pose={Waist=CFrame.Angles(0.10, 0, 0)}},
            {t=0.10, pose={}}
        }
        data.started = os.clock()
    elseif action == "Special" then
        data.track = {
            {t=0.00, pose={
                Waist=CFrame.Angles(0.15, 0, 0),
                Root=CFrame.Angles(0, -0.18, 0)
            }},
            {t=0.18, pose={
                Waist=CFrame.Angles(-0.14, 0.20, 0),
                LeftShoulder=CFrame.Angles(-0.65, 0, 0.25),
                RightShoulder=CFrame.Angles(-0.65, 0, -0.25)
            }},
            {t=0.36, pose={
                Waist=CFrame.Angles(0.08, -0.28, 0),
                LeftShoulder=CFrame.Angles(0.38, 0, -0.75),
                RightShoulder=CFrame.Angles(0.38, 0, 0.75)
            }},
            {t=0.60, pose={}}
        }
        data.started = os.clock()
    end
end

function ProceduralAnimator:Unbind(character: Model)
    local data = active[character]

    if not data then
        return
    end

    RunService:UnbindFromRenderStep(data.name)
    apply(data, {})
    active[character] = nil
end

return ProceduralAnimator