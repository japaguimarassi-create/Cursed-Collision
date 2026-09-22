--!strict

local RunService = game:GetService("RunService")

local ProceduralAnimator = {}
ProceduralAnimator.__index = ProceduralAnimator

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

local function keyframe(t: number, pose: {[string]: CFrame}): any
    return {
        t=t,
        pose=pose
    }
end

local function sample(track: any, time: number): {[string]: CFrame}
    if not track or #track == 0 then
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

            local pose: {[string]: CFrame} = {}
            local keys: {[string]: boolean} = {}

            for key in pairs(a.pose) do
                keys[key] = true
            end

            for key in pairs(b.pose) do
                keys[key] = true
            end

            for name in pairs(keys) do
                local from = a.pose[name] or CFrame.identity
                local to = b.pose[name] or CFrame.identity
                pose[name] = from:Lerp(to, alpha)
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
    local track: any = {}

    table.insert(track, keyframe(0.00, {
        Waist=CFrame.Angles(0, -yaw * 0.5, 0),
        LeftShoulder=CFrame.Angles(0, 0, arm * 0.25),
        RightShoulder=CFrame.Angles(0, 0, -arm * 0.55),
        Root=CFrame.Angles(0, yaw * 0.35, 0)
    }))

    table.insert(track, keyframe(0.07, {
        Waist=CFrame.Angles(-0.10, yaw, 0),
        LeftShoulder=CFrame.Angles(-0.20, 0, -arm),
        RightShoulder=CFrame.Angles(-0.34, 0, arm)
    }))

    table.insert(track, keyframe(0.13, {
        Waist=CFrame.Angles(0.06, -yaw * 0.35, 0),
        LeftShoulder=CFrame.Angles(0.34, 0, arm * 0.45),
        RightShoulder=CFrame.Angles(-0.58, 0, -arm * 0.95),
        Root=CFrame.Angles(0, -yaw * 0.5, 0)
    }))

    table.insert(track, keyframe(0.24, {
        Waist=CFrame.identity,
        LeftShoulder=CFrame.identity,
        RightShoulder=CFrame.identity,
        Root=CFrame.identity
    }))

    return track
end

local function dashTrack(direction: string): any
    local lean = direction == "Back" and 0.12 or 0.28
    local side = direction == "Right"
        and -0.22
        or direction == "Left"
        and 0.22
        or 0
    local track: any = {}

    table.insert(track, keyframe(0.00, {
        Waist=CFrame.Angles(lean, side, 0),
        Root=CFrame.Angles(0, side * 0.7, 0)
    }))

    table.insert(track, keyframe(0.08, {
        Waist=CFrame.Angles(-lean * 0.4, side * 0.35, 0),
        Root=CFrame.Angles(0, side, 0)
    }))

    table.insert(track, keyframe(0.18, {
        Waist=CFrame.identity,
        Root=CFrame.identity
    }))

    return track
end

local function skillTrack(slot: number): any
    local accents = {0.20, -0.24, 0.34, -0.38}
    local reaches = {0.38, 0.55, 0.70, 0.88}
    local accent = accents[slot] or 0.2
    local reach = reaches[slot] or 0.38
    local track: any = {}

    table.insert(track, keyframe(0.00, {
        Waist=CFrame.Angles(0.08, accent * 0.25, 0),
        LeftShoulder=CFrame.Angles(-0.12, 0, -reach * 0.45),
        RightShoulder=CFrame.Angles(-0.12, 0, reach * 0.45)
    }))

    table.insert(track, keyframe(0.09, {
        Waist=CFrame.Angles(-0.10, accent, 0),
        LeftShoulder=CFrame.Angles(-0.32, 0, reach),
        RightShoulder=CFrame.Angles(-0.36, 0, -reach)
    }))

    table.insert(track, keyframe(0.18, {
        Waist=CFrame.Angles(0.05, -accent * 0.35, 0),
        LeftShoulder=CFrame.Angles(0.20, 0, -reach * 0.25),
        RightShoulder=CFrame.Angles(0.20, 0, reach * 0.25)
    }))

    table.insert(track, keyframe(0.30, {}))

    return track
end

local function blockStartTrack(): any
    local track: any = {}

    table.insert(track, keyframe(0.00, {
        Waist=CFrame.Angles(0.10, 0, 0),
        LeftShoulder=CFrame.Angles(-0.45, 0, 0.55),
        RightShoulder=CFrame.Angles(-0.45, 0, -0.55)
    }))

    table.insert(track, keyframe(0.14, {
        Waist=CFrame.Angles(0.10, 0, 0),
        LeftShoulder=CFrame.Angles(-0.45, 0, 0.55),
        RightShoulder=CFrame.Angles(-0.45, 0, -0.55)
    }))

    return track
end

local function blockEndTrack(): any
    local track: any = {}

    table.insert(track, keyframe(0.00, {
        Waist=CFrame.Angles(0.10, 0, 0)
    }))

    table.insert(track, keyframe(0.10, {}))

    return track
end

local function specialTrack(): any
    local track: any = {}

    table.insert(track, keyframe(0.00, {
        Waist=CFrame.Angles(0.15, 0, 0),
        Root=CFrame.Angles(0, -0.18, 0)
    }))

    table.insert(track, keyframe(0.18, {
        Waist=CFrame.Angles(-0.14, 0.20, 0),
        LeftShoulder=CFrame.Angles(-0.65, 0, 0.25),
        RightShoulder=CFrame.Angles(-0.65, 0, -0.25)
    }))

    table.insert(track, keyframe(0.36, {
        Waist=CFrame.Angles(0.08, -0.28, 0),
        LeftShoulder=CFrame.Angles(0.38, 0, -0.75),
        RightShoulder=CFrame.Angles(0.38, 0, 0.75)
    }))

    table.insert(track, keyframe(0.60, {}))

    return track
end

function ProceduralAnimator:Bind(character: Model)
    if active[character] then
        return
    end

    local name = "CC_Procedural_" .. character:GetDebugId()

    active[character] = {
        name=name,
        joints=collectJoints(character),
        track=nil,
        started=0
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

function ProceduralAnimator:Play(
    character: Model,
    action: string,
    payload: any
)
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
    elseif string.sub(action, 1, 5) == "Skill" then
        data.track = skillTrack(math.clamp(
            tonumber(string.sub(action, 6)) or 1,
            1,
            4
        ))
        data.started = os.clock()
    elseif action == "BlockStart" then
        data.track = blockStartTrack()
        data.started = os.clock()
    elseif action == "BlockEnd" then
        data.track = blockEndTrack()
        data.started = os.clock()
    elseif action == "Special" then
        data.track = specialTrack()
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