local StudioTestService = game:GetService("StudioTestService")
local Workspace = game:GetService("Workspace")

local toolbar = plugin:CreateToolbar("Steal An Animal QA")
local button = toolbar:CreateButton("Run Studio Audit", "Run two Studio-only QA clients", "")
button.ClickableWhenViewportHidden = true
local running = false

button.Click:Connect(function()
    if running then return end
    running = true
    local previous = Workspace:GetAttribute("EnableStealAnimalAudit")
    Workspace:SetAttribute("EnableStealAnimalAudit", true)
    print("[STEAL_ANIMAL_AUDIT] Starting two simulated Studio clients...")
    local ok, result = pcall(function()
        return StudioTestService:ExecuteMultiplayerTestAsync(2, "StealAnAnimalAudit-v1")
    end)
    Workspace:SetAttribute("EnableStealAnimalAudit", previous)
    if ok then
        print("[STEAL_ANIMAL_AUDIT_REPORT]" .. tostring(result))
        print("[STEAL_ANIMAL_AUDIT] Copy the JSON report from Output and send it for correction.")
    else
        warn("[STEAL_ANIMAL_AUDIT] Failed to run Studio tests: " .. tostring(result))
    end
    running = false
end)
