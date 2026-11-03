local TreadmillAnimator = {}
local lastStepAt = 0
local STEP_INTERVAL = 0.05

function TreadmillAnimator.Step(entries, elapsed, config)
    local now = tonumber(elapsed) or os.clock()
    if now - lastStepAt < STEP_INTERVAL then
        return
    end
    lastStepAt = now
    for _, entry in ipairs(entries or {}) do
        local part = entry.Part
        if part and part.Parent then
            if entry.Kind == "Roller" then
                local baseCFrame = entry.BaseCFrame or part.CFrame
                entry.BaseCFrame = baseCFrame
                part.CFrame = baseCFrame * CFrame.Angles(now * (entry.Speed or 4), 0, 0)
            else
                local length = entry.Length or (config and config.TreadmillBeltLength) or 7.2
                local speed = entry.Speed or (config and config.TreadmillBeltSpeed) or 2.4
                local phase = entry.Phase or 0
                local origin = entry.Origin
                if origin then
                    local offset = ((phase + now * speed) % length) - length / 2
                    part.Position = Vector3.new(origin.X, part.Position.Y, origin.Z + offset)
                end
            end
        end
    end
end

function TreadmillAnimator.ApplyLevel(model, level, trainingGain)
    if not model or not model.Parent then
        return false
    end
    local safeLevel = math.clamp(math.floor(tonumber(level) or 1), 1, 99)
    local gain = math.max(0, tonumber(trainingGain) or 0)
    model:SetAttribute("TreadmillLevel", safeLevel)
    model:SetAttribute("TrainingGain", gain)

    local hue = math.clamp((safeLevel - 1) / 9, 0, 1)
    local accent = Color3.fromRGB(
        math.floor(67 + 150 * hue),
        math.floor(205 - 55 * hue),
        math.floor(219 + 20 * hue)
    )
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name == "TreadmillRailLight" or descendant.Name == "ConsoleScreen" then
                descendant.Color = accent
            elseif descendant.Name == "MovingBeltStripe" then
                descendant.Color = safeLevel >= 7 and Color3.fromRGB(255, 197, 77) or accent
            end
        elseif descendant:IsA("BillboardGui") and descendant.Name == "AnimalLabel" then
            local title = descendant:FindFirstChild("Title")
            local subtitle = descendant:FindFirstChild("Subtitle")
            if title and title:IsA("TextLabel") then
                title.Text = "ESTEIRA • NÍVEL " .. tostring(safeLevel)
            end
            if subtitle and subtitle:IsA("TextLabel") then
                subtitle.Text = "+" .. tostring(gain) .. " SPEED / TREINO"
            end
        end
    end
    return true
end

return TreadmillAnimator
