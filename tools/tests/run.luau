--!strict

local suite = require("./PhaseASharedSpec")

local ok, err = pcall(suite)
if not ok then
    error("Collision Battlestar Phase A tests failed: " .. tostring(err))
end

print("PASS Collision Battlestar Phase A tests")
