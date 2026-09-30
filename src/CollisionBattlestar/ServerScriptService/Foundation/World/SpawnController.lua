--!strict

local Spawn = {}
Spawn.__index = Spawn

function Spawn.new(playerSpawn: BasePart, enemySpawns: Folder)
    local points = {}
    for _, child in ipairs(enemySpawns:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(points, child.CFrame)
        end
    end
    table.sort(points, function(a, b)
        return a.Position.X < b.Position.X
    end)
    return setmetatable({playerSpawn = playerSpawn, enemySpawns = points}, Spawn)
end

function Spawn:PlayerCFrame(): CFrame
    return self.playerSpawn.CFrame + Vector3.new(0, 4, 0)
end

function Spawn:EnemyCFrame(index: number): CFrame
    if #self.enemySpawns == 0 then
        return CFrame.new(0, 5, -50)
    end
    return self.enemySpawns[((index - 1) % #self.enemySpawns) + 1] + Vector3.new(0, 2, 0)
end

return Spawn