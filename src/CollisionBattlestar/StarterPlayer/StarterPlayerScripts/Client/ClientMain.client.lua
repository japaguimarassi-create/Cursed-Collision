--!strict

local root = script.Parent

local UIController = require(root:WaitForChild("UIController"))
local InputController = require(root:WaitForChild("InputController"))

UIController:Init()
InputController:Init()
