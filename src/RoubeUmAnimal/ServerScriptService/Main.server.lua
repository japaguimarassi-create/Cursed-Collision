local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = script.Parent:WaitForChild("Services", 15)
local core = ReplicatedStorage:WaitForChild("StealAnimalCore", 20)

local function markDegraded(message)
    if core then
        pcall(function()
            core:SetAttribute("BootState", "Degraded")
            core:SetAttribute("WorldState", "Degraded")
            core:SetAttribute("LastFailure", message)
        end)
    end
    warn("[StealAnAnimal/Main] " .. message)
end

if not Services then
    markDegraded("Services folder is missing; the fallback world remains available.")
    return
end

local kernelModule = Services:FindFirstChild("CoreKernel")
if not kernelModule or not kernelModule:IsA("ModuleScript") then
    markDegraded("CoreKernel ModuleScript is missing; the fallback world remains available.")
    return
end

local requireOK, kernel = pcall(require, kernelModule)
if not requireOK or type(kernel) ~= "table" or type(kernel.Start) ~= "function" then
    markDegraded("CoreKernel failed to load; see server Output.")
    if not requireOK then
        warn("[StealAnAnimal/Main] CoreKernel require failed: " .. tostring(kernel))
    end
    return
end

local startOK, startError = pcall(kernel.Start)
if not startOK then
    markDegraded("CoreKernel startup failed; safe fallback retained.")
    warn("[StealAnAnimal/Main] CoreKernel startup exception: " .. tostring(startError))
end
