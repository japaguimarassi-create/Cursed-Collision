local AnimalAnimator = {}

local VALID_STATES = {
    Walk = true,
    Rest = true,
    Run = true,
}

local function roleFor(name)
    local lower = string.lower(name)
    if string.find(lower, "leg", 1, true)
        or string.find(lower, "foot", 1, true)
        or string.find(lower, "paw", 1, true)
        or string.find(lower, "toe", 1, true)
        or string.find(lower, "claw", 1, true) then
        return "Leg"
    end
    if string.find(lower, "wing", 1, true)
        or string.find(lower, "feather", 1, true)
        or string.find(lower, "flipper", 1, true)
        or string.find(lower, "fin", 1, true)
        or string.find(lower, "manta", 1, true) then
        return "Wing"
    end
    if string.find(lower, "tail", 1, true)
        or string.find(lower, "fluke", 1, true)
        or string.find(lower, "stinger", 1, true) then
        return "Tail"
    end
    if string.find(lower, "neck", 1, true)
        or string.find(lower, "head", 1, true)
        or string.find(lower, "ear", 1, true)
        or string.find(lower, "crest", 1, true) then
        return "Head"
    end
    if string.find(lower, "arm", 1, true)
        or string.find(lower, "claw", 1, true)
        or string.find(lower, "pincer", 1, true) then
        return "Arm"
    end
    if lower == "body" or lower == "chest" or lower == "belly" or lower == "modelroot" then
        return "Body"
    end
    return "Static"
end

function AnimalAnimator.new()
    local self = {
        Tracks = setmetatable({}, { __mode = "k" }),
        TrackCount = 0,
        Accumulator = 0,
        StepInterval = 0.05,
    }

    function self:Register(model, state)
        if not model or not model:IsA("Model") or not model.PrimaryPart then
            return false, "invalid_model"
        end
        if self.Tracks[model] then
            return self:SetState(model, state or "Rest")
        end

        local pivot = model:GetPivot()
        local parts = {}
        local index = 0
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                index += 1
                local role = roleFor(descendant.Name)
                if descendant ~= model.PrimaryPart and role ~= "Static" then
                    local offset = pivot:ToObjectSpace(descendant.CFrame)
                    table.insert(parts, {
                        Part = descendant,
                        Offset = offset,
                        Role = role,
                        Side = offset.Position.X >= 0 and 1 or -1,
                        Phase = index * 0.47,
                    })
                end
            end
        end

        local initialState = VALID_STATES[state] and state or "Rest"
        self.Tracks[model] = {
            Model = model,
            Parts = parts,
            State = initialState,
            Time = 0,
        }
        self.TrackCount += 1
        model:SetAttribute("AnimationState", initialState)
        return true
    end

    function self:SetState(model, state)
        local track = self.Tracks[model]
        if not track or not VALID_STATES[state] then
            return false
        end
        if track.State ~= state then
            track.State = state
            track.Time = 0
            model:SetAttribute("AnimationState", state)
        end
        return true
    end

    function self:Remove(model)
        if self.Tracks[model] then
            self.Tracks[model] = nil
            self.TrackCount = math.max(0, self.TrackCount - 1)
        end
    end

    function self:Step(deltaTime)
        local dt = math.clamp(tonumber(deltaTime) or 0, 0, 0.1)
        self.Accumulator += dt
        if self.Accumulator < self.StepInterval then
            return
        end
        local step = self.Accumulator
        self.Accumulator = 0
        for model, track in pairs(self.Tracks) do
            if not model.Parent or not model.PrimaryPart then
                self.Tracks[model] = nil
                self.TrackCount = math.max(0, self.TrackCount - 1)
            else
                track.Time += step
                local pivot = model:GetPivot()
                local state = track.State
                local frequency = state == "Run" and 11.5 or state == "Walk" and 6.2 or 1.8
                local amplitude = state == "Run" and 0.82 or state == "Walk" and 0.38 or 0.035
                local bob = state == "Run" and math.abs(math.sin(track.Time * frequency)) * 0.12
                    or state == "Walk" and math.abs(math.sin(track.Time * frequency)) * 0.055
                    or math.sin(track.Time * frequency) * 0.025

                for _, item in ipairs(track.Parts) do
                    local part = item.Part
                    if part and part.Parent then
                        local phase = track.Time * frequency + item.Phase + (item.Side < 0 and math.pi or 0)
                        local x, y, z = 0, 0, 0
                        if item.Role == "Leg" then
                            x = math.sin(phase) * amplitude
                        elseif item.Role == "Wing" then
                            z = math.sin(phase * 0.82) * (state == "Run" and 0.34 or state == "Walk" and 0.13 or 0.025)
                        elseif item.Role == "Tail" then
                            y = math.sin(phase * 0.72) * (state == "Run" and 0.42 or state == "Walk" and 0.2 or 0.055)
                        elseif item.Role == "Head" then
                            y = math.sin(phase * 0.35) * (state == "Rest" and 0.055 or 0.035)
                            x = math.sin(phase * 0.28) * 0.025
                        elseif item.Role == "Arm" then
                            x = math.sin(phase) * (state == "Run" and 0.6 or state == "Walk" and 0.24 or 0.025)
                        end
                        part.CFrame = pivot * CFrame.new(0, bob, 0) * item.Offset * CFrame.Angles(x, y, z)
                    end
                end
            end
        end
    end

    function self:GetTrackCount()
        return self.TrackCount
    end

    function self:Destroy()
        for model in pairs(self.Tracks) do
            self.Tracks[model] = nil
        end
        self.TrackCount = 0
    end

    return self
end

return AnimalAnimator
