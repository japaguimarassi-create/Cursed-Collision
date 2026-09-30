--!strict

local RunService = game:GetService("RunService")
local Factory = require(script.Parent:WaitForChild("EnemyFactory"))
local Brain = require(script.Parent:WaitForChild("EnemyBrain"))
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({world = nil, brains = {}, defeatHandler = nil, active = 0}, Service)
end

function Service:Init(registry)
    self.world = registry:Get("World")
    local folder = workspace:FindFirstChild("Enemies")
    if folder then
        folder:ClearAllChildren()
    else
        folder = Instance.new("Folder")
        folder.Name = "Enemies"
        folder.Parent = workspace
    end
end

function Service:SetDefeatHandler(callback)
    self.defeatHandler = callback
end

function Service:Spawn(tier: string, index: number): Model
    assert(Constants.Enemies[tier], "Invalid enemy tier")
    local model = Factory.Create(tier, self.world:GetEnemySpawnCFrame(index))
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    self.brains[model] = Brain.new(model, tier)
    self.active += 1

    if humanoid then
        humanoid.Died:Connect(function()
            if model:GetAttribute("Defeated") == true then
                return
            end
            model:SetAttribute("Defeated", true)
            self.active = math.max(0, self.active - 1)
            local attackerId = humanoid:GetAttribute("LastAttackerUserId")
            if self.defeatHandler then
                self.defeatHandler(model, tier, attackerId)
            end
            self.brains[model] = nil
            task.delay(0.3, function()
                if model.Parent then
                    model:Destroy()
                end
            end)
        end)
    end

    return model
end

function Service:GetActiveCount(): number
    return self.active
end

function Service:ClearAll()
    local folder = workspace:FindFirstChild("Enemies")
    if folder then
        folder:ClearAllChildren()
    end
    table.clear(self.brains)
    self.active = 0
end

function Service:Start()
    local elapsed = 0
    RunService.Heartbeat:Connect(function(deltaTime)
        elapsed += deltaTime
        if elapsed < Constants.AI.Tick then
            return
        end
        elapsed = 0
        local now = os.clock()

        for model, brain in pairs(self.brains) do
            Brain.Update(brain, now)
            if not model.Parent then
                self.brains[model] = nil
            end
        end
    end)
end

return Service