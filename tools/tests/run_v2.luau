--!strict

local ok, err = pcall(function()
    require("./V2Spec")
end)

if not ok then
    error("V2 test suite failed: " .. tostring(err))
end

print("PASS Collision Battlestar V2 suite")
