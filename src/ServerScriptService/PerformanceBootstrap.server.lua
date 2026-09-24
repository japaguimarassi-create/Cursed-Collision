--!strict

local Workspace = game:GetService("Workspace")

local function configure()
    if Workspace.StreamingEnabled == false then
        Workspace.StreamingEnabled = true
    end

    Workspace.StreamingMinRadius = 64
    Workspace.StreamingTargetRadius = 768
    Workspace.StreamOutBehavior = Enum.StreamOutBehavior.Opportunistic

    Workspace:SetAttribute("CC_StreamingConfigured", true)
    Workspace:SetAttribute("CC_StreamingMinRadius", 64)
    Workspace:SetAttribute("CC_StreamingTargetRadius", 768)
end

configure()

Workspace:GetPropertyChangedSignal("StreamingEnabled"):Connect(function()
    if Workspace.StreamingEnabled == false then
        Workspace.StreamingEnabled = true
    end
end)

Workspace:GetPropertyChangedSignal("StreamingMinRadius"):Connect(function()
    if Workspace.StreamingMinRadius ~= 64 then
        Workspace.StreamingMinRadius = 64
    end
end)

Workspace:GetPropertyChangedSignal("StreamingTargetRadius"):Connect(function()
    if Workspace.StreamingTargetRadius ~= 768 then
        Workspace.StreamingTargetRadius = 768
    end
end)

return nil