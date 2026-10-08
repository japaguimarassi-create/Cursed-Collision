--!strict

local suite = require("./PhaseASharedSpec")

local ok, err = pcall(suite)
if not ok then
    error("Phase A shared contract failed: " .. tostring(err))
end

print("PASS Phase A shared contracts")
